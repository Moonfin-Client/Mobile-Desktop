import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../data/services/media_server_client_factory.dart';

final _getIt = GetIt.instance;

void registerServerModule() {
  _getIt.registerLazySingleton<MediaServerClientFactory>(
    () => MediaServerClientFactory(
      deviceInfo: _getIt<DeviceInfo>(),
    ),
  );
}

void setActiveServerClient(MediaServerClient client) {
  if (_getIt.isRegistered<MediaServerClient>()) {
    _getIt.unregister<MediaServerClient>();
  }
  _getIt.registerSingleton<MediaServerClient>(client);
}
