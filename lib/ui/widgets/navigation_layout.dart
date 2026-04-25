import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../preference/preference_constants.dart';
import '../../preference/user_preferences.dart';
import '../../util/platform_detection.dart';
import 'download_progress_bar.dart';
import 'left_sidebar.dart';
import 'top_toolbar.dart';

class NavigationLayout extends StatefulWidget {
  final String? activeRoute;
  final Widget child;
  final bool showBackButton;

  /// Notifier that any screen can update to trigger a live position change.
  static final positionNotifier = ValueNotifier<NavbarPosition?>(
    GetIt.instance<UserPreferences>().get(UserPreferences.navbarPosition),
  );

  static final focusNavbarNotifier = ValueNotifier<VoidCallback?>(null);

  const NavigationLayout({
    super.key,
    this.activeRoute,
    required this.child,
    this.showBackButton = false,
  });

  @override
  State<NavigationLayout> createState() => _NavigationLayoutState();
}

class _NavigationLayoutState extends State<NavigationLayout> with WidgetsBindingObserver {
  final _prefs = GetIt.instance<UserPreferences>();
  final _contentFocusNode = FocusNode(debugLabel: 'NavigationContent');
  final ValueNotifier<double> _toolbarScrollOffset = ValueNotifier<double>(0.0);
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
    _toolbarScrollOffset.dispose();
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
    final translateWithScroll = PlatformDetection.isTV;
    final toolbar = TopToolbar(
      activeRoute: widget.activeRoute,
      showBackButton: widget.showBackButton,
    );
    final maxTranslate = TopToolbar.heightFor(context);
    final body = translateWithScroll
        ? NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis != Axis.vertical) return false;
              final px = n.metrics.pixels.clamp(0.0, double.infinity);
              if ((px - _toolbarScrollOffset.value).abs() > 0.5) {
                _toolbarScrollOffset.value = px;
              }
              return false;
            },
            child: widget.child,
          )
        : widget.child;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: body),
              if (translateWithScroll)
                ValueListenableBuilder<double>(
                  valueListenable: _toolbarScrollOffset,
                  builder: (_, offset, child) {
                    final translate = offset.clamp(0.0, maxTranslate);
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: -translate,
                      child: IgnorePointer(
                        ignoring: translate >= maxTranslate,
                        child: child!,
                      ),
                    );
                  },
                  child: toolbar,
                )
              else
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: toolbar,
                ),
            ],
          ),
        ),
        const DownloadProgressBar(),
      ],
    );
  }

  Widget _buildSidebar() {
    final sidebar = LeftSidebar(
      activeRoute: widget.activeRoute,
      contentFocusNode: _contentFocusNode,
      showBackButton: widget.showBackButton,
    );

    if (PlatformDetection.isTV) {
      return Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: widget.child),
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  child: sidebar,
                ),
              ],
            ),
          ),
          const DownloadProgressBar(),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: widget.child),
              Positioned.fill(
                child: sidebar,
              ),
            ],
          ),
        ),
        const DownloadProgressBar(),
      ],
    );
  }
}
