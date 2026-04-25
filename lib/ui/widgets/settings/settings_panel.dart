import 'package:flutter/material.dart';

import '../../../util/platform_detection.dart';
import 'preference_tiles.dart';

class SettingsPanel extends StatelessWidget {
  final Widget child;

  const SettingsPanel({super.key, required this.child});

  static Future<void> open(BuildContext context, Widget content) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, anim, __) => SettingsPanel(child: content),
      transitionBuilder: (context, anim, secondAnim, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = PlatformDetection.useMobileUi
        ? (screenWidth - 8).clamp(320.0, screenWidth)
        : (screenWidth - 16).clamp(320.0, 420.0);
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: panelWidth,
          height: double.infinity,
          child: SettingsListTypography(
            child: _SettingsNavigator(initial: child),
          ),
        ),
      ),
    );
  }
}

class _SettingsNavigator extends StatefulWidget {
  final Widget initial;

  const _SettingsNavigator({required this.initial});

  @override
  State<_SettingsNavigator> createState() => _SettingsNavigatorState();
}

class _SettingsNavigatorState extends State<_SettingsNavigator> {
  final _navKey = GlobalKey<NavigatorState>();
  final _trapScope = FocusScopeNode(
    debugLabel: 'SettingsPanelTrap',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  @override
  void dispose() {
    _trapScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _trapScope,
      autofocus: true,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_navKey.currentState?.canPop() ?? false) {
            _navKey.currentState!.pop();
          } else {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        child: Navigator(
          key: _navKey,
          onGenerateRoute: (_) =>
              MaterialPageRoute(builder: (_) => widget.initial),
        ),
      ),
    );
  }
}

extension SettingsPush on BuildContext {
  void pushSettingsScreen(Widget screen, {FocusNode? returnFocus}) {
    final focusToRestore = returnFocus ?? FocusManager.instance.primaryFocus;
    Navigator.of(this).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _AutoFocusWrapper(child: screen),
        transitionDuration: const Duration(milliseconds: 160),
        reverseTransitionDuration: const Duration(milliseconds: 130),
        transitionsBuilder: (context, anim, _, child) {
          final slide = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
      ),
    ).then((_) {
      if (focusToRestore != null && focusToRestore.context != null) {
        focusToRestore.requestFocus();
      }
    });
  }
}

class _AutoFocusWrapper extends StatefulWidget {
  final Widget child;
  const _AutoFocusWrapper({required this.child});

  @override
  State<_AutoFocusWrapper> createState() => _AutoFocusWrapperState();
}

class _AutoFocusWrapperState extends State<_AutoFocusWrapper> {
  @override
  void initState() {
    super.initState();
    _scheduleInitialFocus();
  }

  void _scheduleInitialFocus({int attempt = 0}) {
    if (!mounted || attempt > 15) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = FocusScope.of(context);
      if (scope.hasFocus) return;
      final didFocus = scope.focusInDirection(TraversalDirection.down);
      if (!didFocus && attempt < 15) {
        Future<void>.delayed(const Duration(milliseconds: 16), () {
          _scheduleInitialFocus(attempt: attempt + 1);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
