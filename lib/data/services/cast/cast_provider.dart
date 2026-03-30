import '../../models/aggregated_item.dart';
import 'cast_target.dart';

abstract class CastProvider {
  Set<CastTargetKind> get supportedKinds;

  Future<List<CastTarget>> discoverTargets(AggregatedItem item);

  Future<void> playToTarget(
    CastTarget target, {
    required AggregatedItem item,
    List<AggregatedItem>? queueItems,
    int? startPositionTicks,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  });
}
