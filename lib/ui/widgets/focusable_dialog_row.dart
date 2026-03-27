import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:moonfin/preference/user_preferences.dart';

class FocusableDialogRow extends StatefulWidget {
  final IconData? icon;
  final Widget Function(double size, Color color)? iconBuilder;
  final String label;
  final VoidCallback onTap;
  final bool autofocus;
  final bool dimmed;

  const FocusableDialogRow({
    super.key,
    this.icon,
    this.iconBuilder,
    required this.label,
    required this.onTap,
    this.autofocus = false,
    this.dimmed = false,
  });

  @override
  State<FocusableDialogRow> createState() => _FocusableDialogRowState();
}

class _FocusableDialogRowState extends State<FocusableDialogRow> {
  final _prefs = GetIt.instance<UserPreferences>();
  final _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = Color(_prefs.get(UserPreferences.focusColor).colorValue);
    final showActive = _isFocused || _isHovered;
    final baseColor = widget.dimmed
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.8);
    final color = showActive ? focusColor : baseColor;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: double.infinity,
            color: showActive ? focusColor.withValues(alpha: 0.2) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                if (widget.icon != null || widget.iconBuilder != null) ...[
                  widget.iconBuilder != null
                      ? widget.iconBuilder!(20, color)
                      : Icon(widget.icon, size: 20, color: color),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(fontSize: 16, color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
