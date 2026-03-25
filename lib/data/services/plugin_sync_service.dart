import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../data/repositories/seerr_repository.dart';
import '../../preference/home_section_config.dart';
import '../../preference/preference_constants.dart' as prefs;
import '../../preference/seerr_preferences.dart';
import '../../preference/seerr_row_config.dart';
import '../../preference/user_preferences.dart';
import '../../util/platform_detection.dart';

class PluginSyncService extends ChangeNotifier {
  static const List<String> supportedProfiles = <String>[
    'global',
    'desktop',
    'mobile',
    'tv',
  ];

  final UserPreferences _prefs;
  final PreferenceStore _store;
  final _dio = Dio();

  SeerrPreferences get _seerrPrefs => GetIt.instance<SeerrPreferences>();

  bool _pluginAvailable = false;
  bool get pluginAvailable => _pluginAvailable;

  String? _pluginVersion;
  String? get pluginVersion => _pluginVersion;

  String? _selectedCustomizationProfile;

  String? _seerrUrl;
  String? get seerrUrl => _seerrUrl;
  bool _seerrEnabled = false;
  bool get seerrEnabled => _seerrEnabled;

  bool _mdblistAvailable = false;
  bool get mdblistAvailable => _mdblistAvailable;
  bool _tmdbAvailable = false;
  bool get tmdbAvailable => _tmdbAvailable;

  PluginSyncService(this._prefs, this._store);

  dynamic _readValue(Map<String, dynamic> data, String key) {
    if (data.containsKey(key)) {
      return data[key];
    }

    if (key.isNotEmpty) {
      final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
      if (data.containsKey(pascal)) {
        return data[pascal];
      }
    }

    return null;
  }

  bool? _readBool(Map<String, dynamic> data, String key) {
    final value = _readValue(data, key);
    return value is bool ? value : null;
  }

  String? _readString(Map<String, dynamic> data, String key) {
    final value = _readValue(data, key);
    return value is String ? value : null;
  }

  void resetState({bool notify = true}) {
    _pluginAvailable = false;
    _pluginVersion = null;
    _seerrUrl = null;
    _seerrEnabled = false;
    _mdblistAvailable = false;
    _tmdbAvailable = false;
    if (notify) {
      _setLocalSeerrEnabled(false);
    }
    if (notify) {
      notifyListeners();
    }
  }

  void _setLocalSeerrEnabled(bool enabled) {
    if (_prefs.get(UserPreferences.seerrEnabled) == enabled) {
      return;
    }
    _store.set(UserPreferences.seerrEnabled, enabled);
    _prefs.notifyPreferenceChanged();
  }

  Future<bool> refreshAvailability(MediaServerClient client) async {
    resetState(notify: false);

    try {
      final pingResult = await _ping(client);
      if (pingResult == null) {
        _setLocalSeerrEnabled(false);
        notifyListeners();
        return false;
      }

      final installed = _readBool(pingResult, 'installed');
      if (installed != null && !installed) {
        _setLocalSeerrEnabled(false);
        notifyListeners();
        return false;
      }

      final syncEnabled = _readBool(pingResult, 'settingsSyncEnabled');
      if (syncEnabled != null && !syncEnabled) {
        _setLocalSeerrEnabled(false);
        notifyListeners();
        return false;
      }

      _pluginAvailable = true;
      _pluginVersion = _readString(pingResult, 'version');
      _seerrUrl = _readString(pingResult, 'jellyseerrUrl');
      _seerrEnabled = _readBool(pingResult, 'jellyseerrEnabled') ?? false;
      _mdblistAvailable = _readBool(pingResult, 'mdblistAvailable') ?? false;
      _tmdbAvailable = _readBool(pingResult, 'tmdbAvailable') ?? false;

      final seerrConfig = await _fetchJellyseerrConfig(client);
      if (seerrConfig != null) {
        _seerrUrl = _readString(seerrConfig, 'url') ?? _seerrUrl;

        final enabled = _readBool(seerrConfig, 'enabled');
        final userEnabled = _readBool(seerrConfig, 'userEnabled');
        _seerrEnabled = (enabled ?? _seerrEnabled) && (userEnabled ?? true);

        final variant = _readString(seerrConfig, 'variant');
        if (variant != null && variant.trim().isNotEmpty) {
          await _seerrPrefs.setMoonfinVariant(variant);
        }

        final displayName = _readString(seerrConfig, 'displayName');
        if (displayName != null && displayName.trim().isNotEmpty) {
          await _seerrPrefs.setMoonfinDisplayName(displayName);
        }
      }

      _setLocalSeerrEnabled(_seerrEnabled);

      notifyListeners();
      return true;
    } catch (_) {
      resetState();
      return false;
    }
  }

  String get _profileName {
    if (PlatformDetection.isTV) return 'tv';
    if (PlatformDetection.useMobileUi) return 'mobile';
    return 'desktop';
  }

