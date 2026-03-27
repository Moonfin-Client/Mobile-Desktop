import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension NavigationX on BuildContext {
  void popOrHome() {
    final router = GoRouter.of(this);

    if (!mounted) return;

    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Destinations.home);
    }
  }
}

class Destinations {
  const Destinations._();

  // Auth
  static const startup = '/';
  static const serverSelect = '/server-select';
  static const embyConnect = '/emby-connect';
  static const server = '/server';
  static const login = '/login';

  // General
  static const home = '/home';
  static const search = '/search';

  // Browsing
  static const libraryBrowse = '/library/:libraryId';
  static const allGenres = '/genres';
  static const allFavorites = '/favorites';
  static const folderView = '/folders';
  static const folderBrowse = '/folder/:folderId';
  static const collectionBrowse = '/collection/:collectionId';
  static const libraryViewRoute = '/library-view/:libraryId';
  static const musicBrowse = '/music/:libraryId';
  static const genreBrowse = '/genre/:genreName';

  // Item details
  static const itemDetail = '/item/:itemId';
  static const musicFavorites = '/music-favorites/:parentId';

  // Live TV
  static const liveTv = '/live-tv';
  static const liveTvGuide = '/live-tv/guide';
  static const liveTvSchedule = '/live-tv/schedule';
  static const liveTvRecordings = '/live-tv/recordings';
  static const liveTvSeriesRecordings = '/live-tv/series-recordings';
  static const liveTvPlayer = '/live-tv/player';

  // Playback
  static const videoPlayer = '/player/video';
  static const audioPlayer = '/player/audio';
  static const bookReader = '/player/book/:itemId';
  static const photoPlayer = '/player/photo/:itemId';
  static const trailerPlayer = '/player/trailer';
  static const nextUp = '/player/next-up/:itemId';
  static const stillWatching = '/player/still-watching/:itemId';

  // Admin
  static const admin = '/admin';
  static const adminUsers = '/admin/users';
  static const adminUsersAdd = '/admin/users/add';
  static const adminUsersEdit = '/admin/users/:userId';
  static const adminLibraries = '/admin/libraries';
  static const adminLibrariesAdd = '/admin/libraries/add';
  static const adminLibrariesEdit = '/admin/libraries/:libraryId';
  static const adminSettings = '/admin/settings';
  static const adminSettingsPlayback = '/admin/settings/playback';
  static const adminSettingsResume = '/admin/settings/resume';
  static const adminSettingsStreaming = '/admin/settings/streaming';
  static const adminSettingsTrickplay = '/admin/settings/trickplay';
  static const adminSettingsNetworking = '/admin/settings/networking';
  static const adminSettingsBranding = '/admin/settings/branding';
  static const adminTasks = '/admin/tasks';
  static const adminTasksDetail = '/admin/tasks/:taskId';
  static const adminPlugins = '/admin/plugins';
  static const adminPluginsDetail = '/admin/plugins/:pluginId';
  static const adminRepositories = '/admin/repositories';
  static const adminActivity = '/admin/activity';
  static const adminDevices = '/admin/devices';
  static const adminKeys = '/admin/keys';
  static const adminBackups = '/admin/backups';
  static const adminLogs = '/admin/logs';
  static const adminLogsFile = '/admin/logs/:fileName';
  static const adminLiveTv = '/admin/live-tv';
  static const adminAnalytics = '/admin/analytics';
  static const adminMetadataEdit = '/admin/metadata/:itemId';

  // Settings
  static const settings = '/settings';
  static const settingsCustomization = '/settings/customization';
  static const settingsPlayback = '/settings/playback';
  static const settingsAppearance = '/settings/appearance';
  static const settingsHomeSections = '/settings/home-sections';
  static const settingsHomeRowsImageType = '/settings/home-sections/image-type';
  static const settingsSubtitles = '/settings/subtitles';
  static const settingsAuth = '/settings/auth';
  static const settingsPinCode = '/settings/pin-code';
  static const settingsScreensaver = '/settings/screensaver';
  static const settingsParental = '/settings/parental';
  static const settingsAbout = '/settings/about';
  static const settingsMediaBar = '/settings/media-bar';
  static const settingsLibrary = '/settings/library';
  static const settingsSeerr = '/settings/seerr-config';
  static const settingsPlugin = '/settings/plugin';
  static const settingsRatings = '/settings/ratings';
  static const settingsNavigation = '/settings/navigation';

  // Seerr
  static const seerrDiscover = '/seerr/discover';
  static const seerrRequests = '/seerr/requests';
  static const seerrBrowse = '/seerr/browse';
  static const seerrMediaDetail = '/seerr/media/:itemId';
  static const seerrPersonDetail = '/seerr/person/:personId';

