import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../preference/preference_constants.dart' as prefs;
import '../../preference/user_preferences.dart';
import '../../util/platform_detection.dart';

class PluginSyncService {
  final UserPreferences _prefs;
  final PreferenceStore _store;
  final _dio = Dio();

  bool _pluginAvailable = false;
  bool get pluginAvailable => _pluginAvailable;

  String? _jellyseerrUrl;
  String? get jellyseerrUrl => _jellyseerrUrl;
  bool _jellyseerrEnabled = false;
  bool get jellyseerrEnabled => _jellyseerrEnabled;

  bool _mdblistAvailable = false;
  bool get mdblistAvailable => _mdblistAvailable;
  bool _tmdbAvailable = false;
  bool get tmdbAvailable => _tmdbAvailable;

  PluginSyncService(this._prefs, this._store);

  String get _profileName {
    if (PlatformDetection.isTV) return 'tv';
    if (PlatformDetection.useMobileUi) return 'mobile';
    return 'desktop';
  }

  Future<void> syncOnLogin(MediaServerClient client) async {
    try {
      final pingResult = await _ping(client);
      if (pingResult == null) {
        _pluginAvailable = false;
        return;
      }
      _pluginAvailable = true;
      _jellyseerrUrl = pingResult['jellyseerrUrl'] as String?;
      _jellyseerrEnabled = pingResult['jellyseerrEnabled'] as bool? ?? false;
      _mdblistAvailable = pingResult['mdblistAvailable'] as bool? ?? false;
      _tmdbAvailable = pingResult['tmdbAvailable'] as bool? ?? false;

      final syncEnabled = _prefs.get(UserPreferences.pluginSyncEnabled);
      if (!syncEnabled) return;

      final resolved = await _fetchResolvedProfile(client, _profileName);
      if (resolved == null) return;

      _applyServerSettings(resolved);
    } catch (e) {
      debugPrint('[Moonfin] Plugin sync failed: $e');
    }
  }

