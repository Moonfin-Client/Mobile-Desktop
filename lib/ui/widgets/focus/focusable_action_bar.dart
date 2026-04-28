import 'package:flutter/widgets.dart';

import '../../../util/focus/dpad_keys.dart';
import '../../../util/focus/key_event_utils.dart';
import 'focus_theme.dart';

class FocusableAction {
  final IconData icon;
  final String? tooltip;
  final double iconSize;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  const FocusableAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 24.0,
    this.focusNode,
  });
}

class FocusableActionBar extends StatefulWidget {
  final List<FocusableAction> actions;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry itemPadding;
  final double spacing;
  final Color? focusColor;
  final double borderRadius;

  const FocusableActionBar({
    super.key,
    required this.actions,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onBack,
    this.itemPadding = const EdgeInsets.all(8),
    this.spacing = 4,
    this.focusColor,
    this.borderRadius = FocusTheme.defaultBorderRadius,
  });

  @override
  State<FocusableActionBar> createState() => FocusableActionBarState();
}

class FocusableActionBarState extends State<FocusableActionBar> {
  final List<FocusNode> _ownedNodes = [];
  late List<FocusNode> _nodes;
  int? _focusedIndex;

  @override
  void initState() {
    super.initState();
    _rebuildNodes();
  }

  @override
  void didUpdateWidget(covariant FocusableActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions.length != widget.actions.length) {
      _rebuildNodes();
    } else {
      for (var i = 0; i < widget.actions.length; i++) {
        final supplied = widget.actions[i].focusNode;
        if (supplied != null && supplied != _nodes[i]) {
          _rebuildNodes();
          break;
        }
      }
    }
  }

  void _rebuildNodes() {
    for (final n in _ownedNodes) {
      n.dispose();
    }
    _ownedNodes.clear();
    _nodes = List.generate(widget.actions.length, (i) {
      final supplied = widget.actions[i].focusNode;
      if (supplied != null) return supplied;
      final node = FocusNode(debugLabel: 'FocusableActionBar[$i]');
      _ownedNodes.add(node);
      return node;
    });
  }

  @override
  void dispose() {
    for (final n in _ownedNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void requestFocusOnFirst() {
    if (_nodes.isNotEmpty) _nodes.first.requestFocus();
  }

  KeyEventResult _onKeyEvent(int index, FocusNode node, KeyEvent event) {
    final action = widget.actions[index];
    final selectResult = handleOneShotSelect(event, action.onPressed);
    if (selectResult != KeyEventResult.ignored) return selectResult;

    if (widget.onBack != null) {
      final r = handleBackKeyAction(event, widget.onBack!);
      if (r != KeyEventResult.ignored) return r;
    }

    if (!event.isActionable) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k.isLeftKey) {
      if (index > 0) {
        _nodes[index - 1].requestFocus();
        return KeyEventResult.handled;
      }
      if (widget.onNavigateLeft != null) {
        widget.onNavigateLeft!();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }
    if (k.isRightKey) {
      if (index < _nodes.length - 1) {
        _nodes[index + 1].requestFocus();
        return KeyEventResult.handled;
      }
      if (widget.onNavigateRight != null) {
        widget.onNavigateRight!();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }
    if (k.isUpKey) {
      if (widget.onNavigateUp != null) widget.onNavigateUp!();
      return KeyEventResult.handled;
    }
    if (k.isDownKey) {
      if (widget.onNavigateDown != null) widget.onNavigateDown!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final color = FocusTheme.resolveColor(context, widget.focusColor);
    final children = <Widget>[];
    for (var i = 0; i < widget.actions.length; i++) {
      if (i > 0) children.add(SizedBox(width: widget.spacing));
      final action = widget.actions[i];
      final isFocused = _focusedIndex == i;
      Widget item = Focus(
        focusNode: _nodes[i],
        onKeyEvent: (node, event) => _onKeyEvent(i, node, event),
        onFocusChange: (f) => setState(() {
          if (f) {
            _focusedIndex = i;
          } else if (_focusedIndex == i) {
            _focusedIndex = null;
          }
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: action.onPressed,
          child: AnimatedContainer(
            duration: FocusTheme.animationDuration,
            curve: Curves.easeOut,
            padding: widget.itemPadding,
            decoration: FocusTheme.focusDecoration(
              isFocused: isFocused,
              radius: widget.borderRadius,
              color: color,
              backgroundColor: isFocused ? color.withValues(alpha: 0.18) : null,
            ),
            child: Icon(action.icon, size: action.iconSize),
          ),
        ),
      );
      if (action.tooltip != null) {
        item = Semantics(label: action.tooltip, button: true, child: item);
      }
      children.add(item);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
