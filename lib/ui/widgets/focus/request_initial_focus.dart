import 'dart:async';

import 'package:flutter/widgets.dart';

/// Wraps a screen subtree and grants focus to the first focusable descendant
/// after the first frame so dpad navigation works on a freshly pushed route.
/// Retries briefly if focusable widgets are not yet registered (e.g. while
/// the screen is loading async data).
///
/// If [targetNode] is provided, focus is granted to that specific node once it
/// attaches to the tree. This is useful when async-loaded content provides the
/// preferred initial focus target.
class RequestInitialFocus extends StatefulWidget {
  final Widget child;
  final FocusNode? targetNode;

  const RequestInitialFocus({super.key, required this.child, this.targetNode});

  @override
  State<RequestInitialFocus> createState() => _RequestInitialFocusState();
}

class _RequestInitialFocusState extends State<RequestInitialFocus> {
  static const _maxAttemptsScope = 8;
  static const _maxAttemptsTarget = 60;
  static const _retryDelay = Duration(milliseconds: 50);
  Timer? _retryTimer;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryFocus(0));
  }

  @override
  void didUpdateWidget(RequestInitialFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.targetNode, widget.targetNode) &&
        widget.targetNode != null) {
      _retryTimer?.cancel();
      _settled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryFocus(0));
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _tryFocus(int attempt) {
    if (!mounted || _settled) return;
    final target = widget.targetNode;
    final scope = FocusScope.of(context);

    if (target != null) {
      final attached = target.context != null;
      final canReq = target.canRequestFocus;
      if (target.hasFocus) {
        _settled = true;
        return;
      }
      if (attached && canReq) {
        scope.requestFocus(target);
        if (target.hasFocus) {
          _settled = true;
          return;
        }
      }
      if (attempt + 1 >= _maxAttemptsTarget) {
        return;
      }
      _retryTimer = Timer(_retryDelay, () => _tryFocus(attempt + 1));
      return;
    }

    if (_scopeHasFocus(scope)) {
      _settled = true;
      return;
    }
    scope.requestFocus();
    scope.nextFocus();
    if (_scopeHasFocus(scope)) {
      _settled = true;
      return;
    }
    if (attempt + 1 >= _maxAttemptsScope) {
      return;
    }
    _retryTimer = Timer(_retryDelay, () => _tryFocus(attempt + 1));
  }

  bool _scopeHasFocus(FocusScopeNode scope) {
    if (scope.focusedChild != null) return true;
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null) return false;
    FocusNode? node = primary;
    while (node != null) {
      if (identical(node, scope)) return true;
      node = node.parent;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
