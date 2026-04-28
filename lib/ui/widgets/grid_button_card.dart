import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import '../mixins/focus_state_mixin.dart';

class GridButtonCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double width;
  final double height;
  final Color? focusColor;
  final bool cardFocusExpansion;
  final FocusNode? focusNode;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final ValueChanged<bool>? onFocusChanged;
  final bool? externalIsFocused;

  const GridButtonCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.width = 160,
    this.height = 120,
    this.focusColor,
    this.cardFocusExpansion = true,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChanged,
    this.externalIsFocused,
  });

  @override
  State<GridButtonCard> createState() => _GridButtonCardState();
}

class _GridButtonCardState extends State<GridButtonCard> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final borders = ThemeRegistry.active.borders;
    final externallyDriven = widget.externalIsFocused != null;
    final hasNodeFocus = widget.focusNode?.hasFocus ?? false;
    final effectiveFocused = externallyDriven
        ? (widget.externalIsFocused! || hovered)
        : (hovered || focused || hasNodeFocus);
    final focusedBackground = widget.focusColor ?? AppColorScheme.buttonFocused;
    final focusedBorderColor = widget.focusColor ?? borders.focusBorder.color;
    final focusedForeground =
      ThemeData.estimateBrightnessForColor(focusedBackground) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final color = effectiveFocused
      ? focusedBackground
      : AppColorScheme.buttonNormal;
    final foregroundColor = effectiveFocused
      ? focusedForeground
      : AppColorScheme.onButtonNormal;
    final scale = widget.cardFocusExpansion && effectiveFocused ? 1.05 : 1.0;

    final inner = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borders.cardRadius,
            border: effectiveFocused
                ? Border.fromBorderSide(
                    borders.focusBorder.copyWith(color: focusedBorderColor),
                  )
                : Border.fromBorderSide(borders.cardBorder),
            boxShadow: effectiveFocused && borders.focusGlow.isNotEmpty
                ? borders.focusGlow
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 36,
                color: foregroundColor,
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              Text(
                widget.label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: externallyDriven
          ? inner
          : Focus(
              focusNode: widget.focusNode,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.enter)) {
                  widget.onTap();
                  return KeyEventResult.handled;
                }
                return widget.onKeyEvent?.call(node, event) ??
                    KeyEventResult.ignored;
              },
              onFocusChange: (f) {
                setFocused(f);
                widget.onFocusChanged?.call(f);
              },
              child: inner,
            ),
    );
  }
}
