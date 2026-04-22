import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'data/services/app_update_service.dart';
import 'data/services/download_service.dart';
import 'di/providers.dart';
import 'l10n/app_localizations.dart';
import 'preference/user_preferences.dart';
import 'syncplay/syncplay_manager.dart';
import 'ui/navigation/app_router.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/cast_mini_player.dart';
import 'ui/widgets/mini_audio_player.dart';
import 'ui/widgets/offline_banner.dart';
import 'ui/widgets/exit_confirmation_dialog.dart';
import 'util/app_exit.dart';
import 'util/focus/back_key_coordinator.dart';
import 'util/focus/dpad_keys.dart';
import 'util/fullscreen_helper.dart';
import 'util/platform_detection.dart';

class MoonfinApp extends StatelessWidget {
  const MoonfinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Moonfin',
        theme: AppTheme.darkTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supportedLocales) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale?.languageCode) {
              return supported;
            }
          }
          return const Locale('en');
        },
        builder: (context, child) {
          var path = appRouter.routerDelegate.currentConfiguration.uri.path;
          try {
            path = GoRouterState.of(context).uri.path;
          } catch (_) {}

          final hidePlayer = path.startsWith('/player/') ||
              path == '/live-tv/player' ||
              path == '/' ||
              path == '/server-select' ||
              path == '/server' ||
              path == '/login';

          return Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => _GlobalShortcutScope(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        const OfflineBanner(),
                        Expanded(
                          child: _ConnectivityListener(
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                        if (!hidePlayer)
                          const RepaintBoundary(child: MiniAudioPlayer()),
                        if (!hidePlayer)
                          const RepaintBoundary(child: CastMiniPlayer()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlobalShortcutScope extends StatefulWidget {
  final Widget child;

  const _GlobalShortcutScope({required this.child});

  @override
  State<_GlobalShortcutScope> createState() => _GlobalShortcutScopeState();
}

class _GlobalShortcutScopeState extends State<_GlobalShortcutScope> with WindowListener {
  final FocusNode _focusNode = FocusNode(debugLabel: 'GlobalShortcutScope');
  late final KeyEventCallback _hardwareKeyHandler;
  Timer? _geometrySaveTimer;
  bool _exitDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _hardwareKeyHandler = _onHardwareKeyEvent;
    HardwareKeyboard.instance.addHandler(_hardwareKeyHandler);
    if (PlatformDetection.isDesktop) {
      windowManager.addListener(this);
    }
  }

  bool _isPlayerRoute() {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    return path.startsWith('/player/') || path == '/live-tv/player';
  }

  bool _isEditingText() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _onHardwareKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final key = event.logicalKey;
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrlPressed =
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);

    final isBackspace = key == LogicalKeyboardKey.backspace;
    if (key.isBackKey || isBackspace) {
      if (_isPlayerRoute()) {
        return false;
      }
      if (isBackspace && _isEditingText()) {
        return false;
      }
      BackKeyCoordinator.markHandled();
      if (appRouter.canPop()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          appRouter.pop();
        });
      } else if (!_exitDialogShowing) {
        _exitDialogShowing = true;
        unawaited(_showExitConfirmation());
      }
      return true;
    }

    if (PlatformDetection.useDesktopUi && key == LogicalKeyboardKey.f11) {
      unawaited(FullscreenHelper.toggle());
      return true;
    }

    if (PlatformDetection.isDesktop && ctrlPressed && key == LogicalKeyboardKey.keyQ) {
      unawaited(windowManager.close());
      return true;
    }

    return false;
  }

  Future<void> _showExitConfirmation() async {
    try {
      final navContext = appRouter.routerDelegate.navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) {
        return;
      }
      await showExitConfirmationDialog(navContext);
    } catch (e, st) {
      debugPrint('[AppExit] _showExitConfirmation error: $e\n$st');
    } finally {
      _exitDialogShowing = false;
    }
  }

  @override
  void dispose() {
    _geometrySaveTimer?.cancel();
    if (PlatformDetection.isDesktop) {
      windowManager.removeListener(this);
    }
    HardwareKeyboard.instance.removeHandler(_hardwareKeyHandler);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveWindowGeometry() async {
    try {
      final isFullScreen = await windowManager.isFullScreen();
      if (isFullScreen) return;
      final size = await windowManager.getSize();
      final pos = await windowManager.getPosition();
      final prefs = GetIt.instance<UserPreferences>();
      await prefs.set(UserPreferences.windowWidth, size.width);
      await prefs.set(UserPreferences.windowHeight, size.height);
      await prefs.set(UserPreferences.windowX, pos.dx);
      await prefs.set(UserPreferences.windowY, pos.dy);
    } catch (_) {}
  }

  void _scheduleSaveGeometry() {
    _geometrySaveTimer?.cancel();
    _geometrySaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveWindowGeometry();
    });
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'move' || eventName == 'resize' ||
        eventName == 'moved' || eventName == 'resized') {
      _scheduleSaveGeometry();
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
      final targetContext = FocusManager.instance.primaryFocus?.context ?? context;
      final activated = Actions.maybeInvoke(targetContext, const ActivateIntent());
      return activated == null
          ? KeyEventResult.ignored
          : KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: widget.child,
    );
  }
}

