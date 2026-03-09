import 'package:flutter/material.dart';

import '../../util/platform_detection.dart';

class SettingsPanel extends StatelessWidget {
  final Widget child;

  const SettingsPanel({super.key, required this.child});

  static Future<void> open(BuildContext context, Widget content) {
    if (PlatformDetection.useMobileUi) {
      return Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => content),
      );
    }
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, anim, __) => SettingsPanel(child: content),
      transitionBuilder: (context, anim, secondAnim, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(position: slide, child: FadeTransition(opacity: anim, child: child));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 380,
          height: double.infinity,
          child: _SettingsNavigator(initial: child),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_navKey.currentState?.canPop() ?? false) {
          _navKey.currentState!.pop();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Navigator(
        key: _navKey,
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => widget.initial,
        ),
      ),
    );
  }
}

extension SettingsPush on BuildContext {
  void pushSettingsScreen(Widget screen) {
    Navigator.of(this).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, anim, _, child) {
          final slide = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
      ),
    );
  }
}