  String get currentDeviceProfile => _profileName;
  String get selectedCustomizationProfile =>
      _selectedCustomizationProfile ?? _profileName;

  void setSelectedCustomizationProfile(String profile) {
    if (!supportedProfiles.contains(profile)) return;
    if (_selectedCustomizationProfile == profile) return;
    _selectedCustomizationProfile = profile;
    notifyListeners();
  }

  Future<void> syncOnLogin(MediaServerClient client) async {
    try {
      final available = await refreshAvailability(client);
      if (!available) {
        return;
      }

      final neverConfigured = !_store.containsKey(UserPreferences.pluginSyncEnabled.key);
      final syncEnabled = _prefs.get(UserPreferences.pluginSyncEnabled);

      if (!syncEnabled && !neverConfigured) return;

      final resolved = await _fetchResolvedProfile(client, _profileName);
      if (resolved == null) return;

      if (neverConfigured) {
        await _prefs.set(UserPreferences.pluginSyncEnabled, true);
      }

      _applyServerSettings(resolved);
    } catch (_) {
      resetState();
    }
  }

  Future<void> configureSeerr(
    MediaServerClient client, {
    String? username,
    String? password,
  }) async {
    if (!_pluginAvailable) return;

    final token = client.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      await _prefs.set(UserPreferences.seerrEnabled, true);

      final seerrRepo = await GetIt.instance.getAsync<SeerrRepository>();
      final status = await seerrRepo.configureWithMoonfin(
        jellyfinBaseUrl: client.baseUrl,
        jellyfinToken: token,
      );

      if (!status.authenticated && status.enabled &&
          username != null && username.isNotEmpty &&
          password != null && password.isNotEmpty) {
        await seerrRepo.loginWithMoonfin(
          username: username,
          password: password,
        );
      }
    } catch (_) {}
  }

  Future<void> pushSettings(MediaServerClient client) async {
    await pushSettingsForProfile(client, profile: selectedCustomizationProfile);
  }

  Future<void> pushSettingsForProfile(
    MediaServerClient client, {
    required String profile,
  }) async {
    if (!_pluginAvailable) return;
    if (!_prefs.get(UserPreferences.pluginSyncEnabled)) return;

    if (!supportedProfiles.contains(profile)) return;

    try {
      final payloadProfile = _buildProfileFromLocal();
      final token = client.accessToken;
      if (token == null) return;

      await _dio.post(
        '${client.baseUrl}/Moonfin/Settings/Profile/$profile',
        data: {'profile': payloadProfile, 'clientId': 'moonfin-flutter'},
        options: Options(headers: {
          'Authorization': 'MediaBrowser Token="$token"',
          'Content-Type': 'application/json',
        }),
      );
    } catch (_) {}
  }

  Future<bool> pullSettingsForProfile(
    MediaServerClient client, {
    required String profile,
  }) async {
    if (!supportedProfiles.contains(profile)) return false;
    if (!_pluginAvailable) return false;

    final resolved = await _fetchResolvedProfile(client, profile);
    if (resolved == null) {
      return false;
    }

    _applyServerSettings(resolved);
    return true;
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

  Future<Map<String, dynamic>?> _fetchJellyseerrConfig(
    MediaServerClient client,
  ) async {
    final token = client.accessToken;
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '${client.baseUrl}/Moonfin/Jellyseerr/Config',
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
    _applyString(resolved, 'mediaBarSourceType',
        UserPreferences.mediaBarContentType);
    _applyInt(
        resolved, 'mediaBarItemCount', UserPreferences.mediaBarItemCount);
    _applyInt(resolved, 'mediaBarOpacity', UserPreferences.navbarOpacity);
    _applyString(resolved, 'mediaBarOverlayColor', UserPreferences.navbarColor);
    _applyInt(resolved, 'navbarOpacity', UserPreferences.navbarOpacity);
    _applyString(resolved, 'navbarColor', UserPreferences.navbarColor);
    _applyBool(resolved, 'mediaBarAutoAdvance',
        UserPreferences.mediaBarAutoAdvance);
    _applyInt(resolved, 'mediaBarIntervalMs',
        UserPreferences.mediaBarIntervalMs);
    _applyBool(resolved, 'mediaBarTrailerPreview',
        UserPreferences.mediaBarTrailerPreview);
    _applyBool(resolved, 'episodePreviewEnabled',
        UserPreferences.episodePreviewEnabled);
    _applyBool(resolved, 'previewAudioEnabled',
        UserPreferences.previewAudioEnabled);

    _applyStringList(
        resolved, 'mediaBarLibraryIds', UserPreferences.mediaBarLibraryIds);
    _applyStringList(resolved, 'mediaBarCollectionIds',
        UserPreferences.mediaBarCollectionIds);
    _applyStringList(resolved, 'mediaBarExcludedGenres',
        UserPreferences.mediaBarExcludedGenres);

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
    _applyBool(resolved, 'mdblistShowRatingNames',
        UserPreferences.showRatingLabels);
    _applyBool(resolved, 'tmdbEpisodeRatingsEnabled',
        UserPreferences.enableEpisodeRatings);
    _applyString(resolved, 'tmdbApiKey', UserPreferences.tmdbApiKey);

    _applyBool(resolved, 'jellyseerrEnabled', UserPreferences.seerrEnabled);

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

    if (resolved['homeRowOrder'] is List) {
      final serverOrder = (resolved['homeRowOrder'] as List).cast<String>();
      final sections = <HomeSectionConfig>[];
      var order = 0;
      for (final name in serverOrder) {
        final type = prefs.HomeSectionType.fromSerialized(name);
        if (type == prefs.HomeSectionType.none) continue;
        sections.add(HomeSectionConfig(type: type, enabled: true, order: order++));
      }
      final enabledTypes = sections.map((s) => s.type).toSet();
      for (final type in prefs.HomeSectionType.values) {
        if (type == prefs.HomeSectionType.none) continue;
        if (!enabledTypes.contains(type)) {
          sections.add(HomeSectionConfig(type: type, enabled: false, order: order++));
        }
      }
      _prefs.setHomeSectionsConfig(sections);
    }

    if (resolved['jellyseerrRows'] is Map<String, dynamic>) {
      final rowsData = resolved['jellyseerrRows'] as Map<String, dynamic>;
      if (rowsData['rowOrder'] is List) {
        final serverOrder = (rowsData['rowOrder'] as List).cast<String>();
        final configs = <SeerrRowConfig>[];
        var order = 0;
        for (final name in serverOrder) {
          final type = prefs.SeerrRowType.fromSerialized(name);
          configs.add(SeerrRowConfig(type: type, enabled: true, order: order++));
        }
        final enabledTypes = configs.map((c) => c.type).toSet();
        for (final type in prefs.SeerrRowType.values) {
          if (!enabledTypes.contains(type)) {
            configs.add(SeerrRowConfig(type: type, enabled: false, order: order++));
          }
        }
        _seerrPrefs.setRowsConfig(configs);
      }
    }

    _prefs.notifyPreferenceChanged();
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

  void _applyStringList(
    Map<String, dynamic> data,
    String serverKey,
    Preference<String> pref,
  ) {
    final value = data[serverKey];
    if (value is List) {
      _store.set(pref, value.cast<String>().join(','));
    }
  }

  List<String> _csvToList(Preference<String> pref) {
    return _prefs
        .get(pref)
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
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
      'mediaBarSourceType': _prefs.get(UserPreferences.mediaBarContentType),
      'mediaBarItemCount':
          int.tryParse(_prefs.get(UserPreferences.mediaBarItemCount)) ?? 10,
      'mediaBarOpacity': _prefs.get(UserPreferences.navbarOpacity),
      'mediaBarOverlayColor': _prefs.get(UserPreferences.navbarColor),
      'navbarOpacity': _prefs.get(UserPreferences.navbarOpacity),
      'navbarColor': _prefs.get(UserPreferences.navbarColor),
      'mediaBarAutoAdvance': _prefs.get(UserPreferences.mediaBarAutoAdvance),
      'mediaBarIntervalMs': _prefs.get(UserPreferences.mediaBarIntervalMs),
      'mediaBarTrailerPreview':
          _prefs.get(UserPreferences.mediaBarTrailerPreview),
      'episodePreviewEnabled':
          _prefs.get(UserPreferences.episodePreviewEnabled),
      'previewAudioEnabled':
          _prefs.get(UserPreferences.previewAudioEnabled),
      'mediaBarLibraryIds': _csvToList(UserPreferences.mediaBarLibraryIds),
      'mediaBarCollectionIds':
          _csvToList(UserPreferences.mediaBarCollectionIds),
      'mediaBarExcludedGenres':
          _csvToList(UserPreferences.mediaBarExcludedGenres),
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
      'mdblistShowRatingNames': _prefs.get(UserPreferences.showRatingLabels),
      'tmdbEpisodeRatingsEnabled':
          _prefs.get(UserPreferences.enableEpisodeRatings),
      'tmdbApiKey': _prefs.get(UserPreferences.tmdbApiKey),
      'jellyseerrEnabled': _prefs.get(UserPreferences.seerrEnabled),
      'blockedRatings': _csvToList(UserPreferences.blockedRatings),
      'mdblistRatingSources': _csvToList(UserPreferences.enabledRatings),
      'homeRowOrder': _prefs.homeSectionsConfig
          .where((c) => c.enabled)
          .map((c) => c.type.serializedName)
          .toList(),
      'jellyseerrRows': {
        'rowOrder': _seerrPrefs.activeRows
            .map((t) => t.serializedName)
            .toList(),
      },
    };
  }
}