class _ConnectivityListener extends ConsumerStatefulWidget {
  final Widget child;
  const _ConnectivityListener({required this.child});

  @override
  ConsumerState<_ConnectivityListener> createState() =>
      _ConnectivityListenerState();
}

class _ConnectivityListenerState
    extends ConsumerState<_ConnectivityListener>
    with WidgetsBindingObserver {
  bool? _wasOnline;
  bool _didScheduleUpdateCheck = false;
  StreamSubscription<SyncPlayUiEvent>? _syncPlayEventsSub;
  StreamSubscription<String>? _downloadErrorSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDesktopUpdateCheck();
    ref.read(syncPlayRuntimeCoordinatorProvider);
    final manager = ref.read(syncPlayManagerProvider);
    _syncPlayEventsSub = manager.uiEvents.listen(_handleSyncPlayEvent);
    if (GetIt.instance.isRegistered<DownloadService>()) {
      _downloadErrorSub = GetIt.instance<DownloadService>()
          .errors
          .listen(_handleDownloadError);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncPlayEventsSub?.cancel();
    _downloadErrorSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final coordinator = ref.read(syncPlayRuntimeCoordinatorProvider);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      coordinator.appDidEnterBackground();
    } else if (state == AppLifecycleState.resumed) {
      coordinator.appDidBecomeActive();
    }
  }

  void _scheduleDesktopUpdateCheck() {
    if (!PlatformDetection.isDesktop || _didScheduleUpdateCheck) {
      return;
    }

    _didScheduleUpdateCheck = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_runDesktopUpdateCheck());
    });
  }

  void _handleSyncPlayEvent(SyncPlayUiEvent event) {    if (!mounted) return;
    switch (event) {
      case SyncPlayUserJoinedEvent(:final userName):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName joined SyncPlay group'),
            duration: const Duration(seconds: 3),
          ),
        );
      case SyncPlayUserLeftEvent(:final userName):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName left SyncPlay group'),
            duration: const Duration(seconds: 3),
          ),
        );
      case SyncPlayLibraryAccessDeniedEvent():
        final navContext =
            appRouter.routerDelegate.navigatorKey.currentContext ?? context;
        showDialog<void>(
          context: navContext,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.lock_outline_rounded),
            title: const Text('SyncPlay access denied'),
            content: const Text(
              'You do not have access to one or more items in this SyncPlay '
              'group. Ask the group owner to verify library permissions or '
              'choose a different queue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
    }
  }

  void _handleDownloadError(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _runDesktopUpdateCheck() async {
    try {
      final update = await GetIt.instance<AppUpdateService>().checkForUpdateIfDue();
      if (!mounted || update == null) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Update available: v${update.version}'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Download',
            onPressed: () {
              unawaited(
                launchUrl(
                  update.downloadUri,
                  mode: LaunchMode.externalApplication,
                ),
              );
            },
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);

    if (_wasOnline != null && _wasOnline != isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOnline
                ? 'Back online. Syncing progress...'
                : 'You are offline.'),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
    _wasOnline = isOnline;

    return widget.child;
  }
}
