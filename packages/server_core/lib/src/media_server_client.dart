import 'models/server_type.dart';
import 'models/device_info.dart';
import 'api/auth_api.dart';
import 'api/items_api.dart';
import 'api/playback_api.dart';
import 'api/image_api.dart';
import 'api/session_api.dart';
import 'api/system_api.dart';
import 'api/user_library_api.dart';
import 'api/user_views_api.dart';
import 'api/live_tv_api.dart';
import 'api/instant_mix_api.dart';
import 'api/display_preferences_api.dart';
import 'api/users_api.dart';
import 'api/admin_system_api.dart';
import 'api/admin_users_api.dart';
import 'api/admin_library_api.dart';
import 'api/admin_environment_api.dart';
import 'api/admin_tasks_api.dart';
import 'api/admin_plugins_api.dart';
import 'api/admin_devices_api.dart';
import 'api/admin_api_keys_api.dart';
import 'api/admin_backup_api.dart';
import 'api/admin_live_tv_api.dart';
import 'api/admin_items_api.dart';

abstract class MediaServerClient {
  ServerType get serverType;
  DeviceInfo get deviceInfo;

  String get baseUrl;
  set baseUrl(String url);

  String? get accessToken;
  set accessToken(String? token);

  String? get userId;
  set userId(String? id);

  AuthApi get authApi;
  ItemsApi get itemsApi;
  PlaybackApi get playbackApi;
  ImageApi get imageApi;
  SessionApi get sessionApi;
  SystemApi get systemApi;
  UserLibraryApi get userLibraryApi;
  UserViewsApi get userViewsApi;
  LiveTvApi get liveTvApi;
  InstantMixApi get instantMixApi;
  DisplayPreferencesApi get displayPreferencesApi;
  UsersApi get usersApi;
  AdminSystemApi get adminSystemApi;
  AdminUsersApi get adminUsersApi;
  AdminLibraryApi get adminLibraryApi;
  AdminEnvironmentApi get adminEnvironmentApi;
  AdminTasksApi get adminTasksApi;
  AdminPluginsApi get adminPluginsApi;
  AdminDevicesApi get adminDevicesApi;
  AdminApiKeysApi get adminApiKeysApi;
  AdminBackupApi get adminBackupApi;
  AdminLiveTvApi get adminLiveTvApi;
  AdminItemsApi get adminItemsApi;

  void dispose();
}