  Future<void> pushSettings(MediaServerClient client) async {
    if (!_pluginAvailable) return;
    if (!_prefs.get(UserPreferences.pluginSyncEnabled)) return;

    try {
      final profile = _buildProfileFromLocal();
      final token = client.accessToken;
      if (token == null) return;

      await _dio.post(
        '${client.baseUrl}/Moonfin/Settings/Profile/global',
        data: {'profile': profile, 'clientId': 'moonfin-flutter'},
        options: Options(headers: {
          'Authorization': 'MediaBrowser Token="$token"',
          'Content-Type': 'application/json',
        }),
      );
    } catch (e) {
      debugPrint('[Moonfin] Plugin push failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _ping(MediaServerClient client) async {
    final token = client.accessToken;
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '${client.baseUrl}/Moonfin/Ping',
        options: Options(headers: {
          'Authorization': 'MediaBrowser Token="$token"',
        }),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _fetchResolvedProfile(
    MediaServerClient client,
    String profile,
  ) async {
    final token = client.accessToken;
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '${client.baseUrl}/Moonfin/Settings/Resolved/$profile',
        options: Options(headers: {
          'Authorization': 'MediaBrowser Token="$token"',
        }),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  void _applyServerSettings(Map<String, dynamic> resolved) {
    _applyString(resolved, 'navbarPosition', UserPreferences.navbarPosition,
        enumValues: prefs.NavbarPosition.values);
    _applyBool(resolved, 'showClock', UserPreferences.showClock);
    _applyBool(resolved, 'use24HourClock', UserPreferences.use24HourClock);
    _applyBool(
        resolved, 'showShuffleButton', UserPreferences.showShuffleButton);
    _applyBool(resolved, 'showGenresButton', UserPreferences.showGenresButton);
    _applyBool(
        resolved, 'showFavoritesButton', UserPreferences.showFavoritesButton);
    _applyBool(
        resolved, 'showSyncPlayButton', UserPreferences.showSyncPlayButton);
    _applyBool(resolved, 'showLibrariesInToolbar',
        UserPreferences.showLibrariesInToolbar);
    _applyString(resolved, 'shuffleContentType',
        UserPreferences.shuffleContentType);
    _applyBool(resolved, 'mergeContinueWatchingNextUp',
        UserPreferences.mergeContinueWatchingNextUp);
    _applyBool(resolved, 'enableMultiServerLibraries',
        UserPreferences.enableMultiServerLibraries);
    _applyBool(resolved, 'enableFolderView', UserPreferences.enableFolderView);
    _applyBool(resolved, 'confirmExit', UserPreferences.confirmExit);
    _applyString(
        resolved, 'seasonalSurprise', UserPreferences.seasonalSurprise);

    _applyBool(resolved, 'mediaBarEnabled', UserPreferences.mediaBarEnabled);
    _applyString(resolved, 'mediaBarContentType',
        UserPreferences.mediaBarContentType);
    _applyInt(
        resolved, 'mediaBarItemCount', UserPreferences.mediaBarItemCount);
    _applyInt(
        resolved, 'mediaBarOpacity', UserPreferences.mediaBarOverlayOpacity);
    _applyString(resolved, 'mediaBarOverlayColor',
        UserPreferences.mediaBarOverlayColor);
    _applyBool(resolved, 'mediaBarAutoAdvance',
        UserPreferences.mediaBarAutoAdvance);
    _applyInt(resolved, 'mediaBarIntervalMs',
        UserPreferences.mediaBarIntervalMs);
    _applyBool(resolved, 'mediaBarTrailerPreview',
        UserPreferences.mediaBarTrailerPreview);

    _applyBool(
        resolved, 'themeMusicEnabled', UserPreferences.themeMusicEnabled);
    _applyInt(resolved, 'themeMusicVolume', UserPreferences.themeMusicVolume);
    _applyBool(resolved, 'themeMusicOnHomeRows',
        UserPreferences.themeMusicOnHomeRows);

    _applyBool(resolved, 'homeRowsImageTypeOverride',
        UserPreferences.homeRowsUniversalOverride);
    _applyString(resolved, 'homeRowsImageType',
        UserPreferences.homeRowsUniversalImageType,
        enumValues: prefs.ImageType.values);

    _applyBool(resolved, 'backdropEnabled', UserPreferences.backdropEnabled);
    _applyString(resolved, 'detailsScreenBlur',
        UserPreferences.detailsBackgroundBlurAmount,
        intFromString: true);
    _applyString(resolved, 'browsingBlur',
        UserPreferences.browsingBackgroundBlurAmount,
        intFromString: true);

    _applyBool(
        resolved, 'mdblistEnabled', UserPreferences.enableAdditionalRatings);
    _applyString(
        resolved, 'mdblistApiKey', UserPreferences.mdblistApiKey);
    _applyBool(resolved, 'tmdbEpisodeRatingsEnabled',
        UserPreferences.enableEpisodeRatings);
    _applyString(resolved, 'tmdbApiKey', UserPreferences.tmdbApiKey);

    if (resolved['mdblistRatingSources'] is List) {
      final sources = (resolved['mdblistRatingSources'] as List)
          .cast<String>()
          .join(',');
      _store.set(UserPreferences.enabledRatings, sources);
    }

    if (resolved['blockedRatings'] is List) {
      final blocked = (resolved['blockedRatings'] as List)
          .cast<String>()
          .join(',');
      _store.set(UserPreferences.blockedRatings, blocked);
    }
  }

  void _applyBool(
    Map<String, dynamic> data,
    String serverKey,
    Preference<bool> pref,
  ) {
    final value = data[serverKey];
    if (value is bool) {
      _store.set(pref, value);
    }
  }

  void _applyInt(
    Map<String, dynamic> data,
    String serverKey,
    Preference<dynamic> pref,
  ) {
    final value = data[serverKey];
    if (value is int) {
      if (pref.defaultValue is String) {
        _store.set(pref as Preference<String>, value.toString());
      } else {
        _store.set(pref as Preference<int>, value);
      }
    }
  }

  void _applyString<T>(
    Map<String, dynamic> data,
    String serverKey,
    Preference<T> pref, {
    List<Enum>? enumValues,
    bool intFromString = false,
  }) {
    final value = data[serverKey];
    if (value == null) return;

    if (intFromString && value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        _store.set(pref as Preference<int>, parsed);
      }
      return;
    }

    if (enumValues != null && pref is EnumPreference) {
      if (value is String) {
        final match = enumValues.cast<Enum>().where(
            (e) => e.name.toLowerCase() == value.toLowerCase());
        if (match.isNotEmpty) {
          _store.set(pref, match.first as T);
        }
      }
      return;
    }

    if (value is String) {
      _store.set(pref as Preference<String>, value);
    }
  }

  Map<String, dynamic> _buildProfileFromLocal() {
    return {
      'navbarPosition': _prefs.get(UserPreferences.navbarPosition).name,
      'showClock': _prefs.get(UserPreferences.showClock),
      'use24HourClock': _prefs.get(UserPreferences.use24HourClock),
      'showShuffleButton': _prefs.get(UserPreferences.showShuffleButton),
      'showGenresButton': _prefs.get(UserPreferences.showGenresButton),
      'showFavoritesButton': _prefs.get(UserPreferences.showFavoritesButton),
      'showSyncPlayButton': _prefs.get(UserPreferences.showSyncPlayButton),
      'showLibrariesInToolbar':
          _prefs.get(UserPreferences.showLibrariesInToolbar),
      'shuffleContentType': _prefs.get(UserPreferences.shuffleContentType),
      'mergeContinueWatchingNextUp':
          _prefs.get(UserPreferences.mergeContinueWatchingNextUp),
      'enableMultiServerLibraries':
          _prefs.get(UserPreferences.enableMultiServerLibraries),
      'enableFolderView': _prefs.get(UserPreferences.enableFolderView),
      'confirmExit': _prefs.get(UserPreferences.confirmExit),
      'seasonalSurprise': _prefs.get(UserPreferences.seasonalSurprise),
      'mediaBarEnabled': _prefs.get(UserPreferences.mediaBarEnabled),
      'mediaBarContentType': _prefs.get(UserPreferences.mediaBarContentType),
      'mediaBarItemCount':
          int.tryParse(_prefs.get(UserPreferences.mediaBarItemCount)) ?? 10,
      'mediaBarOpacity': _prefs.get(UserPreferences.mediaBarOverlayOpacity),
      'mediaBarOverlayColor':
          _prefs.get(UserPreferences.mediaBarOverlayColor),
      'mediaBarAutoAdvance': _prefs.get(UserPreferences.mediaBarAutoAdvance),
      'mediaBarIntervalMs': _prefs.get(UserPreferences.mediaBarIntervalMs),
      'mediaBarTrailerPreview':
          _prefs.get(UserPreferences.mediaBarTrailerPreview),
      'themeMusicEnabled': _prefs.get(UserPreferences.themeMusicEnabled),
      'themeMusicVolume': _prefs.get(UserPreferences.themeMusicVolume),
      'themeMusicOnHomeRows': _prefs.get(UserPreferences.themeMusicOnHomeRows),
      'homeRowsImageTypeOverride':
          _prefs.get(UserPreferences.homeRowsUniversalOverride),
      'homeRowsImageType':
          _prefs.get(UserPreferences.homeRowsUniversalImageType).name,
      'backdropEnabled': _prefs.get(UserPreferences.backdropEnabled),
      'detailsScreenBlur':
          _prefs.get(UserPreferences.detailsBackgroundBlurAmount).toString(),
      'browsingBlur':
          _prefs.get(UserPreferences.browsingBackgroundBlurAmount).toString(),
      'mdblistEnabled': _prefs.get(UserPreferences.enableAdditionalRatings),
      'mdblistApiKey': _prefs.get(UserPreferences.mdblistApiKey),
      'tmdbEpisodeRatingsEnabled':
          _prefs.get(UserPreferences.enableEpisodeRatings),
      'tmdbApiKey': _prefs.get(UserPreferences.tmdbApiKey),
      'mdblistRatingSources':
          _prefs.get(UserPreferences.enabledRatings).split(','),
    };
  }
}
