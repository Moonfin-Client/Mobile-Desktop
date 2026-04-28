enum AudioBehavior {
  directStream,
  downmixToStereo,
}

enum ClockBehavior {
  always,
  inMenus,
  inVideo,
  never,
}

enum MaxVideoResolution {
  auto(width: 0, height: 0),
  res480p(width: 720, height: 480),
  res720p(width: 1280, height: 720),
  res1080p(width: 1920, height: 1080),
  res2160p(width: 3840, height: 2160);

  const MaxVideoResolution({required this.width, required this.height});
  final int width;
  final int height;
}

enum NavbarPosition {
  top,
  left,
}

enum NextUpBehavior {
  extended,
  minimal,
  disabled;

  static const nextUpTimerDisabled = 0;
}

enum PosterSize {
  small(portraitHeight: 120, landscapeHeight: 88),
  medium(portraitHeight: 150, landscapeHeight: 110),
  large(portraitHeight: 180, landscapeHeight: 132),
  extraLarge(portraitHeight: 210, landscapeHeight: 154);

  const PosterSize({required this.portraitHeight, required this.landscapeHeight});
  final int portraitHeight;
  final int landscapeHeight;
}

enum RefreshRateSwitchingBehavior {
  disabled,
  scaleOnTv,
  scaleOnDevice,
}

enum StillWatchingBehavior {
  short_(episodes: 2, hours: 1.0),
  medium(episodes: 3, hours: 1.5),
  long_(episodes: 5, hours: 2.5),
  veryLong(episodes: 8, hours: 4.0),
  disabled(episodes: 0, hours: 0);

  const StillWatchingBehavior({required this.episodes, required this.hours});
  final int episodes;
  final double hours;
}

enum WatchedIndicatorBehavior {
  always,
  hideUnwatched,
  episodesOnly,
  never,
}

enum ZoomMode {
  fit,
  autoCrop,
  stretch,
}

enum AppTheme {
  white(0xFFFFFFFF),
  black(0xFF000000),
  gray(0xFF808080),
  darkBlue(0xFF003366),
  purple(0xFF6A0DAD),
  teal(0xFF008080),
  navy(0xFF000080),
  charcoal(0xFF36454F),
  brown(0xFF8B4513),
  darkRed(0xFF8B0000),
  darkGreen(0xFF006400),
  slate(0xFF708090),
  indigo(0xFF4B0082),
  moonfinCyan(0xFF00A4DC),
  neonPulseMagenta(0xFFFF2E92);

  const AppTheme(this.colorValue);
  final int colorValue;
}

enum VisualThemeId {
  moonfin,
  neonPulse,
}

enum RatingType {
  tomatoes,
  rtAudience,
  stars,
  imdb,
  tmdb,
  metacritic,
  metacriticUser,
  trakt,
  letterboxd,
  myAnimeList,
  aniList,
  hidden,
}

enum MediaSegmentAction {
  nothing,
  skip,
  askToSkip,
}

enum ImageType {
  poster,
  thumb,
  banner,
}

enum UserSelectBehavior {
  disabled,
  lastUser,
  specificUser,
}

enum HomeSectionType {
  mediaBar('mediabar'),
  latestMedia('latestmedia'),
  recentlyReleased('recentlyreleased'),
  libraryTilesSmall('smalllibrarytiles'),
  libraryButtons('librarybuttons'),
  resume('resume'),
  resumeAudio('resumeaudio'),
  resumeBook('resumebook'),
  activeRecordings('activerecordings'),
  nextUp('nextup'),
  playlists('playlists'),
  liveTv('livetv'),
  none('none');

  const HomeSectionType(this.serializedName);
  final String serializedName;

  static HomeSectionType fromSerialized(String name) {
    if (name == 'watchlist') return HomeSectionType.playlists;
    return HomeSectionType.values.firstWhere(
      (e) => e.serializedName == name,
      orElse: () => HomeSectionType.none,
    );
  }
}

enum LibrarySortBy {
  name('SortName', 'Name'),
  dateAdded('DateCreated', 'Date Added'),
  premiereDate('PremiereDate', 'Premiere Date'),
  rating('OfficialRating', 'Rating'),
  runtime('Runtime', 'Runtime'),
  random('Random', 'Random'),
  criticRating('CriticRating', 'Critic Rating'),
  communityRating('CommunityRating', 'Community Rating');

  const LibrarySortBy(this.apiValue, this.displayName);
  final String apiValue;
  final String displayName;
}

enum SortDirection {
  ascending,
  descending,
}

enum PlayedStatusFilter {
  all,
  watched,
  unwatched,
}

enum SeriesStatusFilter {
  all,
  continuing,
  ended,
}

enum FavoriteTypeFilter {
  all,
  movie,
  series,
  episode,
  person,
  musicAlbum,
  musicArtist,
  audio;

  String get displayName => switch (this) {
    all => 'All',
    movie => 'Movies',
    series => 'Series',
    episode => 'Episodes',
    person => 'People',
    musicAlbum => 'Albums',
    musicArtist => 'Artists',
    audio => 'Songs',
  };

  List<String>? get itemTypes => switch (this) {
    all => null,
    movie => ['Movie'],
    series => ['Series'],
    episode => ['Episode'],
    person => ['Person'],
    musicAlbum => ['MusicAlbum'],
    musicArtist => ['MusicArtist'],
    audio => ['Audio'],
  };
}

enum SeerrFetchLimit {
  small(25),
  medium(50),
  large(75);

  const SeerrFetchLimit(this.limit);
  final int limit;
}

enum SeerrRowType {
  recentRequests('recent_requests'),
  recentlyAdded('recently_added'),
  trending('trending'),
  popularMovies('popular_movies'),
  movieGenres('movie_genres'),
  upcomingMovies('upcoming_movies'),
  studios('studios'),
  popularSeries('popular_series'),
  seriesGenres('series_genres'),
  upcomingSeries('upcoming_series'),
  networks('networks');

  const SeerrRowType(this.serializedName);
  final String serializedName;

  static SeerrRowType fromSerialized(String name) =>
      SeerrRowType.values.firstWhere(
        (e) => e.serializedName == name,
        orElse: () => SeerrRowType.trending,
      );
}
