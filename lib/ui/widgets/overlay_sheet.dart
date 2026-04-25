import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../util/focus/dpad_keys.dart';
import 'focus/focus_theme.dart';

/// Drop-in replacement for [showDialog] that captures the currently focused
/// node before opening and restores focus to it after the dialog closes.
/// Use this everywhere [showDialog] is called from a TV-facing screen so
/// keyboard/dpad focus returns to the originating widget instead of being
/// lost to the route's default focus traversal.
Future<T?> showFocusRestoringDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  bool useSafeArea = true,
  RouteSettings? routeSettings,
  String? barrierLabel,
}) {
  final previousFocus = FocusManager.instance.primaryFocus;
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;
        if (event is KeyDownEvent) {
          Navigator.of(dialogContext).pop();
          return KeyEventResult.handled;
        }
        if (event is KeyUpEvent) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: builder),
    ),
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    barrierLabel: barrierLabel,
  ).whenComplete(() {
    if (previousFocus != null && previousFocus.canRequestFocus) {
      previousFocus.requestFocus();
    }
  });
}

/// Drop-in replacement for [showModalBottomSheet] with focus restoration.
Future<T?> showFocusRestoringModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
}) {
  final previousFocus = FocusManager.instance.primaryFocus;
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
  ).whenComplete(() {
    if (previousFocus != null && previousFocus.canRequestFocus) {
      previousFocus.requestFocus();
    }
  });
}

class OverlaySheetController {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    AlignmentGeometry alignment = Alignment.center,
    FocusNode? initialFocusNode,
    bool barrierDismissible = true,
    Color barrierColor = const Color(0xB3000000),
    Duration animationDuration = const Duration(milliseconds: 200),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final completer = Completer<T?>();
    final previousFocus = FocusManager.instance.primaryFocus;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (entryContext) => _OverlaySheet<T>(
        completer: completer,
        builder: builder,
        alignment: alignment,
        initialFocusNode: initialFocusNode,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        animationDuration: animationDuration,
        onClosed: () {
          entry.remove();
          if (previousFocus != null && previousFocus.canRequestFocus) {
            previousFocus.requestFocus();
          }
        },
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }

  static void closeAdaptive<T>(BuildContext context, [T? result]) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_OverlaySheetScope>();
    scope?.close(result);
  }
}

class _OverlaySheet<T> extends StatefulWidget {
  final Completer<T?> completer;
  final WidgetBuilder builder;
  final AlignmentGeometry alignment;
  final FocusNode? initialFocusNode;
  final bool barrierDismissible;
  final Color barrierColor;
  final Duration animationDuration;
  final VoidCallback onClosed;

  const _OverlaySheet({
    required this.completer,
    required this.builder,
    required this.alignment,
    required this.initialFocusNode,
    required this.barrierDismissible,
    required this.barrierColor,
    required this.animationDuration,
    required this.onClosed,
  });

  @override
  State<_OverlaySheet<T>> createState() => _OverlaySheetState<T>();
}

class _OverlaySheetState<T> extends State<_OverlaySheet<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  final FocusScopeNode _scopeNode = FocusScopeNode(debugLabel: 'OverlaySheet');
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final initial = widget.initialFocusNode;
        if (initial != null && initial.canRequestFocus) {
          initial.requestFocus();
        } else {
          _scopeNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scopeNode.dispose();
    super.dispose();
  }

  void _close([T? result]) {
    if (_closing) return;
    _closing = true;
    _controller.reverse().whenComplete(() {
      if (!widget.completer.isCompleted) {
        widget.completer.complete(result);
      }
      widget.onClosed();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event.logicalKey.isBackKey) {
      if (event is KeyDownEvent) {
        _close();
        return KeyEventResult.handled;
      }
      if (event is KeyUpEvent) return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return _OverlaySheetScope(
      close: (result) => _close(result as T?),
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.barrierDismissible ? () => _close() : null,
                child: ColoredBox(color: widget.barrierColor),
              ),
            ),
            Positioned.fill(
              child: FocusScope(
                node: _scopeNode,
                autofocus: true,
                onKeyEvent: _onKey,
                child: SlideTransition(
                  position: _slide,
                  child: Align(
                    alignment: widget.alignment,
                    child: AnimatedContainer(
                      duration: FocusTheme.animationDuration,
                      child: Builder(builder: widget.builder),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlaySheetScope extends InheritedWidget {
  final void Function(Object? result) close;
  const _OverlaySheetScope({required this.close, required super.child});

  @override
  bool updateShouldNotify(covariant _OverlaySheetScope oldWidget) => false;
}
