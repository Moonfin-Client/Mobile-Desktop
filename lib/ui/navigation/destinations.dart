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
  static const settingsJellyseerr = '/settings/jellyseerr-config';
  static const settingsMoonfin = '/settings/moonfin';

  // Jellyseerr
  static const jellyseerrDiscover = '/jellyseerr/discover';
  static const jellyseerrRequests = '/jellyseerr/requests';
  static const jellyseerrSettings = '/jellyseerr/settings';
  static const jellyseerrBrowse = '/jellyseerr/browse';
  static const jellyseerrMediaDetail = '/jellyseerr/media/:itemId';
  static const jellyseerrPersonDetail = '/jellyseerr/person/:personId';

  static String library(String libraryId) => '/library/$libraryId';
  static String libraryGenresOf(String libraryId) =>
      '/library/$libraryId/genres';
  static String libraryLettersOf(String libraryId) =>
      '/library/$libraryId/letters';
  static String librarySuggestionsOf(String libraryId) =>
      '/library/$libraryId/suggestions';
  static String item(String itemId) => '/item/$itemId';
  static String itemListOf(String itemId) => '/item/$itemId/list';
  static String musicFavoritesOf(String parentId) =>
      '/music-favorites/$parentId';
  static String genre(String genreName) =>
      '/genre/${Uri.encodeComponent(genreName)}';
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
  static String jellyseerrMedia(String itemId) => '/jellyseerr/media/$itemId';
  static String jellyseerrPerson(String personId) =>
      '/jellyseerr/person/$personId';
}
