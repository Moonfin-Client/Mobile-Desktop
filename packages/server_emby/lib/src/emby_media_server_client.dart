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

class EmbyMediaServerClient extends MediaServerClient {
  final Dio _dio;

  @override
  final DeviceInfo deviceInfo;

  EmbyMediaServerClient({
    required String baseUrl,
    required this.deviceInfo,
  }) : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _baseUrl = baseUrl;
    _setupInterceptors();
  }

  late String _baseUrl;
  String? _accessToken;
  String? _userId;

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final authHeader = StringBuffer(
          'Emby Client="${deviceInfo.appName}", '
          'Device="${deviceInfo.name}", '
          'DeviceId="${deviceInfo.id}", '
          'Version="${deviceInfo.appVersion}"',
        );
        if (_accessToken != null) {
          authHeader.write(', Token="$_accessToken"');
        }
        options.headers['Authorization'] = authHeader.toString();
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
  void dispose() {
    _dio.close();
  }
}
