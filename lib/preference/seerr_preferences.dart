import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../auth/repositories/session_repository.dart';
import 'preference_constants.dart';
import 'seerr_row_config.dart';

class SeerrPreferences {
  final PreferenceStore _store;
  final SessionRepository _session;

  SeerrPreferences(this._store, this._session);

  String _userKey(String key) {
    final uid = _session.activeUserId ?? '';
    return 'seerr_${key}_$uid';
  }

  bool get enabled => _store.getBool(_userKey('enabled')) ?? false;
  Future<void> setEnabled(bool value) => _store.setBool(_userKey('enabled'), value);

  String get serverUrl => _store.getString(_userKey('server_url')) ?? '';
  Future<void> setServerUrl(String value) => _store.setString(_userKey('server_url'), value);

  String get authMethod => _store.getString(_userKey('auth_method')) ?? 'jellyfin';
  Future<void> setAuthMethod(String value) => _store.setString(_userKey('auth_method'), value);

  String get apiKey => _store.getString(_userKey('api_key')) ?? '';
  Future<void> setApiKey(String value) => _store.setString(_userKey('api_key'), value);

  bool get moonfinMode => _store.getBool(_userKey('moonfin_mode')) ?? false;
  Future<void> setMoonfinMode(bool value) => _store.setBool(_userKey('moonfin_mode'), value);

  String get moonfinDisplayName => _store.getString(_userKey('moonfin_display_name')) ?? '';
  Future<void> setMoonfinDisplayName(String value) =>
      _store.setString(_userKey('moonfin_display_name'), value);

  String get moonfinVariant => _store.getString(_userKey('moonfin_variant')) ?? 'jellyseerr';
  Future<void> setMoonfinVariant(String value) =>
      _store.setString(_userKey('moonfin_variant'), value);

  String get moonfinUserId => _store.getString(_userKey('moonfin_user_id')) ?? '';
  Future<void> setMoonfinUserId(String value) =>
      _store.setString(_userKey('moonfin_user_id'), value);

  bool get lastConnectionSuccess =>
      _store.getBool(_userKey('last_connection_success')) ?? false;
  Future<void> setLastConnectionSuccess(bool value) =>
      _store.setBool(_userKey('last_connection_success'), value);

  bool get showInNavigation => _store.getBool(_userKey('show_in_navigation')) ?? true;
  Future<void> setShowInNavigation(bool value) =>
      _store.setBool(_userKey('show_in_navigation'), value);

  bool get showInToolbar => _store.getBool(_userKey('show_in_toolbar')) ?? true;
  Future<void> setShowInToolbar(bool value) =>
      _store.setBool(_userKey('show_in_toolbar'), value);

  bool get showRequestStatus => _store.getBool(_userKey('show_request_status')) ?? true;
  Future<void> setShowRequestStatus(bool value) =>
      _store.setBool(_userKey('show_request_status'), value);

  bool get blockNsfw => _store.getBool(_userKey('block_nsfw')) ?? true;
  Future<void> setBlockNsfw(bool value) => _store.setBool(_userKey('block_nsfw'), value);

  SeerrFetchLimit get fetchLimit {
    final stored = _store.getString(_userKey('fetch_limit'));
    if (stored == null || stored.isEmpty) return SeerrFetchLimit.medium;
    for (final v in SeerrFetchLimit.values) {
      if (v.name == stored) return v;
    }
    return SeerrFetchLimit.medium;
  }

  Future<void> setFetchLimit(SeerrFetchLimit value) =>
      _store.setString(_userKey('fetch_limit'), value.name);

  List<SeerrRowConfig> get rowsConfig =>
      SeerrRowConfig.fromJsonString(_store.getString(_userKey('rows_config')) ?? '');

  Future<void> setRowsConfig(List<SeerrRowConfig> value) =>
      _store.setString(_userKey('rows_config'), SeerrRowConfig.toJsonString(value));

