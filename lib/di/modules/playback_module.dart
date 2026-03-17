import 'package:get_it/get_it.dart';
import 'package:playback_core/playback_core.dart';
import 'package:playback_jellyfin/playback_jellyfin.dart';
import 'package:playback_emby/playback_emby.dart';
import 'package:server_core/server_core.dart';

import '../../data/models/aggregated_item.dart';
import '../../data/repositories/offline_repository.dart';
import '../../data/services/media_server_client_factory.dart';
import '../../data/services/offline_playback_tracker.dart';
import '../../playback/media_kit_player_backend.dart';
import '../../playback/offline_stream_resolver.dart';
import '../../platform/pip_service.dart';
import '../../preference/user_preferences.dart';

final _getIt = GetIt.instance;

void registerPlaybackModule() {
  final backend = MediaKitPlayerBackend(_getIt<UserPreferences>());
  _getIt.registerSingleton<MediaKitPlayerBackend>(backend);
  _getIt.registerSingleton<PlayerBackend>(backend);

  final manager = PlaybackManager();
  manager.setBackend(backend);
  manager.setResolverConfigurator(_ensureResolverForItem);
  _getIt.registerSingleton<PlaybackManager>(manager);

  _getIt.registerSingleton<PipService>(PipService());

  _getIt.registerLazySingleton<OfflineStreamResolver>(
    () => OfflineStreamResolver(_getIt<OfflineRepository>()),
  );
  _getIt.registerLazySingleton<OfflinePlaybackTracker>(
    () => OfflinePlaybackTracker(_getIt<OfflineRepository>()),
  );
}

void setActiveStreamResolver(MediaServerClient client) {
  if (_getIt.isRegistered<MediaStreamResolver>()) {
    _getIt.unregister<MediaStreamResolver>();
  }
  if (_getIt.isRegistered<PlayerService>()) {
    _getIt.unregister<PlayerService>();
  }

  final (MediaStreamResolver resolver, PlayerService service) =
      switch (client.serverType) {
    ServerType.jellyfin => () {
      final p = JellyfinPlugin(client);
      return (p.createStreamResolver(), p.createPlaySessionService());
    }(),
    ServerType.emby => () {
      final p = EmbyPlugin(client);
      return (p.createStreamResolver(), p.createPlaySessionService());
    }(),
  };

  _getIt.registerSingleton<MediaStreamResolver>(resolver);
  _getIt.registerSingleton<PlayerService>(service);

  final manager = _getIt<PlaybackManager>();
  manager.setResolver(resolver);
  manager.setPlayerService(service);
}

Future<void> _ensureResolverForItem(dynamic item) async {
  if (item is! AggregatedItem) return;
  final factory = _getIt<MediaServerClientFactory>();
  final client = factory.getClientIfExists(item.serverId);
  if (client == null || identical(client, _getIt<MediaServerClient>())) return;
  setActiveStreamResolver(client);
}
