// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Moonfin';

  @override
  String get signIn => 'Sign In';

  @override
  String connectingToServer(String serverName) {
    return 'Connecting to $serverName';
  }

  @override
  String get quickConnect => 'Quick Connect';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get quickConnectInstruction =>
      'Enter this code on your server\'s web dashboard:';

  @override
  String get waitingForAuthorization => 'Waiting for authorization...';

  @override
  String get back => 'Back';

  @override
  String get serverUnavailable => 'Server is unavailable';

  @override
  String get loginFailed => 'Login failed';

  @override
  String quickConnectUnavailable(String detail) {
    return 'QuickConnect unavailable: $detail';
  }

  @override
  String quickConnectUnavailableWithStatus(String status, String detail) {
    return 'QuickConnect unavailable ($status): $detail';
  }

  @override
  String get whosWatching => 'Who\'s watching?';

  @override
  String get addUser => 'Add User';

  @override
  String get selectServer => 'Select Server';

  @override
  String appVersionFooter(String version) {
    return 'Moonfin version $version';
  }

  @override
  String get savedServers => 'Saved Servers';

  @override
  String get discoveredServers => 'Discovered Servers';

  @override
  String get noneFound => 'None found';

  @override
  String get unableToConnectToServer => 'Unable to connect to server';

  @override
  String get addServer => 'Add Server';

  @override
  String get embyConnect => 'Emby Connect';

  @override
  String get removeServer => 'Remove Server';

  @override
  String removeServerConfirmation(String serverName) {
    return 'Remove \"$serverName\" from your servers?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get connectToServer => 'Connect to Server';

  @override
  String get serverAddress => 'Server Address';

  @override
  String get serverAddressHint => 'https://your-server.example.com';

  @override
  String get connect => 'Connect';

  @override
  String get secureStorageUnavailable => 'Secure Storage Unavailable';

  @override
  String get secureStorageUnavailableMessage =>
      'Moonfin could not access your system keyring. Login can continue, but secure token storage may be unavailable until the keyring is unlocked.';

  @override
  String get ok => 'OK';

  @override
  String get embyConnectSignInSubtitle =>
      'Sign in with your Emby Connect account';

  @override
  String get emailOrUsername => 'Email or Username';

  @override
  String get selectAServer => 'Select a Server';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noLinkedServers =>
      'No servers linked to this Emby Connect account';

  @override
  String get invalidEmbyConnectCredentials =>
      'Invalid Emby Connect credentials';

  @override
  String get invalidEmbyConnectLogin =>
      'Invalid Emby Connect username or password';

  @override
  String get embyConnectExchangeNotSupported =>
      'Server does not support Emby Connect exchange';

  @override
  String get embyConnectNetworkError =>
      'Network error while contacting Emby Connect or the selected server';

  @override
  String get loadingLinkedServers => 'Loading linked servers...';

  @override
  String get connectingToServerEllipsis => 'Connecting to server...';

  @override
  String get noReachableAddress => 'No reachable address provided';

  @override
  String get invalidServerExchangeResponse =>
      'Invalid response from server exchange endpoint';

  @override
  String unableToConnectTo(String target) {
    return 'Unable to connect to $target';
  }

  @override
  String get exitApp => 'Exit Moonfin?';

  @override
  String get exitAppConfirmation => 'Are you sure you want to exit?';

  @override
  String get exit => 'Exit';

  @override
  String get noHomeRowsLoaded => 'No home rows could be loaded';

  @override
  String get noHomeRowsHint =>
      'Try refreshing or reducing active home sections.';

  @override
  String get retryHomeRows => 'Retry Home Rows';

  @override
  String get guide => 'Guide';

  @override
  String get recordings => 'Recordings';

  @override
  String get schedule => 'Schedule';

  @override
  String get series => 'Series';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get home => 'Home';

  @override
  String get browseAll => 'Browse All';

  @override
  String get genres => 'Genres';

  @override
  String get collectionPlaceholder => 'Collection items will appear here';

  @override
  String get browseByLetter => 'Browse by Letter';

  @override
  String get alphabeticalBrowsePlaceholder =>
      'Alphabetical browse will appear here';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get suggestionsPlaceholder => 'Suggested items will appear here';

  @override
  String get failedToLoadLibraries => 'Failed to load libraries';

  @override
  String get noLibrariesFound => 'No libraries found';

  @override
  String get library => 'Library';

  @override
  String get displaySettings => 'Display Settings';

  @override
  String get allGenres => 'All Genres';

  @override
  String get noGenresFound => 'No genres found';

  @override
  String failedToLoadFolderError(String error) {
    return 'Failed to load folder: $error';
  }

  @override
  String get thisFolderIsEmpty => 'This folder is empty';

  @override
  String itemCountLabel(int count) {
    return '$count items';
  }

  @override
  String get failedToLoadFavorites => 'Failed to load favorites';

  @override
  String get retry => 'Retry';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get favorites => 'Favorites';

  @override
  String totalCountItems(int count) {
    return '$count Items';
  }

  @override
  String get continuing => 'Continuing';

  @override
  String get ended => 'Ended';

  @override
  String get sortAndFilter => 'Sort & Filter';

  @override
  String get type => 'Type';

  @override
  String get sortBy => 'Sort By';

  @override
  String get display => 'Display';

  @override
  String get imageType => 'Image Type';

  @override
  String get posterSize => 'Poster Size';

  @override
  String get small => 'Small';

  @override
  String get medium => 'Medium';

  @override
  String get large => 'Large';

  @override
  String get extraLarge => 'Extra Large';

  @override
  String libraryGenresTitle(String name) {
    return '$name — Genres';
  }

  @override
  String get views => 'Views';

  @override
  String get albums => 'Albums';

  @override
  String get albumArtists => 'Album Artists';

  @override
  String get artists => 'Artists';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get noSavedBookmarks => 'No saved bookmarks for this title yet.';

  @override
  String get openBook => 'Open Book';

  @override
  String get chapter => 'Chapter';

  @override
  String get page => 'Page';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get discoverySubjects => 'Discovery Subjects';

  @override
  String get pickDiscoverySubjects =>
      'Pick which subject feeds to show in Discover.';

  @override
  String get apply => 'Apply';

  @override
  String get audiobookGenres => 'Audiobook Genres';

  @override
  String get pickAudiobookGenres =>
      'Pick which genres to show in Audiobook Discover.';

  @override
  String get discoverAudiobooks => 'Discover Audiobooks';

  @override
  String get librivoxDescription =>
      'Popular public domain titles from LibriVox.';

  @override
  String titlesCount(int count) {
    return '$count titles';
  }

  @override
  String get scrollLeft => 'Scroll left';

  @override
  String get scrollRight => 'Scroll right';

  @override
  String get couldNotLoadGenre => 'Could not load this genre right now.';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get savedHighlights => 'Saved Highlights';

  @override
  String get continueListening => 'Continue Listening';

  @override
  String get listen => 'Listen';

  @override
  String get resume => 'Resume';

  @override
  String get failedToLoadLibrary => 'Failed to load library';

  @override
  String get popularNow => 'Popular Now';

  @override
  String get savedForLater => 'Saved For Later';

  @override
  String get topListens => 'Top Listens';

  @override
  String get unreadDiscoveries => 'Unread Discoveries';

  @override
  String get pickUpAgain => 'Pick Up Again';

  @override
  String get bookHighlightsDescription =>
      'Your books with highlights, favorites, or reading progress.';

  @override
  String get handPickedFromLibrary => 'Hand-picked from your library.';

  @override
  String get handPickedFromListeningQueue =>
      'Hand-picked from your listening queue.';

  @override
  String get booksWithHighlights =>
      'Books with highlights, favorites, or reading progress.';

  @override
  String get jumpBackNarration =>
      'Jump back into narration without hunting for your place.';

  @override
  String get unreadBooksReady => 'Unread books ready for the next quiet hour.';

  @override
  String get quickAccessFavorites =>
      'Quick access to the books you keep coming back to.';

  @override
  String get searchAudiobooks => 'Search audiobooks';

  @override
  String get searchYourLibrary => 'Search your library';

  @override
  String get pickUpStory => 'Pick up the story where you left off';

  @override
  String get savedPlacesChapters => 'Your saved places and unfinished chapters';

  @override
  String authorsCount(int count) {
    return '$count authors';
  }

  @override
  String genresCount(int count) {
    return '$count genres';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% completed';
  }

  @override
  String get readyWhenYouAre => 'Ready when you are';

  @override
  String get details => 'Details';

  @override
  String get listeningRoom => 'Listening Room';

  @override
  String get bookmarksAndProgress => 'Bookmarks & Progress';

  @override
  String titlesArrangedForBrowsing(int count) {
    return '$count titles arranged for reading-first browsing.';
  }

  @override
  String get titles => 'Titles';

  @override
  String get allTitles => 'All Titles';

  @override
  String get authors => 'Authors';

  @override
  String get browseByAuthor => 'Browse By Author';

  @override
  String get browseByGenre => 'Browse By Genre';

  @override
  String get discover => 'Discover';

  @override
  String get trendingTitlesOpenLibrary =>
      'Trending titles by subject from Open Library.';

  @override
  String get noBookmarkedItems => 'No bookmarked items yet';

  @override
  String get nothingMatchesSection =>
      'Nothing matches this section yet. Try another tab or come back after the library sync finishes.';

  @override
  String get audiobooks => 'Audiobooks';

  @override
  String noLabelFound(String label) {
    return 'No $label found';
  }

  @override
  String get folder => 'Folder';

  @override
  String get filters => 'Filters';

  @override
  String get readingStatus => 'Reading Status';

  @override
  String get playedStatus => 'Played Status';

  @override
  String get readStatus => 'Read';

  @override
  String get watched => 'Watched';

  @override
  String get unread => 'Unread';

  @override
  String get unwatched => 'Unwatched';

  @override
  String get seriesStatus => 'Series Status';

  @override
  String get allLibraries => 'All Libraries';

  @override
  String get books => 'Books';

  @override
  String get author => 'Author';

  @override
  String get unknownAuthor => 'Unknown Author';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get overview => 'Overview';

  @override
  String get noLibrivoxDescription =>
      'No description provided by LibriVox for this title yet.';

  @override
  String get readers => 'Readers';

  @override
  String get openLinks => 'Open Links';

  @override
  String get librivoxPage => 'LibriVox Page';

  @override
  String get internetArchive => 'Internet Archive';

  @override
  String get rssFeed => 'RSS Feed';

  @override
  String get downloadZip => 'Download Zip';

  @override
  String sectionCountLabel(int count) {
    return '$count sections';
  }

  @override
  String firstPublished(int year) {
    return 'First published $year';
  }

  @override
  String get noOpenLibraryOverview =>
      'No overview available from Open Library for this title yet.';

  @override
  String get subjects => 'Subjects';

  @override
  String get all => 'All';

  @override
  String booksCount(int count) {
    return '$count books';
  }

  @override
  String get couldNotLoadSubject => 'Could not load this subject right now.';

  @override
  String get audiobookDetails => 'Audiobook Details';

  @override
  String authorsCountTitle(int count) {
    return '$count Authors';
  }

  @override
  String audiobookCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count audiobooks',
      one: '1 audiobook',
    );
    return '$_temp0';
  }

  @override
  String get trackList => 'Track List';

  @override
  String get itemListPlaceholder => 'Item list will appear here';

  @override
  String get favoriteTracksPlaceholder => 'Favorite tracks will appear here';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get moreLikeThis => 'More Like This';

  @override
  String get castAndCrew => 'Cast & Crew';

  @override
  String get collection => 'Collection';

  @override
  String get episodes => 'Episodes';

  @override
  String get nextUp => 'Next Up';

  @override
  String get seasons => 'Seasons';

  @override
  String get chapters => 'Chapters';

  @override
  String get features => 'Features';

  @override
  String get movies => 'Movies';

  @override
  String get other => 'Other';

  @override
  String get discography => 'Discography';

  @override
  String get similarArtists => 'Similar Artists';

  @override
  String get tableOfContents => 'Table of Contents';

  @override
  String get tracklist => 'Tracklist';

  @override
  String get biography => 'Biography';

  @override
  String get authorDetails => 'Author Details';

  @override
  String get noOverviewAvailable => 'No overview available for this title yet.';

  @override
  String get noBiographyAvailable => 'No biography available for this author.';

  @override
  String get noBooksFound => 'No books found for this author.';

  @override
  String get unableToLoadAuthorDetails =>
      'Unable to load author details right now.';

  @override
  String published(int year) {
    return 'Published $year';
  }

  @override
  String get publicationDateUnknown => 'Publication date unknown';

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seasons',
      one: '1 Season',
    );
    return '$_temp0';
  }

  @override
  String endsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get view => 'View';

  @override
  String get resumeReading => 'Resume Reading';

  @override
  String get read => 'Read';

  @override
  String resumeFrom(String position) {
    return 'Resume from $position';
  }

  @override
  String get play => 'Play';

  @override
  String get startOver => 'Start Over';

  @override
  String get restart => 'Restart';

  @override
  String get readOffline => 'Read Offline';

  @override
  String get playOffline => 'Play Offline';

  @override
  String get audio => 'Audio';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get version => 'Version';

  @override
  String get cast => 'Cast';

  @override
  String get trailer => 'Trailer';

  @override
  String get finished => 'Finished';

  @override
  String get favorited => 'Favorited';

  @override
  String get favorite => 'Favorite';

  @override
  String get playlist => 'Playlist';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get downloadAll => 'Download All';

  @override
  String get download => 'Download';

  @override
  String get deleteDownloaded => 'Delete Downloaded';

  @override
  String get goToSeries => 'Go to Series';

  @override
  String get editMetadata => 'Edit Metadata';

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String get deletePlaylistMessage => 'Delete this playlist from the server?';

  @override
  String get deleteItemMessage => 'Delete this item from the server?';

  @override
  String get failedToDeletePlaylist => 'Failed to delete playlist';

  @override
  String get failedToDeleteItem => 'Failed to delete item';

  @override
  String get renamePlaylist => 'Rename Playlist';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get deleteDownloadedAlbum => 'Delete Downloaded Album';

  @override
  String deleteDownloadedTracksMessage(String title) {
    return 'Delete downloaded tracks for \"$title\"?';
  }

  @override
  String get downloadedTracksDeleted => 'Downloaded tracks deleted';

  @override
  String get downloadedTracksDeleteFailed =>
      'Some downloaded tracks could not be deleted';

  @override
  String get noTracksLoaded => 'No tracks loaded';

  @override
  String noItemsLoaded(String itemLabel) {
    return 'No $itemLabel loaded';
  }

  @override
  String downloadingTitle(String title, int count) {
    return 'Downloading $title ($count items)...';
  }

  @override
  String deleteConfirmMessage(String name) {
    return 'Are you sure you want to delete \"$name\" from the server? This action cannot be undone.';
  }

  @override
  String get itemDeleted => 'Item deleted';

  @override
  String get noPlayableTrailerFound => 'No playable trailer found.';

  @override
  String unsupportedBookFormat(String extension) {
    return 'Unsupported book format: .$extension';
  }

  @override
  String get audioTrack => 'Audio Track';

  @override
  String get subtitleTrack => 'Subtitle Track';

  @override
  String get none => 'None';

  @override
  String get downloadSubtitlesLabel => 'Download subtitles...';

  @override
  String get searchOpenSubtitlesPlugin =>
      'Search using the OpenSubtitles plugin';

  @override
  String get downloadSubtitles => 'Download Subtitles';

  @override
  String get selectedSubtitleInvalid => 'The selected subtitle is invalid.';

  @override
  String subtitleDownloadedSelected(String name) {
    return 'Subtitle downloaded and selected: $name';
  }

  @override
  String get subtitleDownloadedPending =>
      'Subtitle downloaded. It may take a moment to appear while Jellyfin refreshes the item.';

  @override
  String noRemoteSubtitlesFound(String language) {
    return 'No remote subtitles found for $language.';
  }

  @override
  String get selectVersion => 'Select Version';

  @override
  String versionNumber(int number) {
    return 'Version $number';
  }

  @override
  String get downloadAllQuality => 'Download All — Quality';

  @override
  String get downloadQuality => 'Download Quality';

  @override
  String get originalFileNoReencoding => 'Original file, no re-encoding';

  @override
  String get originalFilesNoReencoding => 'Original files, no re-encoding';

  @override
  String get noEpisodesLoaded => 'No episodes loaded';

  @override
  String downloadingItem(String name, String quality) {
    return 'Downloading $name ($quality)...';
  }

  @override
  String get deleteDownloadedFiles => 'Delete Downloaded Files';

  @override
  String deleteLocalFilesMessage(String typeLabel) {
    return 'Delete local files for $typeLabel?\n\nThis will free up storage space. You can re-download later.';
  }

  @override
  String get downloadedFilesDeleted => 'Downloaded files deleted';

  @override
  String get failedToDeleteFiles => 'Failed to delete files';

  @override
  String get deleteFiles => 'Delete Files';

  @override
  String get director => 'DIRECTOR';

  @override
  String get writers => 'WRITERS';

  @override
  String get studio => 'STUDIO';

  @override
  String studioMoreCount(int count) {
    return '+$count more';
  }

  @override
  String totalEpisodes(int count) {
    return '$count Episodes';
  }

  @override
  String episodeProgress(int watched, int total) {
    return '$watched / $total';
  }

  @override
  String episodeLabel(int number) {
    return 'Episode $number';
  }

  @override
  String chapterNumber(int number) {
    return 'Chapter $number';
  }

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String chapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '1 chapter',
    );
    return '$_temp0';
  }

  @override
  String born(String date) {
    return 'Born $date';
  }

  @override
  String died(String date) {
    return 'Died $date';
  }

  @override
  String age(int age) {
    return 'Age $age';
  }

  @override
  String get showLess => 'Show Less';

  @override
  String get readMore => 'Read More';

  @override
  String get shuffle => 'Shuffle';

  @override
  String downloadsCount(int count) {
    return '$count downloads';
  }

  @override
  String get perfectMatch => 'Perfect match';

  @override
  String channelsCount(int count) {
    return '${count}ch';
  }

  @override
  String get mono => 'Mono';

  @override
  String get stereo => 'Stereo';

  @override
  String remoteSubtitlePermissionError(String action) {
    return 'Remote subtitle $action requires the Jellyfin subtitle management permission for this user.';
  }

  @override
  String remoteSubtitleNotFoundError(String action) {
    return 'This item could not be found on the server for remote subtitle $action.';
  }

  @override
  String remoteSubtitleDetailError(String action, String detail) {
    return 'Remote subtitle $action failed: $detail';
  }

  @override
  String remoteSubtitleHttpError(String action, int status) {
    return 'Remote subtitle $action failed (HTTP $status).';
  }

  @override
  String remoteSubtitleGenericError(String action) {
    return 'Failed to $action remote subtitles.';
  }

  @override
  String deleteSeriesFiles(String name) {
    return 'all downloaded episodes for \"$name\"';
  }

  @override
  String get deleteSeasonFiles => 'all downloaded episodes in this season';

  @override
  String get stillWatching => 'Still Watching?';

  @override
  String get unableToLoadTrailerStream => 'Unable to load trailer stream.';

  @override
  String get trailerTimedOut => 'Trailer timed out while loading.';

  @override
  String get playbackFailedForTrailer => 'Playback failed for this trailer.';

  @override
  String photoCountOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get castingUnavailableOffline =>
      'Casting is unavailable during offline playback.';

  @override
  String castActionFailed(String label, String error) {
    return '$label action failed: $error';
  }

  @override
  String failedToSetCastVolume(String error) {
    return 'Failed to set cast volume: $error';
  }

  @override
  String castControlsTitle(String label) {
    return '$label Controls';
  }

  @override
  String get deviceVolume => 'Device Volume';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get pause => 'Pause';

  @override
  String get syncPosition => 'Sync Position';

  @override
  String stopCast(String label) {
    return 'Stop $label';
  }

  @override
  String get queueIsEmpty => 'Queue is empty';

  @override
  String trackNumber(int number) {
    return 'Track $number';
  }

  @override
  String get remotePlayback => 'Remote Playback';

  @override
  String get castingToGoogleCast => 'Casting to Google Cast';

  @override
  String get castingViaAirPlay => 'Casting via AirPlay';

  @override
  String get castingViaDlna => 'Casting via DLNA';

  @override
  String secondsCount(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get longPressToUnlock => 'Long press to unlock';

  @override
  String get off => 'Off';

  @override
  String streamTypeFallback(String streamType, int number) {
    return '$streamType $number';
  }

  @override
  String get auto => 'Auto';

  @override
  String bitrateValueMbps(int mbps) {
    return '$mbps Mbps';
  }

  @override
  String get audioDelay => 'Audio Delay';

  @override
  String get subtitleDelay => 'Subtitle Delay';

  @override
  String get reset => 'Reset';

  @override
  String get unknown => 'Unknown';

  @override
  String get playbackInformation => 'Playback Information';

  @override
  String get playback => 'Playback';

  @override
  String get playMethod => 'Play Method';

  @override
  String get directPlay => 'Direct Play';

  @override
  String get directStream => 'Direct Stream';

  @override
  String get transcoding => 'Transcoding';

  @override
  String get transcodeReasons => 'Transcode Reasons';

  @override
  String get player => 'Player';

  @override
  String get container => 'Container';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get video => 'Video';

  @override
  String get resolution => 'Resolution';

  @override
  String get hdr => 'HDR';

  @override
  String get codec => 'Codec';

  @override
  String get videoBitrate => 'Video Bitrate';

  @override
  String get track => 'Track';

  @override
  String get channels => 'Channels';

  @override
  String get audioBitrate => 'Audio Bitrate';

  @override
  String get sampleRate => 'Sample Rate';

  @override
  String get format => 'Format';

  @override
  String get external => 'External';

  @override
  String get embedded => 'Embedded';

  @override
  String castSessionError(String protocol) {
    return '$protocol session error';
  }

  @override
  String failedToLoadBookDetails(String error) {
    return 'Failed to load book details: $error';
  }

  @override
  String get epubUnavailableOnPlatform =>
      'EPUB rendering in-app is not available on this platform yet.';

  @override
  String formatCannotRenderInApp(String extension) {
    return 'This format (.$extension) cannot be rendered in-app yet.';
  }

  @override
  String get embeddedRenderingUnavailable =>
      'Embedded document rendering is unavailable on this platform.';

  @override
  String get couldNotOpenExternalViewer => 'Could not open external viewer.';

  @override
  String failedToOpenInAppReader(String error) {
    return 'Failed to open in-app reader: $error';
  }

  @override
  String bookmarkAlreadySaved(String label) {
    return 'Bookmark already saved at $label.';
  }

  @override
  String bookmarkAdded(String label) {
    return 'Bookmark added: $label';
  }

  @override
  String get noBookmarksYet =>
      'No bookmarks yet.\nTap the bookmark icon while reading to save your position.';

  @override
  String get noTableOfContentsAvailable => 'No table of contents available';

  @override
  String pageLabel(int number) {
    return 'Page $number';
  }

  @override
  String get position => 'Position';

  @override
  String get bookReader => 'Book Reader';

  @override
  String formatExtension(String extension) {
    return 'Format: .$extension';
  }

  @override
  String percentRead(String percent) {
    return '$percent% read';
  }

  @override
  String get updating => 'Updating...';

  @override
  String get markUnread => 'Mark Unread';

  @override
  String get markAsRead => 'Mark as Read';

  @override
  String get reloadReader => 'Reload Reader';

  @override
  String get noPagesFound => 'No pages found.';

  @override
  String get failedToDecodePageImage => 'Failed to decode page image.';

  @override
  String resetZoom(String zoom) {
    return 'Reset Zoom (${zoom}x)';
  }

  @override
  String get singlePage => 'Single Page';

  @override
  String get twoPageSpread => 'Two-Page Spread';

  @override
  String get addBookmark => 'Add Bookmark';

  @override
  String get bookmarksEllipsis => 'Bookmarks...';

  @override
  String get markedAsRead => 'Marked as read';

  @override
  String get markedAsUnread => 'Marked as unread';

  @override
  String failedToUpdateReadState(String error) {
    return 'Failed to update read state: $error';
  }

  @override
  String get themeSystem => 'Theme: System';

  @override
  String get themeLight => 'Theme: Light';

  @override
  String get themeDark => 'Theme: Dark';

  @override
  String get themeSepia => 'Theme: Sepia';

  @override
  String get invertColorsFixedLayout => 'Invert Colors (fixed layout)';

  @override
  String get invertColorsPdf => 'Invert Colors (PDF)';

  @override
  String get preparingInAppReader => 'Preparing in-app reader...';

  @override
  String get pdfDataNotAvailable => 'PDF data not available.';

  @override
  String get readerFallbackModeActive => 'Reader fallback mode active';

  @override
  String platformCannotHostDocumentEngine(String extension) {
    return 'This platform cannot host the embedded document engine for $extension files.';
  }

  @override
  String get reloadReaderPlatformHint =>
      'Use Reload Reader after switching to a supported platform target (Android, iOS, macOS).';

  @override
  String get openExternally => 'Open Externally';

  @override
  String get noEpubChaptersFound => 'No EPUB chapters found.';

  @override
  String get readerNotReady => 'Reader not ready.';

  @override
  String get seriesRecordings => 'Series Recordings';

  @override
  String get now => 'Now';

  @override
  String get sports => 'Sports';

  @override
  String get news => 'News';

  @override
  String get kids => 'Kids';

  @override
  String get premiere => 'Premiere';

  @override
  String get guideTimeline => 'Guide Timeline';

  @override
  String failedToLoadGuide(String error) {
    return 'Failed to load guide: $error';
  }

  @override
  String get noChannelsFound => 'No channels found';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get movie => 'Movie';

  @override
  String get removedFromFavoriteChannels => 'Removed from favorite channels';

  @override
  String get addedToFavoriteChannels => 'Added to favorite channels';

  @override
  String get failedToUpdateFavoriteChannel =>
      'Failed to update favorite channel';

  @override
  String get unfavoriteChannel => 'Unfavorite Channel';

  @override
  String get favoriteChannel => 'Favorite Channel';

  @override
  String get watch => 'Watch';

  @override
  String get close => 'Close';

  @override
  String failedToPlayChannel(String name) {
    return 'Failed to play $name';
  }

  @override
  String get failedToLoadRecordings => 'Failed to load recordings';

  @override
  String get scheduledInNext24Hours => 'Scheduled in Next 24 Hours';

  @override
  String get recentRecordings => 'Recent Recordings';

  @override
  String get tvSeries => 'TV Series';

  @override
  String get failedToLoadSchedule => 'Failed to load schedule';

  @override
  String get noScheduledRecordings => 'No scheduled recordings';

  @override
  String get cancelRecording => 'Cancel Recording?';

  @override
  String cancelScheduledRecordingOf(String name) {
    return 'Cancel scheduled recording of \"$name\"?';
  }

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get failedToCancelRecording => 'Failed to cancel recording';

  @override
  String get failedToLoadSeriesRecordings => 'Failed to load series recordings';

  @override
  String get noSeriesRecordings => 'No series recordings';

  @override
  String get cancelSeriesRecording => 'Cancel Series Recording';

  @override
  String get cancelSeriesRecordingQuestion => 'Cancel Series Recording?';

  @override
  String stopRecordingName(String name) {
    return 'Stop recording \"$name\"?';
  }

  @override
  String get failedToCancelSeriesRecording =>
      'Failed to cancel series recording';

  @override
  String get searchThisLibrary => 'Search this library...';

  @override
  String get searchEllipsis => 'Search...';

  @override
  String noResultsForQuery(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String searchFailedError(String error) {
    return 'Search failed: $error';
  }

  @override
  String get seerr => 'Seerr';

  @override
  String get savedMedia => 'Saved Media';

  @override
  String get tvShows => 'TV Shows';

  @override
  String get music => 'Music';

  @override
  String get musicAlbums => 'Music Albums';

  @override
  String get noMediaInFilter => 'No media in this filter';

  @override
  String get noDownloadedMediaYet => 'No downloaded media yet';

  @override
  String get browseLibrary => 'Browse Library';

  @override
  String get deleteDownload => 'Delete Download';

  @override
  String removeItemAndFiles(String name) {
    return 'Remove \"$name\" and its files?';
  }

  @override
  String tracksCount(int count) {
    return '$count tracks';
  }

  @override
  String get album => 'Album';

  @override
  String get playAlbum => 'Play Album';

  @override
  String failedToLoadAlbum(String error) {
    return 'Failed to load album: $error';
  }

  @override
  String noDownloadedTracksForAlbum(String name) {
    return 'No downloaded tracks found for $name.';
  }

  @override
  String get season => 'Season';

  @override
  String get errorLoadingEpisodes => 'Error loading episodes';

  @override
  String get noDownloadedEpisodes => 'No downloaded episodes';

  @override
  String get deleteEpisode => 'Delete Episode';

  @override
  String removeName(String name) {
    return 'Remove \"$name\"?';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String seasonEpisodeLabel(int season, int episode) {
    return 'S$season E$episode';
  }

  @override
  String episodeNumber(int number) {
    return 'Episode $number';
  }

  @override
  String get seriesNotFound => 'Series not found';

  @override
  String get errorLoadingSeries => 'Error loading series';

  @override
  String get downloadedEpisodes => 'Downloaded Episodes';

  @override
  String seasonNumber(int number) {
    return 'Season $number';
  }

  @override
  String get specials => 'Specials';

  @override
  String get deleteSeason => 'Delete Season';

  @override
  String deleteAllEpisodesInSeason(String season) {
    return 'Delete all downloaded episodes in $season?';
  }

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String get storageManagement => 'Storage Management';

  @override
  String get storageBreakdown => 'Storage Breakdown';

  @override
  String get downloadedItems => 'Downloaded Items';

  @override
  String get storageLimit => 'Storage Limit';

  @override
  String get noLimit => 'No limit';

  @override
  String get deleteAllDownloads => 'Delete All Downloads';

  @override
  String get deleteAllDownloadsWarning =>
      'This will remove all downloaded media files and cannot be undone.';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String deleteSelectedCount(int count) {
    return 'Delete $count downloaded items?';
  }

  @override
  String get musicAndAudiobooks => 'Music & Audiobooks';

  @override
  String get images => 'Images';

  @override
  String get database => 'Database';

  @override
  String ofStorageLimit(String limit) {
    return 'of $limit limit';
  }

  @override
  String get settings => 'Settings';

  @override
  String get authentication => 'Authentication';

  @override
  String get autoLoginServerManagement => 'Auto login, server management';

  @override
  String get pinCode => 'PIN Code';

  @override
  String get setUpPinCodeProtection => 'Set up PIN code protection';

  @override
  String get parentalControls => 'Parental Controls';

  @override
  String get contentRatingRestrictions => 'Content rating restrictions';

  @override
  String get bitRateResolutionBehavior => 'Bitrate, resolution, behavior';

  @override
  String get languageSizeAppearance => 'Language, size, appearance';

  @override
  String get qualityStorage => 'Quality, storage';

  @override
  String get serverSyncAndPluginStatus => 'Server sync and plugin status';

  @override
  String get mediaRequestIntegration => 'Media request integration';

  @override
  String get switchServer => 'Switch Server';

  @override
  String get signOut => 'Sign Out';

  @override
  String get versionLicenses => 'Version, licenses';

  @override
  String get account => 'Account';

  @override
  String get signInAndSecurity => 'Sign-in and security';

  @override
  String get administration => 'Administration';

  @override
  String get serverSettingsUsersLibraries =>
      'Server settings, users, libraries';

  @override
  String get customization => 'Customization';

  @override
  String get themeAndLayout => 'Theme and layout';

  @override
  String get videoAndSubtitles => 'Video and subtitles';

  @override
  String get integrations => 'Integrations';

  @override
  String get pluginAndRequests => 'Plugin and requests';

  @override
  String get customizeAccountPlaybackInterface =>
      'Customize account, playback, and interface behavior';

  @override
  String optionsCount(int count) {
    return '$count options';
  }

  @override
  String get themeAndAppearance => 'Theme & Appearance';

  @override
  String get focusBorderColor => 'Focus Border Color';

  @override
  String get watchedIndicators => 'Watched Indicators';

  @override
  String get always => 'Always';

  @override
  String get hideUnwatched => 'Hide Unwatched';

  @override
  String get episodesOnly => 'Episodes Only';

  @override
  String get never => 'Never';

  @override
  String get focusExpansionAnimation => 'Focus Expansion Animation';

  @override
  String get scaleFocusedCards => 'Scale focused or hovered cards and tiles';

  @override
  String get backgroundBackdrops => 'Background Backdrops';

  @override
  String get showBackdropImages => 'Show backdrop images behind content';

  @override
  String get seriesThumbnails => 'Series Thumbnails';

  @override
  String get seriesThumbnailsDescription =>
      'Episodes only: use series artwork that matches each row image type';

  @override
  String get homeRowInfoOverlay => 'Home Row Info Overlay';

  @override
  String get showTitleMetadataOnHomeRows =>
      'Show title and metadata when browsing home rows';

  @override
  String get clockDisplay => 'Clock Display';

  @override
  String get inMenus => 'In Menus';

  @override
  String get inVideo => 'In Video';

  @override
  String get seasonalEffects => 'Seasonal Effects';

  @override
  String get snow => 'Snow';

  @override
  String get fireworks => 'Fireworks';

  @override
  String get confetti => 'Confetti';

  @override
  String get fallingLeaves => 'Falling Leaves';

  @override
  String get themeMusic => 'Theme Music';

  @override
  String get playThemeMusicOnDetailPages => 'Play theme music on detail pages';

  @override
  String get themeMusicVolume => 'Theme Music Volume';

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String get themeMusicOnHomeRows => 'Theme Music on Home Rows';

  @override
  String get playWhenBrowsingHomeScreen => 'Play when browsing home screen';

  @override
  String get detailsBackgroundBlur => 'Details Background Blur';

  @override
  String pixelValue(int value) {
    return '${value}px';
  }

  @override
  String get browsingBackgroundBlur => 'Browsing Background Blur';

  @override
  String get maxStreamingBitrate => 'Max Streaming Bitrate';

  @override
  String get maxResolution => 'Max Resolution';

  @override
  String get playerZoomMode => 'Player Zoom Mode';

  @override
  String get fit => 'Fit';

  @override
  String get autoCrop => 'Auto Crop';

  @override
  String get stretch => 'Stretch';

  @override
  String get refreshRateSwitching => 'Refresh Rate Switching';

  @override
  String get disabled => 'Disabled';

  @override
  String get scaleOnTv => 'Scale on TV';

  @override
  String get scaleOnDevice => 'Scale on Device';

  @override
  String get trickPlay => 'Trick Play';

  @override
  String get showPreviewThumbnailsWhenSeeking =>
      'Show preview thumbnails when seeking';

  @override
  String get showDescriptionOnPause => 'Show Description on Pause';

  @override
  String get dimVideoShowOverview =>
      'Dim video and show overview text while paused';

  @override
  String get osdLockButton => 'OSD Lock Button';

  @override
  String get osdLockButtonDescription =>
      'Show a lock button that blocks touch input until long-pressed';

  @override
  String get audioBehavior => 'Audio Behavior';

  @override
  String get downmixToStereo => 'Downmix to Stereo';

  @override
  String get defaultAudioLanguage => 'Default Audio Language';

  @override
  String get autoServerDefault => 'Auto (Server Default)';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get french => 'French';

  @override
  String get german => 'German';

  @override
  String get italian => 'Italian';

  @override
  String get portuguese => 'Portuguese';

  @override
  String get japanese => 'Japanese';

  @override
  String get korean => 'Korean';

  @override
  String get chinese => 'Chinese';

  @override
  String get russian => 'Russian';

  @override
  String get arabic => 'Arabic';

  @override
  String get hindi => 'Hindi';

  @override
  String get dutch => 'Dutch';

  @override
  String get swedish => 'Swedish';

  @override
  String get norwegian => 'Norwegian';

  @override
  String get danish => 'Danish';

  @override
  String get finnish => 'Finnish';

  @override
  String get polish => 'Polish';

  @override
  String get ac3Passthrough => 'AC3 Passthrough';

  @override
  String get trueHdSupport => 'TrueHD Support';

  @override
  String get enableTrueHdAudio =>
      'Enable TrueHD audio (may not work on all platforms)';

  @override
  String get nightMode => 'Night Mode';

  @override
  String get compressDynamicRange => 'Compress dynamic range';

  @override
  String get advancedMpv => 'Advanced mpv';

  @override
  String get enableCustomMpvConf => 'Enable Custom mpv.conf';

  @override
  String get applyMpvConfBeforePlayback =>
      'Apply a user-specified mpv.conf before playback starts';

  @override
  String get unsafeAdvancedMpvOptions => 'Unsafe Advanced mpv Options';

  @override
  String get unsafeMpvOptionsDescription =>
      'Allow a wider set of mpv options. May break playback behavior.';

  @override
  String get nextUpAndQueuing => 'Next Up & Queuing';

  @override
  String get nextUpBehavior => 'Next Up Behavior';

  @override
  String get extended => 'Extended';

  @override
  String get minimal => 'Minimal';

  @override
  String get nextUpTimeout => 'Next Up Timeout';

  @override
  String secondsValue(int value) {
    return '${value}s';
  }

  @override
  String get mediaQueuing => 'Media Queuing';

  @override
  String get autoQueueNextEpisodes => 'Auto-queue next episodes';

  @override
  String get stillWatchingPrompt => 'Still Watching Prompt';

  @override
  String afterEpisodesAndHours(int episodes, double hours) {
    return 'After $episodes episodes / ${hours}h';
  }

  @override
  String get resumeAndSkip => 'Resume & Skip';

  @override
  String get resumeRewind => 'Resume Rewind';

  @override
  String get fiveSeconds => '5 seconds';

  @override
  String get tenSeconds => '10 seconds';

  @override
  String get fifteenSeconds => '15 seconds';

  @override
  String get thirtySeconds => '30 seconds';

  @override
  String get skipBackLength => 'Skip Back Length';

  @override
  String get skipForwardLength => 'Skip Forward Length';

  @override
  String get customMpvConfPath => 'Custom mpv.conf Path';

  @override
  String get notSetMpvConf =>
      'Not set. Moonfin will try a default mpv.conf in app/data folders.';

  @override
  String get selectMpvConf => 'Select mpv.conf';

  @override
  String get pathToMpvConf => '/path/to/mpv.conf';

  @override
  String get subtitleStyleDescription =>
      'Style settings (size, color, offset) apply to text-based subtitles (SRT, VTT, TTML). ASS/SSA subtitles use their own embedded styling unless \"ASS/SSA Direct Play\" is turned off. Bitmap subtitles (PGS, DVB, VobSub) cannot be restyled.';

  @override
  String get defaultSubtitleLanguage => 'Default Subtitle Language';

  @override
  String get defaultToNoSubtitles => 'Default to No Subtitles';

  @override
  String get turnOffSubtitlesByDefault => 'Turn off subtitles by default';

  @override
  String get subtitleSize => 'Subtitle Size';

  @override
  String get textColor => 'Text Color';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get strokeColor => 'Stroke Color';

  @override
  String get verticalOffset => 'Vertical Offset';

  @override
  String get pgsDirectPlay => 'PGS Direct Play';

  @override
  String get directPlayPgsSubtitles => 'Direct play PGS subtitles';

  @override
  String get assSsaDirectPlay => 'ASS/SSA Direct Play';

  @override
  String get directPlayAssSsaSubtitles => 'Direct play ASS/SSA subtitles';

  @override
  String get white => 'White';

  @override
  String get black => 'Black';

  @override
  String get yellow => 'Yellow';

  @override
  String get green => 'Green';

  @override
  String get cyan => 'Cyan';

  @override
  String get red => 'Red';

  @override
  String get transparent => 'Transparent';

  @override
  String get semiTransparentBlack => 'Semi-transparent Black';

  @override
  String get global => 'Global';

  @override
  String get desktop => 'Desktop';

  @override
  String get mobile => 'Mobile';

  @override
  String get tv => 'TV';

  @override
  String loadedProfileSettings(String profile) {
    return 'Loaded $profile profile settings.';
  }

  @override
  String failedToLoadProfileSettings(String profile) {
    return 'Failed to load $profile profile settings.';
  }

  @override
  String syncedSettingsToProfile(String profile) {
    return 'Synced local settings to $profile profile.';
  }

  @override
  String get customizationProfile => 'Customization Profile';

  @override
  String get customizationProfileDescription =>
      'Choose the profile to load, edit, and sync. Global applies everywhere unless a device profile overrides it. The green dot marks your current device profile.';

  @override
  String get loadProfile => 'Load Profile';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncToProfile => 'Sync To Profile';

  @override
  String get profileSyncHidden => 'Profile Sync Hidden';

  @override
  String get enablePluginSyncDescription =>
      'Enable Server Plugin Sync in Plugin settings to show profile controls here.';

  @override
  String get quality => 'Quality';

  @override
  String get defaultDownloadQuality => 'Default Download Quality';

  @override
  String get network => 'Network';

  @override
  String get wifiOnlyDownloads => 'WiFi-Only Downloads';

  @override
  String get onlyDownloadOnWifi => 'Only download when connected to WiFi';

  @override
  String get storage => 'Storage';

  @override
  String get storageUsed => 'Storage Used';

  @override
  String get manage => 'Manage';

  @override
  String get calculating => 'Calculating...';

  @override
  String get downloadLocation => 'Download Location';

  @override
  String get defaultLabel => 'Default';

  @override
  String get saveToDownloadsFolder => 'Save to Downloads folder';

  @override
  String get downloadsVisibleToOtherApps =>
      'Downloads/Moonfin — visible to other apps';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get clearAllDownloads => 'Clear All Downloads';

  @override
  String get original => 'Original';

  @override
  String get changeDownloadLocation => 'Change Download Location';

  @override
  String get changeDownloadLocationDescription =>
      'New downloads will be saved to the selected folder. Existing downloads will remain in their current location and can be managed from Storage settings.';

  @override
  String get confirm => 'Confirm';

  @override
  String get cannotWriteToFolder =>
      'Cannot write to selected folder. Please choose a different location or grant storage permissions.';

  @override
  String get saveToDownloadsFolderQuestion => 'Save to Downloads folder?';

  @override
  String get saveToDownloadsFolderDescription =>
      'Downloaded media will be saved to Downloads/Moonfin on your device. These files will be visible to other apps such as your gallery or music player.\n\nExisting downloads will remain in their current location.';

  @override
  String get enable => 'Enable';

  @override
  String get clearAllDownloadsWarning =>
      'This will delete all downloaded media and cannot be undone.';

  @override
  String get clearAll => 'Clear All';

  @override
  String get navigationStyle => 'Navigation Style';

  @override
  String get topBar => 'Top Bar';

  @override
  String get leftSidebar => 'Left Sidebar';

  @override
  String get showShuffleButton => 'Show Shuffle Button';

  @override
  String get showGenresButton => 'Show Genres Button';

  @override
  String get showFavoritesButton => 'Show Favorites Button';

  @override
  String get showLibrariesInToolbar => 'Show Libraries in Toolbar';

  @override
  String get navbarOpacity => 'Navbar Opacity';

  @override
  String get navbarColor => 'Navbar Color';

  @override
  String get gray => 'Gray';

  @override
  String get darkBlue => 'Dark Blue';

  @override
  String get purple => 'Purple';

  @override
  String get teal => 'Teal';

  @override
  String get navy => 'Navy';

  @override
  String get charcoal => 'Charcoal';

  @override
  String get brown => 'Brown';

  @override
  String get darkRed => 'Dark Red';

  @override
  String get darkGreen => 'Dark Green';

  @override
  String get slate => 'Slate';

  @override
  String get indigo => 'Indigo';

  @override
  String get libraryDisplay => 'Library Display';

  @override
  String get posterLabel => 'Poster';

  @override
  String get thumbnailLabel => 'Thumbnail';

  @override
  String get bannerLabel => 'Banner';

  @override
  String get overridePerLibrarySettings => 'Override Per-Library Settings';

  @override
  String get applyImageTypeToAllLibraries =>
      'Apply image type to all libraries';

  @override
  String get multiServerLibraries => 'Multi-Server Libraries';

  @override
  String get showLibrariesFromAllServers =>
      'Show libraries from all connected servers';

  @override
  String get enableFolderView => 'Enable Folder View';

  @override
  String get showFolderBrowsingOption => 'Show folder browsing option';

  @override
  String get libraryVisibility => 'Library Visibility';

  @override
  String get showInNavigation => 'Show in navigation';

  @override
  String get showInLatestMedia => 'Show in latest media';

  @override
  String get sourceLibraries => 'Source Libraries';

  @override
  String get sourceCollections => 'Source Collections';

  @override
  String get excludedGenres => 'Excluded Genres';

  @override
  String get selectAll => 'Select All';

  @override
  String itemsSelected(int count) {
    return '$count selected';
  }

  @override
  String get mediaBar => 'Media Bar';

  @override
  String get enableMediaBar => 'Enable Media Bar';

  @override
  String get showFeaturedContentSlideshow =>
      'Show featured content slideshow on home';

  @override
  String get contentType => 'Content Type';

  @override
  String get moviesAndTvShows => 'Movies & TV Shows';

  @override
  String get moviesOnly => 'Movies Only';

  @override
  String get tvShowsOnly => 'TV Shows Only';

  @override
  String get itemCount => 'Item Count';

  @override
  String get noneSelected => 'None selected';

  @override
  String get noneExcluded => 'None excluded';

  @override
  String get autoAdvance => 'Auto Advance';

  @override
  String get autoAdvanceSlides => 'Automatically advance to next slide';

  @override
  String get autoAdvanceInterval => 'Auto Advance Interval';

  @override
  String get trailerPreview => 'Trailer Preview';

  @override
  String get autoPlayTrailers =>
      'Auto-play trailers in the media bar after 3 seconds';

  @override
  String get episodePreview => 'Episode Preview';

  @override
  String get episodePreviewDescription =>
      'Play a 30-second inline preview on focused, hovered, or long-pressed cards';

  @override
  String get previewAudio => 'Preview Audio';

  @override
  String get enablePreviewAudio =>
      'Enable audio for trailer and episode previews';

  @override
  String get latestMedia => 'Latest Media';

  @override
  String get recentlyReleased => 'Recently Released';

  @override
  String get myMedia => 'My Media';

  @override
  String get myMediaSmall => 'My Media (Small)';

  @override
  String get continueWatching => 'Continue Watching';

  @override
  String get resumeAudio => 'Resume Audio';

  @override
  String get resumeBooks => 'Resume Books';

  @override
  String get activeRecordings => 'Active Recordings';

  @override
  String get playlists => 'Playlists';

  @override
  String get liveTV => 'Live TV';

  @override
  String get homeSections => 'Home Sections';

  @override
  String get resetToDefaults => 'Reset to defaults';

  @override
  String get homeRowPosterSize => 'Home Row Poster Size';

  @override
  String get perRowImageTypeSelection => 'Per Row Image Type Selection';

  @override
  String get configureImageTypeForEachRow =>
      'Configure image type for each enabled home row';

  @override
  String get mergeContinueWatchingAndNextUp =>
      'Merge Continue Watching and Next Up';

  @override
  String get combineBothRows => 'Combine both rows into a single home section';

  @override
  String get perRowImageType => 'Per Row Image Type';

  @override
  String get perRowSettings => 'Per-Row Settings';

  @override
  String get autoLogin => 'Auto Login';

  @override
  String get lastUser => 'Last User';

  @override
  String get specificUser => 'Specific User';

  @override
  String get alwaysAuthenticate => 'Always Authenticate';

  @override
  String get requirePasswordWithToken =>
      'Require password even with stored token';

  @override
  String get confirmExit => 'Confirm Exit';

  @override
  String get showConfirmationBeforeExiting =>
      'Show confirmation before exiting';

  @override
  String get blockContentWithRatings =>
      'Block content with the following ratings:';

  @override
  String get noContentRatingsFound =>
      'No content ratings were found on this server yet.';

  @override
  String get couldNotLoadServerRatings =>
      'Could not load server ratings. Showing saved ratings only.';

  @override
  String get couldNotRefreshRatings =>
      'Could not refresh ratings from server. Showing saved ratings.';

  @override
  String get enablePinCode => 'Enable PIN Code';

  @override
  String get requirePinToAccess => 'Require a PIN to access your account';

  @override
  String get changePin => 'Change PIN';

  @override
  String get setNewPinCode => 'Set a new PIN code';

  @override
  String get removePin => 'Remove PIN';

  @override
  String get removePinProtection => 'Remove PIN code protection';

  @override
  String get screensaver => 'Screensaver';

  @override
  String get inAppScreensaver => 'In-App Screensaver';

  @override
  String get enableBuiltInScreensaver => 'Enable the built-in screensaver';

  @override
  String get mode => 'Mode';

  @override
  String get libraryArt => 'Library Art';

  @override
  String get logo => 'Logo';

  @override
  String get clock => 'Clock';

  @override
  String get timeout => 'Timeout';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get dimmingLevel => 'Dimming Level';

  @override
  String get maxAgeRating => 'Max Age Rating';

  @override
  String get any => 'Any';

  @override
  String agePlusValue(int age) {
    return '$age+';
  }

  @override
  String get requireAgeRating => 'Require Age Rating';

  @override
  String get onlyShowRatedContent => 'Only show rated content';

  @override
  String get showClock => 'Show Clock';

  @override
  String get displayClockDuringScreensaver =>
      'Display clock during screensaver';

  @override
  String get rottenTomatoesCritics => 'Rotten Tomatoes (Critics)';

  @override
  String get rottenTomatoesAudience => 'Rotten Tomatoes (Audience)';

  @override
  String get imdb => 'IMDb';

  @override
  String get tmdb => 'TMDB';

  @override
  String get metacritic => 'Metacritic';

  @override
  String get metacriticUser => 'Metacritic (User)';

  @override
  String get trakt => 'Trakt';

  @override
  String get letterboxd => 'Letterboxd';

  @override
  String get myAnimeList => 'MyAnimeList';

  @override
  String get aniList => 'AniList';

  @override
  String get communityRating => 'Community Rating';

  @override
  String get ratings => 'Ratings';

  @override
  String get additionalRatings => 'Additional Ratings';

  @override
  String get showMdbListAndTmdbRatings => 'Show MDBList and TMDB ratings';

  @override
  String get ratingLabels => 'Rating Labels';

  @override
  String get showLabelsNextToIcons => 'Show labels next to rating icons';

  @override
  String get ratingBadges => 'Rating Badges';

  @override
  String get showDecorativeBadges => 'Show decorative badges behind ratings';

  @override
  String get episodeRatings => 'Episode Ratings';

  @override
  String get showRatingsOnEpisodes => 'Show ratings on individual episodes';

  @override
  String get ratingSources => 'Rating Sources';

  @override
  String get ratingSourcesDescription =>
      'Enable and reorder the rating sources shown throughout the app';

  @override
  String get pluginLabel => 'Plugin';

  @override
  String get pluginDetected => 'Plugin Detected';

  @override
  String get pluginNotDetected => 'Plugin Not Detected';

  @override
  String get pluginDetectedDescription =>
      'Server plugin detected. Sync is enabled automatically the first time the plugin is found.';

  @override
  String get pluginNotDetectedDescription =>
      'Server plugin is not currently detected. Local settings still use their saved values or built-in defaults.';

  @override
  String pluginStatusVersion(String status, String version) {
    return '$status\nVersion: $version';
  }

  @override
  String get availableServices => 'Available Services';

  @override
  String get serverPluginSync => 'Server Plugin Sync';

  @override
  String get syncSettingsWithPlugin => 'Sync settings with the server plugin';

  @override
  String get whatSyncControls => 'What sync controls';

  @override
  String get syncControlsDescription =>
      'Sync only controls whether plugin-backed settings are pushed to and pulled from the server. Profile selection and profile sync actions are in Customization settings when plugin sync is enabled.';

  @override
  String get recentRequests => 'Recent Requests';

  @override
  String get recentlyAdded => 'Recently Added';

  @override
  String get trending => 'Trending';

  @override
  String get popularMovies => 'Popular Movies';

  @override
  String get movieGenres => 'Movie Genres';

  @override
  String get upcomingMovies => 'Upcoming Movies';

  @override
  String get studios => 'Studios';

  @override
  String get popularSeries => 'Popular Series';

  @override
  String get seriesGenres => 'Series Genres';

  @override
  String get upcomingSeries => 'Upcoming Series';

  @override
  String get networks => 'Networks';

  @override
  String get resetRowsToDefaults => 'Reset rows to defaults';

  @override
  String get enableSeerr => 'Enable Seerr';

  @override
  String get showSeerrInNavigation =>
      'Show Seerr in navigation (requires server plugin)';

  @override
  String get seerrUnavailable =>
      'Unavailable because server plugin Seerr support is disabled.';

  @override
  String get nsfwFilter => 'NSFW Filter';

  @override
  String get hideAdultContent => 'Hide adult content in results';

  @override
  String loggedInAs(String username) {
    return 'Logged in as: $username';
  }

  @override
  String get discoverRows => 'Discover Rows';

  @override
  String get discoverRowsDescriptionPlugin =>
      'Drag to reorder. Enable or disable rows. Enabled row order syncs with the Moonfin plugin.';

  @override
  String get discoverRowsDescription =>
      'Drag to reorder. Enable or disable rows.';

  @override
  String get enabled => 'Enabled';

  @override
  String get hidden => 'Hidden';

  @override
  String get aboutTitle => 'About';

  @override
  String versionValue(String version) {
    return 'Version $version';
  }

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get sourceCode => 'Source Code';

  @override
  String get checkForUpdatesNow => 'Check for Updates Now';

  @override
  String get checksLatestDesktopRelease =>
      'Checks latest desktop release for this platform';

  @override
  String get youAreUpToDate => 'You are up to date.';

  @override
  String get couldNotCheckForUpdates =>
      'Could not check for updates right now.';

  @override
  String get noCompatibleUpdate =>
      'No compatible update package found for this platform.';

  @override
  String get updateChecksNotSupported =>
      'Update checks are not supported on this platform.';

  @override
  String get updateNotificationsDisabled =>
      'Update notifications are disabled.';

  @override
  String get pleaseWaitBeforeChecking => 'Please wait before checking again.';

  @override
  String get latestUpdateAlreadyShown => 'Latest update was already shown.';

  @override
  String get updateAvailable => 'Update available.';

  @override
  String updateAvailableVersion(String version) {
    return 'Update available: v$version';
  }

  @override
  String get updateNotifications => 'Update Notifications';

  @override
  String get showWhenUpdatesAvailable => 'Show when updates are available';

  @override
  String get navigation => 'Navigation';

  @override
  String get watchedIndicatorsBackdrops => 'Watched indicators, backdrops';

  @override
  String get focusColorWatchedIndicatorsBackdrops =>
      'Focus color, watched indicators, backdrops';

  @override
  String get navbarStyleToolbarAppearance =>
      'Navbar style, toolbar buttons, appearance';

  @override
  String get reorderToggleHomeRows => 'Reorder and toggle home rows';

  @override
  String get featuredContentAppearance => 'Featured content, appearance';

  @override
  String get posterSizeImageTypeFolderView =>
      'Poster size, image type, folder view';

  @override
  String get mdbListTmdbRatingSources => 'MDBList, TMDB, and rating sources';

  @override
  String gbValue(String value) {
    return '$value GB';
  }

  @override
  String get clear => 'Clear';

  @override
  String get browse => 'Browse';

  @override
  String get noResults => 'No results';

  @override
  String get seerrAvailableStatus => 'Available';

  @override
  String get seerrRequestedStatus => 'Requested';

  @override
  String itemsCount(int count) {
    return '$count Items';
  }

  @override
  String get seerrSettings => 'Seerr Settings';

  @override
  String get requestMore => 'Request More';

  @override
  String get request => 'Request';

  @override
  String get cancelRequest => 'Cancel Request';

  @override
  String get playInMoonfin => 'Play in Moonfin';

  @override
  String requestedByName(String name) {
    return 'Requested by $name';
  }

  @override
  String get approve => 'Approve';

  @override
  String get declineAction => 'Decline';

  @override
  String get similar => 'Similar';

  @override
  String get recommendations => 'Recommendations';

  @override
  String cancelRequestForTitle(String title) {
    return 'Cancel request for \"$title\"?';
  }

  @override
  String cancelCountRequestsForTitle(int count, String title) {
    return 'Cancel $count requests for \"$title\"?';
  }

  @override
  String get keep => 'Keep';

  @override
  String get itemNotFoundInLibrary => 'Item not found in your Moonfin library';

  @override
  String get errorSearchingLibrary => 'Error searching library';

  @override
  String budgetAmount(String amount) {
    return 'Budget: \$$amount';
  }

  @override
  String revenueAmount(String amount) {
    return 'Revenue: \$$amount';
  }

  @override
  String seasonsCount(int count, String label) {
    return '$count $label';
  }

  @override
  String requestSeriesOrMovie(String type) {
    return 'Request $type';
  }

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get allSeasons => 'All Seasons';

  @override
  String get advancedOptions => 'Advanced Options';

  @override
  String get noServiceServersConfigured => 'No service servers configured';

  @override
  String get server => 'Server';

  @override
  String get qualityProfile => 'Quality Profile';

  @override
  String get rootFolder => 'Root Folder';

  @override
  String get showMore => 'Show More';

  @override
  String get appearances => 'Appearances';

  @override
  String get crewSection => 'Crew';

  @override
  String ageValue(int age) {
    return 'age $age';
  }

  @override
  String get noRequests => 'No requests';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get declinedStatus => 'Declined';

  @override
  String get partiallyAvailable => 'Partially Available';

  @override
  String get downloadingStatus => 'Downloading';

  @override
  String get approvedStatus => 'Approved';

  @override
  String get access => 'Access';

  @override
  String get add => 'Add';

  @override
  String get address => 'Address';

  @override
  String get analytics => 'Analytics';

  @override
  String get catalog => 'Catalog';

  @override
  String get content => 'Content';

  @override
  String get copy => 'Copy';

  @override
  String get create => 'Create';

  @override
  String get disable => 'Disable';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get encoding => 'Encoding';

  @override
  String get error => 'Error';

  @override
  String get forward => 'Forward';

  @override
  String get general => 'General';

  @override
  String get go => 'Go';

  @override
  String get install => 'Install';

  @override
  String get installed => 'Installed';

  @override
  String get interval => 'Interval';

  @override
  String get name => 'Name';

  @override
  String get networking => 'Networking';

  @override
  String get next => 'Next';

  @override
  String get path => 'Path';

  @override
  String get paused => 'Paused';

  @override
  String get permissions => 'Permissions';

  @override
  String get processing => 'Processing';

  @override
  String get profile => 'Profile';

  @override
  String get provider => 'Provider';

  @override
  String get refresh => 'Refresh';

  @override
  String get remote => 'Remote';

  @override
  String get rename => 'Rename';

  @override
  String get revoke => 'Revoke';

  @override
  String get role => 'Role';

  @override
  String get root => 'Root';

  @override
  String get run => 'Run';

  @override
  String get search => 'Search';

  @override
  String get select => 'Select';

  @override
  String get send => 'Send';

  @override
  String get sessions => 'Sessions';

  @override
  String get set => 'Set';

  @override
  String get status => 'Status';

  @override
  String get stop => 'Stop';

  @override
  String get streaming => 'Streaming';

  @override
  String get time => 'Time';

  @override
  String get trickplay => 'Trickplay';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get up => 'Up';

  @override
  String get update => 'Update';

  @override
  String get upload => 'Upload';

  @override
  String get unmute => 'Unmute';

  @override
  String get mute => 'Mute';

  @override
  String get branding => 'Branding';

  @override
  String get adminDrawerDashboard => 'Dashboard';

  @override
  String get adminDrawerAnalytics => 'Analytics';

  @override
  String get adminDrawerSettings => 'Settings';

  @override
  String get adminDrawerBranding => 'Branding';

  @override
  String get adminDrawerUsers => 'Users';

  @override
  String get adminDrawerLibraries => 'Libraries';

  @override
  String get adminDrawerTranscoding => 'Transcoding';

  @override
  String get adminDrawerResume => 'Resume';

  @override
  String get adminDrawerStreaming => 'Streaming';

  @override
  String get adminDrawerTrickplay => 'Trickplay';

  @override
  String get adminDrawerDevices => 'Devices';

  @override
  String get adminDrawerActivity => 'Activity';

  @override
  String get adminDrawerNetworking => 'Networking';

  @override
  String get adminDrawerApiKeys => 'API Keys';

  @override
  String get adminDrawerBackups => 'Backups';

  @override
  String get adminDrawerLogs => 'Logs';

  @override
  String get adminDrawerScheduledTasks => 'Scheduled Tasks';

  @override
  String get adminDrawerPlugins => 'Plugins';

  @override
  String get adminDrawerRepositories => 'Repositories';

  @override
  String get adminDrawerLiveTv => 'Live TV';

  @override
  String get adminExitTooltip => 'Exit Admin';

  @override
  String get adminDashboardLoadFailed => 'Failed to load dashboard';

  @override
  String get adminMediaOverview => 'Media Overview';

  @override
  String get adminMediaTotalsError => 'Could not load server media totals.';

  @override
  String get adminMediaOverviewSubtitle =>
      'A quick read on how much content is on this server.';

  @override
  String adminPluginUpdatesAvailable(int count) {
    return 'Plugin updates available: $count';
  }

  @override
  String adminPluginsRequiringRestart(int count) {
    return 'Plugins requiring restart: $count';
  }

  @override
  String adminFailedScheduledTasks(int count) {
    return 'Failed scheduled tasks: $count';
  }

  @override
  String adminRecentAlertEntries(int count) {
    return 'Recent warning/error entries: $count';
  }

  @override
  String get analyticsMediaDistribution => 'Media Distribution';

  @override
  String get analyticsVideoCodecs => 'Video Codecs';

  @override
  String get analyticsAudioCodecs => 'Audio Codecs';

  @override
  String get analyticsContainers => 'Containers';

  @override
  String get analyticsTopGenres => 'Top Genres';

  @override
  String get analyticsReleaseYears => 'Release Years';

  @override
  String get analyticsContentRatings => 'Content Ratings';

  @override
  String get analyticsRuntimeBuckets => 'Runtime Buckets';

  @override
  String get analyticsFileFormats => 'File Formats';

  @override
  String get analyticsNoData => 'No Data Available.';

  @override
  String get adminServerInfo => 'Server Info';

  @override
  String get adminRestartPending => 'Restart Pending';

  @override
  String get adminServerPaths => 'Server Paths';

  @override
  String get adminServerActions => 'Server Actions';

  @override
  String get adminRestartServer => 'Restart Server';

  @override
  String get adminShutdownServer => 'Shutdown Server';

  @override
  String get adminScanLibraries => 'Scan Libraries';

  @override
  String get adminLibraryScanStarted => 'Library scan started';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get adminServerRebootInProgress => 'Server reboot in progress';

  @override
  String get adminServerRebootMessage =>
      'Server reboot in progress, please restart Moonfin';

  @override
  String get adminActiveSessions => 'Active Sessions';

  @override
  String get adminSessionsLoadFailed => 'Failed to load sessions';

  @override
  String get adminNoActiveSessions => 'No active sessions';

  @override
  String get adminRecentActivity => 'Recent Activity';

  @override
  String get adminNoRecentActivity => 'No recent activity';

  @override
  String adminCommandFailed(String error) {
    return 'Command failed: $error';
  }

  @override
  String get adminSendMessage => 'Send Message';

  @override
  String get adminMessageTextHint => 'Message text';

  @override
  String get adminSetVolume => 'Set Volume';

  @override
  String get sessionPrev => 'Prev';

  @override
  String get sessionRewind => 'Rewind';

  @override
  String get sessionForward => 'Forward';

  @override
  String get sessionNext => 'Next';

  @override
  String get sessionVolumeDown => 'Vol –';

  @override
  String get sessionVolumeUp => 'Vol +';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get volume => 'Volume';

  @override
  String get actions => 'Actions';

  @override
  String get videoCodec => 'Video Codec';

  @override
  String get audioCodec => 'Audio Codec';

  @override
  String get hwAccel => 'HW Accel';

  @override
  String get completion => 'Completion';

  @override
  String get direct => 'Direct';

  @override
  String get adminDisconnect => 'Disconnect';

  @override
  String get adminClearDates => 'Clear dates';

  @override
  String adminActivityLoadFailed(String error) {
    return 'Failed to load activity log: $error';
  }

  @override
  String get adminNoActivityEntries => 'No activity entries';

  @override
  String get adminEditDeviceName => 'Edit Device Name';

  @override
  String get adminCustomName => 'Custom Name';

  @override
  String get adminDeviceNameUpdated => 'Device name updated';

  @override
  String adminDeviceUpdateFailed(String error) {
    return 'Failed to update device: $error';
  }

  @override
  String get adminDeleteDevice => 'Delete Device';

  @override
  String get adminDeviceDeleted => 'Device deleted';

  @override
  String adminDeviceDeleteFailed(String error) {
    return 'Failed to delete device: $error';
  }

  @override
  String get adminDevicesLoadFailed => 'Failed to load devices';

  @override
  String get adminSearchDevices => 'Search devices';

  @override
  String get adminThisDevice => 'This Device';

  @override
  String get adminEditName => 'Edit Name';

  @override
  String get adminLibrariesLoadFailed => 'Failed to load libraries';

  @override
  String get adminNoLibraries => 'No libraries configured';

  @override
  String get adminScanAllLibraries => 'Scan All Libraries';

  @override
  String get adminAddLibrary => 'Add Library';

  @override
  String adminScanFailed(String error) {
    return 'Failed to start scan: $error';
  }

  @override
  String get adminRenameLibrary => 'Rename Library';

  @override
  String get adminNewName => 'New name';

  @override
  String adminLibraryRenamed(String name) {
    return 'Library renamed to \"$name\"';
  }

  @override
  String adminRenameFailed(String error) {
    return 'Failed to rename: $error';
  }

  @override
  String get adminDeleteLibrary => 'Delete Library';

  @override
  String adminLibraryDeleted(String name) {
    return 'Library \"$name\" deleted';
  }

  @override
  String adminLibraryDeleteFailed(String error) {
    return 'Failed to delete library: $error';
  }

  @override
  String adminAddPathFailed(String error) {
    return 'Failed to add path: $error';
  }

  @override
  String get adminRemovePath => 'Remove Path';

  @override
  String adminRemovePathConfirm(String path) {
    return 'Remove \"$path\" from this library?';
  }

  @override
  String adminRemovePathFailed(String error) {
    return 'Failed to remove path: $error';
  }

  @override
  String get adminLibraryOptionsSaved => 'Library options saved';

  @override
  String adminLibraryOptionsSaveFailed(String error) {
    return 'Failed to save options: $error';
  }

  @override
  String get adminLibraryLoadFailed => 'Failed to load library';

  @override
  String get adminNoMediaPaths => 'No media paths configured';

  @override
  String get adminAddPath => 'Add Path';

  @override
  String get adminBrowseFilesystem => 'Browse server filesystem:';

  @override
  String get adminSaveOptions => 'Save Options';

  @override
  String get adminPreferredMetadataLanguage => 'Preferred metadata language';

  @override
  String get adminMetadataLanguageHint => 'e.g. en, de, fr';

  @override
  String get adminMetadataCountryCode => 'Metadata country code';

  @override
  String get adminMetadataCountryHint => 'e.g. US, DE, FR';

  @override
  String get adminLibraryNameRequired => 'Library name is required';

  @override
  String adminLibraryCreateFailed(String error) {
    return 'Failed to create library: $error';
  }

  @override
  String get adminLibraryName => 'Library Name';

  @override
  String get adminSelectedPaths => 'Selected Paths:';

  @override
  String get adminNoPathsAdded => 'No paths added (can be added later)';

  @override
  String get adminCreateLibrary => 'Create Library';

  @override
  String get paths => 'Paths:';

  @override
  String get adminDisableUser => 'Disable User';

  @override
  String get adminEnableUser => 'Enable User';

  @override
  String adminDisableUserConfirm(String name) {
    return 'Disable $name? They will not be able to sign in.';
  }

  @override
  String adminEnableUserConfirm(String name) {
    return 'Enable $name? They will be able to sign in again.';
  }

  @override
  String adminUserDisabled(String name) {
    return 'User \"$name\" disabled';
  }

  @override
  String adminUserEnabled(String name) {
    return 'User \"$name\" enabled';
  }

  @override
  String adminUserPolicyUpdateFailed(String error) {
    return 'Failed to update user policy: $error';
  }

  @override
  String get adminUsersLoadFailed => 'Failed to load users';

  @override
  String get adminSearchUsers => 'Search users';

  @override
  String get adminEditUser => 'Edit User';

  @override
  String get adminAddUser => 'Add User';

  @override
  String adminUserCreateFailed(String error) {
    return 'Failed to create user: $error';
  }

  @override
  String get adminCreateUser => 'Create User';

  @override
  String get adminPasswordOptional => 'Password (optional)';

  @override
  String get adminUsernameRequired => 'Username cannot be empty';

  @override
  String get adminNoProfileChanges => 'No profile changes to save';

  @override
  String get adminProfileSaved => 'Profile saved';

  @override
  String adminSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get adminPermissionsSaved => 'Permissions saved';

  @override
  String get adminPasswordsMismatch => 'Passwords do not match';

  @override
  String adminFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get adminUserLoadFailed => 'Failed to load user';

  @override
  String get adminBackToUsers => 'Back to Users';

  @override
  String get adminSaveProfile => 'Save Profile';

  @override
  String get adminDeleteUser => 'Delete User';

  @override
  String get admin => 'Admin';

  @override
  String get adminFullAccessWarning =>
      'Administrators have complete access to the server. Grant with caution.';

  @override
  String get administrator => 'Administrator';

  @override
  String get adminHiddenUser => 'Hidden user';

  @override
  String get adminAllowMediaPlayback => 'Allow media playback';

  @override
  String get adminAllowAudioTranscoding => 'Allow audio transcoding';

  @override
  String get adminAllowVideoTranscoding => 'Allow video transcoding';

  @override
  String get adminAllowRemuxing => 'Allow remuxing';

  @override
  String get adminForceRemoteTranscoding => 'Force remote source transcoding';

  @override
  String get adminAllowContentDeletion => 'Allow content deletion';

  @override
  String get adminAllowContentDownloading => 'Allow content downloading';

  @override
  String get adminAllowPublicSharing => 'Allow public sharing';

  @override
  String get adminAllowRemoteControl => 'Allow remote control of other users';

  @override
  String get adminAllowSharedDeviceControl => 'Allow shared device control';

  @override
  String get adminAllowRemoteAccess => 'Allow remote access';

  @override
  String get adminRemoteBitrateLimit => 'Remote client bitrate limit (bps)';

  @override
  String get adminLeaveEmptyNoLimit => 'Leave empty for no limit';

  @override
  String get adminMaxActiveSessions => 'Max active sessions';

  @override
  String get adminAllowLiveTvAccess => 'Allow Live TV access';

  @override
  String get adminAllowLiveTvManagement => 'Allow Live TV management';

  @override
  String get adminAllowCollectionManagement => 'Allow collection management';

  @override
  String get adminAllowSubtitleManagement => 'Allow subtitle management';

  @override
  String get adminAllowLyricManagement => 'Allow lyric management';

  @override
  String get adminSavePermissions => 'Save Permissions';

  @override
  String get adminEnableAllLibraryAccess => 'Enable access to all libraries';

  @override
  String get adminSaveAccess => 'Save Access';

  @override
  String get adminChangePassword => 'Change Password';

  @override
  String get adminNewPassword => 'New Password';

  @override
  String get adminConfirmPassword => 'Confirm Password';

  @override
  String get adminSetPassword => 'Set Password';

  @override
  String get adminResetPassword => 'Reset Password';

  @override
  String adminDeleteUserConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String adminUserDeleted(String name) {
    return 'User \"$name\" deleted';
  }

  @override
  String adminUserDeleteFailed(String error) {
    return 'Failed to delete user: $error';
  }

  @override
  String get adminCreateApiKey => 'Create API Key';

  @override
  String get adminAppName => 'App name';

  @override
  String get adminApiKeyCreated => 'API Key Created';

  @override
  String get adminApiKeyCreatedNoToken =>
      'Key created successfully. The server did not return the token. Check server API keys.';

  @override
  String get adminKeyCopied => 'Key copied to clipboard';

  @override
  String adminApiKeyCreateFailed(String error) {
    return 'Failed to create key: $error';
  }

  @override
  String get adminKeyTokenMissing => 'Key token missing from server response';

  @override
  String get adminRevokeApiKey => 'Revoke API Key';

  @override
  String adminRevokeKeyConfirm(String name) {
    return 'Revoke key for $name?';
  }

  @override
  String get adminApiKeyRevoked => 'API key revoked';

  @override
  String adminApiKeyRevokeFailed(String error) {
    return 'Failed to revoke key: $error';
  }

  @override
  String get adminApiKeysLoadFailed => 'Failed to load API keys';

  @override
  String get adminCreateKey => 'Create Key';

  @override
  String get adminNoApiKeys => 'No API keys found';

  @override
  String get adminCreatingBackup => 'Creating backup...';

  @override
  String get adminBackupCreated => 'Backup created successfully';

  @override
  String adminBackupCreateFailed(String error) {
    return 'Failed to create backup: $error';
  }

  @override
  String get adminBackupPathMissing => 'Backup path missing in server response';

  @override
  String adminBackupManifest(String name) {
    return 'Manifest: $name';
  }

  @override
  String adminManifestLoadFailed(String error) {
    return 'Failed to load manifest: $error';
  }

  @override
  String get adminConfirmRestore => 'Confirm Restore';

  @override
  String get adminRestoringBackup => 'Restoring backup...';

  @override
  String adminRestoreFailed(String error) {
    return 'Failed to restore backup: $error';
  }

  @override
  String get adminBackupsLoadFailed => 'Failed to load backups';

  @override
  String get adminCreateBackup => 'Create Backup';

  @override
  String get adminNoBackups => 'No backups found';

  @override
  String get adminViewDetails => 'View Details';

  @override
  String get restore => 'Restore';

  @override
  String get adminLogsLoadFailed => 'Failed to load server logs';

  @override
  String get adminNoLogFiles => 'No log files found';

  @override
  String get adminLogCopied => 'Log copied to clipboard';

  @override
  String get adminSaveLogFile => 'Save log file';

  @override
  String adminSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String adminFileSaveFailed(String error) {
    return 'Failed to save file: $error';
  }

  @override
  String adminLogFileLoadFailed(String fileName) {
    return 'Failed to load $fileName';
  }

  @override
  String get adminSearchInLog => 'Search in log';

  @override
  String get adminNoMatchingLines => 'No matching lines';

  @override
  String adminTasksLoadFailed(String error) {
    return 'Failed to load tasks: $error';
  }

  @override
  String get adminNoScheduledTasks => 'No scheduled tasks found';

  @override
  String get adminNoTasksMatchFilter => 'No tasks match the current filter';

  @override
  String adminTaskStartFailed(String error) {
    return 'Failed to start task: $error';
  }

  @override
  String adminTaskStopFailed(String error) {
    return 'Failed to stop task: $error';
  }

  @override
  String adminTaskLoadFailed(String error) {
    return 'Failed to load task: $error';
  }

  @override
  String get adminRunNow => 'Run Now';

  @override
  String adminTriggerRemoveFailed(String error) {
    return 'Failed to remove trigger: $error';
  }

  @override
  String adminTriggerAddFailed(String error) {
    return 'Failed to add trigger: $error';
  }

  @override
  String get adminLastExecution => 'Last Execution';

  @override
  String get adminTriggers => 'Triggers';

  @override
  String get adminAddTrigger => 'Add Trigger';

  @override
  String get adminNoTriggers => 'No triggers configured';

  @override
  String get adminTriggerType => 'Trigger Type';

  @override
  String get adminTimeLimit => 'Time limit (optional)';

  @override
  String get adminNoLimit => 'No limit';

  @override
  String adminHours(String hours) {
    return '$hours hour(s)';
  }

  @override
  String get adminDayOfWeek => 'Day of week';

  @override
  String get adminSearchPlugins => 'Search plugins...';

  @override
  String adminPluginToggleFailed(String error) {
    return 'Failed to toggle plugin: $error';
  }

  @override
  String get adminUninstallPlugin => 'Uninstall Plugin';

  @override
  String adminUninstallPluginConfirm(String name) {
    return 'Are you sure you want to uninstall \"$name\"?';
  }

  @override
  String adminPluginUninstallFailed(String error) {
    return 'Failed to uninstall plugin: $error';
  }

  @override
  String adminPackageInstallFailed(String error) {
    return 'Failed to install package: $error';
  }

  @override
  String adminPluginUpdateFailed(String error) {
    return 'Failed to install update: $error';
  }

  @override
  String adminPluginsLoadFailed(String error) {
    return 'Failed to load plugins: $error';
  }

  @override
  String get adminNoPluginsMatchSearch => 'No plugins match your search';

  @override
  String get adminNoPluginsInstalled => 'No plugins installed';

  @override
  String adminInstallUpdate(String version) {
    return 'Install update (v$version)';
  }

  @override
  String adminCatalogLoadFailed(String error) {
    return 'Failed to load catalog: $error';
  }

  @override
  String get adminNoPackagesMatchSearch => 'No packages match your search';

  @override
  String get adminNoPackagesAvailable => 'No packages available';

  @override
  String get adminExperimentalIntegration => 'Experimental Integration';

  @override
  String get adminExperimentalWarning =>
      'Plugin settings integration is still experimental. Some settings pages may not render correctly.';

  @override
  String get continueAction => 'Continue';

  @override
  String adminPluginRemoveAfterRestart(String name) {
    return '\"$name\" will be removed after server restart';
  }

  @override
  String adminUninstallFailed(String error) {
    return 'Failed to uninstall: $error';
  }

  @override
  String adminPluginUpdating(String name, String version) {
    return 'Updating \"$name\" to v$version...';
  }

  @override
  String get adminMissingAuthToken =>
      'Unable to open settings: missing auth token.';

  @override
  String adminPluginLoadFailed(String error) {
    return 'Failed to load plugin: $error';
  }

  @override
  String get adminPluginNotFound => 'Plugin not found';

  @override
  String adminPluginVersion(String version) {
    return 'Version $version';
  }

  @override
  String get adminEnablePlugin => 'Enable Plugin';

  @override
  String get adminPluginSettingsPage => 'Plugin settings page';

  @override
  String get adminRevisionHistory => 'Revision History';

  @override
  String get adminNoChangelog => 'No changelog available.';

  @override
  String get adminRemoveRepository => 'Remove Repository';

  @override
  String adminRemoveRepositoryConfirm(String name) {
    return 'Are you sure you want to remove \"$name\"?';
  }

  @override
  String adminRepositoriesSaveFailed(String error) {
    return 'Failed to save repositories: $error';
  }

  @override
  String adminRepositoriesLoadFailed(String error) {
    return 'Failed to load repositories: $error';
  }

  @override
  String get adminRepositoryNameHint => 'e.g. Jellyfin Stable';

  @override
  String get adminRepositoryUrl => 'Repository URL';

  @override
  String get adminAddEntry => 'Add entry';

  @override
  String get adminInvalidUrl => 'Invalid URL';

  @override
  String adminPluginSettingsLoadFailed(String error) {
    return 'Unable to load plugin settings: $error';
  }

  @override
  String adminCouldNotOpenUrl(String uri) {
    return 'Could not open $uri';
  }

  @override
  String get adminOpenInBrowser => 'Open in Browser';

  @override
  String get adminOpenExternally => 'Open externally';

  @override
  String get adminGeneralSettings => 'General Settings';

  @override
  String get adminServerName => 'Server name';

  @override
  String get adminPreferredMetadataCountry => 'Preferred metadata country';

  @override
  String get adminCachePath => 'Cache path';

  @override
  String get adminMetadataPath => 'Metadata path';

  @override
  String get adminLibraryScanConcurrency => 'Library scan concurrency';

  @override
  String get adminParallelImageEncodingLimit => 'Parallel image encoding limit';

  @override
  String get adminSlowResponseThreshold => 'Slow response threshold (ms)';

  @override
  String get adminBrandingSaved => 'Branding settings saved';

  @override
  String get adminBrandingLoadFailed => 'Failed to load branding settings';

  @override
  String get adminLoginDisclaimer => 'Login disclaimer';

  @override
  String get adminLoginDisclaimerHint => 'HTML displayed below the login form';

  @override
  String get adminCustomCss => 'Custom CSS';

  @override
  String get adminCustomCssHint => 'Custom CSS applied to the web interface';

  @override
  String get adminEnableSplashScreen => 'Enable splash screen';

  @override
  String get adminStreamingSaved => 'Streaming settings saved';

  @override
  String get adminStreamingLoadFailed => 'Failed to load streaming settings';

  @override
  String get adminStreamingDescription =>
      'Set global streaming bitrate limits for remote connections.';

  @override
  String get adminRemoteBitrateLimitMbps =>
      'Remote client bitrate limit (Mbps)';

  @override
  String get adminLeaveEmptyForUnlimited => 'Leave empty or 0 for unlimited';

  @override
  String get adminPlaybackSaved => 'Playback settings saved';

  @override
  String get adminPlaybackLoadFailed => 'Failed to load playback settings';

  @override
  String get adminPlaybackTranscoding => 'Playback / Transcoding';

  @override
  String get adminHardwareAcceleration => 'Hardware acceleration';

  @override
  String get adminVaapiDevice => 'VA-API device';

  @override
  String get adminEnableHardwareEncoding => 'Enable hardware encoding';

  @override
  String get adminEnableHardwareDecoding => 'Enable hardware decoding for:';

  @override
  String get adminEncodingThreads => 'Encoding threads';

  @override
  String get adminAutomatic => '0 = automatic';

  @override
  String get adminTranscodingTempPath => 'Transcoding temp path';

  @override
  String get adminEnableFallbackFont => 'Enable fallback font';

  @override
  String get adminFallbackFontPath => 'Fallback font path';

  @override
  String get adminAllowSegmentDeletion => 'Allow segment deletion';

  @override
  String get adminSegmentKeepSeconds => 'Segment keep (seconds)';

  @override
  String get adminThrottleBuffering => 'Throttle buffering';

  @override
  String get adminTrickplaySaved => 'Trickplay settings saved';

  @override
  String get adminTrickplayLoadFailed => 'Failed to load trickplay settings';

  @override
  String get adminEnableHardwareAcceleration => 'Enable hardware acceleration';

  @override
  String get adminEnableKeyFrameExtraction =>
      'Enable key frame only extraction';

  @override
  String get adminKeyFrameSubtitle => 'Faster but lower accuracy';

  @override
  String get adminScanBehavior => 'Scan behavior';

  @override
  String get adminProcessPriority => 'Process priority';

  @override
  String get adminImageSettings => 'Image Settings';

  @override
  String get adminIntervalMs => 'Interval (ms)';

  @override
  String get adminCaptureFrameSubtitle => 'How often to capture frames';

  @override
  String get adminWidthResolutions => 'Width resolutions';

  @override
  String get adminTileWidth => 'Tile width';

  @override
  String get adminTileHeight => 'Tile height';

  @override
  String get adminQualitySubtitle =>
      'Lower values = better quality, larger files';

  @override
  String get adminProcessThreads => 'Process threads';

  @override
  String get adminResumeSaved => 'Resume settings saved';

  @override
  String get adminResumeLoadFailed => 'Failed to load resume settings';

  @override
  String get adminResumeDescription =>
      'Configure when content should be marked as partially played or fully played.';

  @override
  String get adminMinResumePercentage => 'Minimum resume percentage';

  @override
  String get adminMinResumeSubtitle =>
      'Content must be played past this percentage to save progress';

  @override
  String get adminMaxResumePercentage => 'Maximum resume percentage';

  @override
  String get adminMaxResumeSubtitle =>
      'Content is considered fully played after this percentage';

  @override
  String get adminMinResumeDuration => 'Minimum resume duration (seconds)';

  @override
  String get adminMinResumeDurationSubtitle =>
      'Items shorter than this are not resumable';

  @override
  String get adminMinAudiobookResume => 'Minimum audiobook resume percentage';

  @override
  String get adminMaxAudiobookResume => 'Maximum audiobook resume percentage';

  @override
  String get adminNetworkingSaved =>
      'Networking settings saved. A server restart may be required.';

  @override
  String get adminNetworkingLoadFailed => 'Failed to load networking settings';

  @override
  String get adminNetworkingWarning =>
      'Changes to networking settings may require a server restart.';

  @override
  String get adminEnableRemoteAccess => 'Enable remote access';

  @override
  String get ports => 'Ports';

  @override
  String get adminHttpPort => 'HTTP port';

  @override
  String get adminHttpsPort => 'HTTPS port';

  @override
  String get adminPublicHttpsPort => 'Public HTTPS port';

  @override
  String get adminBaseUrl => 'Base URL';

  @override
  String get adminBaseUrlHint => 'e.g. /jellyfin';

  @override
  String get https => 'HTTPS';

  @override
  String get adminEnableHttps => 'Enable HTTPS';

  @override
  String get adminLocalNetwork => 'Local Network';

  @override
  String get adminLocalNetworkAddresses => 'Local network addresses';

  @override
  String get adminKnownProxies => 'Known proxies';

  @override
  String get adminRemoteIpFilter => 'Remote IP Filter';

  @override
  String get adminRemoteIpFilterEntries => 'Remote IP filter';

  @override
  String get adminCertificatePath => 'Certificate path';

  @override
  String get whitelist => 'Whitelist';

  @override
  String get blacklist => 'Blacklist';

  @override
  String get notSet => 'Not set';

  @override
  String get adminMetadataSaved => 'Metadata saved';

  @override
  String adminMetadataLoadFailed(String error) {
    return 'Failed to load metadata: $error';
  }

  @override
  String adminMetadataSaveFailed(String error) {
    return 'Failed to save metadata: $error';
  }

  @override
  String get adminRefreshMetadata => 'Refresh Metadata';

  @override
  String get recursive => 'Recursive';

  @override
  String get adminReplaceAllMetadata => 'Replace all metadata';

  @override
  String get adminReplaceAllImages => 'Replace all images';

  @override
  String get adminMetadataRefreshRequested => 'Metadata refresh requested';

  @override
  String adminMetadataRefreshFailed(String error) {
    return 'Failed to refresh metadata: $error';
  }

  @override
  String get adminSearchRemotePerson => 'Search Remote Person';

  @override
  String get adminNoRemoteMatches => 'No remote matches found';

  @override
  String get adminRemoteResults => 'Remote Results';

  @override
  String get adminRemoteMetadataApplied => 'Remote metadata applied';

  @override
  String adminRemoteSearchFailed(String error) {
    return 'Remote search failed: $error';
  }

  @override
  String get adminUpdateContentType => 'Update Content Type';

  @override
  String get adminContentType => 'Content type';

  @override
  String get adminContentTypeUpdated => 'Content type updated';

  @override
  String adminContentTypeUpdateFailed(String error) {
    return 'Failed to update content type: $error';
  }

  @override
  String get adminMetadataEditorLoadFailed => 'Failed to load metadata editor';

  @override
  String get adminNoPeopleEntries => 'No people entries';

  @override
  String get adminNoExternalIds => 'No external IDs available';

  @override
  String adminImageUpdated(String imageType) {
    return '$imageType image updated';
  }

  @override
  String adminImageDownloadFailed(String error) {
    return 'Failed to download image: $error';
  }

  @override
  String get adminUnsupportedImageFormat => 'Unsupported image format';

  @override
  String get adminImageReadFailed => 'Failed to read selected image';

  @override
  String adminImageUploaded(String imageType) {
    return '$imageType image uploaded';
  }

  @override
  String adminImageUploadFailed(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String adminDeleteImage(String imageType) {
    return 'Delete $imageType image';
  }

  @override
  String adminImageDeleted(String imageType) {
    return '$imageType image deleted';
  }

  @override
  String adminImageDeleteFailed(String error) {
    return 'Failed to delete image: $error';
  }

  @override
  String get adminAllProviders => 'All providers';

  @override
  String get adminNoRemoteImages => 'No remote images found';

  @override
  String adminTunerDiscoveryFailed(String error) {
    return 'Tuner discovery failed: $error';
  }

  @override
  String get adminAddTuner => 'Add Tuner';

  @override
  String get adminTunerType => 'Tuner Type';

  @override
  String get adminTunerTypeHint => 'HDHomeRun, M3U, Other';

  @override
  String get adminUrlPath => 'URL / Path';

  @override
  String get adminNameOptional => 'Name (optional)';

  @override
  String get adminTunerAdded => 'Tuner added';

  @override
  String adminTunerAddFailed(String error) {
    return 'Failed to add tuner: $error';
  }

  @override
  String get adminAddGuideProvider => 'Add Guide Provider';

  @override
  String get adminProviderType => 'Provider Type';

  @override
  String get adminProviderTypeHint => 'SchedulesDirect or XMLTV';

  @override
  String get adminUsernameOptional => 'Username (optional)';

  @override
  String get adminRefreshInterval => 'Refresh interval (hours)';

  @override
  String get adminProviderAdded => 'Provider added';

  @override
  String adminProviderAddFailed(String error) {
    return 'Failed to add provider: $error';
  }

  @override
  String adminTunerRemoveFailed(String error) {
    return 'Failed to remove tuner: $error';
  }

  @override
  String get adminTunerResetRequested => 'Tuner reset requested';

  @override
  String adminTunerResetFailed(String error) {
    return 'Failed to reset tuner: $error';
  }

  @override
  String adminProviderRemoveFailed(String error) {
    return 'Failed to remove provider: $error';
  }

  @override
  String get adminRecordingSettings => 'Recording Settings';

  @override
  String get adminPrePadding => 'Pre-padding (minutes)';

  @override
  String get adminPostPadding => 'Post-padding (minutes)';

  @override
  String get adminRecordingPath => 'Recording path';

  @override
  String get adminSeriesRecordingPath => 'Series recording path';

  @override
  String get adminRecordingSettingsSaved => 'Recording settings saved';

  @override
  String adminSettingsSaveFailed(String error) {
    return 'Failed to save settings: $error';
  }

  @override
  String get adminSetChannelMappings => 'Set Channel Mappings';

  @override
  String get adminMappingJson => 'Mapping JSON';

  @override
  String get adminChannelMappingsUpdated => 'Channel mappings updated';

  @override
  String adminMappingsUpdateFailed(String error) {
    return 'Failed to update mappings: $error';
  }

  @override
  String get adminLiveTvLoadFailed => 'Failed to load Live TV administration';

  @override
  String get adminTunerDevices => 'Tuner Devices';

  @override
  String get adminNoTunerHosts => 'No tuner hosts configured';

  @override
  String get adminGuideProviders => 'Guide Providers';

  @override
  String get adminAddProvider => 'Add Provider';

  @override
  String get adminNoListingProviders => 'No listing providers configured';

  @override
  String adminRecordingPathDisplay(String path) {
    return 'Recording path: $path';
  }

  @override
  String adminSeriesPathDisplay(String path) {
    return 'Series path: $path';
  }

  @override
  String adminPrePaddingDisplay(int minutes) {
    return 'Pre-padding: $minutes min';
  }

  @override
  String adminPostPaddingDisplay(int minutes) {
    return 'Post-padding: $minutes min';
  }

  @override
  String get adminTunerDiscovery => 'Tuner Discovery';

  @override
  String get adminChannelMappings => 'Channel Mappings';

  @override
  String get adminNoDiscoveredTuners => 'No discovered tuners yet';

  @override
  String get adminSettingsSaved => 'Settings saved';

  @override
  String get adminBackupsNotAvailable =>
      'Backups are not available on this server build.';

  @override
  String get adminRestoreWarning1 =>
      'Restoring will replace ALL current server data with the backup data.';

  @override
  String get adminRestoreWarning2 =>
      'Current server settings, users, and library data will be overwritten.';

  @override
  String get adminRestoreWarning3 =>
      'The server will restart after restoration.';

  @override
  String adminRestoreConfirmMessage(String name) {
    return 'Restore backup $name now?';
  }

  @override
  String get adminRestoreRequested =>
      'Restore requested. Server restart may disconnect this session.';

  @override
  String get adminBackupsTitle => 'Backups';

  @override
  String get adminUnknownDate => 'Unknown date';

  @override
  String get adminUnnamedBackup => 'Unnamed Backup';

  @override
  String get adminLiveTvNotAvailable =>
      'Live TV administration is not available on this server build.';

  @override
  String get adminLiveTvTitle => 'Live TV Administration';

  @override
  String get adminApply => 'Apply';

  @override
  String get adminNotSet => 'Not set';

  @override
  String get adminReset => 'Reset';

  @override
  String get adminLogsTitle => 'Server Logs';

  @override
  String get adminLogsNewestFirst => 'Newest First';

  @override
  String get adminLogsOldestFirst => 'Oldest First';

  @override
  String get adminLogsJustNow => 'Just now';

  @override
  String adminLogsMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String adminLogsHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String adminLogsDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String adminLogViewerLoadFailed(String fileName) {
    return 'Failed to load $fileName';
  }

  @override
  String adminLogViewerMatches(int count) {
    return '$count matches';
  }

  @override
  String get adminLogViewerNoMatches => 'No matching lines';

  @override
  String get adminMetadataEditorTitle => 'Metadata Editor';

  @override
  String get adminMetadataRemote => 'Remote';

  @override
  String get adminMetadataType => 'Type';

  @override
  String get adminMetadataDetails => 'Details';

  @override
  String get adminMetadataExternalIds => 'External IDs';

  @override
  String get adminMetadataImages => 'Images';

  @override
  String get adminMetadataFieldTitle => 'Title';

  @override
  String get adminMetadataFieldSortTitle => 'Sort title';

  @override
  String get adminMetadataFieldOriginalTitle => 'Original title';

  @override
  String get adminMetadataFieldPremiereDate => 'Premiere date (YYYY-MM-DD)';

  @override
  String get adminMetadataFieldEndDate => 'End date (YYYY-MM-DD)';

  @override
  String get adminMetadataFieldProductionYear => 'Production year';

  @override
  String get adminMetadataFieldOfficialRating => 'Official rating';

  @override
  String get adminMetadataFieldCommunityRating => 'Community rating';

  @override
  String get adminMetadataFieldCriticRating => 'Critic rating';

  @override
  String get adminMetadataFieldTagline => 'Tagline';

  @override
  String get adminMetadataFieldOverview => 'Overview';

  @override
  String get adminMetadataGenres => 'Genres';

  @override
  String get adminMetadataTags => 'Tags';

  @override
  String get adminMetadataStudios => 'Studios';

  @override
  String get adminMetadataPeople => 'People';

  @override
  String get adminMetadataAddGenre => 'Add genre';

  @override
  String get adminMetadataAddTag => 'Add tag';

  @override
  String get adminMetadataAddStudio => 'Add studio';

  @override
  String get adminMetadataAddPerson => 'Add Person';

  @override
  String get adminMetadataEditPerson => 'Edit Person';

  @override
  String get adminMetadataRole => 'Role';

  @override
  String get adminMetadataImagePrimary => 'Primary';

  @override
  String get adminMetadataImageBackdrop => 'Backdrop';

  @override
  String get adminMetadataImageLogo => 'Logo';

  @override
  String get adminMetadataImageBanner => 'Banner';

  @override
  String get adminMetadataImageThumb => 'Thumb';

  @override
  String get adminMetadataRecursive => 'Recursive';

  @override
  String get adminMetadataProvider => 'Provider';

  @override
  String adminMetadataImageUpdated(String imageType) {
    return '$imageType image updated';
  }

  @override
  String adminMetadataImageUploaded(String imageType) {
    return '$imageType image uploaded';
  }

  @override
  String adminMetadataImageDeleted(String imageType) {
    return '$imageType image deleted';
  }

  @override
  String adminMetadataImageDownloadFailed(String error) {
    return 'Failed to download image: $error';
  }

  @override
  String get adminMetadataImageReadFailed => 'Failed to read selected image';

  @override
  String adminMetadataImageUploadFailed(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String adminMetadataDeleteImageTitle(String imageType) {
    return 'Delete $imageType image';
  }

  @override
  String get adminMetadataDeleteImageContent =>
      'This removes the current image from the item.';

  @override
  String adminMetadataImageDeleteFailed(String error) {
    return 'Failed to delete image: $error';
  }

  @override
  String adminMetadataChooseImage(String imageType) {
    return 'Choose $imageType image';
  }

  @override
  String get adminMetadataUpload => 'Upload';

  @override
  String get adminMetadataUpdate => 'Update';

  @override
  String get adminMetadataRemoteImage => 'Remote image';

  @override
  String get adminPluginsInstalled => 'Installed';

  @override
  String get adminPluginsCatalog => 'Catalog';

  @override
  String get adminPluginsActive => 'Active';

  @override
  String get adminPluginsRestart => 'Restart';

  @override
  String get adminPluginsNoSearchResults => 'No plugins match your search';

  @override
  String get adminPluginsNoneInstalled => 'No plugins installed';

  @override
  String adminPluginsUpdateAvailable(String version) {
    return 'Update available: v$version';
  }

  @override
  String get adminPluginsUpdateAvailableGeneric => 'Update available';

  @override
  String get adminPluginsPendingRemoval => 'Pending removal after restart';

  @override
  String get adminPluginsChangesPending => 'Changes pending restart';

  @override
  String get adminPluginsEnable => 'Enable';

  @override
  String get adminPluginsDisable => 'Disable';

  @override
  String get adminPluginsInstallUpdate => 'Install update';

  @override
  String adminPluginsInstallUpdateVersioned(String version) {
    return 'Install update (v$version)';
  }

  @override
  String get adminPluginsCatalogNoSearchResults =>
      'No packages match your search';

  @override
  String get adminPluginsCatalogEmpty => 'No packages available';

  @override
  String adminPluginsInstalling(String name) {
    return '\"$name\" is being installed...';
  }

  @override
  String get adminPluginDetailExperimental => 'Experimental Integration';

  @override
  String get adminPluginDetailExperimentalContent =>
      'Plugin settings integration is still experimental. Some fields or layouts may not render correctly yet.';

  @override
  String get adminPluginDetailToggle404 =>
      'Failed to toggle plugin. The server could not find this plugin version. Try refreshing plugins, then retry.';

  @override
  String get adminPluginDetailToggleDioError =>
      'Failed to toggle plugin. Please check server logs for details.';

  @override
  String adminPluginDetailSettingsTitle(String name) {
    return '$name Settings';
  }

  @override
  String get adminPluginDetailDetails => 'Details';

  @override
  String get adminPluginDetailDeveloper => 'Developer';

  @override
  String get adminPluginDetailRepository => 'Repository';

  @override
  String get adminPluginDetailBundled => 'Bundled';

  @override
  String get adminPluginDetailEnablePlugin => 'Enable Plugin';

  @override
  String get adminPluginDetailRestartRequired =>
      'A server restart is required for changes to take effect.';

  @override
  String get adminPluginDetailRemovalPending =>
      'This plugin will be removed after server restart.';

  @override
  String get adminPluginDetailMalfunctioned =>
      'This plugin has malfunctioned and may not work correctly.';

  @override
  String get adminPluginDetailNotSupported =>
      'This plugin is not supported by the current server version.';

  @override
  String get adminPluginDetailSuperseded =>
      'This plugin has been superseded by a newer version.';

  @override
  String adminReposLoadFailed(String error) {
    return 'Failed to load repositories: $error';
  }

  @override
  String get adminReposRemoveTitle => 'Remove Repository';

  @override
  String adminReposRemoveConfirm(String name) {
    return 'Are you sure you want to remove \"$name\"?';
  }

  @override
  String get adminReposRemove => 'Remove';

  @override
  String adminReposSaveFailed(String error) {
    return 'Failed to save repositories: $error';
  }

  @override
  String get adminReposEmpty => 'No repositories configured';

  @override
  String get adminReposEmptySubtitle =>
      'Add a repository to browse available plugins';

  @override
  String get adminReposUnnamed => '(unnamed)';

  @override
  String get adminReposEditTitle => 'Edit Repository';

  @override
  String get adminReposAddTitle => 'Add Repository';

  @override
  String get adminReposUrl => 'Repository URL';

  @override
  String get adminReposNameHint => 'e.g. Jellyfin Stable';

  @override
  String get adminPluginSettingsInvalidUrl => 'Invalid URL';

  @override
  String get adminGeneralSettingsTitle => 'General Settings';

  @override
  String get adminGeneralMetadataLanguage => 'Preferred metadata language';

  @override
  String get adminGeneralMetadataLanguageHint => 'e.g. en, de, fr';

  @override
  String get adminGeneralMetadataCountry => 'Preferred metadata country';

  @override
  String get adminGeneralMetadataCountryHint => 'e.g. US, DE, FR';

  @override
  String get adminGeneralLibraryScanConcurrency => 'Library scan concurrency';

  @override
  String get adminGeneralImageEncodingLimit => 'Parallel image encoding limit';

  @override
  String get adminUnknownError => 'Unknown error';

  @override
  String get adminBrowse => 'Browse';

  @override
  String get adminCloseBrowser => 'Close browser';

  @override
  String get adminNetworkingTitle => 'Networking';

  @override
  String get adminNetworkingRestartWarning =>
      'Changes to networking settings may require a server restart.';

  @override
  String get adminNetworkingRemoteAccess => 'Enable remote access';

  @override
  String get adminNetworkingPorts => 'Ports';

  @override
  String get adminNetworkingHttpPort => 'HTTP port';

  @override
  String get adminNetworkingHttpsPort => 'HTTPS port';

  @override
  String get adminNetworkingEnableHttps => 'Enable HTTPS';

  @override
  String get adminNetworkingLocalNetwork => 'Local Network';

  @override
  String get adminNetworkingLocalAddresses => 'Local network addresses';

  @override
  String get adminNetworkingAddressHint => 'e.g. 192.168.1.0/24';

  @override
  String get adminNetworkingKnownProxies => 'Known proxies';

  @override
  String get adminNetworkingProxyHint => 'e.g. 10.0.0.1';

  @override
  String get adminNetworkingWhitelist => 'Whitelist';

  @override
  String get adminNetworkingBlacklist => 'Blacklist';

  @override
  String get adminNetworkingAddEntry => 'Add entry';

  @override
  String get adminBrandingTitle => 'Branding';

  @override
  String get adminBrandingLoginDisclaimer => 'Login disclaimer';

  @override
  String get adminBrandingLoginDisclaimerHint =>
      'HTML displayed below the login form';

  @override
  String get adminBrandingCustomCss => 'Custom CSS';

  @override
  String get adminBrandingCustomCssHint =>
      'Custom CSS applied to the web interface';

  @override
  String get adminBrandingEnableSplash => 'Enable splash screen';

  @override
  String get adminPlaybackHwAccel => 'Hardware Acceleration';

  @override
  String get adminPlaybackHwAccelLabel => 'Hardware acceleration';

  @override
  String get adminPlaybackEnableHwEncoding => 'Enable hardware encoding';

  @override
  String get adminPlaybackEnableHwDecoding => 'Enable hardware decoding for:';

  @override
  String get adminPlaybackEncoding => 'Encoding';

  @override
  String get adminPlaybackEncodingThreads => 'Encoding threads';

  @override
  String get adminPlaybackFallbackFont => 'Enable fallback font';

  @override
  String get adminPlaybackFallbackFontPath => 'Fallback font path';

  @override
  String get adminPlaybackStreaming => 'Streaming';

  @override
  String get adminResumeVideo => 'Video';

  @override
  String get adminResumeAudiobooks => 'Audiobooks';

  @override
  String get adminResumeMinAudiobookPct =>
      'Minimum audiobook resume percentage';

  @override
  String get adminResumeMaxAudiobookPct =>
      'Maximum audiobook resume percentage';

  @override
  String get adminStreamingBitrateLimit => 'Remote client bitrate limit (Mbps)';

  @override
  String get adminStreamingBitrateLimitHint => 'Leave empty or 0 for unlimited';

  @override
  String get adminTrickplayHwAccel => 'Enable hardware acceleration';

  @override
  String get adminTrickplayHwEncoding => 'Enable hardware encoding';

  @override
  String get adminTrickplayKeyFrameOnly => 'Enable key frame only extraction';

  @override
  String get adminTrickplayKeyFrameOnlySubtitle => 'Faster but lower accuracy';

  @override
  String get adminTrickplayNonBlocking => 'Non-Blocking';

  @override
  String get adminTrickplayBlocking => 'Blocking';

  @override
  String get adminTrickplayPriorityHigh => 'High';

  @override
  String get adminTrickplayPriorityAboveNormal => 'Above Normal';

  @override
  String get adminTrickplayPriorityNormal => 'Normal';

  @override
  String get adminTrickplayPriorityBelowNormal => 'Below Normal';

  @override
  String get adminTrickplayPriorityIdle => 'Idle';

  @override
  String get adminTrickplayImageSettings => 'Image Settings';

  @override
  String get adminTrickplayInterval => 'Interval (ms)';

  @override
  String get adminTrickplayIntervalSubtitle => 'How often to capture frames';

  @override
  String get adminTrickplayWidthResolutionsHint =>
      'Comma-separated pixel widths (e.g. 320)';

  @override
  String get adminTrickplayQuality => 'Quality';

  @override
  String get adminTrickplayQScale => 'Quality scale';

  @override
  String get adminTrickplayQScaleSubtitle =>
      'Lower values = better quality, larger files';

  @override
  String get adminTrickplayJpegQuality => 'JPEG quality';

  @override
  String get adminTrickplayProcessing => 'Processing';

  @override
  String get adminTasksEmpty => 'No scheduled tasks found';

  @override
  String get adminTasksNoFilterMatch => 'No tasks match the current filter';

  @override
  String get adminTaskCancelling => 'Cancelling...';

  @override
  String get adminTaskRunning => 'Running...';

  @override
  String get adminTaskNeverRun => 'Never run';

  @override
  String get adminTaskStop => 'Stop';

  @override
  String get adminTaskRun => 'Run';

  @override
  String get adminTaskDetailLastExecution => 'Last Execution';

  @override
  String get adminTaskDetailStarted => 'Started';

  @override
  String get adminTaskDetailEnded => 'Ended';

  @override
  String get adminTaskDetailDuration => 'Duration';

  @override
  String get adminTaskDetailErrorLabel => 'Error:';

  @override
  String adminTaskTriggerDaily(String time) {
    return 'Daily at $time';
  }

  @override
  String adminTaskTriggerWeekly(String day, String time) {
    return 'Every $day at $time';
  }

  @override
  String adminTaskTriggerInterval(String duration) {
    return 'Every $duration';
  }

  @override
  String get adminTaskTriggerStartup => 'On application startup';

  @override
  String get adminTaskTriggerTypeDaily => 'Daily';

  @override
  String get adminTaskTriggerTypeWeekly => 'Weekly';

  @override
  String get adminTaskTriggerTypeInterval => 'On an interval';

  @override
  String get adminTaskTriggerIntervalLabel => 'Interval';

  @override
  String get adminTaskTriggerEveryHour => 'Every hour';

  @override
  String get adminTaskTriggerEvery6Hours => 'Every 6 hours';

  @override
  String get adminTaskTriggerEvery12Hours => 'Every 12 hours';

  @override
  String get adminTaskTriggerEvery24Hours => 'Every 24 hours';

  @override
  String get adminTaskTriggerEvery2Days => 'Every 2 days';

  @override
  String adminTaskTriggerHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get adminTaskTriggerTime => 'Time';

  @override
  String get adminTaskTriggerNoLimit => 'No limit';

  @override
  String get adminActivityJustNow => 'Just now';

  @override
  String get adminActivityLastHour => 'Last hour';

  @override
  String get adminActivityToday => 'Today';

  @override
  String get adminActivityYesterday => 'Yesterday';

  @override
  String get adminActivityOlder => 'Older';

  @override
  String adminActivityDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String adminActivityHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String adminActivityMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get adminActivityNow => 'now';

  @override
  String adminActivityMinutesShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String adminActivityHoursShort(int hours) {
    return '${hours}h';
  }

  @override
  String adminActivityDaysShort(int days) {
    return '${days}d';
  }

  @override
  String adminActivityDateShort(int month, int day) {
    return '$month/$day';
  }

  @override
  String get adminTrickplayDescription =>
      'Configure trickplay image generation for seek preview thumbnails.';

  @override
  String get adminNetworkingPublicHttpsPort => 'Public HTTPS port';

  @override
  String get adminNetworkingBaseUrl => 'Base URL';

  @override
  String get adminNetworkingBaseUrlHint => 'e.g. /jellyfin';

  @override
  String get adminNetworkingHttps => 'HTTPS';

  @override
  String get adminNetworkingCertPath => 'Certificate path';

  @override
  String get adminNetworkingRemoteIpFilter => 'Remote IP Filter';

  @override
  String get adminNetworkingRemoteIpFilterLabel => 'Remote IP filter';

  @override
  String get adminPlaybackVaapiDevice => 'VA-API device';

  @override
  String get adminPlaybackAutomatic => '0 = automatic';

  @override
  String get adminPlaybackTranscodeTempPath => 'Transcoding temp path';

  @override
  String get adminPlaybackSegmentDeletion => 'Allow segment deletion';

  @override
  String get adminPlaybackSegmentKeep => 'Segment keep (seconds)';

  @override
  String get adminPlaybackThrottleBuffering => 'Throttle buffering';

  @override
  String get adminResumeMinPct => 'Minimum resume percentage';

  @override
  String get adminResumeMinPctSubtitle =>
      'Content must be played past this percentage to save progress';

  @override
  String get adminResumeMaxPct => 'Maximum resume percentage';

  @override
  String get adminResumeMaxPctSubtitle =>
      'Content is considered fully played after this percentage';

  @override
  String get adminResumeMinDuration => 'Minimum resume duration (seconds)';

  @override
  String get adminResumeMinDurationSubtitle =>
      'Items shorter than this are not resumable';

  @override
  String get adminTrickplayScanBehavior => 'Scan behavior';

  @override
  String get adminTrickplayProcessPriority => 'Process priority';

  @override
  String get adminTrickplayTileWidth => 'Tile width';

  @override
  String get adminTrickplayTileHeight => 'Tile height';

  @override
  String get adminTrickplayProcessThreads => 'Process threads';

  @override
  String get adminTrickplayWidthResolutions => 'Width resolutions';

  @override
  String get adminMetadataDefault => 'Default';

  @override
  String get adminMetadataContentTypeUpdated => 'Content type updated';

  @override
  String adminMetadataContentTypeFailed(String error) {
    return 'Failed to update content type: $error';
  }

  @override
  String get adminGeneralSlowResponseThreshold =>
      'Slow response threshold (ms)';

  @override
  String get adminGeneralCachePath => 'Cache path';

  @override
  String get adminGeneralMetadataPath => 'Metadata path';

  @override
  String get adminGeneralServerName => 'Server name';

  @override
  String get adminSettingsLoadFailed => 'Failed to load settings';

  @override
  String get adminDiscover => 'Discover';

  @override
  String adminChannelMappingsUpdateFailed(String error) {
    return 'Failed to update mappings: $error';
  }

  @override
  String adminTimeLimitDuration(String duration) {
    return 'Time limit: $duration';
  }

  @override
  String get folders => 'Folders';

  @override
  String get libraries => 'Libraries';

  @override
  String get syncPlay => 'SyncPlay';

  @override
  String get jellyseerr => 'Jellyseerr';

  @override
  String get seeAll => 'See All';

  @override
  String get noItems => 'No items';

  @override
  String get switchUser => 'Switch User';

  @override
  String get remoteControl => 'Remote Control';

  @override
  String get mediaBarLoading => 'Loading media bar...';

  @override
  String get mediaBarError => 'Media bar failed to load';

  @override
  String get offlineServerUnavailable =>
      'Connected to the internet, but the current server is unavailable.';

  @override
  String get offlineNoInternet =>
      'You are offline. Only downloaded content is available.';

  @override
  String get offlineSwitchServer => 'Switch Server';

  @override
  String get offlineSavedMedia => 'Saved Media';

  @override
  String get castGoogleCast => 'Google Cast';

  @override
  String get castAirPlay => 'AirPlay';

  @override
  String get castDlna => 'DLNA';

  @override
  String get castRemotePlayback => 'Remote Playback';

  @override
  String castControlFailed(String error) {
    return 'Cast control failed: $error';
  }

  @override
  String castKindControls(String kind) {
    return '$kind Controls';
  }

  @override
  String get castDeviceVolume => 'Device Volume';

  @override
  String get castVolumeUnavailable => 'Unavailable';

  @override
  String castStopKind(String kind) {
    return 'Stop $kind';
  }

  @override
  String get audioLabel => 'Audio';

  @override
  String get subtitlesLabel => 'Subtitles';

  @override
  String get pinConfirmTitle => 'Confirm PIN';

  @override
  String get pinSetTitle => 'Set PIN';

  @override
  String get pinEnterTitle => 'Enter PIN';

  @override
  String get pinReenterToConfirm => 'Re-enter your PIN to confirm';

  @override
  String pinEnterNDigit(int length) {
    return 'Enter a $length-digit PIN';
  }

  @override
  String pinEnterYourNDigit(int length) {
    return 'Enter your $length-digit PIN';
  }

  @override
  String get pinIncorrect => 'Incorrect PIN';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get pinForgot => 'Forgot PIN?';

  @override
  String get pinClear => 'Clear';

  @override
  String get pinBackspace => 'Backspace';

  @override
  String get quickConnectAuthorized => 'Quick Connect request authorized.';

  @override
  String get quickConnectInvalidOrExpired =>
      'Quick Connect code is invalid or expired.';

  @override
  String get quickConnectNotSupported =>
      'Quick Connect is not supported on this server.';

  @override
  String get quickConnectAuthorizeFailed =>
      'Failed to authorize Quick Connect code.';

  @override
  String get quickConnectDisabled =>
      'Quick Connect is disabled on this server.';

  @override
  String get quickConnectForbidden =>
      'Your account cannot authorize this Quick Connect request.';

  @override
  String get quickConnectNotFound =>
      'Quick Connect code was not found. Try a new code.';

  @override
  String quickConnectFailedWithMessage(String message) {
    return 'Quick Connect failed: $message';
  }

  @override
  String get quickConnectEnterCode => 'Enter code';

  @override
  String get quickConnectAuthorize => 'Authorize';

  @override
  String remoteCommandFailed(String error) {
    return 'Command failed: $error';
  }

  @override
  String get remoteControlTitle => 'Remote Control';

  @override
  String get remoteFailedToLoadSessions => 'Failed to load sessions';

  @override
  String get remoteNoSessions => 'No controllable sessions';

  @override
  String get remoteStartPlayback => 'Start playback on another device';

  @override
  String get unknownUser => 'Unknown';

  @override
  String get unknownItem => 'Unknown';

  @override
  String get remoteNothingPlaying => 'Nothing playing on this session';

  @override
  String get castingStarted => 'Casting started on selected device';

  @override
  String castingFailed(String error) {
    return 'Failed to start casting: $error';
  }

  @override
  String get noRemoteDevices => 'No remote playback devices available.';

  @override
  String get noRemoteDevicesIos =>
      'No remote playback devices available.\n\nOn iOS, AirPlay targets may be unavailable in the simulator.';

  @override
  String get trackActionPlayNext => 'Play Next';

  @override
  String get trackActionAddToQueue => 'Add to Queue';

  @override
  String get trackActionAddToPlaylist => 'Add to Playlist';

  @override
  String get trackActionCancelDownload => 'Cancel Download';

  @override
  String get trackActionDeleteFromPlaylist => 'Delete from Playlist';

  @override
  String get trackActionMoveUp => 'Move Up';

  @override
  String get trackActionMoveDown => 'Move Down';

  @override
  String get trackActionRemoveFromFavorites => 'Remove from Favorites';

  @override
  String get trackActionAddToFavorites => 'Add to Favorites';

  @override
  String get trackActionGoToAlbum => 'Go to Album';

  @override
  String get trackActionGoToArtist => 'Go to Artist';

  @override
  String trackActionDownloading(String name) {
    return 'Downloading $name...';
  }

  @override
  String get trackActionDeletedFile => 'Deleted downloaded file';

  @override
  String get trackActionDeleteFileFailed => 'Could not delete downloaded file';

  @override
  String get shuffleBy => 'Shuffle By';

  @override
  String get shuffleSelectLibrary => 'Select Library';

  @override
  String get shuffleSelectGenre => 'Select Genre';

  @override
  String get shuffleLibrary => 'Library';

  @override
  String get shuffleGenre => 'Genre';

  @override
  String get shuffleNoLibraries => 'No compatible libraries available.';

  @override
  String get shuffleNoGenres => 'No genres found for this shuffle mode.';

  @override
  String get posterDisplayTitle => 'Display';

  @override
  String get posterImageType => 'Image Type';

  @override
  String get imageTypePoster => 'Poster';

  @override
  String get imageTypeThumbnail => 'Thumbnail';

  @override
  String get imageTypeBanner => 'Banner';

  @override
  String get playlistAddFailed => 'Failed to add to playlist';

  @override
  String get playlistCreateFailed => 'Failed to create playlist';

  @override
  String get playlistNew => 'New Playlist';

  @override
  String get playlistCreate => 'Create';

  @override
  String get playlistCreateNew => 'Create New Playlist';

  @override
  String get playlistNoneFound => 'No playlists found';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get lyricsNotAvailable => 'No lyrics available';

  @override
  String get upNext => 'Up Next';

  @override
  String get playNext => 'Play Next';

  @override
  String get stillWatchingContent =>
      'Playback has been paused. Are you still watching?';

  @override
  String get stillWatchingStop => 'Stop';

  @override
  String get stillWatchingContinue => 'Continue';

  @override
  String skipSegment(String segment) {
    return 'Skip $segment';
  }

  @override
  String get liveTv => 'Live TV';

  @override
  String get continueWatchingAndNextUp => 'Continue Watching & Next Up';

  @override
  String downloadingBatchProgress(int current, int total, String fileName) {
    return 'Downloading $current/$total — $fileName';
  }

  @override
  String downloadingFile(String fileName) {
    return 'Downloading $fileName';
  }

  @override
  String get nextEpisode => 'Next Episode';

  @override
  String get moreFromThisSeason => 'More From This Season';
}
