import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../preference/user_preferences.dart';
import 'focus_theme.dart';
import '../../../util/focus/dpad_keys.dart';
import '../../mixins/focus_state_mixin.dart';

enum ToolbarButtonVariant {
  /// Background fills white when focused; icon inverts to black.
  invert,
  /// Translucent background; icon stays white. Optional scale-on-focus.
  translucent,
}

/// Square icon button that participates in dpad focus traversal,
/// activates on select/enter key events, and renders a focus border.
/// Replaces several near-identical screen-private toolbar buttons.
class FocusableToolbarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final double iconSize;
  final ToolbarButtonVariant variant;
  /// Border color when focused. Defaults to the user's preferred focus color.
  final Color? accentColor;
  /// Alpha applied to the unfocused icon color in the [invert] variant.
  final int unfocusedIconAlpha;
  /// Multiplicative scale applied while focused. 1.0 disables scaling.
  final double scaleOnFocus;

  const FocusableToolbarButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 42,
    this.iconSize = 24,
    this.variant = ToolbarButtonVariant.invert,
    this.accentColor,
    this.unfocusedIconAlpha = 179,
    this.scaleOnFocus = 1.0,
  });

  @override
  State<FocusableToolbarButton> createState() => _FocusableToolbarButtonState();
}

class _FocusableToolbarButtonState extends State<FocusableToolbarButton>
    with FocusStateMixin {
  @override
  Widget build(BuildContext context) {
    final prefFocusColor = Color(
      GetIt.instance<UserPreferences>()
          .get(UserPreferences.focusColor)
          .colorValue,
    );
    final focusColor = widget.accentColor ?? prefFocusColor;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: widget.size,
      height: widget.size,
      decoration: FocusTheme.focusDecoration(
        isFocused: showFocusBorder,
        radius: 6,
        color: focusColor,
        backgroundColor: _backgroundColor(),
      ),
      child: Icon(
        widget.icon,
        size: widget.iconSize,
        color: _iconColor(),
      ),
    );

    if (widget.scaleOnFocus != 1.0) {
      content = AnimatedScale(
        scale: showFocusBorder ? widget.scaleOnFocus : 1.0,
        duration: const Duration(milliseconds: 120),
        child: content,
      );
    }

    Widget core = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (f) => setFocused(f),
        onKeyEvent: (_, event) {
          if (isActivateKey(event)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(onTap: widget.onTap, child: content),
      ),
    );

    if (widget.tooltip != null) {
      core = Tooltip(message: widget.tooltip!, child: core);
    }
    return core;
  }

  Color _backgroundColor() {
    switch (widget.variant) {
      case ToolbarButtonVariant.invert:
        return focused ? Colors.white : Colors.transparent;
      case ToolbarButtonVariant.translucent:
        return Colors.white.withAlpha(focused ? 36 : 20);
    }
  }

  Color _iconColor() {
    switch (widget.variant) {
      case ToolbarButtonVariant.invert:
        return focused
            ? Colors.black
            : Colors.white.withAlpha(widget.unfocusedIconAlpha);
      case ToolbarButtonVariant.translucent:
        return Colors.white;
    }
  }
}
