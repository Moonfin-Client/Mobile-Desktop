import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'data/services/app_update_service.dart';
import 'di/providers.dart';
import 'l10n/app_localizations.dart';
import 'preference/user_preferences.dart';
import 'ui/navigation/app_router.dart';
import 'ui/navigation/destinations.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/cast_mini_player.dart';
import 'ui/widgets/mini_audio_player.dart';
import 'ui/widgets/offline_banner.dart';
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
                        if (!hidePlayer) const MiniAudioPlayer(),
                        if (!hidePlayer) const CastMiniPlayer(),
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

  bool _onHardwareKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final key = event.logicalKey;
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrlPressed =
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);

    if (key == LogicalKeyboardKey.escape) {
      if (_isPlayerRoute()) {
        return false;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (appRouter.canPop()) {
          appRouter.pop();
        } else {
          appRouter.go(Destinations.home);
        }
      });
      return true;
    }

    if (PlatformDetection.isDesktop && key == LogicalKeyboardKey.f11) {
      unawaited(() async {
        final full = await windowManager.isFullScreen();
        await windowManager.setFullScreen(!full);
      }());
      return true;
    }

    if (PlatformDetection.isDesktop && ctrlPressed && key == LogicalKeyboardKey.keyQ) {
      unawaited(windowManager.close());
      return true;
    }

    return false;
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
    extends ConsumerState<_ConnectivityListener> {
  bool? _wasOnline;
  bool _didScheduleUpdateCheck = false;

  @override
  void initState() {
    super.initState();
    _scheduleDesktopUpdateCheck();
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
