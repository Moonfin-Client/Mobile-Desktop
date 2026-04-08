import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../../data/models/lyrics.dart';
import '../../../l10n/app_localizations.dart';

class LyricsView extends StatefulWidget {
  final LyricsData lyrics;
  final Stream<Duration> positionStream;
  final Duration position;

  const LyricsView({
    super.key,
    required this.lyrics,
    required this.positionStream,
    required this.position,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final _scrollController = ScrollController();
  StreamSubscription<Duration>? _sub;
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _updateActive(widget.position);
    if (widget.lyrics.isSynced) {
      _sub = widget.positionStream.listen(_updateActive);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateActive(Duration position) {
    final lines = widget.lyrics.lines;
    int idx = -1;
    for (var i = lines.length - 1; i >= 0; i--) {
      if (position >= lines[i].start) {
        idx = i;
        break;
      }
    }
    if (idx != _activeIndex) {
      setState(() => _activeIndex = idx);
      _scrollToActive(idx);
    }
  }

  void _scrollToActive(int index) {
    if (index < 0 || !_scrollController.hasClients) return;
    final target = index * 48.0 - 100.0;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lyrics.lines;
    if (lines.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).lyricsNotAvailable,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    if (!widget.lyrics.isSynced) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceXl,
          vertical: AppSpacing.spaceLg,
        ),
        itemCount: lines.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            lines[index].text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceXl,
        vertical: AppSpacing.spaceLg,
      ),
      itemCount: lines.length,
      itemExtent: 48,
      itemBuilder: (context, index) {
        final isActive = index == _activeIndex;
        return Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: isActive ? 18 : 15,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              height: 1.4,
            ),
            child: Text(
              lines[index].text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
