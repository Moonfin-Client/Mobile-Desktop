import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import 'bounded_network_image.dart';
import '../../util/focus/dpad_keys.dart';
import 'focus/focus_theme.dart';
import '../mixins/focus_state_mixin.dart';

class GenreCardData {
  final String id;
  final String name;
  int itemCount;
  String? imageUrl;
  String? backdropUrl;

  GenreCardData({
    required this.id,
    required this.name,
    required this.itemCount,
    this.imageUrl,
    this.backdropUrl,
  });
}

class GenreGridCard extends StatefulWidget {
  final GenreCardData genre;
  final VoidCallback onTap;
  final ValueChanged<bool>? onHover;
  final bool centerTitle;
  final Color? focusColor;
  final bool cardFocusExpansion;

  const GenreGridCard({
    super.key,
    required this.genre,
    required this.onTap,
    this.onHover,
    this.centerTitle = false,
    this.focusColor,
    this.cardFocusExpansion = true,
  });

  @override
  State<GenreGridCard> createState() => _GenreGridCardState();
}

class _GenreGridCardState extends State<GenreGridCard> with FocusStateMixin {
  @override
  Widget build(BuildContext context) {
    final isNeon = ThemeRegistry.active.id == ThemeRegistry.neonPulseId;
    final borderColor =
        widget.focusColor ?? Theme.of(context).colorScheme.primary;
    final imageUrl = widget.genre.imageUrl ?? widget.genre.backdropUrl;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setHovered(true);
        widget.onHover?.call(true);
      },
      onExit: (_) {
        setHovered(false);
        widget.onHover?.call(false);
      },
      child: Focus(
        onFocusChange: (focused) => setFocused(focused),
        onKeyEvent: (_, event) {
          if (isActivateKey(event)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: widget.cardFocusExpansion && showFocusBorder ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: isNeon
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: showFocusBorder
                          ? Border.fromBorderSide(
                              ThemeRegistry.active.borders.focusBorder.copyWith(
                                color: borderColor,
                              ),
                            )
                          : null,
                    )
                  : FocusTheme.focusDecoration(
                      isFocused: showFocusBorder,
                      radius: 10,
                      color: borderColor,
                    ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      BoundedNetworkImage(
                        imageUrl: imageUrl,
                        fadeInDuration: const Duration(milliseconds: 200),
                        errorBuilder: (_, _, _) =>
                            Container(
                              color: AppColorScheme.surface.withValues(alpha: 0.35),
                            ),
                      )
                    else
                      Container(
                        color: AppColorScheme.surface.withValues(alpha: 0.35),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: widget.centerTitle
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.genre.name,
                            maxLines: widget.centerTitle ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: widget.centerTitle
                                ? TextAlign.center
                                : TextAlign.start,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (widget.genre.itemCount > 0)
                            Text(
                              '${widget.genre.itemCount} items',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha(178),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