  List<SeerrRowType> get activeRows {
    final configs = rowsConfig.where((c) => c.enabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return configs.map((c) => c.type).toList();
  }

  String get hdMovieProfileId => _store.getString(_userKey('hd_movie_profile_id')) ?? '';
  Future<void> setHdMovieProfileId(String value) =>
      _store.setString(_userKey('hd_movie_profile_id'), value);

  String get fourKMovieProfileId => _store.getString(_userKey('4k_movie_profile_id')) ?? '';
  Future<void> setFourKMovieProfileId(String value) =>
      _store.setString(_userKey('4k_movie_profile_id'), value);

  String get hdTvProfileId => _store.getString(_userKey('hd_tv_profile_id')) ?? '';
  Future<void> setHdTvProfileId(String value) =>
      _store.setString(_userKey('hd_tv_profile_id'), value);

  String get fourKTvProfileId => _store.getString(_userKey('4k_tv_profile_id')) ?? '';
  Future<void> setFourKTvProfileId(String value) =>
      _store.setString(_userKey('4k_tv_profile_id'), value);

  String get hdMovieRootFolderId => _store.getString(_userKey('hd_movie_root_folder_id')) ?? '';
  Future<void> setHdMovieRootFolderId(String value) =>
      _store.setString(_userKey('hd_movie_root_folder_id'), value);

  String get fourKMovieRootFolderId =>
      _store.getString(_userKey('4k_movie_root_folder_id')) ?? '';
  Future<void> setFourKMovieRootFolderId(String value) =>
      _store.setString(_userKey('4k_movie_root_folder_id'), value);

  String get hdTvRootFolderId => _store.getString(_userKey('hd_tv_root_folder_id')) ?? '';
  Future<void> setHdTvRootFolderId(String value) =>
      _store.setString(_userKey('hd_tv_root_folder_id'), value);

  String get fourKTvRootFolderId => _store.getString(_userKey('4k_tv_root_folder_id')) ?? '';
  Future<void> setFourKTvRootFolderId(String value) =>
      _store.setString(_userKey('4k_tv_root_folder_id'), value);

  String get hdMovieServerId => _store.getString(_userKey('hd_movie_server_id')) ?? '';
  Future<void> setHdMovieServerId(String value) =>
      _store.setString(_userKey('hd_movie_server_id'), value);

  String get fourKMovieServerId => _store.getString(_userKey('4k_movie_server_id')) ?? '';
  Future<void> setFourKMovieServerId(String value) =>
      _store.setString(_userKey('4k_movie_server_id'), value);

  String get hdTvServerId => _store.getString(_userKey('hd_tv_server_id')) ?? '';
  Future<void> setHdTvServerId(String value) =>
      _store.setString(_userKey('hd_tv_server_id'), value);

  String get fourKTvServerId => _store.getString(_userKey('4k_tv_server_id')) ?? '';
  Future<void> setFourKTvServerId(String value) =>
      _store.setString(_userKey('4k_tv_server_id'), value);

  Future<void> clearAll() async {
    final keys = [
      'enabled', 'server_url', 'auth_method', 'api_key',
      'moonfin_mode', 'moonfin_display_name', 'moonfin_variant', 'moonfin_user_id',
      'last_connection_success',
      'show_in_navigation', 'show_in_toolbar', 'show_request_status',
      'block_nsfw', 'fetch_limit', 'rows_config',
      'hd_movie_profile_id', '4k_movie_profile_id',
      'hd_tv_profile_id', '4k_tv_profile_id',
      'hd_movie_root_folder_id', '4k_movie_root_folder_id',
      'hd_tv_root_folder_id', '4k_tv_root_folder_id',
      'hd_movie_server_id', '4k_movie_server_id',
      'hd_tv_server_id', '4k_tv_server_id',
    ];
    for (final key in keys) {
      await _store.remove(_userKey(key));
    }
  }
}
