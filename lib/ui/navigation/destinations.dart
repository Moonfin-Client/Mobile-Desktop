import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension NavigationX on BuildContext {
  void popOrHome() {
    if (canPop()) {
      pop();
    } else {
      go(Destinations.home);
    }
  }
}

class Destinations {
  const Destinations._();

  // Auth
  static const startup = '/';
  static const serverSelect = '/server-select';
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
  static const photoPlayer = '/player/photo/:itemId';
  static const trailerPlayer = '/player/trailer';
  static const nextUp = '/player/next-up/:itemId';
  static const stillWatching = '/player/still-watching/:itemId';

  // Settings
  static const settings = '/settings';
  static const settingsPlayback = '/settings/playback';
  static const settingsAppearance = '/settings/appearance';
  static const settingsHomeSections = '/settings/home-sections';
  static const settingsSubtitles = '/settings/subtitles';
  static const settingsAuth = '/settings/auth';
  static const settingsPinCode = '/settings/pin-code';
  static const settingsScreensaver = '/settings/screensaver';
  static const settingsParental = '/settings/parental';
  static const settingsAbout = '/settings/about';
  static const settingsMediaBar = '/settings/media-bar';
  static const settingsLibrary = '/settings/library';
  static const settingsSeerr = '/settings/seerr-config';
  static const settingsMoonfin = '/settings/moonfin';
  static const settingsNavigation = '/settings/navigation';

  // Seerr
  static const seerrDiscover = '/seerr/discover';
  static const seerrRequests = '/seerr/requests';
  static const seerrSettings = '/seerr/settings';
  static const seerrBrowse = '/seerr/browse';
  static const seerrMediaDetail = '/seerr/media/:itemId';
  static const seerrPersonDetail = '/seerr/person/:personId';

  static String library(String libraryId) => '/library/$libraryId';
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
  static String genre(String genreName, {required String genreId, String? parentId, String? includeType}) {
    final base = '/genre/${Uri.encodeComponent(genreName)}';
    final params = <String>['genreId=$genreId'];
    if (parentId != null) params.add('parentId=$parentId');
    if (includeType != null) params.add('includeType=$includeType');
    return '$base?${params.join('&')}';
  }
  static String folder(String folderId) => '/folder/$folderId';
  static String collection(String collectionId) =>
      '/collection/$collectionId';
  static String musicLibrary(String libraryId) => '/music/$libraryId';
  static String photo(String itemId) => '/player/photo/$itemId';
  static String nextUpFor(String itemId) => '/player/next-up/$itemId';
  static String stillWatchingFor(String itemId) =>
      '/player/still-watching/$itemId';
  static String searchWith(String query) =>
      '/search?query=${Uri.encodeComponent(query)}';
  static String seerrMedia(String itemId) => '/seerr/media/$itemId';
  static String seerrPerson(String personId) =>
      '/seerr/person/$personId';

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
