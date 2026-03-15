import 'package:get_it/get_it.dart';
import 'package:playback_core/playback_core.dart';
import 'package:playback_jellyfin/playback_jellyfin.dart';
import 'package:playback_emby/playback_emby.dart';
import 'package:server_core/server_core.dart';

import '../../playback/media_kit_player_backend.dart';
import '../../platform/pip_service.dart';
import '../../preference/user_preferences.dart';

final _getIt = GetIt.instance;

void registerPlaybackModule() {
  final backend = MediaKitPlayerBackend(_getIt<UserPreferences>());
  _getIt.registerSingleton<MediaKitPlayerBackend>(backend);
  _getIt.registerSingleton<PlayerBackend>(backend);

  final manager = PlaybackManager();
  manager.setBackend(backend);
  _getIt.registerSingleton<PlaybackManager>(manager);

  _getIt.registerSingleton<PipService>(PipService());
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
