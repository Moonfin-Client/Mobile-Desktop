// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Moonfin';

  @override
  String get signIn => 'Se connecter';

  @override
  String connectingToServer(String serverName) {
    return 'Connexion à $serverName';
  }

  @override
  String get quickConnect => 'Connexion rapide';

  @override
  String get password => 'Mot de passe';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get quickConnectInstruction =>
      'Saisissez ce code dans le tableau de bord web de votre serveur :';

  @override
  String get waitingForAuthorization => 'En attente d\'autorisation...';

  @override
  String get back => 'Retour';

  @override
  String get serverUnavailable => 'Serveur indisponible';

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String quickConnectUnavailable(String detail) {
    return 'Connexion rapide indisponible : $detail';
  }

  @override
  String quickConnectUnavailableWithStatus(String status, String detail) {
    return 'Connexion rapide indisponible ($status) : $detail';
  }

  @override
  String get whosWatching => 'Qui regarde ?';

  @override
  String get addUser => 'Ajouter un utilisateur';

  @override
  String get selectServer => 'Sélectionner un serveur';

  @override
  String appVersionFooter(String version) {
    return 'Version Moonfin $version';
  }

  @override
  String get savedServers => 'Serveurs enregistrés';

  @override
  String get discoveredServers => 'Serveurs détectés';

  @override
  String get noneFound => 'Aucun serveur trouvé';

  @override
  String get unableToConnectToServer => 'Impossible de se connecter au serveur';

  @override
  String get addServer => 'Ajouter un serveur';

  @override
  String get embyConnect => 'Emby Connect';

  @override
  String get removeServer => 'Supprimer le serveur';

  @override
  String removeServerConfirmation(String serverName) {
    return 'Supprimer \"$serverName\" de vos serveurs ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get remove => 'Supprimer';

  @override
  String get connectToServer => 'Se connecter au serveur';

  @override
  String get serverAddress => 'Adresse du serveur';

  @override
  String get serverAddressHint => 'https://votre-serveur.exemple.com';

  @override
  String get connect => 'Se connecter';

  @override
  String get secureStorageUnavailable => 'Stockage sécurisé indisponible';

  @override
  String get secureStorageUnavailableMessage =>
      'Moonfin n\'a pas pu accéder au trousseau de votre système. La connexion peut continuer, mais le stockage sécurisé des jetons peut rester indisponible tant que le trousseau n\'est pas déverrouillé.';

  @override
  String get ok => 'OK';

  @override
  String get embyConnectSignInSubtitle =>
      'Connectez-vous avec votre compte Emby Connect';

  @override
  String get emailOrUsername => 'E-mail ou nom d\'utilisateur';

  @override
  String get selectAServer => 'Sélectionner un serveur';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get noLinkedServers => 'Aucun serveur lié à ce compte Emby Connect';

  @override
  String get invalidEmbyConnectCredentials =>
      'Identifiants Emby Connect invalides';

  @override
  String get invalidEmbyConnectLogin =>
      'Nom d\'utilisateur ou mot de passe Emby Connect invalide';

  @override
  String get embyConnectExchangeNotSupported =>
      'Le serveur ne prend pas en charge l\'échange Emby Connect';

  @override
  String get embyConnectNetworkError =>
      'Erreur réseau lors du contact avec Emby Connect ou le serveur sélectionné';

  @override
  String get loadingLinkedServers => 'Chargement des serveurs liés...';

  @override
  String get connectingToServerEllipsis => 'Connexion au serveur...';

  @override
  String get noReachableAddress => 'Aucune adresse accessible fournie';

  @override
  String get invalidServerExchangeResponse =>
      'Réponse invalide du point de terminaison d\'échange du serveur';

  @override
  String unableToConnectTo(String target) {
    return 'Impossible de se connecter à $target';
  }

  @override
  String get exitApp => 'Quitter Moonfin ?';

  @override
  String get exitAppConfirmation => 'Voulez-vous vraiment quitter ?';

  @override
  String get exit => 'Quitter';

  @override
  String get noHomeRowsLoaded =>
      'Impossible de charger les sections d\'accueil';

  @override
  String get noHomeRowsHint =>
      'Essayez d\'actualiser ou de réduire les sections d\'accueil actives.';

  @override
  String get retryHomeRows => 'Réessayer les sections d\'accueil';

  @override
  String get guide => 'Guide';

  @override
  String get recordings => 'Enregistrements';

  @override
  String get schedule => 'Programmation';

  @override
  String get series => 'Séries';

  @override
  String get noItemsFound => 'Aucun élément trouvé';

  @override
  String get home => 'Accueil';

  @override
  String get browseAll => 'Tout parcourir';

  @override
  String get genres => 'Genres';

  @override
  String get collectionPlaceholder =>
      'Les éléments de la collection apparaîtront ici';

  @override
  String get browseByLetter => 'Parcourir par lettre';

  @override
  String get alphabeticalBrowsePlaceholder =>
      'La navigation alphabétique apparaîtra ici';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get suggestionsPlaceholder => 'Les éléments suggérés apparaîtront ici';

  @override
  String get failedToLoadLibraries => 'Impossible de charger les bibliothèques';

  @override
  String get noLibrariesFound => 'Aucune bibliothèque trouvée';

  @override
  String get library => 'Bibliothèque';

  @override
  String get displaySettings => 'Paramètres d\'affichage';

  @override
  String get allGenres => 'Tous les genres';

  @override
  String get noGenresFound => 'Aucun genre trouvé';

  @override
  String failedToLoadFolderError(String error) {
    return 'Impossible de charger le dossier : $error';
  }

  @override
  String get thisFolderIsEmpty => 'Ce dossier est vide';

  @override
  String itemCountLabel(int count) {
    return '$count éléments';
  }

  @override
  String get failedToLoadFavorites => 'Impossible de charger les favoris';

  @override
  String get retry => 'Réessayer';

  @override
  String get noFavoritesYet => 'Aucun favori pour le moment';

  @override
  String get favorites => 'Favoris';

  @override
  String totalCountItems(int count) {
    return '$count éléments';
  }

  @override
  String get continuing => 'En cours';

  @override
  String get ended => 'Terminée';

  @override
  String get sortAndFilter => 'Trier et filtrer';

  @override
  String get type => 'Type';

  @override
  String get sortBy => 'Trier par';

  @override
  String get display => 'Affichage';

  @override
  String get imageType => 'Type d\'image';

  @override
  String get posterSize => 'Taille du poster';

  @override
  String get small => 'Petit';

  @override
  String get medium => 'Moyen';

  @override
  String get large => 'Grand';

  @override
  String get extraLarge => 'Très grand';

  @override
  String libraryGenresTitle(String name) {
    return '$name — Genres';
  }

  @override
  String get views => 'Vues';

  @override
  String get albums => 'Albums';

  @override
  String get albumArtists => 'Artistes d\'album';

  @override
  String get artists => 'Artistes';

  @override
  String get bookmarks => 'Marque-pages';

  @override
  String get noSavedBookmarks =>
      'Aucun marque-page enregistré pour ce titre pour le moment.';

  @override
  String get openBook => 'Ouvrir le livre';

  @override
  String get chapter => 'Chapitre';

  @override
  String get page => 'Page';

  @override
  String get bookmark => 'Marque-page';

  @override
  String get justNow => 'À l\'instant';

  @override
  String minutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String daysAgo(int count) {
    return 'il y a $count j';
  }

  @override
  String get discoverySubjects => 'Sujets de découverte';

  @override
  String get pickDiscoverySubjects =>
      'Choisissez quels flux de sujets afficher dans Découvrir.';

  @override
  String get apply => 'Appliquer';

  @override
  String get audiobookGenres => 'Genres d\'audiolivres';

  @override
  String get pickAudiobookGenres =>
      'Choisissez quels genres afficher dans Découvrir les audiolivres.';

  @override
  String get discoverAudiobooks => 'Découvrir des audiolivres';

  @override
  String get librivoxDescription =>
      'Titres populaires du domaine public de LibriVox.';

  @override
  String titlesCount(int count) {
    return '$count titres';
  }

  @override
  String get scrollLeft => 'Faire défiler vers la gauche';

  @override
  String get scrollRight => 'Faire défiler vers la droite';

  @override
  String get couldNotLoadGenre =>
      'Impossible de charger ce genre pour le moment.';

  @override
  String get continueReading => 'Continuer la lecture';

  @override
  String get savedHighlights => 'Surlignages enregistrés';

  @override
  String get continueListening => 'Continuer l\'écoute';

  @override
  String get listen => 'Écouter';

  @override
  String get resume => 'Reprendre';

  @override
  String get failedToLoadLibrary => 'Impossible de charger la bibliothèque';

  @override
  String get popularNow => 'Populaire en ce moment';

  @override
  String get savedForLater => 'Enregistré pour plus tard';

  @override
  String get topListens => 'Les plus écoutés';

  @override
  String get unreadDiscoveries => 'Découvertes non lues';

  @override
  String get pickUpAgain => 'Reprendre';

  @override
  String get bookHighlightsDescription =>
      'Vos livres avec des surlignages, des favoris ou une progression de lecture.';

  @override
  String get handPickedFromLibrary => 'Sélectionnés dans votre bibliothèque.';

  @override
  String get handPickedFromListeningQueue =>
      'Sélectionnés dans votre file d\'écoute.';

  @override
  String get booksWithHighlights =>
      'Livres avec des surlignages, des favoris ou une progression de lecture.';

  @override
  String get jumpBackNarration =>
      'Reprenez l\'écoute sans chercher où vous en étiez.';

  @override
  String get unreadBooksReady =>
      'Des livres non lus pour votre prochaine heure de calme.';

  @override
  String get quickAccessFavorites =>
      'Accès rapide aux livres auxquels vous revenez souvent.';

  @override
  String get searchAudiobooks => 'Rechercher des audiolivres';

  @override
  String get searchYourLibrary => 'Rechercher dans votre bibliothèque';

  @override
  String get pickUpStory => 'Reprenez l\'histoire là où vous l\'avez laissée';

  @override
  String get savedPlacesChapters =>
      'Vos emplacements enregistrés et chapitres inachevés';

  @override
  String authorsCount(int count) {
    return '$count auteurs';
  }

  @override
  String genresCount(int count) {
    return '$count genres';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% terminé';
  }

  @override
  String get readyWhenYouAre => 'Prêt quand vous l’êtes';

  @override
  String get details => 'Détails';

  @override
  String get listeningRoom => 'Salle d\'écoute';

  @override
  String get bookmarksAndProgress => 'Marque-pages et progression';

  @override
  String titlesArrangedForBrowsing(int count) {
    return '$count titres classés pour une navigation axée sur la lecture.';
  }

  @override
  String get titles => 'Titres';

  @override
  String get allTitles => 'Tous les titres';

  @override
  String get authors => 'Auteurs';

  @override
  String get browseByAuthor => 'Parcourir par auteur';

  @override
  String get browseByGenre => 'Parcourir par genre';

  @override
  String get discover => 'Découvrir';

  @override
  String get trendingTitlesOpenLibrary =>
      'Titres tendance par sujet depuis Open Library.';

  @override
  String get noBookmarkedItems =>
      'Aucun élément dans les marque-pages pour le moment';

  @override
  String get nothingMatchesSection =>
      'Rien ne correspond encore à cette section. Essayez un autre onglet ou revenez une fois la synchronisation de la bibliothèque terminée.';

  @override
  String get audiobooks => 'Audiolivres';

  @override
  String noLabelFound(String label) {
    return 'Aucun $label trouvé';
  }

  @override
  String get folder => 'Dossier';

  @override
  String get filters => 'Filtres';

  @override
  String get readingStatus => 'Statut de lecture';

  @override
  String get playedStatus => 'Statut de visionnage';

  @override
  String get readStatus => 'Lu';

  @override
  String get watched => 'Vu';

  @override
  String get unread => 'Non lu';

  @override
  String get unwatched => 'Non vu';

  @override
  String get seriesStatus => 'Statut de la série';

  @override
  String get allLibraries => 'Toutes les bibliothèques';

  @override
  String get books => 'Livres';

  @override
  String get author => 'Auteur';

  @override
  String get unknownAuthor => 'Auteur inconnu';

  @override
  String get uncategorized => 'Non classé';

  @override
  String get overview => 'Aperçu';

  @override
  String get noLibrivoxDescription =>
      'Aucune description fournie par LibriVox pour ce titre pour le moment.';

  @override
  String get readers => 'Lecteurs';

  @override
  String get openLinks => 'Ouvrir les liens';

  @override
  String get librivoxPage => 'Page LibriVox';

  @override
  String get internetArchive => 'Internet Archive';

  @override
  String get rssFeed => 'Flux RSS';

  @override
  String get downloadZip => 'Télécharger le ZIP';

  @override
  String sectionCountLabel(int count) {
    return '$count sections';
  }

  @override
  String firstPublished(int year) {
    return 'Première publication en $year';
  }

  @override
  String get noOpenLibraryOverview =>
      'Aucun aperçu disponible depuis Open Library pour ce titre pour le moment.';

  @override
  String get subjects => 'Sujets';

  @override
  String get all => 'Tout';

  @override
  String booksCount(int count) {
    return '$count livres';
  }

  @override
  String get couldNotLoadSubject =>
      'Impossible de charger ce sujet pour le moment.';

  @override
  String get audiobookDetails => 'Détails du livre audio';

  @override
  String authorsCountTitle(int count) {
    return '$count auteurs';
  }

  @override
  String audiobookCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livres audio',
      one: '1 livre audio',
      zero: '0 livres audio',
    );
    return '$_temp0';
  }

  @override
  String get trackList => 'Liste des pistes';

  @override
  String get itemListPlaceholder => 'La liste des éléments apparaîtra ici';

  @override
  String get favoriteTracksPlaceholder =>
      'Les pistes favorites apparaîtront ici';

  @override
  String get failedToLoad => 'Impossible de charger';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get moreLikeThis => 'Plus comme ça';

  @override
  String get castAndCrew => 'Casting et équipe';

  @override
  String get collection => 'Collection';

  @override
  String get episodes => 'Épisodes';

  @override
  String get nextUp => 'À suivre';

  @override
  String get seasons => 'Saisons';

  @override
  String get chapters => 'Chapitres';

  @override
  String get features => 'Bonus';

  @override
  String get movies => 'Films';

  @override
  String get other => 'Autres';

  @override
  String get discography => 'Discographie';

  @override
  String get similarArtists => 'Artistes similaires';

  @override
  String get tableOfContents => 'Table des matières';

  @override
  String get tracklist => 'Liste des pistes';

  @override
  String get biography => 'Biographie';

  @override
  String get authorDetails => 'Détails de l\'auteur';

  @override
  String get noOverviewAvailable =>
      'Aucun résumé disponible pour ce titre pour le moment.';

  @override
  String get noBiographyAvailable =>
      'Aucune biographie disponible pour cet auteur.';

  @override
  String get noBooksFound => 'Aucun livre trouvé pour cet auteur.';

  @override
  String get unableToLoadAuthorDetails =>
      'Impossible de charger les détails de l\'auteur pour le moment.';

  @override
  String published(int year) {
    return 'Publié en $year';
  }

  @override
  String get publicationDateUnknown => 'Date de publication inconnue';

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saisons',
      one: '1 saison',
      zero: '0 saisons',
    );
    return '$_temp0';
  }

  @override
  String endsAt(String time) {
    return 'Se termine à $time';
  }

  @override
  String get view => 'Voir';

  @override
  String get resumeReading => 'Reprendre la lecture';

  @override
  String get read => 'Lire';

  @override
  String resumeFrom(String position) {
    return 'Reprendre à $position';
  }

  @override
  String get play => 'Lire';

  @override
  String get startOver => 'Recommencer';

  @override
  String get restart => 'Redémarrer';

  @override
  String get readOffline => 'Lire hors ligne';

  @override
  String get playOffline => 'Lire hors ligne';

  @override
  String get audio => 'Audio';

  @override
  String get subtitles => 'Sous-titres';

  @override
  String get version => 'Version';

  @override
  String get cast => 'Diffuser';

  @override
  String get trailer => 'Bande-annonce';

  @override
  String get finished => 'Terminé';

  @override
  String get favorited => 'En favori';

  @override
  String get favorite => 'Favori';

  @override
  String get playlist => 'Liste de lecture';

  @override
  String get downloaded => 'Téléchargé';

  @override
  String get downloadAll => 'Tout télécharger';

  @override
  String get download => 'Télécharger';

  @override
  String get deleteDownloaded => 'Supprimer les téléchargements';

  @override
  String get goToSeries => 'Aller à la série';

  @override
  String get editMetadata => 'Modifier les métadonnées';

  @override
  String get less => 'Moins';

  @override
  String get more => 'Plus';

  @override
  String get deleteItem => 'Supprimer l\'élément';

  @override
  String get deletePlaylist => 'Supprimer la liste de lecture';

  @override
  String get deletePlaylistMessage =>
      'Supprimer cette liste de lecture du serveur ?';

  @override
  String get deleteItemMessage => 'Supprimer cet élément du serveur ?';

  @override
  String get failedToDeletePlaylist =>
      'Échec de la suppression de la liste de lecture';

  @override
  String get failedToDeleteItem => 'Échec de la suppression de l\'élément';

  @override
  String get renamePlaylist => 'Renommer la liste de lecture';

  @override
  String get playlistName => 'Nom de la liste de lecture';

  @override
  String get deleteDownloadedAlbum => 'Supprimer l\'album téléchargé';

  @override
  String deleteDownloadedTracksMessage(String title) {
    return 'Supprimer les pistes téléchargées pour \"$title\" ?';
  }

  @override
  String get downloadedTracksDeleted => 'Pistes téléchargées supprimées';

  @override
  String get downloadedTracksDeleteFailed =>
      'Certaines pistes téléchargées n\'ont pas pu être supprimées';

  @override
  String get noTracksLoaded => 'Aucune piste chargée';

  @override
  String noItemsLoaded(String itemLabel) {
    return 'Aucun $itemLabel chargé';
  }

  @override
  String downloadingTitle(String title, int count) {
    return 'Téléchargement de $title ($count éléments)...';
  }

  @override
  String deleteConfirmMessage(String name) {
    return 'Voulez-vous vraiment supprimer \"$name\" du serveur ? Cette action est irréversible.';
  }

  @override
  String get itemDeleted => 'Élément supprimé';

  @override
  String get noPlayableTrailerFound => 'Aucune bande-annonce lisible trouvée.';

  @override
  String unsupportedBookFormat(String extension) {
    return 'Format de livre non pris en charge : .$extension';
  }

  @override
  String get audioTrack => 'Piste audio';

  @override
  String get subtitleTrack => 'Piste de sous-titres';

  @override
  String get none => 'Aucun';

  @override
  String get downloadSubtitlesLabel => 'Télécharger des sous-titres...';

  @override
  String get searchOpenSubtitlesPlugin =>
      'Rechercher avec le plugin OpenSubtitles';

  @override
  String get downloadSubtitles => 'Télécharger des sous-titres';

  @override
  String get selectedSubtitleInvalid =>
      'Le sous-titre sélectionné n\'est pas valide.';

  @override
  String subtitleDownloadedSelected(String name) {
    return 'Sous-titre téléchargé et sélectionné : $name';
  }

  @override
  String get subtitleDownloadedPending =>
      'Sous-titre téléchargé. Il peut mettre un moment à apparaître pendant que Jellyfin actualise l\'élément.';

  @override
  String noRemoteSubtitlesFound(String language) {
    return 'Aucun sous-titre distant trouvé pour $language.';
  }

  @override
  String get selectVersion => 'Choisir une version';

  @override
  String versionNumber(int number) {
    return 'Version $number';
  }

  @override
  String get downloadAllQuality => 'Tout télécharger — Qualité';

  @override
  String get downloadQuality => 'Qualité du téléchargement';

  @override
  String get originalFileNoReencoding => 'Fichier original, sans réencodage';

  @override
  String get originalFilesNoReencoding => 'Fichiers originaux, sans réencodage';

  @override
  String get noEpisodesLoaded => 'Aucun épisode chargé';

  @override
  String downloadingItem(String name, String quality) {
    return 'Téléchargement de $name ($quality)...';
  }

  @override
  String get deleteDownloadedFiles => 'Supprimer les fichiers téléchargés';

  @override
  String deleteLocalFilesMessage(String typeLabel) {
    return 'Supprimer les fichiers locaux pour $typeLabel ?\n\nCela libérera de l\'espace de stockage. Vous pourrez les retélécharger plus tard.';
  }

  @override
  String get downloadedFilesDeleted => 'Fichiers téléchargés supprimés';

  @override
  String get failedToDeleteFiles => 'Échec de la suppression des fichiers';

  @override
  String get deleteFiles => 'Supprimer les fichiers';

  @override
  String get director => 'RÉALISATEUR';

  @override
  String get writers => 'SCÉNARISTES';

  @override
  String get studio => 'STUDIO';

  @override
  String studioMoreCount(int count) {
    return '+$count de plus';
  }

  @override
  String totalEpisodes(int count) {
    return '$count épisodes';
  }

  @override
  String episodeProgress(int watched, int total) {
    return '$watched / $total';
  }

  @override
  String episodeLabel(int number) {
    return 'Épisode $number';
  }

  @override
  String chapterNumber(int number) {
    return 'Chapitre $number';
  }

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistes',
      one: '1 piste',
      zero: '0 pistes',
    );
    return '$_temp0';
  }

  @override
  String chapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapitres',
      one: '1 chapitre',
      zero: '0 chapitres',
    );
    return '$_temp0';
  }

  @override
  String born(String date) {
    return 'Né le $date';
  }

  @override
  String died(String date) {
    return 'Décédé le $date';
  }

  @override
  String age(int age) {
    return 'Âge $age';
  }

  @override
  String get showLess => 'Voir moins';

  @override
  String get readMore => 'Lire plus';

  @override
  String get shuffle => 'Aléatoire';

  @override
  String downloadsCount(int count) {
    return '$count téléchargements';
  }

  @override
  String get perfectMatch => 'Correspondance parfaite';

  @override
  String channelsCount(int count) {
    return '$count can.';
  }

  @override
  String get mono => 'Mono';

  @override
  String get stereo => 'Stéréo';

  @override
  String remoteSubtitlePermissionError(String action) {
    return 'L\'action de sous-titres distants $action nécessite l\'autorisation Jellyfin de gestion des sous-titres pour cet utilisateur.';
  }

  @override
  String remoteSubtitleNotFoundError(String action) {
    return 'Cet élément est introuvable sur le serveur pour l\'action de sous-titres distants $action.';
  }

  @override
  String remoteSubtitleDetailError(String action, String detail) {
    return 'L\'action de sous-titres distants $action a échoué : $detail';
  }

  @override
  String remoteSubtitleHttpError(String action, int status) {
    return 'L\'action de sous-titres distants $action a échoué (HTTP $status).';
  }

  @override
  String remoteSubtitleGenericError(String action) {
    return 'Impossible de $action les sous-titres distants.';
  }

  @override
  String deleteSeriesFiles(String name) {
    return 'tous les épisodes téléchargés de \"$name\"';
  }

  @override
  String get deleteSeasonFiles =>
      'tous les épisodes téléchargés de cette saison';

  @override
  String get stillWatching => 'Vous regardez encore ?';

  @override
  String get unableToLoadTrailerStream =>
      'Impossible de charger le flux de la bande-annonce.';

  @override
  String get trailerTimedOut =>
      'Délai d\'attente dépassé lors du chargement de la bande-annonce.';

  @override
  String get playbackFailedForTrailer =>
      'La lecture de cette bande-annonce a échoué.';

  @override
  String photoCountOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get castingUnavailableOffline =>
      'La diffusion n\'est pas disponible pendant la lecture hors ligne.';

  @override
  String castActionFailed(String label, String error) {
    return 'Échec de l\'action sur $label : $error';
  }

  @override
  String failedToSetCastVolume(String error) {
    return 'Impossible de régler le volume de l\'appareil de diffusion : $error';
  }

  @override
  String castControlsTitle(String label) {
    return 'Commandes $label';
  }

  @override
  String get deviceVolume => 'Volume de l\'appareil';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get pause => 'Pause';

  @override
  String get syncPosition => 'Synchroniser la position';

  @override
  String stopCast(String label) {
    return 'Arrêter $label';
  }

  @override
  String get queueIsEmpty => 'La file d\'attente est vide';

  @override
  String trackNumber(int number) {
    return 'Piste $number';
  }

  @override
  String get remotePlayback => 'Lecture à distance';

  @override
  String get castingToGoogleCast => 'Diffusion vers Google Cast';

  @override
  String get castingViaAirPlay => 'Diffusion via AirPlay';

  @override
  String get castingViaDlna => 'Diffusion via DLNA';

  @override
  String secondsCount(int seconds) {
    return '$seconds secondes';
  }

  @override
  String get longPressToUnlock => 'Appui long pour déverrouiller';

  @override
  String get off => 'Désactivé';

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
  String get audioDelay => 'Décalage audio';

  @override
  String get subtitleDelay => 'Décalage des sous-titres';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get unknown => 'Inconnu';

  @override
  String get playbackInformation => 'Informations de lecture';

  @override
  String get playback => 'Lecture';

  @override
  String get playMethod => 'Méthode de lecture';

  @override
  String get directPlay => 'Lecture directe';

  @override
  String get directStream => 'Flux direct';

  @override
  String get transcoding => 'Transcodage';

  @override
  String get transcodeReasons => 'Raisons du transcodage';

  @override
  String get player => 'Lecteur';

  @override
  String get container => 'Conteneur';

  @override
  String get bitrate => 'Débit';

  @override
  String get video => 'Vidéo';

  @override
  String get resolution => 'Résolution';

  @override
  String get hdr => 'HDR';

  @override
  String get codec => 'Codec';

  @override
  String get videoBitrate => 'Débit vidéo';

  @override
  String get track => 'Piste';

  @override
  String get channels => 'Canaux';

  @override
  String get audioBitrate => 'Débit audio';

  @override
  String get sampleRate => 'Fréquence d\'échantillonnage';

  @override
  String get format => 'Format';

  @override
  String get external => 'Externe';

  @override
  String get embedded => 'Intégré';

  @override
  String castSessionError(String protocol) {
    return 'Erreur de session $protocol';
  }

  @override
  String failedToLoadBookDetails(String error) {
    return 'Échec du chargement des détails du livre : $error';
  }

  @override
  String get epubUnavailableOnPlatform =>
      'Le rendu EPUB intégré n\'est pas encore disponible sur cette plateforme.';

  @override
  String formatCannotRenderInApp(String extension) {
    return 'Ce format (.$extension) ne peut pas encore être affiché dans l\'application.';
  }

  @override
  String get embeddedRenderingUnavailable =>
      'Le rendu intégré des documents n\'est pas disponible sur cette plateforme.';

  @override
  String get couldNotOpenExternalViewer =>
      'Impossible d\'ouvrir la visionneuse externe.';

  @override
  String failedToOpenInAppReader(String error) {
    return 'Échec de l\'ouverture du lecteur intégré : $error';
  }

  @override
  String bookmarkAlreadySaved(String label) {
    return 'Signet déjà enregistré à $label.';
  }

  @override
  String bookmarkAdded(String label) {
    return 'Signet ajouté : $label';
  }

  @override
  String get noBookmarksYet =>
      'Aucun signet pour le moment.\nTouchez l\'icône de signet pendant la lecture pour enregistrer votre position.';

  @override
  String get noTableOfContentsAvailable =>
      'Aucune table des matières disponible';

  @override
  String pageLabel(int number) {
    return 'Page $number';
  }

  @override
  String get position => 'Position';

  @override
  String get bookReader => 'Lecteur de livres';

  @override
  String formatExtension(String extension) {
    return 'Format : .$extension';
  }

  @override
  String percentRead(String percent) {
    return '$percent% lu';
  }

  @override
  String get updating => 'Mise à jour...';

  @override
  String get markUnread => 'Marquer comme non lu';

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String get reloadReader => 'Recharger le lecteur';

  @override
  String get noPagesFound => 'Aucune page trouvée.';

  @override
  String get failedToDecodePageImage =>
      'Impossible de décoder l\'image de la page.';

  @override
  String resetZoom(String zoom) {
    return 'Réinitialiser le zoom (${zoom}x)';
  }

  @override
  String get singlePage => 'Page simple';

  @override
  String get twoPageSpread => 'Double page';

  @override
  String get addBookmark => 'Ajouter un signet';

  @override
  String get bookmarksEllipsis => 'Signets...';

  @override
  String get markedAsRead => 'Marqué comme lu';

  @override
  String get markedAsUnread => 'Marqué comme non lu';

  @override
  String failedToUpdateReadState(String error) {
    return 'Échec de la mise à jour de l\'état de lecture : $error';
  }

  @override
  String get themeSystem => 'Thème : Système';

  @override
  String get themeLight => 'Thème : Clair';

  @override
  String get themeDark => 'Thème : Sombre';

  @override
  String get themeSepia => 'Thème : Sépia';

  @override
  String get invertColorsFixedLayout =>
      'Inverser les couleurs (mise en page fixe)';

  @override
  String get invertColorsPdf => 'Inverser les couleurs (PDF)';

  @override
  String get preparingInAppReader => 'Préparation du lecteur intégré...';

  @override
  String get pdfDataNotAvailable => 'Données PDF indisponibles.';

  @override
  String get readerFallbackModeActive => 'Mode de secours du lecteur activé';

  @override
  String platformCannotHostDocumentEngine(String extension) {
    return 'Cette plateforme ne peut pas héberger le moteur de documents intégré pour les fichiers $extension.';
  }

  @override
  String get reloadReaderPlatformHint =>
      'Utilisez « Recharger le lecteur » après être passé à une plateforme prise en charge (Android, iOS, macOS).';

  @override
  String get openExternally => 'Ouvrir à l’extérieur';

  @override
  String get noEpubChaptersFound => 'Aucun chapitre EPUB trouvé.';

  @override
  String get readerNotReady => 'Lecteur non prêt.';

  @override
  String get seriesRecordings => 'Enregistrements de séries';

  @override
  String get now => 'Maintenant';

  @override
  String get sports => 'Sports';

  @override
  String get news => 'Actualités';

  @override
  String get kids => 'Enfants';

  @override
  String get premiere => 'Première';

  @override
  String get guideTimeline => 'Frise du guide';

  @override
  String failedToLoadGuide(String error) {
    return 'Échec du chargement du guide : $error';
  }

  @override
  String get noChannelsFound => 'Aucune chaîne trouvée';

  @override
  String get liveBadge => 'EN DIRECT';

  @override
  String get movie => 'Film';

  @override
  String get removedFromFavoriteChannels => 'Retiré des chaînes favorites';

  @override
  String get addedToFavoriteChannels => 'Ajouté aux chaînes favorites';

  @override
  String get failedToUpdateFavoriteChannel =>
      'Échec de la mise à jour de la chaîne favorite';

  @override
  String get unfavoriteChannel => 'Retirer des favoris';

  @override
  String get favoriteChannel => 'Ajouter aux favoris';

  @override
  String get watch => 'Regarder';

  @override
  String get close => 'Fermer';

  @override
  String failedToPlayChannel(String name) {
    return 'Impossible de lire $name';
  }

  @override
  String get failedToLoadRecordings =>
      'Échec du chargement des enregistrements';

  @override
  String get scheduledInNext24Hours => 'Prévu dans les 24 prochaines heures';

  @override
  String get recentRecordings => 'Enregistrements récents';

  @override
  String get tvSeries => 'Séries TV';

  @override
  String get failedToLoadSchedule => 'Échec du chargement de la programmation';

  @override
  String get noScheduledRecordings => 'Aucun enregistrement programmé';

  @override
  String get cancelRecording => 'Annuler l’enregistrement ?';

  @override
  String cancelScheduledRecordingOf(String name) {
    return 'Annuler l’enregistrement programmé de « $name » ?';
  }

  @override
  String get no => 'Non';

  @override
  String get yesCancel => 'Oui, annuler';

  @override
  String get failedToCancelRecording =>
      'Échec de l’annulation de l’enregistrement';

  @override
  String get failedToLoadSeriesRecordings =>
      'Échec du chargement des enregistrements de séries';

  @override
  String get noSeriesRecordings => 'Aucun enregistrement de série';

  @override
  String get cancelSeriesRecording => 'Annuler l’enregistrement de la série';

  @override
  String get cancelSeriesRecordingQuestion =>
      'Annuler l’enregistrement de la série ?';

  @override
  String stopRecordingName(String name) {
    return 'Arrêter l’enregistrement de « $name » ?';
  }

  @override
  String get failedToCancelSeriesRecording =>
      'Échec de l’annulation de l’enregistrement de la série';

  @override
  String get searchThisLibrary => 'Rechercher dans cette bibliothèque...';

  @override
  String get searchEllipsis => 'Rechercher...';

  @override
  String noResultsForQuery(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String searchFailedError(String error) {
    return 'Échec de la recherche : $error';
  }

  @override
  String get seerr => 'Seerr';

  @override
  String get savedMedia => 'Médias enregistrés';

  @override
  String get tvShows => 'Séries TV';

  @override
  String get music => 'Musique';

  @override
  String get musicAlbums => 'Albums musicaux';

  @override
  String get noMediaInFilter => 'Aucun média dans ce filtre';

  @override
  String get noDownloadedMediaYet => 'Aucun média téléchargé pour le moment';

  @override
  String get browseLibrary => 'Parcourir la bibliothèque';

  @override
  String get deleteDownload => 'Supprimer le téléchargement';

  @override
  String removeItemAndFiles(String name) {
    return 'Supprimer « $name » et ses fichiers ?';
  }

  @override
  String tracksCount(int count) {
    return '$count pistes';
  }

  @override
  String get album => 'Album';

  @override
  String get playAlbum => 'Lire l’album';

  @override
  String failedToLoadAlbum(String error) {
    return 'Échec du chargement de l’album : $error';
  }

  @override
  String noDownloadedTracksForAlbum(String name) {
    return 'Aucune piste téléchargée trouvée pour $name.';
  }

  @override
  String get season => 'Saison';

  @override
  String get errorLoadingEpisodes => 'Erreur lors du chargement des épisodes';

  @override
  String get noDownloadedEpisodes => 'Aucun épisode téléchargé';

  @override
  String get deleteEpisode => 'Supprimer l’épisode';

  @override
  String removeName(String name) {
    return 'Supprimer « $name » ?';
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
    return 'Épisode $number';
  }

  @override
  String get seriesNotFound => 'Série introuvable';

  @override
  String get errorLoadingSeries => 'Erreur lors du chargement de la série';

  @override
  String get downloadedEpisodes => 'Épisodes téléchargés';

  @override
  String seasonNumber(int number) {
    return 'Saison $number';
  }

  @override
  String get specials => 'Spéciaux';

  @override
  String get deleteSeason => 'Supprimer la saison';

  @override
  String deleteAllEpisodesInSeason(String season) {
    return 'Supprimer tous les épisodes téléchargés de $season ?';
  }

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes',
      one: '1 épisode',
      zero: '0 épisodes',
    );
    return '$_temp0';
  }

  @override
  String get storageManagement => 'Gestion du stockage';

  @override
  String get storageBreakdown => 'Répartition du stockage';

  @override
  String get downloadedItems => 'Éléments téléchargés';

  @override
  String get storageLimit => 'Limite de stockage';

  @override
  String get noLimit => 'Aucune limite';

  @override
  String get deleteAllDownloads => 'Supprimer tous les téléchargements';

  @override
  String get deleteAllDownloadsWarning =>
      'Cela supprimera tous les fichiers média téléchargés et ne pourra pas être annulé.';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get deleteSelected => 'Supprimer la sélection';

  @override
  String deleteSelectedCount(int count) {
    return 'Supprimer $count éléments téléchargés ?';
  }

  @override
  String get musicAndAudiobooks => 'Musique et livres audio';

  @override
  String get images => 'Images';

  @override
  String get database => 'Base de données';

  @override
  String ofStorageLimit(String limit) {
    return 'sur une limite de $limit';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get authentication => 'Authentification';

  @override
  String get autoLoginServerManagement =>
      'Connexion auto, gestion des serveurs';

  @override
  String get pinCode => 'Code PIN';

  @override
  String get setUpPinCodeProtection => 'Configurer la protection par code PIN';

  @override
  String get parentalControls => 'Contrôle parental';

  @override
  String get contentRatingRestrictions => 'Restrictions de classification';

  @override
  String get bitRateResolutionBehavior => 'Débit, résolution, comportement';

  @override
  String get languageSizeAppearance => 'Langue, taille, apparence';

  @override
  String get qualityStorage => 'Qualité, stockage';

  @override
  String get serverSyncAndPluginStatus =>
      'Synchro du serveur et statut du plugin';

  @override
  String get mediaRequestIntegration => 'Intégration des demandes de médias';

  @override
  String get switchServer => 'Changer de serveur';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get versionLicenses => 'Version, licences';

  @override
  String get account => 'Compte';

  @override
  String get signInAndSecurity => 'Connexion et sécurité';

  @override
  String get administration => 'Administration';

  @override
  String get serverSettingsUsersLibraries =>
      'Paramètres serveur, utilisateurs, bibliothèques';

  @override
  String get customization => 'Personnalisation';

  @override
  String get themeAndLayout => 'Thème et mise en page';

  @override
  String get videoAndSubtitles => 'Vidéo et sous-titres';

  @override
  String get integrations => 'Intégrations';

  @override
  String get pluginAndRequests => 'Plugin et demandes';

  @override
  String get customizeAccountPlaybackInterface =>
      'Personnaliser le compte, la lecture et le comportement de l’interface';

  @override
  String optionsCount(int count) {
    return '$count options';
  }

  @override
  String get themeAndAppearance => 'Thème et apparence';

  @override
  String get focusBorderColor => 'Couleur de bordure du focus';

  @override
  String get watchedIndicators => 'Indicateurs de visionnage';

  @override
  String get always => 'Toujours';

  @override
  String get hideUnwatched => 'Masquer les non vus';

  @override
  String get episodesOnly => 'Épisodes uniquement';

  @override
  String get never => 'Jamais';

  @override
  String get focusExpansionAnimation => 'Animation d’agrandissement du focus';

  @override
  String get scaleFocusedCards =>
      'Agrandir les cartes et vignettes focalisées ou survolées';

  @override
  String get backgroundBackdrops => 'Arrière-plans illustrés';

  @override
  String get showBackdropImages =>
      'Afficher des images d’arrière-plan derrière le contenu';

  @override
  String get seriesThumbnails => 'Vignettes de séries';

  @override
  String get seriesThumbnailsDescription =>
      'Épisodes uniquement : utiliser l’illustration de la série correspondant au type d’image de chaque rangée';

  @override
  String get homeRowInfoOverlay =>
      'Superposition d’infos des rangées d’accueil';

  @override
  String get showTitleMetadataOnHomeRows =>
      'Afficher le titre et les métadonnées lors de la navigation sur l’accueil';

  @override
  String get clockDisplay => 'Affichage de l’horloge';

  @override
  String get inMenus => 'Dans les menus';

  @override
  String get inVideo => 'Dans la vidéo';

  @override
  String get seasonalEffects => 'Effets saisonniers';

  @override
  String get snow => 'Neige';

  @override
  String get fireworks => 'Feux d’artifice';

  @override
  String get confetti => 'Confettis';

  @override
  String get fallingLeaves => 'Feuilles tombantes';

  @override
  String get themeMusic => 'Musique du thème';

  @override
  String get playThemeMusicOnDetailPages =>
      'Lire la musique du thème sur les pages de détails';

  @override
  String get themeMusicVolume => 'Volume de la musique du thème';

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String get themeMusicOnHomeRows => 'Musique du thème sur l’accueil';

  @override
  String get playWhenBrowsingHomeScreen =>
      'Lire lors de la navigation sur l’écran d’accueil';

  @override
  String get detailsBackgroundBlur => 'Flou d’arrière-plan des détails';

  @override
  String pixelValue(int value) {
    return '${value}px';
  }

  @override
  String get browsingBackgroundBlur => 'Flou d’arrière-plan de navigation';

  @override
  String get maxStreamingBitrate => 'Débit maximal en streaming';

  @override
  String get maxResolution => 'Résolution maximale';

  @override
  String get playerZoomMode => 'Mode de zoom du lecteur';

  @override
  String get fit => 'Ajuster';

  @override
  String get autoCrop => 'Recadrage auto';

  @override
  String get stretch => 'Étirer';

  @override
  String get refreshRateSwitching =>
      'Changement de fréquence de rafraîchissement';

  @override
  String get disabled => 'Désactivé';

  @override
  String get scaleOnTv => 'Mise à l’échelle sur TV';

  @override
  String get scaleOnDevice => 'Mise à l’échelle sur l’appareil';

  @override
  String get trickPlay => 'Aperçu de lecture';

  @override
  String get showPreviewThumbnailsWhenSeeking =>
      'Afficher les vignettes d’aperçu pendant la recherche';

  @override
  String get showDescriptionOnPause => 'Afficher la description en pause';

  @override
  String get dimVideoShowOverview =>
      'Assombrir la vidéo et afficher le résumé en pause';

  @override
  String get osdLockButton => 'Bouton de verrouillage OSD';

  @override
  String get osdLockButtonDescription =>
      'Afficher un bouton de verrouillage qui bloque les touches tactiles jusqu’à un appui long';

  @override
  String get audioBehavior => 'Comportement audio';

  @override
  String get downmixToStereo => 'Mixer en stéréo';

  @override
  String get defaultAudioLanguage => 'Langue audio par défaut';

  @override
  String get autoServerDefault => 'Auto (par défaut du serveur)';

  @override
  String get english => 'Anglais';

  @override
  String get spanish => 'Espagnol';

  @override
  String get french => 'Français';

  @override
  String get german => 'Allemand';

  @override
  String get italian => 'Italien';

  @override
  String get portuguese => 'Portugais';

  @override
  String get japanese => 'Japonais';

  @override
  String get korean => 'Coréen';

  @override
  String get chinese => 'Chinois';

  @override
  String get russian => 'Russe';

  @override
  String get arabic => 'Arabe';

  @override
  String get hindi => 'Hindi';

  @override
  String get dutch => 'Néerlandais';

  @override
  String get swedish => 'Suédois';

  @override
  String get norwegian => 'Norvégien';

  @override
  String get danish => 'Danois';

  @override
  String get finnish => 'Finnois';

  @override
  String get polish => 'Polonais';

  @override
  String get ac3Passthrough => 'Pass-through AC3';

  @override
  String get trueHdSupport => 'Prise en charge de TrueHD';

  @override
  String get enableTrueHdAudio =>
      'Activer l’audio TrueHD (peut ne pas fonctionner sur toutes les plateformes)';

  @override
  String get nightMode => 'Mode nuit';

  @override
  String get compressDynamicRange => 'Compresser la plage dynamique';

  @override
  String get advancedMpv => 'mpv avancé';

  @override
  String get enableCustomMpvConf => 'Activer le mpv.conf personnalisé';

  @override
  String get applyMpvConfBeforePlayback =>
      'Appliquer un mpv.conf défini par l’utilisateur avant le début de la lecture';

  @override
  String get unsafeAdvancedMpvOptions => 'Options mpv avancées non sécurisées';

  @override
  String get unsafeMpvOptionsDescription =>
      'Autoriser un ensemble plus large d’options mpv. Peut perturber la lecture.';

  @override
  String get nextUpAndQueuing => 'À suivre et file d’attente';

  @override
  String get nextUpBehavior => 'Comportement d’À suivre';

  @override
  String get extended => 'Étendu';

  @override
  String get minimal => 'Minimal';

  @override
  String get nextUpTimeout => 'Délai d’À suivre';

  @override
  String secondsValue(int value) {
    return '${value}s';
  }

  @override
  String get mediaQueuing => 'Mise en file des médias';

  @override
  String get autoQueueNextEpisodes =>
      'Mettre automatiquement les épisodes suivants en file d’attente';

  @override
  String get stillWatchingPrompt => 'Invite « Vous regardez toujours ? »';

  @override
  String afterEpisodesAndHours(int episodes, double hours) {
    return 'Après $episodes épisodes / $hours h';
  }

  @override
  String get resumeAndSkip => 'Reprendre et sauter';

  @override
  String get resumeRewind => 'Retour arrière à la reprise';

  @override
  String get fiveSeconds => '5 secondes';

  @override
  String get tenSeconds => '10 secondes';

  @override
  String get fifteenSeconds => '15 secondes';

  @override
  String get thirtySeconds => '30 secondes';

  @override
  String get skipBackLength => 'Durée du retour arrière';

  @override
  String get skipForwardLength => 'Durée de l’avance';

  @override
  String get customMpvConfPath => 'Chemin du mpv.conf personnalisé';

  @override
  String get notSetMpvConf =>
      'Non défini. Moonfin tentera d’utiliser un mpv.conf par défaut dans les dossiers app/data.';

  @override
  String get selectMpvConf => 'Sélectionner mpv.conf';

  @override
  String get pathToMpvConf => '/chemin/vers/mpv.conf';

  @override
  String get subtitleStyleDescription =>
      'Les réglages de style (taille, couleur, décalage) s’appliquent aux sous-titres textuels (SRT, VTT, TTML). Les sous-titres ASS/SSA utilisent leur propre style intégré sauf si « Lecture directe ASS/SSA » est désactivé. Les sous-titres bitmap (PGS, DVB, VobSub) ne peuvent pas être restylés.';

  @override
  String get defaultSubtitleLanguage => 'Langue des sous-titres par défaut';

  @override
  String get defaultToNoSubtitles => 'Aucun sous-titre par défaut';

  @override
  String get turnOffSubtitlesByDefault =>
      'Désactiver les sous-titres par défaut';

  @override
  String get subtitleSize => 'Taille des sous-titres';

  @override
  String get textColor => 'Couleur du texte';

  @override
  String get backgroundColor => 'Couleur d’arrière-plan';

  @override
  String get strokeColor => 'Couleur du contour';

  @override
  String get verticalOffset => 'Décalage vertical';

  @override
  String get pgsDirectPlay => 'Lecture directe PGS';

  @override
  String get directPlayPgsSubtitles => 'Lire directement les sous-titres PGS';

  @override
  String get assSsaDirectPlay => 'Lecture directe ASS/SSA';

  @override
  String get directPlayAssSsaSubtitles =>
      'Lire directement les sous-titres ASS/SSA';

  @override
  String get white => 'Blanc';

  @override
  String get black => 'Noir';

  @override
  String get yellow => 'Jaune';

  @override
  String get green => 'Vert';

  @override
  String get cyan => 'Cyan';

  @override
  String get red => 'Rouge';

  @override
  String get transparent => 'Transparent';

  @override
  String get semiTransparentBlack => 'Noir semi-transparent';

  @override
  String get global => 'Global';

  @override
  String get desktop => 'Bureau';

  @override
  String get mobile => 'Mobile';

  @override
  String get tv => 'TV';

  @override
  String loadedProfileSettings(String profile) {
    return 'Paramètres du profil $profile chargés.';
  }

  @override
  String failedToLoadProfileSettings(String profile) {
    return 'Impossible de charger les paramètres du profil $profile.';
  }

  @override
  String syncedSettingsToProfile(String profile) {
    return 'Paramètres locaux synchronisés avec le profil $profile.';
  }

  @override
  String get customizationProfile => 'Profil de personnalisation';

  @override
  String get customizationProfileDescription =>
      'Choisissez le profil à charger, modifier et synchroniser. Global s’applique partout sauf si un profil d’appareil le remplace. Le point vert indique le profil de votre appareil actuel.';

  @override
  String get loadProfile => 'Charger le profil';

  @override
  String get syncing => 'Synchronisation...';

  @override
  String get syncToProfile => 'Synchroniser vers le profil';

  @override
  String get profileSyncHidden => 'Synchronisation de profil masquée';

  @override
  String get enablePluginSyncDescription =>
      'Activez la synchronisation du plugin serveur dans les paramètres du plugin pour afficher ici les contrôles du profil.';

  @override
  String get quality => 'Qualité';

  @override
  String get defaultDownloadQuality => 'Qualité de téléchargement par défaut';

  @override
  String get network => 'Réseau';

  @override
  String get wifiOnlyDownloads => 'Téléchargements Wi‑Fi uniquement';

  @override
  String get onlyDownloadOnWifi => 'Télécharger uniquement en Wi‑Fi';

  @override
  String get storage => 'Stockage';

  @override
  String get storageUsed => 'Stockage utilisé';

  @override
  String get manage => 'Gérer';

  @override
  String get calculating => 'Calcul...';

  @override
  String get downloadLocation => 'Emplacement de téléchargement';

  @override
  String get defaultLabel => 'Par défaut';

  @override
  String get saveToDownloadsFolder =>
      'Enregistrer dans le dossier Téléchargements';

  @override
  String get downloadsVisibleToOtherApps =>
      'Téléchargements/Moonfin — visible pour les autres applications';

  @override
  String get dangerZone => 'Zone dangereuse';

  @override
  String get clearAllDownloads => 'Supprimer tous les téléchargements';

  @override
  String get original => 'Original';

  @override
  String get changeDownloadLocation =>
      'Changer l’emplacement de téléchargement';

  @override
  String get changeDownloadLocationDescription =>
      'Les nouveaux téléchargements seront enregistrés dans le dossier sélectionné. Les téléchargements existants resteront à leur emplacement actuel et pourront être gérés dans les paramètres de stockage.';

  @override
  String get confirm => 'Confirmer';

  @override
  String get cannotWriteToFolder =>
      'Impossible d’écrire dans le dossier sélectionné. Choisissez un autre emplacement ou accordez les autorisations de stockage.';

  @override
  String get saveToDownloadsFolderQuestion =>
      'Enregistrer dans le dossier Téléchargements ?';

  @override
  String get saveToDownloadsFolderDescription =>
      'Les médias téléchargés seront enregistrés dans Téléchargements/Moonfin sur votre appareil. Ces fichiers seront visibles par d’autres applications, comme votre galerie ou votre lecteur de musique.\n\nLes téléchargements existants resteront à leur emplacement actuel.';

  @override
  String get enable => 'Activer';

  @override
  String get clearAllDownloadsWarning =>
      'Cela supprimera tous les médias téléchargés et ne peut pas être annulé.';

  @override
  String get clearAll => 'Tout supprimer';

  @override
  String get navigationStyle => 'Style de navigation';

  @override
  String get topBar => 'Barre supérieure';

  @override
  String get leftSidebar => 'Barre latérale gauche';

  @override
  String get showShuffleButton => 'Afficher le bouton Aléatoire';

  @override
  String get showGenresButton => 'Afficher le bouton Genres';

  @override
  String get showFavoritesButton => 'Afficher le bouton Favoris';

  @override
  String get showLibrariesInToolbar =>
      'Afficher les bibliothèques dans la barre d’outils';

  @override
  String get navbarOpacity => 'Opacité de la barre de navigation';

  @override
  String get navbarColor => 'Couleur de la barre de navigation';

  @override
  String get gray => 'Gris';

  @override
  String get darkBlue => 'Bleu foncé';

  @override
  String get purple => 'Violet';

  @override
  String get teal => 'Bleu canard';

  @override
  String get navy => 'Bleu marine';

  @override
  String get charcoal => 'Anthracite';

  @override
  String get brown => 'Marron';

  @override
  String get darkRed => 'Rouge foncé';

  @override
  String get darkGreen => 'Vert foncé';

  @override
  String get slate => 'Ardoise';

  @override
  String get indigo => 'Indigo';

  @override
  String get libraryDisplay => 'Affichage de la bibliothèque';

  @override
  String get posterLabel => 'Affiche';

  @override
  String get thumbnailLabel => 'Miniature';

  @override
  String get bannerLabel => 'Bannière';

  @override
  String get overridePerLibrarySettings =>
      'Remplacer les paramètres par bibliothèque';

  @override
  String get applyImageTypeToAllLibraries =>
      'Appliquer le type d’image à toutes les bibliothèques';

  @override
  String get multiServerLibraries => 'Bibliothèques multi-serveurs';

  @override
  String get showLibrariesFromAllServers =>
      'Afficher les bibliothèques de tous les serveurs connectés';

  @override
  String get enableFolderView => 'Activer la vue dossiers';

  @override
  String get showFolderBrowsingOption =>
      'Afficher l’option de navigation par dossiers';

  @override
  String get libraryVisibility => 'Visibilité de la bibliothèque';

  @override
  String get showInNavigation => 'Afficher dans la navigation';

  @override
  String get showInLatestMedia => 'Afficher dans Derniers médias';

  @override
  String get sourceLibraries => 'Bibliothèques sources';

  @override
  String get sourceCollections => 'Collections sources';

  @override
  String get excludedGenres => 'Genres exclus';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String itemsSelected(int count) {
    return '$count sélectionnés';
  }

  @override
  String get mediaBar => 'Barre média';

  @override
  String get enableMediaBar => 'Activer la barre média';

  @override
  String get showFeaturedContentSlideshow =>
      'Afficher le diaporama du contenu à la une sur l’accueil';

  @override
  String get contentType => 'Type de contenu';

  @override
  String get moviesAndTvShows => 'Films et séries TV';

  @override
  String get moviesOnly => 'Films uniquement';

  @override
  String get tvShowsOnly => 'Séries TV uniquement';

  @override
  String get itemCount => 'Nombre d’éléments';

  @override
  String get noneSelected => 'Aucune sélection';

  @override
  String get noneExcluded => 'Aucune exclusion';

  @override
  String get autoAdvance => 'Avance automatique';

  @override
  String get autoAdvanceSlides =>
      'Passer automatiquement à la diapositive suivante';

  @override
  String get autoAdvanceInterval => 'Intervalle d’avance automatique';

  @override
  String get trailerPreview => 'Aperçu de bande-annonce';

  @override
  String get autoPlayTrailers =>
      'Lire automatiquement les bandes-annonces dans la barre média après 3 secondes';

  @override
  String get episodePreview => 'Aperçu d’épisode';

  @override
  String get episodePreviewDescription =>
      'Lire un aperçu intégré de 30 secondes sur les cartes ciblées, survolées ou maintenues';

  @override
  String get previewAudio => 'Audio de l’aperçu';

  @override
  String get enablePreviewAudio =>
      'Activer l’audio pour les aperçus de bandes-annonces et d’épisodes';

  @override
  String get latestMedia => 'Derniers médias';

  @override
  String get recentlyReleased => 'Récemment sortis';

  @override
  String get myMedia => 'Mes médias';

  @override
  String get myMediaSmall => 'Mes médias (petit)';

  @override
  String get continueWatching => 'Continuer à regarder';

  @override
  String get resumeAudio => 'Reprendre l’audio';

  @override
  String get resumeBooks => 'Reprendre les livres';

  @override
  String get activeRecordings => 'Enregistrements actifs';

  @override
  String get playlists => 'Listes de lecture';

  @override
  String get liveTV => 'TV en direct';

  @override
  String get homeSections => 'Sections de l’accueil';

  @override
  String get resetToDefaults => 'Réinitialiser aux valeurs par défaut';

  @override
  String get homeRowPosterSize => 'Taille des affiches des rangées d’accueil';

  @override
  String get perRowImageTypeSelection => 'Sélection du type d’image par rangée';

  @override
  String get configureImageTypeForEachRow =>
      'Configurer le type d’image pour chaque rangée d’accueil activée';

  @override
  String get mergeContinueWatchingAndNextUp =>
      'Fusionner Continuer à regarder et À suivre';

  @override
  String get combineBothRows =>
      'Combiner les deux rangées en une seule section d’accueil';

  @override
  String get perRowImageType => 'Type d’image par rangée';

  @override
  String get perRowSettings => 'Paramètres par rangée';

  @override
  String get autoLogin => 'Connexion automatique';

  @override
  String get lastUser => 'Dernier utilisateur';

  @override
  String get specificUser => 'Utilisateur spécifique';

  @override
  String get alwaysAuthenticate => 'Toujours s’authentifier';

  @override
  String get requirePasswordWithToken =>
      'Exiger le mot de passe même avec un jeton enregistré';

  @override
  String get confirmExit => 'Confirmer la sortie';

  @override
  String get showConfirmationBeforeExiting =>
      'Afficher une confirmation avant de quitter';

  @override
  String get blockContentWithRatings =>
      'Bloquer le contenu avec les classifications suivantes :';

  @override
  String get noContentRatingsFound =>
      'Aucune classification de contenu n’a encore été trouvée sur ce serveur.';

  @override
  String get couldNotLoadServerRatings =>
      'Impossible de charger les classifications du serveur. Affichage des classifications enregistrées uniquement.';

  @override
  String get couldNotRefreshRatings =>
      'Impossible d’actualiser les classifications depuis le serveur. Affichage des classifications enregistrées.';

  @override
  String get enablePinCode => 'Activer le code PIN';

  @override
  String get requirePinToAccess =>
      'Exiger un code PIN pour accéder à votre compte';

  @override
  String get changePin => 'Modifier le PIN';

  @override
  String get setNewPinCode => 'Définir un nouveau code PIN';

  @override
  String get removePin => 'Supprimer le PIN';

  @override
  String get removePinProtection => 'Supprimer la protection par code PIN';

  @override
  String get screensaver => 'Économiseur d’écran';

  @override
  String get inAppScreensaver => 'Économiseur d’écran intégré';

  @override
  String get enableBuiltInScreensaver =>
      'Activer l’économiseur d’écran intégré';

  @override
  String get mode => 'Mode';

  @override
  String get libraryArt => 'Illustrations de bibliothèque';

  @override
  String get logo => 'Logo';

  @override
  String get clock => 'Horloge';

  @override
  String get timeout => 'Délai';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get dimmingLevel => 'Niveau d’assombrissement';

  @override
  String get maxAgeRating => 'Classification d’âge maximale';

  @override
  String get any => 'Tous';

  @override
  String agePlusValue(int age) {
    return '$age+';
  }

  @override
  String get requireAgeRating => 'Exiger une classification d’âge';

  @override
  String get onlyShowRatedContent => 'Afficher uniquement le contenu classifié';

  @override
  String get showClock => 'Afficher l’horloge';

  @override
  String get displayClockDuringScreensaver =>
      'Afficher l’horloge pendant l’économiseur d’écran';

  @override
  String get rottenTomatoesCritics => 'Rotten Tomatoes (Critiques)';

  @override
  String get rottenTomatoesAudience => 'Rotten Tomatoes (Public)';

  @override
  String get imdb => 'IMDb';

  @override
  String get tmdb => 'TMDB';

  @override
  String get metacritic => 'Metacritic';

  @override
  String get metacriticUser => 'Metacritic (utilisateurs)';

  @override
  String get trakt => 'Trakt';

  @override
  String get letterboxd => 'Letterboxd';

  @override
  String get myAnimeList => 'MyAnimeList';

  @override
  String get aniList => 'AniList';

  @override
  String get communityRating => 'Note de la communauté';

  @override
  String get ratings => 'Notes';

  @override
  String get additionalRatings => 'Notes supplémentaires';

  @override
  String get showMdbListAndTmdbRatings => 'Afficher les notes MDBList et TMDB';

  @override
  String get ratingLabels => 'Libellés des notes';

  @override
  String get showLabelsNextToIcons =>
      'Afficher les libellés à côté des icônes de note';

  @override
  String get ratingBadges => 'Badges de note';

  @override
  String get showDecorativeBadges =>
      'Afficher des badges décoratifs derrière les notes';

  @override
  String get episodeRatings => 'Notes des épisodes';

  @override
  String get showRatingsOnEpisodes => 'Afficher les notes sur chaque épisode';

  @override
  String get ratingSources => 'Sources des notes';

  @override
  String get ratingSourcesDescription =>
      'Activer et réorganiser les sources de notes affichées dans l’app';

  @override
  String get pluginLabel => 'Plugin';

  @override
  String get pluginDetected => 'Plugin détecté';

  @override
  String get pluginNotDetected => 'Plugin non détecté';

  @override
  String get pluginDetectedDescription =>
      'Plugin serveur détecté. La synchronisation est activée automatiquement la première fois que le plugin est trouvé.';

  @override
  String get pluginNotDetectedDescription =>
      'Le plugin serveur n’est pas détecté actuellement. Les paramètres locaux utilisent toujours leurs valeurs enregistrées ou les valeurs par défaut intégrées.';

  @override
  String pluginStatusVersion(String status, String version) {
    return '$status\nVersion : $version';
  }

  @override
  String get availableServices => 'Services disponibles';

  @override
  String get serverPluginSync => 'Synchronisation du plugin serveur';

  @override
  String get syncSettingsWithPlugin =>
      'Synchroniser les paramètres avec le plugin serveur';

  @override
  String get whatSyncControls => 'Ce que contrôle la synchro';

  @override
  String get syncControlsDescription =>
      'La synchro contrôle seulement l’envoi et la récupération des paramètres pris en charge par le plugin sur le serveur. La sélection du profil et les actions de synchronisation du profil se trouvent dans les paramètres de personnalisation quand la synchro du plugin est activée.';

  @override
  String get recentRequests => 'Demandes récentes';

  @override
  String get recentlyAdded => 'Ajouts récents';

  @override
  String get trending => 'Tendances';

  @override
  String get popularMovies => 'Films populaires';

  @override
  String get movieGenres => 'Genres de films';

  @override
  String get upcomingMovies => 'Films à venir';

  @override
  String get studios => 'Studios';

  @override
  String get popularSeries => 'Séries populaires';

  @override
  String get seriesGenres => 'Genres de séries';

  @override
  String get upcomingSeries => 'Séries à venir';

  @override
  String get networks => 'Chaînes';

  @override
  String get resetRowsToDefaults => 'Réinitialiser les lignes par défaut';

  @override
  String get enableSeerr => 'Activer Seerr';

  @override
  String get showSeerrInNavigation =>
      'Afficher Seerr dans la navigation (plugin serveur requis)';

  @override
  String get seerrUnavailable =>
      'Indisponible, car la prise en charge de Seerr par le plugin serveur est désactivée.';

  @override
  String get nsfwFilter => 'Filtre NSFW';

  @override
  String get hideAdultContent => 'Masquer le contenu adulte dans les résultats';

  @override
  String loggedInAs(String username) {
    return 'Connecté en tant que : $username';
  }

  @override
  String get discoverRows => 'Lignes de découverte';

  @override
  String get discoverRowsDescriptionPlugin =>
      'Faites glisser pour réorganiser. Activez ou désactivez les lignes. L’ordre des lignes activées se synchronise avec le plugin Moonfin.';

  @override
  String get discoverRowsDescription =>
      'Faites glisser pour réorganiser. Activez ou désactivez les lignes.';

  @override
  String get enabled => 'Activé';

  @override
  String get hidden => 'Masqué';

  @override
  String get aboutTitle => 'À propos';

  @override
  String versionValue(String version) {
    return 'Version $version';
  }

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get sourceCode => 'Code source';

  @override
  String get checkForUpdatesNow => 'Vérifier les mises à jour';

  @override
  String get checksLatestDesktopRelease =>
      'Vérifie la dernière version desktop pour cette plateforme';

  @override
  String get youAreUpToDate => 'Vous êtes à jour.';

  @override
  String get couldNotCheckForUpdates =>
      'Impossible de vérifier les mises à jour pour le moment.';

  @override
  String get noCompatibleUpdate =>
      'Aucun paquet de mise à jour compatible trouvé pour cette plateforme.';

  @override
  String get updateChecksNotSupported =>
      'La vérification des mises à jour n’est pas prise en charge sur cette plateforme.';

  @override
  String get updateNotificationsDisabled =>
      'Les notifications de mise à jour sont désactivées.';

  @override
  String get pleaseWaitBeforeChecking =>
      'Veuillez attendre avant de vérifier à nouveau.';

  @override
  String get latestUpdateAlreadyShown =>
      'La dernière mise à jour a déjà été affichée.';

  @override
  String get updateAvailable => 'Mise à jour disponible.';

  @override
  String updateAvailableVersion(String version) {
    return 'Mise à jour disponible : v$version';
  }

  @override
  String get updateNotifications => 'Notifications de mise à jour';

  @override
  String get showWhenUpdatesAvailable =>
      'Afficher quand des mises à jour sont disponibles';

  @override
  String get navigation => 'Navigation';

  @override
  String get watchedIndicatorsBackdrops => 'Indicateurs vus, arrière-plans';

  @override
  String get focusColorWatchedIndicatorsBackdrops =>
      'Couleur de focus, indicateurs vus, arrière-plans';

  @override
  String get navbarStyleToolbarAppearance =>
      'Style de la barre de navigation, boutons de la barre d’outils, apparence';

  @override
  String get reorderToggleHomeRows =>
      'Réorganiser et afficher/masquer les lignes d’accueil';

  @override
  String get featuredContentAppearance => 'Contenu à la une, apparence';

  @override
  String get posterSizeImageTypeFolderView =>
      'Taille des affiches, type d’image, vue des dossiers';

  @override
  String get mdbListTmdbRatingSources => 'MDBList, TMDB et sources des notes';

  @override
  String gbValue(String value) {
    return '$value GB';
  }

  @override
  String get clear => 'Effacer';

  @override
  String get browse => 'Parcourir';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get seerrAvailableStatus => 'Disponible';

  @override
  String get seerrRequestedStatus => 'Demandé';

  @override
  String itemsCount(int count) {
    return '$count éléments';
  }

  @override
  String get seerrSettings => 'Paramètres Seerr';

  @override
  String get requestMore => 'Demander plus';

  @override
  String get request => 'Demander';

  @override
  String get cancelRequest => 'Annuler la demande';

  @override
  String get playInMoonfin => 'Lire dans Moonfin';

  @override
  String requestedByName(String name) {
    return 'Demandé par $name';
  }

  @override
  String get approve => 'Approuver';

  @override
  String get declineAction => 'Refuser';

  @override
  String get similar => 'Similaires';

  @override
  String get recommendations => 'Recommandations';

  @override
  String cancelRequestForTitle(String title) {
    return 'Annuler la demande pour \"$title\" ?';
  }

  @override
  String cancelCountRequestsForTitle(int count, String title) {
    return 'Annuler $count demandes pour \"$title\" ?';
  }

  @override
  String get keep => 'Conserver';

  @override
  String get itemNotFoundInLibrary =>
      'Élément introuvable dans votre bibliothèque Moonfin';

  @override
  String get errorSearchingLibrary =>
      'Erreur lors de la recherche dans la bibliothèque';

  @override
  String budgetAmount(String amount) {
    return 'Budget : \$$amount';
  }

  @override
  String revenueAmount(String amount) {
    return 'Recettes : \$$amount';
  }

  @override
  String seasonsCount(int count, String label) {
    return '$count $label';
  }

  @override
  String requestSeriesOrMovie(String type) {
    return 'Demander $type';
  }

  @override
  String get submitRequest => 'Envoyer la demande';

  @override
  String get allSeasons => 'Toutes les saisons';

  @override
  String get advancedOptions => 'Options avancées';

  @override
  String get noServiceServersConfigured => 'Aucun serveur de service configuré';

  @override
  String get server => 'Serveur';

  @override
  String get qualityProfile => 'Profil de qualité';

  @override
  String get rootFolder => 'Dossier racine';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get appearances => 'Apparitions';

  @override
  String get crewSection => 'Équipe';

  @override
  String ageValue(int age) {
    return 'âge $age';
  }

  @override
  String get noRequests => 'Aucune demande';

  @override
  String get pendingStatus => 'En attente';

  @override
  String get declinedStatus => 'Refusé';

  @override
  String get partiallyAvailable => 'Partiellement disponible';

  @override
  String get downloadingStatus => 'Téléchargement';

  @override
  String get approvedStatus => 'Approuvé';

  @override
  String get access => 'Accès';

  @override
  String get add => 'Ajouter';

  @override
  String get address => 'Adresse';

  @override
  String get analytics => 'Analyses';

  @override
  String get catalog => 'Catalogue';

  @override
  String get content => 'Contenu';

  @override
  String get copy => 'Copier';

  @override
  String get create => 'Créer';

  @override
  String get disable => 'Désactiver';

  @override
  String get done => 'Terminé';

  @override
  String get edit => 'Modifier';

  @override
  String get encoding => 'Encodage';

  @override
  String get error => 'Erreur';

  @override
  String get forward => 'Avancer';

  @override
  String get general => 'Général';

  @override
  String get go => 'Aller';

  @override
  String get install => 'Installer';

  @override
  String get installed => 'Installé';

  @override
  String get interval => 'Intervalle';

  @override
  String get name => 'Nom';

  @override
  String get networking => 'Réseau';

  @override
  String get next => 'Suivant';

  @override
  String get path => 'Chemin';

  @override
  String get paused => 'En pause';

  @override
  String get permissions => 'Autorisations';

  @override
  String get processing => 'Traitement';

  @override
  String get profile => 'Profil';

  @override
  String get provider => 'Fournisseur';

  @override
  String get refresh => 'Actualiser';

  @override
  String get remote => 'À distance';

  @override
  String get rename => 'Renommer';

  @override
  String get revoke => 'Révoquer';

  @override
  String get role => 'Rôle';

  @override
  String get root => 'Racine';

  @override
  String get run => 'Exécuter';

  @override
  String get search => 'Rechercher';

  @override
  String get select => 'Sélectionner';

  @override
  String get send => 'Envoyer';

  @override
  String get sessions => 'Sessions';

  @override
  String get set => 'Définir';

  @override
  String get status => 'Statut';

  @override
  String get stop => 'Arrêter';

  @override
  String get streaming => 'Streaming';

  @override
  String get time => 'Heure';

  @override
  String get trickplay => 'Trickplay';

  @override
  String get uninstall => 'Désinstaller';

  @override
  String get up => 'Haut';

  @override
  String get update => 'Mettre à jour';

  @override
  String get upload => 'Téléverser';

  @override
  String get unmute => 'Activer le son';

  @override
  String get mute => 'Couper le son';

  @override
  String get branding => 'Branding';

  @override
  String get adminDrawerDashboard => 'Tableau de bord';

  @override
  String get adminDrawerAnalytics => 'Analyses';

  @override
  String get adminDrawerSettings => 'Paramètres';

  @override
  String get adminDrawerBranding => 'Branding';

  @override
  String get adminDrawerUsers => 'Utilisateurs';

  @override
  String get adminDrawerLibraries => 'Bibliothèques';

  @override
  String get adminDrawerTranscoding => 'Transcodage';

  @override
  String get adminDrawerResume => 'Reprise';

  @override
  String get adminDrawerStreaming => 'Streaming';

  @override
  String get adminDrawerTrickplay => 'Trickplay';

  @override
  String get adminDrawerDevices => 'Appareils';

  @override
  String get adminDrawerActivity => 'Activité';

  @override
  String get adminDrawerNetworking => 'Réseau';

  @override
  String get adminDrawerApiKeys => 'Clés API';

  @override
  String get adminDrawerBackups => 'Sauvegardes';

  @override
  String get adminDrawerLogs => 'Journaux';

  @override
  String get adminDrawerScheduledTasks => 'Tâches planifiées';

  @override
  String get adminDrawerPlugins => 'Plugins';

  @override
  String get adminDrawerRepositories => 'Dépôts';

  @override
  String get adminDrawerLiveTv => 'TV en direct';

  @override
  String get adminExitTooltip => 'Quitter l’admin';

  @override
  String get adminDashboardLoadFailed =>
      'Impossible de charger le tableau de bord';

  @override
  String get adminMediaOverview => 'Vue d’ensemble des médias';

  @override
  String get adminMediaTotalsError =>
      'Impossible de charger les totaux des médias du serveur.';

  @override
  String get adminMediaOverviewSubtitle =>
      'Un aperçu rapide du volume de contenu sur ce serveur.';

  @override
  String adminPluginUpdatesAvailable(int count) {
    return 'Mises à jour de plugins disponibles : $count';
  }

  @override
  String adminPluginsRequiringRestart(int count) {
    return 'Plugins nécessitant un redémarrage : $count';
  }

  @override
  String adminFailedScheduledTasks(int count) {
    return 'Tâches planifiées en échec : $count';
  }

  @override
  String adminRecentAlertEntries(int count) {
    return 'Entrées d\'avertissement/erreur récentes : $count';
  }

  @override
  String get analyticsMediaDistribution => 'Répartition des médias';

  @override
  String get analyticsVideoCodecs => 'Codecs vidéo';

  @override
  String get analyticsAudioCodecs => 'Codecs audio';

  @override
  String get analyticsContainers => 'Conteneurs';

  @override
  String get analyticsTopGenres => 'Genres principaux';

  @override
  String get analyticsReleaseYears => 'Années de sortie';

  @override
  String get analyticsContentRatings => 'Classifications du contenu';

  @override
  String get analyticsRuntimeBuckets => 'Plages de durée';

  @override
  String get analyticsFileFormats => 'Formats de fichier';

  @override
  String get analyticsNoData => 'Aucune donnée disponible.';

  @override
  String get adminServerInfo => 'Infos serveur';

  @override
  String get adminRestartPending => 'Redémarrage en attente';

  @override
  String get adminServerPaths => 'Chemins du serveur';

  @override
  String get adminServerActions => 'Actions du serveur';

  @override
  String get adminRestartServer => 'Redémarrer le serveur';

  @override
  String get adminShutdownServer => 'Arrêter le serveur';

  @override
  String get adminScanLibraries => 'Analyser les bibliothèques';

  @override
  String get adminLibraryScanStarted => 'Analyse de la bibliothèque lancée';

  @override
  String errorGeneric(String error) {
    return 'Erreur : $error';
  }

  @override
  String get adminServerRebootInProgress => 'Redémarrage du serveur en cours';

  @override
  String get adminServerRebootMessage =>
      'Redémarrage du serveur en cours, veuillez redémarrer Moonfin';

  @override
  String get adminActiveSessions => 'Sessions actives';

  @override
  String get adminSessionsLoadFailed => 'Échec du chargement des sessions';

  @override
  String get adminNoActiveSessions => 'Aucune session active';

  @override
  String get adminRecentActivity => 'Activité récente';

  @override
  String get adminNoRecentActivity => 'Aucune activité récente';

  @override
  String adminCommandFailed(String error) {
    return 'Échec de la commande : $error';
  }

  @override
  String get adminSendMessage => 'Envoyer un message';

  @override
  String get adminMessageTextHint => 'Texte du message';

  @override
  String get adminSetVolume => 'Régler le volume';

  @override
  String get sessionPrev => 'Préc.';

  @override
  String get sessionRewind => 'Retour rapide';

  @override
  String get sessionForward => 'Avance rapide';

  @override
  String get sessionNext => 'Suiv.';

  @override
  String get sessionVolumeDown => 'Vol –';

  @override
  String get sessionVolumeUp => 'Vol +';

  @override
  String get nowPlaying => 'Lecture en cours';

  @override
  String get volume => 'Volume';

  @override
  String get actions => 'Actions';

  @override
  String get videoCodec => 'Codec vidéo';

  @override
  String get audioCodec => 'Codec audio';

  @override
  String get hwAccel => 'Accél. matérielle';

  @override
  String get completion => 'Progression';

  @override
  String get direct => 'Direct';

  @override
  String get adminDisconnect => 'Déconnecter';

  @override
  String get adminClearDates => 'Effacer les dates';

  @override
  String adminActivityLoadFailed(String error) {
    return 'Échec du chargement du journal d\'activité : $error';
  }

  @override
  String get adminNoActivityEntries => 'Aucune entrée d\'activité';

  @override
  String get adminEditDeviceName => 'Modifier le nom de l\'appareil';

  @override
  String get adminCustomName => 'Nom personnalisé';

  @override
  String get adminDeviceNameUpdated => 'Nom de l\'appareil mis à jour';

  @override
  String adminDeviceUpdateFailed(String error) {
    return 'Échec de la mise à jour de l\'appareil : $error';
  }

  @override
  String get adminDeleteDevice => 'Supprimer l\'appareil';

  @override
  String get adminDeviceDeleted => 'Appareil supprimé';

  @override
  String adminDeviceDeleteFailed(String error) {
    return 'Échec de la suppression de l\'appareil : $error';
  }

  @override
  String get adminDevicesLoadFailed => 'Échec du chargement des appareils';

  @override
  String get adminSearchDevices => 'Rechercher des appareils';

  @override
  String get adminThisDevice => 'Cet appareil';

  @override
  String get adminEditName => 'Modifier le nom';

  @override
  String get adminLibrariesLoadFailed =>
      'Échec du chargement des bibliothèques';

  @override
  String get adminNoLibraries => 'Aucune bibliothèque configurée';

  @override
  String get adminScanAllLibraries => 'Analyser toutes les bibliothèques';

  @override
  String get adminAddLibrary => 'Ajouter une bibliothèque';

  @override
  String adminScanFailed(String error) {
    return 'Échec du démarrage de l\'analyse : $error';
  }

  @override
  String get adminRenameLibrary => 'Renommer la bibliothèque';

  @override
  String get adminNewName => 'Nouveau nom';

  @override
  String adminLibraryRenamed(String name) {
    return 'Bibliothèque renommée en \"$name\"';
  }

  @override
  String adminRenameFailed(String error) {
    return 'Échec du renommage : $error';
  }

  @override
  String get adminDeleteLibrary => 'Supprimer la bibliothèque';

  @override
  String adminLibraryDeleted(String name) {
    return 'Bibliothèque \"$name\" supprimée';
  }

  @override
  String adminLibraryDeleteFailed(String error) {
    return 'Échec de la suppression de la bibliothèque : $error';
  }

  @override
  String adminAddPathFailed(String error) {
    return 'Échec de l\'ajout du chemin : $error';
  }

  @override
  String get adminRemovePath => 'Supprimer le chemin';

  @override
  String adminRemovePathConfirm(String path) {
    return 'Supprimer \"$path\" de cette bibliothèque ?';
  }

  @override
  String adminRemovePathFailed(String error) {
    return 'Échec de la suppression du chemin : $error';
  }

  @override
  String get adminLibraryOptionsSaved =>
      'Options de la bibliothèque enregistrées';

  @override
  String adminLibraryOptionsSaveFailed(String error) {
    return 'Échec de l\'enregistrement des options : $error';
  }

  @override
  String get adminLibraryLoadFailed => 'Échec du chargement de la bibliothèque';

  @override
  String get adminNoMediaPaths => 'Aucun chemin multimédia configuré';

  @override
  String get adminAddPath => 'Ajouter un chemin';

  @override
  String get adminBrowseFilesystem =>
      'Parcourir le système de fichiers du serveur :';

  @override
  String get adminSaveOptions => 'Enregistrer les options';

  @override
  String get adminPreferredMetadataLanguage =>
      'Langue préférée des métadonnées';

  @override
  String get adminMetadataLanguageHint => 'ex. : en, de, fr';

  @override
  String get adminMetadataCountryCode => 'Code pays des métadonnées';

  @override
  String get adminMetadataCountryHint => 'ex. : US, DE, FR';

  @override
  String get adminLibraryNameRequired => 'Le nom de la bibliothèque est requis';

  @override
  String adminLibraryCreateFailed(String error) {
    return 'Échec de la création de la bibliothèque : $error';
  }

  @override
  String get adminLibraryName => 'Nom de la bibliothèque';

  @override
  String get adminSelectedPaths => 'Chemins sélectionnés :';

  @override
  String get adminNoPathsAdded =>
      'Aucun chemin ajouté (vous pourrez en ajouter plus tard)';

  @override
  String get adminCreateLibrary => 'Créer une bibliothèque';

  @override
  String get paths => 'Chemins :';

  @override
  String get adminDisableUser => 'Désactiver l\'utilisateur';

  @override
  String get adminEnableUser => 'Activer l\'utilisateur';

  @override
  String adminDisableUserConfirm(String name) {
    return 'Désactiver $name ? Cette personne ne pourra plus se connecter.';
  }

  @override
  String adminEnableUserConfirm(String name) {
    return 'Activer $name ? Cette personne pourra de nouveau se connecter.';
  }

  @override
  String adminUserDisabled(String name) {
    return 'Utilisateur \"$name\" désactivé';
  }

  @override
  String adminUserEnabled(String name) {
    return 'Utilisateur \"$name\" activé';
  }

  @override
  String adminUserPolicyUpdateFailed(String error) {
    return 'Échec de la mise à jour de la politique utilisateur : $error';
  }

  @override
  String get adminUsersLoadFailed => 'Échec du chargement des utilisateurs';

  @override
  String get adminSearchUsers => 'Rechercher des utilisateurs';

  @override
  String get adminEditUser => 'Modifier l\'utilisateur';

  @override
  String get adminAddUser => 'Ajouter un utilisateur';

  @override
  String adminUserCreateFailed(String error) {
    return 'Échec de la création de l\'utilisateur : $error';
  }

  @override
  String get adminCreateUser => 'Créer un utilisateur';

  @override
  String get adminPasswordOptional => 'Mot de passe (facultatif)';

  @override
  String get adminUsernameRequired =>
      'Le nom d\'utilisateur ne peut pas être vide';

  @override
  String get adminNoProfileChanges =>
      'Aucune modification du profil à enregistrer';

  @override
  String get adminProfileSaved => 'Profil enregistré';

  @override
  String adminSaveFailed(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String get adminPermissionsSaved => 'Autorisations enregistrées';

  @override
  String get adminPasswordsMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String adminFailed(String error) {
    return 'Échec : $error';
  }

  @override
  String get adminUserLoadFailed => 'Échec du chargement de l\'utilisateur';

  @override
  String get adminBackToUsers => 'Retour aux utilisateurs';

  @override
  String get adminSaveProfile => 'Enregistrer le profil';

  @override
  String get adminDeleteUser => 'Supprimer l\'utilisateur';

  @override
  String get admin => 'Admin';

  @override
  String get adminFullAccessWarning =>
      'Les administrateurs ont un accès complet au serveur. Accordez ce droit avec prudence.';

  @override
  String get administrator => 'Administrateur';

  @override
  String get adminHiddenUser => 'Utilisateur masqué';

  @override
  String get adminAllowMediaPlayback => 'Autoriser la lecture des médias';

  @override
  String get adminAllowAudioTranscoding => 'Autoriser le transcodage audio';

  @override
  String get adminAllowVideoTranscoding => 'Autoriser le transcodage vidéo';

  @override
  String get adminAllowRemuxing => 'Autoriser le remuxage';

  @override
  String get adminForceRemoteTranscoding =>
      'Forcer le transcodage des sources distantes';

  @override
  String get adminAllowContentDeletion => 'Autoriser la suppression du contenu';

  @override
  String get adminAllowContentDownloading =>
      'Autoriser le téléchargement du contenu';

  @override
  String get adminAllowPublicSharing => 'Autoriser le partage public';

  @override
  String get adminAllowRemoteControl =>
      'Autoriser le contrôle à distance des autres utilisateurs';

  @override
  String get adminAllowSharedDeviceControl =>
      'Autoriser le contrôle des appareils partagés';

  @override
  String get adminAllowRemoteAccess => 'Autoriser l\'accès à distance';

  @override
  String get adminRemoteBitrateLimit =>
      'Limite de débit du client distant (bps)';

  @override
  String get adminLeaveEmptyNoLimit => 'Laisser vide pour aucune limite';

  @override
  String get adminMaxActiveSessions => 'Nombre max. de sessions actives';

  @override
  String get adminAllowLiveTvAccess => 'Autoriser l\'accès à la TV en direct';

  @override
  String get adminAllowLiveTvManagement =>
      'Autoriser la gestion de la TV en direct';

  @override
  String get adminAllowCollectionManagement =>
      'Autoriser la gestion des collections';

  @override
  String get adminAllowSubtitleManagement =>
      'Autoriser la gestion des sous-titres';

  @override
  String get adminAllowLyricManagement => 'Autoriser la gestion des paroles';

  @override
  String get adminSavePermissions => 'Enregistrer les autorisations';

  @override
  String get adminEnableAllLibraryAccess =>
      'Activer l\'accès à toutes les bibliothèques';

  @override
  String get adminSaveAccess => 'Enregistrer l\'accès';

  @override
  String get adminChangePassword => 'Changer le mot de passe';

  @override
  String get adminNewPassword => 'Nouveau mot de passe';

  @override
  String get adminConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get adminSetPassword => 'Définir le mot de passe';

  @override
  String get adminResetPassword => 'Réinitialiser le mot de passe';

  @override
  String adminDeleteUserConfirm(String name) {
    return 'Voulez-vous vraiment supprimer $name ?';
  }

  @override
  String adminUserDeleted(String name) {
    return 'Utilisateur \"$name\" supprimé';
  }

  @override
  String adminUserDeleteFailed(String error) {
    return 'Échec de la suppression de l\'utilisateur : $error';
  }

  @override
  String get adminCreateApiKey => 'Créer une clé API';

  @override
  String get adminAppName => 'Nom de l\'application';

  @override
  String get adminApiKeyCreated => 'Clé API créée';

  @override
  String get adminApiKeyCreatedNoToken =>
      'Clé créée avec succès. Le serveur n\'a pas renvoyé le jeton. Vérifiez les clés API du serveur.';

  @override
  String get adminKeyCopied => 'Clé copiée dans le presse-papiers';

  @override
  String adminApiKeyCreateFailed(String error) {
    return 'Échec de la création de la clé : $error';
  }

  @override
  String get adminKeyTokenMissing =>
      'Jeton de clé absent dans la réponse du serveur';

  @override
  String get adminRevokeApiKey => 'Révoquer la clé API';

  @override
  String adminRevokeKeyConfirm(String name) {
    return 'Révoquer la clé de $name ?';
  }

  @override
  String get adminApiKeyRevoked => 'Clé API révoquée';

  @override
  String adminApiKeyRevokeFailed(String error) {
    return 'Échec de la révocation de la clé : $error';
  }

  @override
  String get adminApiKeysLoadFailed => 'Échec du chargement des clés API';

  @override
  String get adminCreateKey => 'Créer une clé';

  @override
  String get adminNoApiKeys => 'Aucune clé API trouvée';

  @override
  String get adminCreatingBackup => 'Création de la sauvegarde...';

  @override
  String get adminBackupCreated => 'Sauvegarde créée avec succès';

  @override
  String adminBackupCreateFailed(String error) {
    return 'Échec de la création de la sauvegarde : $error';
  }

  @override
  String get adminBackupPathMissing =>
      'Chemin de sauvegarde absent dans la réponse du serveur';

  @override
  String adminBackupManifest(String name) {
    return 'Manifeste : $name';
  }

  @override
  String adminManifestLoadFailed(String error) {
    return 'Échec du chargement du manifeste : $error';
  }

  @override
  String get adminConfirmRestore => 'Confirmer la restauration';

  @override
  String get adminRestoringBackup => 'Restauration de la sauvegarde...';

  @override
  String adminRestoreFailed(String error) {
    return 'Échec de la restauration de la sauvegarde : $error';
  }

  @override
  String get adminBackupsLoadFailed => 'Échec du chargement des sauvegardes';

  @override
  String get adminCreateBackup => 'Créer une sauvegarde';

  @override
  String get adminNoBackups => 'Aucune sauvegarde trouvée';

  @override
  String get adminViewDetails => 'Voir les détails';

  @override
  String get restore => 'Restaurer';

  @override
  String get adminLogsLoadFailed =>
      'Échec du chargement des journaux du serveur';

  @override
  String get adminNoLogFiles => 'Aucun fichier journal trouvé';

  @override
  String get adminLogCopied => 'Journal copié dans le presse-papiers';

  @override
  String get adminSaveLogFile => 'Enregistrer le fichier journal';

  @override
  String adminSavedTo(String path) {
    return 'Enregistré dans $path';
  }

  @override
  String adminFileSaveFailed(String error) {
    return 'Échec de l\'enregistrement du fichier : $error';
  }

  @override
  String adminLogFileLoadFailed(String fileName) {
    return 'Échec du chargement de $fileName';
  }

  @override
  String get adminSearchInLog => 'Rechercher dans le journal';

  @override
  String get adminNoMatchingLines => 'Aucune ligne correspondante';

  @override
  String adminTasksLoadFailed(String error) {
    return 'Échec du chargement des tâches : $error';
  }

  @override
  String get adminNoScheduledTasks => 'Aucune tâche planifiée trouvée';

  @override
  String get adminNoTasksMatchFilter =>
      'Aucune tâche ne correspond au filtre actuel';

  @override
  String adminTaskStartFailed(String error) {
    return 'Échec du démarrage de la tâche : $error';
  }

  @override
  String adminTaskStopFailed(String error) {
    return 'Échec de l\'arrêt de la tâche : $error';
  }

  @override
  String adminTaskLoadFailed(String error) {
    return 'Échec du chargement de la tâche : $error';
  }

  @override
  String get adminRunNow => 'Exécuter maintenant';

  @override
  String adminTriggerRemoveFailed(String error) {
    return 'Échec de la suppression du déclencheur : $error';
  }

  @override
  String adminTriggerAddFailed(String error) {
    return 'Échec de l\'ajout du déclencheur : $error';
  }

  @override
  String get adminLastExecution => 'Dernière exécution';

  @override
  String get adminTriggers => 'Déclencheurs';

  @override
  String get adminAddTrigger => 'Ajouter un déclencheur';

  @override
  String get adminNoTriggers => 'Aucun déclencheur configuré';

  @override
  String get adminTriggerType => 'Type de déclencheur';

  @override
  String get adminTimeLimit => 'Limite de temps (facultatif)';

  @override
  String get adminNoLimit => 'Aucune limite';

  @override
  String adminHours(String hours) {
    return '$hours heure(s)';
  }

  @override
  String get adminDayOfWeek => 'Jour de la semaine';

  @override
  String get adminSearchPlugins => 'Rechercher des plugins...';

  @override
  String adminPluginToggleFailed(String error) {
    return 'Impossible d\'activer/désactiver le plugin : $error';
  }

  @override
  String get adminUninstallPlugin => 'Désinstaller le plugin';

  @override
  String adminUninstallPluginConfirm(String name) {
    return 'Voulez-vous vraiment désinstaller « $name » ?';
  }

  @override
  String adminPluginUninstallFailed(String error) {
    return 'Impossible de désinstaller le plugin : $error';
  }

  @override
  String adminPackageInstallFailed(String error) {
    return 'Impossible d\'installer le paquet : $error';
  }

  @override
  String adminPluginUpdateFailed(String error) {
    return 'Impossible d\'installer la mise à jour : $error';
  }

  @override
  String adminPluginsLoadFailed(String error) {
    return 'Impossible de charger les plugins : $error';
  }

  @override
  String get adminNoPluginsMatchSearch =>
      'Aucun plugin ne correspond à votre recherche';

  @override
  String get adminNoPluginsInstalled => 'Aucun plugin installé';

  @override
  String adminInstallUpdate(String version) {
    return 'Installer la mise à jour (v$version)';
  }

  @override
  String adminCatalogLoadFailed(String error) {
    return 'Impossible de charger le catalogue : $error';
  }

  @override
  String get adminNoPackagesMatchSearch =>
      'Aucun paquet ne correspond à votre recherche';

  @override
  String get adminNoPackagesAvailable => 'Aucun paquet disponible';

  @override
  String get adminExperimentalIntegration => 'Intégration expérimentale';

  @override
  String get adminExperimentalWarning =>
      'L\'intégration des paramètres des plugins est encore expérimentale. Certaines pages peuvent ne pas s\'afficher correctement.';

  @override
  String get continueAction => 'Continuer';

  @override
  String adminPluginRemoveAfterRestart(String name) {
    return '« $name » sera supprimé après le redémarrage du serveur';
  }

  @override
  String adminUninstallFailed(String error) {
    return 'Impossible de désinstaller : $error';
  }

  @override
  String adminPluginUpdating(String name, String version) {
    return 'Mise à jour de « $name » vers la v$version...';
  }

  @override
  String get adminMissingAuthToken =>
      'Impossible d\'ouvrir les paramètres : jeton d\'authentification manquant.';

  @override
  String adminPluginLoadFailed(String error) {
    return 'Impossible de charger le plugin : $error';
  }

  @override
  String get adminPluginNotFound => 'Plugin introuvable';

  @override
  String adminPluginVersion(String version) {
    return 'Version $version';
  }

  @override
  String get adminEnablePlugin => 'Activer le plugin';

  @override
  String get adminPluginSettingsPage => 'Page des paramètres du plugin';

  @override
  String get adminRevisionHistory => 'Historique des révisions';

  @override
  String get adminNoChangelog => 'Aucun journal des modifications disponible.';

  @override
  String get adminRemoveRepository => 'Supprimer le dépôt';

  @override
  String adminRemoveRepositoryConfirm(String name) {
    return 'Voulez-vous vraiment supprimer « $name » ?';
  }

  @override
  String adminRepositoriesSaveFailed(String error) {
    return 'Impossible d\'enregistrer les dépôts : $error';
  }

  @override
  String adminRepositoriesLoadFailed(String error) {
    return 'Impossible de charger les dépôts : $error';
  }

  @override
  String get adminRepositoryNameHint => 'ex. Jellyfin Stable';

  @override
  String get adminRepositoryUrl => 'URL du dépôt';

  @override
  String get adminAddEntry => 'Ajouter une entrée';

  @override
  String get adminInvalidUrl => 'URL invalide';

  @override
  String adminPluginSettingsLoadFailed(String error) {
    return 'Impossible de charger les paramètres du plugin : $error';
  }

  @override
  String adminCouldNotOpenUrl(String uri) {
    return 'Impossible d\'ouvrir $uri';
  }

  @override
  String get adminOpenInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get adminOpenExternally => 'Ouvrir en externe';

  @override
  String get adminGeneralSettings => 'Paramètres généraux';

  @override
  String get adminServerName => 'Nom du serveur';

  @override
  String get adminPreferredMetadataCountry =>
      'Pays préféré pour les métadonnées';

  @override
  String get adminCachePath => 'Chemin du cache';

  @override
  String get adminMetadataPath => 'Chemin des métadonnées';

  @override
  String get adminLibraryScanConcurrency =>
      'Parallélisme d\'analyse de la médiathèque';

  @override
  String get adminParallelImageEncodingLimit =>
      'Limite d\'encodage d\'images en parallèle';

  @override
  String get adminSlowResponseThreshold => 'Seuil de réponse lente (ms)';

  @override
  String get adminBrandingSaved => 'Paramètres de marque enregistrés';

  @override
  String get adminBrandingLoadFailed =>
      'Impossible de charger les paramètres de marque';

  @override
  String get adminLoginDisclaimer => 'Avertissement de connexion';

  @override
  String get adminLoginDisclaimerHint =>
      'HTML affiché sous le formulaire de connexion';

  @override
  String get adminCustomCss => 'CSS personnalisé';

  @override
  String get adminCustomCssHint =>
      'CSS personnalisé appliqué à l\'interface web';

  @override
  String get adminEnableSplashScreen => 'Activer l\'écran de démarrage';

  @override
  String get adminStreamingSaved => 'Paramètres de streaming enregistrés';

  @override
  String get adminStreamingLoadFailed =>
      'Impossible de charger les paramètres de streaming';

  @override
  String get adminStreamingDescription =>
      'Définissez les limites globales de débit du streaming pour les connexions distantes.';

  @override
  String get adminRemoteBitrateLimitMbps =>
      'Limite de débit du client distant (Mbit/s)';

  @override
  String get adminLeaveEmptyForUnlimited => 'Laissez vide ou 0 pour illimité';

  @override
  String get adminPlaybackSaved => 'Paramètres de lecture enregistrés';

  @override
  String get adminPlaybackLoadFailed =>
      'Impossible de charger les paramètres de lecture';

  @override
  String get adminPlaybackTranscoding => 'Lecture / Transcodage';

  @override
  String get adminHardwareAcceleration => 'Accélération matérielle';

  @override
  String get adminVaapiDevice => 'Périphérique VA-API';

  @override
  String get adminEnableHardwareEncoding => 'Activer l\'encodage matériel';

  @override
  String get adminEnableHardwareDecoding =>
      'Activer le décodage matériel pour :';

  @override
  String get adminEncodingThreads => 'Threads d\'encodage';

  @override
  String get adminAutomatic => '0 = automatique';

  @override
  String get adminTranscodingTempPath => 'Chemin temporaire du transcodage';

  @override
  String get adminEnableFallbackFont => 'Activer la police de secours';

  @override
  String get adminFallbackFontPath => 'Chemin de la police de secours';

  @override
  String get adminAllowSegmentDeletion =>
      'Autoriser la suppression des segments';

  @override
  String get adminSegmentKeepSeconds => 'Conservation des segments (secondes)';

  @override
  String get adminThrottleBuffering => 'Limiter la mise en mémoire tampon';

  @override
  String get adminTrickplaySaved => 'Paramètres de trickplay enregistrés';

  @override
  String get adminTrickplayLoadFailed =>
      'Impossible de charger les paramètres de trickplay';

  @override
  String get adminEnableHardwareAcceleration =>
      'Activer l\'accélération matérielle';

  @override
  String get adminEnableKeyFrameExtraction =>
      'Activer l\'extraction des images clés uniquement';

  @override
  String get adminKeyFrameSubtitle => 'Plus rapide mais moins précis';

  @override
  String get adminScanBehavior => 'Comportement de l\'analyse';

  @override
  String get adminProcessPriority => 'Priorité du processus';

  @override
  String get adminImageSettings => 'Paramètres des images';

  @override
  String get adminIntervalMs => 'Intervalle (ms)';

  @override
  String get adminCaptureFrameSubtitle => 'Fréquence de capture des images';

  @override
  String get adminWidthResolutions => 'Résolutions en largeur';

  @override
  String get adminTileWidth => 'Largeur des tuiles';

  @override
  String get adminTileHeight => 'Hauteur des tuiles';

  @override
  String get adminQualitySubtitle =>
      'Valeurs plus faibles = meilleure qualité, fichiers plus volumineux';

  @override
  String get adminProcessThreads => 'Threads du processus';

  @override
  String get adminResumeSaved => 'Paramètres de reprise enregistrés';

  @override
  String get adminResumeLoadFailed =>
      'Impossible de charger les paramètres de reprise';

  @override
  String get adminResumeDescription =>
      'Définissez à quel moment le contenu doit être marqué comme partiellement ou entièrement lu.';

  @override
  String get adminMinResumePercentage => 'Pourcentage minimal de reprise';

  @override
  String get adminMinResumeSubtitle =>
      'Le contenu doit dépasser ce pourcentage pour enregistrer la progression';

  @override
  String get adminMaxResumePercentage => 'Pourcentage maximal de reprise';

  @override
  String get adminMaxResumeSubtitle =>
      'Le contenu est considéré comme entièrement lu après ce pourcentage';

  @override
  String get adminMinResumeDuration => 'Durée minimale de reprise (secondes)';

  @override
  String get adminMinResumeDurationSubtitle =>
      'Les éléments plus courts ne peuvent pas être repris';

  @override
  String get adminMinAudiobookResume =>
      'Pourcentage minimal de reprise des livres audio';

  @override
  String get adminMaxAudiobookResume =>
      'Pourcentage maximal de reprise des livres audio';

  @override
  String get adminNetworkingSaved =>
      'Paramètres réseau enregistrés. Un redémarrage du serveur peut être nécessaire.';

  @override
  String get adminNetworkingLoadFailed =>
      'Impossible de charger les paramètres réseau';

  @override
  String get adminNetworkingWarning =>
      'Les modifications des paramètres réseau peuvent nécessiter un redémarrage du serveur.';

  @override
  String get adminEnableRemoteAccess => 'Activer l\'accès à distance';

  @override
  String get ports => 'Ports';

  @override
  String get adminHttpPort => 'Port HTTP';

  @override
  String get adminHttpsPort => 'Port HTTPS';

  @override
  String get adminPublicHttpsPort => 'Port HTTPS public';

  @override
  String get adminBaseUrl => 'URL de base';

  @override
  String get adminBaseUrlHint => 'ex. /jellyfin';

  @override
  String get https => 'HTTPS';

  @override
  String get adminEnableHttps => 'Activer HTTPS';

  @override
  String get adminLocalNetwork => 'Réseau local';

  @override
  String get adminLocalNetworkAddresses => 'Adresses du réseau local';

  @override
  String get adminKnownProxies => 'Proxys connus';

  @override
  String get adminRemoteIpFilter => 'Filtre d\'IP distantes';

  @override
  String get adminRemoteIpFilterEntries => 'Filtre d\'IP distantes';

  @override
  String get adminCertificatePath => 'Chemin du certificat';

  @override
  String get whitelist => 'Liste blanche';

  @override
  String get blacklist => 'Liste noire';

  @override
  String get notSet => 'Non défini';

  @override
  String get adminMetadataSaved => 'Métadonnées enregistrées';

  @override
  String adminMetadataLoadFailed(String error) {
    return 'Impossible de charger les métadonnées : $error';
  }

  @override
  String adminMetadataSaveFailed(String error) {
    return 'Impossible d\'enregistrer les métadonnées : $error';
  }

  @override
  String get adminRefreshMetadata => 'Actualiser les métadonnées';

  @override
  String get recursive => 'Récursif';

  @override
  String get adminReplaceAllMetadata => 'Remplacer toutes les métadonnées';

  @override
  String get adminReplaceAllImages => 'Remplacer toutes les images';

  @override
  String get adminMetadataRefreshRequested =>
      'Actualisation des métadonnées demandée';

  @override
  String adminMetadataRefreshFailed(String error) {
    return 'Impossible d\'actualiser les métadonnées : $error';
  }

  @override
  String get adminSearchRemotePerson => 'Rechercher une personne distante';

  @override
  String get adminNoRemoteMatches => 'Aucun résultat distant trouvé';

  @override
  String get adminRemoteResults => 'Résultats distants';

  @override
  String get adminRemoteMetadataApplied => 'Métadonnées distantes appliquées';

  @override
  String adminRemoteSearchFailed(String error) {
    return 'Échec de la recherche distante : $error';
  }

  @override
  String get adminUpdateContentType => 'Mettre à jour le type de contenu';

  @override
  String get adminContentType => 'Type de contenu';

  @override
  String get adminContentTypeUpdated => 'Type de contenu mis à jour';

  @override
  String adminContentTypeUpdateFailed(String error) {
    return 'Impossible de mettre à jour le type de contenu : $error';
  }

  @override
  String get adminMetadataEditorLoadFailed =>
      'Impossible de charger l\'éditeur de métadonnées';

  @override
  String get adminNoPeopleEntries => 'Aucune entrée de personne';

  @override
  String get adminNoExternalIds => 'Aucun ID externe disponible';

  @override
  String adminImageUpdated(String imageType) {
    return 'Image $imageType mise à jour';
  }

  @override
  String adminImageDownloadFailed(String error) {
    return 'Impossible de télécharger l\'image : $error';
  }

  @override
  String get adminUnsupportedImageFormat =>
      'Format d\'image non pris en charge';

  @override
  String get adminImageReadFailed => 'Impossible de lire l\'image sélectionnée';

  @override
  String adminImageUploaded(String imageType) {
    return 'Image $imageType envoyée';
  }

  @override
  String adminImageUploadFailed(String error) {
    return 'Impossible d\'envoyer l\'image : $error';
  }

  @override
  String adminDeleteImage(String imageType) {
    return 'Supprimer l\'image $imageType';
  }

  @override
  String adminImageDeleted(String imageType) {
    return 'Image $imageType supprimée';
  }

  @override
  String adminImageDeleteFailed(String error) {
    return 'Impossible de supprimer l\'image : $error';
  }

  @override
  String get adminAllProviders => 'Tous les fournisseurs';

  @override
  String get adminNoRemoteImages => 'Aucune image distante trouvée';

  @override
  String adminTunerDiscoveryFailed(String error) {
    return 'Échec de la découverte des tuners : $error';
  }

  @override
  String get adminAddTuner => 'Ajouter un tuner';

  @override
  String get adminTunerType => 'Type de tuner';

  @override
  String get adminTunerTypeHint => 'HDHomeRun, M3U, autre';

  @override
  String get adminUrlPath => 'URL / Chemin';

  @override
  String get adminNameOptional => 'Nom (facultatif)';

  @override
  String get adminTunerAdded => 'Tuner ajouté';

  @override
  String adminTunerAddFailed(String error) {
    return 'Impossible d\'ajouter le tuner : $error';
  }

  @override
  String get adminAddGuideProvider => 'Ajouter un fournisseur de guide';

  @override
  String get adminProviderType => 'Type de fournisseur';

  @override
  String get adminProviderTypeHint => 'SchedulesDirect ou XMLTV';

  @override
  String get adminUsernameOptional => 'Nom d\'utilisateur (facultatif)';

  @override
  String get adminRefreshInterval => 'Intervalle d\'actualisation (heures)';

  @override
  String get adminProviderAdded => 'Fournisseur ajouté';

  @override
  String adminProviderAddFailed(String error) {
    return 'Impossible d\'ajouter le fournisseur : $error';
  }

  @override
  String adminTunerRemoveFailed(String error) {
    return 'Impossible de supprimer le tuner : $error';
  }

  @override
  String get adminTunerResetRequested => 'Réinitialisation du tuner demandée';

  @override
  String adminTunerResetFailed(String error) {
    return 'Impossible de réinitialiser le tuner : $error';
  }

  @override
  String adminProviderRemoveFailed(String error) {
    return 'Impossible de supprimer le fournisseur : $error';
  }

  @override
  String get adminRecordingSettings => 'Paramètres d\'enregistrement';

  @override
  String get adminPrePadding => 'Marge avant (minutes)';

  @override
  String get adminPostPadding => 'Marge après (minutes)';

  @override
  String get adminRecordingPath => 'Chemin d\'enregistrement';

  @override
  String get adminSeriesRecordingPath => 'Chemin d\'enregistrement des séries';

  @override
  String get adminRecordingSettingsSaved =>
      'Paramètres d\'enregistrement enregistrés';

  @override
  String adminSettingsSaveFailed(String error) {
    return 'Impossible d\'enregistrer les paramètres : $error';
  }

  @override
  String get adminSetChannelMappings =>
      'Définir les correspondances des chaînes';

  @override
  String get adminMappingJson => 'JSON de correspondance';

  @override
  String get adminChannelMappingsUpdated =>
      'Correspondances des chaînes mises à jour';

  @override
  String adminMappingsUpdateFailed(String error) {
    return 'Impossible de mettre à jour les correspondances : $error';
  }

  @override
  String get adminLiveTvLoadFailed =>
      'Impossible de charger l\'administration de la TV en direct';

  @override
  String get adminTunerDevices => 'Périphériques tuner';

  @override
  String get adminNoTunerHosts => 'Aucun hôte tuner configuré';

  @override
  String get adminGuideProviders => 'Fournisseurs de guide';

  @override
  String get adminAddProvider => 'Ajouter un fournisseur';

  @override
  String get adminNoListingProviders => 'Aucun fournisseur de guide configuré';

  @override
  String adminRecordingPathDisplay(String path) {
    return 'Chemin d\'enregistrement : $path';
  }

  @override
  String adminSeriesPathDisplay(String path) {
    return 'Chemin des séries : $path';
  }

  @override
  String adminPrePaddingDisplay(int minutes) {
    return 'Marge avant : $minutes min';
  }

  @override
  String adminPostPaddingDisplay(int minutes) {
    return 'Marge après : $minutes min';
  }

  @override
  String get adminTunerDiscovery => 'Détection des tuners';

  @override
  String get adminChannelMappings => 'Mappage des chaînes';

  @override
  String get adminNoDiscoveredTuners => 'Aucun tuner détecté pour l’instant';

  @override
  String get adminSettingsSaved => 'Paramètres enregistrés';

  @override
  String get adminBackupsNotAvailable =>
      'Les sauvegardes ne sont pas disponibles sur cette version du serveur.';

  @override
  String get adminRestoreWarning1 =>
      'La restauration remplacera TOUTES les données actuelles du serveur par celles de la sauvegarde.';

  @override
  String get adminRestoreWarning2 =>
      'Les paramètres, utilisateurs et données de bibliothèque actuels du serveur seront écrasés.';

  @override
  String get adminRestoreWarning3 =>
      'Le serveur redémarrera après la restauration.';

  @override
  String adminRestoreConfirmMessage(String name) {
    return 'Restaurer la sauvegarde $name maintenant ?';
  }

  @override
  String get adminRestoreRequested =>
      'Restauration demandée. Le redémarrage du serveur peut déconnecter cette session.';

  @override
  String get adminBackupsTitle => 'Sauvegardes';

  @override
  String get adminUnknownDate => 'Date inconnue';

  @override
  String get adminUnnamedBackup => 'Sauvegarde sans nom';

  @override
  String get adminLiveTvNotAvailable =>
      'L’administration de la TV en direct n’est pas disponible sur cette version du serveur.';

  @override
  String get adminLiveTvTitle => 'Administration de la TV en direct';

  @override
  String get adminApply => 'Appliquer';

  @override
  String get adminNotSet => 'Non défini';

  @override
  String get adminReset => 'Réinitialiser';

  @override
  String get adminLogsTitle => 'Journaux du serveur';

  @override
  String get adminLogsNewestFirst => 'Plus récents d’abord';

  @override
  String get adminLogsOldestFirst => 'Plus anciens d’abord';

  @override
  String get adminLogsJustNow => 'À l’instant';

  @override
  String adminLogsMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String adminLogsHoursAgo(int hours) {
    return 'il y a $hours h';
  }

  @override
  String adminLogsDaysAgo(int days) {
    return 'il y a $days j';
  }

  @override
  String adminLogViewerLoadFailed(String fileName) {
    return 'Impossible de charger $fileName';
  }

  @override
  String adminLogViewerMatches(int count) {
    return '$count correspondances';
  }

  @override
  String get adminLogViewerNoMatches => 'Aucune ligne correspondante';

  @override
  String get adminMetadataEditorTitle => 'Éditeur de métadonnées';

  @override
  String get adminMetadataRemote => 'Distant';

  @override
  String get adminMetadataType => 'Type';

  @override
  String get adminMetadataDetails => 'Détails';

  @override
  String get adminMetadataExternalIds => 'ID externes';

  @override
  String get adminMetadataImages => 'Images';

  @override
  String get adminMetadataFieldTitle => 'Titre';

  @override
  String get adminMetadataFieldSortTitle => 'Titre de tri';

  @override
  String get adminMetadataFieldOriginalTitle => 'Titre original';

  @override
  String get adminMetadataFieldPremiereDate => 'Date de première (YYYY-MM-DD)';

  @override
  String get adminMetadataFieldEndDate => 'Date de fin (YYYY-MM-DD)';

  @override
  String get adminMetadataFieldProductionYear => 'Année de production';

  @override
  String get adminMetadataFieldOfficialRating => 'Classification officielle';

  @override
  String get adminMetadataFieldCommunityRating => 'Note de la communauté';

  @override
  String get adminMetadataFieldCriticRating => 'Note des critiques';

  @override
  String get adminMetadataFieldTagline => 'Slogan';

  @override
  String get adminMetadataFieldOverview => 'Synopsis';

  @override
  String get adminMetadataGenres => 'Genres';

  @override
  String get adminMetadataTags => 'Tags';

  @override
  String get adminMetadataStudios => 'Studios';

  @override
  String get adminMetadataPeople => 'Personnes';

  @override
  String get adminMetadataAddGenre => 'Ajouter un genre';

  @override
  String get adminMetadataAddTag => 'Ajouter un tag';

  @override
  String get adminMetadataAddStudio => 'Ajouter un studio';

  @override
  String get adminMetadataAddPerson => 'Ajouter une personne';

  @override
  String get adminMetadataEditPerson => 'Modifier la personne';

  @override
  String get adminMetadataRole => 'Rôle';

  @override
  String get adminMetadataImagePrimary => 'Principale';

  @override
  String get adminMetadataImageBackdrop => 'Arrière-plan';

  @override
  String get adminMetadataImageLogo => 'Logo';

  @override
  String get adminMetadataImageBanner => 'Bannière';

  @override
  String get adminMetadataImageThumb => 'Vignette';

  @override
  String get adminMetadataRecursive => 'Récursif';

  @override
  String get adminMetadataProvider => 'Fournisseur';

  @override
  String adminMetadataImageUpdated(String imageType) {
    return 'Image $imageType mise à jour';
  }

  @override
  String adminMetadataImageUploaded(String imageType) {
    return 'Image $imageType téléversée';
  }

  @override
  String adminMetadataImageDeleted(String imageType) {
    return 'Image $imageType supprimée';
  }

  @override
  String adminMetadataImageDownloadFailed(String error) {
    return 'Impossible de télécharger l’image : $error';
  }

  @override
  String get adminMetadataImageReadFailed =>
      'Impossible de lire l’image sélectionnée';

  @override
  String adminMetadataImageUploadFailed(String error) {
    return 'Impossible de téléverser l’image : $error';
  }

  @override
  String adminMetadataDeleteImageTitle(String imageType) {
    return 'Supprimer l’image $imageType';
  }

  @override
  String get adminMetadataDeleteImageContent =>
      'Ceci supprime l’image actuelle de l’élément.';

  @override
  String adminMetadataImageDeleteFailed(String error) {
    return 'Impossible de supprimer l’image : $error';
  }

  @override
  String adminMetadataChooseImage(String imageType) {
    return 'Choisir l’image $imageType';
  }

  @override
  String get adminMetadataUpload => 'Téléverser';

  @override
  String get adminMetadataUpdate => 'Mettre à jour';

  @override
  String get adminMetadataRemoteImage => 'Image distante';

  @override
  String get adminPluginsInstalled => 'Installés';

  @override
  String get adminPluginsCatalog => 'Catalogue';

  @override
  String get adminPluginsActive => 'Actifs';

  @override
  String get adminPluginsRestart => 'Redémarrer';

  @override
  String get adminPluginsNoSearchResults =>
      'Aucun plugin ne correspond à votre recherche';

  @override
  String get adminPluginsNoneInstalled => 'Aucun plugin installé';

  @override
  String adminPluginsUpdateAvailable(String version) {
    return 'Mise à jour disponible : v$version';
  }

  @override
  String get adminPluginsUpdateAvailableGeneric => 'Mise à jour disponible';

  @override
  String get adminPluginsPendingRemoval =>
      'Suppression en attente après redémarrage';

  @override
  String get adminPluginsChangesPending =>
      'Modifications en attente de redémarrage';

  @override
  String get adminPluginsEnable => 'Activer';

  @override
  String get adminPluginsDisable => 'Désactiver';

  @override
  String get adminPluginsInstallUpdate => 'Installer la mise à jour';

  @override
  String adminPluginsInstallUpdateVersioned(String version) {
    return 'Installer la mise à jour (v$version)';
  }

  @override
  String get adminPluginsCatalogNoSearchResults =>
      'Aucun paquet ne correspond à votre recherche';

  @override
  String get adminPluginsCatalogEmpty => 'Aucun paquet disponible';

  @override
  String adminPluginsInstalling(String name) {
    return '« $name » est en cours d’installation...';
  }

  @override
  String get adminPluginDetailExperimental => 'Intégration expérimentale';

  @override
  String get adminPluginDetailExperimentalContent =>
      'L’intégration des paramètres des plugins est encore expérimentale. Certains champs ou mises en page peuvent ne pas encore s’afficher correctement.';

  @override
  String get adminPluginDetailToggle404 =>
      'Impossible d’activer ou désactiver le plugin. Le serveur n’a pas trouvé cette version du plugin. Actualisez les plugins, puis réessayez.';

  @override
  String get adminPluginDetailToggleDioError =>
      'Impossible d’activer ou désactiver le plugin. Consultez les journaux du serveur pour plus de détails.';

  @override
  String adminPluginDetailSettingsTitle(String name) {
    return 'Paramètres de $name';
  }

  @override
  String get adminPluginDetailDetails => 'Détails';

  @override
  String get adminPluginDetailDeveloper => 'Développeur';

  @override
  String get adminPluginDetailRepository => 'Dépôt';

  @override
  String get adminPluginDetailBundled => 'Inclus';

  @override
  String get adminPluginDetailEnablePlugin => 'Activer le plugin';

  @override
  String get adminPluginDetailRestartRequired =>
      'Un redémarrage du serveur est nécessaire pour appliquer les modifications.';

  @override
  String get adminPluginDetailRemovalPending =>
      'Ce plugin sera supprimé après le redémarrage du serveur.';

  @override
  String get adminPluginDetailMalfunctioned =>
      'Ce plugin présente un dysfonctionnement et peut ne pas fonctionner correctement.';

  @override
  String get adminPluginDetailNotSupported =>
      'Ce plugin n’est pas pris en charge par la version actuelle du serveur.';

  @override
  String get adminPluginDetailSuperseded =>
      'Ce plugin a été remplacé par une version plus récente.';

  @override
  String adminReposLoadFailed(String error) {
    return 'Impossible de charger les dépôts : $error';
  }

  @override
  String get adminReposRemoveTitle => 'Supprimer le dépôt';

  @override
  String adminReposRemoveConfirm(String name) {
    return 'Voulez-vous vraiment supprimer « $name » ?';
  }

  @override
  String get adminReposRemove => 'Supprimer';

  @override
  String adminReposSaveFailed(String error) {
    return 'Impossible d’enregistrer les dépôts : $error';
  }

  @override
  String get adminReposEmpty => 'Aucun dépôt configuré';

  @override
  String get adminReposEmptySubtitle =>
      'Ajoutez un dépôt pour parcourir les plugins disponibles';

  @override
  String get adminReposUnnamed => '(sans nom)';

  @override
  String get adminReposEditTitle => 'Modifier le dépôt';

  @override
  String get adminReposAddTitle => 'Ajouter un dépôt';

  @override
  String get adminReposUrl => 'URL du dépôt';

  @override
  String get adminReposNameHint => 'ex. Jellyfin Stable';

  @override
  String get adminPluginSettingsInvalidUrl => 'URL invalide';

  @override
  String get adminGeneralSettingsTitle => 'Paramètres généraux';

  @override
  String get adminGeneralMetadataLanguage => 'Langue de métadonnées préférée';

  @override
  String get adminGeneralMetadataLanguageHint => 'ex. en, de, fr';

  @override
  String get adminGeneralMetadataCountry => 'Pays de métadonnées préféré';

  @override
  String get adminGeneralMetadataCountryHint => 'ex. US, DE, FR';

  @override
  String get adminGeneralLibraryScanConcurrency =>
      'Parallélisme d’analyse de la bibliothèque';

  @override
  String get adminGeneralImageEncodingLimit =>
      'Limite d’encodage d’images en parallèle';

  @override
  String get adminUnknownError => 'Erreur inconnue';

  @override
  String get adminBrowse => 'Parcourir';

  @override
  String get adminCloseBrowser => 'Fermer le navigateur';

  @override
  String get adminNetworkingTitle => 'Réseau';

  @override
  String get adminNetworkingRestartWarning =>
      'Les modifications des paramètres réseau peuvent nécessiter un redémarrage du serveur.';

  @override
  String get adminNetworkingRemoteAccess => 'Activer l’accès à distance';

  @override
  String get adminNetworkingPorts => 'Ports';

  @override
  String get adminNetworkingHttpPort => 'Port HTTP';

  @override
  String get adminNetworkingHttpsPort => 'Port HTTPS';

  @override
  String get adminNetworkingEnableHttps => 'Activer HTTPS';

  @override
  String get adminNetworkingLocalNetwork => 'Réseau local';

  @override
  String get adminNetworkingLocalAddresses => 'Adresses du réseau local';

  @override
  String get adminNetworkingAddressHint => 'ex. 192.168.1.0/24';

  @override
  String get adminNetworkingKnownProxies => 'Proxys connus';

  @override
  String get adminNetworkingProxyHint => 'ex. 10.0.0.1';

  @override
  String get adminNetworkingWhitelist => 'Liste blanche';

  @override
  String get adminNetworkingBlacklist => 'Liste noire';

  @override
  String get adminNetworkingAddEntry => 'Ajouter une entrée';

  @override
  String get adminBrandingTitle => 'Personnalisation';

  @override
  String get adminBrandingLoginDisclaimer => 'Avertissement de connexion';

  @override
  String get adminBrandingLoginDisclaimerHint =>
      'HTML affiché sous le formulaire de connexion';

  @override
  String get adminBrandingCustomCss => 'CSS personnalisé';

  @override
  String get adminBrandingCustomCssHint =>
      'CSS personnalisé appliqué à l’interface web';

  @override
  String get adminBrandingEnableSplash => 'Activer l’écran de démarrage';

  @override
  String get adminPlaybackHwAccel => 'Accélération matérielle';

  @override
  String get adminPlaybackHwAccelLabel => 'Accélération matérielle';

  @override
  String get adminPlaybackEnableHwEncoding => 'Activer l’encodage matériel';

  @override
  String get adminPlaybackEnableHwDecoding =>
      'Activer le décodage matériel pour :';

  @override
  String get adminPlaybackEncoding => 'Encodage';

  @override
  String get adminPlaybackEncodingThreads => 'Threads d’encodage';

  @override
  String get adminPlaybackFallbackFont => 'Activer la police de secours';

  @override
  String get adminPlaybackFallbackFontPath => 'Chemin de la police de secours';

  @override
  String get adminPlaybackStreaming => 'Streaming';

  @override
  String get adminResumeVideo => 'Vidéo';

  @override
  String get adminResumeAudiobooks => 'Livres audio';

  @override
  String get adminResumeMinAudiobookPct =>
      'Pourcentage minimal de reprise des livres audio';

  @override
  String get adminResumeMaxAudiobookPct =>
      'Pourcentage maximal de reprise des livres audio';

  @override
  String get adminStreamingBitrateLimit =>
      'Limite de débit du client distant (Mbps)';

  @override
  String get adminStreamingBitrateLimitHint =>
      'Laisser vide ou 0 pour illimité';

  @override
  String get adminTrickplayHwAccel => 'Activer l’accélération matérielle';

  @override
  String get adminTrickplayHwEncoding => 'Activer l’encodage matériel';

  @override
  String get adminTrickplayKeyFrameOnly =>
      'Activer l’extraction des images clés uniquement';

  @override
  String get adminTrickplayKeyFrameOnlySubtitle =>
      'Plus rapide mais moins précis';

  @override
  String get adminTrickplayNonBlocking => 'Non bloquant';

  @override
  String get adminTrickplayBlocking => 'Bloquant';

  @override
  String get adminTrickplayPriorityHigh => 'Haute';

  @override
  String get adminTrickplayPriorityAboveNormal => 'Supérieure à la normale';

  @override
  String get adminTrickplayPriorityNormal => 'Normale';

  @override
  String get adminTrickplayPriorityBelowNormal => 'Inférieure à la normale';

  @override
  String get adminTrickplayPriorityIdle => 'Inactive';

  @override
  String get adminTrickplayImageSettings => 'Paramètres d’image';

  @override
  String get adminTrickplayInterval => 'Intervalle (ms)';

  @override
  String get adminTrickplayIntervalSubtitle =>
      'Fréquence de capture des images';

  @override
  String get adminTrickplayWidthResolutionsHint =>
      'Largeurs en pixels séparées par des virgules (ex. 320)';

  @override
  String get adminTrickplayQuality => 'Qualité';

  @override
  String get adminTrickplayQScale => 'Échelle de qualité';

  @override
  String get adminTrickplayQScaleSubtitle =>
      'Valeurs plus faibles = meilleure qualité, fichiers plus volumineux';

  @override
  String get adminTrickplayJpegQuality => 'Qualité JPEG';

  @override
  String get adminTrickplayProcessing => 'Traitement';

  @override
  String get adminTasksEmpty => 'Aucune tâche planifiée trouvée';

  @override
  String get adminTasksNoFilterMatch =>
      'Aucune tâche ne correspond au filtre actuel';

  @override
  String get adminTaskCancelling => 'Annulation...';

  @override
  String get adminTaskRunning => 'En cours...';

  @override
  String get adminTaskNeverRun => 'Jamais exécutée';

  @override
  String get adminTaskStop => 'Arrêter';

  @override
  String get adminTaskRun => 'Exécuter';

  @override
  String get adminTaskDetailLastExecution => 'Dernière exécution';

  @override
  String get adminTaskDetailStarted => 'Début';

  @override
  String get adminTaskDetailEnded => 'Fin';

  @override
  String get adminTaskDetailDuration => 'Durée';

  @override
  String get adminTaskDetailErrorLabel => 'Erreur :';

  @override
  String adminTaskTriggerDaily(String time) {
    return 'Quotidien à $time';
  }

  @override
  String adminTaskTriggerWeekly(String day, String time) {
    return 'Chaque $day à $time';
  }

  @override
  String adminTaskTriggerInterval(String duration) {
    return 'Toutes les $duration';
  }

  @override
  String get adminTaskTriggerStartup => 'Au démarrage de l\'application';

  @override
  String get adminTaskTriggerTypeDaily => 'Quotidien';

  @override
  String get adminTaskTriggerTypeWeekly => 'Hebdomadaire';

  @override
  String get adminTaskTriggerTypeInterval => 'À intervalle régulier';

  @override
  String get adminTaskTriggerIntervalLabel => 'Intervalle';

  @override
  String get adminTaskTriggerEveryHour => 'Toutes les heures';

  @override
  String get adminTaskTriggerEvery6Hours => 'Toutes les 6 heures';

  @override
  String get adminTaskTriggerEvery12Hours => 'Toutes les 12 heures';

  @override
  String get adminTaskTriggerEvery24Hours => 'Toutes les 24 heures';

  @override
  String get adminTaskTriggerEvery2Days => 'Tous les 2 jours';

  @override
  String adminTaskTriggerHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
      zero: '0 heures',
    );
    return '$_temp0';
  }

  @override
  String get adminTaskTriggerTime => 'Heure';

  @override
  String get adminTaskTriggerNoLimit => 'Sans limite';

  @override
  String get adminActivityJustNow => 'À l\'instant';

  @override
  String get adminActivityLastHour => 'Dernière heure';

  @override
  String get adminActivityToday => 'Aujourd\'hui';

  @override
  String get adminActivityYesterday => 'Hier';

  @override
  String get adminActivityOlder => 'Plus ancien';

  @override
  String adminActivityDaysAgo(int days) {
    return 'Il y a $days j';
  }

  @override
  String adminActivityHoursAgo(int hours) {
    return 'Il y a $hours h';
  }

  @override
  String adminActivityMinutesAgo(int minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String get adminActivityNow => 'maintenant';

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
    return '$days j';
  }

  @override
  String adminActivityDateShort(int month, int day) {
    return '$month/$day';
  }

  @override
  String get adminTrickplayDescription =>
      'Configurez la génération d\'images trickplay pour les miniatures d\'aperçu lors de la recherche.';

  @override
  String get adminNetworkingPublicHttpsPort => 'Port HTTPS public';

  @override
  String get adminNetworkingBaseUrl => 'URL de base';

  @override
  String get adminNetworkingBaseUrlHint => 'ex. /jellyfin';

  @override
  String get adminNetworkingHttps => 'HTTPS';

  @override
  String get adminNetworkingCertPath => 'Chemin du certificat';

  @override
  String get adminNetworkingRemoteIpFilter => 'Filtre IP distant';

  @override
  String get adminNetworkingRemoteIpFilterLabel => 'Filtre IP distant';

  @override
  String get adminPlaybackVaapiDevice => 'Périphérique VA-API';

  @override
  String get adminPlaybackAutomatic => '0 = automatique';

  @override
  String get adminPlaybackTranscodeTempPath =>
      'Chemin temporaire de transcodage';

  @override
  String get adminPlaybackSegmentDeletion =>
      'Autoriser la suppression des segments';

  @override
  String get adminPlaybackSegmentKeep => 'Conservation des segments (secondes)';

  @override
  String get adminPlaybackThrottleBuffering =>
      'Limiter la mise en mémoire tampon';

  @override
  String get adminResumeMinPct => 'Pourcentage minimum de reprise';

  @override
  String get adminResumeMinPctSubtitle =>
      'Le contenu doit être lu au-delà de ce pourcentage pour enregistrer la progression';

  @override
  String get adminResumeMaxPct => 'Pourcentage maximum de reprise';

  @override
  String get adminResumeMaxPctSubtitle =>
      'Le contenu est considéré comme entièrement lu après ce pourcentage';

  @override
  String get adminResumeMinDuration => 'Durée minimale de reprise (secondes)';

  @override
  String get adminResumeMinDurationSubtitle =>
      'Les éléments plus courts ne peuvent pas être repris';

  @override
  String get adminTrickplayScanBehavior => 'Comportement d\'analyse';

  @override
  String get adminTrickplayProcessPriority => 'Priorité du processus';

  @override
  String get adminTrickplayTileWidth => 'Largeur des tuiles';

  @override
  String get adminTrickplayTileHeight => 'Hauteur des tuiles';

  @override
  String get adminTrickplayProcessThreads => 'Threads du processus';

  @override
  String get adminTrickplayWidthResolutions => 'Résolutions en largeur';

  @override
  String get adminMetadataDefault => 'Par défaut';

  @override
  String get adminMetadataContentTypeUpdated => 'Type de contenu mis à jour';

  @override
  String adminMetadataContentTypeFailed(String error) {
    return 'Échec de la mise à jour du type de contenu : $error';
  }

  @override
  String get adminGeneralSlowResponseThreshold => 'Seuil de réponse lente (ms)';

  @override
  String get adminGeneralCachePath => 'Chemin du cache';

  @override
  String get adminGeneralMetadataPath => 'Chemin des métadonnées';

  @override
  String get adminGeneralServerName => 'Nom du serveur';

  @override
  String get adminSettingsLoadFailed => 'Échec du chargement des paramètres';

  @override
  String get adminDiscover => 'Découvrir';

  @override
  String adminChannelMappingsUpdateFailed(String error) {
    return 'Échec de la mise à jour des mappages : $error';
  }

  @override
  String adminTimeLimitDuration(String duration) {
    return 'Limite de temps : $duration';
  }

  @override
  String get folders => 'Dossiers';

  @override
  String get libraries => 'Bibliothèques';

  @override
  String get syncPlay => 'SyncPlay';

  @override
  String get jellyseerr => 'Jellyseerr';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get noItems => 'Aucun élément';

  @override
  String get switchUser => 'Changer d\'utilisateur';

  @override
  String get remoteControl => 'Télécommande';

  @override
  String get mediaBarLoading => 'Chargement de la barre multimédia...';

  @override
  String get mediaBarError => 'Échec du chargement de la barre multimédia';

  @override
  String get offlineServerUnavailable =>
      'Connecté à Internet, mais le serveur actuel est indisponible.';

  @override
  String get offlineNoInternet =>
      'Vous êtes hors ligne. Seul le contenu téléchargé est disponible.';

  @override
  String get offlineSwitchServer => 'Changer de serveur';

  @override
  String get offlineSavedMedia => 'Médias enregistrés';

  @override
  String get castGoogleCast => 'Google Cast';

  @override
  String get castAirPlay => 'AirPlay';

  @override
  String get castDlna => 'DLNA';

  @override
  String get castRemotePlayback => 'Lecture à distance';

  @override
  String castControlFailed(String error) {
    return 'Échec du contrôle Cast : $error';
  }

  @override
  String castKindControls(String kind) {
    return 'Commandes $kind';
  }

  @override
  String get castDeviceVolume => 'Volume de l\'appareil';

  @override
  String get castVolumeUnavailable => 'Indisponible';

  @override
  String castStopKind(String kind) {
    return 'Arrêter $kind';
  }

  @override
  String get audioLabel => 'Audio';

  @override
  String get subtitlesLabel => 'Sous-titres';

  @override
  String get pinConfirmTitle => 'Confirmer le PIN';

  @override
  String get pinSetTitle => 'Définir un PIN';

  @override
  String get pinEnterTitle => 'Saisir le PIN';

  @override
  String get pinReenterToConfirm =>
      'Saisissez à nouveau votre PIN pour confirmer';

  @override
  String pinEnterNDigit(int length) {
    return 'Saisissez un PIN à $length chiffres';
  }

  @override
  String pinEnterYourNDigit(int length) {
    return 'Saisissez votre PIN à $length chiffres';
  }

  @override
  String get pinIncorrect => 'PIN incorrect';

  @override
  String get pinMismatch => 'Les PIN ne correspondent pas';

  @override
  String get pinForgot => 'PIN oublié ?';

  @override
  String get pinClear => 'Effacer';

  @override
  String get pinBackspace => 'Retour arrière';

  @override
  String get quickConnectAuthorized => 'Demande de connexion rapide autorisée.';

  @override
  String get quickConnectInvalidOrExpired =>
      'Le code de connexion rapide est invalide ou expiré.';

  @override
  String get quickConnectNotSupported =>
      'La connexion rapide n\'est pas prise en charge sur ce serveur.';

  @override
  String get quickConnectAuthorizeFailed =>
      'Échec de l\'autorisation du code de connexion rapide.';

  @override
  String get quickConnectDisabled =>
      'La connexion rapide est désactivée sur ce serveur.';

  @override
  String get quickConnectForbidden =>
      'Votre compte ne peut pas autoriser cette demande de connexion rapide.';

  @override
  String get quickConnectNotFound =>
      'Code de connexion rapide introuvable. Essayez un nouveau code.';

  @override
  String quickConnectFailedWithMessage(String message) {
    return 'Échec de la connexion rapide : $message';
  }

  @override
  String get quickConnectEnterCode => 'Saisir le code';

  @override
  String get quickConnectAuthorize => 'Autoriser';

  @override
  String remoteCommandFailed(String error) {
    return 'Échec de la commande : $error';
  }

  @override
  String get remoteControlTitle => 'Télécommande';

  @override
  String get remoteFailedToLoadSessions => 'Échec du chargement des sessions';

  @override
  String get remoteNoSessions => 'Aucune session contrôlable';

  @override
  String get remoteStartPlayback => 'Démarrer la lecture sur un autre appareil';

  @override
  String get unknownUser => 'Inconnu';

  @override
  String get unknownItem => 'Inconnu';

  @override
  String get remoteNothingPlaying =>
      'Rien n\'est en cours de lecture sur cette session';

  @override
  String get castingStarted =>
      'La diffusion a commencé sur l\'appareil sélectionné';

  @override
  String castingFailed(String error) {
    return 'Échec du démarrage de la diffusion : $error';
  }

  @override
  String get noRemoteDevices =>
      'Aucun appareil de lecture à distance disponible.';

  @override
  String get noRemoteDevicesIos =>
      'Aucun appareil de lecture à distance disponible.\n\nSur iOS, les cibles AirPlay peuvent être indisponibles dans le simulateur.';

  @override
  String get trackActionPlayNext => 'Lire ensuite';

  @override
  String get trackActionAddToQueue => 'Ajouter à la file d\'attente';

  @override
  String get trackActionAddToPlaylist => 'Ajouter à la playlist';

  @override
  String get trackActionCancelDownload => 'Annuler le téléchargement';

  @override
  String get trackActionDeleteFromPlaylist => 'Supprimer de la playlist';

  @override
  String get trackActionMoveUp => 'Déplacer vers le haut';

  @override
  String get trackActionMoveDown => 'Déplacer vers le bas';

  @override
  String get trackActionRemoveFromFavorites => 'Retirer des favoris';

  @override
  String get trackActionAddToFavorites => 'Ajouter aux favoris';

  @override
  String get trackActionGoToAlbum => 'Aller à l\'album';

  @override
  String get trackActionGoToArtist => 'Aller à l\'artiste';

  @override
  String trackActionDownloading(String name) {
    return 'Téléchargement de $name...';
  }

  @override
  String get trackActionDeletedFile => 'Fichier téléchargé supprimé';

  @override
  String get trackActionDeleteFileFailed =>
      'Impossible de supprimer le fichier téléchargé';

  @override
  String get shuffleBy => 'Mélanger par';

  @override
  String get shuffleSelectLibrary => 'Sélectionner une bibliothèque';

  @override
  String get shuffleSelectGenre => 'Sélectionner un genre';

  @override
  String get shuffleLibrary => 'Bibliothèque';

  @override
  String get shuffleGenre => 'Genre';

  @override
  String get shuffleNoLibraries => 'Aucune bibliothèque compatible disponible.';

  @override
  String get shuffleNoGenres => 'Aucun genre trouvé pour ce mode aléatoire.';

  @override
  String get posterDisplayTitle => 'Affichage';

  @override
  String get posterImageType => 'Type d\'image';

  @override
  String get imageTypePoster => 'Poster';

  @override
  String get imageTypeThumbnail => 'Miniature';

  @override
  String get imageTypeBanner => 'Bannière';

  @override
  String get playlistAddFailed => 'Échec de l\'ajout à la playlist';

  @override
  String get playlistCreateFailed => 'Échec de la création de la playlist';

  @override
  String get playlistNew => 'Nouvelle playlist';

  @override
  String get playlistCreate => 'Créer';

  @override
  String get playlistCreateNew => 'Créer une nouvelle playlist';

  @override
  String get playlistNoneFound => 'Aucune playlist trouvée';

  @override
  String get addToPlaylist => 'Ajouter à la playlist';

  @override
  String get lyricsNotAvailable => 'Paroles non disponibles';

  @override
  String get upNext => 'À suivre';

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get stillWatchingContent =>
      'La lecture a été mise en pause. Regardez-vous toujours ?';

  @override
  String get stillWatchingStop => 'Arrêter';

  @override
  String get stillWatchingContinue => 'Continuer';

  @override
  String skipSegment(String segment) {
    return 'Passer $segment';
  }

  @override
  String get liveTv => 'TV en direct';

  @override
  String get continueWatchingAndNextUp => 'Reprendre la lecture et À suivre';

  @override
  String downloadingBatchProgress(int current, int total, String fileName) {
    return 'Téléchargement $current/$total — $fileName';
  }

  @override
  String downloadingFile(String fileName) {
    return 'Téléchargement de $fileName';
  }

  @override
  String get nextEpisode => 'Épisode suivant';

  @override
  String get moreFromThisSeason => 'Plus de cette saison';

  @override
  String get playerTooltipPlaybackSpeed => 'Vitesse de lecture';

  @override
  String get playerTooltipCastControls => 'Commandes Cast';

  @override
  String get playerTooltipPlaybackQuality => 'Qualité de lecture';

  @override
  String get playerTooltipEnterFullscreen => 'Passer en plein écran';

  @override
  String get playerTooltipExitFullscreen => 'Quitter le plein écran';

  @override
  String get playerTooltipPrevious => 'Précédent';

  @override
  String get playerTooltipSeekBack => 'Reculer';

  @override
  String get playerTooltipSeekForward => 'Avancer';
}
