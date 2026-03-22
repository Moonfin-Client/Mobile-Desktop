import '../../models/aggregated_item.dart';
import 'cast_provider.dart';
import 'cast_target.dart';
import 'cast_transport_controls.dart';

class CastService {
  final List<CastProvider> _providers;
  CastTargetKind? _activeKind;

  CastService(this._providers);

  CastTargetKind? get activeKind => _activeKind;

  void setActiveKind(CastTargetKind? kind) {
    _activeKind = kind;
  }

  Future<List<CastTarget>> discoverTargets(AggregatedItem item) async {
    final all = <CastTarget>[];
    for (final provider in _providers) {
      try {
        final targets = await provider.discoverTargets(item);
        all.addAll(targets);
      } catch (_) {
      }
    }
    return all;
  }

  Future<void> playToTarget(
    CastTarget target, {
    required AggregatedItem item,
    int? startPositionTicks,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final provider = _providers.firstWhere(
      (p) => p.supportedKinds.contains(target.kind),
      orElse: () => throw StateError('No cast provider found for target'),
    );
    await provider.playToTarget(
      target,
      item: item,
      startPositionTicks: startPositionTicks,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );

    _activeKind = target.kind;
  }

  Future<void> play(CastTargetKind kind) async {
    final provider = _controlProviderForKind(kind);
    await provider.play(kind);
  }

  Future<void> pause(CastTargetKind kind) async {
    final provider = _controlProviderForKind(kind);
    await provider.pause(kind);
  }

  Future<void> seek(CastTargetKind kind, {required int positionTicks}) async {
    final provider = _controlProviderForKind(kind);
    await provider.seek(kind, positionTicks: positionTicks);
  }

  Future<void> stop(CastTargetKind kind) async {
    final provider = _controlProviderForKind(kind);
    await provider.stop(kind);
    if (_activeKind == kind) {
      _activeKind = null;
    }
  }

  CastTransportControls _controlProviderForKind(CastTargetKind kind) {
    final provider = _providers.whereType<CastTransportControls>().firstWhere(
      (p) => p.controllableKinds.contains(kind),
      orElse: () => throw UnsupportedError('No transport controls for cast kind: $kind'),
    );

    return provider;
  }
}
