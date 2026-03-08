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

  _getIt.registerLazySingleton<MediaServerClient>(
    () => throw StateError(
      'MediaServerClient not configured. '
      'Call setServerClient() after server selection.',
    ),
  );
}

void setServerClient(MediaServerClient client) {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<MediaServerClient>()) {
    getIt.unregister<MediaServerClient>();
  }
  getIt.registerSingleton<MediaServerClient>(client);
}
