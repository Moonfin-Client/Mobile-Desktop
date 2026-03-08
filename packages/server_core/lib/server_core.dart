/// Server core abstraction layer.
///
/// Provides abstract interfaces for media server communication,
/// supporting multiple backends (Jellyfin, Emby).
library;

export 'src/media_server_client.dart';
export 'src/models/server_type.dart';
export 'src/models/device_info.dart';
export 'src/models/enums.dart';
export 'src/models/server_models.dart';
export 'src/models/playback_models.dart';
export 'src/models/system_models.dart';
export 'src/models/websocket_models.dart';
export 'src/api/auth_api.dart';
export 'src/api/items_api.dart';
export 'src/api/playback_api.dart';
export 'src/api/image_api.dart';
export 'src/api/session_api.dart';
export 'src/api/system_api.dart';
export 'src/api/user_library_api.dart';
export 'src/api/user_views_api.dart';
export 'src/api/live_tv_api.dart';
export 'src/api/instant_mix_api.dart';
export 'src/api/display_preferences_api.dart';
export 'src/feature/feature_detector.dart';
