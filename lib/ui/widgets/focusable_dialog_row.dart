import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _focusNode = FocusNode();
  bool _isFocused = false;

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
    final baseColor = widget.dimmed
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.8);
    final color = _isFocused ? Colors.white : baseColor;

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
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          color: _isFocused ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
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
    );
  }
}
