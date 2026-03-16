import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../util/platform_detection.dart';

const _kExpandDuration = Duration(milliseconds: 150);
const _kHoverDelay = Duration(milliseconds: 150);
const _kSpacing = 10.0;

class ExpandableIconButton extends StatefulWidget {
  final IconData? icon;
  final Widget Function(double size, Color color)? iconBuilder;
  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool isActive;
  final Color activeColor;

  const ExpandableIconButton({
    super.key,
    this.icon,
    this.iconBuilder,
    required this.label,
    required this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.isActive = false,
    this.activeColor = const Color(0xFF00A4DC),
  });

  @override
  State<ExpandableIconButton> createState() => _ExpandableIconButtonState();
}

class _ExpandableIconButtonState extends State<ExpandableIconButton> {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;
  Timer? _hoverTimer;

  bool get _expanded => _isFocused || _isHovered;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter)) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = PlatformDetection.useMobileUi;
    final isTV = PlatformDetection.useLeanbackUi;
    final btnSize = isMobile ? 40.0 : 48.0;
    final iconSize = isMobile ? 22.0 : 28.0;
    final borderRadius = btnSize / 2;

    final bgColor = widget.isActive
        ? Colors.white.withValues(alpha: 0.22)
        : (_isFocused || _isHovered)
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent;

    final fgColor = (widget.isActive || _isFocused || _isHovered)
        ? Colors.white
        : Colors.white.withValues(alpha: 0.6);

    return MouseRegion(
      onEnter: (_) {
        _hoverTimer?.cancel();
        _hoverTimer = Timer(_kHoverDelay, () {
          if (mounted) setState(() => _isHovered = true);
        });
      },
      onExit: (_) {
        _hoverTimer?.cancel();
        setState(() => _isHovered = false);
      },
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: GestureDetector(
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          child: AnimatedContainer(
            duration: _kExpandDuration,
            curve: Curves.easeOut,
            height: btnSize,
            constraints: BoxConstraints(
              minWidth: btnSize,
              maxWidth: _expanded ? 200 : btnSize,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: isTV && _isFocused
                  ? Border.all(color: widget.activeColor, width: 2)
                  : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: _expanded ? 18 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.iconBuilder?.call(iconSize, fgColor) ?? Icon(widget.icon, size: iconSize, color: fgColor),
                if (_expanded) ...[
                  const SizedBox(width: _kSpacing),
                  Flexible(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: fgColor,
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
