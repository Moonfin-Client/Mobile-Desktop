import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../../data/models/media_segment.dart';
import '../../../l10n/app_localizations.dart';
import '../focus/focus_theme.dart';

class SkipSegmentOverlay extends StatefulWidget {
  final MediaSegment segment;
  final VoidCallback onSkip;
  final VoidCallback onDismiss;
  final FocusNode? focusNode;

  const SkipSegmentOverlay({
    super.key,
    required this.segment,
    required this.onSkip,
    required this.onDismiss,
    this.focusNode,
  });

  @override
  State<SkipSegmentOverlay> createState() => _SkipSegmentOverlayState();
}

class _SkipSegmentOverlayState extends State<SkipSegmentOverlay> {
  Timer? _autoHide;

  @override
  void initState() {
    super.initState();
    _autoHide = Timer(const Duration(seconds: 8), widget.onDismiss);
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned(
      right: 24,
      bottom: 120,
      child: Material(
        color: Colors.transparent,
        child: Focus(
          focusNode: widget.focusNode,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter)) {
              widget.onSkip();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: InkWell(
            onTap: widget.onSkip,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: FocusTheme.focusDecoration(
                isFocused: true,
                radius: 8,
                color: AppColorScheme.accent,
                backgroundColor: AppColorScheme.surface.withValues(alpha: 0.9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.skipSegment(widget.segment.type.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.skip_next_rounded,
                    color: AppColorScheme.accent,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
