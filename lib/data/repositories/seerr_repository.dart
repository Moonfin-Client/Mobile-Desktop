import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../auth/repositories/session_repository.dart';
import '../services/seerr/seerr_api_models.dart';
import '../services/seerr/seerr_cookie_jar.dart';
import '../services/seerr/seerr_http_client.dart';
import '../services/seerr/seerr_models.dart';

class SeerrRepository {
  final PreferenceStore _store;
  final SessionRepository _session;
  final SeerrCookieJar _cookieJar;
  final MediaServerClient _client;

  SeerrHttpClient? _httpClient;
  bool _initialized = false;
  String? _lastUserId;

  bool _isAvailable = false;
  bool _isMoonfinMode = false;

  int _lastSessionCheckMs = 0;
  bool _lastSessionValid = false;
  static const _sessionCacheDurationMs = 5 * 60 * 1000;

  bool get isAvailable => _isAvailable;
  bool get isMoonfinMode => _isMoonfinMode;

  SeerrRepository(this._store, this._session, this._cookieJar, this._client);

  String _userKey(String key) {
    final uid = _session.activeUserId ?? '';
    return 'seerr_${key}_$uid';
  }

  String get _enabledKey => _userKey('enabled');
  String get _serverUrlKey => _userKey('server_url');
  String get _apiKeyKey => _userKey('api_key');
  String get _authMethodKey => _userKey('auth_method');
  String get _moonfinModeKey => _userKey('moonfin_mode');
  String get _moonfinDisplayNameKey => _userKey('moonfin_display_name');
  String get _moonfinUserIdKey => _userKey('moonfin_user_id');
  String get _lastConnectionSuccessKey => _userKey('last_connection_success');

  void _invalidateSessionCache() {
    _lastSessionCheckMs = 0;
    _lastSessionValid = false;
  }

  Future<void> ensureInitialized() async {
    final currentUserId = _session.activeUserId;

    if (_initialized && currentUserId != null && currentUserId != _lastUserId) {
      _initialized = false;
      _httpClient?.close();
      _httpClient = null;
      _isAvailable = false;
      _invalidateSessionCache();
    }

    if (_initialized && _httpClient == null) {
      _initialized = false;
    }

    if (_initialized) return;
    if (_httpClient != null) {
      _initialized = true;
      return;
    }

    try {
      if (currentUserId == null) {
        _isAvailable = false;
        _initialized = true;
        return;
      }

      _cookieJar.switchToUser(currentUserId);
      _lastUserId = currentUserId;

      final enabled = _store.getBool(_enabledKey) ?? false;
      final serverUrl = _store.getString(_serverUrlKey) ?? '';
      final apiKey = _store.getString(_apiKeyKey) ?? '';
      final authMethod = _store.getString(_authMethodKey) ?? '';
      final moonfinMode = _store.getBool(_moonfinModeKey) ?? false;

      if (moonfinMode) {
        await _initMoonfinMode();
        _initialized = true;
        return;
      }

      if (enabled && serverUrl.isNotEmpty) {
        if (apiKey.isNotEmpty) {
          _initClient(serverUrl, apiKey);
          _isAvailable = true;
        } else if (authMethod == 'jellyfin' || authMethod == 'local') {
          _initClient(serverUrl, '');
          final valid = await isSessionValid();
          _isAvailable = valid;
        }
      } else {
        _isAvailable = false;
      }
      _initialized = true;
    } catch (_) {
      _isAvailable = false;
      _initialized = true;
    }
  }

  Future<void> _initMoonfinMode() async {
    final baseUrl = _client.baseUrl;
    final token = _client.accessToken;
    if (baseUrl.isEmpty || token == null || token.isEmpty) {
      _isAvailable = false;
      return;
    }

    final proxyConfig = MoonfinProxyConfig(
      jellyfinBaseUrl: baseUrl,
      jellyfinToken: token,
    );

    _initClient(baseUrl, '');
    _httpClient!.proxyConfig = proxyConfig;
    _isMoonfinMode = true;

    try {
      final status = await _httpClient!.getMoonfinStatus();
      _isAvailable = status.authenticated;
    } catch (_) {
      _isAvailable = false;
    }
  }

  void _initClient(String serverUrl, String apiKey) {
    _httpClient?.close();
    _httpClient = SeerrHttpClient(
      baseUrl: serverUrl,
      apiKey: apiKey,
      cookieJar: _cookieJar,
    );
  }

  Future<T> _withClient<T>(Future<T> Function(SeerrHttpClient client) fn) async {
    await ensureInitialized();
    final client = _httpClient;
    if (client == null) throw StateError('Seerr HTTP client not initialized');
    return fn(client);
  }

