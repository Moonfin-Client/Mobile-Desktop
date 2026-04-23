import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../preference/user_preferences.dart';
import '../../util/focus/dpad_keys.dart';
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
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final ValueChanged<bool>? onFocusChanged;
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
    this.onKeyEvent,
    this.onFocusChanged,
    this.isActive = false,
    this.activeColor = const Color(0xFF00A4DC),
  });

  @override
  State<ExpandableIconButton> createState() => _ExpandableIconButtonState();
}

class _ExpandableIconButtonState extends State<ExpandableIconButton> {
  final _prefs = GetIt.instance<UserPreferences>();
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;
  Timer? _hoverTimer;
  Timer? _longPressTimer;
  bool _longPressTriggered = false;

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
    _longPressTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    setState(() => _isFocused = hasFocus);
    widget.onFocusChanged?.call(hasFocus);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final delegated = widget.onKeyEvent?.call(node, event);
    if (delegated != null && delegated != KeyEventResult.ignored) {
      return delegated;
    }

    if (widget.onLongPress != null &&
        event is KeyDownEvent &&
        event.logicalKey.isContextMenuKey) {
      widget.onLongPress!();
      return KeyEventResult.handled;
    }

    if (widget.onLongPress != null && event.logicalKey.isSelectKey) {
      if (event is KeyDownEvent) {
        _longPressTriggered = false;
        _longPressTimer?.cancel();
        _longPressTimer = Timer(const Duration(milliseconds: 450), () {
          if (!mounted || !_focusNode.hasFocus) return;
          _longPressTriggered = true;
          widget.onLongPress?.call();
        });
        return KeyEventResult.handled;
      }

      if (event is KeyUpEvent) {
        _longPressTimer?.cancel();
        _longPressTimer = null;
        final triggered = _longPressTriggered;
        _longPressTriggered = false;
        if (!triggered) {
          widget.onPressed();
        }
        return KeyEventResult.handled;
      }
    }

    if (event is KeyDownEvent && event.logicalKey.isSelectKey) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = PlatformDetection.useMobileUi;
    final isTV = PlatformDetection.isTV;
    final btnSize = isMobile ? 40.0 : (isTV ? 64.0 : 56.0);
    final iconSize = isMobile ? 22.0 : (isTV ? 34.0 : 30.0);
    final focusColor = Color(_prefs.get(UserPreferences.focusColor).colorValue);

    final leanbackFocused = _isFocused && !isMobile;
    final isExpanded = _expanded || leanbackFocused;

    // Full-height pill: radius matches the outer pill container
    final effectiveBorderRadius = !isMobile ? 36.0 : (btnSize / 2);

    final bgColor = leanbackFocused
        ? Colors.white
        : widget.isActive
            ? widget.activeColor.withValues(alpha: 0.22)
            : (_isFocused || _isHovered)
                ? focusColor.withValues(alpha: 0.18)
                : Colors.transparent;

    final fgColor = leanbackFocused
        ? Colors.black
        : widget.isActive
            ? widget.activeColor
            : (_isFocused || _isHovered)
                ? focusColor
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
            height: isMobile ? btnSize : null,
            constraints: BoxConstraints(
              minWidth: btnSize,
              maxWidth: isExpanded ? 200 : btnSize,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
                border: (_isFocused && isMobile)
                  ? Border.all(color: focusColor, width: 2)
                  : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? (isMobile ? 18 : 24) : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.iconBuilder?.call(iconSize, fgColor) ?? Icon(widget.icon, size: iconSize, color: fgColor),
                if (isExpanded) ...[
                  const SizedBox(width: _kSpacing),
                  Flexible(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: fgColor,
                        fontSize: isMobile ? 14 : (isTV ? 18 : 16),
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
