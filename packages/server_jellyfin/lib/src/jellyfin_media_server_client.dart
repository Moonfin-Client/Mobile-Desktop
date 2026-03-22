import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

import 'api/jellyfin_auth_api.dart';
import 'api/jellyfin_items_api.dart';
import 'api/jellyfin_playback_api.dart';
import 'api/jellyfin_image_api.dart';
import 'api/jellyfin_session_api.dart';
import 'api/jellyfin_system_api.dart';
import 'api/jellyfin_user_library_api.dart';
import 'api/jellyfin_user_views_api.dart';
import 'api/jellyfin_live_tv_api.dart';
import 'api/jellyfin_instant_mix_api.dart';
import 'api/jellyfin_display_preferences_api.dart';
import 'api/jellyfin_users_api.dart';
import 'api/jellyfin_admin_system_api.dart';
import 'api/jellyfin_admin_users_api.dart';
import 'api/jellyfin_admin_library_api.dart';
import 'api/jellyfin_admin_environment_api.dart';
import 'api/jellyfin_admin_tasks_api.dart';
import 'api/jellyfin_admin_plugins_api.dart';
import 'api/jellyfin_admin_devices_api.dart';
import 'api/jellyfin_admin_api_keys_api.dart';
import 'api/jellyfin_admin_backup_api.dart';
import 'api/jellyfin_admin_live_tv_api.dart';
import 'api/jellyfin_admin_items_api.dart';

class JellyfinMediaServerClient extends MediaServerClient {
  final Dio _dio;

  @override
  final DeviceInfo deviceInfo;

  JellyfinMediaServerClient({
    required String baseUrl,
    required this.deviceInfo,
  }) : _dio = Dio(BaseOptions(
         baseUrl: baseUrl,
         connectTimeout: const Duration(seconds: 30),
         receiveTimeout: const Duration(seconds: 30),
       )) {
    _baseUrl = baseUrl;
    configureServerDio(_dio);
    _setupInterceptors();
  }

  late String _baseUrl;
  String? _accessToken;
  String? _userId;

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = buildServerAuthorizationHeader(
          scheme: 'MediaBrowser',
          deviceInfo: deviceInfo,
          accessToken: _accessToken,
        );
        handler.next(options);
      },
    ));
  }

  @override
  ServerType get serverType => ServerType.jellyfin;

  @override
  String get baseUrl => _baseUrl;

  @override
  set baseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  @override
  String? get accessToken => _accessToken;

  @override
  set accessToken(String? token) => _accessToken = token;

  @override
  String? get userId => _userId;

  @override
  set userId(String? id) => _userId = id;

  @override
  late final AuthApi authApi = JellyfinAuthApi(_dio);

  @override
  late final ItemsApi itemsApi = JellyfinItemsApi(_dio);

  @override
  late final PlaybackApi playbackApi = JellyfinPlaybackApi(_dio, _baseUrl);

  @override
  late final ImageApi imageApi = JellyfinImageApi(_baseUrl);

  @override
  late final SessionApi sessionApi = JellyfinSessionApi(_dio);

  @override
  late final SystemApi systemApi = JellyfinSystemApi(_dio);

  @override
  late final UserLibraryApi userLibraryApi = JellyfinUserLibraryApi(_dio);

  @override
  late final UserViewsApi userViewsApi = JellyfinUserViewsApi(_dio);

  @override
  late final LiveTvApi liveTvApi = JellyfinLiveTvApi(_dio);

  @override
  late final InstantMixApi instantMixApi = JellyfinInstantMixApi(_dio);

  @override
  late final DisplayPreferencesApi displayPreferencesApi =
      JellyfinDisplayPreferencesApi(_dio);

  @override
  late final UsersApi usersApi = JellyfinUsersApi(_dio);

  @override
  late final AdminSystemApi adminSystemApi = JellyfinAdminSystemApi(_dio);

  @override
  late final AdminUsersApi adminUsersApi = JellyfinAdminUsersApi(_dio);

  @override
  late final AdminLibraryApi adminLibraryApi = JellyfinAdminLibraryApi(_dio);

  @override
  late final AdminEnvironmentApi adminEnvironmentApi =
      JellyfinAdminEnvironmentApi(_dio);

  @override
  late final AdminTasksApi adminTasksApi = JellyfinAdminTasksApi(_dio);

  @override
  late final AdminPluginsApi adminPluginsApi = JellyfinAdminPluginsApi(_dio);

  @override
  late final AdminDevicesApi adminDevicesApi = JellyfinAdminDevicesApi(_dio);

  @override
  late final AdminApiKeysApi adminApiKeysApi = JellyfinAdminApiKeysApi(_dio);

  @override
  late final AdminBackupApi adminBackupApi = JellyfinAdminBackupApi(_dio);

  @override
  late final AdminLiveTvApi adminLiveTvApi = JellyfinAdminLiveTvApi(_dio);

  @override
  late final AdminItemsApi adminItemsApi = JellyfinAdminItemsApi(_dio);

  @override
  void dispose() {
    _dio.close();
  }
}
