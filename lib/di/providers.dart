import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

import '../data/services/media_server_client_factory.dart';
import '../data/services/socket_handler.dart';
import '../preference/user_preferences.dart';
import 'injection.dart';

final deviceInfoProvider = Provider<DeviceInfo>(
  (_) => getIt<DeviceInfo>(),
);

final mediaServerClientFactoryProvider = Provider<MediaServerClientFactory>(
  (_) => getIt<MediaServerClientFactory>(),
);

final activeServerClientProvider =
    StateProvider<MediaServerClient?>((_) => null);

final playbackManagerProvider = Provider<PlaybackManager>(
  (_) => getIt<PlaybackManager>(),
);

final socketHandlerProvider = Provider<SocketHandler>(
  (_) => getIt<SocketHandler>(),
);

final userPreferencesProvider = Provider<UserPreferences>(
  (_) => getIt<UserPreferences>(),
);