  Future<bool> testConnection() => _withClient((c) => c.testConnection());

  Future<bool> isSessionValid() async {
    try {
      await _withClient((c) => c.getCurrentUser());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isSessionValidCached() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if ((now - _lastSessionCheckMs) < _sessionCacheDurationMs && _lastSessionValid) {
      return true;
    }
    final valid = await isSessionValid();
    _lastSessionCheckMs = DateTime.now().millisecondsSinceEpoch;
    _lastSessionValid = valid;
    return valid;
  }

  Future<SeerrUser> getCurrentUser() => _withClient(
      (c) async => SeerrUser.fromJson(await c.getCurrentUser()));

  Future<SeerrUser> loginWithJellyfin({
    required String username,
    required String password,
    required String jellyfinUrl,
    required String seerrUrl,
  }) async {
    final userId = _session.activeUserId;
    if (userId == null) throw StateError('No active user');
    _cookieJar.switchToUser(userId);

    await _store.setString(_authMethodKey, 'jellyfin');
    await _store.setString(_serverUrlKey, seerrUrl);

    _initClient(seerrUrl, '');
    final data = await _httpClient!.loginJellyfin(username, password, jellyfinUrl);
    final user = SeerrUser.fromJson(data);

    await _store.setBool(_enabledKey, true);
    await _store.setBool(_lastConnectionSuccessKey, true);
    _isAvailable = true;
    _lastUserId = userId;

    return user;
  }

  Future<SeerrUser> loginLocal({
    required String email,
    required String password,
    required String seerrUrl,
  }) async {
    final userId = _session.activeUserId;
    if (userId == null) throw StateError('No active user');
    _cookieJar.switchToUser(userId);

    await _store.setString(_authMethodKey, 'local');
    await _store.setString(_serverUrlKey, seerrUrl);

    _initClient(seerrUrl, '');
    final data = await _httpClient!.loginLocal(email, password);
    final user = SeerrUser.fromJson(data);

    await _store.setBool(_enabledKey, true);
    await _store.setBool(_lastConnectionSuccessKey, true);
    _isAvailable = true;
    _lastUserId = userId;

    return user;
  }

  Future<SeerrUser> loginWithApiKey({
    required String apiKey,
    required String seerrUrl,
  }) async {
    final userId = _session.activeUserId;
    if (userId == null) throw StateError('No active user');
    _cookieJar.switchToUser(userId);

    await _store.setString(_authMethodKey, 'apikey');
    await _store.setString(_apiKeyKey, apiKey);
    await _store.setString(_serverUrlKey, seerrUrl);

    _initClient(seerrUrl, apiKey);
    final data = await _httpClient!.getCurrentUser();
    final user = SeerrUser.fromJson(data);

    await _store.setBool(_enabledKey, true);
    await _store.setBool(_lastConnectionSuccessKey, true);
    _isAvailable = true;
    _lastUserId = userId;

    return user;
  }

  Future<String> regenerateApiKey() async {
    final key = await _withClient((c) => c.regenerateApiKey());
    await _store.setString(_apiKeyKey, key);
    return key;
  }

  Future<MoonfinStatusResponse> configureWithMoonfin({
    required String jellyfinBaseUrl,
    required String jellyfinToken,
  }) async {
    final userId = _session.activeUserId;
    if (userId == null) throw StateError('No active user');
    _cookieJar.switchToUser(userId);
    _lastUserId = userId;

    _initClient(jellyfinBaseUrl, '');
    _httpClient!.proxyConfig = MoonfinProxyConfig(
      jellyfinBaseUrl: jellyfinBaseUrl,
      jellyfinToken: jellyfinToken,
    );

    final status = await _httpClient!.getMoonfinStatus();

    await _store.setBool(_moonfinModeKey, true);
    await _store.setBool(_enabledKey, true);
    await _store.setString(_authMethodKey, 'moonfin');
    _isMoonfinMode = true;

    if (status.authenticated) {
      if (status.jellyseerrUserId != null) {
        await _store.setString(_moonfinUserIdKey, status.jellyseerrUserId.toString());
      }
      _isAvailable = true;
    } else {
      _isAvailable = false;
    }

    return status;
  }

  Future<MoonfinStatusResponse> checkMoonfinStatus() =>
      _withClient((c) => c.getMoonfinStatus());

  Future<MoonfinLoginResponse> loginWithMoonfin({
    required String username,
    required String password,
    String authType = 'jellyfin',
  }) async {
    await ensureInitialized();
    final client = _httpClient;
    if (client == null || !client.isProxyMode) {
      throw StateError('Not in Moonfin proxy mode');
    }

    final response = await client.moonfinLogin(
      username: username,
      password: password,
      authType: authType,
    );

    if (response.success) {
      await _store.setString(
        _moonfinDisplayNameKey,
        response.displayName ?? '',
      );
      await _store.setString(
        _moonfinUserIdKey,
        response.jellyseerrUserId?.toString() ?? '',
      );
      _isAvailable = true;
    }

    return response;
  }

  Future<void> logoutMoonfin() async {
    final client = _httpClient;
    if (client != null && client.isProxyMode) {
      try {
        await client.moonfinLogout();
      } catch (_) {}
    }

    await _store.setBool(_moonfinModeKey, false);
    await _store.setString(_moonfinDisplayNameKey, '');
    await _store.setString(_moonfinUserIdKey, '');
    await _store.setBool(_enabledKey, false);
    await _store.setString(_authMethodKey, '');

    _httpClient?.proxyConfig = null;
    _isMoonfinMode = false;
    _isAvailable = false;
    _initialized = false;
  }

  Future<SeerrDiscoverPage> getTrending({int limit = 20, int offset = 0}) =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getTrending(limit: limit, offset: offset)));

  Future<SeerrDiscoverPage> getTrendingMovies({int limit = 20, int offset = 0}) =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getTrendingMovies(limit: limit, offset: offset)));

  Future<SeerrDiscoverPage> getTrendingTv({int limit = 20, int offset = 0}) =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getTrendingTv(limit: limit, offset: offset)));

  Future<SeerrDiscoverPage> getTopMovies({int limit = 20, int offset = 0}) =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getTopMovies(limit: limit, offset: offset)));

  Future<SeerrDiscoverPage> getTopTv({int limit = 20, int offset = 0}) =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getTopTv(limit: limit, offset: offset)));

  Future<SeerrDiscoverPage> getUpcomingMovies() =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getUpcomingMovies()));

  Future<SeerrDiscoverPage> getUpcomingTv() =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getUpcomingTv()));

  Future<SeerrDiscoverPage> discoverMovies({
    int page = 1,
    String sortBy = 'popularity.desc',
    int? genre,
    int? studio,
    int? keywords,
    String language = 'en',
  }) =>
      _withClient((c) async => SeerrDiscoverPage.fromJson(
          await c.discoverMovies(
            page: page,
            sortBy: sortBy,
            genre: genre,
            studio: studio,
            keywords: keywords,
            language: language,
          )));

  Future<SeerrDiscoverPage> discoverTv({
    int page = 1,
    String sortBy = 'popularity.desc',
    int? genre,
    int? network,
    int? keywords,
    String language = 'en',
  }) =>
      _withClient((c) async => SeerrDiscoverPage.fromJson(
          await c.discoverTv(
            page: page,
            sortBy: sortBy,
            genre: genre,
            network: network,
            keywords: keywords,
            language: language,
          )));

  Future<SeerrDiscoverPage> search(
    String query, {
    String? mediaType,
    int limit = 20,
    int offset = 0,
  }) =>
      _withClient((c) async => SeerrDiscoverPage.fromJson(
          await c.search(query, mediaType: mediaType, limit: limit, offset: offset)));

  Future<SeerrMovieDetails> getMovieDetails(int tmdbId) =>
      _withClient((c) async =>
          SeerrMovieDetails.fromJson(await c.getMovieDetails(tmdbId)));

  Future<SeerrTvDetails> getTvDetails(int tmdbId) =>
      _withClient((c) async =>
          SeerrTvDetails.fromJson(await c.getTvDetails(tmdbId)));

  Future<SeerrDiscoverPage> getSimilarMovies(int tmdbId, {int page = 1}) =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getSimilarMovies(tmdbId, page: page)));

  Future<SeerrDiscoverPage> getSimilarTv(int tmdbId, {int page = 1}) =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getSimilarTv(tmdbId, page: page)));

  Future<SeerrDiscoverPage> getMovieRecommendations(int tmdbId, {int page = 1}) =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getMovieRecommendations(tmdbId, page: page)));

  Future<SeerrDiscoverPage> getTvRecommendations(int tmdbId, {int page = 1}) =>
      _withClient((c) async =>
          SeerrDiscoverPage.fromJson(await c.getTvRecommendations(tmdbId, page: page)));

  Future<SeerrPersonDetails> getPersonDetails(int personId) =>
      _withClient((c) async =>
          SeerrPersonDetails.fromJson(await c.getPersonDetails(personId)));

  Future<SeerrPersonCombinedCredits> getPersonCombinedCredits(int personId) =>
      _withClient((c) async =>
          SeerrPersonCombinedCredits.fromJson(await c.getPersonCombinedCredits(personId)));

  Future<List<SeerrGenre>> getGenreSliderMovies() =>
      _withClient((c) async => (await c.getGenreSliderMovies())
          .cast<Map<String, dynamic>>()
          .map(SeerrGenre.fromJson)
          .toList());

  Future<List<SeerrGenre>> getGenreSliderTv() =>
      _withClient((c) async => (await c.getGenreSliderTv())
          .cast<Map<String, dynamic>>()
          .map(SeerrGenre.fromJson)
          .toList());

  Future<SeerrRequestListResponse> getRequests({
    String? filter,
    int? requestedBy,
    int limit = 50,
    int offset = 0,
  }) =>
      _withClient((c) async => SeerrRequestListResponse.fromJson(
          await c.getRequests(
            filter: filter,
            requestedBy: requestedBy,
            limit: limit,
            offset: offset,
          )));

  Future<SeerrRequest> getRequest(int requestId) =>
      _withClient((c) async =>
          SeerrRequest.fromJson(await c.getRequest(requestId)));

  Future<SeerrRequest> createRequest({
    required int mediaId,
    required String mediaType,
    List<int>? seasons,
    bool allSeasons = false,
    bool is4k = false,
    int? profileId,
    String? rootFolder,
    int? serverId,
  }) =>
      _withClient((c) async => SeerrRequest.fromJson(
          await c.createRequest(
            mediaId: mediaId,
            mediaType: mediaType,
            seasons: seasons,
            allSeasons: allSeasons,
            is4k: is4k,
            profileId: profileId,
            rootFolder: rootFolder,
            serverId: serverId,
          )));

  Future<void> deleteRequest(int requestId) =>
      _withClient((c) => c.deleteRequest(requestId));

  Future<List<SeerrMedia>> getRecentlyAdded({int limit = 20}) =>
      _withClient((c) async {
        final data = await c.getRecentlyAdded(take: limit);
        final results = (data['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        return results.map(SeerrMedia.fromJson).toList();
      });

  Future<void> approveRequest(int requestId) =>
      _withClient((c) => c.approveRequest(requestId));

  Future<void> declineRequest(int requestId) =>
      _withClient((c) => c.declineRequest(requestId));

  Future<List<SeerrServiceServer>> getRadarrServers() =>
      _withClient((c) async => (await c.getRadarrServers())
          .cast<Map<String, dynamic>>()
          .map(SeerrServiceServer.fromJson)
          .toList());

  Future<SeerrServiceServerDetails> getRadarrServerDetails(int serverId) =>
      _withClient((c) async =>
          SeerrServiceServerDetails.fromJson(await c.getRadarrServerDetails(serverId)));

  Future<List<SeerrServiceServer>> getSonarrServers() =>
      _withClient((c) async => (await c.getSonarrServers())
          .cast<Map<String, dynamic>>()
          .map(SeerrServiceServer.fromJson)
          .toList());

  Future<SeerrServiceServerDetails> getSonarrServerDetails(int serverId) =>
      _withClient((c) async =>
          SeerrServiceServerDetails.fromJson(await c.getSonarrServerDetails(serverId)));

  Future<List<SeerrRadarrSettings>> getRadarrSettings() =>
      _withClient((c) async => (await c.getRadarrSettings())
          .cast<Map<String, dynamic>>()
          .map(SeerrRadarrSettings.fromJson)
          .toList());

  Future<List<SeerrSonarrSettings>> getSonarrSettings() =>
      _withClient((c) async => (await c.getSonarrSettings())
          .cast<Map<String, dynamic>>()
          .map(SeerrSonarrSettings.fromJson)
          .toList());

  Future<SeerrStatus> getStatus() =>
      _withClient((c) => c.getStatus());

  Future<void> logout() async {
    if (_httpClient?.isProxyMode == true) {
      await logoutMoonfin();
      return;
    }

    await _store.setString(_serverUrlKey, '');
    await _store.setBool(_enabledKey, false);
    await _store.setString(_apiKeyKey, '');
    await _store.setString(_authMethodKey, '');

    _httpClient?.close();
    _httpClient = null;
    _initialized = false;
    _lastUserId = null;
    _isAvailable = false;
  }

  void close() {
    _httpClient?.close();
    _httpClient = null;
  }
}
