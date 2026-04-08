import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../l10n/app_localizations.dart';

class NextUpOverlay extends StatefulWidget {
  final AggregatedItem nextItem;
  final String? imageUrl;
  final int timeoutMs;
  final VoidCallback onPlayNext;
  final VoidCallback onDismiss;

  const NextUpOverlay({
    super.key,
    required this.nextItem,
    this.imageUrl,
    required this.timeoutMs,
    required this.onPlayNext,
    required this.onDismiss,
  });

  @override
  State<NextUpOverlay> createState() => _NextUpOverlayState();
}

class _NextUpOverlayState extends State<NextUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _countdownController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.timeoutMs),
    )..forward();

    if (widget.timeoutMs > 0) {
      _timer = Timer(
        Duration(milliseconds: widget.timeoutMs),
        widget.onPlayNext,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.nextItem;
    final epInfo = item.indexNumber != null
        ? 'S${item.parentIndexNumber ?? '?'}:E${item.indexNumber}'
        : null;

    return Positioned(
      right: 24,
      bottom: 100,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: AppColorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.imageUrl != null)
              SizedBox(
                height: 120,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColorScheme.surfaceVariant),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.upNext,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [if (epInfo != null) epInfo, item.name]
                        .where((s) => s.isNotEmpty)
                        .join(' — '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onPlayNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorScheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(l10n.playNext),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: widget.onDismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(l10n.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.timeoutMs > 0)
              AnimatedBuilder(
                animation: _countdownController,
                builder: (context, _) => LinearProgressIndicator(
                  value: 1.0 - _countdownController.value,
                  backgroundColor: Colors.transparent,
                  color: AppColorScheme.accent,
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
