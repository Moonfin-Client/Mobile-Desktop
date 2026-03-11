import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../preference/preference_constants.dart';
import '../../preference/user_preferences.dart';
import 'left_sidebar.dart';
import 'top_toolbar.dart';

class NavigationLayout extends StatefulWidget {
  final String? activeRoute;
  final Widget child;

  /// Notifier that any screen can update to trigger a live position change.
  static final positionNotifier = ValueNotifier<NavbarPosition?>(
    GetIt.instance<UserPreferences>().get(UserPreferences.navbarPosition),
  );

  const NavigationLayout({
    super.key,
    this.activeRoute,
    required this.child,
  });

  @override
  State<NavigationLayout> createState() => _NavigationLayoutState();
}

class _NavigationLayoutState extends State<NavigationLayout> with WidgetsBindingObserver {
  final _prefs = GetIt.instance<UserPreferences>();
  final _contentFocusNode = FocusNode(debugLabel: 'NavigationContent');
  late NavbarPosition _position;

  @override
  void initState() {
    super.initState();
    _position = _prefs.get(UserPreferences.navbarPosition);
    WidgetsBinding.instance.addObserver(this);
    NavigationLayout.positionNotifier.addListener(_onPositionNotified);
  }

  @override
  void dispose() {
    NavigationLayout.positionNotifier.removeListener(_onPositionNotified);
    WidgetsBinding.instance.removeObserver(this);
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onPositionNotified() {
    final pos = NavigationLayout.positionNotifier.value;
    if (pos != null && pos != _position && mounted) {
      setState(() => _position = pos);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPosition();
  }

  void _refreshPosition() {
    final pos = _prefs.get(UserPreferences.navbarPosition);
    if (pos != _position && mounted) setState(() => _position = pos);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_position) {
      NavbarPosition.left => _buildSidebar(),
      NavbarPosition.top => _buildToolbar(),
    };
  }

  Widget _buildToolbar() {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: TopToolbar(activeRoute: widget.activeRoute),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned.fill(
          child: LeftSidebar(
            activeRoute: widget.activeRoute,
            contentFocusNode: _contentFocusNode,
          ),
        ),
      ],
    );
  }
}
