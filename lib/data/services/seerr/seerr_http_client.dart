import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import 'seerr_cookie_jar.dart';
import 'seerr_models.dart';

class SeerrHttpClient {
  final String baseUrl;
  final String apiKey;
  final SeerrCookieJar cookieJar;

  MoonfinProxyConfig? proxyConfig;

  bool get isProxyMode => proxyConfig != null;

  late final Dio _dio;

  SeerrHttpClient({
    required this.baseUrl,
    required this.apiKey,
    required this.cookieJar,
    this.proxyConfig,
  }) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      followRedirects: true,
      validateStatus: (_) => true,
    ));

    _dio.interceptors.add(CookieManager(cookieJar));
    _dio.interceptors.add(_ProxyUnwrapInterceptor());
  }

  static String _trimSlash(String path) =>
      path.startsWith('/') ? path.substring(1) : path;

  String _apiUrl(String path) {
    final proxy = proxyConfig;
    if (proxy != null) {
      return '${proxy.jellyfinBaseUrl}/Moonfin/Jellyseerr/Api/${_trimSlash(path)}';
    }
    return '$baseUrl/api/v1/${_trimSlash(path)}';
  }

  String _moonfinUrl(String path) {
    final proxy = proxyConfig;
    if (proxy == null) throw StateError('Moonfin proxy not configured');
    return '${proxy.jellyfinBaseUrl}/Moonfin/Jellyseerr/${_trimSlash(path)}';
  }

  Options _authOptions([Options? existing]) {
    final headers = <String, dynamic>{};
    final proxy = proxyConfig;
    if (proxy != null) {
      headers['Authorization'] = 'MediaBrowser Token="${proxy.jellyfinToken}"';
    } else if (apiKey.isNotEmpty) {
      headers['X-Api-Key'] = apiKey;
    }

    if (existing != null) {
      return existing.copyWith(headers: {...?existing.headers, ...headers});
    }
    return Options(headers: headers);
  }

  Options _authJsonOptions([Options? existing]) {
    return _authOptions(existing).copyWith(
      contentType: Headers.jsonContentType,
    );
  }

  Future<String?> _fetchCsrfToken(String endpoint) async {
    if (isProxyMode) return null;
    try {
      await _dio.get(
        '$baseUrl$endpoint',
        options: _authOptions(),
      );
      return cookieJar.getCsrfToken(Uri.parse(baseUrl).host);
    } catch (e) {
      debugPrint('[Seerr] CSRF fetch failed (non-critical): $e');
      return null;
    }
  }

  Options _withCsrf(String? csrfToken, [Options? base]) {
    final options = base ?? _authJsonOptions();
    if (csrfToken == null) return options;
    return options.copyWith(headers: {
      ...?options.headers,
      'X-CSRF-Token': csrfToken,
      'X-XSRF-TOKEN': csrfToken,
    });
  }

  void _requireSuccess(Response response, String context) {
    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! > 299) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: '$context: HTTP ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> loginLocal(String email, String password) async {
    await cookieJar.deleteAll();
    final csrfToken = await _fetchCsrfToken('/api/v1/auth/local');

    var url = _apiUrl('auth/local');
    var response = await _dio.post(
      url,
      data: {'email': email, 'password': password},
      options: _withCsrf(csrfToken),
    );

    if (response.statusCode == 308) {
      final location = response.headers['location']?.first;
      if (location != null && location.startsWith('https://') && baseUrl.startsWith('http://')) {
        response = await _dio.post(
          location,
          data: {'email': email, 'password': password},
          options: _withCsrf(csrfToken),
        );
      } else {
        throw Exception('Server requires HTTPS but redirect location is invalid');
      }
    }

    _requireSuccess(response, 'loginLocal');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginJellyfin(
    String username,
    String password,
    String jellyfinUrl,
  ) async {
    await cookieJar.deleteAll();
    final csrfToken = await _fetchCsrfToken('/api/v1/auth/jellyfin');

    var url = _apiUrl('auth/jellyfin');
    var response = await _dio.post(
      url,
      data: {'username': username, 'password': password},
      options: _withCsrf(csrfToken),
    );

    if (response.statusCode == 308) {
      final location = response.headers['location']?.first;
      if (location != null && location.startsWith('https://') && baseUrl.startsWith('http://')) {
        url = location;
        response = await _dio.post(
          url,
          data: {'username': username, 'password': password},
          options: _withCsrf(csrfToken),
        );
      } else {
        throw Exception('Server requires HTTPS but redirect location is invalid');
      }
    }

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      response = await _dio.post(
        url,
        data: {
          'username': username,
          'password': password,
          'hostname': jellyfinUrl,
        },
        options: _withCsrf(csrfToken),
      );
      _requireSuccess(response, 'loginJellyfin (with hostname)');
      return response.data as Map<String, dynamic>;
    }

    _requireSuccess(response, 'loginJellyfin');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get(
      _apiUrl('auth/me'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getCurrentUser');
    return response.data as Map<String, dynamic>;
  }

  Future<String> regenerateApiKey() async {
    final csrfToken = await _fetchCsrfToken('/api/v1/settings/main/regenerate');
    final response = await _dio.post(
      _apiUrl('settings/main/regenerate'),
      options: _withCsrf(csrfToken, _authOptions()),
    );
    _requireSuccess(response, 'regenerateApiKey');
    return SeerrMainSettings.fromJson(response.data as Map<String, dynamic>).apiKey;
  }

  Future<Map<String, dynamic>> getRequests({
    String? filter,
    int? requestedBy,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      _apiUrl('request'),
      queryParameters: {
        'skip': offset,
        'take': limit,
        if (filter != null) 'filter': filter,
        if (requestedBy != null) 'requestedBy': requestedBy,
      },
      options: _authOptions(),
    );
    _requireSuccess(response, 'getRequests');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRequest(int requestId) async {
    final response = await _dio.get(
      _apiUrl('request/$requestId'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getRequest');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRequest({
    required int mediaId,
    required String mediaType,
    List<int>? seasons,
    bool allSeasons = false,
    bool is4k = false,
    int? profileId,
    String? rootFolder,
    int? serverId,
  }) async {
    final csrfToken = await _fetchCsrfToken('/api/v1/request');

    final body = <String, dynamic>{
      'mediaId': mediaId,
      'mediaType': mediaType,
      'is4k': is4k,
      if (profileId != null) 'profileId': profileId,
      if (rootFolder != null) 'rootFolder': rootFolder,
      if (serverId != null) 'serverId': serverId,
    };

    if (mediaType == 'tv') {
      if (allSeasons || seasons == null) {
        body['seasons'] = 'all';
      } else {
        body['seasons'] = seasons;
      }
    }

    final response = await _dio.post(
      _apiUrl('request'),
      data: body,
      options: _withCsrf(csrfToken),
    );
    _requireSuccess(response, 'createRequest');
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteRequest(int requestId) async {
    final csrfToken = await _fetchCsrfToken('/api/v1/request/$requestId');
    final response = await _dio.delete(
      _apiUrl('request/$requestId'),
      options: _withCsrf(csrfToken, _authOptions()),
    );
    _requireSuccess(response, 'deleteRequest');
  }

  Future<void> approveRequest(int requestId) async {
    await _postRequestAction(
      requestId,
      action: 'approve',
      opName: 'approveRequest',
    );
  }

  Future<void> declineRequest(int requestId) async {
    await _postRequestAction(
      requestId,
      action: 'decline',
      opName: 'declineRequest',
    );
  }

  Future<void> _postRequestAction(
    int requestId, {
    required String action,
    required String opName,
  }) async {
    final endpoint = 'request/$requestId/$action';
    final csrfToken = await _fetchCsrfToken('/api/v1/$endpoint');
    final response = await _dio.post(
      _apiUrl(endpoint),
      options: _withCsrf(csrfToken),
    );
    _requireSuccess(response, opName);
  }

  Future<Map<String, dynamic>> getRecentlyAdded({int take = 20}) async {
    final response = await _dio.get(
      _apiUrl('media'),
      queryParameters: {'filter': 'allavailable', 'sort': 'mediaAdded', 'take': take},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getRecentlyAdded');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTrending({int limit = 20, int offset = 0}) async {
    final page = (offset ~/ limit) + 1;
    final response = await _dio.get(
      _apiUrl('discover/trending'),
      queryParameters: {'page': page, 'language': 'en'},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getTrending');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTrendingMovies({int limit = 20, int offset = 0}) async {
    final page = (offset ~/ limit) + 1;
    final response = await _dio.get(
      _apiUrl('discover/movies'),
      queryParameters: {'page': page, 'language': 'en'},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getTrendingMovies');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTrendingTv({int limit = 20, int offset = 0}) async {
    final page = (offset ~/ limit) + 1;
    final response = await _dio.get(
      _apiUrl('discover/tv'),
      queryParameters: {'page': page, 'language': 'en'},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getTrendingTv');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTopMovies({int limit = 20, int offset = 0}) async {
    final response = await _dio.get(
      _apiUrl('discover/movies/top'),
      queryParameters: {'limit': limit, 'offset': offset},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getTopMovies');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTopTv({int limit = 20, int offset = 0}) async {
    final response = await _dio.get(
      _apiUrl('discover/tv/top'),
      queryParameters: {'limit': limit, 'offset': offset},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getTopTv');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUpcomingMovies() async {
    final response = await _dio.get(
      _apiUrl('discover/movies/upcoming'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getUpcomingMovies');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUpcomingTv() async {
    final response = await _dio.get(
      _apiUrl('discover/tv/upcoming'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getUpcomingTv');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> discoverMovies({
    int page = 1,
    String sortBy = 'popularity.desc',
    int? genre,
    int? studio,
    int? keywords,
    String language = 'en',
  }) async {
    final response = await _dio.get(
      _apiUrl('discover/movies'),
      queryParameters: {
        'page': page,
        'sortBy': sortBy,
        'language': language,
        if (genre != null) 'genre': genre,
        if (studio != null) 'studio': studio,
        if (keywords != null) 'keywords': keywords,
      },
      options: _authOptions(),
    );
    _requireSuccess(response, 'discoverMovies');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> discoverTv({
    int page = 1,
    String sortBy = 'popularity.desc',
    int? genre,
    int? network,
    int? keywords,
    String language = 'en',
  }) async {
    final response = await _dio.get(
      _apiUrl('discover/tv'),
      queryParameters: {
        'page': page,
        'sortBy': sortBy,
        'language': language,
        if (genre != null) 'genre': genre,
        if (network != null) 'network': network,
        if (keywords != null) 'keywords': keywords,
      },
      options: _authOptions(),
    );
    _requireSuccess(response, 'discoverTv');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> search(
    String query, {
    String? mediaType,
    int limit = 20,
    int offset = 0,
  }) async {
    final page = (offset ~/ limit) + 1;
    final eq = Uri.encodeComponent(query);
    var url = '${_apiUrl('search')}?query=$eq&page=$page';
    if (mediaType != null) {
      url += '&type=${Uri.encodeComponent(mediaType)}';
    }
    final response = await _dio.get(
      url,
      options: _authOptions(),
    );
    _requireSuccess(response, 'search');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMovieDetails(int tmdbId) async {
    final response = await _dio.get(
      _apiUrl('movie/$tmdbId'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getMovieDetails');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTvDetails(int tmdbId) async {
    final response = await _dio.get(
      _apiUrl('tv/$tmdbId'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getTvDetails');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSimilarMovies(int tmdbId, {int page = 1}) async {
    final response = await _dio.get(
      _apiUrl('movie/$tmdbId/similar'),
      queryParameters: {'page': page},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getSimilarMovies');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSimilarTv(int tmdbId, {int page = 1}) async {
    final response = await _dio.get(
      _apiUrl('tv/$tmdbId/similar'),
      queryParameters: {'page': page},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getSimilarTv');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMovieRecommendations(int tmdbId, {int page = 1}) async {
    final response = await _dio.get(
      _apiUrl('movie/$tmdbId/recommendations'),
      queryParameters: {'page': page},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getMovieRecommendations');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTvRecommendations(int tmdbId, {int page = 1}) async {
    final response = await _dio.get(
      _apiUrl('tv/$tmdbId/recommendations'),
      queryParameters: {'page': page},
      options: _authOptions(),
    );
    _requireSuccess(response, 'getTvRecommendations');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getGenreSliderMovies() async {
    final response = await _dio.get(
      _apiUrl('discover/genreslider/movie'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getGenreSliderMovies');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getGenreSliderTv() async {
    final response = await _dio.get(
      _apiUrl('discover/genreslider/tv'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getGenreSliderTv');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    final response = await _dio.get(
      _apiUrl('person/$personId'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getPersonDetails');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPersonCombinedCredits(int personId) async {
    final response = await _dio.get(
      _apiUrl('person/$personId/combined_credits'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getPersonCombinedCredits');
    return response.data as Map<String, dynamic>;
  }

  Future<SeerrStatus> getStatus() async {
    final response = await _dio.get(
      _apiUrl('status'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getStatus');
    return SeerrStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> testConnection() async {
    try {
      final response = await _dio.get(
        _apiUrl('status'),
        options: _authOptions(),
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getRadarrServers() async {
    final response = await _dio.get(
      _apiUrl('service/radarr'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getRadarrServers');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getRadarrServerDetails(int serverId) async {
    final response = await _dio.get(
      _apiUrl('service/radarr/$serverId'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getRadarrServerDetails');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSonarrServers() async {
    final response = await _dio.get(
      _apiUrl('service/sonarr'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getSonarrServers');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getSonarrServerDetails(int serverId) async {
    final response = await _dio.get(
      _apiUrl('service/sonarr/$serverId'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getSonarrServerDetails');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getRadarrSettings() async {
    final response = await _dio.get(
      _apiUrl('settings/radarr'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getRadarrSettings');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getSonarrSettings() async {
    final response = await _dio.get(
      _apiUrl('settings/sonarr'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getSonarrSettings');
    return response.data as List<dynamic>;
  }

  Future<MoonfinStatusResponse> getMoonfinStatus() async {
    final response = await _dio.get(
      _moonfinUrl('Status'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'getMoonfinStatus');
    return MoonfinStatusResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MoonfinLoginResponse> moonfinLogin({
    required String username,
    required String password,
    String authType = 'jellyfin',
  }) async {
    final response = await _dio.post(
      _moonfinUrl('Login'),
      data: MoonfinLoginRequest(
        username: username,
        password: password,
        authType: authType,
      ).toJson(),
      options: _authJsonOptions(),
    );
    _requireSuccess(response, 'moonfinLogin');
    final result = MoonfinLoginResponse.fromJson(response.data as Map<String, dynamic>);
    if (!result.success) {
      throw Exception(result.error ?? 'Moonfin login failed');
    }
    return result;
  }

  Future<void> moonfinLogout() async {
    final response = await _dio.delete(
      _moonfinUrl('Logout'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'moonfinLogout');
  }

  Future<MoonfinValidateResponse> moonfinValidate() async {
    final response = await _dio.get(
      _moonfinUrl('Validate'),
      options: _authOptions(),
    );
    _requireSuccess(response, 'moonfinValidate');
    return MoonfinValidateResponse.fromJson(response.data as Map<String, dynamic>);
  }

  void close() {
    _dio.close();
  }
}

class _ProxyUnwrapInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final path = response.requestOptions.path;
    if (!path.contains('/Moonfin/Jellyseerr/Api/')) {
      return handler.next(response);
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return handler.next(response);
    }

    final fileContents = data['FileContents'] as String?;
    if (fileContents == null) {
      return handler.next(response);
    }

    try {
      final decoded = utf8.decode(base64Decode(fileContents));
      final parsed = jsonDecode(decoded);
      response.data = parsed;
    } catch (e) {
      debugPrint('[Seerr] Failed to unwrap proxy envelope: $e');
    }

    handler.next(response);
  }
}