  // Downloads / Saved Media
  static const downloads = '/downloads';
  static const downloadsSeries = '/downloads/series/:seriesId';
  static const downloadsSeason = '/downloads/series/:seriesId/season/:seasonId';
  static const downloadsAlbum = '/downloads/music/:albumId';
  static const settingsDownloads = '/settings/downloads';
  static const storageManagement = '/settings/downloads/storage';

  static String library(String libraryId, {List<String>? includeItemTypes}) {
    final base = '/library/$libraryId';
    if (includeItemTypes != null && includeItemTypes.isNotEmpty) {
      final types = includeItemTypes.map(Uri.encodeComponent).join(',');
      return '$base?types=$types';
    }
    return base;
  }

  static String libraryView(String libraryId) => '/library-view/$libraryId';
  static String libraryGenresOf(String libraryId) =>
      '/library/$libraryId/genres';
  static String libraryLettersOf(String libraryId) =>
      '/library/$libraryId/letters';
  static String librarySuggestionsOf(String libraryId) =>
      '/library/$libraryId/suggestions';
  static String item(String itemId, {String? serverId}) {
    final base = '/item/$itemId';
    return serverId != null ? '$base?serverId=$serverId' : base;
  }

  static String itemListOf(String itemId) => '/item/$itemId/list';
  static String musicFavoritesOf(String parentId) =>
      '/music-favorites/$parentId';
  static String genre(
    String genreName, {
    required String genreId,
    String? parentId,
    String? includeType,
  }) {
    final base = '/genre/${Uri.encodeComponent(genreName)}';
    final params = <String>['genreId=$genreId'];
    if (parentId != null) params.add('parentId=$parentId');
    if (includeType != null) params.add('includeType=$includeType');
    return '$base?${params.join('&')}';
  }

  static String folder(String folderId) => '/folder/$folderId';
  static String collection(String collectionId) => '/collection/$collectionId';
  static String musicLibrary(String libraryId) => '/music/$libraryId';
  static String photo(String itemId) => '/player/photo/$itemId';
  static String trailer({String? videoId, String? url}) {
    final params = <String, String>{
      if (videoId != null && videoId.isNotEmpty) 'videoId': videoId,
      if (url != null && url.isNotEmpty) 'url': url,
    };
    return Uri(path: trailerPlayer, queryParameters: params).toString();
  }
  static String book(String itemId, {String? serverId}) {
    final base = '/player/book/$itemId';
    return serverId != null
        ? '$base?serverId=${Uri.encodeComponent(serverId)}'
        : base;
  }

  static String itemOrPhoto(String itemId, {String? serverId, String? type}) =>
      type == 'Photo' ? photo(itemId) : item(itemId, serverId: serverId);
  static String nextUpFor(String itemId) => '/player/next-up/$itemId';
  static String stillWatchingFor(String itemId) =>
      '/player/still-watching/$itemId';
  static String searchWith(String query) =>
      '/search?query=${Uri.encodeComponent(query)}';
  static String seerrMedia(String itemId) => '/seerr/media/$itemId';
  static String seerrPerson(String personId) => '/seerr/person/$personId';

  static String downloadedSeries(String seriesId) =>
      '/downloads/series/$seriesId';
  static String downloadedSeason(String seriesId, String seasonId) =>
      '/downloads/series/$seriesId/season/$seasonId';
  static String downloadedAlbum(String albumId, {String? albumName}) {
    final base = '/downloads/music/${Uri.encodeComponent(albumId)}';
    if (albumName == null || albumName.isEmpty) {
      return base;
    }

    return '$base?name=${Uri.encodeComponent(albumName)}';
  }

  static String adminUser(String userId) => '/admin/users/$userId';
  static String adminLibrary(String libraryId) => '/admin/libraries/$libraryId';
  static String adminTask(String taskId) => '/admin/tasks/$taskId';
  static String adminPlugin(String pluginId) => '/admin/plugins/$pluginId';
  static String adminLogFile(String fileName) =>
      '/admin/logs/${Uri.encodeComponent(fileName)}';
  static String adminMetadata(String itemId) => '/admin/metadata/$itemId';

  static String seerrBrowseWith({
    required String filterId,
    required String filterName,
    required String mediaType,
    required String filterType,
  }) {
    return Uri(
      path: '/seerr/browse',
      queryParameters: {
        'filterId': filterId,
        'filterName': filterName,
        'mediaType': mediaType,
        'filterType': filterType,
      },
    ).toString();
  }
}
