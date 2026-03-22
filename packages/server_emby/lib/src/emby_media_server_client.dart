import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

import 'api/emby_auth_api.dart';
import 'api/emby_items_api.dart';
import 'api/emby_playback_api.dart';
import 'api/emby_image_api.dart';
import 'api/emby_session_api.dart';
import 'api/emby_system_api.dart';
import 'api/emby_user_library_api.dart';
import 'api/emby_user_views_api.dart';
import 'api/emby_live_tv_api.dart';
import 'api/emby_instant_mix_api.dart';
import 'api/emby_display_preferences_api.dart';
import 'api/emby_users_api.dart';

class EmbyMediaServerClient extends MediaServerClient {
  final Dio _dio;

  @override
  final DeviceInfo deviceInfo;

  EmbyMediaServerClient({
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
          scheme: 'Emby',
          deviceInfo: deviceInfo,
          accessToken: _accessToken,
        );
        handler.next(options);
      },
    ));
  }

  String _requireUserId() {
    final id = _userId;
    if (id == null) throw StateError('userId not configured');
    return id;
  }

  @override
  ServerType get serverType => ServerType.emby;

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
  late final AuthApi authApi = EmbyAuthApi(_dio);

  @override
  late final ItemsApi itemsApi = EmbyItemsApi(_dio, _requireUserId);

  @override
  late final PlaybackApi playbackApi =
      EmbyPlaybackApi(_dio, () => _baseUrl);

  @override
  late final ImageApi imageApi =
      EmbyImageApi(() => _baseUrl, () => _accessToken);

  @override
  late final SessionApi sessionApi = EmbySessionApi(_dio);

  @override
  late final SystemApi systemApi = EmbySystemApi(_dio);

  @override
  late final UserLibraryApi userLibraryApi =
      EmbyUserLibraryApi(_dio, _requireUserId);

  @override
  late final EmbyUserViewsApi userViewsApi =
      EmbyUserViewsApi(_dio, _requireUserId);

  @override
  late final LiveTvApi liveTvApi = EmbyLiveTvApi(_dio);

  @override
  late final InstantMixApi instantMixApi = EmbyInstantMixApi(_dio);

  @override
  late final EmbyDisplayPreferencesApi displayPreferencesApi =
      EmbyDisplayPreferencesApi(_dio);

  @override
  late final UsersApi usersApi = EmbyUsersApi(_dio, _requireUserId);

  @override
  AdminSystemApi get adminSystemApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminUsersApi get adminUsersApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminLibraryApi get adminLibraryApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminEnvironmentApi get adminEnvironmentApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminTasksApi get adminTasksApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminPluginsApi get adminPluginsApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminDevicesApi get adminDevicesApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminApiKeysApi get adminApiKeysApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminBackupApi get adminBackupApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminLiveTvApi get adminLiveTvApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  AdminItemsApi get adminItemsApi =>
      throw UnsupportedError('Admin not supported on Emby yet');

  @override
  void dispose() {
    _dio.close();
  }
}
