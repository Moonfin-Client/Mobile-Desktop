// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Moonfin';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String connectingToServer(String serverName) {
    return 'Conectando a $serverName';
  }

  @override
  String get quickConnect => 'Conexión rápida';

  @override
  String get password => 'Contraseña';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get quickConnectInstruction =>
      'Introduce este código en el panel web de tu servidor:';

  @override
  String get waitingForAuthorization => 'Esperando autorización...';

  @override
  String get back => 'Atrás';

  @override
  String get serverUnavailable => 'Servidor no disponible';

  @override
  String get loginFailed => 'Error de inicio de sesión';

  @override
  String quickConnectUnavailable(String detail) {
    return 'Conexión rápida no disponible: $detail';
  }

  @override
  String quickConnectUnavailableWithStatus(String status, String detail) {
    return 'Conexión rápida no disponible ($status): $detail';
  }

  @override
  String get whosWatching => '¿Quién está viendo?';

  @override
  String get addUser => 'Añadir usuario';

  @override
  String get selectServer => 'Seleccionar servidor';

  @override
  String appVersionFooter(String version) {
    return 'Moonfin versión $version';
  }

  @override
  String get savedServers => 'Servidores guardados';

  @override
  String get discoveredServers => 'Servidores descubiertos';

  @override
  String get noneFound => 'Ninguno encontrado';

  @override
  String get unableToConnectToServer => 'No se puede conectar al servidor';

  @override
  String get addServer => 'Añadir servidor';

  @override
  String get embyConnect => 'Emby Connect';

  @override
  String get removeServer => 'Eliminar servidor';

  @override
  String removeServerConfirmation(String serverName) {
    return '¿Eliminar “$serverName” de tus servidores?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Eliminar';

  @override
  String get connectToServer => 'Conectar al servidor';

  @override
  String get serverAddress => 'Dirección del servidor';

  @override
  String get serverAddressHint => 'https://tu-servidor.ejemplo.com';

  @override
  String get connect => 'Conectar';

  @override
  String get secureStorageUnavailable => 'Almacenamiento seguro no disponible';

  @override
  String get secureStorageUnavailableMessage =>
      'Moonfin no pudo acceder al llavero del sistema. El inicio de sesión puede continuar, pero el almacenamiento seguro de tokens podría no estar disponible hasta que se desbloquee el llavero.';

  @override
  String get ok => 'OK';

  @override
  String get embyConnectSignInSubtitle =>
      'Inicia sesión con tu cuenta de Emby Connect';

  @override
  String get emailOrUsername => 'Correo electrónico o nombre de usuario';

  @override
  String get selectAServer => 'Selecciona un servidor';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get noLinkedServers =>
      'No hay servidores vinculados a esta cuenta de Emby Connect';

  @override
  String get invalidEmbyConnectCredentials =>
      'Credenciales de Emby Connect no válidas';

  @override
  String get invalidEmbyConnectLogin =>
      'Nombre de usuario o contraseña de Emby Connect no válidos';

  @override
  String get embyConnectExchangeNotSupported =>
      'El servidor no soporta el intercambio de Emby Connect';

  @override
  String get embyConnectNetworkError =>
      'Error de red al contactar con Emby Connect o el servidor seleccionado';

  @override
  String get loadingLinkedServers => 'Cargando servidores vinculados...';

  @override
  String get connectingToServerEllipsis => 'Conectando al servidor...';

  @override
  String get noReachableAddress => 'No se proporcionó una dirección accesible';

  @override
  String get invalidServerExchangeResponse =>
      'Respuesta no válida del punto de intercambio del servidor';

  @override
  String unableToConnectTo(String target) {
    return 'No se puede conectar a $target';
  }

  @override
  String get exitApp => '¿Salir de Moonfin?';

  @override
  String get exitAppConfirmation => '¿Estás seguro de que quieres salir?';

  @override
  String get exit => 'Salir';

  @override
  String get noHomeRowsLoaded => 'No se pudieron cargar las filas del inicio';

  @override
  String get noHomeRowsHint =>
      'Intenta actualizar o reducir las secciones activas del inicio.';

  @override
  String get retryHomeRows => 'Reintentar filas del inicio';

  @override
  String get guide => 'Guía';

  @override
  String get recordings => 'Grabaciones';

  @override
  String get schedule => 'Programación';

  @override
  String get series => 'Series';

  @override
  String get noItemsFound => 'No se encontraron elementos';

  @override
  String get home => 'Inicio';

  @override
  String get browseAll => 'Explorar todo';

  @override
  String get genres => 'Géneros';

  @override
  String get collectionPlaceholder =>
      'Los elementos de la colección aparecerán aquí';

  @override
  String get browseByLetter => 'Explorar por letra';

  @override
  String get alphabeticalBrowsePlaceholder =>
      'La exploración alfabética aparecerá aquí';

  @override
  String get suggestions => 'Sugerencias';

  @override
  String get suggestionsPlaceholder =>
      'Los elementos sugeridos aparecerán aquí';

  @override
  String get failedToLoadLibraries => 'Error al cargar las bibliotecas';

  @override
  String get noLibrariesFound => 'No se encontraron bibliotecas';

  @override
  String get library => 'Biblioteca';

  @override
  String get displaySettings => 'Ajustes de visualización';

  @override
  String get allGenres => 'Todos los géneros';

  @override
  String get noGenresFound => 'No se encontraron géneros';

  @override
  String failedToLoadFolderError(String error) {
    return 'Error al cargar la carpeta: $error';
  }

  @override
  String get thisFolderIsEmpty => 'Esta carpeta está vacía';

  @override
  String itemCountLabel(int count) {
    return '$count elementos';
  }

  @override
  String get failedToLoadFavorites => 'Error al cargar los favoritos';

  @override
  String get retry => 'Reintentar';

  @override
  String get noFavoritesYet => 'Aún no hay favoritos';

  @override
  String get favorites => 'Favoritos';

  @override
  String totalCountItems(int count) {
    return '$count elementos';
  }

  @override
  String get continuing => 'En emisión';

  @override
  String get ended => 'Finalizada';

  @override
  String get sortAndFilter => 'Ordenar y filtrar';

  @override
  String get type => 'Tipo';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get display => 'Visualización';

  @override
  String get imageType => 'Tipo de imagen';

  @override
  String get posterSize => 'Tamaño del póster';

  @override
  String get small => 'Pequeño';

  @override
  String get medium => 'Mediano';

  @override
  String get large => 'Grande';

  @override
  String get extraLarge => 'Muy grande';

  @override
  String libraryGenresTitle(String name) {
    return '$name — Géneros';
  }

  @override
  String get views => 'Vistas';

  @override
  String get albums => 'Álbumes';

  @override
  String get albumArtists => 'Artistas de álbum';

  @override
  String get artists => 'Artistas';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get noSavedBookmarks =>
      'Aún no hay marcadores guardados para este título.';

  @override
  String get openBook => 'Abrir libro';

  @override
  String get chapter => 'Capítulo';

  @override
  String get page => 'Página';

  @override
  String get bookmark => 'Marcador';

  @override
  String get justNow => 'Ahora mismo';

  @override
  String minutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String daysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String get discoverySubjects => 'Temas de descubrimiento';

  @override
  String get pickDiscoverySubjects => 'Elige qué temas mostrar en Descubrir.';

  @override
  String get apply => 'Aplicar';

  @override
  String get audiobookGenres => 'Géneros de audiolibros';

  @override
  String get pickAudiobookGenres =>
      'Elige qué géneros mostrar en Descubrir audiolibros.';

  @override
  String get discoverAudiobooks => 'Descubrir audiolibros';

  @override
  String get librivoxDescription =>
      'Títulos populares de dominio público de LibriVox.';

  @override
  String titlesCount(int count) {
    return '$count títulos';
  }

  @override
  String get scrollLeft => 'Desplazar a la izquierda';

  @override
  String get scrollRight => 'Desplazar a la derecha';

  @override
  String get couldNotLoadGenre =>
      'No se pudo cargar este género en este momento.';

  @override
  String get continueReading => 'Continuar leyendo';

  @override
  String get savedHighlights => 'Destacados guardados';

  @override
  String get continueListening => 'Continuar escuchando';

  @override
  String get listen => 'Escuchar';

  @override
  String get resume => 'Reanudar';

  @override
  String get failedToLoadLibrary => 'Error al cargar la biblioteca';

  @override
  String get popularNow => 'Popular ahora';

  @override
  String get savedForLater => 'Guardado para después';

  @override
  String get topListens => 'Más escuchados';

  @override
  String get unreadDiscoveries => 'Descubrimientos sin leer';

  @override
  String get pickUpAgain => 'Retomar';

  @override
  String get bookHighlightsDescription =>
      'Tus libros con destacados, favoritos o progreso de lectura.';

  @override
  String get handPickedFromLibrary => 'Seleccionados de tu biblioteca.';

  @override
  String get handPickedFromListeningQueue =>
      'Seleccionados de tu cola de escucha.';

  @override
  String get booksWithHighlights =>
      'Libros con destacados, favoritos o progreso de lectura.';

  @override
  String get jumpBackNarration =>
      'Vuelve a la narración sin tener que buscar dónde te quedaste.';

  @override
  String get unreadBooksReady =>
      'Libros sin leer listos para la próxima hora de tranquilidad.';

  @override
  String get quickAccessFavorites =>
      'Acceso rápido a los libros a los que siempre vuelves.';

  @override
  String get searchAudiobooks => 'Buscar audiolibros';

  @override
  String get searchYourLibrary => 'Buscar en tu biblioteca';

  @override
  String get pickUpStory => 'Retoma la historia donde la dejaste';

  @override
  String get savedPlacesChapters =>
      'Tus lugares guardados y capítulos sin terminar';

  @override
  String authorsCount(int count) {
    return '$count autores';
  }

  @override
  String genresCount(int count) {
    return '$count géneros';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent % completado';
  }

  @override
  String get readyWhenYouAre => 'Listo cuando tú lo estés';

  @override
  String get details => 'Detalles';

  @override
  String get listeningRoom => 'Sala de escucha';

  @override
  String get bookmarksAndProgress => 'Marcadores y progreso';

  @override
  String titlesArrangedForBrowsing(int count) {
    return '$count títulos organizados para explorar.';
  }

  @override
  String get titles => 'Títulos';

  @override
  String get allTitles => 'Todos los títulos';

  @override
  String get authors => 'Autores';

  @override
  String get browseByAuthor => 'Explorar por autor';

  @override
  String get browseByGenre => 'Explorar por género';

  @override
  String get discover => 'Descubrir';

  @override
  String get trendingTitlesOpenLibrary =>
      'Títulos en tendencia por tema de Open Library.';

  @override
  String get noBookmarkedItems => 'Aún no hay elementos marcados';

  @override
  String get nothingMatchesSection =>
      'Nada coincide con esta sección. Prueba otra pestaña o vuelve después de la sincronización de la biblioteca.';

  @override
  String get audiobooks => 'Audiolibros';

  @override
  String noLabelFound(String label) {
    return 'No se encontraron $label';
  }

  @override
  String get folder => 'Carpeta';

  @override
  String get filters => 'Filtros';

  @override
  String get readingStatus => 'Estado de lectura';

  @override
  String get playedStatus => 'Estado de reproducción';

  @override
  String get readStatus => 'Leído';

  @override
  String get watched => 'Visto';

  @override
  String get unread => 'Sin leer';

  @override
  String get unwatched => 'No visto';

  @override
  String get seriesStatus => 'Estado de la serie';

  @override
  String get allLibraries => 'Todas las bibliotecas';

  @override
  String get books => 'Libros';

  @override
  String get author => 'Autor';

  @override
  String get unknownAuthor => 'Autor desconocido';

  @override
  String get uncategorized => 'Sin categoría';

  @override
  String get overview => 'Sinopsis';

  @override
  String get noLibrivoxDescription =>
      'Aún no hay descripción de LibriVox para este título.';

  @override
  String get readers => 'Lectores';

  @override
  String get openLinks => 'Abrir enlaces';

  @override
  String get librivoxPage => 'Página de LibriVox';

  @override
  String get internetArchive => 'Internet Archive';

  @override
  String get rssFeed => 'Feed RSS';

  @override
  String get downloadZip => 'Descargar Zip';

  @override
  String sectionCountLabel(int count) {
    return '$count secciones';
  }

  @override
  String firstPublished(int year) {
    return 'Publicado por primera vez en $year';
  }

  @override
  String get noOpenLibraryOverview =>
      'Aún no hay sinopsis disponible de Open Library para este título.';

  @override
  String get subjects => 'Temas';

  @override
  String get all => 'Todos';

  @override
  String booksCount(int count) {
    return '$count libros';
  }

  @override
  String get couldNotLoadSubject =>
      'No se pudo cargar este tema en este momento.';

  @override
  String get audiobookDetails => 'Detalles del audiolibro';

  @override
  String authorsCountTitle(int count) {
    return '$count autores';
  }

  @override
  String audiobookCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count audiolibros',
      one: '1 audiolibro',
    );
    return '$_temp0';
  }

  @override
  String get trackList => 'Lista de pistas';

  @override
  String get itemListPlaceholder => 'La lista de elementos aparecerá aquí';

  @override
  String get favoriteTracksPlaceholder =>
      'Las pistas favoritas aparecerán aquí';

  @override
  String get failedToLoad => 'Error al cargar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get moreLikeThis => 'Más como esto';

  @override
  String get castAndCrew => 'Reparto y equipo';

  @override
  String get collection => 'Colección';

  @override
  String get episodes => 'Episodios';

  @override
  String get nextUp => 'A continuación';

  @override
  String get seasons => 'Temporadas';

  @override
  String get chapters => 'Capítulos';

  @override
  String get features => 'Características';

  @override
  String get movies => 'Películas';

  @override
  String get other => 'Otros';

  @override
  String get discography => 'Discografía';

  @override
  String get similarArtists => 'Artistas similares';

  @override
  String get tableOfContents => 'Índice';

  @override
  String get tracklist => 'Lista de pistas';

  @override
  String get biography => 'Biografía';

  @override
  String get authorDetails => 'Detalles del autor';

  @override
  String get noOverviewAvailable =>
      'Aún no hay sinopsis disponible para este título.';

  @override
  String get noBiographyAvailable =>
      'No hay biografía disponible para este autor.';

  @override
  String get noBooksFound => 'No se encontraron libros para este autor.';

  @override
  String get unableToLoadAuthorDetails =>
      'No se pudieron cargar los detalles del autor en este momento.';

  @override
  String published(int year) {
    return 'Publicado en $year';
  }

  @override
  String get publicationDateUnknown => 'Fecha de publicación desconocida';

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temporadas',
      one: '1 temporada',
    );
    return '$_temp0';
  }

  @override
  String endsAt(String time) {
    return 'Termina a las $time';
  }

  @override
  String get view => 'Ver';

  @override
  String get resumeReading => 'Continuar leyendo';

  @override
  String get read => 'Leer';

  @override
  String resumeFrom(String position) {
    return 'Reanudar desde $position';
  }

  @override
  String get play => 'Reproducir';

  @override
  String get startOver => 'Empezar de nuevo';

  @override
  String get restart => 'Reiniciar';

  @override
  String get readOffline => 'Leer sin conexión';

  @override
  String get playOffline => 'Reproducir sin conexión';

  @override
  String get audio => 'Audio';

  @override
  String get subtitles => 'Subtítulos';

  @override
  String get version => 'Versión';

  @override
  String get cast => 'Reparto';

  @override
  String get trailer => 'Tráiler';

  @override
  String get finished => 'Terminado';

  @override
  String get favorited => 'En favoritos';

  @override
  String get favorite => 'Favorito';

  @override
  String get playlist => 'Lista de reproducción';

  @override
  String get downloaded => 'Descargado';

  @override
  String get downloadAll => 'Descargar todo';

  @override
  String get download => 'Descargar';

  @override
  String get deleteDownloaded => 'Eliminar descarga';

  @override
  String get goToSeries => 'Ir a la serie';

  @override
  String get editMetadata => 'Editar metadatos';

  @override
  String get less => 'Menos';

  @override
  String get more => 'Más';

  @override
  String get deleteItem => 'Eliminar elemento';

  @override
  String get deletePlaylist => 'Eliminar lista de reproducción';

  @override
  String get deletePlaylistMessage =>
      '¿Eliminar esta lista de reproducción del servidor?';

  @override
  String get deleteItemMessage => '¿Eliminar este elemento del servidor?';

  @override
  String get failedToDeletePlaylist =>
      'Error al eliminar la lista de reproducción';

  @override
  String get failedToDeleteItem => 'Error al eliminar el elemento';

  @override
  String get renamePlaylist => 'Renombrar lista de reproducción';

  @override
  String get playlistName => 'Nombre de la lista de reproducción';

  @override
  String get deleteDownloadedAlbum => 'Eliminar álbum descargado';

  @override
  String deleteDownloadedTracksMessage(String title) {
    return '¿Eliminar las pistas descargadas de “$title”?';
  }

  @override
  String get downloadedTracksDeleted => 'Pistas descargadas eliminadas';

  @override
  String get downloadedTracksDeleteFailed =>
      'No se pudieron eliminar algunas pistas descargadas';

  @override
  String get noTracksLoaded => 'No hay pistas cargadas';

  @override
  String noItemsLoaded(String itemLabel) {
    return 'No hay $itemLabel cargados';
  }

  @override
  String downloadingTitle(String title, int count) {
    return 'Descargando $title ($count elementos)...';
  }

  @override
  String deleteConfirmMessage(String name) {
    return '¿Estás seguro de que quieres eliminar “$name” del servidor? Esta acción no se puede deshacer.';
  }

  @override
  String get itemDeleted => 'Elemento eliminado';

  @override
  String get noPlayableTrailerFound =>
      'No se encontró un tráiler reproducible.';

  @override
  String unsupportedBookFormat(String extension) {
    return 'Formato de libro no soportado: .$extension';
  }

  @override
  String get audioTrack => 'Pista de audio';

  @override
  String get subtitleTrack => 'Pista de subtítulos';

  @override
  String get none => 'Ninguno';

  @override
  String get downloadSubtitlesLabel => 'Descargar subtítulos...';

  @override
  String get searchOpenSubtitlesPlugin =>
      'Buscar usando el plugin de OpenSubtitles';

  @override
  String get downloadSubtitles => 'Descargar subtítulos';

  @override
  String get selectedSubtitleInvalid =>
      'El subtítulo seleccionado no es válido.';

  @override
  String subtitleDownloadedSelected(String name) {
    return 'Subtítulo descargado y seleccionado: $name';
  }

  @override
  String get subtitleDownloadedPending =>
      'Subtítulo descargado. Puede tardar un momento en aparecer mientras Jellyfin actualiza el elemento.';

  @override
  String noRemoteSubtitlesFound(String language) {
    return 'No se encontraron subtítulos remotos para $language.';
  }

  @override
  String get selectVersion => 'Seleccionar versión';

  @override
  String versionNumber(int number) {
    return 'Versión $number';
  }

  @override
  String get downloadAllQuality => 'Descargar todo — Calidad';

  @override
  String get downloadQuality => 'Calidad de descarga';

  @override
  String get originalFileNoReencoding => 'Archivo original, sin recodificación';

  @override
  String get originalFilesNoReencoding =>
      'Archivos originales, sin recodificación';

  @override
  String get noEpisodesLoaded => 'No hay episodios cargados';

  @override
  String downloadingItem(String name, String quality) {
    return 'Descargando $name ($quality)...';
  }

  @override
  String get deleteDownloadedFiles => 'Eliminar archivos descargados';

  @override
  String deleteLocalFilesMessage(String typeLabel) {
    return '¿Eliminar archivos locales de $typeLabel?\n\nEsto liberará espacio de almacenamiento. Puedes volver a descargarlos más tarde.';
  }

  @override
  String get downloadedFilesDeleted => 'Archivos descargados eliminados';

  @override
  String get failedToDeleteFiles => 'Error al eliminar archivos';

  @override
  String get deleteFiles => 'Eliminar archivos';

  @override
  String get director => 'DIRECTOR';

  @override
  String get writers => 'GUIONISTAS';

  @override
  String get studio => 'ESTUDIO';

  @override
  String studioMoreCount(int count) {
    return '+$count más';
  }

  @override
  String totalEpisodes(int count) {
    return '$count episodios';
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
    return 'Capítulo $number';
  }

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistas',
      one: '1 pista',
    );
    return '$_temp0';
  }

  @override
  String chapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capítulos',
      one: '1 capítulo',
    );
    return '$_temp0';
  }

  @override
  String born(String date) {
    return 'Nacido/a el $date';
  }

  @override
  String died(String date) {
    return 'Fallecido/a el $date';
  }

  @override
  String age(int age) {
    return 'Edad $age';
  }

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get readMore => 'Leer más';

  @override
  String get shuffle => 'Aleatorio';

  @override
  String downloadsCount(int count) {
    return '$count descargas';
  }

  @override
  String get perfectMatch => 'Coincidencia perfecta';

  @override
  String channelsCount(int count) {
    return '$count canales';
  }

  @override
  String get mono => 'Mono';

  @override
  String get stereo => 'Estéreo';

  @override
  String remoteSubtitlePermissionError(String action) {
    return 'La acción $action de subtítulos remotos requiere el permiso de gestión de subtítulos de Jellyfin para este usuario.';
  }

  @override
  String remoteSubtitleNotFoundError(String action) {
    return 'No se pudo encontrar este elemento en el servidor para la acción $action de subtítulos remotos.';
  }

  @override
  String remoteSubtitleDetailError(String action, String detail) {
    return 'Acción $action de subtítulos remotos fallida: $detail';
  }

  @override
  String remoteSubtitleHttpError(String action, int status) {
    return 'Acción $action de subtítulos remotos fallida (HTTP $status).';
  }

  @override
  String remoteSubtitleGenericError(String action) {
    return 'No se pudieron $action los subtítulos remotos.';
  }

  @override
  String deleteSeriesFiles(String name) {
    return 'todos los episodios descargados de “$name”';
  }

  @override
  String get deleteSeasonFiles =>
      'todos los episodios descargados de esta temporada';

  @override
  String get stillWatching => '¿Sigues viendo?';

  @override
  String get unableToLoadTrailerStream =>
      'No se pudo cargar el stream del tráiler.';

  @override
  String get trailerTimedOut =>
      'El tráiler agotó el tiempo de espera al cargar.';

  @override
  String get playbackFailedForTrailer =>
      'La reproducción falló para este tráiler.';

  @override
  String photoCountOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get castingUnavailableOffline =>
      'La transmisión no está disponible durante la reproducción sin conexión.';

  @override
  String castActionFailed(String label, String error) {
    return 'Acción de $label fallida: $error';
  }

  @override
  String failedToSetCastVolume(String error) {
    return 'Error al establecer el volumen de transmisión: $error';
  }

  @override
  String castControlsTitle(String label) {
    return 'Controles de $label';
  }

  @override
  String get deviceVolume => 'Volumen del dispositivo';

  @override
  String get unavailable => 'No disponible';

  @override
  String get pause => 'Pausa';

  @override
  String get syncPosition => 'Sincronizar posición';

  @override
  String stopCast(String label) {
    return 'Detener $label';
  }

  @override
  String get queueIsEmpty => 'La cola está vacía';

  @override
  String trackNumber(int number) {
    return 'Pista $number';
  }

  @override
  String get remotePlayback => 'Reproducción remota';

  @override
  String get castingToGoogleCast => 'Transmitiendo a Google Cast';

  @override
  String get castingViaAirPlay => 'Transmitiendo vía AirPlay';

  @override
  String get castingViaDlna => 'Transmitiendo vía DLNA';

  @override
  String secondsCount(int seconds) {
    return '$seconds segundos';
  }

  @override
  String get longPressToUnlock => 'Mantén pulsado para desbloquear';

  @override
  String get off => 'Desactivado';

  @override
  String streamTypeFallback(String streamType, int number) {
    return '$streamType $number';
  }

  @override
  String get auto => 'Automático';

  @override
  String bitrateValueMbps(int mbps) {
    return '$mbps Mbps';
  }

  @override
  String get audioDelay => 'Retardo de audio';

  @override
  String get subtitleDelay => 'Retardo de subtítulos';

  @override
  String get reset => 'Restablecer';

  @override
  String get unknown => 'Desconocido';

  @override
  String get playbackInformation => 'Información de reproducción';

  @override
  String get playback => 'Reproducción';

  @override
  String get playMethod => 'Método de reproducción';

  @override
  String get directPlay => 'Reproducción directa';

  @override
  String get directStream => 'Stream directo';

  @override
  String get transcoding => 'Transcodificación';

  @override
  String get transcodeReasons => 'Razones de transcodificación';

  @override
  String get player => 'Reproductor';

  @override
  String get container => 'Contenedor';

  @override
  String get bitrate => 'Tasa de bits';

  @override
  String get video => 'Vídeo';

  @override
  String get resolution => 'Resolución';

  @override
  String get hdr => 'HDR';

  @override
  String get codec => 'Códec';

  @override
  String get videoBitrate => 'Tasa de bits de vídeo';

  @override
  String get track => 'Pista';

  @override
  String get channels => 'Canales';

  @override
  String get audioBitrate => 'Tasa de bits de audio';

  @override
  String get sampleRate => 'Frecuencia de muestreo';

  @override
  String get format => 'Formato';

  @override
  String get external => 'Externo';

  @override
  String get embedded => 'Incrustado';

  @override
  String castSessionError(String protocol) {
    return 'Error de sesión de $protocol';
  }

  @override
  String failedToLoadBookDetails(String error) {
    return 'Error al cargar los detalles del libro: $error';
  }

  @override
  String get epubUnavailableOnPlatform =>
      'La visualización de EPUB en la app aún no está disponible en esta plataforma.';

  @override
  String formatCannotRenderInApp(String extension) {
    return 'Este formato (.$extension) aún no se puede visualizar en la app.';
  }

  @override
  String get embeddedRenderingUnavailable =>
      'La visualización de documentos incrustados no está disponible en esta plataforma.';

  @override
  String get couldNotOpenExternalViewer => 'No se pudo abrir el visor externo.';

  @override
  String failedToOpenInAppReader(String error) {
    return 'Error al abrir el lector integrado: $error';
  }

  @override
  String bookmarkAlreadySaved(String label) {
    return 'Marcador ya guardado en $label.';
  }

  @override
  String bookmarkAdded(String label) {
    return 'Marcador añadido: $label';
  }

  @override
  String get noBookmarksYet =>
      'Aún no hay marcadores.\nToca el icono de marcador mientras lees para guardar tu posición.';

  @override
  String get noTableOfContentsAvailable => 'No hay índice disponible';

  @override
  String pageLabel(int number) {
    return 'Página $number';
  }

  @override
  String get position => 'Posición';

  @override
  String get bookReader => 'Lector de libros';

  @override
  String formatExtension(String extension) {
    return 'Formato: .$extension';
  }

  @override
  String percentRead(String percent) {
    return '$percent % leído';
  }

  @override
  String get updating => 'Actualizando...';

  @override
  String get markUnread => 'Marcar como no leído';

  @override
  String get markAsRead => 'Marcar como leído';

  @override
  String get reloadReader => 'Recargar lector';

  @override
  String get noPagesFound => 'No se encontraron páginas.';

  @override
  String get failedToDecodePageImage =>
      'Error al decodificar la imagen de la página.';

  @override
  String resetZoom(String zoom) {
    return 'Restablecer zoom (${zoom}x)';
  }

  @override
  String get singlePage => 'Página simple';

  @override
  String get twoPageSpread => 'Doble página';

  @override
  String get addBookmark => 'Añadir marcador';

  @override
  String get bookmarksEllipsis => 'Marcadores...';

  @override
  String get markedAsRead => 'Marcado como leído';

  @override
  String get markedAsUnread => 'Marcado como no leído';

  @override
  String failedToUpdateReadState(String error) {
    return 'Error al actualizar el estado de lectura: $error';
  }

  @override
  String get themeSystem => 'Tema: Sistema';

  @override
  String get themeLight => 'Tema: Claro';

  @override
  String get themeDark => 'Tema: Oscuro';

  @override
  String get themeSepia => 'Tema: Sepia';

  @override
  String get invertColorsFixedLayout => 'Invertir colores (diseño fijo)';

  @override
  String get invertColorsPdf => 'Invertir colores (PDF)';

  @override
  String get preparingInAppReader => 'Preparando el lector integrado...';

  @override
  String get pdfDataNotAvailable => 'Datos PDF no disponibles.';

  @override
  String get readerFallbackModeActive => 'Modo alternativo del lector activo';

  @override
  String platformCannotHostDocumentEngine(String extension) {
    return 'Esta plataforma no puede alojar el motor de documentos incrustado para archivos $extension.';
  }

  @override
  String get reloadReaderPlatformHint =>
      'Usa Recargar lector después de cambiar a una plataforma compatible (Android, iOS, macOS).';

  @override
  String get openExternally => 'Abrir externamente';

  @override
  String get noEpubChaptersFound => 'No se encontraron capítulos EPUB.';

  @override
  String get readerNotReady => 'Lector no listo.';

  @override
  String get seriesRecordings => 'Grabaciones de series';

  @override
  String get now => 'Ahora';

  @override
  String get sports => 'Deportes';

  @override
  String get news => 'Noticias';

  @override
  String get kids => 'Infantil';

  @override
  String get premiere => 'Estreno';

  @override
  String get guideTimeline => 'Línea temporal de la guía';

  @override
  String failedToLoadGuide(String error) {
    return 'Error al cargar la guía: $error';
  }

  @override
  String get noChannelsFound => 'No se encontraron canales';

  @override
  String get liveBadge => 'EN VIVO';

  @override
  String get movie => 'Película';

  @override
  String get removedFromFavoriteChannels => 'Eliminado de canales favoritos';

  @override
  String get addedToFavoriteChannels => 'Añadido a canales favoritos';

  @override
  String get failedToUpdateFavoriteChannel =>
      'Error al actualizar el canal favorito';

  @override
  String get unfavoriteChannel => 'Quitar canal de favoritos';

  @override
  String get favoriteChannel => 'Canal favorito';

  @override
  String get watch => 'Ver';

  @override
  String get close => 'Cerrar';

  @override
  String failedToPlayChannel(String name) {
    return 'Error al reproducir $name';
  }

  @override
  String get failedToLoadRecordings => 'Error al cargar las grabaciones';

  @override
  String get scheduledInNext24Hours => 'Programadas en las próximas 24 horas';

  @override
  String get recentRecordings => 'Grabaciones recientes';

  @override
  String get tvSeries => 'Series de TV';

  @override
  String get failedToLoadSchedule => 'Error al cargar la programación';

  @override
  String get noScheduledRecordings => 'No hay grabaciones programadas';

  @override
  String get cancelRecording => '¿Cancelar grabación?';

  @override
  String cancelScheduledRecordingOf(String name) {
    return '¿Cancelar la grabación programada de “$name”?';
  }

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Sí, cancelar';

  @override
  String get failedToCancelRecording => 'Error al cancelar la grabación';

  @override
  String get failedToLoadSeriesRecordings =>
      'Error al cargar las grabaciones de series';

  @override
  String get noSeriesRecordings => 'No hay grabaciones de series';

  @override
  String get cancelSeriesRecording => 'Cancelar grabación de serie';

  @override
  String get cancelSeriesRecordingQuestion => '¿Cancelar grabación de serie?';

  @override
  String stopRecordingName(String name) {
    return '¿Detener la grabación de “$name”?';
  }

  @override
  String get failedToCancelSeriesRecording =>
      'Error al cancelar la grabación de serie';

  @override
  String get searchThisLibrary => 'Buscar en esta biblioteca...';

  @override
  String get searchEllipsis => 'Buscar...';

  @override
  String noResultsForQuery(String query) {
    return 'Sin resultados para “$query”';
  }

  @override
  String searchFailedError(String error) {
    return 'Error en la búsqueda: $error';
  }

  @override
  String get seerr => 'Seerr';

  @override
  String get savedMedia => 'Contenido guardado';

  @override
  String get tvShows => 'Series de TV';

  @override
  String get music => 'Música';

  @override
  String get musicAlbums => 'Álbumes de música';

  @override
  String get noMediaInFilter => 'No hay contenido en este filtro';

  @override
  String get noDownloadedMediaYet => 'Aún no hay contenido descargado';

  @override
  String get browseLibrary => 'Explorar biblioteca';

  @override
  String get deleteDownload => 'Eliminar descarga';

  @override
  String removeItemAndFiles(String name) {
    return '¿Eliminar “$name” y sus archivos?';
  }

  @override
  String tracksCount(int count) {
    return '$count pistas';
  }

  @override
  String get album => 'Álbum';

  @override
  String get playAlbum => 'Reproducir álbum';

  @override
  String failedToLoadAlbum(String error) {
    return 'Error al cargar el álbum: $error';
  }

  @override
  String noDownloadedTracksForAlbum(String name) {
    return 'No se encontraron pistas descargadas para $name.';
  }

  @override
  String get season => 'Temporada';

  @override
  String get errorLoadingEpisodes => 'Error al cargar los episodios';

  @override
  String get noDownloadedEpisodes => 'No hay episodios descargados';

  @override
  String get deleteEpisode => 'Eliminar episodio';

  @override
  String removeName(String name) {
    return '¿Eliminar “$name”?';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String seasonEpisodeLabel(int season, int episode) {
    return 'T$season E$episode';
  }

  @override
  String episodeNumber(int number) {
    return 'Episodio $number';
  }

  @override
  String get seriesNotFound => 'Serie no encontrada';

  @override
  String get errorLoadingSeries => 'Error al cargar la serie';

  @override
  String get downloadedEpisodes => 'Episodios descargados';

  @override
  String seasonNumber(int number) {
    return 'Temporada $number';
  }

  @override
  String get specials => 'Especiales';

  @override
  String get deleteSeason => 'Eliminar temporada';

  @override
  String deleteAllEpisodesInSeason(String season) {
    return '¿Eliminar todos los episodios descargados de $season?';
  }

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodios',
      one: '1 episodio',
    );
    return '$_temp0';
  }

  @override
  String get storageManagement => 'Gestión de almacenamiento';

  @override
  String get storageBreakdown => 'Desglose de almacenamiento';

  @override
  String get downloadedItems => 'Elementos descargados';

  @override
  String get storageLimit => 'Límite de almacenamiento';

  @override
  String get noLimit => 'Sin límite';

  @override
  String get deleteAllDownloads => 'Eliminar todas las descargas';

  @override
  String get deleteAllDownloadsWarning =>
      'Esto eliminará todos los archivos multimedia descargados y no se puede deshacer.';

  @override
  String get deleteAll => 'Eliminar todo';

  @override
  String get deleteSelected => 'Eliminar seleccionados';

  @override
  String deleteSelectedCount(int count) {
    return '¿Eliminar $count elementos descargados?';
  }

  @override
  String get musicAndAudiobooks => 'Música y audiolibros';

  @override
  String get images => 'Imágenes';

  @override
  String get database => 'Base de datos';

  @override
  String ofStorageLimit(String limit) {
    return 'de $limit de límite';
  }

  @override
  String get settings => 'Ajustes';

  @override
  String get authentication => 'Autenticación';

  @override
  String get autoLoginServerManagement =>
      'Inicio de sesión automático, gestión de servidores';

  @override
  String get pinCode => 'Código PIN';

  @override
  String get setUpPinCodeProtection => 'Configurar protección con código PIN';

  @override
  String get parentalControls => 'Control parental';

  @override
  String get contentRatingRestrictions =>
      'Restricciones de clasificación de contenido';

  @override
  String get bitRateResolutionBehavior =>
      'Tasa de bits, resolución, comportamiento';

  @override
  String get languageSizeAppearance => 'Idioma, tamaño, apariencia';

  @override
  String get qualityStorage => 'Calidad, almacenamiento';

  @override
  String get serverSyncAndPluginStatus =>
      'Sincronización del servidor y estado del plugin';

  @override
  String get mediaRequestIntegration =>
      'Integración de solicitudes de contenido';

  @override
  String get switchServer => 'Cambiar de servidor';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get versionLicenses => 'Versión, licencias';

  @override
  String get account => 'Cuenta';

  @override
  String get signInAndSecurity => 'Inicio de sesión y seguridad';

  @override
  String get administration => 'Administración';

  @override
  String get serverSettingsUsersLibraries =>
      'Ajustes del servidor, usuarios, bibliotecas';

  @override
  String get customization => 'Personalización';

  @override
  String get themeAndLayout => 'Tema y diseño';

  @override
  String get videoAndSubtitles => 'Vídeo y subtítulos';

  @override
  String get integrations => 'Integraciones';

  @override
  String get pluginAndRequests => 'Plugin y solicitudes';

  @override
  String get customizeAccountPlaybackInterface =>
      'Personalizar cuenta, reproducción e interfaz';

  @override
  String optionsCount(int count) {
    return '$count opciones';
  }

  @override
  String get themeAndAppearance => 'Tema y apariencia';

  @override
  String get focusBorderColor => 'Color del borde de enfoque';

  @override
  String get watchedIndicators => 'Indicadores de visto';

  @override
  String get always => 'Siempre';

  @override
  String get hideUnwatched => 'Ocultar no vistos';

  @override
  String get episodesOnly => 'Solo episodios';

  @override
  String get never => 'Nunca';

  @override
  String get focusExpansionAnimation => 'Animación de expansión al enfocar';

  @override
  String get scaleFocusedCards => 'Escalar tarjetas enfocadas';

  @override
  String get backgroundBackdrops => 'Fondos de pantalla';

  @override
  String get showBackdropImages => 'Mostrar imágenes de fondo';

  @override
  String get seriesThumbnails => 'Miniaturas de series';

  @override
  String get seriesThumbnailsDescription =>
      'Mostrar imágenes de episodios en tarjetas de series';

  @override
  String get homeRowInfoOverlay =>
      'Superposición de información en filas del inicio';

  @override
  String get showTitleMetadataOnHomeRows =>
      'Mostrar título y metadatos en las filas del inicio';

  @override
  String get clockDisplay => 'Visualización del reloj';

  @override
  String get inMenus => 'En los menús';

  @override
  String get inVideo => 'En el vídeo';

  @override
  String get seasonalEffects => 'Efectos estacionales';

  @override
  String get snow => 'Nieve';

  @override
  String get fireworks => 'Fuegos artificiales';

  @override
  String get confetti => 'Confeti';

  @override
  String get fallingLeaves => 'Hojas cayendo';

  @override
  String get themeMusic => 'Música de tema';

  @override
  String get playThemeMusicOnDetailPages =>
      'Reproducir música de tema en páginas de detalles';

  @override
  String get themeMusicVolume => 'Volumen de la música de tema';

  @override
  String percentValue(int value) {
    return '$value %';
  }

  @override
  String get themeMusicOnHomeRows => 'Música de tema en filas del inicio';

  @override
  String get playWhenBrowsingHomeScreen =>
      'Reproducir al navegar por la pantalla de inicio';

  @override
  String get detailsBackgroundBlur => 'Desenfoque de fondo en detalles';

  @override
  String pixelValue(int value) {
    return '$value px';
  }

  @override
  String get browsingBackgroundBlur => 'Desenfoque de fondo al navegar';

  @override
  String get maxStreamingBitrate => 'Tasa de bits máxima de streaming';

  @override
  String get maxResolution => 'Resolución máxima';

  @override
  String get playerZoomMode => 'Modo de zoom del reproductor';

  @override
  String get fit => 'Ajustar';

  @override
  String get autoCrop => 'Recorte automático';

  @override
  String get stretch => 'Estirar';

  @override
  String get refreshRateSwitching => 'Cambio de frecuencia de actualización';

  @override
  String get disabled => 'Desactivado';

  @override
  String get scaleOnTv => 'Escalar en TV';

  @override
  String get scaleOnDevice => 'Escalar en dispositivo';

  @override
  String get trickPlay => 'Trickplay';

  @override
  String get showPreviewThumbnailsWhenSeeking =>
      'Mostrar miniaturas de vista previa al buscar';

  @override
  String get showDescriptionOnPause => 'Mostrar descripción al pausar';

  @override
  String get dimVideoShowOverview => 'Atenuar vídeo y mostrar sinopsis';

  @override
  String get osdLockButton => 'Botón de bloqueo del OSD';

  @override
  String get osdLockButtonDescription =>
      'Mostrar botón de bloqueo en los controles del reproductor';

  @override
  String get audioBehavior => 'Comportamiento de audio';

  @override
  String get downmixToStereo => 'Mezclar a estéreo';

  @override
  String get defaultAudioLanguage => 'Idioma de audio predeterminado';

  @override
  String get autoServerDefault => 'Automático (predeterminado del servidor)';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Francés';

  @override
  String get german => 'Alemán';

  @override
  String get italian => 'Italiano';

  @override
  String get portuguese => 'Portugués';

  @override
  String get japanese => 'Japonés';

  @override
  String get korean => 'Coreano';

  @override
  String get chinese => 'Chino';

  @override
  String get russian => 'Ruso';

  @override
  String get arabic => 'Árabe';

  @override
  String get hindi => 'Hindi';

  @override
  String get dutch => 'Neerlandés';

  @override
  String get swedish => 'Sueco';

  @override
  String get norwegian => 'Noruego';

  @override
  String get danish => 'Danés';

  @override
  String get finnish => 'Finés';

  @override
  String get polish => 'Polaco';

  @override
  String get ac3Passthrough => 'Passthrough AC3';

  @override
  String get trueHdSupport => 'Soporte TrueHD';

  @override
  String get enableTrueHdAudio => 'Habilitar audio TrueHD';

  @override
  String get nightMode => 'Modo nocturno';

  @override
  String get compressDynamicRange => 'Comprimir rango dinámico';

  @override
  String get advancedMpv => 'MPV avanzado';

  @override
  String get enableCustomMpvConf => 'Habilitar mpv.conf personalizado';

  @override
  String get applyMpvConfBeforePlayback =>
      'Aplicar mpv.conf antes de la reproducción';

  @override
  String get unsafeAdvancedMpvOptions => 'Opciones avanzadas de MPV inseguras';

  @override
  String get unsafeMpvOptionsDescription =>
      'Estas opciones pueden causar fallos o comportamiento inesperado';

  @override
  String get nextUpAndQueuing => 'A continuación y cola';

  @override
  String get nextUpBehavior => 'Comportamiento de A continuación';

  @override
  String get extended => 'Extendido';

  @override
  String get minimal => 'Mínimo';

  @override
  String get nextUpTimeout => 'Tiempo de espera de A continuación';

  @override
  String secondsValue(int value) {
    return '$value segundos';
  }

  @override
  String get mediaQueuing => 'Cola de medios';

  @override
  String get autoQueueNextEpisodes =>
      'Añadir automáticamente los siguientes episodios a la cola';

  @override
  String get stillWatchingPrompt => 'Mensaje de ¿Sigues viendo?';

  @override
  String afterEpisodesAndHours(int episodes, double hours) {
    return 'Después de $episodes episodios / $hours h';
  }

  @override
  String get resumeAndSkip => 'Reanudar y saltar';

  @override
  String get resumeRewind => 'Retroceso al reanudar';

  @override
  String get fiveSeconds => '5 segundos';

  @override
  String get tenSeconds => '10 segundos';

  @override
  String get fifteenSeconds => '15 segundos';

  @override
  String get thirtySeconds => '30 segundos';

  @override
  String get skipBackLength => 'Duración del salto atrás';

  @override
  String get skipForwardLength => 'Duración del salto adelante';

  @override
  String get customMpvConfPath => 'Ruta del mpv.conf personalizado';

  @override
  String get notSetMpvConf =>
      'No establecido. Moonfin intentará usar un mpv.conf predeterminado en las carpetas de la app/datos.';

  @override
  String get selectMpvConf => 'Seleccionar mpv.conf';

  @override
  String get pathToMpvConf => '/ruta/a/mpv.conf';

  @override
  String get subtitleStyleDescription =>
      'Los ajustes de estilo (tamaño, color, desplazamiento) se aplican a subtítulos de texto (SRT, VTT, TTML). Los subtítulos ASS/SSA usan su propio estilo incrustado a menos que se desactive “Reproducción directa de ASS/SSA”. Los subtítulos de mapa de bits (PGS, DVB, VobSub) no se pueden reestilizar.';

  @override
  String get defaultSubtitleLanguage => 'Idioma de subtítulos predeterminado';

  @override
  String get defaultToNoSubtitles => 'Sin subtítulos por defecto';

  @override
  String get turnOffSubtitlesByDefault => 'Desactivar subtítulos por defecto';

  @override
  String get subtitleSize => 'Tamaño de subtítulos';

  @override
  String get textColor => 'Color del texto';

  @override
  String get backgroundColor => 'Color de fondo';

  @override
  String get strokeColor => 'Color del contorno';

  @override
  String get verticalOffset => 'Desplazamiento vertical';

  @override
  String get pgsDirectPlay => 'Reproducción directa de PGS';

  @override
  String get directPlayPgsSubtitles => 'Reproducción directa de subtítulos PGS';

  @override
  String get assSsaDirectPlay => 'Reproducción directa de ASS/SSA';

  @override
  String get directPlayAssSsaSubtitles =>
      'Reproducción directa de subtítulos ASS/SSA';

  @override
  String get white => 'Blanco';

  @override
  String get black => 'Negro';

  @override
  String get yellow => 'Amarillo';

  @override
  String get green => 'Verde';

  @override
  String get cyan => 'Cian';

  @override
  String get red => 'Rojo';

  @override
  String get transparent => 'Transparente';

  @override
  String get semiTransparentBlack => 'Negro semitransparente';

  @override
  String get global => 'Global';

  @override
  String get desktop => 'Escritorio';

  @override
  String get mobile => 'Móvil';

  @override
  String get tv => 'TV';

  @override
  String loadedProfileSettings(String profile) {
    return 'Ajustes del perfil $profile cargados.';
  }

  @override
  String failedToLoadProfileSettings(String profile) {
    return 'Error al cargar los ajustes del perfil $profile.';
  }

  @override
  String syncedSettingsToProfile(String profile) {
    return 'Ajustes locales sincronizados con el perfil $profile.';
  }

  @override
  String get customizationProfile => 'Perfil de personalización';

  @override
  String get customizationProfileDescription =>
      'Elige el perfil para cargar, editar y sincronizar. Global se aplica en todas partes a menos que un perfil de dispositivo lo anule. El punto verde marca tu perfil de dispositivo actual.';

  @override
  String get loadProfile => 'Cargar perfil';

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get syncToProfile => 'Sincronizar con perfil';

  @override
  String get profileSyncHidden => 'Sincronización de perfil oculta';

  @override
  String get enablePluginSyncDescription =>
      'Habilita la sincronización con el plugin del servidor en los ajustes de Plugin para mostrar los controles de perfil aquí.';

  @override
  String get quality => 'Calidad';

  @override
  String get defaultDownloadQuality => 'Calidad de descarga predeterminada';

  @override
  String get network => 'Red';

  @override
  String get wifiOnlyDownloads => 'Descargas solo por WiFi';

  @override
  String get onlyDownloadOnWifi => 'Solo descargar con conexión WiFi';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get storageUsed => 'Almacenamiento usado';

  @override
  String get manage => 'Gestionar';

  @override
  String get calculating => 'Calculando...';

  @override
  String get downloadLocation => 'Ubicación de descarga';

  @override
  String get defaultLabel => 'Predeterminado';

  @override
  String get saveToDownloadsFolder => 'Guardar en la carpeta de Descargas';

  @override
  String get downloadsVisibleToOtherApps =>
      'Descargas/Moonfin — visible para otras apps';

  @override
  String get dangerZone => 'Zona peligrosa';

  @override
  String get clearAllDownloads => 'Borrar todas las descargas';

  @override
  String get original => 'Original';

  @override
  String get changeDownloadLocation => 'Cambiar ubicación de descarga';

  @override
  String get changeDownloadLocationDescription =>
      'Las nuevas descargas se guardarán en la carpeta seleccionada. Las descargas existentes permanecerán en su ubicación actual y se pueden gestionar desde los ajustes de Almacenamiento.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cannotWriteToFolder =>
      'No se puede escribir en la carpeta seleccionada. Elige otra ubicación o concede permisos de almacenamiento.';

  @override
  String get saveToDownloadsFolderQuestion =>
      '¿Guardar en la carpeta de Descargas?';

  @override
  String get saveToDownloadsFolderDescription =>
      'El contenido descargado se guardará en Descargas/Moonfin en tu dispositivo. Estos archivos serán visibles para otras apps como tu galería o reproductor de música.';

  @override
  String get enable => 'Habilitar';

  @override
  String get clearAllDownloadsWarning =>
      'Esto eliminará todo el contenido descargado y no se puede deshacer.';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get navigationStyle => 'Estilo de navegación';

  @override
  String get topBar => 'Barra superior';

  @override
  String get leftSidebar => 'Barra lateral izquierda';

  @override
  String get showShuffleButton => 'Mostrar botón de aleatorio';

  @override
  String get showGenresButton => 'Mostrar botón de géneros';

  @override
  String get showFavoritesButton => 'Mostrar botón de favoritos';

  @override
  String get showLibrariesInToolbar =>
      'Mostrar bibliotecas en la barra de herramientas';

  @override
  String get navbarOpacity => 'Opacidad de la barra de navegación';

  @override
  String get navbarColor => 'Color de la barra de navegación';

  @override
  String get gray => 'Gris';

  @override
  String get darkBlue => 'Azul oscuro';

  @override
  String get purple => 'Púrpura';

  @override
  String get teal => 'Verde azulado';

  @override
  String get navy => 'Azul marino';

  @override
  String get charcoal => 'Carbón';

  @override
  String get brown => 'Marrón';

  @override
  String get darkRed => 'Rojo oscuro';

  @override
  String get darkGreen => 'Verde oscuro';

  @override
  String get slate => 'Pizarra';

  @override
  String get indigo => 'Índigo';

  @override
  String get libraryDisplay => 'Visualización de biblioteca';

  @override
  String get posterLabel => 'Póster';

  @override
  String get thumbnailLabel => 'Miniatura';

  @override
  String get bannerLabel => 'Pancarta';

  @override
  String get overridePerLibrarySettings => 'Anular ajustes por biblioteca';

  @override
  String get applyImageTypeToAllLibraries =>
      'Aplicar tipo de imagen a todas las bibliotecas';

  @override
  String get multiServerLibraries => 'Bibliotecas multiservisor';

  @override
  String get showLibrariesFromAllServers =>
      'Mostrar bibliotecas de todos los servidores conectados';

  @override
  String get enableFolderView => 'Habilitar vista de carpetas';

  @override
  String get showFolderBrowsingOption =>
      'Mostrar opción de exploración por carpetas';

  @override
  String get libraryVisibility => 'Visibilidad de la biblioteca';

  @override
  String get showInNavigation => 'Mostrar en la navegación';

  @override
  String get showInLatestMedia => 'Mostrar en contenido reciente';

  @override
  String get sourceLibraries => 'Bibliotecas de origen';

  @override
  String get sourceCollections => 'Colecciones de origen';

  @override
  String get excludedGenres => 'Géneros excluidos';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String itemsSelected(int count) {
    return '$count seleccionados';
  }

  @override
  String get mediaBar => 'Barra de medios';

  @override
  String get enableMediaBar => 'Habilitar barra de medios';

  @override
  String get showFeaturedContentSlideshow =>
      'Mostrar carrusel de contenido destacado en el inicio';

  @override
  String get contentType => 'Tipo de contenido';

  @override
  String get moviesAndTvShows => 'Películas y series de TV';

  @override
  String get moviesOnly => 'Solo películas';

  @override
  String get tvShowsOnly => 'Solo series de TV';

  @override
  String get itemCount => 'Cantidad de elementos';

  @override
  String get noneSelected => 'Ninguno seleccionado';

  @override
  String get noneExcluded => 'Ninguno excluido';

  @override
  String get autoAdvance => 'Avance automático';

  @override
  String get autoAdvanceSlides =>
      'Avanzar automáticamente a la siguiente diapositiva';

  @override
  String get autoAdvanceInterval => 'Intervalo de avance automático';

  @override
  String get trailerPreview => 'Vista previa de tráiler';

  @override
  String get autoPlayTrailers =>
      'Reproducir tráilers automáticamente en la barra de medios después de 3 segundos';

  @override
  String get episodePreview => 'Vista previa de episodio';

  @override
  String get episodePreviewDescription =>
      'Reproducir una vista previa de 30 segundos en tarjetas enfocadas, con el cursor encima o pulsación larga';

  @override
  String get previewAudio => 'Audio de vista previa';

  @override
  String get enablePreviewAudio =>
      'Habilitar audio para vistas previas de tráilers y episodios';

  @override
  String get latestMedia => 'Contenido reciente';

  @override
  String get recentlyReleased => 'Lanzado recientemente';

  @override
  String get myMedia => 'Mi contenido';

  @override
  String get myMediaSmall => 'Mi contenido (pequeño)';

  @override
  String get continueWatching => 'Continuar viendo';

  @override
  String get resumeAudio => 'Reanudar audio';

  @override
  String get resumeBooks => 'Reanudar libros';

  @override
  String get activeRecordings => 'Grabaciones activas';

  @override
  String get playlists => 'Listas de reproducción';

  @override
  String get liveTV => 'TV en vivo';

  @override
  String get homeSections => 'Secciones del inicio';

  @override
  String get resetToDefaults => 'Restablecer valores predeterminados';

  @override
  String get homeRowPosterSize => 'Tamaño de póster en filas del inicio';

  @override
  String get perRowImageTypeSelection => 'Selección de tipo de imagen por fila';

  @override
  String get configureImageTypeForEachRow =>
      'Configurar tipo de imagen para cada fila habilitada del inicio';

  @override
  String get mergeContinueWatchingAndNextUp =>
      'Fusionar Continuar viendo y A continuación';

  @override
  String get combineBothRows =>
      'Combinar ambas filas en una sola sección del inicio';

  @override
  String get perRowImageType => 'Tipo de imagen por fila';

  @override
  String get perRowSettings => 'Ajustes por fila';

  @override
  String get autoLogin => 'Inicio de sesión automático';

  @override
  String get lastUser => 'Último usuario';

  @override
  String get specificUser => 'Usuario específico';

  @override
  String get alwaysAuthenticate => 'Siempre autenticar';

  @override
  String get requirePasswordWithToken =>
      'Requerir contraseña incluso con token almacenado';

  @override
  String get confirmExit => 'Confirmar salida';

  @override
  String get showConfirmationBeforeExiting =>
      'Mostrar confirmación antes de salir';

  @override
  String get blockContentWithRatings =>
      'Bloquear contenido con las siguientes clasificaciones:';

  @override
  String get noContentRatingsFound =>
      'Aún no se encontraron clasificaciones de contenido en este servidor.';

  @override
  String get couldNotLoadServerRatings =>
      'No se pudieron cargar las clasificaciones del servidor. Mostrando solo las clasificaciones guardadas.';

  @override
  String get couldNotRefreshRatings =>
      'No se pudieron actualizar las clasificaciones del servidor. Mostrando las clasificaciones guardadas.';

  @override
  String get enablePinCode => 'Habilitar código PIN';

  @override
  String get requirePinToAccess => 'Requerir un PIN para acceder a tu cuenta';

  @override
  String get changePin => 'Cambiar PIN';

  @override
  String get setNewPinCode => 'Establecer un nuevo código PIN';

  @override
  String get removePin => 'Eliminar PIN';

  @override
  String get removePinProtection => 'Eliminar protección con código PIN';

  @override
  String get screensaver => 'Salvapantallas';

  @override
  String get inAppScreensaver => 'Salvapantallas de la app';

  @override
  String get enableBuiltInScreensaver =>
      'Habilitar el salvapantallas integrado';

  @override
  String get mode => 'Modo';

  @override
  String get libraryArt => 'Arte de la biblioteca';

  @override
  String get logo => 'Logotipo';

  @override
  String get clock => 'Reloj';

  @override
  String get timeout => 'Tiempo de espera';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get dimmingLevel => 'Nivel de atenuación';

  @override
  String get maxAgeRating => 'Clasificación máxima de edad';

  @override
  String get any => 'Cualquiera';

  @override
  String agePlusValue(int age) {
    return '$age+';
  }

  @override
  String get requireAgeRating => 'Requerir clasificación por edad';

  @override
  String get onlyShowRatedContent => 'Mostrar solo contenido clasificado';

  @override
  String get showClock => 'Mostrar reloj';

  @override
  String get displayClockDuringScreensaver =>
      'Mostrar reloj durante el salvapantallas';

  @override
  String get rottenTomatoesCritics => 'Rotten Tomatoes (Críticos)';

  @override
  String get rottenTomatoesAudience => 'Rotten Tomatoes (Audiencia)';

  @override
  String get imdb => 'IMDb';

  @override
  String get tmdb => 'TMDB';

  @override
  String get metacritic => 'Metacritic';

  @override
  String get metacriticUser => 'Metacritic (Usuario)';

  @override
  String get trakt => 'Trakt';

  @override
  String get letterboxd => 'Letterboxd';

  @override
  String get myAnimeList => 'MyAnimeList';

  @override
  String get aniList => 'AniList';

  @override
  String get communityRating => 'Valoración de la comunidad';

  @override
  String get ratings => 'Valoraciones';

  @override
  String get additionalRatings => 'Valoraciones adicionales';

  @override
  String get showMdbListAndTmdbRatings =>
      'Mostrar valoraciones de MDBList y TMDB';

  @override
  String get ratingLabels => 'Etiquetas de valoración';

  @override
  String get showLabelsNextToIcons =>
      'Mostrar etiquetas junto a los iconos de valoración';

  @override
  String get ratingBadges => 'Insignias de valoración';

  @override
  String get showDecorativeBadges =>
      'Mostrar insignias decorativas detrás de las valoraciones';

  @override
  String get episodeRatings => 'Valoraciones de episodios';

  @override
  String get showRatingsOnEpisodes =>
      'Mostrar valoraciones en episodios individuales';

  @override
  String get ratingSources => 'Fuentes de valoración';

  @override
  String get ratingSourcesDescription =>
      'Habilitar y reordenar las fuentes de valoración mostradas en la app';

  @override
  String get pluginLabel => 'Plugin';

  @override
  String get pluginDetected => 'Plugin detectado';

  @override
  String get pluginNotDetected => 'Plugin no detectado';

  @override
  String get pluginDetectedDescription =>
      'Plugin del servidor detectado. La sincronización se habilita automáticamente la primera vez que se encuentra el plugin.';

  @override
  String get pluginNotDetectedDescription =>
      'El plugin del servidor no se detecta actualmente. Los ajustes locales siguen usando sus valores guardados o los predeterminados.';

  @override
  String pluginStatusVersion(String status, String version) {
    return '$status';
  }

  @override
  String get availableServices => 'Servicios disponibles';

  @override
  String get serverPluginSync => 'Sincronización con plugin del servidor';

  @override
  String get syncSettingsWithPlugin =>
      'Sincronizar ajustes con el plugin del servidor';

  @override
  String get whatSyncControls => 'Qué controla la sincronización';

  @override
  String get syncControlsDescription =>
      'La sincronización solo controla si los ajustes respaldados por el plugin se envían y reciben del servidor. La selección de perfil y las acciones de sincronización de perfil están en los ajustes de Personalización cuando la sincronización del plugin está habilitada.';

  @override
  String get recentRequests => 'Solicitudes recientes';

  @override
  String get recentlyAdded => 'Añadido recientemente';

  @override
  String get trending => 'En tendencia';

  @override
  String get popularMovies => 'Películas populares';

  @override
  String get movieGenres => 'Géneros de películas';

  @override
  String get upcomingMovies => 'Próximas películas';

  @override
  String get studios => 'Estudios';

  @override
  String get popularSeries => 'Series populares';

  @override
  String get seriesGenres => 'Géneros de series';

  @override
  String get upcomingSeries => 'Próximas series';

  @override
  String get networks => 'Redes';

  @override
  String get resetRowsToDefaults =>
      'Restablecer filas a valores predeterminados';

  @override
  String get enableSeerr => 'Habilitar Seerr';

  @override
  String get showSeerrInNavigation =>
      'Mostrar Seerr en la navegación (requiere plugin del servidor)';

  @override
  String get seerrUnavailable =>
      'No disponible porque el soporte de Seerr del plugin del servidor está deshabilitado.';

  @override
  String get nsfwFilter => 'Filtro NSFW';

  @override
  String get hideAdultContent => 'Ocultar contenido adulto en los resultados';

  @override
  String loggedInAs(String username) {
    return 'Conectado como: $username';
  }

  @override
  String get discoverRows => 'Filas de Descubrir';

  @override
  String get discoverRowsDescriptionPlugin =>
      'Arrastra para reordenar. Habilita o deshabilita filas. El orden de filas habilitadas se sincroniza con el plugin de Moonfin.';

  @override
  String get discoverRowsDescription =>
      'Arrastra para reordenar. Habilita o deshabilita filas.';

  @override
  String get enabled => 'Habilitado';

  @override
  String get hidden => 'Oculto';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String versionValue(String version) {
    return 'Versión $version';
  }

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get sourceCode => 'Código fuente';

  @override
  String get checkForUpdatesNow => 'Buscar actualizaciones ahora';

  @override
  String get checksLatestDesktopRelease =>
      'Busca la última versión de escritorio para esta plataforma';

  @override
  String get youAreUpToDate => 'Estás actualizado.';

  @override
  String get couldNotCheckForUpdates =>
      'No se pudo buscar actualizaciones en este momento.';

  @override
  String get noCompatibleUpdate =>
      'No se encontró un paquete de actualización compatible para esta plataforma.';

  @override
  String get updateChecksNotSupported =>
      'La búsqueda de actualizaciones no es compatible con esta plataforma.';

  @override
  String get updateNotificationsDisabled =>
      'Las notificaciones de actualización están desactivadas.';

  @override
  String get pleaseWaitBeforeChecking => 'Espera antes de volver a comprobar.';

  @override
  String get latestUpdateAlreadyShown =>
      'La última actualización ya se ha mostrado.';

  @override
  String get updateAvailable => 'Actualización disponible.';

  @override
  String updateAvailableVersion(String version) {
    return 'Actualización disponible: v$version';
  }

  @override
  String get updateNotifications => 'Notificaciones de actualización';

  @override
  String get showWhenUpdatesAvailable =>
      'Mostrar cuando haya actualizaciones disponibles';

  @override
  String get navigation => 'Navegación';

  @override
  String get watchedIndicatorsBackdrops =>
      'Indicadores de visto, fondos de pantalla';

  @override
  String get focusColorWatchedIndicatorsBackdrops =>
      'Color de enfoque, indicadores de visto, fondos de pantalla';

  @override
  String get navbarStyleToolbarAppearance =>
      'Estilo de la barra de navegación, botones de la barra de herramientas, apariencia';

  @override
  String get reorderToggleHomeRows => 'Reordenar y alternar filas del inicio';

  @override
  String get featuredContentAppearance => 'Contenido destacado, apariencia';

  @override
  String get posterSizeImageTypeFolderView =>
      'Tamaño de póster, tipo de imagen, vista de carpetas';

  @override
  String get mdbListTmdbRatingSources =>
      'MDBList, TMDB y fuentes de valoración';

  @override
  String gbValue(String value) {
    return '$value GB';
  }

  @override
  String get clear => 'Borrar';

  @override
  String get browse => 'Explorar';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get seerrAvailableStatus => 'Disponible';

  @override
  String get seerrRequestedStatus => 'Solicitado';

  @override
  String itemsCount(int count) {
    return '$count elementos';
  }

  @override
  String get seerrSettings => 'Ajustes de Seerr';

  @override
  String get requestMore => 'Solicitar más';

  @override
  String get request => 'Solicitar';

  @override
  String get cancelRequest => 'Cancelar solicitud';

  @override
  String get playInMoonfin => 'Reproducir en Moonfin';

  @override
  String requestedByName(String name) {
    return 'Solicitado por $name';
  }

  @override
  String get approve => 'Aprobar';

  @override
  String get declineAction => 'Rechazar';

  @override
  String get similar => 'Similar';

  @override
  String get recommendations => 'Recomendaciones';

  @override
  String cancelRequestForTitle(String title) {
    return '¿Cancelar solicitud de “$title”?';
  }

  @override
  String cancelCountRequestsForTitle(int count, String title) {
    return '¿Cancelar $count solicitudes de “$title”?';
  }

  @override
  String get keep => 'Mantener';

  @override
  String get itemNotFoundInLibrary =>
      'Elemento no encontrado en tu biblioteca de Moonfin';

  @override
  String get errorSearchingLibrary => 'Error al buscar en la biblioteca';

  @override
  String budgetAmount(String amount) {
    return 'Presupuesto: \$$amount';
  }

  @override
  String revenueAmount(String amount) {
    return 'Ingresos: \$$amount';
  }

  @override
  String seasonsCount(int count, String label) {
    return '$count $label';
  }

  @override
  String requestSeriesOrMovie(String type) {
    return 'Solicitar $type';
  }

  @override
  String get submitRequest => 'Enviar solicitud';

  @override
  String get allSeasons => 'Todas las temporadas';

  @override
  String get advancedOptions => 'Opciones avanzadas';

  @override
  String get noServiceServersConfigured =>
      'No hay servidores de servicio configurados';

  @override
  String get server => 'Servidor';

  @override
  String get qualityProfile => 'Perfil de calidad';

  @override
  String get rootFolder => 'Carpeta raíz';

  @override
  String get showMore => 'Mostrar más';

  @override
  String get appearances => 'Apariciones';

  @override
  String get crewSection => 'Equipo';

  @override
  String ageValue(int age) {
    return 'edad $age';
  }

  @override
  String get noRequests => 'Sin solicitudes';

  @override
  String get pendingStatus => 'Pendiente';

  @override
  String get declinedStatus => 'Rechazado';

  @override
  String get partiallyAvailable => 'Parcialmente disponible';

  @override
  String get downloadingStatus => 'Descargando';

  @override
  String get approvedStatus => 'Aprobado';

  @override
  String get access => 'Acceso';

  @override
  String get add => 'Añadir';

  @override
  String get address => 'Dirección';

  @override
  String get analytics => 'Analíticas';

  @override
  String get catalog => 'Catálogo';

  @override
  String get content => 'Contenido';

  @override
  String get copy => 'Copiar';

  @override
  String get create => 'Crear';

  @override
  String get disable => 'Deshabilitar';

  @override
  String get done => 'Hecho';

  @override
  String get edit => 'Editar';

  @override
  String get encoding => 'Codificación';

  @override
  String get error => 'Error';

  @override
  String get forward => 'Adelante';

  @override
  String get general => 'General';

  @override
  String get go => 'Ir';

  @override
  String get install => 'Instalar';

  @override
  String get installed => 'Instalado';

  @override
  String get interval => 'Intervalo';

  @override
  String get name => 'Nombre';

  @override
  String get networking => 'Redes';

  @override
  String get next => 'Siguiente';

  @override
  String get path => 'Ruta';

  @override
  String get paused => 'En pausa';

  @override
  String get permissions => 'Permisos';

  @override
  String get processing => 'Procesando';

  @override
  String get profile => 'Perfil';

  @override
  String get provider => 'Proveedor';

  @override
  String get refresh => 'Actualizar';

  @override
  String get remote => 'Remoto';

  @override
  String get rename => 'Renombrar';

  @override
  String get revoke => 'Revocar';

  @override
  String get role => 'Rol';

  @override
  String get root => 'Raíz';

  @override
  String get run => 'Ejecutar';

  @override
  String get search => 'Buscar';

  @override
  String get select => 'Seleccionar';

  @override
  String get send => 'Enviar';

  @override
  String get sessions => 'Sesiones';

  @override
  String get set => 'Establecer';

  @override
  String get status => 'Estado';

  @override
  String get stop => 'Detener';

  @override
  String get streaming => 'Streaming';

  @override
  String get time => 'Hora';

  @override
  String get trickplay => 'Trickplay';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get up => 'Arriba';

  @override
  String get update => 'Actualizar';

  @override
  String get upload => 'Subir';

  @override
  String get unmute => 'Activar sonido';

  @override
  String get mute => 'Silenciar';

  @override
  String get branding => 'Marca';

  @override
  String get adminDrawerDashboard => 'Panel de control';

  @override
  String get adminDrawerAnalytics => 'Analíticas';

  @override
  String get adminDrawerSettings => 'Ajustes';

  @override
  String get adminDrawerBranding => 'Marca';

  @override
  String get adminDrawerUsers => 'Usuarios';

  @override
  String get adminDrawerLibraries => 'Bibliotecas';

  @override
  String get adminDrawerTranscoding => 'Transcodificación';

  @override
  String get adminDrawerResume => 'Reanudación';

  @override
  String get adminDrawerStreaming => 'Streaming';

  @override
  String get adminDrawerTrickplay => 'Trickplay';

  @override
  String get adminDrawerDevices => 'Dispositivos';

  @override
  String get adminDrawerActivity => 'Actividad';

  @override
  String get adminDrawerNetworking => 'Redes';

  @override
  String get adminDrawerApiKeys => 'Claves API';

  @override
  String get adminDrawerBackups => 'Copias de seguridad';

  @override
  String get adminDrawerLogs => 'Registros';

  @override
  String get adminDrawerScheduledTasks => 'Tareas programadas';

  @override
  String get adminDrawerPlugins => 'Plugins';

  @override
  String get adminDrawerRepositories => 'Repositorios';

  @override
  String get adminDrawerLiveTv => 'TV en vivo';

  @override
  String get adminExitTooltip => 'Salir de Admin';

  @override
  String get adminDashboardLoadFailed => 'Error al cargar el panel de control';

  @override
  String get adminMediaOverview => 'Vista general de medios';

  @override
  String get adminMediaTotalsError =>
      'No se pudieron cargar los totales de medios del servidor.';

  @override
  String get adminMediaOverviewSubtitle =>
      'Un resumen rápido de cuánto contenido hay en este servidor.';

  @override
  String adminPluginUpdatesAvailable(int count) {
    return 'Actualizaciones de plugins disponibles: $count';
  }

  @override
  String adminPluginsRequiringRestart(int count) {
    return 'Plugins que requieren reinicio: $count';
  }

  @override
  String adminFailedScheduledTasks(int count) {
    return 'Tareas programadas fallidas: $count';
  }

  @override
  String adminRecentAlertEntries(int count) {
    return 'Entradas recientes de advertencia/error: $count';
  }

  @override
  String get analyticsMediaDistribution => 'Distribución de medios';

  @override
  String get analyticsVideoCodecs => 'Códecs de vídeo';

  @override
  String get analyticsAudioCodecs => 'Códecs de audio';

  @override
  String get analyticsContainers => 'Contenedores';

  @override
  String get analyticsTopGenres => 'Principales géneros';

  @override
  String get analyticsReleaseYears => 'Años de lanzamiento';

  @override
  String get analyticsContentRatings => 'Clasificaciones de contenido';

  @override
  String get analyticsRuntimeBuckets => 'Rangos de duración';

  @override
  String get analyticsFileFormats => 'Formatos de archivo';

  @override
  String get analyticsNoData => 'No hay datos disponibles.';

  @override
  String get adminServerInfo => 'Información del servidor';

  @override
  String get adminRestartPending => 'Reinicio pendiente';

  @override
  String get adminServerPaths => 'Rutas del servidor';

  @override
  String get adminServerActions => 'Acciones del servidor';

  @override
  String get adminRestartServer => 'Reiniciar servidor';

  @override
  String get adminShutdownServer => 'Apagar servidor';

  @override
  String get adminScanLibraries => 'Escanear bibliotecas';

  @override
  String get adminLibraryScanStarted => 'Escaneo de bibliotecas iniciado';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get adminServerRebootInProgress => 'Reinicio del servidor en curso';

  @override
  String get adminServerRebootMessage =>
      'Reinicio del servidor en curso, por favor reinicia Moonfin';

  @override
  String get adminActiveSessions => 'Sesiones activas';

  @override
  String get adminSessionsLoadFailed => 'Error al cargar las sesiones';

  @override
  String get adminNoActiveSessions => 'No hay sesiones activas';

  @override
  String get adminRecentActivity => 'Actividad reciente';

  @override
  String get adminNoRecentActivity => 'No hay actividad reciente';

  @override
  String adminCommandFailed(String error) {
    return 'Comando fallido: $error';
  }

  @override
  String get adminSendMessage => 'Enviar mensaje';

  @override
  String get adminMessageTextHint => 'Texto del mensaje';

  @override
  String get adminSetVolume => 'Establecer volumen';

  @override
  String get sessionPrev => 'Anterior';

  @override
  String get sessionRewind => 'Retroceder';

  @override
  String get sessionForward => 'Adelantar';

  @override
  String get sessionNext => 'Siguiente';

  @override
  String get sessionVolumeDown => 'Vol –';

  @override
  String get sessionVolumeUp => 'Vol +';

  @override
  String get nowPlaying => 'Reproduciendo ahora';

  @override
  String get volume => 'Volumen';

  @override
  String get actions => 'Acciones';

  @override
  String get videoCodec => 'Códec de vídeo';

  @override
  String get audioCodec => 'Códec de audio';

  @override
  String get hwAccel => 'Aceleración HW';

  @override
  String get completion => 'Progreso';

  @override
  String get direct => 'Directo';

  @override
  String get adminDisconnect => 'Desconectar';

  @override
  String get adminClearDates => 'Borrar fechas';

  @override
  String adminActivityLoadFailed(String error) {
    return 'Error al cargar el registro de actividad: $error';
  }

  @override
  String get adminNoActivityEntries => 'No hay entradas de actividad';

  @override
  String get adminEditDeviceName => 'Editar nombre del dispositivo';

  @override
  String get adminCustomName => 'Nombre personalizado';

  @override
  String get adminDeviceNameUpdated => 'Nombre del dispositivo actualizado';

  @override
  String adminDeviceUpdateFailed(String error) {
    return 'Error al actualizar el dispositivo: $error';
  }

  @override
  String get adminDeleteDevice => 'Eliminar dispositivo';

  @override
  String get adminDeviceDeleted => 'Dispositivo eliminado';

  @override
  String adminDeviceDeleteFailed(String error) {
    return 'Error al eliminar el dispositivo: $error';
  }

  @override
  String get adminDevicesLoadFailed => 'Error al cargar los dispositivos';

  @override
  String get adminSearchDevices => 'Buscar dispositivos';

  @override
  String get adminThisDevice => 'Este dispositivo';

  @override
  String get adminEditName => 'Editar nombre';

  @override
  String get adminLibrariesLoadFailed => 'Error al cargar las bibliotecas';

  @override
  String get adminNoLibraries => 'No hay bibliotecas configuradas';

  @override
  String get adminScanAllLibraries => 'Escanear todas las bibliotecas';

  @override
  String get adminAddLibrary => 'Añadir biblioteca';

  @override
  String adminScanFailed(String error) {
    return 'Error al iniciar el escaneo: $error';
  }

  @override
  String get adminRenameLibrary => 'Renombrar biblioteca';

  @override
  String get adminNewName => 'Nuevo nombre';

  @override
  String adminLibraryRenamed(String name) {
    return 'Biblioteca renombrada a “$name”';
  }

  @override
  String adminRenameFailed(String error) {
    return 'Error al renombrar: $error';
  }

  @override
  String get adminDeleteLibrary => 'Eliminar biblioteca';

  @override
  String adminLibraryDeleted(String name) {
    return 'Biblioteca “$name” eliminada';
  }

  @override
  String adminLibraryDeleteFailed(String error) {
    return 'Error al eliminar la biblioteca: $error';
  }

  @override
  String adminAddPathFailed(String error) {
    return 'Error al añadir la ruta: $error';
  }

  @override
  String get adminRemovePath => 'Eliminar ruta';

  @override
  String adminRemovePathConfirm(String path) {
    return '¿Eliminar “$path” de esta biblioteca?';
  }

  @override
  String adminRemovePathFailed(String error) {
    return 'Error al eliminar la ruta: $error';
  }

  @override
  String get adminLibraryOptionsSaved => 'Opciones de biblioteca guardadas';

  @override
  String adminLibraryOptionsSaveFailed(String error) {
    return 'Error al guardar las opciones: $error';
  }

  @override
  String get adminLibraryLoadFailed => 'Error al cargar la biblioteca';

  @override
  String get adminNoMediaPaths => 'No hay rutas de medios configuradas';

  @override
  String get adminAddPath => 'Añadir ruta';

  @override
  String get adminBrowseFilesystem =>
      'Explorar el sistema de archivos del servidor:';

  @override
  String get adminSaveOptions => 'Guardar opciones';

  @override
  String get adminPreferredMetadataLanguage => 'Idioma de metadatos preferido';

  @override
  String get adminMetadataLanguageHint => 'p. ej. en, de, fr';

  @override
  String get adminMetadataCountryCode => 'Código de país de metadatos';

  @override
  String get adminMetadataCountryHint => 'p. ej. US, DE, FR';

  @override
  String get adminLibraryNameRequired =>
      'El nombre de la biblioteca es obligatorio';

  @override
  String adminLibraryCreateFailed(String error) {
    return 'Error al crear la biblioteca: $error';
  }

  @override
  String get adminLibraryName => 'Nombre de la biblioteca';

  @override
  String get adminSelectedPaths => 'Rutas seleccionadas:';

  @override
  String get adminNoPathsAdded =>
      'No se añadieron rutas (se pueden añadir después)';

  @override
  String get adminCreateLibrary => 'Crear biblioteca';

  @override
  String get paths => 'Rutas:';

  @override
  String get adminDisableUser => 'Deshabilitar usuario';

  @override
  String get adminEnableUser => 'Habilitar usuario';

  @override
  String adminDisableUserConfirm(String name) {
    return '¿Deshabilitar a $name? No podrá iniciar sesión.';
  }

  @override
  String adminEnableUserConfirm(String name) {
    return '¿Habilitar a $name? Podrá iniciar sesión de nuevo.';
  }

  @override
  String adminUserDisabled(String name) {
    return 'Usuario “$name” deshabilitado';
  }

  @override
  String adminUserEnabled(String name) {
    return 'Usuario “$name” habilitado';
  }

  @override
  String adminUserPolicyUpdateFailed(String error) {
    return 'Error al actualizar la política del usuario: $error';
  }

  @override
  String get adminUsersLoadFailed => 'Error al cargar los usuarios';

  @override
  String get adminSearchUsers => 'Buscar usuarios';

  @override
  String get adminEditUser => 'Editar usuario';

  @override
  String get adminAddUser => 'Añadir usuario';

  @override
  String adminUserCreateFailed(String error) {
    return 'Error al crear el usuario: $error';
  }

  @override
  String get adminCreateUser => 'Crear usuario';

  @override
  String get adminPasswordOptional => 'Contraseña (opcional)';

  @override
  String get adminUsernameRequired =>
      'El nombre de usuario no puede estar vacío';

  @override
  String get adminNoProfileChanges => 'No hay cambios de perfil que guardar';

  @override
  String get adminProfileSaved => 'Perfil guardado';

  @override
  String adminSaveFailed(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get adminPermissionsSaved => 'Permisos guardados';

  @override
  String get adminPasswordsMismatch => 'Las contraseñas no coinciden';

  @override
  String adminFailed(String error) {
    return 'Error: $error';
  }

  @override
  String get adminUserLoadFailed => 'Error al cargar el usuario';

  @override
  String get adminBackToUsers => 'Volver a usuarios';

  @override
  String get adminSaveProfile => 'Guardar perfil';

  @override
  String get adminDeleteUser => 'Eliminar usuario';

  @override
  String get admin => 'Admin';

  @override
  String get adminFullAccessWarning =>
      'Los administradores tienen acceso completo al servidor. Concede con precaución.';

  @override
  String get administrator => 'Administrador';

  @override
  String get adminHiddenUser => 'Usuario oculto';

  @override
  String get adminAllowMediaPlayback => 'Permitir reproducción de medios';

  @override
  String get adminAllowAudioTranscoding =>
      'Permitir transcodificación de audio';

  @override
  String get adminAllowVideoTranscoding =>
      'Permitir transcodificación de vídeo';

  @override
  String get adminAllowRemuxing => 'Permitir remuxing';

  @override
  String get adminForceRemoteTranscoding =>
      'Forzar transcodificación de fuente remota';

  @override
  String get adminAllowContentDeletion => 'Permitir eliminación de contenido';

  @override
  String get adminAllowContentDownloading => 'Permitir descarga de contenido';

  @override
  String get adminAllowPublicSharing => 'Permitir compartir públicamente';

  @override
  String get adminAllowRemoteControl =>
      'Permitir control remoto de otros usuarios';

  @override
  String get adminAllowSharedDeviceControl =>
      'Permitir control de dispositivo compartido';

  @override
  String get adminAllowRemoteAccess => 'Permitir acceso remoto';

  @override
  String get adminRemoteBitrateLimit =>
      'Límite de tasa de bits del cliente remoto (bps)';

  @override
  String get adminLeaveEmptyNoLimit => 'Dejar vacío para sin límite';

  @override
  String get adminMaxActiveSessions => 'Máximo de sesiones activas';

  @override
  String get adminAllowLiveTvAccess => 'Permitir acceso a TV en vivo';

  @override
  String get adminAllowLiveTvManagement => 'Permitir gestión de TV en vivo';

  @override
  String get adminAllowCollectionManagement =>
      'Permitir gestión de colecciones';

  @override
  String get adminAllowSubtitleManagement => 'Permitir gestión de subtítulos';

  @override
  String get adminAllowLyricManagement => 'Permitir gestión de letras';

  @override
  String get adminSavePermissions => 'Guardar permisos';

  @override
  String get adminEnableAllLibraryAccess =>
      'Habilitar acceso a todas las bibliotecas';

  @override
  String get adminSaveAccess => 'Guardar acceso';

  @override
  String get adminChangePassword => 'Cambiar contraseña';

  @override
  String get adminNewPassword => 'Nueva contraseña';

  @override
  String get adminConfirmPassword => 'Confirmar contraseña';

  @override
  String get adminSetPassword => 'Establecer contraseña';

  @override
  String get adminResetPassword => 'Restablecer contraseña';

  @override
  String adminDeleteUserConfirm(String name) {
    return '¿Estás seguro de que quieres eliminar a $name?';
  }

  @override
  String adminUserDeleted(String name) {
    return 'Usuario “$name” eliminado';
  }

  @override
  String adminUserDeleteFailed(String error) {
    return 'Error al eliminar el usuario: $error';
  }

  @override
  String get adminCreateApiKey => 'Crear clave API';

  @override
  String get adminAppName => 'Nombre de la app';

  @override
  String get adminApiKeyCreated => 'Clave API creada';

  @override
  String get adminApiKeyCreatedNoToken =>
      'Clave creada correctamente. El servidor no devolvió el token. Comprueba las claves API del servidor.';

  @override
  String get adminKeyCopied => 'Clave copiada al portapapeles';

  @override
  String adminApiKeyCreateFailed(String error) {
    return 'Error al crear la clave: $error';
  }

  @override
  String get adminKeyTokenMissing =>
      'Token de clave ausente en la respuesta del servidor';

  @override
  String get adminRevokeApiKey => 'Revocar clave API';

  @override
  String adminRevokeKeyConfirm(String name) {
    return '¿Revocar la clave de $name?';
  }

  @override
  String get adminApiKeyRevoked => 'Clave API revocada';

  @override
  String adminApiKeyRevokeFailed(String error) {
    return 'Error al revocar la clave: $error';
  }

  @override
  String get adminApiKeysLoadFailed => 'Error al cargar las claves API';

  @override
  String get adminCreateKey => 'Crear clave';

  @override
  String get adminNoApiKeys => 'No se encontraron claves API';

  @override
  String get adminCreatingBackup => 'Creando copia de seguridad...';

  @override
  String get adminBackupCreated => 'Copia de seguridad creada correctamente';

  @override
  String adminBackupCreateFailed(String error) {
    return 'Error al crear la copia de seguridad: $error';
  }

  @override
  String get adminBackupPathMissing =>
      'Ruta de copia de seguridad ausente en la respuesta del servidor';

  @override
  String adminBackupManifest(String name) {
    return 'Manifiesto: $name';
  }

  @override
  String adminManifestLoadFailed(String error) {
    return 'Error al cargar el manifiesto: $error';
  }

  @override
  String get adminConfirmRestore => 'Confirmar restauración';

  @override
  String get adminRestoringBackup => 'Restaurando copia de seguridad...';

  @override
  String adminRestoreFailed(String error) {
    return 'Error al restaurar la copia de seguridad: $error';
  }

  @override
  String get adminBackupsLoadFailed =>
      'Error al cargar las copias de seguridad';

  @override
  String get adminCreateBackup => 'Crear copia de seguridad';

  @override
  String get adminNoBackups => 'No se encontraron copias de seguridad';

  @override
  String get adminViewDetails => 'Ver detalles';

  @override
  String get restore => 'Restaurar';

  @override
  String get adminLogsLoadFailed =>
      'Error al cargar los registros del servidor';

  @override
  String get adminNoLogFiles => 'No se encontraron archivos de registro';

  @override
  String get adminLogCopied => 'Registro copiado al portapapeles';

  @override
  String get adminSaveLogFile => 'Guardar archivo de registro';

  @override
  String adminSavedTo(String path) {
    return 'Guardado en $path';
  }

  @override
  String adminFileSaveFailed(String error) {
    return 'Error al guardar el archivo: $error';
  }

  @override
  String adminLogFileLoadFailed(String fileName) {
    return 'Error al cargar $fileName';
  }

  @override
  String get adminSearchInLog => 'Buscar en el registro';

  @override
  String get adminNoMatchingLines => 'No hay líneas coincidentes';

  @override
  String adminTasksLoadFailed(String error) {
    return 'Error al cargar las tareas: $error';
  }

  @override
  String get adminNoScheduledTasks => 'No se encontraron tareas programadas';

  @override
  String get adminNoTasksMatchFilter =>
      'Ninguna tarea coincide con el filtro actual';

  @override
  String adminTaskStartFailed(String error) {
    return 'Error al iniciar la tarea: $error';
  }

  @override
  String adminTaskStopFailed(String error) {
    return 'Error al detener la tarea: $error';
  }

  @override
  String adminTaskLoadFailed(String error) {
    return 'Error al cargar la tarea: $error';
  }

  @override
  String get adminRunNow => 'Ejecutar ahora';

  @override
  String adminTriggerRemoveFailed(String error) {
    return 'Error al eliminar el disparador: $error';
  }

  @override
  String adminTriggerAddFailed(String error) {
    return 'Error al añadir el disparador: $error';
  }

  @override
  String get adminLastExecution => 'Última ejecución';

  @override
  String get adminTriggers => 'Disparadores';

  @override
  String get adminAddTrigger => 'Añadir disparador';

  @override
  String get adminNoTriggers => 'No hay disparadores configurados';

  @override
  String get adminTriggerType => 'Tipo de disparador';

  @override
  String get adminTimeLimit => 'Límite de tiempo (opcional)';

  @override
  String get adminNoLimit => 'Sin límite';

  @override
  String adminHours(String hours) {
    return '$hours hora(s)';
  }

  @override
  String get adminDayOfWeek => 'Día de la semana';

  @override
  String get adminSearchPlugins => 'Buscar plugins...';

  @override
  String adminPluginToggleFailed(String error) {
    return 'Error al alternar el plugin: $error';
  }

  @override
  String get adminUninstallPlugin => 'Desinstalar plugin';

  @override
  String adminUninstallPluginConfirm(String name) {
    return '¿Estás seguro de que quieres desinstalar “$name”?';
  }

  @override
  String adminPluginUninstallFailed(String error) {
    return 'Error al desinstalar el plugin: $error';
  }

  @override
  String adminPackageInstallFailed(String error) {
    return 'Error al instalar el paquete: $error';
  }

  @override
  String adminPluginUpdateFailed(String error) {
    return 'Error al instalar la actualización: $error';
  }

  @override
  String adminPluginsLoadFailed(String error) {
    return 'Error al cargar los plugins: $error';
  }

  @override
  String get adminNoPluginsMatchSearch =>
      'Ningún plugin coincide con tu búsqueda';

  @override
  String get adminNoPluginsInstalled => 'No hay plugins instalados';

  @override
  String adminInstallUpdate(String version) {
    return 'Instalar actualización (v$version)';
  }

  @override
  String adminCatalogLoadFailed(String error) {
    return 'Error al cargar el catálogo: $error';
  }

  @override
  String get adminNoPackagesMatchSearch =>
      'Ningún paquete coincide con tu búsqueda';

  @override
  String get adminNoPackagesAvailable => 'No hay paquetes disponibles';

  @override
  String get adminExperimentalIntegration => 'Integración experimental';

  @override
  String get adminExperimentalWarning =>
      'La integración de ajustes de plugins es aún experimental. Algunas páginas de ajustes pueden no mostrarse correctamente.';

  @override
  String get continueAction => 'Continuar';

  @override
  String adminPluginRemoveAfterRestart(String name) {
    return '“$name” se eliminará tras reiniciar el servidor';
  }

  @override
  String adminUninstallFailed(String error) {
    return 'Error al desinstalar: $error';
  }

  @override
  String adminPluginUpdating(String name, String version) {
    return 'Actualizando “$name” a v$version...';
  }

  @override
  String get adminMissingAuthToken =>
      'No se pueden abrir los ajustes: falta el token de autenticación.';

  @override
  String adminPluginLoadFailed(String error) {
    return 'Error al cargar el plugin: $error';
  }

  @override
  String get adminPluginNotFound => 'Plugin no encontrado';

  @override
  String adminPluginVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get adminEnablePlugin => 'Habilitar plugin';

  @override
  String get adminPluginSettingsPage => 'Página de ajustes del plugin';

  @override
  String get adminRevisionHistory => 'Historial de revisiones';

  @override
  String get adminNoChangelog => 'No hay registro de cambios disponible.';

  @override
  String get adminRemoveRepository => 'Eliminar repositorio';

  @override
  String adminRemoveRepositoryConfirm(String name) {
    return '¿Estás seguro de que quieres eliminar “$name”?';
  }

  @override
  String adminRepositoriesSaveFailed(String error) {
    return 'Error al guardar los repositorios: $error';
  }

  @override
  String adminRepositoriesLoadFailed(String error) {
    return 'Error al cargar los repositorios: $error';
  }

  @override
  String get adminRepositoryNameHint => 'p. ej. Jellyfin Stable';

  @override
  String get adminRepositoryUrl => 'URL del repositorio';

  @override
  String get adminAddEntry => 'Añadir entrada';

  @override
  String get adminInvalidUrl => 'URL no válida';

  @override
  String adminPluginSettingsLoadFailed(String error) {
    return 'No se pudieron cargar los ajustes del plugin: $error';
  }

  @override
  String adminCouldNotOpenUrl(String uri) {
    return 'No se pudo abrir $uri';
  }

  @override
  String get adminOpenInBrowser => 'Abrir en el navegador';

  @override
  String get adminOpenExternally => 'Abrir externamente';

  @override
  String get adminGeneralSettings => 'Ajustes generales';

  @override
  String get adminServerName => 'Nombre del servidor';

  @override
  String get adminPreferredMetadataCountry => 'País de metadatos preferido';

  @override
  String get adminCachePath => 'Ruta de caché';

  @override
  String get adminMetadataPath => 'Ruta de metadatos';

  @override
  String get adminLibraryScanConcurrency =>
      'Concurrencia de escaneo de bibliotecas';

  @override
  String get adminParallelImageEncodingLimit =>
      'Límite de codificación de imágenes en paralelo';

  @override
  String get adminSlowResponseThreshold => 'Umbral de respuesta lenta (ms)';

  @override
  String get adminBrandingSaved => 'Ajustes de marca guardados';

  @override
  String get adminBrandingLoadFailed => 'Error al cargar los ajustes de marca';

  @override
  String get adminLoginDisclaimer => 'Aviso legal de inicio de sesión';

  @override
  String get adminLoginDisclaimerHint =>
      'HTML que se muestra debajo del formulario de inicio de sesión';

  @override
  String get adminCustomCss => 'CSS personalizado';

  @override
  String get adminCustomCssHint =>
      'CSS personalizado aplicado a la interfaz web';

  @override
  String get adminEnableSplashScreen => 'Habilitar pantalla de bienvenida';

  @override
  String get adminStreamingSaved => 'Ajustes de streaming guardados';

  @override
  String get adminStreamingLoadFailed =>
      'Error al cargar los ajustes de streaming';

  @override
  String get adminStreamingDescription =>
      'Establece los límites globales de tasa de bits de streaming para conexiones remotas.';

  @override
  String get adminRemoteBitrateLimitMbps =>
      'Límite de tasa de bits del cliente remoto (Mbps)';

  @override
  String get adminLeaveEmptyForUnlimited => 'Dejar vacío o 0 para sin límite';

  @override
  String get adminPlaybackSaved => 'Ajustes de reproducción guardados';

  @override
  String get adminPlaybackLoadFailed =>
      'Error al cargar los ajustes de reproducción';

  @override
  String get adminPlaybackTranscoding => 'Reproducción / Transcodificación';

  @override
  String get adminHardwareAcceleration => 'Aceleración por hardware';

  @override
  String get adminVaapiDevice => 'Dispositivo VA-API';

  @override
  String get adminEnableHardwareEncoding =>
      'Habilitar codificación por hardware';

  @override
  String get adminEnableHardwareDecoding =>
      'Habilitar decodificación por hardware para:';

  @override
  String get adminEncodingThreads => 'Hilos de codificación';

  @override
  String get adminAutomatic => '0 = automático';

  @override
  String get adminTranscodingTempPath => 'Ruta temporal de transcodificación';

  @override
  String get adminEnableFallbackFont => 'Habilitar fuente alternativa';

  @override
  String get adminFallbackFontPath => 'Ruta de fuente alternativa';

  @override
  String get adminAllowSegmentDeletion => 'Permitir eliminación de segmentos';

  @override
  String get adminSegmentKeepSeconds => 'Conservar segmentos (segundos)';

  @override
  String get adminThrottleBuffering => 'Limitar el búfer';

  @override
  String get adminTrickplaySaved => 'Ajustes de Trickplay guardados';

  @override
  String get adminTrickplayLoadFailed =>
      'Error al cargar los ajustes de Trickplay';

  @override
  String get adminEnableHardwareAcceleration =>
      'Habilitar aceleración por hardware';

  @override
  String get adminEnableKeyFrameExtraction =>
      'Habilitar extracción solo de fotogramas clave';

  @override
  String get adminKeyFrameSubtitle => 'Más rápido pero menos preciso';

  @override
  String get adminScanBehavior => 'Comportamiento de escaneo';

  @override
  String get adminProcessPriority => 'Prioridad del proceso';

  @override
  String get adminImageSettings => 'Ajustes de imagen';

  @override
  String get adminIntervalMs => 'Intervalo (ms)';

  @override
  String get adminCaptureFrameSubtitle =>
      'Con qué frecuencia capturar fotogramas';

  @override
  String get adminWidthResolutions => 'Resoluciones de ancho';

  @override
  String get adminTileWidth => 'Ancho del mosaico';

  @override
  String get adminTileHeight => 'Alto del mosaico';

  @override
  String get adminQualitySubtitle =>
      'Valores más bajos = mejor calidad, archivos más grandes';

  @override
  String get adminProcessThreads => 'Hilos de proceso';

  @override
  String get adminResumeSaved => 'Ajustes de reanudación guardados';

  @override
  String get adminResumeLoadFailed =>
      'Error al cargar los ajustes de reanudación';

  @override
  String get adminResumeDescription =>
      'Configura cuándo el contenido se marca como parcialmente reproducido o completamente reproducido.';

  @override
  String get adminMinResumePercentage => 'Porcentaje mínimo de reanudación';

  @override
  String get adminMinResumeSubtitle =>
      'El contenido debe reproducirse más allá de este porcentaje para guardar el progreso';

  @override
  String get adminMaxResumePercentage => 'Porcentaje máximo de reanudación';

  @override
  String get adminMaxResumeSubtitle =>
      'El contenido se considera completamente reproducido después de este porcentaje';

  @override
  String get adminMinResumeDuration =>
      'Duración mínima de reanudación (segundos)';

  @override
  String get adminMinResumeDurationSubtitle =>
      'Los elementos más cortos que esto no son reanudables';

  @override
  String get adminMinAudiobookResume =>
      'Porcentaje mínimo de reanudación de audiolibros';

  @override
  String get adminMaxAudiobookResume =>
      'Porcentaje máximo de reanudación de audiolibros';

  @override
  String get adminNetworkingSaved =>
      'Ajustes de red guardados. Puede ser necesario reiniciar el servidor.';

  @override
  String get adminNetworkingLoadFailed => 'Error al cargar los ajustes de red';

  @override
  String get adminNetworkingWarning =>
      'Los cambios en los ajustes de red pueden requerir un reinicio del servidor.';

  @override
  String get adminEnableRemoteAccess => 'Habilitar acceso remoto';

  @override
  String get ports => 'Puertos';

  @override
  String get adminHttpPort => 'Puerto HTTP';

  @override
  String get adminHttpsPort => 'Puerto HTTPS';

  @override
  String get adminPublicHttpsPort => 'Puerto HTTPS público';

  @override
  String get adminBaseUrl => 'URL base';

  @override
  String get adminBaseUrlHint => 'p. ej. /jellyfin';

  @override
  String get https => 'HTTPS';

  @override
  String get adminEnableHttps => 'Habilitar HTTPS';

  @override
  String get adminLocalNetwork => 'Red local';

  @override
  String get adminLocalNetworkAddresses => 'Direcciones de red local';

  @override
  String get adminKnownProxies => 'Proxies conocidos';

  @override
  String get adminRemoteIpFilter => 'Filtro de IP remota';

  @override
  String get adminRemoteIpFilterEntries => 'Filtro de IP remota';

  @override
  String get adminCertificatePath => 'Ruta del certificado';

  @override
  String get whitelist => 'Lista blanca';

  @override
  String get blacklist => 'Lista negra';

  @override
  String get notSet => 'No establecido';

  @override
  String get adminMetadataSaved => 'Metadatos guardados';

  @override
  String adminMetadataLoadFailed(String error) {
    return 'Error al cargar los metadatos: $error';
  }

  @override
  String adminMetadataSaveFailed(String error) {
    return 'Error al guardar los metadatos: $error';
  }

  @override
  String get adminRefreshMetadata => 'Actualizar metadatos';

  @override
  String get recursive => 'Recursivo';

  @override
  String get adminReplaceAllMetadata => 'Reemplazar todos los metadatos';

  @override
  String get adminReplaceAllImages => 'Reemplazar todas las imágenes';

  @override
  String get adminMetadataRefreshRequested =>
      'Actualización de metadatos solicitada';

  @override
  String adminMetadataRefreshFailed(String error) {
    return 'Error al actualizar los metadatos: $error';
  }

  @override
  String get adminSearchRemotePerson => 'Buscar persona remota';

  @override
  String get adminNoRemoteMatches => 'No se encontraron coincidencias remotas';

  @override
  String get adminRemoteResults => 'Resultados remotos';

  @override
  String get adminRemoteMetadataApplied => 'Metadatos remotos aplicados';

  @override
  String adminRemoteSearchFailed(String error) {
    return 'Error en la búsqueda remota: $error';
  }

  @override
  String get adminUpdateContentType => 'Actualizar tipo de contenido';

  @override
  String get adminContentType => 'Tipo de contenido';

  @override
  String get adminContentTypeUpdated => 'Tipo de contenido actualizado';

  @override
  String adminContentTypeUpdateFailed(String error) {
    return 'Error al actualizar el tipo de contenido: $error';
  }

  @override
  String get adminMetadataEditorLoadFailed =>
      'Error al cargar el editor de metadatos';

  @override
  String get adminNoPeopleEntries => 'No hay entradas de personas';

  @override
  String get adminNoExternalIds => 'No hay IDs externos disponibles';

  @override
  String adminImageUpdated(String imageType) {
    return 'Imagen de $imageType actualizada';
  }

  @override
  String adminImageDownloadFailed(String error) {
    return 'Error al descargar la imagen: $error';
  }

  @override
  String get adminUnsupportedImageFormat => 'Formato de imagen no soportado';

  @override
  String get adminImageReadFailed => 'Error al leer la imagen seleccionada';

  @override
  String adminImageUploaded(String imageType) {
    return 'Imagen de $imageType subida';
  }

  @override
  String adminImageUploadFailed(String error) {
    return 'Error al subir la imagen: $error';
  }

  @override
  String adminDeleteImage(String imageType) {
    return 'Eliminar imagen de $imageType';
  }

  @override
  String adminImageDeleted(String imageType) {
    return 'Imagen de $imageType eliminada';
  }

  @override
  String adminImageDeleteFailed(String error) {
    return 'Error al eliminar la imagen: $error';
  }

  @override
  String get adminAllProviders => 'Todos los proveedores';

  @override
  String get adminNoRemoteImages => 'No se encontraron imágenes remotas';

  @override
  String adminTunerDiscoveryFailed(String error) {
    return 'Error en el descubrimiento de sintonizadores: $error';
  }

  @override
  String get adminAddTuner => 'Añadir sintonizador';

  @override
  String get adminTunerType => 'Tipo de sintonizador';

  @override
  String get adminTunerTypeHint => 'HDHomeRun, M3U, Otro';

  @override
  String get adminUrlPath => 'URL / Ruta';

  @override
  String get adminNameOptional => 'Nombre (opcional)';

  @override
  String get adminTunerAdded => 'Sintonizador añadido';

  @override
  String adminTunerAddFailed(String error) {
    return 'Error al añadir el sintonizador: $error';
  }

  @override
  String get adminAddGuideProvider => 'Añadir proveedor de guía';

  @override
  String get adminProviderType => 'Tipo de proveedor';

  @override
  String get adminProviderTypeHint => 'SchedulesDirect o XMLTV';

  @override
  String get adminUsernameOptional => 'Nombre de usuario (opcional)';

  @override
  String get adminRefreshInterval => 'Intervalo de actualización (horas)';

  @override
  String get adminProviderAdded => 'Proveedor añadido';

  @override
  String adminProviderAddFailed(String error) {
    return 'Error al añadir el proveedor: $error';
  }

  @override
  String adminTunerRemoveFailed(String error) {
    return 'Error al eliminar el sintonizador: $error';
  }

  @override
  String get adminTunerResetRequested => 'Reinicio del sintonizador solicitado';

  @override
  String adminTunerResetFailed(String error) {
    return 'Error al reiniciar el sintonizador: $error';
  }

  @override
  String adminProviderRemoveFailed(String error) {
    return 'Error al eliminar el proveedor: $error';
  }

  @override
  String get adminRecordingSettings => 'Ajustes de grabación';

  @override
  String get adminPrePadding => 'Relleno previo (minutos)';

  @override
  String get adminPostPadding => 'Relleno posterior (minutos)';

  @override
  String get adminRecordingPath => 'Ruta de grabación';

  @override
  String get adminSeriesRecordingPath => 'Ruta de grabación de series';

  @override
  String get adminRecordingSettingsSaved => 'Ajustes de grabación guardados';

  @override
  String adminSettingsSaveFailed(String error) {
    return 'Error al guardar los ajustes: $error';
  }

  @override
  String get adminSetChannelMappings => 'Establecer mapeo de canales';

  @override
  String get adminMappingJson => 'JSON de mapeo';

  @override
  String get adminChannelMappingsUpdated => 'Mapeo de canales actualizado';

  @override
  String adminMappingsUpdateFailed(String error) {
    return 'Error al actualizar el mapeo: $error';
  }

  @override
  String get adminLiveTvLoadFailed =>
      'Error al cargar la administración de TV en vivo';

  @override
  String get adminTunerDevices => 'Dispositivos sintonizadores';

  @override
  String get adminNoTunerHosts => 'No hay hosts de sintonizador configurados';

  @override
  String get adminGuideProviders => 'Proveedores de guía';

  @override
  String get adminAddProvider => 'Añadir proveedor';

  @override
  String get adminNoListingProviders =>
      'No hay proveedores de listados configurados';

  @override
  String adminRecordingPathDisplay(String path) {
    return 'Ruta de grabación: $path';
  }

  @override
  String adminSeriesPathDisplay(String path) {
    return 'Ruta de series: $path';
  }

  @override
  String adminPrePaddingDisplay(int minutes) {
    return 'Relleno previo: $minutes min';
  }

  @override
  String adminPostPaddingDisplay(int minutes) {
    return 'Relleno posterior: $minutes min';
  }

  @override
  String get adminTunerDiscovery => 'Descubrimiento de sintonizadores';

  @override
  String get adminChannelMappings => 'Mapeo de canales';

  @override
  String get adminNoDiscoveredTuners =>
      'Aún no se han descubierto sintonizadores';

  @override
  String get adminSettingsSaved => 'Ajustes guardados';

  @override
  String get adminBackupsNotAvailable =>
      'Las copias de seguridad no están disponibles en esta versión del servidor.';

  @override
  String get adminRestoreWarning1 =>
      'La restauración reemplazará TODOS los datos actuales del servidor con los datos de la copia de seguridad.';

  @override
  String get adminRestoreWarning2 =>
      'Los ajustes del servidor, usuarios y datos de bibliotecas actuales serán sobrescritos.';

  @override
  String get adminRestoreWarning3 =>
      'El servidor se reiniciará después de la restauración.';

  @override
  String adminRestoreConfirmMessage(String name) {
    return '¿Restaurar la copia de seguridad $name ahora?';
  }

  @override
  String get adminRestoreRequested =>
      'Restauración solicitada. El reinicio del servidor puede desconectar esta sesión.';

  @override
  String get adminBackupsTitle => 'Copias de seguridad';

  @override
  String get adminUnknownDate => 'Fecha desconocida';

  @override
  String get adminUnnamedBackup => 'Copia de seguridad sin nombre';

  @override
  String get adminLiveTvNotAvailable =>
      'La administración de TV en vivo no está disponible en esta versión del servidor.';

  @override
  String get adminLiveTvTitle => 'Administración de TV en vivo';

  @override
  String get adminApply => 'Aplicar';

  @override
  String get adminNotSet => 'No establecido';

  @override
  String get adminReset => 'Restablecer';

  @override
  String get adminLogsTitle => 'Registros del servidor';

  @override
  String get adminLogsNewestFirst => 'Más reciente primero';

  @override
  String get adminLogsOldestFirst => 'Más antiguo primero';

  @override
  String get adminLogsJustNow => 'Ahora mismo';

  @override
  String adminLogsMinutesAgo(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String adminLogsHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String adminLogsDaysAgo(int days) {
    return 'hace $days d';
  }

  @override
  String adminLogViewerLoadFailed(String fileName) {
    return 'Error al cargar $fileName';
  }

  @override
  String adminLogViewerMatches(int count) {
    return '$count coincidencias';
  }

  @override
  String get adminLogViewerNoMatches => 'No hay líneas coincidentes';

  @override
  String get adminMetadataEditorTitle => 'Editor de metadatos';

  @override
  String get adminMetadataRemote => 'Remoto';

  @override
  String get adminMetadataType => 'Tipo';

  @override
  String get adminMetadataDetails => 'Detalles';

  @override
  String get adminMetadataExternalIds => 'IDs externos';

  @override
  String get adminMetadataImages => 'Imágenes';

  @override
  String get adminMetadataFieldTitle => 'Título';

  @override
  String get adminMetadataFieldSortTitle => 'Título de ordenación';

  @override
  String get adminMetadataFieldOriginalTitle => 'Título original';

  @override
  String get adminMetadataFieldPremiereDate => 'Fecha de estreno (AAAA-MM-DD)';

  @override
  String get adminMetadataFieldEndDate => 'Fecha de finalización (AAAA-MM-DD)';

  @override
  String get adminMetadataFieldProductionYear => 'Año de producción';

  @override
  String get adminMetadataFieldOfficialRating => 'Clasificación oficial';

  @override
  String get adminMetadataFieldCommunityRating => 'Valoración de la comunidad';

  @override
  String get adminMetadataFieldCriticRating => 'Valoración de críticos';

  @override
  String get adminMetadataFieldTagline => 'Eslogan';

  @override
  String get adminMetadataFieldOverview => 'Sinopsis';

  @override
  String get adminMetadataGenres => 'Géneros';

  @override
  String get adminMetadataTags => 'Etiquetas';

  @override
  String get adminMetadataStudios => 'Estudios';

  @override
  String get adminMetadataPeople => 'Personas';

  @override
  String get adminMetadataAddGenre => 'Añadir género';

  @override
  String get adminMetadataAddTag => 'Añadir etiqueta';

  @override
  String get adminMetadataAddStudio => 'Añadir estudio';

  @override
  String get adminMetadataAddPerson => 'Añadir persona';

  @override
  String get adminMetadataEditPerson => 'Editar persona';

  @override
  String get adminMetadataRole => 'Rol';

  @override
  String get adminMetadataImagePrimary => 'Principal';

  @override
  String get adminMetadataImageBackdrop => 'Fondo';

  @override
  String get adminMetadataImageLogo => 'Logotipo';

  @override
  String get adminMetadataImageBanner => 'Pancarta';

  @override
  String get adminMetadataImageThumb => 'Miniatura';

  @override
  String get adminMetadataRecursive => 'Recursivo';

  @override
  String get adminMetadataProvider => 'Proveedor';

  @override
  String adminMetadataImageUpdated(String imageType) {
    return 'Imagen de $imageType actualizada';
  }

  @override
  String adminMetadataImageUploaded(String imageType) {
    return 'Imagen de $imageType subida';
  }

  @override
  String adminMetadataImageDeleted(String imageType) {
    return 'Imagen de $imageType eliminada';
  }

  @override
  String adminMetadataImageDownloadFailed(String error) {
    return 'Error al descargar la imagen: $error';
  }

  @override
  String get adminMetadataImageReadFailed =>
      'Error al leer la imagen seleccionada';

  @override
  String adminMetadataImageUploadFailed(String error) {
    return 'Error al subir la imagen: $error';
  }

  @override
  String adminMetadataDeleteImageTitle(String imageType) {
    return 'Eliminar imagen de $imageType';
  }

  @override
  String get adminMetadataDeleteImageContent =>
      'Esto elimina la imagen actual del elemento.';

  @override
  String adminMetadataImageDeleteFailed(String error) {
    return 'Error al eliminar la imagen: $error';
  }

  @override
  String adminMetadataChooseImage(String imageType) {
    return 'Elegir imagen de $imageType';
  }

  @override
  String get adminMetadataUpload => 'Subir';

  @override
  String get adminMetadataUpdate => 'Actualizar';

  @override
  String get adminMetadataRemoteImage => 'Imagen remota';

  @override
  String get adminPluginsInstalled => 'Instalados';

  @override
  String get adminPluginsCatalog => 'Catálogo';

  @override
  String get adminPluginsActive => 'Activos';

  @override
  String get adminPluginsRestart => 'Reiniciar';

  @override
  String get adminPluginsNoSearchResults =>
      'Ningún plugin coincide con tu búsqueda';

  @override
  String get adminPluginsNoneInstalled => 'No hay plugins instalados';

  @override
  String adminPluginsUpdateAvailable(String version) {
    return 'Actualización disponible: v$version';
  }

  @override
  String get adminPluginsUpdateAvailableGeneric => 'Actualización disponible';

  @override
  String get adminPluginsPendingRemoval =>
      'Eliminación pendiente tras reinicio';

  @override
  String get adminPluginsChangesPending => 'Cambios pendientes de reinicio';

  @override
  String get adminPluginsEnable => 'Habilitar';

  @override
  String get adminPluginsDisable => 'Deshabilitar';

  @override
  String get adminPluginsInstallUpdate => 'Instalar actualización';

  @override
  String adminPluginsInstallUpdateVersioned(String version) {
    return 'Instalar actualización (v$version)';
  }

  @override
  String get adminPluginsCatalogNoSearchResults =>
      'Ningún paquete coincide con tu búsqueda';

  @override
  String get adminPluginsCatalogEmpty => 'No hay paquetes disponibles';

  @override
  String adminPluginsInstalling(String name) {
    return 'Instalando “$name”...';
  }

  @override
  String get adminPluginDetailExperimental => 'Integración experimental';

  @override
  String get adminPluginDetailExperimentalContent =>
      'La integración de ajustes de plugins es aún experimental. Algunos campos o diseños pueden no mostrarse correctamente.';

  @override
  String get adminPluginDetailToggle404 =>
      'Error al alternar el plugin. El servidor no encontró esta versión del plugin. Intenta actualizar los plugins y vuelve a intentarlo.';

  @override
  String get adminPluginDetailToggleDioError =>
      'Error al alternar el plugin. Consulta los registros del servidor para más detalles.';

  @override
  String adminPluginDetailSettingsTitle(String name) {
    return 'Ajustes de $name';
  }

  @override
  String get adminPluginDetailDetails => 'Detalles';

  @override
  String get adminPluginDetailDeveloper => 'Desarrollador';

  @override
  String get adminPluginDetailRepository => 'Repositorio';

  @override
  String get adminPluginDetailBundled => 'Incluido';

  @override
  String get adminPluginDetailEnablePlugin => 'Habilitar plugin';

  @override
  String get adminPluginDetailRestartRequired =>
      'Se requiere un reinicio del servidor para que los cambios surtan efecto.';

  @override
  String get adminPluginDetailRemovalPending =>
      'Este plugin se eliminará tras reiniciar el servidor.';

  @override
  String get adminPluginDetailMalfunctioned =>
      'Este plugin ha funcionado incorrectamente y puede no funcionar bien.';

  @override
  String get adminPluginDetailNotSupported =>
      'Este plugin no es compatible con la versión actual del servidor.';

  @override
  String get adminPluginDetailSuperseded =>
      'Este plugin ha sido reemplazado por una versión más nueva.';

  @override
  String adminReposLoadFailed(String error) {
    return 'Error al cargar los repositorios: $error';
  }

  @override
  String get adminReposRemoveTitle => 'Eliminar repositorio';

  @override
  String adminReposRemoveConfirm(String name) {
    return '¿Estás seguro de que quieres eliminar “$name”?';
  }

  @override
  String get adminReposRemove => 'Eliminar';

  @override
  String adminReposSaveFailed(String error) {
    return 'Error al guardar los repositorios: $error';
  }

  @override
  String get adminReposEmpty => 'No hay repositorios configurados';

  @override
  String get adminReposEmptySubtitle =>
      'Añade un repositorio para explorar los plugins disponibles';

  @override
  String get adminReposUnnamed => '(sin nombre)';

  @override
  String get adminReposEditTitle => 'Editar repositorio';

  @override
  String get adminReposAddTitle => 'Añadir repositorio';

  @override
  String get adminReposUrl => 'URL del repositorio';

  @override
  String get adminReposNameHint => 'p. ej. Jellyfin Stable';

  @override
  String get adminPluginSettingsInvalidUrl => 'URL no válida';

  @override
  String get adminGeneralSettingsTitle => 'Ajustes generales';

  @override
  String get adminGeneralMetadataLanguage => 'Idioma de metadatos preferido';

  @override
  String get adminGeneralMetadataLanguageHint => 'p. ej. en, de, fr';

  @override
  String get adminGeneralMetadataCountry => 'País de metadatos preferido';

  @override
  String get adminGeneralMetadataCountryHint => 'p. ej. US, DE, FR';

  @override
  String get adminGeneralLibraryScanConcurrency =>
      'Concurrencia de escaneo de bibliotecas';

  @override
  String get adminGeneralImageEncodingLimit =>
      'Límite de codificación de imágenes en paralelo';

  @override
  String get adminUnknownError => 'Error desconocido';

  @override
  String get adminBrowse => 'Explorar';

  @override
  String get adminCloseBrowser => 'Cerrar explorador';

  @override
  String get adminNetworkingTitle => 'Redes';

  @override
  String get adminNetworkingRestartWarning =>
      'Los cambios en los ajustes de red pueden requerir un reinicio del servidor.';

  @override
  String get adminNetworkingRemoteAccess => 'Habilitar acceso remoto';

  @override
  String get adminNetworkingPorts => 'Puertos';

  @override
  String get adminNetworkingHttpPort => 'Puerto HTTP';

  @override
  String get adminNetworkingHttpsPort => 'Puerto HTTPS';

  @override
  String get adminNetworkingEnableHttps => 'Habilitar HTTPS';

  @override
  String get adminNetworkingLocalNetwork => 'Red local';

  @override
  String get adminNetworkingLocalAddresses => 'Direcciones de red local';

  @override
  String get adminNetworkingAddressHint => 'p. ej. 192.168.1.0/24';

  @override
  String get adminNetworkingKnownProxies => 'Proxies conocidos';

  @override
  String get adminNetworkingProxyHint => 'p. ej. 10.0.0.1';

  @override
  String get adminNetworkingWhitelist => 'Lista blanca';

  @override
  String get adminNetworkingBlacklist => 'Lista negra';

  @override
  String get adminNetworkingAddEntry => 'Añadir entrada';

  @override
  String get adminBrandingTitle => 'Marca';

  @override
  String get adminBrandingLoginDisclaimer => 'Aviso legal de inicio de sesión';

  @override
  String get adminBrandingLoginDisclaimerHint =>
      'HTML que se muestra debajo del formulario de inicio de sesión';

  @override
  String get adminBrandingCustomCss => 'CSS personalizado';

  @override
  String get adminBrandingCustomCssHint =>
      'CSS personalizado aplicado a la interfaz web';

  @override
  String get adminBrandingEnableSplash => 'Habilitar pantalla de bienvenida';

  @override
  String get adminPlaybackHwAccel => 'Aceleración por hardware';

  @override
  String get adminPlaybackHwAccelLabel => 'Aceleración por hardware';

  @override
  String get adminPlaybackEnableHwEncoding =>
      'Habilitar codificación por hardware';

  @override
  String get adminPlaybackEnableHwDecoding =>
      'Habilitar decodificación por hardware para:';

  @override
  String get adminPlaybackEncoding => 'Codificación';

  @override
  String get adminPlaybackEncodingThreads => 'Hilos de codificación';

  @override
  String get adminPlaybackFallbackFont => 'Habilitar fuente alternativa';

  @override
  String get adminPlaybackFallbackFontPath => 'Ruta de fuente alternativa';

  @override
  String get adminPlaybackStreaming => 'Streaming';

  @override
  String get adminResumeVideo => 'Vídeo';

  @override
  String get adminResumeAudiobooks => 'Audiolibros';

  @override
  String get adminResumeMinAudiobookPct =>
      'Porcentaje mínimo de reanudación de audiolibros';

  @override
  String get adminResumeMaxAudiobookPct =>
      'Porcentaje máximo de reanudación de audiolibros';

  @override
  String get adminStreamingBitrateLimit =>
      'Límite de tasa de bits del cliente remoto (Mbps)';

  @override
  String get adminStreamingBitrateLimitHint =>
      'Dejar vacío o 0 para sin límite';

  @override
  String get adminTrickplayHwAccel => 'Habilitar aceleración por hardware';

  @override
  String get adminTrickplayHwEncoding => 'Habilitar codificación por hardware';

  @override
  String get adminTrickplayKeyFrameOnly =>
      'Habilitar extracción solo de fotogramas clave';

  @override
  String get adminTrickplayKeyFrameOnlySubtitle =>
      'Más rápido pero menos preciso';

  @override
  String get adminTrickplayNonBlocking => 'No bloqueante';

  @override
  String get adminTrickplayBlocking => 'Bloqueante';

  @override
  String get adminTrickplayPriorityHigh => 'Alta';

  @override
  String get adminTrickplayPriorityAboveNormal => 'Superior a Normal';

  @override
  String get adminTrickplayPriorityNormal => 'Normal';

  @override
  String get adminTrickplayPriorityBelowNormal => 'Inferior a Normal';

  @override
  String get adminTrickplayPriorityIdle => 'Inactivo';

  @override
  String get adminTrickplayImageSettings => 'Ajustes de imagen';

  @override
  String get adminTrickplayInterval => 'Intervalo (ms)';

  @override
  String get adminTrickplayIntervalSubtitle =>
      'Con qué frecuencia capturar fotogramas';

  @override
  String get adminTrickplayWidthResolutionsHint =>
      'Anchos de píxeles separados por comas (p. ej. 320)';

  @override
  String get adminTrickplayQuality => 'Calidad';

  @override
  String get adminTrickplayQScale => 'Escala de calidad';

  @override
  String get adminTrickplayQScaleSubtitle =>
      'Valores más bajos = mejor calidad, archivos más grandes';

  @override
  String get adminTrickplayJpegQuality => 'Calidad JPEG';

  @override
  String get adminTrickplayProcessing => 'Procesamiento';

  @override
  String get adminTasksEmpty => 'No se encontraron tareas programadas';

  @override
  String get adminTasksNoFilterMatch =>
      'Ninguna tarea coincide con el filtro actual';

  @override
  String get adminTaskCancelling => 'Cancelando...';

  @override
  String get adminTaskRunning => 'Ejecutando...';

  @override
  String get adminTaskNeverRun => 'Nunca ejecutada';

  @override
  String get adminTaskStop => 'Detener';

  @override
  String get adminTaskRun => 'Ejecutar';

  @override
  String get adminTaskDetailLastExecution => 'Última ejecución';

  @override
  String get adminTaskDetailStarted => 'Iniciada';

  @override
  String get adminTaskDetailEnded => 'Finalizada';

  @override
  String get adminTaskDetailDuration => 'Duración';

  @override
  String get adminTaskDetailErrorLabel => 'Error:';

  @override
  String adminTaskTriggerDaily(String time) {
    return 'Diario a las $time';
  }

  @override
  String adminTaskTriggerWeekly(String day, String time) {
    return 'Cada $day a las $time';
  }

  @override
  String adminTaskTriggerInterval(String duration) {
    return 'Cada $duration';
  }

  @override
  String get adminTaskTriggerStartup => 'Al iniciar la aplicación';

  @override
  String get adminTaskTriggerTypeDaily => 'Diario';

  @override
  String get adminTaskTriggerTypeWeekly => 'Semanal';

  @override
  String get adminTaskTriggerTypeInterval => 'Por intervalo';

  @override
  String get adminTaskTriggerIntervalLabel => 'Intervalo';

  @override
  String get adminTaskTriggerEveryHour => 'Cada hora';

  @override
  String get adminTaskTriggerEvery6Hours => 'Cada 6 horas';

  @override
  String get adminTaskTriggerEvery12Hours => 'Cada 12 horas';

  @override
  String get adminTaskTriggerEvery24Hours => 'Cada 24 horas';

  @override
  String get adminTaskTriggerEvery2Days => 'Cada 2 días';

  @override
  String adminTaskTriggerHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String get adminTaskTriggerTime => 'Hora';

  @override
  String get adminTaskTriggerNoLimit => 'Sin límite';

  @override
  String get adminActivityJustNow => 'Ahora mismo';

  @override
  String get adminActivityLastHour => 'Última hora';

  @override
  String get adminActivityToday => 'Hoy';

  @override
  String get adminActivityYesterday => 'Ayer';

  @override
  String get adminActivityOlder => 'Más antiguo';

  @override
  String adminActivityDaysAgo(int days) {
    return 'hace $days d';
  }

  @override
  String adminActivityHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String adminActivityMinutesAgo(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String get adminActivityNow => 'ahora';

  @override
  String adminActivityMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String adminActivityHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String adminActivityDaysShort(int days) {
    return '$days d';
  }

  @override
  String adminActivityDateShort(int month, int day) {
    return '$month/$day';
  }

  @override
  String get adminTrickplayDescription =>
      'Configura la generación de imágenes de trickplay para las miniaturas de vista previa al buscar.';

  @override
  String get adminNetworkingPublicHttpsPort => 'Puerto HTTPS público';

  @override
  String get adminNetworkingBaseUrl => 'URL base';

  @override
  String get adminNetworkingBaseUrlHint => 'p. ej. /jellyfin';

  @override
  String get adminNetworkingHttps => 'HTTPS';

  @override
  String get adminNetworkingCertPath => 'Ruta del certificado';

  @override
  String get adminNetworkingRemoteIpFilter => 'Filtro de IP remota';

  @override
  String get adminNetworkingRemoteIpFilterLabel => 'Filtro de IP remota';

  @override
  String get adminPlaybackVaapiDevice => 'Dispositivo VA-API';

  @override
  String get adminPlaybackAutomatic => '0 = automático';

  @override
  String get adminPlaybackTranscodeTempPath =>
      'Ruta temporal de transcodificación';

  @override
  String get adminPlaybackSegmentDeletion =>
      'Permitir eliminación de segmentos';

  @override
  String get adminPlaybackSegmentKeep => 'Conservar segmentos (segundos)';

  @override
  String get adminPlaybackThrottleBuffering => 'Limitar el búfer';

  @override
  String get adminResumeMinPct => 'Porcentaje mínimo de reanudación';

  @override
  String get adminResumeMinPctSubtitle =>
      'El contenido debe reproducirse más allá de este porcentaje para guardar el progreso';

  @override
  String get adminResumeMaxPct => 'Porcentaje máximo de reanudación';

  @override
  String get adminResumeMaxPctSubtitle =>
      'El contenido se considera completamente reproducido después de este porcentaje';

  @override
  String get adminResumeMinDuration =>
      'Duración mínima de reanudación (segundos)';

  @override
  String get adminResumeMinDurationSubtitle =>
      'Los elementos más cortos que esto no son reanudables';

  @override
  String get adminTrickplayScanBehavior => 'Comportamiento de escaneo';

  @override
  String get adminTrickplayProcessPriority => 'Prioridad del proceso';

  @override
  String get adminTrickplayTileWidth => 'Ancho del mosaico';

  @override
  String get adminTrickplayTileHeight => 'Alto del mosaico';

  @override
  String get adminTrickplayProcessThreads => 'Hilos de proceso';

  @override
  String get adminTrickplayWidthResolutions => 'Resoluciones de ancho';

  @override
  String get adminMetadataDefault => 'Predeterminado';

  @override
  String get adminMetadataContentTypeUpdated => 'Tipo de contenido actualizado';

  @override
  String adminMetadataContentTypeFailed(String error) {
    return 'Error al actualizar el tipo de contenido: $error';
  }

  @override
  String get adminGeneralSlowResponseThreshold =>
      'Umbral de respuesta lenta (ms)';

  @override
  String get adminGeneralCachePath => 'Ruta de caché';

  @override
  String get adminGeneralMetadataPath => 'Ruta de metadatos';

  @override
  String get adminGeneralServerName => 'Nombre del servidor';

  @override
  String get adminSettingsLoadFailed => 'Error al cargar los ajustes';

  @override
  String get adminDiscover => 'Descubrir';

  @override
  String adminChannelMappingsUpdateFailed(String error) {
    return 'Error al actualizar el mapeo: $error';
  }

  @override
  String adminTimeLimitDuration(String duration) {
    return 'Límite de tiempo: $duration';
  }

  @override
  String get folders => 'Carpetas';

  @override
  String get libraries => 'Bibliotecas';

  @override
  String get syncPlay => 'SyncPlay';

  @override
  String get jellyseerr => 'Jellyseerr';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get noItems => 'No hay elementos';

  @override
  String get switchUser => 'Cambiar de usuario';

  @override
  String get remoteControl => 'Control remoto';

  @override
  String get mediaBarLoading => 'Cargando barra de medios...';

  @override
  String get mediaBarError => 'Error al cargar la barra de medios';

  @override
  String get offlineServerUnavailable =>
      'Conectado a internet, pero el servidor actual no está disponible.';

  @override
  String get offlineNoInternet =>
      'Estás sin conexión. Solo el contenido descargado está disponible.';

  @override
  String get offlineSwitchServer => 'Cambiar de servidor';

  @override
  String get offlineSavedMedia => 'Contenido guardado';

  @override
  String get castGoogleCast => 'Google Cast';

  @override
  String get castAirPlay => 'AirPlay';

  @override
  String get castDlna => 'DLNA';

  @override
  String get castRemotePlayback => 'Reproducción remota';

  @override
  String castControlFailed(String error) {
    return 'Error en el control de transmisión: $error';
  }

  @override
  String castKindControls(String kind) {
    return 'Controles de $kind';
  }

  @override
  String get castDeviceVolume => 'Volumen del dispositivo';

  @override
  String get castVolumeUnavailable => 'No disponible';

  @override
  String castStopKind(String kind) {
    return 'Detener $kind';
  }

  @override
  String get audioLabel => 'Audio';

  @override
  String get subtitlesLabel => 'Subtítulos';

  @override
  String get pinConfirmTitle => 'Confirmar PIN';

  @override
  String get pinSetTitle => 'Establecer PIN';

  @override
  String get pinEnterTitle => 'Introducir PIN';

  @override
  String get pinReenterToConfirm => 'Vuelve a introducir tu PIN para confirmar';

  @override
  String pinEnterNDigit(int length) {
    return 'Introduce un PIN de $length dígitos';
  }

  @override
  String pinEnterYourNDigit(int length) {
    return 'Introduce tu PIN de $length dígitos';
  }

  @override
  String get pinIncorrect => 'PIN incorrecto';

  @override
  String get pinMismatch => 'Los PINs no coinciden';

  @override
  String get pinForgot => '¿Olvidaste el PIN?';

  @override
  String get pinClear => 'Borrar';

  @override
  String get pinBackspace => 'Retroceso';

  @override
  String get quickConnectAuthorized =>
      'Solicitud de conexión rápida autorizada.';

  @override
  String get quickConnectInvalidOrExpired =>
      'El código de conexión rápida no es válido o ha expirado.';

  @override
  String get quickConnectNotSupported =>
      'La conexión rápida no es compatible con este servidor.';

  @override
  String get quickConnectAuthorizeFailed =>
      'Error al autorizar el código de conexión rápida.';

  @override
  String get quickConnectDisabled =>
      'La conexión rápida está deshabilitada en este servidor.';

  @override
  String get quickConnectForbidden =>
      'Tu cuenta no puede autorizar esta solicitud de conexión rápida.';

  @override
  String get quickConnectNotFound =>
      'No se encontró el código de conexión rápida. Prueba con un nuevo código.';

  @override
  String quickConnectFailedWithMessage(String message) {
    return 'Error de conexión rápida: $message';
  }

  @override
  String get quickConnectEnterCode => 'Introducir código';

  @override
  String get quickConnectAuthorize => 'Autorizar';

  @override
  String remoteCommandFailed(String error) {
    return 'Comando fallido: $error';
  }

  @override
  String get remoteControlTitle => 'Control remoto';

  @override
  String get remoteFailedToLoadSessions => 'Error al cargar las sesiones';

  @override
  String get remoteNoSessions => 'No hay sesiones controlables';

  @override
  String get remoteStartPlayback => 'Iniciar reproducción en otro dispositivo';

  @override
  String get unknownUser => 'Desconocido';

  @override
  String get unknownItem => 'Desconocido';

  @override
  String get remoteNothingPlaying =>
      'No se está reproduciendo nada en esta sesión';

  @override
  String get castingStarted =>
      'Transmisión iniciada en el dispositivo seleccionado';

  @override
  String castingFailed(String error) {
    return 'Error al iniciar la transmisión: $error';
  }

  @override
  String get noRemoteDevices =>
      'No hay dispositivos de reproducción remota disponibles.';

  @override
  String get noRemoteDevicesIos =>
      'No hay dispositivos de reproducción remota disponibles.';

  @override
  String get trackActionPlayNext => 'Reproducir a continuación';

  @override
  String get trackActionAddToQueue => 'Añadir a la cola';

  @override
  String get trackActionAddToPlaylist => 'Añadir a lista de reproducción';

  @override
  String get trackActionCancelDownload => 'Cancelar descarga';

  @override
  String get trackActionDeleteFromPlaylist =>
      'Eliminar de la lista de reproducción';

  @override
  String get trackActionMoveUp => 'Mover arriba';

  @override
  String get trackActionMoveDown => 'Mover abajo';

  @override
  String get trackActionRemoveFromFavorites => 'Quitar de favoritos';

  @override
  String get trackActionAddToFavorites => 'Añadir a favoritos';

  @override
  String get trackActionGoToAlbum => 'Ir al álbum';

  @override
  String get trackActionGoToArtist => 'Ir al artista';

  @override
  String trackActionDownloading(String name) {
    return 'Descargando $name...';
  }

  @override
  String get trackActionDeletedFile => 'Archivo descargado eliminado';

  @override
  String get trackActionDeleteFileFailed =>
      'No se pudo eliminar el archivo descargado';

  @override
  String get shuffleBy => 'Aleatorio por';

  @override
  String get shuffleSelectLibrary => 'Seleccionar biblioteca';

  @override
  String get shuffleSelectGenre => 'Seleccionar género';

  @override
  String get shuffleLibrary => 'Biblioteca';

  @override
  String get shuffleGenre => 'Género';

  @override
  String get shuffleNoLibraries =>
      'No hay bibliotecas compatibles disponibles.';

  @override
  String get shuffleNoGenres =>
      'No se encontraron géneros para este modo aleatorio.';

  @override
  String get posterDisplayTitle => 'Visualización';

  @override
  String get posterImageType => 'Tipo de imagen';

  @override
  String get imageTypePoster => 'Póster';

  @override
  String get imageTypeThumbnail => 'Miniatura';

  @override
  String get imageTypeBanner => 'Pancarta';

  @override
  String get playlistAddFailed => 'Error al añadir a la lista de reproducción';

  @override
  String get playlistCreateFailed => 'Error al crear la lista de reproducción';

  @override
  String get playlistNew => 'Nueva lista de reproducción';

  @override
  String get playlistCreate => 'Crear';

  @override
  String get playlistCreateNew => 'Crear nueva lista de reproducción';

  @override
  String get playlistNoneFound => 'No se encontraron listas de reproducción';

  @override
  String get addToPlaylist => 'Añadir a lista de reproducción';

  @override
  String get lyricsNotAvailable => 'No hay letras disponibles';

  @override
  String get upNext => 'A continuación';

  @override
  String get playNext => 'Reproducir a continuación';

  @override
  String get stillWatchingContent =>
      'La reproducción se ha pausado. ¿Sigues viendo?';

  @override
  String get stillWatchingStop => 'Detener';

  @override
  String get stillWatchingContinue => 'Continuar';

  @override
  String skipSegment(String segment) {
    return 'Saltar $segment';
  }

  @override
  String get liveTv => 'TV en vivo';

  @override
  String get continueWatchingAndNextUp => 'Continuar viendo y A continuación';

  @override
  String downloadingBatchProgress(int current, int total, String fileName) {
    return 'Descargando $current/$total — $fileName';
  }

  @override
  String downloadingFile(String fileName) {
    return 'Descargando $fileName';
  }

  @override
  String get nextEpisode => 'Siguiente episodio';

  @override
  String get moreFromThisSeason => 'Más de esta temporada';
}
