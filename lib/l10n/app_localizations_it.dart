// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Moonfin';

  @override
  String get signIn => 'Accedi';

  @override
  String connectingToServer(String serverName) {
    return 'Connessione a $serverName';
  }

  @override
  String get quickConnect => 'Connessione Rapida';

  @override
  String get password => 'Password';

  @override
  String get username => 'Nome utente';

  @override
  String get quickConnectInstruction =>
      'Inserisci questo codice nella dashboard web del tuo server:';

  @override
  String get waitingForAuthorization => 'In attesa di autorizzazione...';

  @override
  String get back => 'Indietro';

  @override
  String get serverUnavailable => 'Server non disponibile';

  @override
  String get loginFailed => 'Accesso fallito';

  @override
  String quickConnectUnavailable(String detail) {
    return 'Connessione Rapida non disponibile: $detail';
  }

  @override
  String quickConnectUnavailableWithStatus(String status, String detail) {
    return 'Connessione Rapida non disponibile ($status): $detail';
  }

  @override
  String get whosWatching => 'Chi sta guardando?';

  @override
  String get addUser => 'Aggiungi Utente';

  @override
  String get selectServer => 'Seleziona Server';

  @override
  String appVersionFooter(String version) {
    return 'Moonfin versione $version';
  }

  @override
  String get savedServers => 'Server Salvati';

  @override
  String get discoveredServers => 'Server Trovati';

  @override
  String get noneFound => 'Nessuno trovato';

  @override
  String get unableToConnectToServer => 'Impossibile connettersi al server';

  @override
  String get addServer => 'Aggiungi Server';

  @override
  String get embyConnect => 'Emby Connect';

  @override
  String get removeServer => 'Rimuovi Server';

  @override
  String removeServerConfirmation(String serverName) {
    return 'Rimuovere \"$serverName\" dai tuoi server?';
  }

  @override
  String get cancel => 'Annulla';

  @override
  String get remove => 'Rimuovi';

  @override
  String get connectToServer => 'Connetti al Server';

  @override
  String get serverAddress => 'Indirizzo Server';

  @override
  String get serverAddressHint => 'https://tuo-server.esempio.com';

  @override
  String get connect => 'Connetti';

  @override
  String get secureStorageUnavailable => 'Archiviazione Sicura Non Disponibile';

  @override
  String get secureStorageUnavailableMessage =>
      'Moonfin non è riuscito ad accedere al portachiavi di sistema. L\'accesso può continuare, ma l\'archiviazione sicura dei token potrebbe non essere disponibile fino allo sblocco del portachiavi.';

  @override
  String get ok => 'OK';

  @override
  String get embyConnectSignInSubtitle =>
      'Accedi con il tuo account Emby Connect';

  @override
  String get emailOrUsername => 'Email o Nome utente';

  @override
  String get selectAServer => 'Seleziona un Server';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get noLinkedServers =>
      'Nessun server collegato a questo account Emby Connect';

  @override
  String get invalidEmbyConnectCredentials =>
      'Credenziali Emby Connect non valide';

  @override
  String get invalidEmbyConnectLogin =>
      'Nome utente o password Emby Connect non validi';

  @override
  String get embyConnectExchangeNotSupported =>
      'Il server non supporta lo scambio Emby Connect';

  @override
  String get embyConnectNetworkError =>
      'Errore di rete durante il contatto con Emby Connect o il server selezionato';

  @override
  String get loadingLinkedServers => 'Caricamento server collegati...';

  @override
  String get connectingToServerEllipsis => 'Connessione al server...';

  @override
  String get noReachableAddress => 'Nessun indirizzo raggiungibile fornito';

  @override
  String get invalidServerExchangeResponse =>
      'Risposta non valida dall\'endpoint di scambio del server';

  @override
  String unableToConnectTo(String target) {
    return 'Impossibile connettersi a $target';
  }

  @override
  String get exitApp => 'Uscire da Moonfin?';

  @override
  String get exitAppConfirmation => 'Sei sicuro di voler uscire?';

  @override
  String get exit => 'Esci';

  @override
  String get noHomeRowsLoaded => 'Impossibile caricare le righe della home';

  @override
  String get noHomeRowsHint =>
      'Prova ad aggiornare o a ridurre le sezioni home attive.';

  @override
  String get retryHomeRows => 'Ricarica Righe Home';

  @override
  String get guide => 'Guida';

  @override
  String get recordings => 'Registrazioni';

  @override
  String get schedule => 'Programmazione';

  @override
  String get series => 'Serie';

  @override
  String get noItemsFound => 'Nessun elemento trovato';

  @override
  String get home => 'Home';

  @override
  String get browseAll => 'Sfoglia Tutto';

  @override
  String get genres => 'Generi';

  @override
  String get collectionPlaceholder =>
      'Gli elementi della collezione appariranno qui';

  @override
  String get browseByLetter => 'Sfoglia per Lettera';

  @override
  String get alphabeticalBrowsePlaceholder =>
      'La navigazione alfabetica apparirà qui';

  @override
  String get suggestions => 'Suggerimenti';

  @override
  String get suggestionsPlaceholder => 'Gli elementi suggeriti appariranno qui';

  @override
  String get failedToLoadLibraries => 'Impossibile caricare le librerie';

  @override
  String get noLibrariesFound => 'Nessuna libreria trovata';

  @override
  String get library => 'Libreria';

  @override
  String get displaySettings => 'Impostazioni Visualizzazione';

  @override
  String get allGenres => 'Tutti i Generi';

  @override
  String get noGenresFound => 'Nessun genere trovato';

  @override
  String failedToLoadFolderError(String error) {
    return 'Impossibile caricare la cartella: $error';
  }

  @override
  String get thisFolderIsEmpty => 'Questa cartella è vuota';

  @override
  String itemCountLabel(int count) {
    return '$count elementi';
  }

  @override
  String get failedToLoadFavorites => 'Impossibile caricare i preferiti';

  @override
  String get retry => 'Riprova';

  @override
  String get noFavoritesYet => 'Nessun preferito ancora';

  @override
  String get favorites => 'Preferiti';

  @override
  String totalCountItems(int count) {
    return '$count Elementi';
  }

  @override
  String get continuing => 'In corso';

  @override
  String get ended => 'Terminata';

  @override
  String get sortAndFilter => 'Ordina e Filtra';

  @override
  String get type => 'Tipo';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get display => 'Visualizzazione';

  @override
  String get imageType => 'Tipo Immagine';

  @override
  String get posterSize => 'Dimensione Poster';

  @override
  String get small => 'Piccolo';

  @override
  String get medium => 'Medio';

  @override
  String get large => 'Grande';

  @override
  String get extraLarge => 'Extra Grande';

  @override
  String libraryGenresTitle(String name) {
    return '$name — Generi';
  }

  @override
  String get views => 'Viste';

  @override
  String get albums => 'Album';

  @override
  String get albumArtists => 'Artisti Album';

  @override
  String get artists => 'Artisti';

  @override
  String get bookmarks => 'Segnalibri';

  @override
  String get noSavedBookmarks => 'Nessun segnalibro salvato per questo titolo.';

  @override
  String get openBook => 'Apri Libro';

  @override
  String get chapter => 'Capitolo';

  @override
  String get page => 'Pagina';

  @override
  String get bookmark => 'Segnalibro';

  @override
  String get justNow => 'Proprio ora';

  @override
  String minutesAgo(int count) {
    return '${count}m fa';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h fa';
  }

  @override
  String daysAgo(int count) {
    return '${count}g fa';
  }

  @override
  String get discoverySubjects => 'Argomenti Scoperta';

  @override
  String get pickDiscoverySubjects =>
      'Scegli quali feed di argomenti mostrare in Scopri.';

  @override
  String get apply => 'Applica';

  @override
  String get audiobookGenres => 'Generi Audiolibri';

  @override
  String get pickAudiobookGenres =>
      'Scegli quali generi mostrare in Scopri Audiolibri.';

  @override
  String get discoverAudiobooks => 'Scopri Audiolibri';

  @override
  String get librivoxDescription =>
      'Titoli popolari di dominio pubblico da LibriVox.';

  @override
  String titlesCount(int count) {
    return '$count titoli';
  }

  @override
  String get scrollLeft => 'Scorri a sinistra';

  @override
  String get scrollRight => 'Scorri a destra';

  @override
  String get couldNotLoadGenre =>
      'Impossibile caricare questo genere al momento.';

  @override
  String get continueReading => 'Continua a Leggere';

  @override
  String get savedHighlights => 'Evidenziazioni Salvate';

  @override
  String get continueListening => 'Continua ad Ascoltare';

  @override
  String get listen => 'Ascolta';

  @override
  String get resume => 'Riprendi';

  @override
  String get failedToLoadLibrary => 'Impossibile caricare la libreria';

  @override
  String get popularNow => 'Popolari Ora';

  @override
  String get savedForLater => 'Salvati per Dopo';

  @override
  String get topListens => 'Più Ascoltati';

  @override
  String get unreadDiscoveries => 'Scoperte Non Lette';

  @override
  String get pickUpAgain => 'Riprendi';

  @override
  String get bookHighlightsDescription =>
      'I tuoi libri con evidenziazioni, preferiti o progressi di lettura.';

  @override
  String get handPickedFromLibrary => 'Selezionati dalla tua libreria.';

  @override
  String get handPickedFromListeningQueue =>
      'Selezionati dalla tua coda di ascolto.';

  @override
  String get booksWithHighlights =>
      'Libri con evidenziazioni, preferiti o progressi di lettura.';

  @override
  String get jumpBackNarration =>
      'Torna alla narrazione senza cercare il punto.';

  @override
  String get unreadBooksReady =>
      'Libri non letti pronti per la prossima ora tranquilla.';

  @override
  String get quickAccessFavorites =>
      'Accesso rapido ai libri a cui torni sempre.';

  @override
  String get searchAudiobooks => 'Cerca audiolibri';

  @override
  String get searchYourLibrary => 'Cerca nella tua libreria';

  @override
  String get pickUpStory => 'Riprendi la storia da dove l\'avevi lasciata';

  @override
  String get savedPlacesChapters =>
      'I tuoi punti salvati e capitoli non finiti';

  @override
  String authorsCount(int count) {
    return '$count autori';
  }

  @override
  String genresCount(int count) {
    return '$count generi';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% completato';
  }

  @override
  String get readyWhenYouAre => 'Pronto quando lo sei tu';

  @override
  String get details => 'Dettagli';

  @override
  String get listeningRoom => 'Sala d\'Ascolto';

  @override
  String get bookmarksAndProgress => 'Segnalibri e Progressi';

  @override
  String titlesArrangedForBrowsing(int count) {
    return '$count titoli organizzati per la navigazione.';
  }

  @override
  String get titles => 'Titoli';

  @override
  String get allTitles => 'Tutti i Titoli';

  @override
  String get authors => 'Autori';

  @override
  String get browseByAuthor => 'Sfoglia per Autore';

  @override
  String get browseByGenre => 'Sfoglia per Genere';

  @override
  String get discover => 'Scopri';

  @override
  String get trendingTitlesOpenLibrary =>
      'Titoli di tendenza per argomento da Open Library.';

  @override
  String get noBookmarkedItems => 'Nessun elemento nei segnalibri';

  @override
  String get nothingMatchesSection =>
      'Nessun risultato per questa sezione. Prova un\'altra scheda o torna dopo la sincronizzazione della libreria.';

  @override
  String get audiobooks => 'Audiolibri';

  @override
  String noLabelFound(String label) {
    return 'Nessun $label trovato';
  }

  @override
  String get folder => 'Cartella';

  @override
  String get filters => 'Filtri';

  @override
  String get readingStatus => 'Stato Lettura';

  @override
  String get playedStatus => 'Stato Riproduzione';

  @override
  String get readStatus => 'Letto';

  @override
  String get watched => 'Visto';

  @override
  String get unread => 'Non letto';

  @override
  String get unwatched => 'Non visto';

  @override
  String get seriesStatus => 'Stato Serie';

  @override
  String get allLibraries => 'Tutte le Librerie';

  @override
  String get books => 'Libri';

  @override
  String get author => 'Autore';

  @override
  String get unknownAuthor => 'Autore Sconosciuto';

  @override
  String get uncategorized => 'Non categorizzato';

  @override
  String get overview => 'Panoramica';

  @override
  String get noLibrivoxDescription =>
      'Nessuna descrizione fornita da LibriVox per questo titolo.';

  @override
  String get readers => 'Lettori';

  @override
  String get openLinks => 'Apri Link';

  @override
  String get librivoxPage => 'Pagina LibriVox';

  @override
  String get internetArchive => 'Internet Archive';

  @override
  String get rssFeed => 'Feed RSS';

  @override
  String get downloadZip => 'Scarica Zip';

  @override
  String sectionCountLabel(int count) {
    return '$count sezioni';
  }

  @override
  String firstPublished(int year) {
    return 'Prima pubblicazione $year';
  }

  @override
  String get noOpenLibraryOverview =>
      'Nessuna panoramica disponibile da Open Library per questo titolo.';

  @override
  String get subjects => 'Argomenti';

  @override
  String get all => 'Tutto';

  @override
  String booksCount(int count) {
    return '$count libri';
  }

  @override
  String get couldNotLoadSubject =>
      'Impossibile caricare questo argomento al momento.';

  @override
  String get audiobookDetails => 'Dettagli Audiolibro';

  @override
  String authorsCountTitle(int count) {
    return '$count Autori';
  }

  @override
  String audiobookCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count audiolibri',
      one: '1 audiolibro',
    );
    return '$_temp0';
  }

  @override
  String get trackList => 'Lista Tracce';

  @override
  String get itemListPlaceholder => 'La lista elementi apparirà qui';

  @override
  String get favoriteTracksPlaceholder => 'Le tracce preferite appariranno qui';

  @override
  String get failedToLoad => 'Impossibile caricare';

  @override
  String get delete => 'Elimina';

  @override
  String get save => 'Salva';

  @override
  String get moreLikeThis => 'Titoli Simili';

  @override
  String get castAndCrew => 'Cast e Troupe';

  @override
  String get collection => 'Collezione';

  @override
  String get episodes => 'Episodi';

  @override
  String get nextUp => 'Prossimo';

  @override
  String get seasons => 'Stagioni';

  @override
  String get chapters => 'Capitoli';

  @override
  String get features => 'Contenuti';

  @override
  String get movies => 'Film';

  @override
  String get other => 'Altro';

  @override
  String get discography => 'Discografia';

  @override
  String get similarArtists => 'Artisti Simili';

  @override
  String get tableOfContents => 'Indice';

  @override
  String get tracklist => 'Lista Tracce';

  @override
  String get biography => 'Biografia';

  @override
  String get authorDetails => 'Dettagli Autore';

  @override
  String get noOverviewAvailable =>
      'Nessuna panoramica disponibile per questo titolo.';

  @override
  String get noBiographyAvailable =>
      'Nessuna biografia disponibile per questo autore.';

  @override
  String get noBooksFound => 'Nessun libro trovato per questo autore.';

  @override
  String get unableToLoadAuthorDetails =>
      'Impossibile caricare i dettagli dell\'autore al momento.';

  @override
  String published(int year) {
    return 'Pubblicato $year';
  }

  @override
  String get publicationDateUnknown => 'Data di pubblicazione sconosciuta';

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stagioni',
      one: '1 Stagione',
    );
    return '$_temp0';
  }

  @override
  String endsAt(String time) {
    return 'Finisce alle $time';
  }

  @override
  String get view => 'Visualizza';

  @override
  String get resumeReading => 'Riprendi Lettura';

  @override
  String get read => 'Leggi';

  @override
  String resumeFrom(String position) {
    return 'Riprendi da $position';
  }

  @override
  String get play => 'Riproduci';

  @override
  String get startOver => 'Ricomincia';

  @override
  String get restart => 'Riavvia';

  @override
  String get readOffline => 'Leggi Offline';

  @override
  String get playOffline => 'Riproduci Offline';

  @override
  String get audio => 'Audio';

  @override
  String get subtitles => 'Sottotitoli';

  @override
  String get version => 'Versione';

  @override
  String get cast => 'Cast';

  @override
  String get trailer => 'Trailer';

  @override
  String get finished => 'Completato';

  @override
  String get favorited => 'Nei Preferiti';

  @override
  String get favorite => 'Preferito';

  @override
  String get playlist => 'Playlist';

  @override
  String get downloaded => 'Scaricato';

  @override
  String get downloadAll => 'Scarica Tutto';

  @override
  String get download => 'Scarica';

  @override
  String get deleteDownloaded => 'Elimina Scaricato';

  @override
  String get goToSeries => 'Vai alla Serie';

  @override
  String get editMetadata => 'Modifica Metadati';

  @override
  String get less => 'Meno';

  @override
  String get more => 'Altro';

  @override
  String get deleteItem => 'Elimina Elemento';

  @override
  String get deletePlaylist => 'Elimina Playlist';

  @override
  String get deletePlaylistMessage => 'Eliminare questa playlist dal server?';

  @override
  String get deleteItemMessage => 'Eliminare questo elemento dal server?';

  @override
  String get failedToDeletePlaylist => 'Impossibile eliminare la playlist';

  @override
  String get failedToDeleteItem => 'Impossibile eliminare l\'elemento';

  @override
  String get renamePlaylist => 'Rinomina Playlist';

  @override
  String get playlistName => 'Nome playlist';

  @override
  String get deleteDownloadedAlbum => 'Elimina Album Scaricato';

  @override
  String deleteDownloadedTracksMessage(String title) {
    return 'Eliminare le tracce scaricate per \"$title\"?';
  }

  @override
  String get downloadedTracksDeleted => 'Tracce scaricate eliminate';

  @override
  String get downloadedTracksDeleteFailed =>
      'Alcune tracce scaricate non possono essere eliminate';

  @override
  String get noTracksLoaded => 'Nessuna traccia caricata';

  @override
  String noItemsLoaded(String itemLabel) {
    return 'Nessun $itemLabel caricato';
  }

  @override
  String downloadingTitle(String title, int count) {
    return 'Download di $title ($count elementi)...';
  }

  @override
  String deleteConfirmMessage(String name) {
    return 'Sei sicuro di voler eliminare \"$name\" dal server? Questa azione non può essere annullata.';
  }

  @override
  String get itemDeleted => 'Elemento eliminato';

  @override
  String get noPlayableTrailerFound => 'Nessun trailer riproducibile trovato.';

  @override
  String unsupportedBookFormat(String extension) {
    return 'Formato libro non supportato: .$extension';
  }

  @override
  String get audioTrack => 'Traccia Audio';

  @override
  String get subtitleTrack => 'Traccia Sottotitoli';

  @override
  String get none => 'Nessuno';

  @override
  String get downloadSubtitlesLabel => 'Scarica sottotitoli...';

  @override
  String get searchOpenSubtitlesPlugin => 'Cerca con il plugin OpenSubtitles';

  @override
  String get downloadSubtitles => 'Scarica Sottotitoli';

  @override
  String get selectedSubtitleInvalid =>
      'Il sottotitolo selezionato non è valido.';

  @override
  String subtitleDownloadedSelected(String name) {
    return 'Sottotitolo scaricato e selezionato: $name';
  }

  @override
  String get subtitleDownloadedPending =>
      'Sottotitolo scaricato. Potrebbe volerci un momento prima che appaia mentre Jellyfin aggiorna l\'elemento.';

  @override
  String noRemoteSubtitlesFound(String language) {
    return 'Nessun sottotitolo remoto trovato per $language.';
  }

  @override
  String get selectVersion => 'Seleziona Versione';

  @override
  String versionNumber(int number) {
    return 'Versione $number';
  }

  @override
  String get downloadAllQuality => 'Scarica Tutto — Qualità';

  @override
  String get downloadQuality => 'Qualità Download';

  @override
  String get originalFileNoReencoding => 'File originale, nessuna ri-codifica';

  @override
  String get originalFilesNoReencoding => 'File originali, nessuna ri-codifica';

  @override
  String get noEpisodesLoaded => 'Nessun episodio caricato';

  @override
  String downloadingItem(String name, String quality) {
    return 'Download di $name ($quality)...';
  }

  @override
  String get deleteDownloadedFiles => 'Elimina File Scaricati';

  @override
  String deleteLocalFilesMessage(String typeLabel) {
    return 'Eliminare i file locali per $typeLabel?\n\nQuesto libererà spazio di archiviazione. Potrai scaricarli di nuovo in seguito.';
  }

  @override
  String get downloadedFilesDeleted => 'File scaricati eliminati';

  @override
  String get failedToDeleteFiles => 'Impossibile eliminare i file';

  @override
  String get deleteFiles => 'Elimina File';

  @override
  String get director => 'REGISTA';

  @override
  String get writers => 'SCENEGGIATORI';

  @override
  String get studio => 'STUDIO';

  @override
  String studioMoreCount(int count) {
    return '+$count altri';
  }

  @override
  String totalEpisodes(int count) {
    return '$count Episodi';
  }

  @override
  String episodeProgress(int watched, int total) {
    return '$watched / $total';
  }

  @override
  String episodeLabel(int number) {
    return 'Episodio $number';
  }

  @override
  String chapterNumber(int number) {
    return 'Capitolo $number';
  }

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracce',
      one: '1 traccia',
    );
    return '$_temp0';
  }

  @override
  String chapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capitoli',
      one: '1 capitolo',
    );
    return '$_temp0';
  }

  @override
  String born(String date) {
    return 'Nato il $date';
  }

  @override
  String died(String date) {
    return 'Morto il $date';
  }

  @override
  String age(int age) {
    return 'Età $age';
  }

  @override
  String get showLess => 'Mostra Meno';

  @override
  String get readMore => 'Leggi Tutto';

  @override
  String get shuffle => 'Riproduzione Casuale';

  @override
  String downloadsCount(int count) {
    return '$count download';
  }

  @override
  String get perfectMatch => 'Corrispondenza perfetta';

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
    return 'La $action dei sottotitoli remoti richiede il permesso di gestione sottotitoli di Jellyfin per questo utente.';
  }

  @override
  String remoteSubtitleNotFoundError(String action) {
    return 'Questo elemento non è stato trovato sul server per la $action dei sottotitoli remoti.';
  }

  @override
  String remoteSubtitleDetailError(String action, String detail) {
    return 'La $action dei sottotitoli remoti è fallita: $detail';
  }

  @override
  String remoteSubtitleHttpError(String action, int status) {
    return 'La $action dei sottotitoli remoti è fallita (HTTP $status).';
  }

  @override
  String remoteSubtitleGenericError(String action) {
    return 'Impossibile $action i sottotitoli remoti.';
  }

  @override
  String deleteSeriesFiles(String name) {
    return 'tutti gli episodi scaricati per \"$name\"';
  }

  @override
  String get deleteSeasonFiles =>
      'tutti gli episodi scaricati in questa stagione';

  @override
  String get stillWatching => 'Stai ancora guardando?';

  @override
  String get unableToLoadTrailerStream =>
      'Impossibile caricare lo stream del trailer.';

  @override
  String get trailerTimedOut => 'Timeout durante il caricamento del trailer.';

  @override
  String get playbackFailedForTrailer =>
      'Riproduzione fallita per questo trailer.';

  @override
  String photoCountOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get castingUnavailableOffline =>
      'Il casting non è disponibile durante la riproduzione offline.';

  @override
  String castActionFailed(String label, String error) {
    return 'Azione $label fallita: $error';
  }

  @override
  String failedToSetCastVolume(String error) {
    return 'Impossibile impostare il volume del cast: $error';
  }

  @override
  String castControlsTitle(String label) {
    return 'Controlli $label';
  }

  @override
  String get deviceVolume => 'Volume Dispositivo';

  @override
  String get unavailable => 'Non disponibile';

  @override
  String get pause => 'Pausa';

  @override
  String get syncPosition => 'Sincronizza Posizione';

  @override
  String stopCast(String label) {
    return 'Ferma $label';
  }

  @override
  String get queueIsEmpty => 'La coda è vuota';

  @override
  String trackNumber(int number) {
    return 'Traccia $number';
  }

  @override
  String get remotePlayback => 'Riproduzione Remota';

  @override
  String get castingToGoogleCast => 'Trasmissione su Google Cast';

  @override
  String get castingViaAirPlay => 'Trasmissione via AirPlay';

  @override
  String get castingViaDlna => 'Trasmissione via DLNA';

  @override
  String secondsCount(int seconds) {
    return '$seconds secondi';
  }

  @override
  String get longPressToUnlock => 'Premi a lungo per sbloccare';

  @override
  String get off => 'Spento';

  @override
  String streamTypeFallback(String streamType, int number) {
    return '$streamType $number';
  }

  @override
  String get auto => 'Automatico';

  @override
  String bitrateValueMbps(int mbps) {
    return '$mbps Mbps';
  }

  @override
  String get audioDelay => 'Ritardo Audio';

  @override
  String get subtitleDelay => 'Ritardo Sottotitoli';

  @override
  String get reset => 'Ripristina';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get playbackInformation => 'Informazioni Riproduzione';

  @override
  String get playback => 'Riproduzione';

  @override
  String get playMethod => 'Metodo Riproduzione';

  @override
  String get directPlay => 'Riproduzione Diretta';

  @override
  String get directStream => 'Stream Diretto';

  @override
  String get transcoding => 'Transcodifica';

  @override
  String get transcodeReasons => 'Motivi Transcodifica';

  @override
  String get player => 'Lettore';

  @override
  String get container => 'Contenitore';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get video => 'Video';

  @override
  String get resolution => 'Risoluzione';

  @override
  String get hdr => 'HDR';

  @override
  String get codec => 'Codec';

  @override
  String get videoBitrate => 'Bitrate Video';

  @override
  String get track => 'Traccia';

  @override
  String get channels => 'Canali';

  @override
  String get audioBitrate => 'Bitrate Audio';

  @override
  String get sampleRate => 'Frequenza di Campionamento';

  @override
  String get format => 'Formato';

  @override
  String get external => 'Esterno';

  @override
  String get embedded => 'Incorporato';

  @override
  String castSessionError(String protocol) {
    return 'Errore sessione $protocol';
  }

  @override
  String failedToLoadBookDetails(String error) {
    return 'Impossibile caricare i dettagli del libro: $error';
  }

  @override
  String get epubUnavailableOnPlatform =>
      'La visualizzazione EPUB nell\'app non è ancora disponibile su questa piattaforma.';

  @override
  String formatCannotRenderInApp(String extension) {
    return 'Questo formato (.$extension) non può ancora essere visualizzato nell\'app.';
  }

  @override
  String get embeddedRenderingUnavailable =>
      'La visualizzazione di documenti incorporati non è disponibile su questa piattaforma.';

  @override
  String get couldNotOpenExternalViewer =>
      'Impossibile aprire il visualizzatore esterno.';

  @override
  String failedToOpenInAppReader(String error) {
    return 'Impossibile aprire il lettore integrato: $error';
  }

  @override
  String bookmarkAlreadySaved(String label) {
    return 'Segnalibro già salvato a $label.';
  }

  @override
  String bookmarkAdded(String label) {
    return 'Segnalibro aggiunto: $label';
  }

  @override
  String get noBookmarksYet =>
      'Nessun segnalibro ancora.\nTocca l\'icona del segnalibro durante la lettura per salvare la tua posizione.';

  @override
  String get noTableOfContentsAvailable => 'Indice non disponibile';

  @override
  String pageLabel(int number) {
    return 'Pagina $number';
  }

  @override
  String get position => 'Posizione';

  @override
  String get bookReader => 'Lettore di Libri';

  @override
  String formatExtension(String extension) {
    return 'Formato: .$extension';
  }

  @override
  String percentRead(String percent) {
    return '$percent% letto';
  }

  @override
  String get updating => 'Aggiornamento...';

  @override
  String get markUnread => 'Segna come Non Letto';

  @override
  String get markAsRead => 'Segna come Letto';

  @override
  String get reloadReader => 'Ricarica Lettore';

  @override
  String get noPagesFound => 'Nessuna pagina trovata.';

  @override
  String get failedToDecodePageImage =>
      'Impossibile decodificare l\'immagine della pagina.';

  @override
  String resetZoom(String zoom) {
    return 'Ripristina Zoom (${zoom}x)';
  }

  @override
  String get singlePage => 'Pagina Singola';

  @override
  String get twoPageSpread => 'Doppia Pagina';

  @override
  String get addBookmark => 'Aggiungi Segnalibro';

  @override
  String get bookmarksEllipsis => 'Segnalibri...';

  @override
  String get markedAsRead => 'Segnato come letto';

  @override
  String get markedAsUnread => 'Segnato come non letto';

  @override
  String failedToUpdateReadState(String error) {
    return 'Impossibile aggiornare lo stato di lettura: $error';
  }

  @override
  String get themeSystem => 'Tema: Sistema';

  @override
  String get themeLight => 'Tema: Chiaro';

  @override
  String get themeDark => 'Tema: Scuro';

  @override
  String get themeSepia => 'Tema: Seppia';

  @override
  String get invertColorsFixedLayout => 'Inverti Colori (layout fisso)';

  @override
  String get invertColorsPdf => 'Inverti Colori (PDF)';

  @override
  String get preparingInAppReader => 'Preparazione del lettore integrato...';

  @override
  String get pdfDataNotAvailable => 'Dati PDF non disponibili.';

  @override
  String get readerFallbackModeActive => 'Modalità lettore di riserva attiva';

  @override
  String platformCannotHostDocumentEngine(String extension) {
    return 'Questa piattaforma non può ospitare il motore documenti incorporato per i file $extension.';
  }

  @override
  String get reloadReaderPlatformHint =>
      'Usa Ricarica Lettore dopo il passaggio a una piattaforma supportata (Android, iOS, macOS).';

  @override
  String get openExternally => 'Apri Esternamente';

  @override
  String get noEpubChaptersFound => 'Nessun capitolo EPUB trovato.';

  @override
  String get readerNotReady => 'Lettore non pronto.';

  @override
  String get seriesRecordings => 'Registrazioni Serie';

  @override
  String get now => 'Ora';

  @override
  String get sports => 'Sport';

  @override
  String get news => 'Notizie';

  @override
  String get kids => 'Bambini';

  @override
  String get premiere => 'Prima Visione';

  @override
  String get guideTimeline => 'Timeline Guida';

  @override
  String failedToLoadGuide(String error) {
    return 'Impossibile caricare la guida: $error';
  }

  @override
  String get noChannelsFound => 'Nessun canale trovato';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get movie => 'Film';

  @override
  String get removedFromFavoriteChannels => 'Rimosso dai canali preferiti';

  @override
  String get addedToFavoriteChannels => 'Aggiunto ai canali preferiti';

  @override
  String get failedToUpdateFavoriteChannel =>
      'Impossibile aggiornare il canale preferito';

  @override
  String get unfavoriteChannel => 'Rimuovi Canale dai Preferiti';

  @override
  String get favoriteChannel => 'Canale Preferito';

  @override
  String get watch => 'Guarda';

  @override
  String get close => 'Chiudi';

  @override
  String failedToPlayChannel(String name) {
    return 'Impossibile riprodurre $name';
  }

  @override
  String get failedToLoadRecordings => 'Impossibile caricare le registrazioni';

  @override
  String get scheduledInNext24Hours => 'Programmati nelle Prossime 24 Ore';

  @override
  String get recentRecordings => 'Registrazioni Recenti';

  @override
  String get tvSeries => 'Serie TV';

  @override
  String get failedToLoadSchedule => 'Impossibile caricare la programmazione';

  @override
  String get noScheduledRecordings => 'Nessuna registrazione programmata';

  @override
  String get cancelRecording => 'Annullare la Registrazione?';

  @override
  String cancelScheduledRecordingOf(String name) {
    return 'Annullare la registrazione programmata di \"$name\"?';
  }

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Sì, Annulla';

  @override
  String get failedToCancelRecording =>
      'Impossibile annullare la registrazione';

  @override
  String get failedToLoadSeriesRecordings =>
      'Impossibile caricare le registrazioni delle serie';

  @override
  String get noSeriesRecordings => 'Nessuna registrazione di serie';

  @override
  String get cancelSeriesRecording => 'Annulla Registrazione Serie';

  @override
  String get cancelSeriesRecordingQuestion =>
      'Annullare la Registrazione Serie?';

  @override
  String stopRecordingName(String name) {
    return 'Fermare la registrazione di \"$name\"?';
  }

  @override
  String get failedToCancelSeriesRecording =>
      'Impossibile annullare la registrazione della serie';

  @override
  String get searchThisLibrary => 'Cerca in questa libreria...';

  @override
  String get searchEllipsis => 'Cerca...';

  @override
  String noResultsForQuery(String query) {
    return 'Nessun risultato per \"$query\"';
  }

  @override
  String searchFailedError(String error) {
    return 'Ricerca fallita: $error';
  }

  @override
  String get seerr => 'Seerr';

  @override
  String get savedMedia => 'Media Salvati';

  @override
  String get tvShows => 'Serie TV';

  @override
  String get music => 'Musica';

  @override
  String get musicAlbums => 'Album Musicali';

  @override
  String get noMediaInFilter => 'Nessun media in questo filtro';

  @override
  String get noDownloadedMediaYet => 'Nessun media scaricato ancora';

  @override
  String get browseLibrary => 'Sfoglia Libreria';

  @override
  String get deleteDownload => 'Elimina Download';

  @override
  String removeItemAndFiles(String name) {
    return 'Rimuovere \"$name\" e i suoi file?';
  }

  @override
  String tracksCount(int count) {
    return '$count tracce';
  }

  @override
  String get album => 'Album';

  @override
  String get playAlbum => 'Riproduci Album';

  @override
  String failedToLoadAlbum(String error) {
    return 'Impossibile caricare l\'album: $error';
  }

  @override
  String noDownloadedTracksForAlbum(String name) {
    return 'Nessuna traccia scaricata trovata per $name.';
  }

  @override
  String get season => 'Stagione';

  @override
  String get errorLoadingEpisodes => 'Errore nel caricamento degli episodi';

  @override
  String get noDownloadedEpisodes => 'Nessun episodio scaricato';

  @override
  String get deleteEpisode => 'Elimina Episodio';

  @override
  String removeName(String name) {
    return 'Rimuovere \"$name\"?';
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
    return 'Episodio $number';
  }

  @override
  String get seriesNotFound => 'Serie non trovata';

  @override
  String get errorLoadingSeries => 'Errore nel caricamento della serie';

  @override
  String get downloadedEpisodes => 'Episodi Scaricati';

  @override
  String seasonNumber(int number) {
    return 'Stagione $number';
  }

  @override
  String get specials => 'Speciali';

  @override
  String get deleteSeason => 'Elimina Stagione';

  @override
  String deleteAllEpisodesInSeason(String season) {
    return 'Eliminare tutti gli episodi scaricati in $season?';
  }

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodi',
      one: '1 episodio',
    );
    return '$_temp0';
  }

  @override
  String get storageManagement => 'Gestione Archiviazione';

  @override
  String get storageBreakdown => 'Dettaglio Archiviazione';

  @override
  String get downloadedItems => 'Elementi Scaricati';

  @override
  String get storageLimit => 'Limite Archiviazione';

  @override
  String get noLimit => 'Nessun limite';

  @override
  String get deleteAllDownloads => 'Elimina Tutti i Download';

  @override
  String get deleteAllDownloadsWarning =>
      'Questo rimuoverà tutti i file media scaricati e non può essere annullato.';

  @override
  String get deleteAll => 'Elimina Tutto';

  @override
  String get deleteSelected => 'Elimina Selezionati';

  @override
  String deleteSelectedCount(int count) {
    return 'Eliminare $count elementi scaricati?';
  }

  @override
  String get musicAndAudiobooks => 'Musica e Audiolibri';

  @override
  String get images => 'Immagini';

  @override
  String get database => 'Database';

  @override
  String ofStorageLimit(String limit) {
    return 'di $limit limite';
  }

  @override
  String get settings => 'Impostazioni';

  @override
  String get authentication => 'Autenticazione';

  @override
  String get autoLoginServerManagement => 'Accesso automatico, gestione server';

  @override
  String get pinCode => 'Codice PIN';

  @override
  String get setUpPinCodeProtection => 'Imposta la protezione con codice PIN';

  @override
  String get parentalControls => 'Controllo Genitori';

  @override
  String get contentRatingRestrictions =>
      'Restrizioni classificazione contenuti';

  @override
  String get bitRateResolutionBehavior => 'Bitrate, risoluzione, comportamento';

  @override
  String get languageSizeAppearance => 'Lingua, dimensione, aspetto';

  @override
  String get qualityStorage => 'Qualità, archiviazione';

  @override
  String get serverSyncAndPluginStatus =>
      'Sincronizzazione server e stato plugin';

  @override
  String get mediaRequestIntegration => 'Integrazione richieste media';

  @override
  String get switchServer => 'Cambia Server';

  @override
  String get signOut => 'Esci';

  @override
  String get versionLicenses => 'Versione, licenze';

  @override
  String get account => 'Account';

  @override
  String get signInAndSecurity => 'Accesso e sicurezza';

  @override
  String get administration => 'Amministrazione';

  @override
  String get serverSettingsUsersLibraries =>
      'Impostazioni server, utenti, librerie';

  @override
  String get customization => 'Personalizzazione';

  @override
  String get themeAndLayout => 'Tema e layout';

  @override
  String get videoAndSubtitles => 'Video e sottotitoli';

  @override
  String get integrations => 'Integrazioni';

  @override
  String get pluginAndRequests => 'Plugin e richieste';

  @override
  String get customizeAccountPlaybackInterface =>
      'Personalizza account, riproduzione e comportamento interfaccia';

  @override
  String optionsCount(int count) {
    return '$count opzioni';
  }

  @override
  String get themeAndAppearance => 'Tema e Aspetto';

  @override
  String get focusBorderColor => 'Colore Bordo Focus';

  @override
  String get watchedIndicators => 'Indicatori Visti';

  @override
  String get always => 'Sempre';

  @override
  String get hideUnwatched => 'Nascondi Non Visti';

  @override
  String get episodesOnly => 'Solo Episodi';

  @override
  String get never => 'Mai';

  @override
  String get focusExpansionAnimation => 'Animazione Espansione Focus';

  @override
  String get scaleFocusedCards =>
      'Ingrandisci le schede e i riquadri in focus o hover';

  @override
  String get backgroundBackdrops => 'Sfondi';

  @override
  String get showBackdropImages =>
      'Mostra immagini di sfondo dietro i contenuti';

  @override
  String get seriesThumbnails => 'Miniature Serie';

  @override
  String get seriesThumbnailsDescription =>
      'Solo episodi: usa le immagini della serie corrispondenti al tipo di immagine di ogni riga';

  @override
  String get homeRowInfoOverlay => 'Overlay Info Righe Home';

  @override
  String get showTitleMetadataOnHomeRows =>
      'Mostra titolo e metadati durante la navigazione delle righe home';

  @override
  String get clockDisplay => 'Visualizzazione Orologio';

  @override
  String get inMenus => 'Nei Menu';

  @override
  String get inVideo => 'Nel Video';

  @override
  String get seasonalEffects => 'Effetti Stagionali';

  @override
  String get snow => 'Neve';

  @override
  String get fireworks => 'Fuochi d\'Artificio';

  @override
  String get confetti => 'Coriandoli';

  @override
  String get fallingLeaves => 'Foglie Cadenti';

  @override
  String get themeMusic => 'Musica Tema';

  @override
  String get playThemeMusicOnDetailPages =>
      'Riproduci musica tema nelle pagine di dettaglio';

  @override
  String get themeMusicVolume => 'Volume Musica Tema';

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String get themeMusicOnHomeRows => 'Musica Tema nelle Righe Home';

  @override
  String get playWhenBrowsingHomeScreen =>
      'Riproduci durante la navigazione della schermata home';

  @override
  String get detailsBackgroundBlur => 'Sfocatura Sfondo Dettagli';

  @override
  String pixelValue(int value) {
    return '${value}px';
  }

  @override
  String get browsingBackgroundBlur => 'Sfocatura Sfondo Navigazione';

  @override
  String get maxStreamingBitrate => 'Bitrate Massimo Streaming';

  @override
  String get maxResolution => 'Risoluzione Massima';

  @override
  String get playerZoomMode => 'Modalità Zoom Lettore';

  @override
  String get fit => 'Adatta';

  @override
  String get autoCrop => 'Ritaglio Automatico';

  @override
  String get stretch => 'Estendi';

  @override
  String get refreshRateSwitching => 'Cambio Frequenza Aggiornamento';

  @override
  String get disabled => 'Disabilitato';

  @override
  String get scaleOnTv => 'Scala su TV';

  @override
  String get scaleOnDevice => 'Scala su Dispositivo';

  @override
  String get trickPlay => 'Trick Play';

  @override
  String get showPreviewThumbnailsWhenSeeking =>
      'Mostra miniature di anteprima durante la ricerca';

  @override
  String get showDescriptionOnPause => 'Mostra Descrizione in Pausa';

  @override
  String get dimVideoShowOverview =>
      'Oscura il video e mostra il testo della panoramica in pausa';

  @override
  String get osdLockButton => 'Pulsante Blocco OSD';

  @override
  String get osdLockButtonDescription =>
      'Mostra un pulsante di blocco che blocca l\'input touch fino alla pressione prolungata';

  @override
  String get audioBehavior => 'Comportamento Audio';

  @override
  String get downmixToStereo => 'Downmix a Stereo';

  @override
  String get defaultAudioLanguage => 'Lingua Audio Predefinita';

  @override
  String get autoServerDefault => 'Automatico (Predefinito Server)';

  @override
  String get english => 'Inglese';

  @override
  String get spanish => 'Spagnolo';

  @override
  String get french => 'Francese';

  @override
  String get german => 'Tedesco';

  @override
  String get italian => 'Italiano';

  @override
  String get portuguese => 'Portoghese';

  @override
  String get japanese => 'Giapponese';

  @override
  String get korean => 'Coreano';

  @override
  String get chinese => 'Cinese';

  @override
  String get russian => 'Russo';

  @override
  String get arabic => 'Arabo';

  @override
  String get hindi => 'Hindi';

  @override
  String get dutch => 'Olandese';

  @override
  String get swedish => 'Svedese';

  @override
  String get norwegian => 'Norvegese';

  @override
  String get danish => 'Danese';

  @override
  String get finnish => 'Finlandese';

  @override
  String get polish => 'Polacco';

  @override
  String get ac3Passthrough => 'Passthrough AC3';

  @override
  String get trueHdSupport => 'Supporto TrueHD';

  @override
  String get enableTrueHdAudio =>
      'Abilita audio TrueHD (potrebbe non funzionare su tutte le piattaforme)';

  @override
  String get nightMode => 'Modalità Notturna';

  @override
  String get compressDynamicRange => 'Comprimi gamma dinamica';

  @override
  String get advancedMpv => 'mpv Avanzato';

  @override
  String get enableCustomMpvConf => 'Abilita mpv.conf Personalizzato';

  @override
  String get applyMpvConfBeforePlayback =>
      'Applica un mpv.conf specificato dall\'utente prima dell\'inizio della riproduzione';

  @override
  String get unsafeAdvancedMpvOptions => 'Opzioni mpv Avanzate Non Sicure';

  @override
  String get unsafeMpvOptionsDescription =>
      'Consenti un set più ampio di opzioni mpv. Potrebbe compromettere il comportamento della riproduzione.';

  @override
  String get nextUpAndQueuing => 'Prossimo e Coda';

  @override
  String get nextUpBehavior => 'Comportamento Prossimo';

  @override
  String get extended => 'Esteso';

  @override
  String get minimal => 'Minimale';

  @override
  String get nextUpTimeout => 'Timeout Prossimo';

  @override
  String secondsValue(int value) {
    return '${value}s';
  }

  @override
  String get mediaQueuing => 'Coda Media';

  @override
  String get autoQueueNextEpisodes =>
      'Accoda automaticamente i prossimi episodi';

  @override
  String get stillWatchingPrompt => 'Prompt Stai Ancora Guardando';

  @override
  String afterEpisodesAndHours(int episodes, double hours) {
    return 'Dopo $episodes episodi / ${hours}h';
  }

  @override
  String get resumeAndSkip => 'Riprendi e Salta';

  @override
  String get resumeRewind => 'Riavvolgimento Ripresa';

  @override
  String get fiveSeconds => '5 secondi';

  @override
  String get tenSeconds => '10 secondi';

  @override
  String get fifteenSeconds => '15 secondi';

  @override
  String get thirtySeconds => '30 secondi';

  @override
  String get skipBackLength => 'Durata Salto Indietro';

  @override
  String get skipForwardLength => 'Durata Salto Avanti';

  @override
  String get customMpvConfPath => 'Percorso mpv.conf Personalizzato';

  @override
  String get notSetMpvConf =>
      'Non impostato. Moonfin cercherà un mpv.conf predefinito nelle cartelle app/dati.';

  @override
  String get selectMpvConf => 'Seleziona mpv.conf';

  @override
  String get pathToMpvConf => '/percorso/a/mpv.conf';

  @override
  String get subtitleStyleDescription =>
      'Le impostazioni di stile (dimensione, colore, offset) si applicano ai sottotitoli testuali (SRT, VTT, TTML). I sottotitoli ASS/SSA usano il proprio stile incorporato a meno che \"Riproduzione Diretta ASS/SSA\" non sia disattivata. I sottotitoli bitmap (PGS, DVB, VobSub) non possono essere personalizzati.';

  @override
  String get defaultSubtitleLanguage => 'Lingua Sottotitoli Predefinita';

  @override
  String get defaultToNoSubtitles => 'Nessun Sottotitolo Predefinito';

  @override
  String get turnOffSubtitlesByDefault =>
      'Disattiva i sottotitoli per impostazione predefinita';

  @override
  String get subtitleSize => 'Dimensione Sottotitoli';

  @override
  String get textColor => 'Colore Testo';

  @override
  String get backgroundColor => 'Colore Sfondo';

  @override
  String get strokeColor => 'Colore Bordo';

  @override
  String get verticalOffset => 'Offset Verticale';

  @override
  String get pgsDirectPlay => 'Riproduzione Diretta PGS';

  @override
  String get directPlayPgsSubtitles => 'Riproduzione diretta sottotitoli PGS';

  @override
  String get assSsaDirectPlay => 'Riproduzione Diretta ASS/SSA';

  @override
  String get directPlayAssSsaSubtitles =>
      'Riproduzione diretta sottotitoli ASS/SSA';

  @override
  String get white => 'Bianco';

  @override
  String get black => 'Nero';

  @override
  String get yellow => 'Giallo';

  @override
  String get green => 'Verde';

  @override
  String get cyan => 'Ciano';

  @override
  String get red => 'Rosso';

  @override
  String get transparent => 'Trasparente';

  @override
  String get semiTransparentBlack => 'Nero Semi-trasparente';

  @override
  String get global => 'Globale';

  @override
  String get desktop => 'Desktop';

  @override
  String get mobile => 'Mobile';

  @override
  String get tv => 'TV';

  @override
  String loadedProfileSettings(String profile) {
    return 'Impostazioni profilo $profile caricate.';
  }

  @override
  String failedToLoadProfileSettings(String profile) {
    return 'Impossibile caricare le impostazioni del profilo $profile.';
  }

  @override
  String syncedSettingsToProfile(String profile) {
    return 'Impostazioni locali sincronizzate con il profilo $profile.';
  }

  @override
  String get customizationProfile => 'Profilo Personalizzazione';

  @override
  String get customizationProfileDescription =>
      'Scegli il profilo da caricare, modificare e sincronizzare. Globale si applica ovunque a meno che un profilo dispositivo non lo sovrascriva. Il punto verde indica il profilo del tuo dispositivo attuale.';

  @override
  String get loadProfile => 'Carica Profilo';

  @override
  String get syncing => 'Sincronizzazione...';

  @override
  String get syncToProfile => 'Sincronizza con Profilo';

  @override
  String get profileSyncHidden => 'Sincronizzazione Profilo Nascosta';

  @override
  String get enablePluginSyncDescription =>
      'Abilita la Sincronizzazione Plugin Server nelle impostazioni Plugin per mostrare i controlli del profilo qui.';

  @override
  String get quality => 'Qualità';

  @override
  String get defaultDownloadQuality => 'Qualità Download Predefinita';

  @override
  String get network => 'Rete';

  @override
  String get wifiOnlyDownloads => 'Download Solo WiFi';

  @override
  String get onlyDownloadOnWifi => 'Scarica solo quando connesso al WiFi';

  @override
  String get storage => 'Archiviazione';

  @override
  String get storageUsed => 'Spazio Utilizzato';

  @override
  String get manage => 'Gestisci';

  @override
  String get calculating => 'Calcolo in corso...';

  @override
  String get downloadLocation => 'Posizione Download';

  @override
  String get defaultLabel => 'Predefinito';

  @override
  String get saveToDownloadsFolder => 'Salva nella cartella Download';

  @override
  String get downloadsVisibleToOtherApps =>
      'Download/Moonfin — visibile ad altre app';

  @override
  String get dangerZone => 'Zona Pericolosa';

  @override
  String get clearAllDownloads => 'Cancella Tutti i Download';

  @override
  String get original => 'Originale';

  @override
  String get changeDownloadLocation => 'Cambia Posizione Download';

  @override
  String get changeDownloadLocationDescription =>
      'I nuovi download verranno salvati nella cartella selezionata. I download esistenti rimarranno nella loro posizione attuale e possono essere gestiti dalle impostazioni di Archiviazione.';

  @override
  String get confirm => 'Conferma';

  @override
  String get cannotWriteToFolder =>
      'Impossibile scrivere nella cartella selezionata. Scegli un\'altra posizione o concedi i permessi di archiviazione.';

  @override
  String get saveToDownloadsFolderQuestion =>
      'Salvare nella cartella Download?';

  @override
  String get saveToDownloadsFolderDescription =>
      'I media scaricati verranno salvati in Download/Moonfin sul tuo dispositivo. Questi file saranno visibili ad altre app come la galleria o il lettore musicale.\n\nI download esistenti rimarranno nella loro posizione attuale.';

  @override
  String get enable => 'Abilita';

  @override
  String get clearAllDownloadsWarning =>
      'Questo eliminerà tutti i media scaricati e non può essere annullato.';

  @override
  String get clearAll => 'Cancella Tutto';

  @override
  String get navigationStyle => 'Stile Navigazione';

  @override
  String get topBar => 'Barra Superiore';

  @override
  String get leftSidebar => 'Barra Laterale Sinistra';

  @override
  String get showShuffleButton => 'Mostra Pulsante Casuale';

  @override
  String get showGenresButton => 'Mostra Pulsante Generi';

  @override
  String get showFavoritesButton => 'Mostra Pulsante Preferiti';

  @override
  String get showLibrariesInToolbar => 'Mostra Librerie nella Barra Strumenti';

  @override
  String get navbarOpacity => 'Opacità Barra Navigazione';

  @override
  String get navbarColor => 'Colore Barra Navigazione';

  @override
  String get gray => 'Grigio';

  @override
  String get darkBlue => 'Blu Scuro';

  @override
  String get purple => 'Viola';

  @override
  String get teal => 'Verde Acqua';

  @override
  String get navy => 'Blu Navy';

  @override
  String get charcoal => 'Antracite';

  @override
  String get brown => 'Marrone';

  @override
  String get darkRed => 'Rosso Scuro';

  @override
  String get darkGreen => 'Verde Scuro';

  @override
  String get slate => 'Ardesia';

  @override
  String get indigo => 'Indaco';

  @override
  String get libraryDisplay => 'Visualizzazione Libreria';

  @override
  String get posterLabel => 'Poster';

  @override
  String get thumbnailLabel => 'Miniatura';

  @override
  String get bannerLabel => 'Banner';

  @override
  String get overridePerLibrarySettings =>
      'Sovrascrivi Impostazioni per Libreria';

  @override
  String get applyImageTypeToAllLibraries =>
      'Applica tipo immagine a tutte le librerie';

  @override
  String get multiServerLibraries => 'Librerie Multi-Server';

  @override
  String get showLibrariesFromAllServers =>
      'Mostra librerie da tutti i server connessi';

  @override
  String get enableFolderView => 'Abilita Visualizzazione Cartelle';

  @override
  String get showFolderBrowsingOption =>
      'Mostra opzione di navigazione cartelle';

  @override
  String get libraryVisibility => 'Visibilità Libreria';

  @override
  String get showInNavigation => 'Mostra nella navigazione';

  @override
  String get showInLatestMedia => 'Mostra negli ultimi media';

  @override
  String get sourceLibraries => 'Librerie Sorgente';

  @override
  String get sourceCollections => 'Collezioni Sorgente';

  @override
  String get excludedGenres => 'Generi Esclusi';

  @override
  String get selectAll => 'Seleziona Tutto';

  @override
  String itemsSelected(int count) {
    return '$count selezionati';
  }

  @override
  String get mediaBar => 'Barra Media';

  @override
  String get enableMediaBar => 'Abilita Barra Media';

  @override
  String get showFeaturedContentSlideshow =>
      'Mostra presentazione contenuti in evidenza nella home';

  @override
  String get contentType => 'Tipo Contenuto';

  @override
  String get moviesAndTvShows => 'Film e Serie TV';

  @override
  String get moviesOnly => 'Solo Film';

  @override
  String get tvShowsOnly => 'Solo Serie TV';

  @override
  String get itemCount => 'Numero Elementi';

  @override
  String get noneSelected => 'Nessuno selezionato';

  @override
  String get noneExcluded => 'Nessuno escluso';

  @override
  String get autoAdvance => 'Avanzamento Automatico';

  @override
  String get autoAdvanceSlides => 'Avanza automaticamente alla prossima slide';

  @override
  String get autoAdvanceInterval => 'Intervallo Avanzamento Automatico';

  @override
  String get trailerPreview => 'Anteprima Trailer';

  @override
  String get autoPlayTrailers =>
      'Riproduci automaticamente i trailer nella barra media dopo 3 secondi';

  @override
  String get episodePreview => 'Anteprima Episodio';

  @override
  String get episodePreviewDescription =>
      'Riproduci un\'anteprima in linea di 30 secondi sulle schede in focus, hover o pressione prolungata';

  @override
  String get previewAudio => 'Audio Anteprima';

  @override
  String get enablePreviewAudio =>
      'Abilita audio per le anteprime trailer e episodi';

  @override
  String get latestMedia => 'Ultimi Media';

  @override
  String get recentlyReleased => 'Usciti di Recente';

  @override
  String get myMedia => 'I Miei Media';

  @override
  String get myMediaSmall => 'I Miei Media (Piccolo)';

  @override
  String get continueWatching => 'Continua a Guardare';

  @override
  String get resumeAudio => 'Riprendi Audio';

  @override
  String get resumeBooks => 'Riprendi Libri';

  @override
  String get activeRecordings => 'Registrazioni Attive';

  @override
  String get playlists => 'Playlist';

  @override
  String get liveTV => 'TV Live';

  @override
  String get homeSections => 'Sezioni Home';

  @override
  String get resetToDefaults => 'Ripristina predefiniti';

  @override
  String get homeRowPosterSize => 'Dimensione Poster Righe Home';

  @override
  String get perRowImageTypeSelection => 'Selezione Tipo Immagine per Riga';

  @override
  String get configureImageTypeForEachRow =>
      'Configura il tipo di immagine per ogni riga home abilitata';

  @override
  String get mergeContinueWatchingAndNextUp =>
      'Unisci Continua a Guardare e Prossimo';

  @override
  String get combineBothRows =>
      'Combina entrambe le righe in un\'unica sezione home';

  @override
  String get perRowImageType => 'Tipo Immagine per Riga';

  @override
  String get perRowSettings => 'Impostazioni per Riga';

  @override
  String get autoLogin => 'Accesso Automatico';

  @override
  String get lastUser => 'Ultimo Utente';

  @override
  String get specificUser => 'Utente Specifico';

  @override
  String get alwaysAuthenticate => 'Autentica Sempre';

  @override
  String get requirePasswordWithToken =>
      'Richiedi password anche con token salvato';

  @override
  String get confirmExit => 'Conferma Uscita';

  @override
  String get showConfirmationBeforeExiting => 'Mostra conferma prima di uscire';

  @override
  String get blockContentWithRatings =>
      'Blocca contenuti con le seguenti classificazioni:';

  @override
  String get noContentRatingsFound =>
      'Nessuna classificazione dei contenuti trovata su questo server.';

  @override
  String get couldNotLoadServerRatings =>
      'Impossibile caricare le classificazioni del server. Vengono mostrate solo le classificazioni salvate.';

  @override
  String get couldNotRefreshRatings =>
      'Impossibile aggiornare le classificazioni dal server. Vengono mostrate le classificazioni salvate.';

  @override
  String get enablePinCode => 'Abilita Codice PIN';

  @override
  String get requirePinToAccess =>
      'Richiedi un PIN per accedere al tuo account';

  @override
  String get changePin => 'Cambia PIN';

  @override
  String get setNewPinCode => 'Imposta un nuovo codice PIN';

  @override
  String get removePin => 'Rimuovi PIN';

  @override
  String get removePinProtection => 'Rimuovi protezione codice PIN';

  @override
  String get screensaver => 'Screensaver';

  @override
  String get inAppScreensaver => 'Screensaver in App';

  @override
  String get enableBuiltInScreensaver => 'Abilita lo screensaver integrato';

  @override
  String get mode => 'Modalità';

  @override
  String get libraryArt => 'Arte Libreria';

  @override
  String get logo => 'Logo';

  @override
  String get clock => 'Orologio';

  @override
  String get timeout => 'Timeout';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get dimmingLevel => 'Livello Oscuramento';

  @override
  String get maxAgeRating => 'Classificazione Età Massima';

  @override
  String get any => 'Qualsiasi';

  @override
  String agePlusValue(int age) {
    return '$age+';
  }

  @override
  String get requireAgeRating => 'Richiedi Classificazione Età';

  @override
  String get onlyShowRatedContent => 'Mostra solo contenuti classificati';

  @override
  String get showClock => 'Mostra Orologio';

  @override
  String get displayClockDuringScreensaver =>
      'Mostra l\'orologio durante lo screensaver';

  @override
  String get rottenTomatoesCritics => 'Rotten Tomatoes (Critici)';

  @override
  String get rottenTomatoesAudience => 'Rotten Tomatoes (Pubblico)';

  @override
  String get imdb => 'IMDb';

  @override
  String get tmdb => 'TMDB';

  @override
  String get metacritic => 'Metacritic';

  @override
  String get metacriticUser => 'Metacritic (Utenti)';

  @override
  String get trakt => 'Trakt';

  @override
  String get letterboxd => 'Letterboxd';

  @override
  String get myAnimeList => 'MyAnimeList';

  @override
  String get aniList => 'AniList';

  @override
  String get communityRating => 'Valutazione Comunità';

  @override
  String get ratings => 'Valutazioni';

  @override
  String get additionalRatings => 'Valutazioni Aggiuntive';

  @override
  String get showMdbListAndTmdbRatings => 'Mostra valutazioni MDBList e TMDB';

  @override
  String get ratingLabels => 'Etichette Valutazione';

  @override
  String get showLabelsNextToIcons =>
      'Mostra etichette accanto alle icone di valutazione';

  @override
  String get ratingBadges => 'Badge Valutazione';

  @override
  String get showDecorativeBadges =>
      'Mostra badge decorativi dietro le valutazioni';

  @override
  String get episodeRatings => 'Valutazioni Episodi';

  @override
  String get showRatingsOnEpisodes => 'Mostra valutazioni sui singoli episodi';

  @override
  String get ratingSources => 'Fonti Valutazione';

  @override
  String get ratingSourcesDescription =>
      'Abilita e riordina le fonti di valutazione mostrate nell\'app';

  @override
  String get pluginLabel => 'Plugin';

  @override
  String get pluginDetected => 'Plugin Rilevato';

  @override
  String get pluginNotDetected => 'Plugin Non Rilevato';

  @override
  String get pluginDetectedDescription =>
      'Plugin server rilevato. La sincronizzazione è abilitata automaticamente la prima volta che il plugin viene trovato.';

  @override
  String get pluginNotDetectedDescription =>
      'Plugin server attualmente non rilevato. Le impostazioni locali utilizzano ancora i valori salvati o i predefiniti integrati.';

  @override
  String pluginStatusVersion(String status, String version) {
    return '$status\nVersione: $version';
  }

  @override
  String get availableServices => 'Servizi Disponibili';

  @override
  String get serverPluginSync => 'Sincronizzazione Plugin Server';

  @override
  String get syncSettingsWithPlugin =>
      'Sincronizza impostazioni con il plugin server';

  @override
  String get whatSyncControls => 'Cosa controlla la sincronizzazione';

  @override
  String get syncControlsDescription =>
      'La sincronizzazione controlla solo se le impostazioni supportate dal plugin vengono inviate e ricevute dal server. La selezione del profilo e le azioni di sincronizzazione del profilo sono nelle impostazioni di Personalizzazione quando la sincronizzazione del plugin è abilitata.';

  @override
  String get recentRequests => 'Richieste Recenti';

  @override
  String get recentlyAdded => 'Aggiunti di Recente';

  @override
  String get trending => 'Di Tendenza';

  @override
  String get popularMovies => 'Film Popolari';

  @override
  String get movieGenres => 'Generi Film';

  @override
  String get upcomingMovies => 'Film in Arrivo';

  @override
  String get studios => 'Studi';

  @override
  String get popularSeries => 'Serie Popolari';

  @override
  String get seriesGenres => 'Generi Serie';

  @override
  String get upcomingSeries => 'Serie in Arrivo';

  @override
  String get networks => 'Reti';

  @override
  String get resetRowsToDefaults => 'Ripristina righe predefinite';

  @override
  String get enableSeerr => 'Abilita Seerr';

  @override
  String get showSeerrInNavigation =>
      'Mostra Seerr nella navigazione (richiede plugin server)';

  @override
  String get seerrUnavailable =>
      'Non disponibile perché il supporto Seerr del plugin server è disabilitato.';

  @override
  String get nsfwFilter => 'Filtro NSFW';

  @override
  String get hideAdultContent => 'Nascondi contenuti per adulti nei risultati';

  @override
  String loggedInAs(String username) {
    return 'Connesso come: $username';
  }

  @override
  String get discoverRows => 'Righe Scoperta';

  @override
  String get discoverRowsDescriptionPlugin =>
      'Trascina per riordinare. Abilita o disabilita le righe. L\'ordine delle righe abilitate si sincronizza con il plugin Moonfin.';

  @override
  String get discoverRowsDescription =>
      'Trascina per riordinare. Abilita o disabilita le righe.';

  @override
  String get enabled => 'Abilitato';

  @override
  String get hidden => 'Nascosto';

  @override
  String get aboutTitle => 'Informazioni';

  @override
  String versionValue(String version) {
    return 'Versione $version';
  }

  @override
  String get openSourceLicenses => 'Licenze Open Source';

  @override
  String get sourceCode => 'Codice Sorgente';

  @override
  String get checkForUpdatesNow => 'Controlla Aggiornamenti Ora';

  @override
  String get checksLatestDesktopRelease =>
      'Controlla l\'ultima versione desktop per questa piattaforma';

  @override
  String get youAreUpToDate => 'Sei aggiornato.';

  @override
  String get couldNotCheckForUpdates =>
      'Impossibile controllare gli aggiornamenti al momento.';

  @override
  String get noCompatibleUpdate =>
      'Nessun pacchetto di aggiornamento compatibile trovato per questa piattaforma.';

  @override
  String get updateChecksNotSupported =>
      'Il controllo aggiornamenti non è supportato su questa piattaforma.';

  @override
  String get updateNotificationsDisabled =>
      'Le notifiche di aggiornamento sono disabilitate.';

  @override
  String get pleaseWaitBeforeChecking =>
      'Attendi prima di controllare di nuovo.';

  @override
  String get latestUpdateAlreadyShown =>
      'L\'ultimo aggiornamento è già stato mostrato.';

  @override
  String get updateAvailable => 'Aggiornamento disponibile.';

  @override
  String updateAvailableVersion(String version) {
    return 'Aggiornamento disponibile: v$version';
  }

  @override
  String get updateNotifications => 'Notifiche Aggiornamento';

  @override
  String get showWhenUpdatesAvailable =>
      'Mostra quando sono disponibili aggiornamenti';

  @override
  String get navigation => 'Navigazione';

  @override
  String get watchedIndicatorsBackdrops => 'Indicatori visti, sfondi';

  @override
  String get focusColorWatchedIndicatorsBackdrops =>
      'Colore focus, indicatori visti, sfondi';

  @override
  String get navbarStyleToolbarAppearance =>
      'Stile barra navigazione, pulsanti barra strumenti, aspetto';

  @override
  String get reorderToggleHomeRows => 'Riordina e attiva/disattiva righe home';

  @override
  String get featuredContentAppearance => 'Contenuti in evidenza, aspetto';

  @override
  String get posterSizeImageTypeFolderView =>
      'Dimensione poster, tipo immagine, visualizzazione cartelle';

  @override
  String get mdbListTmdbRatingSources => 'MDBList, TMDB e fonti di valutazione';

  @override
  String gbValue(String value) {
    return '$value GB';
  }

  @override
  String get clear => 'Cancella';

  @override
  String get browse => 'Sfoglia';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get seerrAvailableStatus => 'Disponibile';

  @override
  String get seerrRequestedStatus => 'Richiesto';

  @override
  String itemsCount(int count) {
    return '$count Elementi';
  }

  @override
  String get seerrSettings => 'Impostazioni Seerr';

  @override
  String get requestMore => 'Richiedi Altro';

  @override
  String get request => 'Richiesta';

  @override
  String get cancelRequest => 'Annulla Richiesta';

  @override
  String get playInMoonfin => 'Riproduci in Moonfin';

  @override
  String requestedByName(String name) {
    return 'Richiesto da $name';
  }

  @override
  String get approve => 'Approva';

  @override
  String get declineAction => 'Rifiuta';

  @override
  String get similar => 'Simili';

  @override
  String get recommendations => 'Raccomandazioni';

  @override
  String cancelRequestForTitle(String title) {
    return 'Annullare la richiesta per \"$title\"?';
  }

  @override
  String cancelCountRequestsForTitle(int count, String title) {
    return 'Annullare $count richieste per \"$title\"?';
  }

  @override
  String get keep => 'Mantieni';

  @override
  String get itemNotFoundInLibrary =>
      'Elemento non trovato nella tua libreria Moonfin';

  @override
  String get errorSearchingLibrary => 'Errore nella ricerca della libreria';

  @override
  String budgetAmount(String amount) {
    return 'Budget: \\\$$amount';
  }

  @override
  String revenueAmount(String amount) {
    return 'Incasso: \\\$$amount';
  }

  @override
  String seasonsCount(int count, String label) {
    return '$count $label';
  }

  @override
  String requestSeriesOrMovie(String type) {
    return 'Richiedi $type';
  }

  @override
  String get submitRequest => 'Invia Richiesta';

  @override
  String get allSeasons => 'Tutte le Stagioni';

  @override
  String get advancedOptions => 'Opzioni Avanzate';

  @override
  String get noServiceServersConfigured =>
      'Nessun server di servizio configurato';

  @override
  String get server => 'Server';

  @override
  String get qualityProfile => 'Profilo Qualità';

  @override
  String get rootFolder => 'Cartella Principale';

  @override
  String get showMore => 'Mostra Altro';

  @override
  String get appearances => 'Apparizioni';

  @override
  String get crewSection => 'Troupe';

  @override
  String ageValue(int age) {
    return 'età $age';
  }

  @override
  String get noRequests => 'Nessuna richiesta';

  @override
  String get pendingStatus => 'In attesa';

  @override
  String get declinedStatus => 'Rifiutato';

  @override
  String get partiallyAvailable => 'Parzialmente Disponibile';

  @override
  String get downloadingStatus => 'In download';

  @override
  String get approvedStatus => 'Approvato';

  @override
  String get access => 'Accesso';

  @override
  String get add => 'Aggiungi';

  @override
  String get address => 'Indirizzo';

  @override
  String get analytics => 'Analisi';

  @override
  String get catalog => 'Catalogo';

  @override
  String get content => 'Contenuto';

  @override
  String get copy => 'Copia';

  @override
  String get create => 'Crea';

  @override
  String get disable => 'Disabilita';

  @override
  String get done => 'Fatto';

  @override
  String get edit => 'Modifica';

  @override
  String get encoding => 'Codifica';

  @override
  String get error => 'Errore';

  @override
  String get forward => 'Avanti';

  @override
  String get general => 'Generale';

  @override
  String get go => 'Vai';

  @override
  String get install => 'Installa';

  @override
  String get installed => 'Installato';

  @override
  String get interval => 'Intervallo';

  @override
  String get name => 'Nome';

  @override
  String get networking => 'Rete';

  @override
  String get next => 'Successivo';

  @override
  String get path => 'Percorso';

  @override
  String get paused => 'In pausa';

  @override
  String get permissions => 'Permessi';

  @override
  String get processing => 'Elaborazione';

  @override
  String get profile => 'Profilo';

  @override
  String get provider => 'Provider';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get remote => 'Remoto';

  @override
  String get rename => 'Rinomina';

  @override
  String get revoke => 'Revoca';

  @override
  String get role => 'Ruolo';

  @override
  String get root => 'Radice';

  @override
  String get run => 'Esegui';

  @override
  String get search => 'Cerca';

  @override
  String get select => 'Seleziona';

  @override
  String get send => 'Invia';

  @override
  String get sessions => 'Sessioni';

  @override
  String get set => 'Imposta';

  @override
  String get status => 'Stato';

  @override
  String get stop => 'Ferma';

  @override
  String get streaming => 'Streaming';

  @override
  String get time => 'Ora';

  @override
  String get trickplay => 'Trickplay';

  @override
  String get uninstall => 'Disinstalla';

  @override
  String get up => 'Su';

  @override
  String get update => 'Aggiorna';

  @override
  String get upload => 'Carica';

  @override
  String get unmute => 'Riattiva Audio';

  @override
  String get mute => 'Silenzia';

  @override
  String get branding => 'Branding';

  @override
  String get adminDrawerDashboard => 'Dashboard';

  @override
  String get adminDrawerAnalytics => 'Analisi';

  @override
  String get adminDrawerSettings => 'Impostazioni';

  @override
  String get adminDrawerBranding => 'Branding';

  @override
  String get adminDrawerUsers => 'Utenti';

  @override
  String get adminDrawerLibraries => 'Librerie';

  @override
  String get adminDrawerTranscoding => 'Transcodifica';

  @override
  String get adminDrawerResume => 'Ripresa';

  @override
  String get adminDrawerStreaming => 'Streaming';

  @override
  String get adminDrawerTrickplay => 'Trickplay';

  @override
  String get adminDrawerDevices => 'Dispositivi';

  @override
  String get adminDrawerActivity => 'Attività';

  @override
  String get adminDrawerNetworking => 'Rete';

  @override
  String get adminDrawerApiKeys => 'Chiavi API';

  @override
  String get adminDrawerBackups => 'Backup';

  @override
  String get adminDrawerLogs => 'Log';

  @override
  String get adminDrawerScheduledTasks => 'Attività Pianificate';

  @override
  String get adminDrawerPlugins => 'Plugin';

  @override
  String get adminDrawerRepositories => 'Repository';

  @override
  String get adminDrawerLiveTv => 'TV Live';

  @override
  String get adminExitTooltip => 'Esci dall\'Amministrazione';

  @override
  String get adminDashboardLoadFailed => 'Impossibile caricare la dashboard';

  @override
  String get adminMediaOverview => 'Panoramica Media';

  @override
  String get adminMediaTotalsError =>
      'Impossibile caricare i totali media del server.';

  @override
  String get adminMediaOverviewSubtitle =>
      'Una panoramica rapida su quanti contenuti ci sono su questo server.';

  @override
  String adminPluginUpdatesAvailable(int count) {
    return 'Aggiornamenti plugin disponibili: $count';
  }

  @override
  String adminPluginsRequiringRestart(int count) {
    return 'Plugin che richiedono riavvio: $count';
  }

  @override
  String adminFailedScheduledTasks(int count) {
    return 'Attività pianificate fallite: $count';
  }

  @override
  String adminRecentAlertEntries(int count) {
    return 'Voci di avviso/errore recenti: $count';
  }

  @override
  String get analyticsMediaDistribution => 'Distribuzione Media';

  @override
  String get analyticsVideoCodecs => 'Codec Video';

  @override
  String get analyticsAudioCodecs => 'Codec Audio';

  @override
  String get analyticsContainers => 'Contenitori';

  @override
  String get analyticsTopGenres => 'Generi Principali';

  @override
  String get analyticsReleaseYears => 'Anni di Uscita';

  @override
  String get analyticsContentRatings => 'Classificazioni Contenuti';

  @override
  String get analyticsRuntimeBuckets => 'Fasce Durata';

  @override
  String get analyticsFileFormats => 'Formati File';

  @override
  String get analyticsNoData => 'Nessun Dato Disponibile.';

  @override
  String get adminServerInfo => 'Info Server';

  @override
  String get adminRestartPending => 'Riavvio in Attesa';

  @override
  String get adminServerPaths => 'Percorsi Server';

  @override
  String get adminServerActions => 'Azioni Server';

  @override
  String get adminRestartServer => 'Riavvia Server';

  @override
  String get adminShutdownServer => 'Spegni Server';

  @override
  String get adminScanLibraries => 'Scansiona Librerie';

  @override
  String get adminLibraryScanStarted => 'Scansione libreria avviata';

  @override
  String errorGeneric(String error) {
    return 'Errore: $error';
  }

  @override
  String get adminServerRebootInProgress => 'Riavvio server in corso';

  @override
  String get adminServerRebootMessage =>
      'Riavvio server in corso, riavvia Moonfin';

  @override
  String get adminActiveSessions => 'Sessioni Attive';

  @override
  String get adminSessionsLoadFailed => 'Impossibile caricare le sessioni';

  @override
  String get adminNoActiveSessions => 'Nessuna sessione attiva';

  @override
  String get adminRecentActivity => 'Attività Recente';

  @override
  String get adminNoRecentActivity => 'Nessuna attività recente';

  @override
  String adminCommandFailed(String error) {
    return 'Comando fallito: $error';
  }

  @override
  String get adminSendMessage => 'Invia Messaggio';

  @override
  String get adminMessageTextHint => 'Testo del messaggio';

  @override
  String get adminSetVolume => 'Imposta Volume';

  @override
  String get sessionPrev => 'Precedente';

  @override
  String get sessionRewind => 'Riavvolgi';

  @override
  String get sessionForward => 'Avanti';

  @override
  String get sessionNext => 'Successivo';

  @override
  String get sessionVolumeDown => 'Vol –';

  @override
  String get sessionVolumeUp => 'Vol +';

  @override
  String get nowPlaying => 'In Riproduzione';

  @override
  String get volume => 'Volume';

  @override
  String get actions => 'Azioni';

  @override
  String get videoCodec => 'Codec Video';

  @override
  String get audioCodec => 'Codec Audio';

  @override
  String get hwAccel => 'Accel. HW';

  @override
  String get completion => 'Completamento';

  @override
  String get direct => 'Diretto';

  @override
  String get adminDisconnect => 'Disconnetti';

  @override
  String get adminClearDates => 'Cancella date';

  @override
  String adminActivityLoadFailed(String error) {
    return 'Impossibile caricare il registro attività: $error';
  }

  @override
  String get adminNoActivityEntries => 'Nessuna voce di attività';

  @override
  String get adminEditDeviceName => 'Modifica Nome Dispositivo';

  @override
  String get adminCustomName => 'Nome Personalizzato';

  @override
  String get adminDeviceNameUpdated => 'Nome dispositivo aggiornato';

  @override
  String adminDeviceUpdateFailed(String error) {
    return 'Impossibile aggiornare il dispositivo: $error';
  }

  @override
  String get adminDeleteDevice => 'Elimina Dispositivo';

  @override
  String get adminDeviceDeleted => 'Dispositivo eliminato';

  @override
  String adminDeviceDeleteFailed(String error) {
    return 'Impossibile eliminare il dispositivo: $error';
  }

  @override
  String get adminDevicesLoadFailed => 'Impossibile caricare i dispositivi';

  @override
  String get adminSearchDevices => 'Cerca dispositivi';

  @override
  String get adminThisDevice => 'Questo Dispositivo';

  @override
  String get adminEditName => 'Modifica Nome';

  @override
  String get adminLibrariesLoadFailed => 'Impossibile caricare le librerie';

  @override
  String get adminNoLibraries => 'Nessuna libreria configurata';

  @override
  String get adminScanAllLibraries => 'Scansiona Tutte le Librerie';

  @override
  String get adminAddLibrary => 'Aggiungi Libreria';

  @override
  String adminScanFailed(String error) {
    return 'Impossibile avviare la scansione: $error';
  }

  @override
  String get adminRenameLibrary => 'Rinomina Libreria';

  @override
  String get adminNewName => 'Nuovo nome';

  @override
  String adminLibraryRenamed(String name) {
    return 'Libreria rinominata in \"$name\"';
  }

  @override
  String adminRenameFailed(String error) {
    return 'Impossibile rinominare: $error';
  }

  @override
  String get adminDeleteLibrary => 'Elimina Libreria';

  @override
  String adminLibraryDeleted(String name) {
    return 'Libreria \"$name\" eliminata';
  }

  @override
  String adminLibraryDeleteFailed(String error) {
    return 'Impossibile eliminare la libreria: $error';
  }

  @override
  String adminAddPathFailed(String error) {
    return 'Impossibile aggiungere il percorso: $error';
  }

  @override
  String get adminRemovePath => 'Rimuovi Percorso';

  @override
  String adminRemovePathConfirm(String path) {
    return 'Rimuovere \"$path\" da questa libreria?';
  }

  @override
  String adminRemovePathFailed(String error) {
    return 'Impossibile rimuovere il percorso: $error';
  }

  @override
  String get adminLibraryOptionsSaved => 'Opzioni libreria salvate';

  @override
  String adminLibraryOptionsSaveFailed(String error) {
    return 'Impossibile salvare le opzioni: $error';
  }

  @override
  String get adminLibraryLoadFailed => 'Impossibile caricare la libreria';

  @override
  String get adminNoMediaPaths => 'Nessun percorso media configurato';

  @override
  String get adminAddPath => 'Aggiungi Percorso';

  @override
  String get adminBrowseFilesystem => 'Sfoglia il filesystem del server:';

  @override
  String get adminSaveOptions => 'Salva Opzioni';

  @override
  String get adminPreferredMetadataLanguage => 'Lingua metadati preferita';

  @override
  String get adminMetadataLanguageHint => 'es. it, en, de';

  @override
  String get adminMetadataCountryCode => 'Codice paese metadati';

  @override
  String get adminMetadataCountryHint => 'es. IT, US, DE';

  @override
  String get adminLibraryNameRequired =>
      'Il nome della libreria è obbligatorio';

  @override
  String adminLibraryCreateFailed(String error) {
    return 'Impossibile creare la libreria: $error';
  }

  @override
  String get adminLibraryName => 'Nome Libreria';

  @override
  String get adminSelectedPaths => 'Percorsi Selezionati:';

  @override
  String get adminNoPathsAdded =>
      'Nessun percorso aggiunto (possono essere aggiunti in seguito)';

  @override
  String get adminCreateLibrary => 'Crea Libreria';

  @override
  String get paths => 'Percorsi:';

  @override
  String get adminDisableUser => 'Disabilita Utente';

  @override
  String get adminEnableUser => 'Abilita Utente';

  @override
  String adminDisableUserConfirm(String name) {
    return 'Disabilitare $name? Non potrà più accedere.';
  }

  @override
  String adminEnableUserConfirm(String name) {
    return 'Abilitare $name? Potrà accedere di nuovo.';
  }

  @override
  String adminUserDisabled(String name) {
    return 'Utente \"$name\" disabilitato';
  }

  @override
  String adminUserEnabled(String name) {
    return 'Utente \"$name\" abilitato';
  }

  @override
  String adminUserPolicyUpdateFailed(String error) {
    return 'Impossibile aggiornare le politiche utente: $error';
  }

  @override
  String get adminUsersLoadFailed => 'Impossibile caricare gli utenti';

  @override
  String get adminSearchUsers => 'Cerca utenti';

  @override
  String get adminEditUser => 'Modifica Utente';

  @override
  String get adminAddUser => 'Aggiungi Utente';

  @override
  String adminUserCreateFailed(String error) {
    return 'Impossibile creare l\'utente: $error';
  }

  @override
  String get adminCreateUser => 'Crea Utente';

  @override
  String get adminPasswordOptional => 'Password (opzionale)';

  @override
  String get adminUsernameRequired => 'Il nome utente non può essere vuoto';

  @override
  String get adminNoProfileChanges => 'Nessuna modifica al profilo da salvare';

  @override
  String get adminProfileSaved => 'Profilo salvato';

  @override
  String adminSaveFailed(String error) {
    return 'Impossibile salvare: $error';
  }

  @override
  String get adminPermissionsSaved => 'Permessi salvati';

  @override
  String get adminPasswordsMismatch => 'Le password non corrispondono';

  @override
  String adminFailed(String error) {
    return 'Fallito: $error';
  }

  @override
  String get adminUserLoadFailed => 'Impossibile caricare l\'utente';

  @override
  String get adminBackToUsers => 'Torna agli Utenti';

  @override
  String get adminSaveProfile => 'Salva Profilo';

  @override
  String get adminDeleteUser => 'Elimina Utente';

  @override
  String get admin => 'Amministrazione';

  @override
  String get adminFullAccessWarning =>
      'Gli amministratori hanno accesso completo al server. Concedi con cautela.';

  @override
  String get administrator => 'Amministratore';

  @override
  String get adminHiddenUser => 'Utente nascosto';

  @override
  String get adminAllowMediaPlayback => 'Consenti riproduzione media';

  @override
  String get adminAllowAudioTranscoding => 'Consenti transcodifica audio';

  @override
  String get adminAllowVideoTranscoding => 'Consenti transcodifica video';

  @override
  String get adminAllowRemuxing => 'Consenti remuxing';

  @override
  String get adminForceRemoteTranscoding =>
      'Forza transcodifica sorgente remota';

  @override
  String get adminAllowContentDeletion => 'Consenti eliminazione contenuti';

  @override
  String get adminAllowContentDownloading => 'Consenti download contenuti';

  @override
  String get adminAllowPublicSharing => 'Consenti condivisione pubblica';

  @override
  String get adminAllowRemoteControl =>
      'Consenti controllo remoto di altri utenti';

  @override
  String get adminAllowSharedDeviceControl =>
      'Consenti controllo dispositivo condiviso';

  @override
  String get adminAllowRemoteAccess => 'Consenti accesso remoto';

  @override
  String get adminRemoteBitrateLimit => 'Limite bitrate client remoto (bps)';

  @override
  String get adminLeaveEmptyNoLimit => 'Lascia vuoto per nessun limite';

  @override
  String get adminMaxActiveSessions => 'Sessioni attive massime';

  @override
  String get adminAllowLiveTvAccess => 'Consenti accesso TV Live';

  @override
  String get adminAllowLiveTvManagement => 'Consenti gestione TV Live';

  @override
  String get adminAllowCollectionManagement => 'Consenti gestione collezioni';

  @override
  String get adminAllowSubtitleManagement => 'Consenti gestione sottotitoli';

  @override
  String get adminAllowLyricManagement => 'Consenti gestione testi';

  @override
  String get adminSavePermissions => 'Salva Permessi';

  @override
  String get adminEnableAllLibraryAccess =>
      'Abilita accesso a tutte le librerie';

  @override
  String get adminSaveAccess => 'Salva Accesso';

  @override
  String get adminChangePassword => 'Cambia Password';

  @override
  String get adminNewPassword => 'Nuova Password';

  @override
  String get adminConfirmPassword => 'Conferma Password';

  @override
  String get adminSetPassword => 'Imposta Password';

  @override
  String get adminResetPassword => 'Reimposta Password';

  @override
  String adminDeleteUserConfirm(String name) {
    return 'Sei sicuro di voler eliminare $name?';
  }

  @override
  String adminUserDeleted(String name) {
    return 'Utente \"$name\" eliminato';
  }

  @override
  String adminUserDeleteFailed(String error) {
    return 'Impossibile eliminare l\'utente: $error';
  }

  @override
  String get adminCreateApiKey => 'Crea Chiave API';

  @override
  String get adminAppName => 'Nome app';

  @override
  String get adminApiKeyCreated => 'Chiave API Creata';

  @override
  String get adminApiKeyCreatedNoToken =>
      'Chiave creata con successo. Il server non ha restituito il token. Controlla le chiavi API del server.';

  @override
  String get adminKeyCopied => 'Chiave copiata negli appunti';

  @override
  String adminApiKeyCreateFailed(String error) {
    return 'Impossibile creare la chiave: $error';
  }

  @override
  String get adminKeyTokenMissing =>
      'Token chiave mancante nella risposta del server';

  @override
  String get adminRevokeApiKey => 'Revoca Chiave API';

  @override
  String adminRevokeKeyConfirm(String name) {
    return 'Revocare la chiave per $name?';
  }

  @override
  String get adminApiKeyRevoked => 'Chiave API revocata';

  @override
  String adminApiKeyRevokeFailed(String error) {
    return 'Impossibile revocare la chiave: $error';
  }

  @override
  String get adminApiKeysLoadFailed => 'Impossibile caricare le chiavi API';

  @override
  String get adminCreateKey => 'Crea Chiave';

  @override
  String get adminNoApiKeys => 'Nessuna chiave API trovata';

  @override
  String get adminCreatingBackup => 'Creazione backup...';

  @override
  String get adminBackupCreated => 'Backup creato con successo';

  @override
  String adminBackupCreateFailed(String error) {
    return 'Impossibile creare il backup: $error';
  }

  @override
  String get adminBackupPathMissing =>
      'Percorso backup mancante nella risposta del server';

  @override
  String adminBackupManifest(String name) {
    return 'Manifesto: $name';
  }

  @override
  String adminManifestLoadFailed(String error) {
    return 'Impossibile caricare il manifesto: $error';
  }

  @override
  String get adminConfirmRestore => 'Conferma Ripristino';

  @override
  String get adminRestoringBackup => 'Ripristino backup...';

  @override
  String adminRestoreFailed(String error) {
    return 'Impossibile ripristinare il backup: $error';
  }

  @override
  String get adminBackupsLoadFailed => 'Impossibile caricare i backup';

  @override
  String get adminCreateBackup => 'Crea Backup';

  @override
  String get adminNoBackups => 'Nessun backup trovato';

  @override
  String get adminViewDetails => 'Visualizza Dettagli';

  @override
  String get restore => 'Ripristina';

  @override
  String get adminLogsLoadFailed => 'Impossibile caricare i log del server';

  @override
  String get adminNoLogFiles => 'Nessun file di log trovato';

  @override
  String get adminLogCopied => 'Log copiato negli appunti';

  @override
  String get adminSaveLogFile => 'Salva file log';

  @override
  String adminSavedTo(String path) {
    return 'Salvato in $path';
  }

  @override
  String adminFileSaveFailed(String error) {
    return 'Impossibile salvare il file: $error';
  }

  @override
  String adminLogFileLoadFailed(String fileName) {
    return 'Impossibile caricare $fileName';
  }

  @override
  String get adminSearchInLog => 'Cerca nel log';

  @override
  String get adminNoMatchingLines => 'Nessuna riga corrispondente';

  @override
  String adminTasksLoadFailed(String error) {
    return 'Impossibile caricare le attività: $error';
  }

  @override
  String get adminNoScheduledTasks => 'Nessuna attività pianificata trovata';

  @override
  String get adminNoTasksMatchFilter =>
      'Nessuna attività corrisponde al filtro attuale';

  @override
  String adminTaskStartFailed(String error) {
    return 'Impossibile avviare l\'attività: $error';
  }

  @override
  String adminTaskStopFailed(String error) {
    return 'Impossibile fermare l\'attività: $error';
  }

  @override
  String adminTaskLoadFailed(String error) {
    return 'Impossibile caricare l\'attività: $error';
  }

  @override
  String get adminRunNow => 'Esegui Ora';

  @override
  String adminTriggerRemoveFailed(String error) {
    return 'Impossibile rimuovere il trigger: $error';
  }

  @override
  String adminTriggerAddFailed(String error) {
    return 'Impossibile aggiungere il trigger: $error';
  }

  @override
  String get adminLastExecution => 'Ultima Esecuzione';

  @override
  String get adminTriggers => 'Trigger';

  @override
  String get adminAddTrigger => 'Aggiungi Trigger';

  @override
  String get adminNoTriggers => 'Nessun trigger configurato';

  @override
  String get adminTriggerType => 'Tipo Trigger';

  @override
  String get adminTimeLimit => 'Limite di tempo (opzionale)';

  @override
  String get adminNoLimit => 'Nessun limite';

  @override
  String adminHours(String hours) {
    return '$hours ore';
  }

  @override
  String get adminDayOfWeek => 'Giorno della settimana';

  @override
  String get adminSearchPlugins => 'Cerca plugin...';

  @override
  String adminPluginToggleFailed(String error) {
    return 'Impossibile attivare/disattivare il plugin: $error';
  }

  @override
  String get adminUninstallPlugin => 'Disinstalla Plugin';

  @override
  String adminUninstallPluginConfirm(String name) {
    return 'Sei sicuro di voler disinstallare \"$name\"?';
  }

  @override
  String adminPluginUninstallFailed(String error) {
    return 'Impossibile disinstallare il plugin: $error';
  }

  @override
  String adminPackageInstallFailed(String error) {
    return 'Impossibile installare il pacchetto: $error';
  }

  @override
  String adminPluginUpdateFailed(String error) {
    return 'Impossibile installare l\'aggiornamento: $error';
  }

  @override
  String adminPluginsLoadFailed(String error) {
    return 'Impossibile caricare i plugin: $error';
  }

  @override
  String get adminNoPluginsMatchSearch =>
      'Nessun plugin corrisponde alla ricerca';

  @override
  String get adminNoPluginsInstalled => 'Nessun plugin installato';

  @override
  String adminInstallUpdate(String version) {
    return 'Installa aggiornamento (v$version)';
  }

  @override
  String adminCatalogLoadFailed(String error) {
    return 'Impossibile caricare il catalogo: $error';
  }

  @override
  String get adminNoPackagesMatchSearch =>
      'Nessun pacchetto corrisponde alla ricerca';

  @override
  String get adminNoPackagesAvailable => 'Nessun pacchetto disponibile';

  @override
  String get adminExperimentalIntegration => 'Integrazione Sperimentale';

  @override
  String get adminExperimentalWarning =>
      'L\'integrazione delle impostazioni dei plugin è ancora sperimentale. Alcune pagine di impostazioni potrebbero non essere visualizzate correttamente.';

  @override
  String get continueAction => 'Continua';

  @override
  String adminPluginRemoveAfterRestart(String name) {
    return '\"$name\" verrà rimosso dopo il riavvio del server';
  }

  @override
  String adminUninstallFailed(String error) {
    return 'Impossibile disinstallare: $error';
  }

  @override
  String adminPluginUpdating(String name, String version) {
    return 'Aggiornamento di \"$name\" alla v$version...';
  }

  @override
  String get adminMissingAuthToken =>
      'Impossibile aprire le impostazioni: token di autenticazione mancante.';

  @override
  String adminPluginLoadFailed(String error) {
    return 'Impossibile caricare il plugin: $error';
  }

  @override
  String get adminPluginNotFound => 'Plugin non trovato';

  @override
  String adminPluginVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get adminEnablePlugin => 'Abilita Plugin';

  @override
  String get adminPluginSettingsPage => 'Pagina impostazioni plugin';

  @override
  String get adminRevisionHistory => 'Cronologia Revisioni';

  @override
  String get adminNoChangelog => 'Nessun changelog disponibile.';

  @override
  String get adminRemoveRepository => 'Rimuovi Repository';

  @override
  String adminRemoveRepositoryConfirm(String name) {
    return 'Sei sicuro di voler rimuovere \"$name\"?';
  }

  @override
  String adminRepositoriesSaveFailed(String error) {
    return 'Impossibile salvare i repository: $error';
  }

  @override
  String adminRepositoriesLoadFailed(String error) {
    return 'Impossibile caricare i repository: $error';
  }

  @override
  String get adminRepositoryNameHint => 'es. Jellyfin Stabile';

  @override
  String get adminRepositoryUrl => 'URL Repository';

  @override
  String get adminAddEntry => 'Aggiungi voce';

  @override
  String get adminInvalidUrl => 'URL non valido';

  @override
  String adminPluginSettingsLoadFailed(String error) {
    return 'Impossibile caricare le impostazioni del plugin: $error';
  }

  @override
  String adminCouldNotOpenUrl(String uri) {
    return 'Impossibile aprire $uri';
  }

  @override
  String get adminOpenInBrowser => 'Apri nel Browser';

  @override
  String get adminOpenExternally => 'Apri esternamente';

  @override
  String get adminGeneralSettings => 'Impostazioni Generali';

  @override
  String get adminServerName => 'Nome server';

  @override
  String get adminPreferredMetadataCountry => 'Paese metadati preferito';

  @override
  String get adminCachePath => 'Percorso cache';

  @override
  String get adminMetadataPath => 'Percorso metadati';

  @override
  String get adminLibraryScanConcurrency => 'Concorrenza scansione libreria';

  @override
  String get adminParallelImageEncodingLimit =>
      'Limite codifica immagini parallela';

  @override
  String get adminSlowResponseThreshold => 'Soglia risposta lenta (ms)';

  @override
  String get adminBrandingSaved => 'Impostazioni branding salvate';

  @override
  String get adminBrandingLoadFailed =>
      'Impossibile caricare le impostazioni di branding';

  @override
  String get adminLoginDisclaimer => 'Disclaimer accesso';

  @override
  String get adminLoginDisclaimerHint =>
      'HTML visualizzato sotto il modulo di accesso';

  @override
  String get adminCustomCss => 'CSS Personalizzato';

  @override
  String get adminCustomCssHint =>
      'CSS personalizzato applicato all\'interfaccia web';

  @override
  String get adminEnableSplashScreen => 'Abilita schermata di avvio';

  @override
  String get adminStreamingSaved => 'Impostazioni streaming salvate';

  @override
  String get adminStreamingLoadFailed =>
      'Impossibile caricare le impostazioni di streaming';

  @override
  String get adminStreamingDescription =>
      'Imposta limiti globali di bitrate streaming per connessioni remote.';

  @override
  String get adminRemoteBitrateLimitMbps =>
      'Limite bitrate client remoto (Mbps)';

  @override
  String get adminLeaveEmptyForUnlimited => 'Lascia vuoto o 0 per illimitato';

  @override
  String get adminPlaybackSaved => 'Impostazioni riproduzione salvate';

  @override
  String get adminPlaybackLoadFailed =>
      'Impossibile caricare le impostazioni di riproduzione';

  @override
  String get adminPlaybackTranscoding => 'Riproduzione / Transcodifica';

  @override
  String get adminHardwareAcceleration => 'Accelerazione hardware';

  @override
  String get adminVaapiDevice => 'Dispositivo VA-API';

  @override
  String get adminEnableHardwareEncoding => 'Abilita codifica hardware';

  @override
  String get adminEnableHardwareDecoding => 'Abilita decodifica hardware per:';

  @override
  String get adminEncodingThreads => 'Thread di codifica';

  @override
  String get adminAutomatic => '0 = automatico';

  @override
  String get adminTranscodingTempPath => 'Percorso temporaneo transcodifica';

  @override
  String get adminEnableFallbackFont => 'Abilita font di riserva';

  @override
  String get adminFallbackFontPath => 'Percorso font di riserva';

  @override
  String get adminAllowSegmentDeletion => 'Consenti eliminazione segmenti';

  @override
  String get adminSegmentKeepSeconds => 'Mantenimento segmenti (secondi)';

  @override
  String get adminThrottleBuffering => 'Limitazione buffering';

  @override
  String get adminTrickplaySaved => 'Impostazioni trickplay salvate';

  @override
  String get adminTrickplayLoadFailed =>
      'Impossibile caricare le impostazioni trickplay';

  @override
  String get adminEnableHardwareAcceleration =>
      'Abilita accelerazione hardware';

  @override
  String get adminEnableKeyFrameExtraction =>
      'Abilita estrazione solo fotogrammi chiave';

  @override
  String get adminKeyFrameSubtitle => 'Più veloce ma meno preciso';

  @override
  String get adminScanBehavior => 'Comportamento scansione';

  @override
  String get adminProcessPriority => 'Priorità processo';

  @override
  String get adminImageSettings => 'Impostazioni Immagine';

  @override
  String get adminIntervalMs => 'Intervallo (ms)';

  @override
  String get adminCaptureFrameSubtitle => 'Frequenza di cattura dei fotogrammi';

  @override
  String get adminWidthResolutions => 'Risoluzioni larghezza';

  @override
  String get adminTileWidth => 'Larghezza tile';

  @override
  String get adminTileHeight => 'Altezza tile';

  @override
  String get adminQualitySubtitle =>
      'Valori più bassi = qualità migliore, file più grandi';

  @override
  String get adminProcessThreads => 'Thread di processo';

  @override
  String get adminResumeSaved => 'Impostazioni ripresa salvate';

  @override
  String get adminResumeLoadFailed =>
      'Impossibile caricare le impostazioni di ripresa';

  @override
  String get adminResumeDescription =>
      'Configura quando i contenuti devono essere contrassegnati come parzialmente riprodotti o completamente riprodotti.';

  @override
  String get adminMinResumePercentage => 'Percentuale minima di ripresa';

  @override
  String get adminMinResumeSubtitle =>
      'I contenuti devono essere riprodotti oltre questa percentuale per salvare i progressi';

  @override
  String get adminMaxResumePercentage => 'Percentuale massima di ripresa';

  @override
  String get adminMaxResumeSubtitle =>
      'I contenuti sono considerati completamente riprodotti dopo questa percentuale';

  @override
  String get adminMinResumeDuration => 'Durata minima di ripresa (secondi)';

  @override
  String get adminMinResumeDurationSubtitle =>
      'Gli elementi più brevi di questo non sono riprendibili';

  @override
  String get adminMinAudiobookResume => 'Percentuale minima ripresa audiolibri';

  @override
  String get adminMaxAudiobookResume =>
      'Percentuale massima ripresa audiolibri';

  @override
  String get adminNetworkingSaved =>
      'Impostazioni di rete salvate. Potrebbe essere necessario un riavvio del server.';

  @override
  String get adminNetworkingLoadFailed =>
      'Impossibile caricare le impostazioni di rete';

  @override
  String get adminNetworkingWarning =>
      'Le modifiche alle impostazioni di rete potrebbero richiedere un riavvio del server.';

  @override
  String get adminEnableRemoteAccess => 'Abilita accesso remoto';

  @override
  String get ports => 'Porte';

  @override
  String get adminHttpPort => 'Porta HTTP';

  @override
  String get adminHttpsPort => 'Porta HTTPS';

  @override
  String get adminPublicHttpsPort => 'Porta HTTPS pubblica';

  @override
  String get adminBaseUrl => 'URL Base';

  @override
  String get adminBaseUrlHint => 'es. /jellyfin';

  @override
  String get https => 'HTTPS';

  @override
  String get adminEnableHttps => 'Abilita HTTPS';

  @override
  String get adminLocalNetwork => 'Rete Locale';

  @override
  String get adminLocalNetworkAddresses => 'Indirizzi rete locale';

  @override
  String get adminKnownProxies => 'Proxy conosciuti';

  @override
  String get adminRemoteIpFilter => 'Filtro IP Remoto';

  @override
  String get adminRemoteIpFilterEntries => 'Filtro IP remoto';

  @override
  String get adminCertificatePath => 'Percorso certificato';

  @override
  String get whitelist => 'Whitelist';

  @override
  String get blacklist => 'Blacklist';

  @override
  String get notSet => 'Non impostato';

  @override
  String get adminMetadataSaved => 'Metadati salvati';

  @override
  String adminMetadataLoadFailed(String error) {
    return 'Impossibile caricare i metadati: $error';
  }

  @override
  String adminMetadataSaveFailed(String error) {
    return 'Impossibile salvare i metadati: $error';
  }

  @override
  String get adminRefreshMetadata => 'Aggiorna Metadati';

  @override
  String get recursive => 'Ricorsivo';

  @override
  String get adminReplaceAllMetadata => 'Sostituisci tutti i metadati';

  @override
  String get adminReplaceAllImages => 'Sostituisci tutte le immagini';

  @override
  String get adminMetadataRefreshRequested =>
      'Aggiornamento metadati richiesto';

  @override
  String adminMetadataRefreshFailed(String error) {
    return 'Impossibile aggiornare i metadati: $error';
  }

  @override
  String get adminSearchRemotePerson => 'Cerca Persona Remota';

  @override
  String get adminNoRemoteMatches => 'Nessuna corrispondenza remota trovata';

  @override
  String get adminRemoteResults => 'Risultati Remoti';

  @override
  String get adminRemoteMetadataApplied => 'Metadati remoti applicati';

  @override
  String adminRemoteSearchFailed(String error) {
    return 'Ricerca remota fallita: $error';
  }

  @override
  String get adminUpdateContentType => 'Aggiorna Tipo Contenuto';

  @override
  String get adminContentType => 'Tipo contenuto';

  @override
  String get adminContentTypeUpdated => 'Tipo contenuto aggiornato';

  @override
  String adminContentTypeUpdateFailed(String error) {
    return 'Impossibile aggiornare il tipo di contenuto: $error';
  }

  @override
  String get adminMetadataEditorLoadFailed =>
      'Impossibile caricare l\'editor metadati';

  @override
  String get adminNoPeopleEntries => 'Nessuna voce persone';

  @override
  String get adminNoExternalIds => 'Nessun ID esterno disponibile';

  @override
  String adminImageUpdated(String imageType) {
    return 'Immagine $imageType aggiornata';
  }

  @override
  String adminImageDownloadFailed(String error) {
    return 'Impossibile scaricare l\'immagine: $error';
  }

  @override
  String get adminUnsupportedImageFormat => 'Formato immagine non supportato';

  @override
  String get adminImageReadFailed =>
      'Impossibile leggere l\'immagine selezionata';

  @override
  String adminImageUploaded(String imageType) {
    return 'Immagine $imageType caricata';
  }

  @override
  String adminImageUploadFailed(String error) {
    return 'Impossibile caricare l\'immagine: $error';
  }

  @override
  String adminDeleteImage(String imageType) {
    return 'Elimina immagine $imageType';
  }

  @override
  String adminImageDeleted(String imageType) {
    return 'Immagine $imageType eliminata';
  }

  @override
  String adminImageDeleteFailed(String error) {
    return 'Impossibile eliminare l\'immagine: $error';
  }

  @override
  String get adminAllProviders => 'Tutti i provider';

  @override
  String get adminNoRemoteImages => 'Nessuna immagine remota trovata';

  @override
  String adminTunerDiscoveryFailed(String error) {
    return 'Scoperta tuner fallita: $error';
  }

  @override
  String get adminAddTuner => 'Aggiungi Tuner';

  @override
  String get adminTunerType => 'Tipo Tuner';

  @override
  String get adminTunerTypeHint => 'HDHomeRun, M3U, Altro';

  @override
  String get adminUrlPath => 'URL / Percorso';

  @override
  String get adminNameOptional => 'Nome (opzionale)';

  @override
  String get adminTunerAdded => 'Tuner aggiunto';

  @override
  String adminTunerAddFailed(String error) {
    return 'Impossibile aggiungere il tuner: $error';
  }

  @override
  String get adminAddGuideProvider => 'Aggiungi Provider Guida';

  @override
  String get adminProviderType => 'Tipo Provider';

  @override
  String get adminProviderTypeHint => 'SchedulesDirect o XMLTV';

  @override
  String get adminUsernameOptional => 'Nome utente (opzionale)';

  @override
  String get adminRefreshInterval => 'Intervallo di aggiornamento (ore)';

  @override
  String get adminProviderAdded => 'Provider aggiunto';

  @override
  String adminProviderAddFailed(String error) {
    return 'Impossibile aggiungere il provider: $error';
  }

  @override
  String adminTunerRemoveFailed(String error) {
    return 'Impossibile rimuovere il tuner: $error';
  }

  @override
  String get adminTunerResetRequested => 'Reset tuner richiesto';

  @override
  String adminTunerResetFailed(String error) {
    return 'Impossibile resettare il tuner: $error';
  }

  @override
  String adminProviderRemoveFailed(String error) {
    return 'Impossibile rimuovere il provider: $error';
  }

  @override
  String get adminRecordingSettings => 'Impostazioni Registrazione';

  @override
  String get adminPrePadding => 'Pre-padding (minuti)';

  @override
  String get adminPostPadding => 'Post-padding (minuti)';

  @override
  String get adminRecordingPath => 'Percorso registrazione';

  @override
  String get adminSeriesRecordingPath => 'Percorso registrazione serie';

  @override
  String get adminRecordingSettingsSaved =>
      'Impostazioni registrazione salvate';

  @override
  String adminSettingsSaveFailed(String error) {
    return 'Impossibile salvare le impostazioni: $error';
  }

  @override
  String get adminSetChannelMappings => 'Imposta Mappature Canali';

  @override
  String get adminMappingJson => 'JSON Mappatura';

  @override
  String get adminChannelMappingsUpdated => 'Mappature canali aggiornate';

  @override
  String adminMappingsUpdateFailed(String error) {
    return 'Impossibile aggiornare le mappature: $error';
  }

  @override
  String get adminLiveTvLoadFailed =>
      'Impossibile caricare l\'amministrazione TV Live';

  @override
  String get adminTunerDevices => 'Dispositivi Tuner';

  @override
  String get adminNoTunerHosts => 'Nessun host tuner configurato';

  @override
  String get adminGuideProviders => 'Provider Guida';

  @override
  String get adminAddProvider => 'Aggiungi Provider';

  @override
  String get adminNoListingProviders =>
      'Nessun provider di elenchi configurato';

  @override
  String adminRecordingPathDisplay(String path) {
    return 'Percorso registrazione: $path';
  }

  @override
  String adminSeriesPathDisplay(String path) {
    return 'Percorso serie: $path';
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
  String get adminTunerDiscovery => 'Scoperta Tuner';

  @override
  String get adminChannelMappings => 'Mappature Canali';

  @override
  String get adminNoDiscoveredTuners => 'Nessun tuner scoperto ancora';

  @override
  String get adminSettingsSaved => 'Impostazioni salvate';

  @override
  String get adminBackupsNotAvailable =>
      'I backup non sono disponibili in questa build del server.';

  @override
  String get adminRestoreWarning1 =>
      'Il ripristino sostituirà TUTTI i dati attuali del server con i dati del backup.';

  @override
  String get adminRestoreWarning2 =>
      'Le impostazioni del server, gli utenti e i dati delle librerie attuali verranno sovrascritti.';

  @override
  String get adminRestoreWarning3 =>
      'Il server si riavvierà dopo il ripristino.';

  @override
  String adminRestoreConfirmMessage(String name) {
    return 'Ripristinare il backup $name ora?';
  }

  @override
  String get adminRestoreRequested =>
      'Ripristino richiesto. Il riavvio del server potrebbe disconnettere questa sessione.';

  @override
  String get adminBackupsTitle => 'Backup';

  @override
  String get adminUnknownDate => 'Data sconosciuta';

  @override
  String get adminUnnamedBackup => 'Backup Senza Nome';

  @override
  String get adminLiveTvNotAvailable =>
      'L\'amministrazione TV Live non è disponibile in questa build del server.';

  @override
  String get adminLiveTvTitle => 'Amministrazione TV Live';

  @override
  String get adminApply => 'Applica';

  @override
  String get adminNotSet => 'Non impostato';

  @override
  String get adminReset => 'Ripristina';

  @override
  String get adminLogsTitle => 'Log del Server';

  @override
  String get adminLogsNewestFirst => 'Più Recenti';

  @override
  String get adminLogsOldestFirst => 'Più Vecchi';

  @override
  String get adminLogsJustNow => 'Proprio ora';

  @override
  String adminLogsMinutesAgo(int minutes) {
    return '${minutes}m fa';
  }

  @override
  String adminLogsHoursAgo(int hours) {
    return '${hours}h fa';
  }

  @override
  String adminLogsDaysAgo(int days) {
    return '${days}g fa';
  }

  @override
  String adminLogViewerLoadFailed(String fileName) {
    return 'Impossibile caricare $fileName';
  }

  @override
  String adminLogViewerMatches(int count) {
    return '$count corrispondenze';
  }

  @override
  String get adminLogViewerNoMatches => 'Nessuna riga corrispondente';

  @override
  String get adminMetadataEditorTitle => 'Editor Metadati';

  @override
  String get adminMetadataRemote => 'Remoto';

  @override
  String get adminMetadataType => 'Tipo';

  @override
  String get adminMetadataDetails => 'Dettagli';

  @override
  String get adminMetadataExternalIds => 'ID Esterni';

  @override
  String get adminMetadataImages => 'Immagini';

  @override
  String get adminMetadataFieldTitle => 'Titolo';

  @override
  String get adminMetadataFieldSortTitle => 'Titolo ordinamento';

  @override
  String get adminMetadataFieldOriginalTitle => 'Titolo originale';

  @override
  String get adminMetadataFieldPremiereDate =>
      'Data prima visione (AAAA-MM-GG)';

  @override
  String get adminMetadataFieldEndDate => 'Data fine (AAAA-MM-GG)';

  @override
  String get adminMetadataFieldProductionYear => 'Anno di produzione';

  @override
  String get adminMetadataFieldOfficialRating => 'Classificazione ufficiale';

  @override
  String get adminMetadataFieldCommunityRating => 'Valutazione comunità';

  @override
  String get adminMetadataFieldCriticRating => 'Valutazione critica';

  @override
  String get adminMetadataFieldTagline => 'Tagline';

  @override
  String get adminMetadataFieldOverview => 'Panoramica';

  @override
  String get adminMetadataGenres => 'Generi';

  @override
  String get adminMetadataTags => 'Tag';

  @override
  String get adminMetadataStudios => 'Studi';

  @override
  String get adminMetadataPeople => 'Persone';

  @override
  String get adminMetadataAddGenre => 'Aggiungi genere';

  @override
  String get adminMetadataAddTag => 'Aggiungi tag';

  @override
  String get adminMetadataAddStudio => 'Aggiungi studio';

  @override
  String get adminMetadataAddPerson => 'Aggiungi Persona';

  @override
  String get adminMetadataEditPerson => 'Modifica Persona';

  @override
  String get adminMetadataRole => 'Ruolo';

  @override
  String get adminMetadataImagePrimary => 'Principale';

  @override
  String get adminMetadataImageBackdrop => 'Sfondo';

  @override
  String get adminMetadataImageLogo => 'Logo';

  @override
  String get adminMetadataImageBanner => 'Banner';

  @override
  String get adminMetadataImageThumb => 'Miniatura';

  @override
  String get adminMetadataRecursive => 'Ricorsivo';

  @override
  String get adminMetadataProvider => 'Provider';

  @override
  String adminMetadataImageUpdated(String imageType) {
    return 'Immagine $imageType aggiornata';
  }

  @override
  String adminMetadataImageUploaded(String imageType) {
    return 'Immagine $imageType caricata';
  }

  @override
  String adminMetadataImageDeleted(String imageType) {
    return 'Immagine $imageType eliminata';
  }

  @override
  String adminMetadataImageDownloadFailed(String error) {
    return 'Impossibile scaricare l\'immagine: $error';
  }

  @override
  String get adminMetadataImageReadFailed =>
      'Impossibile leggere l\'immagine selezionata';

  @override
  String adminMetadataImageUploadFailed(String error) {
    return 'Impossibile caricare l\'immagine: $error';
  }

  @override
  String adminMetadataDeleteImageTitle(String imageType) {
    return 'Elimina immagine $imageType';
  }

  @override
  String get adminMetadataDeleteImageContent =>
      'Questo rimuoverà l\'immagine corrente dall\'elemento.';

  @override
  String adminMetadataImageDeleteFailed(String error) {
    return 'Impossibile eliminare l\'immagine: $error';
  }

  @override
  String adminMetadataChooseImage(String imageType) {
    return 'Scegli immagine $imageType';
  }

  @override
  String get adminMetadataUpload => 'Carica';

  @override
  String get adminMetadataUpdate => 'Aggiorna';

  @override
  String get adminMetadataRemoteImage => 'Immagine remota';

  @override
  String get adminPluginsInstalled => 'Installati';

  @override
  String get adminPluginsCatalog => 'Catalogo';

  @override
  String get adminPluginsActive => 'Attivi';

  @override
  String get adminPluginsRestart => 'Riavvio';

  @override
  String get adminPluginsNoSearchResults =>
      'Nessun plugin corrisponde alla ricerca';

  @override
  String get adminPluginsNoneInstalled => 'Nessun plugin installato';

  @override
  String adminPluginsUpdateAvailable(String version) {
    return 'Aggiornamento disponibile: v$version';
  }

  @override
  String get adminPluginsUpdateAvailableGeneric => 'Aggiornamento disponibile';

  @override
  String get adminPluginsPendingRemoval =>
      'Rimozione in attesa dopo il riavvio';

  @override
  String get adminPluginsChangesPending => 'Modifiche in attesa di riavvio';

  @override
  String get adminPluginsEnable => 'Abilita';

  @override
  String get adminPluginsDisable => 'Disabilita';

  @override
  String get adminPluginsInstallUpdate => 'Installa aggiornamento';

  @override
  String adminPluginsInstallUpdateVersioned(String version) {
    return 'Installa aggiornamento (v$version)';
  }

  @override
  String get adminPluginsCatalogNoSearchResults =>
      'Nessun pacchetto corrisponde alla ricerca';

  @override
  String get adminPluginsCatalogEmpty => 'Nessun pacchetto disponibile';

  @override
  String adminPluginsInstalling(String name) {
    return '\"$name\" è in fase di installazione...';
  }

  @override
  String get adminPluginDetailExperimental => 'Integrazione Sperimentale';

  @override
  String get adminPluginDetailExperimentalContent =>
      'L\'integrazione delle impostazioni dei plugin è ancora sperimentale. Alcuni campi o layout potrebbero non essere visualizzati correttamente.';

  @override
  String get adminPluginDetailToggle404 =>
      'Impossibile attivare/disattivare il plugin. Il server non ha trovato questa versione del plugin. Prova ad aggiornare i plugin, poi riprova.';

  @override
  String get adminPluginDetailToggleDioError =>
      'Impossibile attivare/disattivare il plugin. Controlla i log del server per i dettagli.';

  @override
  String adminPluginDetailSettingsTitle(String name) {
    return 'Impostazioni $name';
  }

  @override
  String get adminPluginDetailDetails => 'Dettagli';

  @override
  String get adminPluginDetailDeveloper => 'Sviluppatore';

  @override
  String get adminPluginDetailRepository => 'Repository';

  @override
  String get adminPluginDetailBundled => 'Incluso';

  @override
  String get adminPluginDetailEnablePlugin => 'Abilita Plugin';

  @override
  String get adminPluginDetailRestartRequired =>
      'È necessario un riavvio del server per rendere effettive le modifiche.';

  @override
  String get adminPluginDetailRemovalPending =>
      'Questo plugin verrà rimosso dopo il riavvio del server.';

  @override
  String get adminPluginDetailMalfunctioned =>
      'Questo plugin ha avuto un malfunzionamento e potrebbe non funzionare correttamente.';

  @override
  String get adminPluginDetailNotSupported =>
      'Questo plugin non è supportato dalla versione corrente del server.';

  @override
  String get adminPluginDetailSuperseded =>
      'Questo plugin è stato sostituito da una versione più recente.';

  @override
  String adminReposLoadFailed(String error) {
    return 'Impossibile caricare i repository: $error';
  }

  @override
  String get adminReposRemoveTitle => 'Rimuovi Repository';

  @override
  String adminReposRemoveConfirm(String name) {
    return 'Sei sicuro di voler rimuovere \"$name\"?';
  }

  @override
  String get adminReposRemove => 'Rimuovi';

  @override
  String adminReposSaveFailed(String error) {
    return 'Impossibile salvare i repository: $error';
  }

  @override
  String get adminReposEmpty => 'Nessun repository configurato';

  @override
  String get adminReposEmptySubtitle =>
      'Aggiungi un repository per sfogliare i plugin disponibili';

  @override
  String get adminReposUnnamed => '(senza nome)';

  @override
  String get adminReposEditTitle => 'Modifica Repository';

  @override
  String get adminReposAddTitle => 'Aggiungi Repository';

  @override
  String get adminReposUrl => 'URL Repository';

  @override
  String get adminReposNameHint => 'es. Jellyfin Stabile';

  @override
  String get adminPluginSettingsInvalidUrl => 'URL non valido';

  @override
  String get adminGeneralSettingsTitle => 'Impostazioni Generali';

  @override
  String get adminGeneralMetadataLanguage => 'Lingua metadati preferita';

  @override
  String get adminGeneralMetadataLanguageHint => 'es. it, en, de';

  @override
  String get adminGeneralMetadataCountry => 'Paese metadati preferito';

  @override
  String get adminGeneralMetadataCountryHint => 'es. IT, US, DE';

  @override
  String get adminGeneralLibraryScanConcurrency =>
      'Concorrenza scansione libreria';

  @override
  String get adminGeneralImageEncodingLimit =>
      'Limite codifica immagini parallela';

  @override
  String get adminUnknownError => 'Errore sconosciuto';

  @override
  String get adminBrowse => 'Sfoglia';

  @override
  String get adminCloseBrowser => 'Chiudi browser';

  @override
  String get adminNetworkingTitle => 'Rete';

  @override
  String get adminNetworkingRestartWarning =>
      'Le modifiche alle impostazioni di rete potrebbero richiedere un riavvio del server.';

  @override
  String get adminNetworkingRemoteAccess => 'Abilita accesso remoto';

  @override
  String get adminNetworkingPorts => 'Porte';

  @override
  String get adminNetworkingHttpPort => 'Porta HTTP';

  @override
  String get adminNetworkingHttpsPort => 'Porta HTTPS';

  @override
  String get adminNetworkingEnableHttps => 'Abilita HTTPS';

  @override
  String get adminNetworkingLocalNetwork => 'Rete Locale';

  @override
  String get adminNetworkingLocalAddresses => 'Indirizzi rete locale';

  @override
  String get adminNetworkingAddressHint => 'es. 192.168.1.0/24';

  @override
  String get adminNetworkingKnownProxies => 'Proxy conosciuti';

  @override
  String get adminNetworkingProxyHint => 'es. 10.0.0.1';

  @override
  String get adminNetworkingWhitelist => 'Whitelist';

  @override
  String get adminNetworkingBlacklist => 'Blacklist';

  @override
  String get adminNetworkingAddEntry => 'Aggiungi voce';

  @override
  String get adminBrandingTitle => 'Branding';

  @override
  String get adminBrandingLoginDisclaimer => 'Disclaimer accesso';

  @override
  String get adminBrandingLoginDisclaimerHint =>
      'HTML visualizzato sotto il modulo di accesso';

  @override
  String get adminBrandingCustomCss => 'CSS Personalizzato';

  @override
  String get adminBrandingCustomCssHint =>
      'CSS personalizzato applicato all\'interfaccia web';

  @override
  String get adminBrandingEnableSplash => 'Abilita schermata di avvio';

  @override
  String get adminPlaybackHwAccel => 'Accelerazione Hardware';

  @override
  String get adminPlaybackHwAccelLabel => 'Accelerazione hardware';

  @override
  String get adminPlaybackEnableHwEncoding => 'Abilita codifica hardware';

  @override
  String get adminPlaybackEnableHwDecoding =>
      'Abilita decodifica hardware per:';

  @override
  String get adminPlaybackEncoding => 'Codifica';

  @override
  String get adminPlaybackEncodingThreads => 'Thread di codifica';

  @override
  String get adminPlaybackFallbackFont => 'Abilita font di riserva';

  @override
  String get adminPlaybackFallbackFontPath => 'Percorso font di riserva';

  @override
  String get adminPlaybackStreaming => 'Streaming';

  @override
  String get adminResumeVideo => 'Video';

  @override
  String get adminResumeAudiobooks => 'Audiolibri';

  @override
  String get adminResumeMinAudiobookPct =>
      'Percentuale minima ripresa audiolibri';

  @override
  String get adminResumeMaxAudiobookPct =>
      'Percentuale massima ripresa audiolibri';

  @override
  String get adminStreamingBitrateLimit =>
      'Limite bitrate client remoto (Mbps)';

  @override
  String get adminStreamingBitrateLimitHint =>
      'Lascia vuoto o 0 per illimitato';

  @override
  String get adminTrickplayHwAccel => 'Abilita accelerazione hardware';

  @override
  String get adminTrickplayHwEncoding => 'Abilita codifica hardware';

  @override
  String get adminTrickplayKeyFrameOnly =>
      'Abilita estrazione solo fotogrammi chiave';

  @override
  String get adminTrickplayKeyFrameOnlySubtitle => 'Più veloce ma meno preciso';

  @override
  String get adminTrickplayNonBlocking => 'Non bloccante';

  @override
  String get adminTrickplayBlocking => 'Bloccante';

  @override
  String get adminTrickplayPriorityHigh => 'Alta';

  @override
  String get adminTrickplayPriorityAboveNormal => 'Sopra il Normale';

  @override
  String get adminTrickplayPriorityNormal => 'Normale';

  @override
  String get adminTrickplayPriorityBelowNormal => 'Sotto il Normale';

  @override
  String get adminTrickplayPriorityIdle => 'Inattivo';

  @override
  String get adminTrickplayImageSettings => 'Impostazioni Immagine';

  @override
  String get adminTrickplayInterval => 'Intervallo (ms)';

  @override
  String get adminTrickplayIntervalSubtitle =>
      'Frequenza di cattura dei fotogrammi';

  @override
  String get adminTrickplayWidthResolutionsHint =>
      'Larghezze in pixel separate da virgola (es. 320)';

  @override
  String get adminTrickplayQuality => 'Qualità';

  @override
  String get adminTrickplayQScale => 'Scala qualità';

  @override
  String get adminTrickplayQScaleSubtitle =>
      'Valori più bassi = qualità migliore, file più grandi';

  @override
  String get adminTrickplayJpegQuality => 'Qualità JPEG';

  @override
  String get adminTrickplayProcessing => 'Elaborazione';

  @override
  String get adminTasksEmpty => 'Nessuna attività pianificata trovata';

  @override
  String get adminTasksNoFilterMatch =>
      'Nessuna attività corrisponde al filtro attuale';

  @override
  String get adminTaskCancelling => 'Annullamento...';

  @override
  String get adminTaskRunning => 'In esecuzione...';

  @override
  String get adminTaskNeverRun => 'Mai eseguita';

  @override
  String get adminTaskStop => 'Ferma';

  @override
  String get adminTaskRun => 'Esegui';

  @override
  String get adminTaskDetailLastExecution => 'Ultima Esecuzione';

  @override
  String get adminTaskDetailStarted => 'Iniziata';

  @override
  String get adminTaskDetailEnded => 'Terminata';

  @override
  String get adminTaskDetailDuration => 'Durata';

  @override
  String get adminTaskDetailErrorLabel => 'Errore:';

  @override
  String adminTaskTriggerDaily(String time) {
    return 'Ogni giorno alle $time';
  }

  @override
  String adminTaskTriggerWeekly(String day, String time) {
    return 'Ogni $day alle $time';
  }

  @override
  String adminTaskTriggerInterval(String duration) {
    return 'Ogni $duration';
  }

  @override
  String get adminTaskTriggerStartup => 'All\'avvio dell\'applicazione';

  @override
  String get adminTaskTriggerTypeDaily => 'Giornaliero';

  @override
  String get adminTaskTriggerTypeWeekly => 'Settimanale';

  @override
  String get adminTaskTriggerTypeInterval => 'A intervalli';

  @override
  String get adminTaskTriggerIntervalLabel => 'Intervallo';

  @override
  String get adminTaskTriggerEveryHour => 'Ogni ora';

  @override
  String get adminTaskTriggerEvery6Hours => 'Ogni 6 ore';

  @override
  String get adminTaskTriggerEvery12Hours => 'Ogni 12 ore';

  @override
  String get adminTaskTriggerEvery24Hours => 'Ogni 24 ore';

  @override
  String get adminTaskTriggerEvery2Days => 'Ogni 2 giorni';

  @override
  String adminTaskTriggerHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore',
      one: '1 ora',
    );
    return '$_temp0';
  }

  @override
  String get adminTaskTriggerTime => 'Orario';

  @override
  String get adminTaskTriggerNoLimit => 'Nessun limite';

  @override
  String get adminActivityJustNow => 'Proprio ora';

  @override
  String get adminActivityLastHour => 'Ultima ora';

  @override
  String get adminActivityToday => 'Oggi';

  @override
  String get adminActivityYesterday => 'Ieri';

  @override
  String get adminActivityOlder => 'Più vecchie';

  @override
  String adminActivityDaysAgo(int days) {
    return '${days}g fa';
  }

  @override
  String adminActivityHoursAgo(int hours) {
    return '${hours}h fa';
  }

  @override
  String adminActivityMinutesAgo(int minutes) {
    return '${minutes}m fa';
  }

  @override
  String get adminActivityNow => 'ora';

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
    return '${days}g';
  }

  @override
  String adminActivityDateShort(int month, int day) {
    return '$month/$day';
  }

  @override
  String get adminTrickplayDescription =>
      'Configura la generazione di immagini trickplay per le miniature di anteprima nella ricerca.';

  @override
  String get adminNetworkingPublicHttpsPort => 'Porta HTTPS pubblica';

  @override
  String get adminNetworkingBaseUrl => 'URL Base';

  @override
  String get adminNetworkingBaseUrlHint => 'es. /jellyfin';

  @override
  String get adminNetworkingHttps => 'HTTPS';

  @override
  String get adminNetworkingCertPath => 'Percorso certificato';

  @override
  String get adminNetworkingRemoteIpFilter => 'Filtro IP Remoto';

  @override
  String get adminNetworkingRemoteIpFilterLabel => 'Filtro IP remoto';

  @override
  String get adminPlaybackVaapiDevice => 'Dispositivo VA-API';

  @override
  String get adminPlaybackAutomatic => '0 = automatico';

  @override
  String get adminPlaybackTranscodeTempPath =>
      'Percorso temporaneo transcodifica';

  @override
  String get adminPlaybackSegmentDeletion => 'Consenti eliminazione segmenti';

  @override
  String get adminPlaybackSegmentKeep => 'Mantenimento segmenti (secondi)';

  @override
  String get adminPlaybackThrottleBuffering => 'Limitazione buffering';

  @override
  String get adminResumeMinPct => 'Percentuale minima di ripresa';

  @override
  String get adminResumeMinPctSubtitle =>
      'I contenuti devono essere riprodotti oltre questa percentuale per salvare i progressi';

  @override
  String get adminResumeMaxPct => 'Percentuale massima di ripresa';

  @override
  String get adminResumeMaxPctSubtitle =>
      'I contenuti sono considerati completamente riprodotti dopo questa percentuale';

  @override
  String get adminResumeMinDuration => 'Durata minima di ripresa (secondi)';

  @override
  String get adminResumeMinDurationSubtitle =>
      'Gli elementi più brevi di questo non sono riprendibili';

  @override
  String get adminTrickplayScanBehavior => 'Comportamento scansione';

  @override
  String get adminTrickplayProcessPriority => 'Priorità processo';

  @override
  String get adminTrickplayTileWidth => 'Larghezza tile';

  @override
  String get adminTrickplayTileHeight => 'Altezza tile';

  @override
  String get adminTrickplayProcessThreads => 'Thread di processo';

  @override
  String get adminTrickplayWidthResolutions => 'Risoluzioni larghezza';

  @override
  String get adminMetadataDefault => 'Predefinito';

  @override
  String get adminMetadataContentTypeUpdated => 'Tipo contenuto aggiornato';

  @override
  String adminMetadataContentTypeFailed(String error) {
    return 'Impossibile aggiornare il tipo di contenuto: $error';
  }

  @override
  String get adminGeneralSlowResponseThreshold => 'Soglia risposta lenta (ms)';

  @override
  String get adminGeneralCachePath => 'Percorso cache';

  @override
  String get adminGeneralMetadataPath => 'Percorso metadati';

  @override
  String get adminGeneralServerName => 'Nome server';

  @override
  String get adminSettingsLoadFailed => 'Impossibile caricare le impostazioni';

  @override
  String get adminDiscover => 'Scopri';

  @override
  String adminChannelMappingsUpdateFailed(String error) {
    return 'Impossibile aggiornare le mappature: $error';
  }

  @override
  String adminTimeLimitDuration(String duration) {
    return 'Limite di tempo: $duration';
  }

  @override
  String get folders => 'Cartelle';

  @override
  String get libraries => 'Librerie';

  @override
  String get syncPlay => 'SyncPlay';

  @override
  String get jellyseerr => 'Jellyseerr';

  @override
  String get seeAll => 'Vedi Tutto';

  @override
  String get noItems => 'Nessun elemento';

  @override
  String get switchUser => 'Cambia Utente';

  @override
  String get remoteControl => 'Controllo Remoto';

  @override
  String get mediaBarLoading => 'Caricamento barra media...';

  @override
  String get mediaBarError => 'Impossibile caricare la barra media';

  @override
  String get offlineServerUnavailable =>
      'Connesso a Internet, ma il server attuale non è disponibile.';

  @override
  String get offlineNoInternet =>
      'Sei offline. Solo i contenuti scaricati sono disponibili.';

  @override
  String get offlineSwitchServer => 'Cambia Server';

  @override
  String get offlineSavedMedia => 'Media Salvati';

  @override
  String get castGoogleCast => 'Google Cast';

  @override
  String get castAirPlay => 'AirPlay';

  @override
  String get castDlna => 'DLNA';

  @override
  String get castRemotePlayback => 'Riproduzione Remota';

  @override
  String castControlFailed(String error) {
    return 'Controllo cast fallito: $error';
  }

  @override
  String castKindControls(String kind) {
    return 'Controlli $kind';
  }

  @override
  String get castDeviceVolume => 'Volume Dispositivo';

  @override
  String get castVolumeUnavailable => 'Non disponibile';

  @override
  String castStopKind(String kind) {
    return 'Ferma $kind';
  }

  @override
  String get audioLabel => 'Audio';

  @override
  String get subtitlesLabel => 'Sottotitoli';

  @override
  String get pinConfirmTitle => 'Conferma PIN';

  @override
  String get pinSetTitle => 'Imposta PIN';

  @override
  String get pinEnterTitle => 'Inserisci PIN';

  @override
  String get pinReenterToConfirm => 'Reinserisci il PIN per confermare';

  @override
  String pinEnterNDigit(int length) {
    return 'Inserisci un PIN di $length cifre';
  }

  @override
  String pinEnterYourNDigit(int length) {
    return 'Inserisci il tuo PIN di $length cifre';
  }

  @override
  String get pinIncorrect => 'PIN errato';

  @override
  String get pinMismatch => 'I PIN non corrispondono';

  @override
  String get pinForgot => 'PIN dimenticato?';

  @override
  String get pinClear => 'Cancella';

  @override
  String get pinBackspace => 'Cancella';

  @override
  String get quickConnectAuthorized =>
      'Richiesta Connessione Rapida autorizzata.';

  @override
  String get quickConnectInvalidOrExpired =>
      'Il codice Connessione Rapida non è valido o è scaduto.';

  @override
  String get quickConnectNotSupported =>
      'La Connessione Rapida non è supportata su questo server.';

  @override
  String get quickConnectAuthorizeFailed =>
      'Impossibile autorizzare il codice Connessione Rapida.';

  @override
  String get quickConnectDisabled =>
      'La Connessione Rapida è disabilitata su questo server.';

  @override
  String get quickConnectForbidden =>
      'Il tuo account non può autorizzare questa richiesta di Connessione Rapida.';

  @override
  String get quickConnectNotFound =>
      'Codice Connessione Rapida non trovato. Prova un nuovo codice.';

  @override
  String quickConnectFailedWithMessage(String message) {
    return 'Connessione Rapida fallita: $message';
  }

  @override
  String get quickConnectEnterCode => 'Inserisci codice';

  @override
  String get quickConnectAuthorize => 'Autorizza';

  @override
  String remoteCommandFailed(String error) {
    return 'Comando fallito: $error';
  }

  @override
  String get remoteControlTitle => 'Controllo Remoto';

  @override
  String get remoteFailedToLoadSessions => 'Impossibile caricare le sessioni';

  @override
  String get remoteNoSessions => 'Nessuna sessione controllabile';

  @override
  String get remoteStartPlayback =>
      'Avvia la riproduzione su un altro dispositivo';

  @override
  String get unknownUser => 'Sconosciuto';

  @override
  String get unknownItem => 'Sconosciuto';

  @override
  String get remoteNothingPlaying => 'Nulla in riproduzione su questa sessione';

  @override
  String get castingStarted =>
      'Trasmissione avviata sul dispositivo selezionato';

  @override
  String castingFailed(String error) {
    return 'Impossibile avviare la trasmissione: $error';
  }

  @override
  String get noRemoteDevices =>
      'Nessun dispositivo di riproduzione remota disponibile.';

  @override
  String get noRemoteDevicesIos =>
      'Nessun dispositivo di riproduzione remota disponibile.\n\nSu iOS, i dispositivi AirPlay potrebbero non essere disponibili nel simulatore.';

  @override
  String get trackActionPlayNext => 'Riproduci Dopo';

  @override
  String get trackActionAddToQueue => 'Aggiungi alla Coda';

  @override
  String get trackActionAddToPlaylist => 'Aggiungi alla Playlist';

  @override
  String get trackActionCancelDownload => 'Annulla Download';

  @override
  String get trackActionDeleteFromPlaylist => 'Elimina dalla Playlist';

  @override
  String get trackActionMoveUp => 'Sposta Su';

  @override
  String get trackActionMoveDown => 'Sposta Giù';

  @override
  String get trackActionRemoveFromFavorites => 'Rimuovi dai Preferiti';

  @override
  String get trackActionAddToFavorites => 'Aggiungi ai Preferiti';

  @override
  String get trackActionGoToAlbum => 'Vai all\'Album';

  @override
  String get trackActionGoToArtist => 'Vai all\'Artista';

  @override
  String trackActionDownloading(String name) {
    return 'Download di $name...';
  }

  @override
  String get trackActionDeletedFile => 'File scaricato eliminato';

  @override
  String get trackActionDeleteFileFailed =>
      'Impossibile eliminare il file scaricato';

  @override
  String get shuffleBy => 'Casuale per';

  @override
  String get shuffleSelectLibrary => 'Seleziona Libreria';

  @override
  String get shuffleSelectGenre => 'Seleziona Genere';

  @override
  String get shuffleLibrary => 'Libreria';

  @override
  String get shuffleGenre => 'Genere';

  @override
  String get shuffleNoLibraries => 'Nessuna libreria compatibile disponibile.';

  @override
  String get shuffleNoGenres =>
      'Nessun genere trovato per questa modalità casuale.';

  @override
  String get posterDisplayTitle => 'Visualizzazione';

  @override
  String get posterImageType => 'Tipo Immagine';

  @override
  String get imageTypePoster => 'Poster';

  @override
  String get imageTypeThumbnail => 'Miniatura';

  @override
  String get imageTypeBanner => 'Banner';

  @override
  String get playlistAddFailed => 'Impossibile aggiungere alla playlist';

  @override
  String get playlistCreateFailed => 'Impossibile creare la playlist';

  @override
  String get playlistNew => 'Nuova Playlist';

  @override
  String get playlistCreate => 'Crea';

  @override
  String get playlistCreateNew => 'Crea Nuova Playlist';

  @override
  String get playlistNoneFound => 'Nessuna playlist trovata';

  @override
  String get addToPlaylist => 'Aggiungi alla Playlist';

  @override
  String get lyricsNotAvailable => 'Nessun testo disponibile';

  @override
  String get upNext => 'Prossimo';

  @override
  String get playNext => 'Riproduci Dopo';

  @override
  String get stillWatchingContent =>
      'La riproduzione è stata messa in pausa. Stai ancora guardando?';

  @override
  String get stillWatchingStop => 'Ferma';

  @override
  String get stillWatchingContinue => 'Continua';

  @override
  String skipSegment(String segment) {
    return 'Salta $segment';
  }

  @override
  String get liveTv => 'TV Live';

  @override
  String get continueWatchingAndNextUp => 'Continua a Guardare e Prossimo';

  @override
  String downloadingBatchProgress(int current, int total, String fileName) {
    return 'Download $current/$total — $fileName';
  }

  @override
  String downloadingFile(String fileName) {
    return 'Download di $fileName';
  }

  @override
  String get nextEpisode => 'Prossimo Episodio';

  @override
  String get moreFromThisSeason => 'Altro da Questa Stagione';

  @override
  String get playerTooltipPlaybackSpeed => 'Velocità di riproduzione';

  @override
  String get playerTooltipCastControls => 'Controlli cast';

  @override
  String get playerTooltipPlaybackQuality => 'Qualità di riproduzione';

  @override
  String get playerTooltipEnterFullscreen => 'Entra a schermo intero';

  @override
  String get playerTooltipExitFullscreen => 'Esci da schermo intero';

  @override
  String get playerTooltipPrevious => 'Precedente';

  @override
  String get playerTooltipSeekBack => 'Riavvolgi';

  @override
  String get playerTooltipSeekForward => 'Avanti veloce';
}
