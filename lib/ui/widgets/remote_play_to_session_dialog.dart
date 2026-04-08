import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../data/models/aggregated_item.dart';
import '../../data/services/cast/cast_service.dart';
import '../../data/services/cast/cast_target.dart';
import '../../l10n/app_localizations.dart';

Future<void> showRemotePlayToSessionDialog(
  BuildContext context, {
  required AggregatedItem item,
  List<AggregatedItem>? queueItems,
  int? startPositionTicks,
  String? mediaSourceId,
  int? audioStreamIndex,
  int? subtitleStreamIndex,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final castService = GetIt.instance<CastService>();

  final picked = await showModalBottomSheet<CastTarget>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (_, scrollController) => _CastTargetSheet(
        stream: castService.discoverTargetsStreamed(item),
        scrollController: scrollController,
      ),
    ),
  );

  if (picked == null || !context.mounted) return;

  try {
    await castService.playToTarget(
      picked,
      item: item,
      queueItems: queueItems,
      startPositionTicks: startPositionTicks,
      mediaSourceId: mediaSourceId,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );
    if (!context.mounted) return;
    if (picked.kind != CastTargetKind.airPlay) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).castingStarted)),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).castingFailed(e.toString()))),
    );
  }
}

class _CastTargetSheet extends StatefulWidget {
  final Stream<CastTarget> stream;
  final ScrollController scrollController;

  const _CastTargetSheet({
    required this.stream,
    required this.scrollController,
  });

  @override
  State<_CastTargetSheet> createState() => _CastTargetSheetState();
}

class _CastTargetSheetState extends State<_CastTargetSheet> {
  final _targets = <CastTarget>[];
  StreamSubscription<CastTarget>? _sub;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen(
      (target) {
        if (mounted) setState(() => _targets.add(target));
      },
      onDone: () {
        if (mounted) setState(() => _done = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = !_done;

    if (loading && _targets.isEmpty) {
      return const SafeArea(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_done && _targets.isEmpty) {
      final l10n = AppLocalizations.of(context);
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb;
      final message = isIOS
          ? l10n.noRemoteDevicesIos
          : l10n.noRemoteDevices;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Material(
        color: Theme.of(context).bottomSheetTheme.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView.separated(
                controller: widget.scrollController,
                itemCount: _targets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final target = _targets[index];
                  return ListTile(
                    leading: Icon(_iconForTargetKind(target.kind)),
                    title: Text(target.title),
                    subtitle: target.subtitle.isNotEmpty ? Text(target.subtitle) : null,
                    onTap: () => Navigator.of(context).pop(target),
                  );
                },
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForTargetKind(CastTargetKind kind) {
  return switch (kind) {
    CastTargetKind.jellyfinSession => Icons.cast,
    CastTargetKind.googleCast => Icons.cast_connected,
    CastTargetKind.airPlay => Icons.airplay,
    CastTargetKind.dlna => Icons.router,
  };
}
