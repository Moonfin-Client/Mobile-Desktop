// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Moonfin';

  @override
  String get signIn => 'Anmelden';

  @override
  String connectingToServer(String serverName) {
    return 'Verbindung zu $serverName';
  }

  @override
  String get quickConnect => 'Schnellverbindung';

  @override
  String get password => 'Passwort';

  @override
  String get username => 'Benutzername';

  @override
  String get quickConnectInstruction =>
      'Gib diesen Code im Web-Dashboard deines Servers ein:';

  @override
  String get waitingForAuthorization => 'Warte auf Autorisierung...';

  @override
  String get back => 'Zurück';

  @override
  String get serverUnavailable => 'Server nicht erreichbar';

  @override
  String get loginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String quickConnectUnavailable(String detail) {
    return 'Schnellverbindung nicht verfügbar: $detail';
  }

  @override
  String quickConnectUnavailableWithStatus(String status, String detail) {
    return 'Schnellverbindung nicht verfügbar ($status): $detail';
  }

  @override
  String get whosWatching => 'Wer schaut zu?';

  @override
  String get addUser => 'Benutzer hinzufügen';

  @override
  String get selectServer => 'Server auswählen';

  @override
  String appVersionFooter(String version) {
    return 'Moonfin Version $version';
  }

  @override
  String get savedServers => 'Gespeicherte Server';

  @override
  String get discoveredServers => 'Erkannte Server';

  @override
  String get noneFound => 'Keine gefunden';

  @override
  String get unableToConnectToServer => 'Verbindung zum Server nicht möglich';

  @override
  String get addServer => 'Server hinzufügen';

  @override
  String get embyConnect => 'Emby Connect';

  @override
  String get removeServer => 'Server entfernen';

  @override
  String removeServerConfirmation(String serverName) {
    return '„$serverName“ von deinen Servern entfernen?';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get remove => 'Entfernen';

  @override
  String get connectToServer => 'Mit Server verbinden';

  @override
  String get serverAddress => 'Serveradresse';

  @override
  String get serverAddressHint => 'https://dein-server.beispiel.de';

  @override
  String get connect => 'Verbinden';

  @override
  String get secureStorageUnavailable => 'Sicherer Speicher nicht verfügbar';

  @override
  String get secureStorageUnavailableMessage =>
      'Moonfin konnte nicht auf deinen System-Schlüsselbund zugreifen. Die Anmeldung kann fortgesetzt werden, aber die sichere Token-Speicherung ist möglicherweise nicht verfügbar, bis der Schlüsselbund entsperrt wird.';

  @override
  String get ok => 'OK';

  @override
  String get embyConnectSignInSubtitle =>
      'Melde dich mit deinem Emby-Connect-Konto an';

  @override
  String get emailOrUsername => 'E-Mail oder Benutzername';

  @override
  String get selectAServer => 'Server auswählen';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get noLinkedServers =>
      'Keine Server mit diesem Emby-Connect-Konto verknüpft';

  @override
  String get invalidEmbyConnectCredentials =>
      'Ungültige Emby-Connect-Anmeldedaten';

  @override
  String get invalidEmbyConnectLogin =>
      'Ungültiger Emby-Connect-Benutzername oder Passwort';

  @override
  String get embyConnectExchangeNotSupported =>
      'Server unterstützt keinen Emby-Connect-Austausch';

  @override
  String get embyConnectNetworkError =>
      'Netzwerkfehler beim Kontaktieren von Emby Connect oder dem ausgewählten Server';

  @override
  String get loadingLinkedServers => 'Lade verknüpfte Server...';

  @override
  String get connectingToServerEllipsis =>
      'Verbindung zum Server wird hergestellt...';

  @override
  String get noReachableAddress => 'Keine erreichbare Adresse angegeben';

  @override
  String get invalidServerExchangeResponse =>
      'Ungültige Antwort vom Server-Austauschendpunkt';

  @override
  String unableToConnectTo(String target) {
    return 'Verbindung zu $target nicht möglich';
  }

  @override
  String get exitApp => 'Moonfin beenden?';

  @override
  String get exitAppConfirmation => 'Möchtest du die App wirklich beenden?';

  @override
  String get exit => 'Beenden';

  @override
  String get noHomeRowsLoaded => 'Keine Startseiten-Reihen geladen';

  @override
  String get noHomeRowsHint =>
      'Versuche zu aktualisieren oder reduziere die aktiven Bereiche.';

  @override
  String get retryHomeRows => 'Startseiten-Reihen erneut laden';

  @override
  String get guide => 'Programmführer';

  @override
  String get recordings => 'Aufnahmen';

  @override
  String get schedule => 'Zeitplan';

  @override
  String get series => 'Serien';

  @override
  String get noItemsFound => 'Keine Einträge gefunden';

  @override
  String get home => 'Startseite';

  @override
  String get browseAll => 'Alle durchsuchen';

  @override
  String get genres => 'Genres';

  @override
  String get collectionPlaceholder => 'Sammlungselemente werden hier angezeigt';

  @override
  String get browseByLetter => 'Nach Buchstaben durchsuchen';

  @override
  String get alphabeticalBrowsePlaceholder =>
      'Alphabetische Übersicht wird hier angezeigt';

  @override
  String get suggestions => 'Vorschläge';

  @override
  String get suggestionsPlaceholder =>
      'Vorgeschlagene Einträge werden hier angezeigt';

  @override
  String get failedToLoadLibraries =>
      'Bibliotheken konnten nicht geladen werden';

  @override
  String get noLibrariesFound => 'Keine Bibliotheken gefunden';

  @override
  String get library => 'Bibliothek';

  @override
  String get displaySettings => 'Anzeigeeinstellungen';

  @override
  String get allGenres => 'Alle Genres';

  @override
  String get noGenresFound => 'Keine Genres gefunden';

  @override
  String failedToLoadFolderError(String error) {
    return 'Ordner konnte nicht geladen werden: $error';
  }

  @override
  String get thisFolderIsEmpty => 'Dieser Ordner ist leer';

  @override
  String itemCountLabel(int count) {
    return '$count Einträge';
  }

  @override
  String get failedToLoadFavorites => 'Favoriten konnten nicht geladen werden';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noFavoritesYet => 'Noch keine Favoriten';

  @override
  String get favorites => 'Favoriten';

  @override
  String totalCountItems(int count) {
    return '$count Einträge';
  }

  @override
  String get continuing => 'Wird fortgesetzt';

  @override
  String get ended => 'Beendet';

  @override
  String get sortAndFilter => 'Sortieren & Filtern';

  @override
  String get type => 'Typ';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get display => 'Anzeige';

  @override
  String get imageType => 'Bildtyp';

  @override
  String get posterSize => 'Postergröße';

  @override
  String get small => 'Klein';

  @override
  String get medium => 'Mittel';

  @override
  String get large => 'Groß';

  @override
  String get extraLarge => 'Sehr groß';

  @override
  String libraryGenresTitle(String name) {
    return '$name — Genres';
  }

  @override
  String get views => 'Ansichten';

  @override
  String get albums => 'Alben';

  @override
  String get albumArtists => 'Alben-Interpreten';

  @override
  String get artists => 'Interpreten';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String get noSavedBookmarks =>
      'Noch keine gespeicherten Lesezeichen für diesen Titel.';

  @override
  String get openBook => 'Buch öffnen';

  @override
  String get chapter => 'Kapitel';

  @override
  String get page => 'Seite';

  @override
  String get bookmark => 'Lesezeichen';

  @override
  String get justNow => 'Gerade eben';

  @override
  String minutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String hoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String daysAgo(int count) {
    return 'vor $count T.';
  }

  @override
  String get discoverySubjects => 'Entdecken-Themen';

  @override
  String get pickDiscoverySubjects =>
      'Wähle aus, welche Themen-Feeds in Entdecken angezeigt werden.';

  @override
  String get apply => 'Anwenden';

  @override
  String get audiobookGenres => 'Hörbuch-Genres';

  @override
  String get pickAudiobookGenres =>
      'Wähle aus, welche Genres in Hörbuch-Entdecken angezeigt werden.';

  @override
  String get discoverAudiobooks => 'Hörbücher entdecken';

  @override
  String get librivoxDescription => 'Beliebte gemeinfreie Titel von LibriVox.';

  @override
  String titlesCount(int count) {
    return '$count Titel';
  }

  @override
  String get scrollLeft => 'Nach links scrollen';

  @override
  String get scrollRight => 'Nach rechts scrollen';

  @override
  String get couldNotLoadGenre =>
      'Dieses Genre konnte gerade nicht geladen werden.';

  @override
  String get continueReading => 'Weiterlesen';

  @override
  String get savedHighlights => 'Gespeicherte Markierungen';

  @override
  String get continueListening => 'Weiterhören';

  @override
  String get listen => 'Anhören';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get failedToLoadLibrary => 'Bibliothek konnte nicht geladen werden';

  @override
  String get popularNow => 'Jetzt beliebt';

  @override
  String get savedForLater => 'Für später gespeichert';

  @override
  String get topListens => 'Am meisten gehört';

  @override
  String get unreadDiscoveries => 'Ungelesene Entdeckungen';

  @override
  String get pickUpAgain => 'Wieder aufnehmen';

  @override
  String get bookHighlightsDescription =>
      'Deine Bücher mit Markierungen, Favoriten oder Lesefortschritt.';

  @override
  String get handPickedFromLibrary => 'Handverlesen aus deiner Bibliothek.';

  @override
  String get handPickedFromListeningQueue =>
      'Handverlesen aus deiner Hörwarteschlange.';

  @override
  String get booksWithHighlights =>
      'Bücher mit Markierungen, Favoriten oder Lesefortschritt.';

  @override
  String get jumpBackNarration =>
      'Springe zurück in die Erzählung, ohne deine Stelle suchen zu müssen.';

  @override
  String get unreadBooksReady =>
      'Ungelesene Bücher, bereit für die nächste ruhige Stunde.';

  @override
  String get quickAccessFavorites =>
      'Schnellzugriff auf die Bücher, zu denen du immer wieder zurückkehrst.';

  @override
  String get searchAudiobooks => 'Hörbücher suchen';

  @override
  String get searchYourLibrary => 'Deine Bibliothek durchsuchen';

  @override
  String get pickUpStory =>
      'Setze die Geschichte dort fort, wo du aufgehört hast';

  @override
  String get savedPlacesChapters =>
      'Deine gespeicherten Stellen und unvollständigen Kapitel';

  @override
  String authorsCount(int count) {
    return '$count Autoren';
  }

  @override
  String genresCount(int count) {
    return '$count Genres';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent % abgeschlossen';
  }

  @override
  String get readyWhenYouAre => 'Bereit, wenn du es bist';

  @override
  String get details => 'Details';

  @override
  String get listeningRoom => 'Hörzimmer';

  @override
  String get bookmarksAndProgress => 'Lesezeichen & Fortschritt';

  @override
  String titlesArrangedForBrowsing(int count) {
    return '$count Titel zum Stöbern angeordnet.';
  }

  @override
  String get titles => 'Titel';

  @override
  String get allTitles => 'Alle Titel';

  @override
  String get authors => 'Autoren';

  @override
  String get browseByAuthor => 'Nach Autor durchsuchen';

  @override
  String get browseByGenre => 'Nach Genre durchsuchen';

  @override
  String get discover => 'Entdecken';

  @override
  String get trendingTitlesOpenLibrary =>
      'Aktuelle Titel nach Thema von Open Library.';

  @override
  String get noBookmarkedItems =>
      'Noch keine mit Lesezeichen versehenen Einträge';

  @override
  String get nothingMatchesSection =>
      'Nichts passt zu diesem Bereich. Versuche einen anderen Tab oder komme nach der Bibliothekssynchronisierung zurück.';

  @override
  String get audiobooks => 'Hörbücher';

  @override
  String noLabelFound(String label) {
    return 'Keine $label gefunden';
  }

  @override
  String get folder => 'Ordner';

  @override
  String get filters => 'Filter';

  @override
  String get readingStatus => 'Lesestatus';

  @override
  String get playedStatus => 'Wiedergabestatus';

  @override
  String get readStatus => 'Gelesen';

  @override
  String get watched => 'Gesehen';

  @override
  String get unread => 'Ungelesen';

  @override
  String get unwatched => 'Nicht gesehen';

  @override
  String get seriesStatus => 'Serienstatus';

  @override
  String get allLibraries => 'Alle Bibliotheken';

  @override
  String get books => 'Bücher';

  @override
  String get author => 'Autor';

  @override
  String get unknownAuthor => 'Unbekannter Autor';

  @override
  String get uncategorized => 'Unkategorisiert';

  @override
  String get overview => 'Übersicht';

  @override
  String get noLibrivoxDescription =>
      'Für diesen Titel ist noch keine Beschreibung von LibriVox vorhanden.';

  @override
  String get readers => 'Vorleser';

  @override
  String get openLinks => 'Links öffnen';

  @override
  String get librivoxPage => 'LibriVox-Seite';

  @override
  String get internetArchive => 'Internet Archive';

  @override
  String get rssFeed => 'RSS-Feed';

  @override
  String get downloadZip => 'ZIP herunterladen';

  @override
  String sectionCountLabel(int count) {
    return '$count Abschnitte';
  }

  @override
  String firstPublished(int year) {
    return 'Erstveröffentlichung $year';
  }

  @override
  String get noOpenLibraryOverview =>
      'Für diesen Titel ist noch keine Übersicht von Open Library verfügbar.';

  @override
  String get subjects => 'Themen';

  @override
  String get all => 'Alle';

  @override
  String booksCount(int count) {
    return '$count Bücher';
  }

  @override
  String get couldNotLoadSubject =>
      'Dieses Thema konnte gerade nicht geladen werden.';

  @override
  String get audiobookDetails => 'Hörbuch-Details';

  @override
  String authorsCountTitle(int count) {
    return '$count Autoren';
  }

  @override
  String audiobookCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Hörbücher',
      one: '1 Hörbuch',
    );
    return '$_temp0';
  }

  @override
  String get trackList => 'Titelliste';

  @override
  String get itemListPlaceholder => 'Die Elementliste wird hier angezeigt';

  @override
  String get favoriteTracksPlaceholder =>
      'Favorisierte Titel werden hier angezeigt';

  @override
  String get failedToLoad => 'Laden fehlgeschlagen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get moreLikeThis => 'Mehr davon';

  @override
  String get castAndCrew => 'Besetzung & Crew';

  @override
  String get collection => 'Sammlung';

  @override
  String get episodes => 'Episoden';

  @override
  String get nextUp => 'Als Nächstes';

  @override
  String get seasons => 'Staffeln';

  @override
  String get chapters => 'Kapitel';

  @override
  String get features => 'Besonderheiten';

  @override
  String get movies => 'Filme';

  @override
  String get other => 'Sonstige';

  @override
  String get discography => 'Diskografie';

  @override
  String get similarArtists => 'Ähnliche Interpreten';

  @override
  String get tableOfContents => 'Inhaltsverzeichnis';

  @override
  String get tracklist => 'Titelliste';

  @override
  String get biography => 'Biografie';

  @override
  String get authorDetails => 'Autordetails';

  @override
  String get noOverviewAvailable =>
      'Für diesen Titel ist noch keine Übersicht verfügbar.';

  @override
  String get noBiographyAvailable =>
      'Für diesen Autor ist keine Biografie verfügbar.';

  @override
  String get noBooksFound => 'Keine Bücher für diesen Autor gefunden.';

  @override
  String get unableToLoadAuthorDetails =>
      'Autordetails konnten gerade nicht geladen werden.';

  @override
  String published(int year) {
    return 'Veröffentlicht $year';
  }

  @override
  String get publicationDateUnknown => 'Veröffentlichungsdatum unbekannt';

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Staffeln',
      one: '1 Staffel',
    );
    return '$_temp0';
  }

  @override
  String endsAt(String time) {
    return 'Endet um $time';
  }

  @override
  String get view => 'Ansehen';

  @override
  String get resumeReading => 'Weiterlesen';

  @override
  String get read => 'Lesen';

  @override
  String resumeFrom(String position) {
    return 'Fortsetzen ab $position';
  }

  @override
  String get play => 'Abspielen';

  @override
  String get startOver => 'Von vorn beginnen';

  @override
  String get restart => 'Neustart';

  @override
  String get readOffline => 'Offline lesen';

  @override
  String get playOffline => 'Offline abspielen';

  @override
  String get audio => 'Audio';

  @override
  String get subtitles => 'Untertitel';

  @override
  String get version => 'Version';

  @override
  String get cast => 'Besetzung';

  @override
  String get trailer => 'Trailer';

  @override
  String get finished => 'Abgeschlossen';

  @override
  String get favorited => 'Favorisiert';

  @override
  String get favorite => 'Favorit';

  @override
  String get playlist => 'Wiedergabeliste';

  @override
  String get downloaded => 'Heruntergeladen';

  @override
  String get downloadAll => 'Alle herunterladen';

  @override
  String get download => 'Herunterladen';

  @override
  String get deleteDownloaded => 'Download löschen';

  @override
  String get goToSeries => 'Zur Serie';

  @override
  String get editMetadata => 'Metadaten bearbeiten';

  @override
  String get less => 'Weniger';

  @override
  String get more => 'Mehr';

  @override
  String get deleteItem => 'Element löschen';

  @override
  String get deletePlaylist => 'Wiedergabeliste löschen';

  @override
  String get deletePlaylistMessage =>
      'Diese Wiedergabeliste vom Server löschen?';

  @override
  String get deleteItemMessage => 'Dieses Element vom Server löschen?';

  @override
  String get failedToDeletePlaylist =>
      'Wiedergabeliste konnte nicht gelöscht werden';

  @override
  String get failedToDeleteItem => 'Element konnte nicht gelöscht werden';

  @override
  String get renamePlaylist => 'Wiedergabeliste umbenennen';

  @override
  String get playlistName => 'Name der Wiedergabeliste';

  @override
  String get deleteDownloadedAlbum => 'Heruntergeladenes Album löschen';

  @override
  String deleteDownloadedTracksMessage(String title) {
    return 'Heruntergeladene Titel für „$title“ löschen?';
  }

  @override
  String get downloadedTracksDeleted => 'Heruntergeladene Titel gelöscht';

  @override
  String get downloadedTracksDeleteFailed =>
      'Einige heruntergeladene Titel konnten nicht gelöscht werden';

  @override
  String get noTracksLoaded => 'Keine Titel geladen';

  @override
  String noItemsLoaded(String itemLabel) {
    return 'Keine $itemLabel geladen';
  }

  @override
  String downloadingTitle(String title, int count) {
    return '$title wird heruntergeladen ($count Einträge)...';
  }

  @override
  String deleteConfirmMessage(String name) {
    return 'Möchtest du „$name“ wirklich vom Server löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get itemDeleted => 'Element gelöscht';

  @override
  String get noPlayableTrailerFound => 'Kein abspielbarer Trailer gefunden.';

  @override
  String unsupportedBookFormat(String extension) {
    return 'Nicht unterstütztes Buchformat: .$extension';
  }

  @override
  String get audioTrack => 'Audiospur';

  @override
  String get subtitleTrack => 'Untertitelspur';

  @override
  String get none => 'Keine';

  @override
  String get downloadSubtitlesLabel => 'Untertitel herunterladen...';

  @override
  String get searchOpenSubtitlesPlugin => 'Mit dem OpenSubtitles-Plugin suchen';

  @override
  String get downloadSubtitles => 'Untertitel herunterladen';

  @override
  String get selectedSubtitleInvalid =>
      'Der ausgewählte Untertitel ist ungültig.';

  @override
  String subtitleDownloadedSelected(String name) {
    return 'Untertitel heruntergeladen und ausgewählt: $name';
  }

  @override
  String get subtitleDownloadedPending =>
      'Untertitel heruntergeladen. Es kann einen Moment dauern, bis er angezeigt wird, während Jellyfin das Element aktualisiert.';

  @override
  String noRemoteSubtitlesFound(String language) {
    return 'Keine Remote-Untertitel für $language gefunden.';
  }

  @override
  String get selectVersion => 'Version auswählen';

  @override
  String versionNumber(int number) {
    return 'Version $number';
  }

  @override
  String get downloadAllQuality => 'Alle herunterladen — Qualität';

  @override
  String get downloadQuality => 'Downloadqualität';

  @override
  String get originalFileNoReencoding => 'Originaldatei, ohne Neukodierung';

  @override
  String get originalFilesNoReencoding => 'Originaldateien, ohne Neukodierung';

  @override
  String get noEpisodesLoaded => 'Keine Episoden geladen';

  @override
  String downloadingItem(String name, String quality) {
    return '$name wird heruntergeladen ($quality)...';
  }

  @override
  String get deleteDownloadedFiles => 'Heruntergeladene Dateien löschen';

  @override
  String deleteLocalFilesMessage(String typeLabel) {
    return 'Lokale Dateien für $typeLabel löschen?\n\nDies gibt Speicherplatz frei. Du kannst sie später erneut herunterladen.';
  }

  @override
  String get downloadedFilesDeleted => 'Heruntergeladene Dateien gelöscht';

  @override
  String get failedToDeleteFiles => 'Dateien konnten nicht gelöscht werden';

  @override
  String get deleteFiles => 'Dateien löschen';

  @override
  String get director => 'REGIE';

  @override
  String get writers => 'DREHBUCH';

  @override
  String get studio => 'STUDIO';

  @override
  String studioMoreCount(int count) {
    return '+$count weitere';
  }

  @override
  String totalEpisodes(int count) {
    return '$count Episoden';
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
    return 'Kapitel $number';
  }

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String chapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kapitel',
      one: '1 Kapitel',
    );
    return '$_temp0';
  }

  @override
  String born(String date) {
    return 'Geboren $date';
  }

  @override
  String died(String date) {
    return 'Gestorben $date';
  }

  @override
  String age(int age) {
    return 'Alter $age';
  }

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get readMore => 'Mehr lesen';

  @override
  String get shuffle => 'Zufallswiedergabe';

  @override
  String downloadsCount(int count) {
    return '$count Downloads';
  }

  @override
  String get perfectMatch => 'Perfekte Übereinstimmung';

  @override
  String channelsCount(int count) {
    return '$count Kanäle';
  }

  @override
  String get mono => 'Mono';

  @override
  String get stereo => 'Stereo';

  @override
  String remoteSubtitlePermissionError(String action) {
    return 'Remote-Untertitel-$action erfordert die Jellyfin-Untertitelverwaltungsberechtigung für diesen Benutzer.';
  }

  @override
  String remoteSubtitleNotFoundError(String action) {
    return 'Dieses Element konnte auf dem Server für Remote-Untertitel-$action nicht gefunden werden.';
  }

  @override
  String remoteSubtitleDetailError(String action, String detail) {
    return 'Remote-Untertitel-$action fehlgeschlagen: $detail';
  }

  @override
  String remoteSubtitleHttpError(String action, int status) {
    return 'Remote-Untertitel-$action fehlgeschlagen (HTTP $status).';
  }

  @override
  String remoteSubtitleGenericError(String action) {
    return 'Remote-Untertitel konnten nicht $action werden.';
  }

  @override
  String deleteSeriesFiles(String name) {
    return 'alle heruntergeladenen Episoden für „$name“';
  }

  @override
  String get deleteSeasonFiles =>
      'alle heruntergeladenen Episoden in dieser Staffel';

  @override
  String get stillWatching => 'Noch da?';

  @override
  String get unableToLoadTrailerStream =>
      'Trailer-Stream konnte nicht geladen werden.';

  @override
  String get trailerTimedOut => 'Zeitüberschreitung beim Laden des Trailers.';

  @override
  String get playbackFailedForTrailer =>
      'Wiedergabe für diesen Trailer fehlgeschlagen.';

  @override
  String photoCountOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get castingUnavailableOffline =>
      'Streaming ist während der Offline-Wiedergabe nicht verfügbar.';

  @override
  String castActionFailed(String label, String error) {
    return '$label-Aktion fehlgeschlagen: $error';
  }

  @override
  String failedToSetCastVolume(String error) {
    return 'Cast-Lautstärke konnte nicht eingestellt werden: $error';
  }

  @override
  String castControlsTitle(String label) {
    return '$label-Steuerung';
  }

  @override
  String get deviceVolume => 'Gerätelautstärke';

  @override
  String get unavailable => 'Nicht verfügbar';

  @override
  String get pause => 'Pause';

  @override
  String get syncPosition => 'Position synchronisieren';

  @override
  String stopCast(String label) {
    return '$label stoppen';
  }

  @override
  String get queueIsEmpty => 'Die Warteschlange ist leer';

  @override
  String trackNumber(int number) {
    return 'Titel $number';
  }

  @override
  String get remotePlayback => 'Remote-Wiedergabe';

  @override
  String get castingToGoogleCast => 'Wird zu Google Cast übertragen';

  @override
  String get castingViaAirPlay => 'Wird über AirPlay übertragen';

  @override
  String get castingViaDlna => 'Wird über DLNA übertragen';

  @override
  String secondsCount(int seconds) {
    return '$seconds Sekunden';
  }

  @override
  String get longPressToUnlock => 'Zum Entsperren lange drücken';

  @override
  String get off => 'Aus';

  @override
  String streamTypeFallback(String streamType, int number) {
    return '$streamType $number';
  }

  @override
  String get auto => 'Automatisch';

  @override
  String bitrateValueMbps(int mbps) {
    return '$mbps Mbit/s';
  }

  @override
  String get audioDelay => 'Audioverzögerung';

  @override
  String get subtitleDelay => 'Untertitelverzögerung';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get playbackInformation => 'Wiedergabe-Informationen';

  @override
  String get playback => 'Wiedergabe';

  @override
  String get playMethod => 'Wiedergabemethode';

  @override
  String get directPlay => 'Direktwiedergabe';

  @override
  String get directStream => 'Direkter Stream';

  @override
  String get transcoding => 'Transkodierung';

  @override
  String get transcodeReasons => 'Transkodierungsgründe';

  @override
  String get player => 'Player';

  @override
  String get container => 'Container';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get video => 'Video';

  @override
  String get resolution => 'Auflösung';

  @override
  String get hdr => 'HDR';

  @override
  String get codec => 'Codec';

  @override
  String get videoBitrate => 'Video-Bitrate';

  @override
  String get track => 'Titel';

  @override
  String get channels => 'Kanäle';

  @override
  String get audioBitrate => 'Audio-Bitrate';

  @override
  String get sampleRate => 'Abtastrate';

  @override
  String get format => 'Format';

  @override
  String get external => 'Extern';

  @override
  String get embedded => 'Eingebettet';

  @override
  String castSessionError(String protocol) {
    return '$protocol-Sitzungsfehler';
  }

  @override
  String failedToLoadBookDetails(String error) {
    return 'Buchdetails konnten nicht geladen werden: $error';
  }

  @override
  String get epubUnavailableOnPlatform =>
      'EPUB-Darstellung in der App ist auf dieser Plattform noch nicht verfügbar.';

  @override
  String formatCannotRenderInApp(String extension) {
    return 'Dieses Format (.$extension) kann in der App noch nicht dargestellt werden.';
  }

  @override
  String get embeddedRenderingUnavailable =>
      'Eingebettete Dokumentendarstellung ist auf dieser Plattform nicht verfügbar.';

  @override
  String get couldNotOpenExternalViewer =>
      'Externer Viewer konnte nicht geöffnet werden.';

  @override
  String failedToOpenInAppReader(String error) {
    return 'In-App-Reader konnte nicht geöffnet werden: $error';
  }

  @override
  String bookmarkAlreadySaved(String label) {
    return 'Lesezeichen bereits bei $label gespeichert.';
  }

  @override
  String bookmarkAdded(String label) {
    return 'Lesezeichen hinzugefügt: $label';
  }

  @override
  String get noBookmarksYet =>
      'Noch keine Lesezeichen.\nTippe beim Lesen auf das Lesezeichen-Symbol, um deine Position zu speichern.';

  @override
  String get noTableOfContentsAvailable => 'Kein Inhaltsverzeichnis verfügbar';

  @override
  String pageLabel(int number) {
    return 'Seite $number';
  }

  @override
  String get position => 'Position';

  @override
  String get bookReader => 'Buchleser';

  @override
  String formatExtension(String extension) {
    return 'Format: .$extension';
  }

  @override
  String percentRead(String percent) {
    return '$percent % gelesen';
  }

  @override
  String get updating => 'Wird aktualisiert...';

  @override
  String get markUnread => 'Als ungelesen markieren';

  @override
  String get markAsRead => 'Als gelesen markieren';

  @override
  String get reloadReader => 'Reader neu laden';

  @override
  String get noPagesFound => 'Keine Seiten gefunden.';

  @override
  String get failedToDecodePageImage =>
      'Seitenbild konnte nicht dekodiert werden.';

  @override
  String resetZoom(String zoom) {
    return 'Zoom zurücksetzen (${zoom}x)';
  }

  @override
  String get singlePage => 'Einzelseite';

  @override
  String get twoPageSpread => 'Doppelseite';

  @override
  String get addBookmark => 'Lesezeichen hinzufügen';

  @override
  String get bookmarksEllipsis => 'Lesezeichen...';

  @override
  String get markedAsRead => 'Als gelesen markiert';

  @override
  String get markedAsUnread => 'Als ungelesen markiert';

  @override
  String failedToUpdateReadState(String error) {
    return 'Lesestatus konnte nicht aktualisiert werden: $error';
  }

  @override
  String get themeSystem => 'Thema: System';

  @override
  String get themeLight => 'Thema: Hell';

  @override
  String get themeDark => 'Thema: Dunkel';

  @override
  String get themeSepia => 'Thema: Sepia';

  @override
  String get invertColorsFixedLayout => 'Farben invertieren (festes Layout)';

  @override
  String get invertColorsPdf => 'Farben invertieren (PDF)';

  @override
  String get preparingInAppReader => 'In-App-Reader wird vorbereitet...';

  @override
  String get pdfDataNotAvailable => 'PDF-Daten nicht verfügbar.';

  @override
  String get readerFallbackModeActive => 'Reader-Fallbackmodus aktiv';

  @override
  String platformCannotHostDocumentEngine(String extension) {
    return 'Diese Plattform kann die eingebettete Dokument-Engine für $extension-Dateien nicht hosten.';
  }

  @override
  String get reloadReaderPlatformHint =>
      'Verwende „Reader neu laden“ nach dem Wechsel zu einem unterstützten Plattformziel (Android, iOS, macOS).';

  @override
  String get openExternally => 'Extern öffnen';

  @override
  String get noEpubChaptersFound => 'Keine EPUB-Kapitel gefunden.';

  @override
  String get readerNotReady => 'Reader nicht bereit.';

  @override
  String get seriesRecordings => 'Serienaufnahmen';

  @override
  String get now => 'Jetzt';

  @override
  String get sports => 'Sport';

  @override
  String get news => 'Nachrichten';

  @override
  String get kids => 'Kinder';

  @override
  String get premiere => 'Premiere';

  @override
  String get guideTimeline => 'Programmzeitleiste';

  @override
  String failedToLoadGuide(String error) {
    return 'Programmführer konnte nicht geladen werden: $error';
  }

  @override
  String get noChannelsFound => 'Keine Kanäle gefunden';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get movie => 'Film';

  @override
  String get removedFromFavoriteChannels => 'Aus Lieblingskanälen entfernt';

  @override
  String get addedToFavoriteChannels => 'Zu Lieblingskanälen hinzugefügt';

  @override
  String get failedToUpdateFavoriteChannel =>
      'Lieblingskanal konnte nicht aktualisiert werden';

  @override
  String get unfavoriteChannel => 'Kanal aus Favoriten entfernen';

  @override
  String get favoriteChannel => 'Kanal favorisieren';

  @override
  String get watch => 'Ansehen';

  @override
  String get close => 'Schließen';

  @override
  String failedToPlayChannel(String name) {
    return '$name konnte nicht abgespielt werden';
  }

  @override
  String get failedToLoadRecordings => 'Aufnahmen konnten nicht geladen werden';

  @override
  String get scheduledInNext24Hours => 'Geplant in den nächsten 24 Stunden';

  @override
  String get recentRecordings => 'Letzte Aufnahmen';

  @override
  String get tvSeries => 'TV-Serien';

  @override
  String get failedToLoadSchedule => 'Zeitplan konnte nicht geladen werden';

  @override
  String get noScheduledRecordings => 'Keine geplanten Aufnahmen';

  @override
  String get cancelRecording => 'Aufnahme abbrechen?';

  @override
  String cancelScheduledRecordingOf(String name) {
    return 'Geplante Aufnahme von „$name“ abbrechen?';
  }

  @override
  String get no => 'Nein';

  @override
  String get yesCancel => 'Ja, abbrechen';

  @override
  String get failedToCancelRecording =>
      'Aufnahme konnte nicht abgebrochen werden';

  @override
  String get failedToLoadSeriesRecordings =>
      'Serienaufnahmen konnten nicht geladen werden';

  @override
  String get noSeriesRecordings => 'Keine Serienaufnahmen';

  @override
  String get cancelSeriesRecording => 'Serienaufnahme abbrechen';

  @override
  String get cancelSeriesRecordingQuestion => 'Serienaufnahme abbrechen?';

  @override
  String stopRecordingName(String name) {
    return 'Aufnahme von „$name“ stoppen?';
  }

  @override
  String get failedToCancelSeriesRecording =>
      'Serienaufnahme konnte nicht abgebrochen werden';

  @override
  String get searchThisLibrary => 'Diese Bibliothek durchsuchen...';

  @override
  String get searchEllipsis => 'Suchen...';

  @override
  String noResultsForQuery(String query) {
    return 'Keine Ergebnisse für „$query“';
  }

  @override
  String searchFailedError(String error) {
    return 'Suche fehlgeschlagen: $error';
  }

  @override
  String get seerr => 'Seerr';

  @override
  String get savedMedia => 'Gespeicherte Medien';

  @override
  String get tvShows => 'TV-Sendungen';

  @override
  String get music => 'Musik';

  @override
  String get musicAlbums => 'Musikalben';

  @override
  String get noMediaInFilter => 'Keine Medien in diesem Filter';

  @override
  String get noDownloadedMediaYet => 'Noch keine heruntergeladenen Medien';

  @override
  String get browseLibrary => 'Bibliothek durchsuchen';

  @override
  String get deleteDownload => 'Download löschen';

  @override
  String removeItemAndFiles(String name) {
    return '„$name“ und zugehörige Dateien entfernen?';
  }

  @override
  String tracksCount(int count) {
    return '$count Titel';
  }

  @override
  String get album => 'Album';

  @override
  String get playAlbum => 'Album abspielen';

  @override
  String failedToLoadAlbum(String error) {
    return 'Album konnte nicht geladen werden: $error';
  }

  @override
  String noDownloadedTracksForAlbum(String name) {
    return 'Keine heruntergeladenen Titel für $name gefunden.';
  }

  @override
  String get season => 'Staffel';

  @override
  String get errorLoadingEpisodes => 'Fehler beim Laden der Episoden';

  @override
  String get noDownloadedEpisodes => 'Keine heruntergeladenen Episoden';

  @override
  String get deleteEpisode => 'Episode löschen';

  @override
  String removeName(String name) {
    return '„$name“ entfernen?';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes Min.';
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
  String get seriesNotFound => 'Serie nicht gefunden';

  @override
  String get errorLoadingSeries => 'Fehler beim Laden der Serie';

  @override
  String get downloadedEpisodes => 'Heruntergeladene Episoden';

  @override
  String seasonNumber(int number) {
    return 'Staffel $number';
  }

  @override
  String get specials => 'Specials';

  @override
  String get deleteSeason => 'Staffel löschen';

  @override
  String deleteAllEpisodesInSeason(String season) {
    return 'Alle heruntergeladenen Episoden in $season löschen?';
  }

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episoden',
      one: '1 Episode',
    );
    return '$_temp0';
  }

  @override
  String get storageManagement => 'Speicherverwaltung';

  @override
  String get storageBreakdown => 'Speicheraufschlüsselung';

  @override
  String get downloadedItems => 'Heruntergeladene Elemente';

  @override
  String get storageLimit => 'Speicherlimit';

  @override
  String get noLimit => 'Kein Limit';

  @override
  String get deleteAllDownloads => 'Alle Downloads löschen';

  @override
  String get deleteAllDownloadsWarning =>
      'Dadurch werden alle heruntergeladenen Mediendateien entfernt. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get deleteAll => 'Alle löschen';

  @override
  String get deleteSelected => 'Ausgewählte löschen';

  @override
  String deleteSelectedCount(int count) {
    return '$count heruntergeladene Elemente löschen?';
  }

  @override
  String get musicAndAudiobooks => 'Musik & Hörbücher';

  @override
  String get images => 'Bilder';

  @override
  String get database => 'Datenbank';

  @override
  String ofStorageLimit(String limit) {
    return 'von $limit Limit';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get authentication => 'Authentifizierung';

  @override
  String get autoLoginServerManagement =>
      'Automatische Anmeldung, Serververwaltung';

  @override
  String get pinCode => 'PIN-Code';

  @override
  String get setUpPinCodeProtection => 'PIN-Code-Schutz einrichten';

  @override
  String get parentalControls => 'Jugendschutz';

  @override
  String get contentRatingRestrictions => 'Altersfreigabe-Einschränkungen';

  @override
  String get bitRateResolutionBehavior => 'Bitrate, Auflösung, Verhalten';

  @override
  String get languageSizeAppearance => 'Sprache, Größe, Erscheinungsbild';

  @override
  String get qualityStorage => 'Qualität, Speicher';

  @override
  String get serverSyncAndPluginStatus =>
      'Serversynchronisierung und Plugin-Status';

  @override
  String get mediaRequestIntegration => 'Medienanfragen-Integration';

  @override
  String get switchServer => 'Server wechseln';

  @override
  String get signOut => 'Abmelden';

  @override
  String get versionLicenses => 'Version, Lizenzen';

  @override
  String get account => 'Konto';

  @override
  String get signInAndSecurity => 'Anmeldung und Sicherheit';

  @override
  String get administration => 'Administration';

  @override
  String get serverSettingsUsersLibraries =>
      'Servereinstellungen, Benutzer, Bibliotheken';

  @override
  String get customization => 'Anpassung';

  @override
  String get themeAndLayout => 'Thema und Layout';

  @override
  String get videoAndSubtitles => 'Video und Untertitel';

  @override
  String get integrations => 'Integrationen';

  @override
  String get pluginAndRequests => 'Plugin und Anfragen';

  @override
  String get customizeAccountPlaybackInterface =>
      'Konto, Wiedergabe und Oberfläche anpassen';

  @override
  String optionsCount(int count) {
    return '$count Optionen';
  }

  @override
  String get themeAndAppearance => 'Thema & Erscheinungsbild';

  @override
  String get focusBorderColor => 'Fokusrahmenfarbe';

  @override
  String get watchedIndicators => 'Gesehen-Indikatoren';

  @override
  String get always => 'Immer';

  @override
  String get hideUnwatched => 'Nicht Gesehene ausblenden';

  @override
  String get episodesOnly => 'Nur Episoden';

  @override
  String get never => 'Nie';

  @override
  String get focusExpansionAnimation => 'Fokus-Vergrößerungsanimation';

  @override
  String get scaleFocusedCards =>
      'Fokussierte oder überfahrene Karten und Kacheln vergrößern';

  @override
  String get backgroundBackdrops => 'Hintergrundbilder';

  @override
  String get showBackdropImages => 'Hintergrundbilder hinter Inhalten anzeigen';

  @override
  String get seriesThumbnails => 'Serien-Miniaturbilder';

  @override
  String get seriesThumbnailsDescription =>
      'Nur Episoden: Serienbilder verwenden, die zum Bildtyp jeder Reihe passen';

  @override
  String get homeRowInfoOverlay => 'Startseiten-Info-Overlay';

  @override
  String get showTitleMetadataOnHomeRows =>
      'Titel und Metadaten beim Durchstöbern der Startseite anzeigen';

  @override
  String get clockDisplay => 'Uhranzeige';

  @override
  String get inMenus => 'In Menüs';

  @override
  String get inVideo => 'Im Video';

  @override
  String get seasonalEffects => 'Saisonale Effekte';

  @override
  String get snow => 'Schnee';

  @override
  String get fireworks => 'Feuerwerk';

  @override
  String get confetti => 'Konfetti';

  @override
  String get fallingLeaves => 'Fallende Blätter';

  @override
  String get themeMusic => 'Titelmusik';

  @override
  String get playThemeMusicOnDetailPages =>
      'Titelmusik auf Detailseiten abspielen';

  @override
  String get themeMusicVolume => 'Titelmusik-Lautstärke';

  @override
  String percentValue(int value) {
    return '$value %';
  }

  @override
  String get themeMusicOnHomeRows => 'Titelmusik auf der Startseite';

  @override
  String get playWhenBrowsingHomeScreen =>
      'Beim Durchstöbern der Startseite abspielen';

  @override
  String get detailsBackgroundBlur => 'Detail-Hintergrundunschärfe';

  @override
  String pixelValue(int value) {
    return '$value px';
  }

  @override
  String get browsingBackgroundBlur => 'Stöbern-Hintergrundunschärfe';

  @override
  String get maxStreamingBitrate => 'Maximale Streaming-Bitrate';

  @override
  String get maxResolution => 'Maximale Auflösung';

  @override
  String get playerZoomMode => 'Player-Zoommodus';

  @override
  String get fit => 'Einpassen';

  @override
  String get autoCrop => 'Automatisch zuschneiden';

  @override
  String get stretch => 'Strecken';

  @override
  String get refreshRateSwitching => 'Bildwiederholrate-Umschaltung';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get scaleOnTv => 'Auf TV skalieren';

  @override
  String get scaleOnDevice => 'Auf Gerät skalieren';

  @override
  String get trickPlay => 'Trick Play';

  @override
  String get showPreviewThumbnailsWhenSeeking =>
      'Vorschaubilder beim Spulen anzeigen';

  @override
  String get showDescriptionOnPause => 'Beschreibung bei Pause anzeigen';

  @override
  String get dimVideoShowOverview =>
      'Video abdunkeln und Übersichtstext bei Pause anzeigen';

  @override
  String get osdLockButton => 'OSD-Sperrtaste';

  @override
  String get osdLockButtonDescription =>
      'Sperrtaste anzeigen, die Touch-Eingaben blockiert, bis lange gedrückt wird';

  @override
  String get audioBehavior => 'Audio-Verhalten';

  @override
  String get downmixToStereo => 'Auf Stereo heruntermischen';

  @override
  String get defaultAudioLanguage => 'Standard-Audiosprache';

  @override
  String get autoServerDefault => 'Automatisch (Serverstandard)';

  @override
  String get english => 'Englisch';

  @override
  String get spanish => 'Spanisch';

  @override
  String get french => 'Französisch';

  @override
  String get german => 'Deutsch';

  @override
  String get italian => 'Italienisch';

  @override
  String get portuguese => 'Portugiesisch';

  @override
  String get japanese => 'Japanisch';

  @override
  String get korean => 'Koreanisch';

  @override
  String get chinese => 'Chinesisch';

  @override
  String get russian => 'Russisch';

  @override
  String get arabic => 'Arabisch';

  @override
  String get hindi => 'Hindi';

  @override
  String get dutch => 'Niederländisch';

  @override
  String get swedish => 'Schwedisch';

  @override
  String get norwegian => 'Norwegisch';

  @override
  String get danish => 'Dänisch';

  @override
  String get finnish => 'Finnisch';

  @override
  String get polish => 'Polnisch';

  @override
  String get ac3Passthrough => 'AC3-Durchleitung';

  @override
  String get trueHdSupport => 'TrueHD-Unterstützung';

  @override
  String get enableTrueHdAudio =>
      'TrueHD-Audio aktivieren (funktioniert möglicherweise nicht auf allen Plattformen)';

  @override
  String get nightMode => 'Nachtmodus';

  @override
  String get compressDynamicRange => 'Dynamikbereich komprimieren';

  @override
  String get advancedMpv => 'Erweitertes mpv';

  @override
  String get enableCustomMpvConf => 'Benutzerdefinierte mpv.conf aktivieren';

  @override
  String get applyMpvConfBeforePlayback =>
      'Eine benutzerdefinierte mpv.conf vor der Wiedergabe anwenden';

  @override
  String get unsafeAdvancedMpvOptions => 'Unsichere erweiterte mpv-Optionen';

  @override
  String get unsafeMpvOptionsDescription =>
      'Erweiterte mpv-Optionen zulassen. Kann das Wiedergabeverhalten beeinträchtigen.';

  @override
  String get nextUpAndQueuing => 'Als Nächstes & Warteschlange';

  @override
  String get nextUpBehavior => 'Nächstes-Verhalten';

  @override
  String get extended => 'Erweitert';

  @override
  String get minimal => 'Minimal';

  @override
  String get nextUpTimeout => 'Nächstes-Timeout';

  @override
  String secondsValue(int value) {
    return '$value s';
  }

  @override
  String get mediaQueuing => 'Medien-Warteschlange';

  @override
  String get autoQueueNextEpisodes => 'Nächste Episoden automatisch einreihen';

  @override
  String get stillWatchingPrompt => 'Noch-da-Abfrage';

  @override
  String afterEpisodesAndHours(int episodes, double hours) {
    return 'Nach $episodes Episoden / $hours Std.';
  }

  @override
  String get resumeAndSkip => 'Fortsetzen & Überspringen';

  @override
  String get resumeRewind => 'Zurückspulen beim Fortsetzen';

  @override
  String get fiveSeconds => '5 Sekunden';

  @override
  String get tenSeconds => '10 Sekunden';

  @override
  String get fifteenSeconds => '15 Sekunden';

  @override
  String get thirtySeconds => '30 Sekunden';

  @override
  String get skipBackLength => 'Rücksprunglänge';

  @override
  String get skipForwardLength => 'Vorsprunglänge';

  @override
  String get customMpvConfPath => 'Benutzerdefinierter mpv.conf-Pfad';

  @override
  String get notSetMpvConf =>
      'Nicht gesetzt. Moonfin versucht eine Standard-mpv.conf in App-/Datenordnern.';

  @override
  String get selectMpvConf => 'mpv.conf auswählen';

  @override
  String get pathToMpvConf => '/pfad/zu/mpv.conf';

  @override
  String get subtitleStyleDescription =>
      'Stileinstellungen (Größe, Farbe, Versatz) gelten für textbasierte Untertitel (SRT, VTT, TTML). ASS/SSA-Untertitel verwenden ihre eigene eingebettete Formatierung, es sei denn „ASS/SSA-Direktwiedergabe“ ist deaktiviert. Bitmap-Untertitel (PGS, DVB, VobSub) können nicht umformatiert werden.';

  @override
  String get defaultSubtitleLanguage => 'Standard-Untertitelsprache';

  @override
  String get defaultToNoSubtitles => 'Standardmäßig keine Untertitel';

  @override
  String get turnOffSubtitlesByDefault =>
      'Untertitel standardmäßig ausschalten';

  @override
  String get subtitleSize => 'Untertitelgröße';

  @override
  String get textColor => 'Textfarbe';

  @override
  String get backgroundColor => 'Hintergrundfarbe';

  @override
  String get strokeColor => 'Konturfarbe';

  @override
  String get verticalOffset => 'Vertikaler Versatz';

  @override
  String get pgsDirectPlay => 'PGS-Direktwiedergabe';

  @override
  String get directPlayPgsSubtitles => 'PGS-Untertitel direkt wiedergeben';

  @override
  String get assSsaDirectPlay => 'ASS/SSA-Direktwiedergabe';

  @override
  String get directPlayAssSsaSubtitles =>
      'ASS/SSA-Untertitel direkt wiedergeben';

  @override
  String get white => 'Weiß';

  @override
  String get black => 'Schwarz';

  @override
  String get yellow => 'Gelb';

  @override
  String get green => 'Grün';

  @override
  String get cyan => 'Cyan';

  @override
  String get red => 'Rot';

  @override
  String get transparent => 'Transparent';

  @override
  String get semiTransparentBlack => 'Halbtransparentes Schwarz';

  @override
  String get global => 'Global';

  @override
  String get desktop => 'Desktop';

  @override
  String get mobile => 'Mobil';

  @override
  String get tv => 'TV';

  @override
  String loadedProfileSettings(String profile) {
    return '$profile-Profileinstellungen geladen.';
  }

  @override
  String failedToLoadProfileSettings(String profile) {
    return '$profile-Profileinstellungen konnten nicht geladen werden.';
  }

  @override
  String syncedSettingsToProfile(String profile) {
    return 'Lokale Einstellungen mit $profile-Profil synchronisiert.';
  }

  @override
  String get customizationProfile => 'Anpassungsprofil';

  @override
  String get customizationProfileDescription =>
      'Wähle das Profil zum Laden, Bearbeiten und Synchronisieren. Global gilt überall, sofern kein Geräteprofil es überschreibt. Der grüne Punkt markiert dein aktuelles Geräteprofil.';

  @override
  String get loadProfile => 'Profil laden';

  @override
  String get syncing => 'Synchronisiere...';

  @override
  String get syncToProfile => 'Zum Profil synchronisieren';

  @override
  String get profileSyncHidden => 'Profilsynchronisierung ausgeblendet';

  @override
  String get enablePluginSyncDescription =>
      'Aktiviere die Server-Plugin-Synchronisierung in den Plugin-Einstellungen, um hier Profilsteuerungen anzuzeigen.';

  @override
  String get quality => 'Qualität';

  @override
  String get defaultDownloadQuality => 'Standard-Downloadqualität';

  @override
  String get network => 'Netzwerk';

  @override
  String get wifiOnlyDownloads => 'Nur über WLAN herunterladen';

  @override
  String get onlyDownloadOnWifi => 'Nur herunterladen, wenn mit WLAN verbunden';

  @override
  String get storage => 'Speicher';

  @override
  String get storageUsed => 'Genutzter Speicher';

  @override
  String get manage => 'Verwalten';

  @override
  String get calculating => 'Wird berechnet...';

  @override
  String get downloadLocation => 'Speicherort';

  @override
  String get defaultLabel => 'Standard';

  @override
  String get saveToDownloadsFolder => 'Im Downloads-Ordner speichern';

  @override
  String get downloadsVisibleToOtherApps =>
      'Downloads/Moonfin — für andere Apps sichtbar';

  @override
  String get dangerZone => 'Gefahrenzone';

  @override
  String get clearAllDownloads => 'Alle Downloads löschen';

  @override
  String get original => 'Original';

  @override
  String get changeDownloadLocation => 'Speicherort ändern';

  @override
  String get changeDownloadLocationDescription =>
      'Neue Downloads werden im ausgewählten Ordner gespeichert. Bestehende Downloads verbleiben an ihrem aktuellen Speicherort und können in den Speichereinstellungen verwaltet werden.';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get cannotWriteToFolder =>
      'In den ausgewählten Ordner kann nicht geschrieben werden. Bitte wähle einen anderen Speicherort oder erteile Speicherberechtigungen.';

  @override
  String get saveToDownloadsFolderQuestion => 'Im Downloads-Ordner speichern?';

  @override
  String get saveToDownloadsFolderDescription =>
      'Heruntergeladene Medien werden im Downloads/Moonfin-Ordner auf deinem Gerät gespeichert. Diese Dateien sind für andere Apps wie deine Galerie oder deinen Musikplayer sichtbar.\n\nBestehende Downloads verbleiben an ihrem aktuellen Speicherort.';

  @override
  String get enable => 'Aktivieren';

  @override
  String get clearAllDownloadsWarning =>
      'Dadurch werden alle heruntergeladenen Medien gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get navigationStyle => 'Navigationsstil';

  @override
  String get topBar => 'Obere Leiste';

  @override
  String get leftSidebar => 'Linke Seitenleiste';

  @override
  String get showShuffleButton => 'Zufallswiedergabe-Schaltfläche anzeigen';

  @override
  String get showGenresButton => 'Genre-Schaltfläche anzeigen';

  @override
  String get showFavoritesButton => 'Favoriten-Schaltfläche anzeigen';

  @override
  String get showLibrariesInToolbar =>
      'Bibliotheken in der Symbolleiste anzeigen';

  @override
  String get navbarOpacity => 'Navigationsleisten-Transparenz';

  @override
  String get navbarColor => 'Navigationsleisten-Farbe';

  @override
  String get gray => 'Grau';

  @override
  String get darkBlue => 'Dunkelblau';

  @override
  String get purple => 'Lila';

  @override
  String get teal => 'Blaugrün';

  @override
  String get navy => 'Marineblau';

  @override
  String get charcoal => 'Anthrazit';

  @override
  String get brown => 'Braun';

  @override
  String get darkRed => 'Dunkelrot';

  @override
  String get darkGreen => 'Dunkelgrün';

  @override
  String get slate => 'Schiefergrau';

  @override
  String get indigo => 'Indigo';

  @override
  String get libraryDisplay => 'Bibliotheksanzeige';

  @override
  String get posterLabel => 'Poster';

  @override
  String get thumbnailLabel => 'Miniaturansicht';

  @override
  String get bannerLabel => 'Banner';

  @override
  String get overridePerLibrarySettings =>
      'Pro-Bibliothek-Einstellungen überschreiben';

  @override
  String get applyImageTypeToAllLibraries =>
      'Bildtyp auf alle Bibliotheken anwenden';

  @override
  String get multiServerLibraries => 'Multi-Server-Bibliotheken';

  @override
  String get showLibrariesFromAllServers =>
      'Bibliotheken von allen verbundenen Servern anzeigen';

  @override
  String get enableFolderView => 'Ordneransicht aktivieren';

  @override
  String get showFolderBrowsingOption => 'Ordner-Durchsuchen-Option anzeigen';

  @override
  String get libraryVisibility => 'Bibliothekssichtbarkeit';

  @override
  String get showInNavigation => 'In Navigation anzeigen';

  @override
  String get showInLatestMedia => 'In „Neueste Medien“ anzeigen';

  @override
  String get sourceLibraries => 'Quellbibliotheken';

  @override
  String get sourceCollections => 'Quellsammlungen';

  @override
  String get excludedGenres => 'Ausgeschlossene Genres';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String itemsSelected(int count) {
    return '$count ausgewählt';
  }

  @override
  String get mediaBar => 'Medienleiste';

  @override
  String get enableMediaBar => 'Medienleiste aktivieren';

  @override
  String get showFeaturedContentSlideshow =>
      'Empfohlene Inhalte als Diashow auf der Startseite anzeigen';

  @override
  String get contentType => 'Inhaltstyp';

  @override
  String get moviesAndTvShows => 'Filme & TV-Sendungen';

  @override
  String get moviesOnly => 'Nur Filme';

  @override
  String get tvShowsOnly => 'Nur TV-Sendungen';

  @override
  String get itemCount => 'Anzahl der Elemente';

  @override
  String get noneSelected => 'Keine ausgewählt';

  @override
  String get noneExcluded => 'Keine ausgeschlossen';

  @override
  String get autoAdvance => 'Automatisch weiterschalten';

  @override
  String get autoAdvanceSlides =>
      'Automatisch zur nächsten Folie weiterschalten';

  @override
  String get autoAdvanceInterval =>
      'Intervall für automatisches Weiterschalten';

  @override
  String get trailerPreview => 'Trailervorschau';

  @override
  String get autoPlayTrailers =>
      'Trailer in der Medienleiste nach 3 Sekunden automatisch abspielen';

  @override
  String get episodePreview => 'Episodenvorschau';

  @override
  String get episodePreviewDescription =>
      '30-Sekunden-Inline-Vorschau bei fokussierten, überfahrenen oder lange gedrückten Karten abspielen';

  @override
  String get previewAudio => 'Vorschau-Audio';

  @override
  String get enablePreviewAudio =>
      'Audio für Trailer- und Episodenvorschauen aktivieren';

  @override
  String get latestMedia => 'Neueste Medien';

  @override
  String get recentlyReleased => 'Kürzlich veröffentlicht';

  @override
  String get myMedia => 'Meine Medien';

  @override
  String get myMediaSmall => 'Meine Medien (Klein)';

  @override
  String get continueWatching => 'Weiterschauen';

  @override
  String get resumeAudio => 'Audio fortsetzen';

  @override
  String get resumeBooks => 'Bücher fortsetzen';

  @override
  String get activeRecordings => 'Aktive Aufnahmen';

  @override
  String get playlists => 'Wiedergabelisten';

  @override
  String get liveTV => 'Live TV';

  @override
  String get homeSections => 'Startseiten-Bereiche';

  @override
  String get resetToDefaults => 'Auf Standard zurücksetzen';

  @override
  String get homeRowPosterSize => 'Startseiten-Postergröße';

  @override
  String get perRowImageTypeSelection => 'Bildtypauswahl pro Reihe';

  @override
  String get configureImageTypeForEachRow =>
      'Bildtyp für jede aktivierte Startseitenreihe konfigurieren';

  @override
  String get mergeContinueWatchingAndNextUp =>
      'Weiterschauen und Als Nächstes zusammenführen';

  @override
  String get combineBothRows =>
      'Beide Reihen in einen Startseitenbereich zusammenführen';

  @override
  String get perRowImageType => 'Bildtyp pro Reihe';

  @override
  String get perRowSettings => 'Einstellungen pro Reihe';

  @override
  String get autoLogin => 'Automatische Anmeldung';

  @override
  String get lastUser => 'Letzter Benutzer';

  @override
  String get specificUser => 'Bestimmter Benutzer';

  @override
  String get alwaysAuthenticate => 'Immer authentifizieren';

  @override
  String get requirePasswordWithToken =>
      'Passwort auch mit gespeichertem Token anfordern';

  @override
  String get confirmExit => 'Beenden bestätigen';

  @override
  String get showConfirmationBeforeExiting =>
      'Bestätigung vor dem Beenden anzeigen';

  @override
  String get blockContentWithRatings =>
      'Inhalte mit folgenden Altersfreigaben blockieren:';

  @override
  String get noContentRatingsFound =>
      'Auf diesem Server wurden noch keine Altersfreigaben gefunden.';

  @override
  String get couldNotLoadServerRatings =>
      'Serverbewertungen konnten nicht geladen werden. Es werden nur gespeicherte Bewertungen angezeigt.';

  @override
  String get couldNotRefreshRatings =>
      'Bewertungen vom Server konnten nicht aktualisiert werden. Es werden gespeicherte Bewertungen angezeigt.';

  @override
  String get enablePinCode => 'PIN-Code aktivieren';

  @override
  String get requirePinToAccess =>
      'PIN für den Zugriff auf dein Konto erforderlich';

  @override
  String get changePin => 'PIN ändern';

  @override
  String get setNewPinCode => 'Neuen PIN-Code festlegen';

  @override
  String get removePin => 'PIN entfernen';

  @override
  String get removePinProtection => 'PIN-Code-Schutz entfernen';

  @override
  String get screensaver => 'Bildschirmschoner';

  @override
  String get inAppScreensaver => 'In-App-Bildschirmschoner';

  @override
  String get enableBuiltInScreensaver =>
      'Integrierten Bildschirmschoner aktivieren';

  @override
  String get mode => 'Modus';

  @override
  String get libraryArt => 'Bibliothekskunst';

  @override
  String get logo => 'Logo';

  @override
  String get clock => 'Uhr';

  @override
  String get timeout => 'Zeitüberschreitung';

  @override
  String minutesShort(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get dimmingLevel => 'Abdunklungsstufe';

  @override
  String get maxAgeRating => 'Maximale Altersfreigabe';

  @override
  String get any => 'Beliebig';

  @override
  String agePlusValue(int age) {
    return '$age+';
  }

  @override
  String get requireAgeRating => 'Altersfreigabe erforderlich';

  @override
  String get onlyShowRatedContent => 'Nur bewertete Inhalte anzeigen';

  @override
  String get showClock => 'Uhr anzeigen';

  @override
  String get displayClockDuringScreensaver =>
      'Uhr während des Bildschirmschoners anzeigen';

  @override
  String get rottenTomatoesCritics => 'Rotten Tomatoes (Kritiker)';

  @override
  String get rottenTomatoesAudience => 'Rotten Tomatoes (Publikum)';

  @override
  String get imdb => 'IMDb';

  @override
  String get tmdb => 'TMDB';

  @override
  String get metacritic => 'Metacritic';

  @override
  String get metacriticUser => 'Metacritic (Benutzer)';

  @override
  String get trakt => 'Trakt';

  @override
  String get letterboxd => 'Letterboxd';

  @override
  String get myAnimeList => 'MyAnimeList';

  @override
  String get aniList => 'AniList';

  @override
  String get communityRating => 'Community-Bewertung';

  @override
  String get ratings => 'Bewertungen';

  @override
  String get additionalRatings => 'Zusätzliche Bewertungen';

  @override
  String get showMdbListAndTmdbRatings =>
      'MDBList- und TMDB-Bewertungen anzeigen';

  @override
  String get ratingLabels => 'Bewertungslabels';

  @override
  String get showLabelsNextToIcons =>
      'Labels neben Bewertungssymbolen anzeigen';

  @override
  String get ratingBadges => 'Bewertungsabzeichen';

  @override
  String get showDecorativeBadges =>
      'Dekorative Abzeichen hinter Bewertungen anzeigen';

  @override
  String get episodeRatings => 'Episodenbewertungen';

  @override
  String get showRatingsOnEpisodes =>
      'Bewertungen bei einzelnen Episoden anzeigen';

  @override
  String get ratingSources => 'Bewertungsquellen';

  @override
  String get ratingSourcesDescription =>
      'Bewertungsquellen aktivieren und neu anordnen, die in der App angezeigt werden';

  @override
  String get pluginLabel => 'Plugin';

  @override
  String get pluginDetected => 'Plugin erkannt';

  @override
  String get pluginNotDetected => 'Plugin nicht erkannt';

  @override
  String get pluginDetectedDescription =>
      'Server-Plugin erkannt. Synchronisierung wird beim ersten Fund automatisch aktiviert.';

  @override
  String get pluginNotDetectedDescription =>
      'Server-Plugin nicht erkannt. Lokale Einstellungen verwenden weiterhin gespeicherte Werte oder eingebaute Standards.';

  @override
  String pluginStatusVersion(String status, String version) {
    return '$status\nVersion: $version';
  }

  @override
  String get availableServices => 'Verfügbare Dienste';

  @override
  String get serverPluginSync => 'Server-Plugin-Synchronisierung';

  @override
  String get syncSettingsWithPlugin =>
      'Einstellungen mit dem Server-Plugin synchronisieren';

  @override
  String get whatSyncControls => 'Was Synchronisierung steuert';

  @override
  String get syncControlsDescription =>
      'Synchronisierung steuert nur, ob Plugin-gestützte Einstellungen zum und vom Server übertragen werden. Profilauswahl und Profilsynchronisierungsaktionen befinden sich in den Anpassungseinstellungen, wenn Plugin-Sync aktiviert ist.';

  @override
  String get recentRequests => 'Letzte Anfragen';

  @override
  String get recentlyAdded => 'Kürzlich hinzugefügt';

  @override
  String get trending => 'Im Trend';

  @override
  String get popularMovies => 'Beliebte Filme';

  @override
  String get movieGenres => 'Film-Genres';

  @override
  String get upcomingMovies => 'Kommende Filme';

  @override
  String get studios => 'Studios';

  @override
  String get popularSeries => 'Beliebte Serien';

  @override
  String get seriesGenres => 'Serien-Genres';

  @override
  String get upcomingSeries => 'Kommende Serien';

  @override
  String get networks => 'Netzwerke';

  @override
  String get resetRowsToDefaults => 'Reihen auf Standard zurücksetzen';

  @override
  String get enableSeerr => 'Seerr aktivieren';

  @override
  String get showSeerrInNavigation =>
      'Seerr in der Navigation anzeigen (erfordert Server-Plugin)';

  @override
  String get seerrUnavailable =>
      'Nicht verfügbar, da die Seerr-Unterstützung des Server-Plugins deaktiviert ist.';

  @override
  String get nsfwFilter => 'NSFW-Filter';

  @override
  String get hideAdultContent =>
      'Inhalte für Erwachsene in Ergebnissen ausblenden';

  @override
  String loggedInAs(String username) {
    return 'Angemeldet als: $username';
  }

  @override
  String get discoverRows => 'Entdecken-Reihen';

  @override
  String get discoverRowsDescriptionPlugin =>
      'Zum Neuordnen ziehen. Reihen aktivieren oder deaktivieren. Die Reihenfolge wird mit dem Moonfin-Plugin synchronisiert.';

  @override
  String get discoverRowsDescription =>
      'Zum Neuordnen ziehen. Reihen aktivieren oder deaktivieren.';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get hidden => 'Ausgeblendet';

  @override
  String get aboutTitle => 'Über';

  @override
  String versionValue(String version) {
    return 'Version $version';
  }

  @override
  String get openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get checkForUpdatesNow => 'Jetzt nach Updates suchen';

  @override
  String get checksLatestDesktopRelease =>
      'Prüft die neueste Desktop-Version für diese Plattform';

  @override
  String get youAreUpToDate => 'Du bist auf dem neuesten Stand.';

  @override
  String get couldNotCheckForUpdates =>
      'Es konnte gerade nicht nach Updates gesucht werden.';

  @override
  String get noCompatibleUpdate =>
      'Kein kompatibles Update-Paket für diese Plattform gefunden.';

  @override
  String get updateChecksNotSupported =>
      'Update-Prüfungen werden auf dieser Plattform nicht unterstützt.';

  @override
  String get updateNotificationsDisabled =>
      'Update-Benachrichtigungen sind deaktiviert.';

  @override
  String get pleaseWaitBeforeChecking => 'Bitte warte, bevor du erneut prüfst.';

  @override
  String get latestUpdateAlreadyShown =>
      'Das neueste Update wurde bereits angezeigt.';

  @override
  String get updateAvailable => 'Update verfügbar.';

  @override
  String updateAvailableVersion(String version) {
    return 'Update verfügbar: v$version';
  }

  @override
  String get updateNotifications => 'Update-Benachrichtigungen';

  @override
  String get showWhenUpdatesAvailable =>
      'Anzeigen, wenn Updates verfügbar sind';

  @override
  String get navigation => 'Navigation';

  @override
  String get watchedIndicatorsBackdrops =>
      'Gesehen-Indikatoren, Hintergrundbilder';

  @override
  String get focusColorWatchedIndicatorsBackdrops =>
      'Fokusfarbe, Gesehen-Indikatoren, Hintergrundbilder';

  @override
  String get navbarStyleToolbarAppearance =>
      'Navigationsleiste, Symbole, Erscheinungsbild';

  @override
  String get reorderToggleHomeRows =>
      'Startseitenreihen neu anordnen und umschalten';

  @override
  String get featuredContentAppearance =>
      'Empfohlene Inhalte, Erscheinungsbild';

  @override
  String get posterSizeImageTypeFolderView =>
      'Postergröße, Bildtyp, Ordneransicht';

  @override
  String get mdbListTmdbRatingSources => 'MDBList, TMDB und Bewertungsquellen';

  @override
  String gbValue(String value) {
    return '$value GB';
  }

  @override
  String get clear => 'Leeren';

  @override
  String get browse => 'Durchsuchen';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get seerrAvailableStatus => 'Verfügbar';

  @override
  String get seerrRequestedStatus => 'Angefragt';

  @override
  String itemsCount(int count) {
    return '$count Einträge';
  }

  @override
  String get seerrSettings => 'Seerr-Einstellungen';

  @override
  String get requestMore => 'Mehr anfordern';

  @override
  String get request => 'Anfordern';

  @override
  String get cancelRequest => 'Anfrage abbrechen';

  @override
  String get playInMoonfin => 'In Moonfin abspielen';

  @override
  String requestedByName(String name) {
    return 'Angefragt von $name';
  }

  @override
  String get approve => 'Genehmigen';

  @override
  String get declineAction => 'Ablehnen';

  @override
  String get similar => 'Ähnlich';

  @override
  String get recommendations => 'Empfehlungen';

  @override
  String cancelRequestForTitle(String title) {
    return 'Anfrage für „$title“ abbrechen?';
  }

  @override
  String cancelCountRequestsForTitle(int count, String title) {
    return '$count Anfragen für „$title“ abbrechen?';
  }

  @override
  String get keep => 'Behalten';

  @override
  String get itemNotFoundInLibrary =>
      'Element nicht in deiner Moonfin-Bibliothek gefunden';

  @override
  String get errorSearchingLibrary => 'Fehler bei der Bibliothekssuche';

  @override
  String budgetAmount(String amount) {
    return 'Budget: $amount \$';
  }

  @override
  String revenueAmount(String amount) {
    return 'Einnahmen: $amount \$';
  }

  @override
  String seasonsCount(int count, String label) {
    return '$count $label';
  }

  @override
  String requestSeriesOrMovie(String type) {
    return '$type anfordern';
  }

  @override
  String get submitRequest => 'Anfrage absenden';

  @override
  String get allSeasons => 'Alle Staffeln';

  @override
  String get advancedOptions => 'Erweiterte Optionen';

  @override
  String get noServiceServersConfigured => 'Keine Dienstserver konfiguriert';

  @override
  String get server => 'Server';

  @override
  String get qualityProfile => 'Qualitätsprofil';

  @override
  String get rootFolder => 'Stammordner';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get appearances => 'Auftritte';

  @override
  String get crewSection => 'Crew';

  @override
  String ageValue(int age) {
    return 'Alter $age';
  }

  @override
  String get noRequests => 'Keine Anfragen';

  @override
  String get pendingStatus => 'Ausstehend';

  @override
  String get declinedStatus => 'Abgelehnt';

  @override
  String get partiallyAvailable => 'Teilweise verfügbar';

  @override
  String get downloadingStatus => 'Wird heruntergeladen';

  @override
  String get approvedStatus => 'Genehmigt';

  @override
  String get access => 'Zugriff';

  @override
  String get add => 'Hinzufügen';

  @override
  String get address => 'Adresse';

  @override
  String get analytics => 'Analyse';

  @override
  String get catalog => 'Katalog';

  @override
  String get content => 'Inhalt';

  @override
  String get copy => 'Kopieren';

  @override
  String get create => 'Erstellen';

  @override
  String get disable => 'Deaktivieren';

  @override
  String get done => 'Fertig';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get encoding => 'Kodierung';

  @override
  String get error => 'Fehler';

  @override
  String get forward => 'Vorwärts';

  @override
  String get general => 'Allgemein';

  @override
  String get go => 'Los';

  @override
  String get install => 'Installieren';

  @override
  String get installed => 'Installiert';

  @override
  String get interval => 'Intervall';

  @override
  String get name => 'Name';

  @override
  String get networking => 'Netzwerk';

  @override
  String get next => 'Weiter';

  @override
  String get path => 'Pfad';

  @override
  String get paused => 'Angehalten';

  @override
  String get permissions => 'Berechtigungen';

  @override
  String get processing => 'Verarbeitung';

  @override
  String get profile => 'Profil';

  @override
  String get provider => 'Anbieter';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get remote => 'Remote';

  @override
  String get rename => 'Umbenennen';

  @override
  String get revoke => 'Widerrufen';

  @override
  String get role => 'Rolle';

  @override
  String get root => 'Stammverzeichnis';

  @override
  String get run => 'Ausführen';

  @override
  String get search => 'Suche';

  @override
  String get select => 'Auswählen';

  @override
  String get send => 'Senden';

  @override
  String get sessions => 'Sitzungen';

  @override
  String get set => 'Festlegen';

  @override
  String get status => 'Status';

  @override
  String get stop => 'Stoppen';

  @override
  String get streaming => 'Streaming';

  @override
  String get time => 'Zeit';

  @override
  String get trickplay => 'Trickplay';

  @override
  String get uninstall => 'Deinstallieren';

  @override
  String get up => 'Hoch';

  @override
  String get update => 'Aktualisieren';

  @override
  String get upload => 'Hochladen';

  @override
  String get unmute => 'Stummschaltung aufheben';

  @override
  String get mute => 'Stummschalten';

  @override
  String get branding => 'Branding';

  @override
  String get adminDrawerDashboard => 'Dashboard';

  @override
  String get adminDrawerAnalytics => 'Analyse';

  @override
  String get adminDrawerSettings => 'Einstellungen';

  @override
  String get adminDrawerBranding => 'Branding';

  @override
  String get adminDrawerUsers => 'Benutzer';

  @override
  String get adminDrawerLibraries => 'Bibliotheken';

  @override
  String get adminDrawerTranscoding => 'Transkodierung';

  @override
  String get adminDrawerResume => 'Fortsetzen';

  @override
  String get adminDrawerStreaming => 'Streaming';

  @override
  String get adminDrawerTrickplay => 'Trickplay';

  @override
  String get adminDrawerDevices => 'Geräte';

  @override
  String get adminDrawerActivity => 'Aktivität';

  @override
  String get adminDrawerNetworking => 'Netzwerk';

  @override
  String get adminDrawerApiKeys => 'API-Schlüssel';

  @override
  String get adminDrawerBackups => 'Backups';

  @override
  String get adminDrawerLogs => 'Protokolle';

  @override
  String get adminDrawerScheduledTasks => 'Geplante Aufgaben';

  @override
  String get adminDrawerPlugins => 'Plugins';

  @override
  String get adminDrawerRepositories => 'Repositories';

  @override
  String get adminDrawerLiveTv => 'Live TV';

  @override
  String get adminExitTooltip => 'Admin verlassen';

  @override
  String get adminDashboardLoadFailed =>
      'Dashboard konnte nicht geladen werden';

  @override
  String get adminMediaOverview => 'Medienübersicht';

  @override
  String get adminMediaTotalsError =>
      'Server-Medienstatistiken konnten nicht geladen werden.';

  @override
  String get adminMediaOverviewSubtitle =>
      'Ein kurzer Überblick über die Inhalte auf diesem Server.';

  @override
  String adminPluginUpdatesAvailable(int count) {
    return 'Plugin-Updates verfügbar: $count';
  }

  @override
  String adminPluginsRequiringRestart(int count) {
    return 'Plugins erfordern Neustart: $count';
  }

  @override
  String adminFailedScheduledTasks(int count) {
    return 'Fehlgeschlagene geplante Aufgaben: $count';
  }

  @override
  String adminRecentAlertEntries(int count) {
    return 'Aktuelle Warn-/Fehlereinträge: $count';
  }

  @override
  String get analyticsMediaDistribution => 'Medienverteilung';

  @override
  String get analyticsVideoCodecs => 'Video-Codecs';

  @override
  String get analyticsAudioCodecs => 'Audio-Codecs';

  @override
  String get analyticsContainers => 'Container';

  @override
  String get analyticsTopGenres => 'Top-Genres';

  @override
  String get analyticsReleaseYears => 'Erscheinungsjahre';

  @override
  String get analyticsContentRatings => 'Altersfreigaben';

  @override
  String get analyticsRuntimeBuckets => 'Laufzeitgruppen';

  @override
  String get analyticsFileFormats => 'Dateiformate';

  @override
  String get analyticsNoData => 'Keine Daten verfügbar.';

  @override
  String get adminServerInfo => 'Serverinformationen';

  @override
  String get adminRestartPending => 'Neustart ausstehend';

  @override
  String get adminServerPaths => 'Serverpfade';

  @override
  String get adminServerActions => 'Serveraktionen';

  @override
  String get adminRestartServer => 'Server neu starten';

  @override
  String get adminShutdownServer => 'Server herunterfahren';

  @override
  String get adminScanLibraries => 'Bibliotheken scannen';

  @override
  String get adminLibraryScanStarted => 'Bibliotheksscan gestartet';

  @override
  String errorGeneric(String error) {
    return 'Fehler: $error';
  }

  @override
  String get adminServerRebootInProgress => 'Server-Neustart wird durchgeführt';

  @override
  String get adminServerRebootMessage =>
      'Server-Neustart wird durchgeführt, bitte starte Moonfin neu';

  @override
  String get adminActiveSessions => 'Aktive Sitzungen';

  @override
  String get adminSessionsLoadFailed =>
      'Sitzungen konnten nicht geladen werden';

  @override
  String get adminNoActiveSessions => 'Keine aktiven Sitzungen';

  @override
  String get adminRecentActivity => 'Letzte Aktivität';

  @override
  String get adminNoRecentActivity => 'Keine aktuelle Aktivität';

  @override
  String adminCommandFailed(String error) {
    return 'Befehl fehlgeschlagen: $error';
  }

  @override
  String get adminSendMessage => 'Nachricht senden';

  @override
  String get adminMessageTextHint => 'Nachrichtentext';

  @override
  String get adminSetVolume => 'Lautstärke einstellen';

  @override
  String get sessionPrev => 'Zurück';

  @override
  String get sessionRewind => 'Zurückspulen';

  @override
  String get sessionForward => 'Vorspulen';

  @override
  String get sessionNext => 'Weiter';

  @override
  String get sessionVolumeDown => 'Leiser';

  @override
  String get sessionVolumeUp => 'Lauter';

  @override
  String get nowPlaying => 'Wird wiedergegeben';

  @override
  String get volume => 'Lautstärke';

  @override
  String get actions => 'Aktionen';

  @override
  String get videoCodec => 'Video-Codec';

  @override
  String get audioCodec => 'Audio-Codec';

  @override
  String get hwAccel => 'HW-Beschleunigung';

  @override
  String get completion => 'Abschluss';

  @override
  String get direct => 'Direkt';

  @override
  String get adminDisconnect => 'Trennen';

  @override
  String get adminClearDates => 'Daten löschen';

  @override
  String adminActivityLoadFailed(String error) {
    return 'Aktivitätsprotokoll konnte nicht geladen werden: $error';
  }

  @override
  String get adminNoActivityEntries => 'Keine Aktivitätseinträge';

  @override
  String get adminEditDeviceName => 'Gerätename bearbeiten';

  @override
  String get adminCustomName => 'Benutzerdefinierter Name';

  @override
  String get adminDeviceNameUpdated => 'Gerätename aktualisiert';

  @override
  String adminDeviceUpdateFailed(String error) {
    return 'Gerät konnte nicht aktualisiert werden: $error';
  }

  @override
  String get adminDeleteDevice => 'Gerät löschen';

  @override
  String get adminDeviceDeleted => 'Gerät gelöscht';

  @override
  String adminDeviceDeleteFailed(String error) {
    return 'Gerät konnte nicht gelöscht werden: $error';
  }

  @override
  String get adminDevicesLoadFailed => 'Geräte konnten nicht geladen werden';

  @override
  String get adminSearchDevices => 'Geräte suchen';

  @override
  String get adminThisDevice => 'Dieses Gerät';

  @override
  String get adminEditName => 'Name bearbeiten';

  @override
  String get adminLibrariesLoadFailed =>
      'Bibliotheken konnten nicht geladen werden';

  @override
  String get adminNoLibraries => 'Keine Bibliotheken konfiguriert';

  @override
  String get adminScanAllLibraries => 'Alle Bibliotheken scannen';

  @override
  String get adminAddLibrary => 'Bibliothek hinzufügen';

  @override
  String adminScanFailed(String error) {
    return 'Scan konnte nicht gestartet werden: $error';
  }

  @override
  String get adminRenameLibrary => 'Bibliothek umbenennen';

  @override
  String get adminNewName => 'Neuer Name';

  @override
  String adminLibraryRenamed(String name) {
    return 'Bibliothek umbenannt in „$name“';
  }

  @override
  String adminRenameFailed(String error) {
    return 'Umbenennen fehlgeschlagen: $error';
  }

  @override
  String get adminDeleteLibrary => 'Bibliothek löschen';

  @override
  String adminLibraryDeleted(String name) {
    return 'Bibliothek „$name“ gelöscht';
  }

  @override
  String adminLibraryDeleteFailed(String error) {
    return 'Bibliothek konnte nicht gelöscht werden: $error';
  }

  @override
  String adminAddPathFailed(String error) {
    return 'Pfad konnte nicht hinzugefügt werden: $error';
  }

  @override
  String get adminRemovePath => 'Pfad entfernen';

  @override
  String adminRemovePathConfirm(String path) {
    return '„$path“ aus dieser Bibliothek entfernen?';
  }

  @override
  String adminRemovePathFailed(String error) {
    return 'Pfad konnte nicht entfernt werden: $error';
  }

  @override
  String get adminLibraryOptionsSaved => 'Bibliotheksoptionen gespeichert';

  @override
  String adminLibraryOptionsSaveFailed(String error) {
    return 'Optionen konnten nicht gespeichert werden: $error';
  }

  @override
  String get adminLibraryLoadFailed => 'Bibliothek konnte nicht geladen werden';

  @override
  String get adminNoMediaPaths => 'Keine Medienpfade konfiguriert';

  @override
  String get adminAddPath => 'Pfad hinzufügen';

  @override
  String get adminBrowseFilesystem => 'Server-Dateisystem durchsuchen:';

  @override
  String get adminSaveOptions => 'Optionen speichern';

  @override
  String get adminPreferredMetadataLanguage => 'Bevorzugte Metadatensprache';

  @override
  String get adminMetadataLanguageHint => 'z. B. en, de, fr';

  @override
  String get adminMetadataCountryCode => 'Metadaten-Ländercode';

  @override
  String get adminMetadataCountryHint => 'z. B. US, DE, FR';

  @override
  String get adminLibraryNameRequired => 'Bibliotheksname ist erforderlich';

  @override
  String adminLibraryCreateFailed(String error) {
    return 'Bibliothek konnte nicht erstellt werden: $error';
  }

  @override
  String get adminLibraryName => 'Bibliotheksname';

  @override
  String get adminSelectedPaths => 'Ausgewählte Pfade:';

  @override
  String get adminNoPathsAdded =>
      'Keine Pfade hinzugefügt (kann später ergänzt werden)';

  @override
  String get adminCreateLibrary => 'Bibliothek erstellen';

  @override
  String get paths => 'Pfade:';

  @override
  String get adminDisableUser => 'Benutzer deaktivieren';

  @override
  String get adminEnableUser => 'Benutzer aktivieren';

  @override
  String adminDisableUserConfirm(String name) {
    return '$name deaktivieren? Die Anmeldung wird nicht mehr möglich sein.';
  }

  @override
  String adminEnableUserConfirm(String name) {
    return '$name aktivieren? Die Anmeldung wird wieder möglich sein.';
  }

  @override
  String adminUserDisabled(String name) {
    return 'Benutzer „$name“ deaktiviert';
  }

  @override
  String adminUserEnabled(String name) {
    return 'Benutzer „$name“ aktiviert';
  }

  @override
  String adminUserPolicyUpdateFailed(String error) {
    return 'Benutzerrichtlinie konnte nicht aktualisiert werden: $error';
  }

  @override
  String get adminUsersLoadFailed => 'Benutzer konnten nicht geladen werden';

  @override
  String get adminSearchUsers => 'Benutzer suchen';

  @override
  String get adminEditUser => 'Benutzer bearbeiten';

  @override
  String get adminAddUser => 'Benutzer hinzufügen';

  @override
  String adminUserCreateFailed(String error) {
    return 'Benutzer konnte nicht erstellt werden: $error';
  }

  @override
  String get adminCreateUser => 'Benutzer erstellen';

  @override
  String get adminPasswordOptional => 'Passwort (optional)';

  @override
  String get adminUsernameRequired => 'Benutzername darf nicht leer sein';

  @override
  String get adminNoProfileChanges => 'Keine Profiländerungen zu speichern';

  @override
  String get adminProfileSaved => 'Profil gespeichert';

  @override
  String adminSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get adminPermissionsSaved => 'Berechtigungen gespeichert';

  @override
  String get adminPasswordsMismatch => 'Passwörter stimmen nicht überein';

  @override
  String adminFailed(String error) {
    return 'Fehlgeschlagen: $error';
  }

  @override
  String get adminUserLoadFailed => 'Benutzer konnte nicht geladen werden';

  @override
  String get adminBackToUsers => 'Zurück zu Benutzer';

  @override
  String get adminSaveProfile => 'Profil speichern';

  @override
  String get adminDeleteUser => 'Benutzer löschen';

  @override
  String get admin => 'Admin';

  @override
  String get adminFullAccessWarning =>
      'Administratoren haben vollständigen Zugriff auf den Server. Mit Vorsicht vergeben.';

  @override
  String get administrator => 'Administrator';

  @override
  String get adminHiddenUser => 'Versteckter Benutzer';

  @override
  String get adminAllowMediaPlayback => 'Medienwiedergabe erlauben';

  @override
  String get adminAllowAudioTranscoding => 'Audio-Transkodierung erlauben';

  @override
  String get adminAllowVideoTranscoding => 'Video-Transkodierung erlauben';

  @override
  String get adminAllowRemuxing => 'Remuxing erlauben';

  @override
  String get adminForceRemoteTranscoding =>
      'Remote-Quell-Transkodierung erzwingen';

  @override
  String get adminAllowContentDeletion => 'Inhaltslöschung erlauben';

  @override
  String get adminAllowContentDownloading => 'Inhaltsdownload erlauben';

  @override
  String get adminAllowPublicSharing => 'Öffentliches Teilen erlauben';

  @override
  String get adminAllowRemoteControl =>
      'Fernsteuerung anderer Benutzer erlauben';

  @override
  String get adminAllowSharedDeviceControl =>
      'Gemeinsame Gerätesteuerung erlauben';

  @override
  String get adminAllowRemoteAccess => 'Fernzugriff erlauben';

  @override
  String get adminRemoteBitrateLimit => 'Remote-Client-Bitrate-Limit (bps)';

  @override
  String get adminLeaveEmptyNoLimit => 'Leer lassen für kein Limit';

  @override
  String get adminMaxActiveSessions => 'Maximale aktive Sitzungen';

  @override
  String get adminAllowLiveTvAccess => 'Live-TV-Zugriff erlauben';

  @override
  String get adminAllowLiveTvManagement => 'Live-TV-Verwaltung erlauben';

  @override
  String get adminAllowCollectionManagement => 'Sammlungsverwaltung erlauben';

  @override
  String get adminAllowSubtitleManagement => 'Untertitelverwaltung erlauben';

  @override
  String get adminAllowLyricManagement => 'Liedtext-Verwaltung erlauben';

  @override
  String get adminSavePermissions => 'Berechtigungen speichern';

  @override
  String get adminEnableAllLibraryAccess =>
      'Zugriff auf alle Bibliotheken aktivieren';

  @override
  String get adminSaveAccess => 'Zugriff speichern';

  @override
  String get adminChangePassword => 'Passwort ändern';

  @override
  String get adminNewPassword => 'Neues Passwort';

  @override
  String get adminConfirmPassword => 'Passwort bestätigen';

  @override
  String get adminSetPassword => 'Passwort festlegen';

  @override
  String get adminResetPassword => 'Passwort zurücksetzen';

  @override
  String adminDeleteUserConfirm(String name) {
    return 'Möchtest du $name wirklich löschen?';
  }

  @override
  String adminUserDeleted(String name) {
    return 'Benutzer „$name“ gelöscht';
  }

  @override
  String adminUserDeleteFailed(String error) {
    return 'Benutzer konnte nicht gelöscht werden: $error';
  }

  @override
  String get adminCreateApiKey => 'API-Schlüssel erstellen';

  @override
  String get adminAppName => 'App-Name';

  @override
  String get adminApiKeyCreated => 'API-Schlüssel erstellt';

  @override
  String get adminApiKeyCreatedNoToken =>
      'Schlüssel erfolgreich erstellt. Der Server hat das Token nicht zurückgegeben. Prüfe die Server-API-Schlüssel.';

  @override
  String get adminKeyCopied => 'Schlüssel in Zwischenablage kopiert';

  @override
  String adminApiKeyCreateFailed(String error) {
    return 'Schlüssel konnte nicht erstellt werden: $error';
  }

  @override
  String get adminKeyTokenMissing =>
      'Schlüssel-Token fehlt in der Serverantwort';

  @override
  String get adminRevokeApiKey => 'API-Schlüssel widerrufen';

  @override
  String adminRevokeKeyConfirm(String name) {
    return 'Schlüssel für $name widerrufen?';
  }

  @override
  String get adminApiKeyRevoked => 'API-Schlüssel widerrufen';

  @override
  String adminApiKeyRevokeFailed(String error) {
    return 'Schlüssel konnte nicht widerrufen werden: $error';
  }

  @override
  String get adminApiKeysLoadFailed =>
      'API-Schlüssel konnten nicht geladen werden';

  @override
  String get adminCreateKey => 'Schlüssel erstellen';

  @override
  String get adminNoApiKeys => 'Keine API-Schlüssel gefunden';

  @override
  String get adminCreatingBackup => 'Backup wird erstellt...';

  @override
  String get adminBackupCreated => 'Backup erfolgreich erstellt';

  @override
  String adminBackupCreateFailed(String error) {
    return 'Backup konnte nicht erstellt werden: $error';
  }

  @override
  String get adminBackupPathMissing => 'Backup-Pfad fehlt in der Serverantwort';

  @override
  String adminBackupManifest(String name) {
    return 'Manifest: $name';
  }

  @override
  String adminManifestLoadFailed(String error) {
    return 'Manifest konnte nicht geladen werden: $error';
  }

  @override
  String get adminConfirmRestore => 'Wiederherstellung bestätigen';

  @override
  String get adminRestoringBackup => 'Backup wird wiederhergestellt...';

  @override
  String adminRestoreFailed(String error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String get adminBackupsLoadFailed => 'Backups konnten nicht geladen werden';

  @override
  String get adminCreateBackup => 'Backup erstellen';

  @override
  String get adminNoBackups => 'Keine Backups gefunden';

  @override
  String get adminViewDetails => 'Details anzeigen';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get adminLogsLoadFailed =>
      'Serverprotokolle konnten nicht geladen werden';

  @override
  String get adminNoLogFiles => 'Keine Protokolldateien gefunden';

  @override
  String get adminLogCopied => 'Protokoll in Zwischenablage kopiert';

  @override
  String get adminSaveLogFile => 'Protokolldatei speichern';

  @override
  String adminSavedTo(String path) {
    return 'Gespeichert in $path';
  }

  @override
  String adminFileSaveFailed(String error) {
    return 'Datei konnte nicht gespeichert werden: $error';
  }

  @override
  String adminLogFileLoadFailed(String fileName) {
    return '$fileName konnte nicht geladen werden';
  }

  @override
  String get adminSearchInLog => 'Im Protokoll suchen';

  @override
  String get adminNoMatchingLines => 'Keine übereinstimmenden Zeilen';

  @override
  String adminTasksLoadFailed(String error) {
    return 'Aufgaben konnten nicht geladen werden: $error';
  }

  @override
  String get adminNoScheduledTasks => 'Keine geplanten Aufgaben gefunden';

  @override
  String get adminNoTasksMatchFilter =>
      'Keine Aufgaben stimmen mit dem aktuellen Filter überein';

  @override
  String adminTaskStartFailed(String error) {
    return 'Aufgabe konnte nicht gestartet werden: $error';
  }

  @override
  String adminTaskStopFailed(String error) {
    return 'Aufgabe konnte nicht gestoppt werden: $error';
  }

  @override
  String adminTaskLoadFailed(String error) {
    return 'Aufgabe konnte nicht geladen werden: $error';
  }

  @override
  String get adminRunNow => 'Jetzt ausführen';

  @override
  String adminTriggerRemoveFailed(String error) {
    return 'Auslöser konnte nicht entfernt werden: $error';
  }

  @override
  String adminTriggerAddFailed(String error) {
    return 'Auslöser konnte nicht hinzugefügt werden: $error';
  }

  @override
  String get adminLastExecution => 'Letzte Ausführung';

  @override
  String get adminTriggers => 'Auslöser';

  @override
  String get adminAddTrigger => 'Auslöser hinzufügen';

  @override
  String get adminNoTriggers => 'Keine Auslöser konfiguriert';

  @override
  String get adminTriggerType => 'Auslösertyp';

  @override
  String get adminTimeLimit => 'Zeitlimit (optional)';

  @override
  String get adminNoLimit => 'Kein Limit';

  @override
  String adminHours(String hours) {
    return '$hours Stunde(n)';
  }

  @override
  String get adminDayOfWeek => 'Wochentag';

  @override
  String get adminSearchPlugins => 'Plugins suchen...';

  @override
  String adminPluginToggleFailed(String error) {
    return 'Plugin konnte nicht umgeschaltet werden: $error';
  }

  @override
  String get adminUninstallPlugin => 'Plugin deinstallieren';

  @override
  String adminUninstallPluginConfirm(String name) {
    return 'Möchtest du „$name“ wirklich deinstallieren?';
  }

  @override
  String adminPluginUninstallFailed(String error) {
    return 'Plugin konnte nicht deinstalliert werden: $error';
  }

  @override
  String adminPackageInstallFailed(String error) {
    return 'Paket konnte nicht installiert werden: $error';
  }

  @override
  String adminPluginUpdateFailed(String error) {
    return 'Update konnte nicht installiert werden: $error';
  }

  @override
  String adminPluginsLoadFailed(String error) {
    return 'Plugins konnten nicht geladen werden: $error';
  }

  @override
  String get adminNoPluginsMatchSearch =>
      'Keine Plugins stimmen mit deiner Suche überein';

  @override
  String get adminNoPluginsInstalled => 'Keine Plugins installiert';

  @override
  String adminInstallUpdate(String version) {
    return 'Update installieren (v$version)';
  }

  @override
  String adminCatalogLoadFailed(String error) {
    return 'Katalog konnte nicht geladen werden: $error';
  }

  @override
  String get adminNoPackagesMatchSearch =>
      'Keine Pakete stimmen mit deiner Suche überein';

  @override
  String get adminNoPackagesAvailable => 'Keine Pakete verfügbar';

  @override
  String get adminExperimentalIntegration => 'Experimentelle Integration';

  @override
  String get adminExperimentalWarning =>
      'Plugin-Einstellungsintegration ist noch experimentell. Einige Einstellungsseiten werden möglicherweise nicht korrekt dargestellt.';

  @override
  String get continueAction => 'Fortfahren';

  @override
  String adminPluginRemoveAfterRestart(String name) {
    return '„$name“ wird nach dem Serverneustart entfernt';
  }

  @override
  String adminUninstallFailed(String error) {
    return 'Deinstallation fehlgeschlagen: $error';
  }

  @override
  String adminPluginUpdating(String name, String version) {
    return '„$name“ wird auf v$version aktualisiert...';
  }

  @override
  String get adminMissingAuthToken =>
      'Einstellungen können nicht geöffnet werden: Auth-Token fehlt.';

  @override
  String adminPluginLoadFailed(String error) {
    return 'Plugin konnte nicht geladen werden: $error';
  }

  @override
  String get adminPluginNotFound => 'Plugin nicht gefunden';

  @override
  String adminPluginVersion(String version) {
    return 'Version $version';
  }

  @override
  String get adminEnablePlugin => 'Plugin aktivieren';

  @override
  String get adminPluginSettingsPage => 'Plugin-Einstellungsseite';

  @override
  String get adminRevisionHistory => 'Änderungshistorie';

  @override
  String get adminNoChangelog => 'Kein Änderungsprotokoll verfügbar.';

  @override
  String get adminRemoveRepository => 'Repository entfernen';

  @override
  String adminRemoveRepositoryConfirm(String name) {
    return 'Möchtest du „$name“ wirklich entfernen?';
  }

  @override
  String adminRepositoriesSaveFailed(String error) {
    return 'Repositories konnten nicht gespeichert werden: $error';
  }

  @override
  String adminRepositoriesLoadFailed(String error) {
    return 'Repositories konnten nicht geladen werden: $error';
  }

  @override
  String get adminRepositoryNameHint => 'z. B. Jellyfin Stable';

  @override
  String get adminRepositoryUrl => 'Repository-URL';

  @override
  String get adminAddEntry => 'Eintrag hinzufügen';

  @override
  String get adminInvalidUrl => 'Ungültige URL';

  @override
  String adminPluginSettingsLoadFailed(String error) {
    return 'Plugin-Einstellungen konnten nicht geladen werden: $error';
  }

  @override
  String adminCouldNotOpenUrl(String uri) {
    return '$uri konnte nicht geöffnet werden';
  }

  @override
  String get adminOpenInBrowser => 'Im Browser öffnen';

  @override
  String get adminOpenExternally => 'Extern öffnen';

  @override
  String get adminGeneralSettings => 'Allgemeine Einstellungen';

  @override
  String get adminServerName => 'Servername';

  @override
  String get adminPreferredMetadataCountry => 'Bevorzugtes Metadatenland';

  @override
  String get adminCachePath => 'Cache-Pfad';

  @override
  String get adminMetadataPath => 'Metadatenpfad';

  @override
  String get adminLibraryScanConcurrency => 'Bibliotheksscan-Parallelität';

  @override
  String get adminParallelImageEncodingLimit =>
      'Paralleles Bildkodierungslimit';

  @override
  String get adminSlowResponseThreshold =>
      'Schwellenwert für langsame Antwort (ms)';

  @override
  String get adminBrandingSaved => 'Branding-Einstellungen gespeichert';

  @override
  String get adminBrandingLoadFailed =>
      'Branding-Einstellungen konnten nicht geladen werden';

  @override
  String get adminLoginDisclaimer => 'Anmelde-Haftungsausschluss';

  @override
  String get adminLoginDisclaimerHint =>
      'HTML, das unter dem Anmeldeformular angezeigt wird';

  @override
  String get adminCustomCss => 'Benutzerdefiniertes CSS';

  @override
  String get adminCustomCssHint =>
      'Benutzerdefiniertes CSS für das Web-Interface';

  @override
  String get adminEnableSplashScreen => 'Startbildschirm aktivieren';

  @override
  String get adminStreamingSaved => 'Streaming-Einstellungen gespeichert';

  @override
  String get adminStreamingLoadFailed =>
      'Streaming-Einstellungen konnten nicht geladen werden';

  @override
  String get adminStreamingDescription =>
      'Globale Streaming-Bitrate-Limits für Remote-Verbindungen festlegen.';

  @override
  String get adminRemoteBitrateLimitMbps =>
      'Remote-Client-Bitrate-Limit (Mbps)';

  @override
  String get adminLeaveEmptyForUnlimited => 'Leer lassen oder 0 für unbegrenzt';

  @override
  String get adminPlaybackSaved => 'Wiedergabe-Einstellungen gespeichert';

  @override
  String get adminPlaybackLoadFailed =>
      'Wiedergabe-Einstellungen konnten nicht geladen werden';

  @override
  String get adminPlaybackTranscoding => 'Wiedergabe / Transkodierung';

  @override
  String get adminHardwareAcceleration => 'Hardwarebeschleunigung';

  @override
  String get adminVaapiDevice => 'VA-API-Gerät';

  @override
  String get adminEnableHardwareEncoding => 'Hardwarekodierung aktivieren';

  @override
  String get adminEnableHardwareDecoding =>
      'Hardwaredekodierung aktivieren für:';

  @override
  String get adminEncodingThreads => 'Kodierungsthreads';

  @override
  String get adminAutomatic => '0 = automatisch';

  @override
  String get adminTranscodingTempPath => 'Transkodierungs-Temporärpfad';

  @override
  String get adminEnableFallbackFont => 'Ersatzschriftart aktivieren';

  @override
  String get adminFallbackFontPath => 'Ersatzschriftart-Pfad';

  @override
  String get adminAllowSegmentDeletion => 'Segmentlöschung erlauben';

  @override
  String get adminSegmentKeepSeconds => 'Segmente behalten (Sekunden)';

  @override
  String get adminThrottleBuffering => 'Pufferung drosseln';

  @override
  String get adminTrickplaySaved => 'Trickplay-Einstellungen gespeichert';

  @override
  String get adminTrickplayLoadFailed =>
      'Trickplay-Einstellungen konnten nicht geladen werden';

  @override
  String get adminEnableHardwareAcceleration =>
      'Hardwarebeschleunigung aktivieren';

  @override
  String get adminEnableKeyFrameExtraction =>
      'Nur Schlüsselbild-Extraktion aktivieren';

  @override
  String get adminKeyFrameSubtitle => 'Schneller, aber geringere Genauigkeit';

  @override
  String get adminScanBehavior => 'Scanverhalten';

  @override
  String get adminProcessPriority => 'Prozesspriorität';

  @override
  String get adminImageSettings => 'Bildeinstellungen';

  @override
  String get adminIntervalMs => 'Intervall (ms)';

  @override
  String get adminCaptureFrameSubtitle => 'Wie oft Frames aufgenommen werden';

  @override
  String get adminWidthResolutions => 'Breitenauflösungen';

  @override
  String get adminTileWidth => 'Kachelbreite';

  @override
  String get adminTileHeight => 'Kachelhöhe';

  @override
  String get adminQualitySubtitle =>
      'Niedrigere Werte = bessere Qualität, größere Dateien';

  @override
  String get adminProcessThreads => 'Verarbeitungsthreads';

  @override
  String get adminResumeSaved => 'Fortsetzen-Einstellungen gespeichert';

  @override
  String get adminResumeLoadFailed =>
      'Fortsetzen-Einstellungen konnten nicht geladen werden';

  @override
  String get adminResumeDescription =>
      'Konfiguriere, wann Inhalte als teilweise oder vollständig wiedergegeben markiert werden.';

  @override
  String get adminMinResumePercentage => 'Mindest-Fortsetzungsprozentsatz';

  @override
  String get adminMinResumeSubtitle =>
      'Inhalte müssen über diesen Prozentsatz hinaus abgespielt werden, um den Fortschritt zu speichern';

  @override
  String get adminMaxResumePercentage => 'Maximaler Fortsetzungsprozentsatz';

  @override
  String get adminMaxResumeSubtitle =>
      'Inhalte gelten nach diesem Prozentsatz als vollständig wiedergegeben';

  @override
  String get adminMinResumeDuration => 'Mindest-Fortsetzungsdauer (Sekunden)';

  @override
  String get adminMinResumeDurationSubtitle =>
      'Kürzere Elemente sind nicht fortsetzbar';

  @override
  String get adminMinAudiobookResume =>
      'Mindest-Hörbuch-Fortsetzungsprozentsatz';

  @override
  String get adminMaxAudiobookResume =>
      'Maximaler Hörbuch-Fortsetzungsprozentsatz';

  @override
  String get adminNetworkingSaved =>
      'Netzwerkeinstellungen gespeichert. Ein Serverneustart kann erforderlich sein.';

  @override
  String get adminNetworkingLoadFailed =>
      'Netzwerkeinstellungen konnten nicht geladen werden';

  @override
  String get adminNetworkingWarning =>
      'Änderungen an den Netzwerkeinstellungen können einen Serverneustart erfordern.';

  @override
  String get adminEnableRemoteAccess => 'Fernzugriff aktivieren';

  @override
  String get ports => 'Ports';

  @override
  String get adminHttpPort => 'HTTP-Port';

  @override
  String get adminHttpsPort => 'HTTPS-Port';

  @override
  String get adminPublicHttpsPort => 'Öffentlicher HTTPS-Port';

  @override
  String get adminBaseUrl => 'Basis-URL';

  @override
  String get adminBaseUrlHint => 'z. B. /jellyfin';

  @override
  String get https => 'HTTPS';

  @override
  String get adminEnableHttps => 'HTTPS aktivieren';

  @override
  String get adminLocalNetwork => 'Lokales Netzwerk';

  @override
  String get adminLocalNetworkAddresses => 'Lokale Netzwerkadressen';

  @override
  String get adminKnownProxies => 'Bekannte Proxys';

  @override
  String get adminRemoteIpFilter => 'Remote-IP-Filter';

  @override
  String get adminRemoteIpFilterEntries => 'Remote-IP-Filter';

  @override
  String get adminCertificatePath => 'Zertifikatspfad';

  @override
  String get whitelist => 'Whitelist';

  @override
  String get blacklist => 'Blacklist';

  @override
  String get notSet => 'Nicht gesetzt';

  @override
  String get adminMetadataSaved => 'Metadaten gespeichert';

  @override
  String adminMetadataLoadFailed(String error) {
    return 'Metadaten konnten nicht geladen werden: $error';
  }

  @override
  String adminMetadataSaveFailed(String error) {
    return 'Metadaten konnten nicht gespeichert werden: $error';
  }

  @override
  String get adminRefreshMetadata => 'Metadaten aktualisieren';

  @override
  String get recursive => 'Rekursiv';

  @override
  String get adminReplaceAllMetadata => 'Alle Metadaten ersetzen';

  @override
  String get adminReplaceAllImages => 'Alle Bilder ersetzen';

  @override
  String get adminMetadataRefreshRequested =>
      'Metadatenaktualisierung angefordert';

  @override
  String adminMetadataRefreshFailed(String error) {
    return 'Metadatenaktualisierung fehlgeschlagen: $error';
  }

  @override
  String get adminSearchRemotePerson => 'Remote-Person suchen';

  @override
  String get adminNoRemoteMatches => 'Keine Remote-Treffer gefunden';

  @override
  String get adminRemoteResults => 'Remote-Ergebnisse';

  @override
  String get adminRemoteMetadataApplied => 'Remote-Metadaten angewendet';

  @override
  String adminRemoteSearchFailed(String error) {
    return 'Remote-Suche fehlgeschlagen: $error';
  }

  @override
  String get adminUpdateContentType => 'Inhaltstyp aktualisieren';

  @override
  String get adminContentType => 'Inhaltstyp';

  @override
  String get adminContentTypeUpdated => 'Inhaltstyp aktualisiert';

  @override
  String adminContentTypeUpdateFailed(String error) {
    return 'Inhaltstyp konnte nicht aktualisiert werden: $error';
  }

  @override
  String get adminMetadataEditorLoadFailed =>
      'Metadaten-Editor konnte nicht geladen werden';

  @override
  String get adminNoPeopleEntries => 'Keine Personeneinträge';

  @override
  String get adminNoExternalIds => 'Keine externen IDs verfügbar';

  @override
  String adminImageUpdated(String imageType) {
    return '$imageType-Bild aktualisiert';
  }

  @override
  String adminImageDownloadFailed(String error) {
    return 'Bild konnte nicht heruntergeladen werden: $error';
  }

  @override
  String get adminUnsupportedImageFormat => 'Nicht unterstütztes Bildformat';

  @override
  String get adminImageReadFailed =>
      'Ausgewähltes Bild konnte nicht gelesen werden';

  @override
  String adminImageUploaded(String imageType) {
    return '$imageType-Bild hochgeladen';
  }

  @override
  String adminImageUploadFailed(String error) {
    return 'Bild konnte nicht hochgeladen werden: $error';
  }

  @override
  String adminDeleteImage(String imageType) {
    return '$imageType-Bild löschen';
  }

  @override
  String adminImageDeleted(String imageType) {
    return '$imageType-Bild gelöscht';
  }

  @override
  String adminImageDeleteFailed(String error) {
    return 'Bild konnte nicht gelöscht werden: $error';
  }

  @override
  String get adminAllProviders => 'Alle Anbieter';

  @override
  String get adminNoRemoteImages => 'Keine Remote-Bilder gefunden';

  @override
  String adminTunerDiscoveryFailed(String error) {
    return 'Tuner-Erkennung fehlgeschlagen: $error';
  }

  @override
  String get adminAddTuner => 'Tuner hinzufügen';

  @override
  String get adminTunerType => 'Tuner-Typ';

  @override
  String get adminTunerTypeHint => 'HDHomeRun, M3U, Andere';

  @override
  String get adminUrlPath => 'URL / Pfad';

  @override
  String get adminNameOptional => 'Name (optional)';

  @override
  String get adminTunerAdded => 'Tuner hinzugefügt';

  @override
  String adminTunerAddFailed(String error) {
    return 'Tuner konnte nicht hinzugefügt werden: $error';
  }

  @override
  String get adminAddGuideProvider => 'Programmführer-Anbieter hinzufügen';

  @override
  String get adminProviderType => 'Anbietertyp';

  @override
  String get adminProviderTypeHint => 'SchedulesDirect oder XMLTV';

  @override
  String get adminUsernameOptional => 'Benutzername (optional)';

  @override
  String get adminRefreshInterval => 'Aktualisierungsintervall (Stunden)';

  @override
  String get adminProviderAdded => 'Anbieter hinzugefügt';

  @override
  String adminProviderAddFailed(String error) {
    return 'Anbieter konnte nicht hinzugefügt werden: $error';
  }

  @override
  String adminTunerRemoveFailed(String error) {
    return 'Tuner konnte nicht entfernt werden: $error';
  }

  @override
  String get adminTunerResetRequested => 'Tuner-Zurücksetzung angefordert';

  @override
  String adminTunerResetFailed(String error) {
    return 'Tuner konnte nicht zurückgesetzt werden: $error';
  }

  @override
  String adminProviderRemoveFailed(String error) {
    return 'Anbieter konnte nicht entfernt werden: $error';
  }

  @override
  String get adminRecordingSettings => 'Aufnahme-Einstellungen';

  @override
  String get adminPrePadding => 'Vorlaufzeit (Minuten)';

  @override
  String get adminPostPadding => 'Nachlaufzeit (Minuten)';

  @override
  String get adminRecordingPath => 'Aufnahmepfad';

  @override
  String get adminSeriesRecordingPath => 'Serienaufnahmepfad';

  @override
  String get adminRecordingSettingsSaved =>
      'Aufnahme-Einstellungen gespeichert';

  @override
  String adminSettingsSaveFailed(String error) {
    return 'Einstellungen konnten nicht gespeichert werden: $error';
  }

  @override
  String get adminSetChannelMappings => 'Kanalzuordnungen festlegen';

  @override
  String get adminMappingJson => 'Zuordnungs-JSON';

  @override
  String get adminChannelMappingsUpdated => 'Kanalzuordnungen aktualisiert';

  @override
  String adminMappingsUpdateFailed(String error) {
    return 'Zuordnungen konnten nicht aktualisiert werden: $error';
  }

  @override
  String get adminLiveTvLoadFailed =>
      'Live-TV-Administration konnte nicht geladen werden';

  @override
  String get adminTunerDevices => 'Tuner-Geräte';

  @override
  String get adminNoTunerHosts => 'Keine Tuner-Hosts konfiguriert';

  @override
  String get adminGuideProviders => 'Programmführer-Anbieter';

  @override
  String get adminAddProvider => 'Anbieter hinzufügen';

  @override
  String get adminNoListingProviders => 'Keine Listing-Anbieter konfiguriert';

  @override
  String adminRecordingPathDisplay(String path) {
    return 'Aufnahmepfad: $path';
  }

  @override
  String adminSeriesPathDisplay(String path) {
    return 'Serienpfad: $path';
  }

  @override
  String adminPrePaddingDisplay(int minutes) {
    return 'Vorlaufzeit: $minutes Min.';
  }

  @override
  String adminPostPaddingDisplay(int minutes) {
    return 'Nachlaufzeit: $minutes Min.';
  }

  @override
  String get adminTunerDiscovery => 'Tuner-Erkennung';

  @override
  String get adminChannelMappings => 'Kanalzuordnungen';

  @override
  String get adminNoDiscoveredTuners => 'Noch keine erkannten Tuner';

  @override
  String get adminSettingsSaved => 'Einstellungen gespeichert';

  @override
  String get adminBackupsNotAvailable =>
      'Backups sind auf diesem Server-Build nicht verfügbar.';

  @override
  String get adminRestoreWarning1 =>
      'Die Wiederherstellung ersetzt ALLE aktuellen Serverdaten durch die Backup-Daten.';

  @override
  String get adminRestoreWarning2 =>
      'Aktuelle Servereinstellungen, Benutzer und Bibliotheksdaten werden überschrieben.';

  @override
  String get adminRestoreWarning3 =>
      'Der Server wird nach der Wiederherstellung neu gestartet.';

  @override
  String adminRestoreConfirmMessage(String name) {
    return 'Backup $name jetzt wiederherstellen?';
  }

  @override
  String get adminRestoreRequested =>
      'Wiederherstellung angefordert. Ein Serverneustart kann diese Sitzung trennen.';

  @override
  String get adminBackupsTitle => 'Backups';

  @override
  String get adminUnknownDate => 'Unbekanntes Datum';

  @override
  String get adminUnnamedBackup => 'Unbenanntes Backup';

  @override
  String get adminLiveTvNotAvailable =>
      'Live-TV-Administration ist auf diesem Server-Build nicht verfügbar.';

  @override
  String get adminLiveTvTitle => 'Live-TV-Administration';

  @override
  String get adminApply => 'Anwenden';

  @override
  String get adminNotSet => 'Nicht gesetzt';

  @override
  String get adminReset => 'Zurücksetzen';

  @override
  String get adminLogsTitle => 'Serverprotokolle';

  @override
  String get adminLogsNewestFirst => 'Neueste zuerst';

  @override
  String get adminLogsOldestFirst => 'Älteste zuerst';

  @override
  String get adminLogsJustNow => 'Gerade eben';

  @override
  String adminLogsMinutesAgo(int minutes) {
    return 'vor $minutes Min.';
  }

  @override
  String adminLogsHoursAgo(int hours) {
    return 'vor $hours Std.';
  }

  @override
  String adminLogsDaysAgo(int days) {
    return 'vor $days T.';
  }

  @override
  String adminLogViewerLoadFailed(String fileName) {
    return '$fileName konnte nicht geladen werden';
  }

  @override
  String adminLogViewerMatches(int count) {
    return '$count Treffer';
  }

  @override
  String get adminLogViewerNoMatches => 'Keine übereinstimmenden Zeilen';

  @override
  String get adminMetadataEditorTitle => 'Metadaten-Editor';

  @override
  String get adminMetadataRemote => 'Remote';

  @override
  String get adminMetadataType => 'Typ';

  @override
  String get adminMetadataDetails => 'Details';

  @override
  String get adminMetadataExternalIds => 'Externe IDs';

  @override
  String get adminMetadataImages => 'Bilder';

  @override
  String get adminMetadataFieldTitle => 'Titel';

  @override
  String get adminMetadataFieldSortTitle => 'Sortiertitel';

  @override
  String get adminMetadataFieldOriginalTitle => 'Originaltitel';

  @override
  String get adminMetadataFieldPremiereDate => 'Premierendatum (JJJJ-MM-TT)';

  @override
  String get adminMetadataFieldEndDate => 'Enddatum (JJJJ-MM-TT)';

  @override
  String get adminMetadataFieldProductionYear => 'Produktionsjahr';

  @override
  String get adminMetadataFieldOfficialRating => 'Offizielle Bewertung';

  @override
  String get adminMetadataFieldCommunityRating => 'Community-Bewertung';

  @override
  String get adminMetadataFieldCriticRating => 'Kritikerbewertung';

  @override
  String get adminMetadataFieldTagline => 'Schlagzeile';

  @override
  String get adminMetadataFieldOverview => 'Übersicht';

  @override
  String get adminMetadataGenres => 'Genres';

  @override
  String get adminMetadataTags => 'Tags';

  @override
  String get adminMetadataStudios => 'Studios';

  @override
  String get adminMetadataPeople => 'Personen';

  @override
  String get adminMetadataAddGenre => 'Genre hinzufügen';

  @override
  String get adminMetadataAddTag => 'Tag hinzufügen';

  @override
  String get adminMetadataAddStudio => 'Studio hinzufügen';

  @override
  String get adminMetadataAddPerson => 'Person hinzufügen';

  @override
  String get adminMetadataEditPerson => 'Person bearbeiten';

  @override
  String get adminMetadataRole => 'Rolle';

  @override
  String get adminMetadataImagePrimary => 'Primär';

  @override
  String get adminMetadataImageBackdrop => 'Hintergrund';

  @override
  String get adminMetadataImageLogo => 'Logo';

  @override
  String get adminMetadataImageBanner => 'Banner';

  @override
  String get adminMetadataImageThumb => 'Miniaturansicht';

  @override
  String get adminMetadataRecursive => 'Rekursiv';

  @override
  String get adminMetadataProvider => 'Anbieter';

  @override
  String adminMetadataImageUpdated(String imageType) {
    return '$imageType-Bild aktualisiert';
  }

  @override
  String adminMetadataImageUploaded(String imageType) {
    return '$imageType-Bild hochgeladen';
  }

  @override
  String adminMetadataImageDeleted(String imageType) {
    return '$imageType-Bild gelöscht';
  }

  @override
  String adminMetadataImageDownloadFailed(String error) {
    return 'Bild konnte nicht heruntergeladen werden: $error';
  }

  @override
  String get adminMetadataImageReadFailed =>
      'Ausgewähltes Bild konnte nicht gelesen werden';

  @override
  String adminMetadataImageUploadFailed(String error) {
    return 'Bild konnte nicht hochgeladen werden: $error';
  }

  @override
  String adminMetadataDeleteImageTitle(String imageType) {
    return '$imageType-Bild löschen';
  }

  @override
  String get adminMetadataDeleteImageContent =>
      'Dadurch wird das aktuelle Bild vom Element entfernt.';

  @override
  String adminMetadataImageDeleteFailed(String error) {
    return 'Bild konnte nicht gelöscht werden: $error';
  }

  @override
  String adminMetadataChooseImage(String imageType) {
    return '$imageType-Bild auswählen';
  }

  @override
  String get adminMetadataUpload => 'Hochladen';

  @override
  String get adminMetadataUpdate => 'Aktualisieren';

  @override
  String get adminMetadataRemoteImage => 'Remote-Bild';

  @override
  String get adminPluginsInstalled => 'Installiert';

  @override
  String get adminPluginsCatalog => 'Katalog';

  @override
  String get adminPluginsActive => 'Aktiv';

  @override
  String get adminPluginsRestart => 'Neustart';

  @override
  String get adminPluginsNoSearchResults =>
      'Keine Plugins stimmen mit deiner Suche überein';

  @override
  String get adminPluginsNoneInstalled => 'Keine Plugins installiert';

  @override
  String adminPluginsUpdateAvailable(String version) {
    return 'Update verfügbar: v$version';
  }

  @override
  String get adminPluginsUpdateAvailableGeneric => 'Update verfügbar';

  @override
  String get adminPluginsPendingRemoval =>
      'Entfernung nach Neustart ausstehend';

  @override
  String get adminPluginsChangesPending => 'Änderungen erfordern Neustart';

  @override
  String get adminPluginsEnable => 'Aktivieren';

  @override
  String get adminPluginsDisable => 'Deaktivieren';

  @override
  String get adminPluginsInstallUpdate => 'Update installieren';

  @override
  String adminPluginsInstallUpdateVersioned(String version) {
    return 'Update installieren (v$version)';
  }

  @override
  String get adminPluginsCatalogNoSearchResults =>
      'Keine Pakete stimmen mit deiner Suche überein';

  @override
  String get adminPluginsCatalogEmpty => 'Keine Pakete verfügbar';

  @override
  String adminPluginsInstalling(String name) {
    return '„$name“ wird installiert...';
  }

  @override
  String get adminPluginDetailExperimental => 'Experimentelle Integration';

  @override
  String get adminPluginDetailExperimentalContent =>
      'Plugin-Einstellungsintegration ist noch experimentell. Einige Felder oder Layouts werden möglicherweise noch nicht korrekt dargestellt.';

  @override
  String get adminPluginDetailToggle404 =>
      'Plugin konnte nicht umgeschaltet werden. Der Server konnte diese Plugin-Version nicht finden. Versuche die Plugins zu aktualisieren und dann erneut.';

  @override
  String get adminPluginDetailToggleDioError =>
      'Plugin konnte nicht umgeschaltet werden. Bitte prüfe die Serverprotokolle für Details.';

  @override
  String adminPluginDetailSettingsTitle(String name) {
    return '$name-Einstellungen';
  }

  @override
  String get adminPluginDetailDetails => 'Details';

  @override
  String get adminPluginDetailDeveloper => 'Entwickler';

  @override
  String get adminPluginDetailRepository => 'Repository';

  @override
  String get adminPluginDetailBundled => 'Mitgeliefert';

  @override
  String get adminPluginDetailEnablePlugin => 'Plugin aktivieren';

  @override
  String get adminPluginDetailRestartRequired =>
      'Ein Serverneustart ist erforderlich, damit die Änderungen wirksam werden.';

  @override
  String get adminPluginDetailRemovalPending =>
      'Dieses Plugin wird nach dem Serverneustart entfernt.';

  @override
  String get adminPluginDetailMalfunctioned =>
      'Dieses Plugin hat eine Fehlfunktion und funktioniert möglicherweise nicht korrekt.';

  @override
  String get adminPluginDetailNotSupported =>
      'Dieses Plugin wird von der aktuellen Serverversion nicht unterstützt.';

  @override
  String get adminPluginDetailSuperseded =>
      'Dieses Plugin wurde durch eine neuere Version ersetzt.';

  @override
  String adminReposLoadFailed(String error) {
    return 'Repositories konnten nicht geladen werden: $error';
  }

  @override
  String get adminReposRemoveTitle => 'Repository entfernen';

  @override
  String adminReposRemoveConfirm(String name) {
    return 'Möchtest du „$name“ wirklich entfernen?';
  }

  @override
  String get adminReposRemove => 'Entfernen';

  @override
  String adminReposSaveFailed(String error) {
    return 'Repositories konnten nicht gespeichert werden: $error';
  }

  @override
  String get adminReposEmpty => 'Keine Repositories konfiguriert';

  @override
  String get adminReposEmptySubtitle =>
      'Füge ein Repository hinzu, um verfügbare Plugins zu durchsuchen';

  @override
  String get adminReposUnnamed => '(unbenannt)';

  @override
  String get adminReposEditTitle => 'Repository bearbeiten';

  @override
  String get adminReposAddTitle => 'Repository hinzufügen';

  @override
  String get adminReposUrl => 'Repository-URL';

  @override
  String get adminReposNameHint => 'z. B. Jellyfin Stable';

  @override
  String get adminPluginSettingsInvalidUrl => 'Ungültige URL';

  @override
  String get adminGeneralSettingsTitle => 'Allgemeine Einstellungen';

  @override
  String get adminGeneralMetadataLanguage => 'Bevorzugte Metadatensprache';

  @override
  String get adminGeneralMetadataLanguageHint => 'z. B. en, de, fr';

  @override
  String get adminGeneralMetadataCountry => 'Bevorzugtes Metadatenland';

  @override
  String get adminGeneralMetadataCountryHint => 'z. B. US, DE, FR';

  @override
  String get adminGeneralLibraryScanConcurrency =>
      'Bibliotheksscan-Parallelität';

  @override
  String get adminGeneralImageEncodingLimit => 'Paralleles Bildkodierungslimit';

  @override
  String get adminUnknownError => 'Unbekannter Fehler';

  @override
  String get adminBrowse => 'Durchsuchen';

  @override
  String get adminCloseBrowser => 'Browser schließen';

  @override
  String get adminNetworkingTitle => 'Netzwerk';

  @override
  String get adminNetworkingRestartWarning =>
      'Änderungen an den Netzwerkeinstellungen können einen Serverneustart erfordern.';

  @override
  String get adminNetworkingRemoteAccess => 'Fernzugriff aktivieren';

  @override
  String get adminNetworkingPorts => 'Ports';

  @override
  String get adminNetworkingHttpPort => 'HTTP-Port';

  @override
  String get adminNetworkingHttpsPort => 'HTTPS-Port';

  @override
  String get adminNetworkingEnableHttps => 'HTTPS aktivieren';

  @override
  String get adminNetworkingLocalNetwork => 'Lokales Netzwerk';

  @override
  String get adminNetworkingLocalAddresses => 'Lokale Netzwerkadressen';

  @override
  String get adminNetworkingAddressHint => 'z. B. 192.168.1.0/24';

  @override
  String get adminNetworkingKnownProxies => 'Bekannte Proxys';

  @override
  String get adminNetworkingProxyHint => 'z. B. 10.0.0.1';

  @override
  String get adminNetworkingWhitelist => 'Whitelist';

  @override
  String get adminNetworkingBlacklist => 'Blacklist';

  @override
  String get adminNetworkingAddEntry => 'Eintrag hinzufügen';

  @override
  String get adminBrandingTitle => 'Branding';

  @override
  String get adminBrandingLoginDisclaimer => 'Anmelde-Haftungsausschluss';

  @override
  String get adminBrandingLoginDisclaimerHint =>
      'HTML, das unter dem Anmeldeformular angezeigt wird';

  @override
  String get adminBrandingCustomCss => 'Benutzerdefiniertes CSS';

  @override
  String get adminBrandingCustomCssHint =>
      'Benutzerdefiniertes CSS für das Web-Interface';

  @override
  String get adminBrandingEnableSplash => 'Startbildschirm aktivieren';

  @override
  String get adminPlaybackHwAccel => 'Hardwarebeschleunigung';

  @override
  String get adminPlaybackHwAccelLabel => 'Hardwarebeschleunigung';

  @override
  String get adminPlaybackEnableHwEncoding => 'Hardwarekodierung aktivieren';

  @override
  String get adminPlaybackEnableHwDecoding =>
      'Hardwaredekodierung aktivieren für:';

  @override
  String get adminPlaybackEncoding => 'Kodierung';

  @override
  String get adminPlaybackEncodingThreads => 'Kodierungsthreads';

  @override
  String get adminPlaybackFallbackFont => 'Ersatzschriftart aktivieren';

  @override
  String get adminPlaybackFallbackFontPath => 'Ersatzschriftart-Pfad';

  @override
  String get adminPlaybackStreaming => 'Streaming';

  @override
  String get adminResumeVideo => 'Video';

  @override
  String get adminResumeAudiobooks => 'Hörbücher';

  @override
  String get adminResumeMinAudiobookPct =>
      'Mindest-Hörbuch-Fortsetzungsprozentsatz';

  @override
  String get adminResumeMaxAudiobookPct =>
      'Maximaler Hörbuch-Fortsetzungsprozentsatz';

  @override
  String get adminStreamingBitrateLimit => 'Remote-Client-Bitrate-Limit (Mbps)';

  @override
  String get adminStreamingBitrateLimitHint =>
      'Leer lassen oder 0 für unbegrenzt';

  @override
  String get adminTrickplayHwAccel => 'Hardwarebeschleunigung aktivieren';

  @override
  String get adminTrickplayHwEncoding => 'Hardwarekodierung aktivieren';

  @override
  String get adminTrickplayKeyFrameOnly =>
      'Nur Schlüsselbild-Extraktion aktivieren';

  @override
  String get adminTrickplayKeyFrameOnlySubtitle =>
      'Schneller, aber geringere Genauigkeit';

  @override
  String get adminTrickplayNonBlocking => 'Nicht-blockierend';

  @override
  String get adminTrickplayBlocking => 'Blockierend';

  @override
  String get adminTrickplayPriorityHigh => 'Hoch';

  @override
  String get adminTrickplayPriorityAboveNormal => 'Überdurchschnittlich';

  @override
  String get adminTrickplayPriorityNormal => 'Normal';

  @override
  String get adminTrickplayPriorityBelowNormal => 'Unterdurchschnittlich';

  @override
  String get adminTrickplayPriorityIdle => 'Leerlauf';

  @override
  String get adminTrickplayImageSettings => 'Bildeinstellungen';

  @override
  String get adminTrickplayInterval => 'Intervall (ms)';

  @override
  String get adminTrickplayIntervalSubtitle =>
      'Wie oft Frames aufgenommen werden';

  @override
  String get adminTrickplayWidthResolutionsHint =>
      'Kommagetrennte Pixelbreiten (z. B. 320)';

  @override
  String get adminTrickplayQuality => 'Qualität';

  @override
  String get adminTrickplayQScale => 'Qualitätsskala';

  @override
  String get adminTrickplayQScaleSubtitle =>
      'Niedrigere Werte = bessere Qualität, größere Dateien';

  @override
  String get adminTrickplayJpegQuality => 'JPEG-Qualität';

  @override
  String get adminTrickplayProcessing => 'Verarbeitung';

  @override
  String get adminTasksEmpty => 'Keine geplanten Aufgaben gefunden';

  @override
  String get adminTasksNoFilterMatch =>
      'Keine Aufgaben stimmen mit dem aktuellen Filter überein';

  @override
  String get adminTaskCancelling => 'Wird abgebrochen...';

  @override
  String get adminTaskRunning => 'Wird ausgeführt...';

  @override
  String get adminTaskNeverRun => 'Noch nie ausgeführt';

  @override
  String get adminTaskStop => 'Stoppen';

  @override
  String get adminTaskRun => 'Ausführen';

  @override
  String get adminTaskDetailLastExecution => 'Letzte Ausführung';

  @override
  String get adminTaskDetailStarted => 'Gestartet';

  @override
  String get adminTaskDetailEnded => 'Beendet';

  @override
  String get adminTaskDetailDuration => 'Dauer';

  @override
  String get adminTaskDetailErrorLabel => 'Fehler:';

  @override
  String adminTaskTriggerDaily(String time) {
    return 'Täglich um $time';
  }

  @override
  String adminTaskTriggerWeekly(String day, String time) {
    return 'Jeden $day um $time';
  }

  @override
  String adminTaskTriggerInterval(String duration) {
    return 'Alle $duration';
  }

  @override
  String get adminTaskTriggerStartup => 'Beim Anwendungsstart';

  @override
  String get adminTaskTriggerTypeDaily => 'Täglich';

  @override
  String get adminTaskTriggerTypeWeekly => 'Wöchentlich';

  @override
  String get adminTaskTriggerTypeInterval => 'Im Intervall';

  @override
  String get adminTaskTriggerIntervalLabel => 'Intervall';

  @override
  String get adminTaskTriggerEveryHour => 'Jede Stunde';

  @override
  String get adminTaskTriggerEvery6Hours => 'Alle 6 Stunden';

  @override
  String get adminTaskTriggerEvery12Hours => 'Alle 12 Stunden';

  @override
  String get adminTaskTriggerEvery24Hours => 'Alle 24 Stunden';

  @override
  String get adminTaskTriggerEvery2Days => 'Alle 2 Tage';

  @override
  String adminTaskTriggerHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String get adminTaskTriggerTime => 'Uhrzeit';

  @override
  String get adminTaskTriggerNoLimit => 'Kein Limit';

  @override
  String get adminActivityJustNow => 'Gerade eben';

  @override
  String get adminActivityLastHour => 'Letzte Stunde';

  @override
  String get adminActivityToday => 'Heute';

  @override
  String get adminActivityYesterday => 'Gestern';

  @override
  String get adminActivityOlder => 'Älter';

  @override
  String adminActivityDaysAgo(int days) {
    return 'vor $days T.';
  }

  @override
  String adminActivityHoursAgo(int hours) {
    return 'vor $hours Std.';
  }

  @override
  String adminActivityMinutesAgo(int minutes) {
    return 'vor $minutes Min.';
  }

  @override
  String get adminActivityNow => 'jetzt';

  @override
  String adminActivityMinutesShort(int minutes) {
    return '$minutes Min.';
  }

  @override
  String adminActivityHoursShort(int hours) {
    return '$hours Std.';
  }

  @override
  String adminActivityDaysShort(int days) {
    return '$days T.';
  }

  @override
  String adminActivityDateShort(int month, int day) {
    return '$month/$day';
  }

  @override
  String get adminTrickplayDescription =>
      'Trickplay-Bildgenerierung für Vorschaubilder beim Spulen konfigurieren.';

  @override
  String get adminNetworkingPublicHttpsPort => 'Öffentlicher HTTPS-Port';

  @override
  String get adminNetworkingBaseUrl => 'Basis-URL';

  @override
  String get adminNetworkingBaseUrlHint => 'z. B. /jellyfin';

  @override
  String get adminNetworkingHttps => 'HTTPS';

  @override
  String get adminNetworkingCertPath => 'Zertifikatspfad';

  @override
  String get adminNetworkingRemoteIpFilter => 'Remote-IP-Filter';

  @override
  String get adminNetworkingRemoteIpFilterLabel => 'Remote-IP-Filter';

  @override
  String get adminPlaybackVaapiDevice => 'VA-API-Gerät';

  @override
  String get adminPlaybackAutomatic => '0 = automatisch';

  @override
  String get adminPlaybackTranscodeTempPath => 'Transkodierungs-Temporärpfad';

  @override
  String get adminPlaybackSegmentDeletion => 'Segmentlöschung erlauben';

  @override
  String get adminPlaybackSegmentKeep => 'Segmente behalten (Sekunden)';

  @override
  String get adminPlaybackThrottleBuffering => 'Pufferung drosseln';

  @override
  String get adminResumeMinPct => 'Mindest-Fortsetzungsprozentsatz';

  @override
  String get adminResumeMinPctSubtitle =>
      'Inhalte müssen über diesen Prozentsatz hinaus abgespielt werden, um den Fortschritt zu speichern';

  @override
  String get adminResumeMaxPct => 'Maximaler Fortsetzungsprozentsatz';

  @override
  String get adminResumeMaxPctSubtitle =>
      'Inhalte gelten nach diesem Prozentsatz als vollständig wiedergegeben';

  @override
  String get adminResumeMinDuration => 'Mindest-Fortsetzungsdauer (Sekunden)';

  @override
  String get adminResumeMinDurationSubtitle =>
      'Kürzere Elemente sind nicht fortsetzbar';

  @override
  String get adminTrickplayScanBehavior => 'Scanverhalten';

  @override
  String get adminTrickplayProcessPriority => 'Prozesspriorität';

  @override
  String get adminTrickplayTileWidth => 'Kachelbreite';

  @override
  String get adminTrickplayTileHeight => 'Kachelhöhe';

  @override
  String get adminTrickplayProcessThreads => 'Verarbeitungsthreads';

  @override
  String get adminTrickplayWidthResolutions => 'Breitenauflösungen';

  @override
  String get adminMetadataDefault => 'Standard';

  @override
  String get adminMetadataContentTypeUpdated => 'Inhaltstyp aktualisiert';

  @override
  String adminMetadataContentTypeFailed(String error) {
    return 'Inhaltstyp konnte nicht aktualisiert werden: $error';
  }

  @override
  String get adminGeneralSlowResponseThreshold =>
      'Schwellenwert für langsame Antwort (ms)';

  @override
  String get adminGeneralCachePath => 'Cache-Pfad';

  @override
  String get adminGeneralMetadataPath => 'Metadatenpfad';

  @override
  String get adminGeneralServerName => 'Servername';

  @override
  String get adminSettingsLoadFailed =>
      'Einstellungen konnten nicht geladen werden';

  @override
  String get adminDiscover => 'Entdecken';

  @override
  String adminChannelMappingsUpdateFailed(String error) {
    return 'Zuordnungen konnten nicht aktualisiert werden: $error';
  }

  @override
  String adminTimeLimitDuration(String duration) {
    return 'Zeitlimit: $duration';
  }

  @override
  String get folders => 'Ordner';

  @override
  String get libraries => 'Bibliotheken';

  @override
  String get syncPlay => 'SyncPlay';

  @override
  String get jellyseerr => 'Jellyseerr';

  @override
  String get seeAll => 'Alle anzeigen';

  @override
  String get noItems => 'Keine Einträge';

  @override
  String get switchUser => 'Benutzer wechseln';

  @override
  String get remoteControl => 'Fernbedienung';

  @override
  String get mediaBarLoading => 'Medienleiste wird geladen...';

  @override
  String get mediaBarError => 'Medienleiste konnte nicht geladen werden';

  @override
  String get offlineServerUnavailable =>
      'Mit dem Internet verbunden, aber der aktuelle Server ist nicht erreichbar.';

  @override
  String get offlineNoInternet =>
      'Du bist offline. Nur heruntergeladene Inhalte sind verfügbar.';

  @override
  String get offlineSwitchServer => 'Server wechseln';

  @override
  String get offlineSavedMedia => 'Gespeicherte Medien';

  @override
  String get castGoogleCast => 'Google Cast';

  @override
  String get castAirPlay => 'AirPlay';

  @override
  String get castDlna => 'DLNA';

  @override
  String get castRemotePlayback => 'Remote-Wiedergabe';

  @override
  String castControlFailed(String error) {
    return 'Cast-Steuerung fehlgeschlagen: $error';
  }

  @override
  String castKindControls(String kind) {
    return '$kind-Steuerung';
  }

  @override
  String get castDeviceVolume => 'Gerätelautstärke';

  @override
  String get castVolumeUnavailable => 'Nicht verfügbar';

  @override
  String castStopKind(String kind) {
    return '$kind stoppen';
  }

  @override
  String get audioLabel => 'Audio';

  @override
  String get subtitlesLabel => 'Untertitel';

  @override
  String get pinConfirmTitle => 'PIN bestätigen';

  @override
  String get pinSetTitle => 'PIN festlegen';

  @override
  String get pinEnterTitle => 'PIN eingeben';

  @override
  String get pinReenterToConfirm => 'Gib deine PIN zur Bestätigung erneut ein';

  @override
  String pinEnterNDigit(int length) {
    return 'Gib eine $length-stellige PIN ein';
  }

  @override
  String pinEnterYourNDigit(int length) {
    return 'Gib deine $length-stellige PIN ein';
  }

  @override
  String get pinIncorrect => 'Falsche PIN';

  @override
  String get pinMismatch => 'PINs stimmen nicht überein';

  @override
  String get pinForgot => 'PIN vergessen?';

  @override
  String get pinClear => 'Löschen';

  @override
  String get pinBackspace => 'Rücktaste';

  @override
  String get quickConnectAuthorized =>
      'Schnellverbindungs-Anfrage autorisiert.';

  @override
  String get quickConnectInvalidOrExpired =>
      'Schnellverbindungs-Code ist ungültig oder abgelaufen.';

  @override
  String get quickConnectNotSupported =>
      'Schnellverbindung wird auf diesem Server nicht unterstützt.';

  @override
  String get quickConnectAuthorizeFailed =>
      'Schnellverbindungs-Code konnte nicht autorisiert werden.';

  @override
  String get quickConnectDisabled =>
      'Schnellverbindung ist auf diesem Server deaktiviert.';

  @override
  String get quickConnectForbidden =>
      'Dein Konto kann diese Schnellverbindungs-Anfrage nicht autorisieren.';

  @override
  String get quickConnectNotFound =>
      'Schnellverbindungs-Code wurde nicht gefunden. Versuche einen neuen Code.';

  @override
  String quickConnectFailedWithMessage(String message) {
    return 'Schnellverbindung fehlgeschlagen: $message';
  }

  @override
  String get quickConnectEnterCode => 'Code eingeben';

  @override
  String get quickConnectAuthorize => 'Autorisieren';

  @override
  String remoteCommandFailed(String error) {
    return 'Befehl fehlgeschlagen: $error';
  }

  @override
  String get remoteControlTitle => 'Fernbedienung';

  @override
  String get remoteFailedToLoadSessions =>
      'Sitzungen konnten nicht geladen werden';

  @override
  String get remoteNoSessions => 'Keine steuerbaren Sitzungen';

  @override
  String get remoteStartPlayback =>
      'Wiedergabe auf einem anderen Gerät starten';

  @override
  String get unknownUser => 'Unbekannt';

  @override
  String get unknownItem => 'Unbekannt';

  @override
  String get remoteNothingPlaying =>
      'Auf dieser Sitzung wird nichts wiedergegeben';

  @override
  String get castingStarted => 'Streaming auf ausgewähltem Gerät gestartet';

  @override
  String castingFailed(String error) {
    return 'Streaming konnte nicht gestartet werden: $error';
  }

  @override
  String get noRemoteDevices => 'Keine Remote-Wiedergabegeräte verfügbar.';

  @override
  String get noRemoteDevicesIos =>
      'Keine Remote-Wiedergabegeräte verfügbar.\n\nAuf iOS sind AirPlay-Ziele im Simulator möglicherweise nicht verfügbar.';

  @override
  String get trackActionPlayNext => 'Als Nächstes abspielen';

  @override
  String get trackActionAddToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String get trackActionAddToPlaylist => 'Zur Wiedergabeliste hinzufügen';

  @override
  String get trackActionCancelDownload => 'Download abbrechen';

  @override
  String get trackActionDeleteFromPlaylist => 'Aus Wiedergabeliste löschen';

  @override
  String get trackActionMoveUp => 'Nach oben';

  @override
  String get trackActionMoveDown => 'Nach unten';

  @override
  String get trackActionRemoveFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get trackActionAddToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get trackActionGoToAlbum => 'Zum Album';

  @override
  String get trackActionGoToArtist => 'Zum Interpreten';

  @override
  String trackActionDownloading(String name) {
    return '$name wird heruntergeladen...';
  }

  @override
  String get trackActionDeletedFile => 'Heruntergeladene Datei gelöscht';

  @override
  String get trackActionDeleteFileFailed =>
      'Heruntergeladene Datei konnte nicht gelöscht werden';

  @override
  String get shuffleBy => 'Zufallswiedergabe nach';

  @override
  String get shuffleSelectLibrary => 'Bibliothek auswählen';

  @override
  String get shuffleSelectGenre => 'Genre auswählen';

  @override
  String get shuffleLibrary => 'Bibliothek';

  @override
  String get shuffleGenre => 'Genre';

  @override
  String get shuffleNoLibraries => 'Keine kompatiblen Bibliotheken verfügbar.';

  @override
  String get shuffleNoGenres =>
      'Keine Genres für diesen Zufallswiedergabemodus gefunden.';

  @override
  String get posterDisplayTitle => 'Anzeige';

  @override
  String get posterImageType => 'Bildtyp';

  @override
  String get imageTypePoster => 'Poster';

  @override
  String get imageTypeThumbnail => 'Miniaturansicht';

  @override
  String get imageTypeBanner => 'Banner';

  @override
  String get playlistAddFailed =>
      'Hinzufügen zur Wiedergabeliste fehlgeschlagen';

  @override
  String get playlistCreateFailed =>
      'Wiedergabeliste konnte nicht erstellt werden';

  @override
  String get playlistNew => 'Neue Wiedergabeliste';

  @override
  String get playlistCreate => 'Erstellen';

  @override
  String get playlistCreateNew => 'Neue Wiedergabeliste erstellen';

  @override
  String get playlistNoneFound => 'Keine Wiedergabelisten gefunden';

  @override
  String get addToPlaylist => 'Zur Wiedergabeliste hinzufügen';

  @override
  String get lyricsNotAvailable => 'Keine Liedtexte verfügbar';

  @override
  String get upNext => 'Als Nächstes';

  @override
  String get playNext => 'Als Nächstes abspielen';

  @override
  String get stillWatchingContent =>
      'Die Wiedergabe wurde angehalten. Schaust du noch?';

  @override
  String get stillWatchingStop => 'Stoppen';

  @override
  String get stillWatchingContinue => 'Fortsetzen';

  @override
  String skipSegment(String segment) {
    return '$segment überspringen';
  }

  @override
  String get liveTv => 'Live TV';

  @override
  String get continueWatchingAndNextUp => 'Weiterschauen & Als Nächstes';

  @override
  String downloadingBatchProgress(int current, int total, String fileName) {
    return 'Heruntergeladen $current/$total — $fileName';
  }

  @override
  String downloadingFile(String fileName) {
    return '$fileName wird heruntergeladen';
  }

  @override
  String get nextEpisode => 'Nächste Episode';

  @override
  String get moreFromThisSeason => 'Mehr aus dieser Staffel';

  @override
  String get playerTooltipPlaybackSpeed => 'Wiedergabegeschwindigkeit';

  @override
  String get playerTooltipCastControls => 'Casting-Steuerung';

  @override
  String get playerTooltipPlaybackQuality => 'Wiedergabequalität';

  @override
  String get playerTooltipEnterFullscreen => 'Vollbild aktivieren';

  @override
  String get playerTooltipExitFullscreen => 'Vollbild verlassen';

  @override
  String get playerTooltipPrevious => 'Vorherige';

  @override
  String get playerTooltipSeekBack => 'Zurückspulen';

  @override
  String get playerTooltipSeekForward => 'Vorspulen';
}
