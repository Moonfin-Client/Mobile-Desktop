import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../data/services/download_notification_service.dart';
import '../../data/services/download_service.dart';
import '../../data/services/media_server_client_factory.dart';

final _getIt = GetIt.instance;

void registerServerModule() {
  _getIt.registerLazySingleton<MediaServerClientFactory>(
    () => MediaServerClientFactory(
      deviceInfo: _getIt<DeviceInfo>(),
    ),
  );

  if (!_getIt.isRegistered<DownloadNotificationService>()) {
    _getIt.registerLazySingleton<DownloadNotificationService>(
      () => DownloadNotificationService(),
    );
  }
}

void setActiveServerClient(MediaServerClient client) {
  if (_getIt.isRegistered<MediaServerClient>()) {
    _getIt.unregister<MediaServerClient>();
  }
  _getIt.registerSingleton<MediaServerClient>(client);

  if (_getIt.isRegistered<DownloadService>()) {
    _getIt.unregister<DownloadService>();
  }
  final downloadService = DownloadService(
    client,
    _getIt<DownloadNotificationService>(),
  );
  _getIt.registerSingleton<DownloadService>(downloadService);

  downloadService.recoverIncompleteDownloads();
}
