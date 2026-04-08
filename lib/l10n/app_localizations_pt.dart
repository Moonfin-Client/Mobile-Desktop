// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Moonfin';

  @override
  String get signIn => 'Entrar';

  @override
  String connectingToServer(String serverName) {
    return 'Conectando a $serverName';
  }

  @override
  String get quickConnect => 'Conexão Rápida';

  @override
  String get password => 'Senha';

  @override
  String get username => 'Usuário';

  @override
  String get quickConnectInstruction =>
      'Insira este código no painel web do seu servidor:';

  @override
  String get waitingForAuthorization => 'Aguardando autorização...';

  @override
  String get back => 'Voltar';

  @override
  String get serverUnavailable => 'Servidor indisponível';

  @override
  String get loginFailed => 'Falha no login';

  @override
  String quickConnectUnavailable(String detail) {
    return 'QuickConnect indisponível: $detail';
  }

  @override
  String quickConnectUnavailableWithStatus(String status, String detail) {
    return 'QuickConnect indisponível ($status): $detail';
  }

  @override
  String get whosWatching => 'Quem está assistindo?';

  @override
  String get addUser => 'Adicionar Usuário';

  @override
  String get selectServer => 'Selecionar Servidor';

  @override
  String appVersionFooter(String version) {
    return 'Moonfin versão $version';
  }

  @override
  String get savedServers => 'Servidores Salvos';

  @override
  String get discoveredServers => 'Servidores Descobertos';

  @override
  String get noneFound => 'Nenhum encontrado';

  @override
  String get unableToConnectToServer => 'Não foi possível conectar ao servidor';

  @override
  String get addServer => 'Adicionar Servidor';

  @override
  String get embyConnect => 'Emby Connect';

  @override
  String get removeServer => 'Remover Servidor';

  @override
  String removeServerConfirmation(String serverName) {
    return 'Remover \"$serverName\" dos seus servidores?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Remover';

  @override
  String get connectToServer => 'Conectar ao Servidor';

  @override
  String get serverAddress => 'Endereço do Servidor';

  @override
  String get serverAddressHint => 'https://seu-servidor.exemplo.com';

  @override
  String get connect => 'Conectar';

  @override
  String get secureStorageUnavailable => 'Armazenamento Seguro Indisponível';

  @override
  String get secureStorageUnavailableMessage =>
      'O Moonfin não conseguiu acessar o chaveiro do sistema. O login pode continuar, mas o armazenamento seguro de tokens pode ficar indisponível até que o chaveiro seja desbloqueado.';

  @override
  String get ok => 'OK';

  @override
  String get embyConnectSignInSubtitle => 'Entre com sua conta Emby Connect';

  @override
  String get emailOrUsername => 'E-mail ou Usuário';

  @override
  String get selectAServer => 'Selecione um Servidor';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get noLinkedServers =>
      'Nenhum servidor vinculado a esta conta Emby Connect';

  @override
  String get invalidEmbyConnectCredentials =>
      'Credenciais do Emby Connect inválidas';

  @override
  String get invalidEmbyConnectLogin =>
      'Usuário ou senha do Emby Connect inválidos';

  @override
  String get embyConnectExchangeNotSupported =>
      'O servidor não suporta troca via Emby Connect';

  @override
  String get embyConnectNetworkError =>
      'Erro de rede ao contatar o Emby Connect ou o servidor selecionado';

  @override
  String get loadingLinkedServers => 'Carregando servidores vinculados...';

  @override
  String get connectingToServerEllipsis => 'Conectando ao servidor...';

  @override
  String get noReachableAddress => 'Nenhum endereço acessível fornecido';

  @override
  String get invalidServerExchangeResponse =>
      'Resposta inválida do endpoint de troca do servidor';

  @override
  String unableToConnectTo(String target) {
    return 'Não foi possível conectar a $target';
  }

  @override
  String get exitApp => 'Sair do Moonfin?';

  @override
  String get exitAppConfirmation => 'Tem certeza que deseja sair?';

  @override
  String get exit => 'Sair';

  @override
  String get noHomeRowsLoaded =>
      'Nenhuma seção da tela inicial pôde ser carregada';

  @override
  String get noHomeRowsHint =>
      'Tente atualizar ou reduzir as seções ativas da tela inicial.';

  @override
  String get retryHomeRows => 'Tentar Novamente';

  @override
  String get guide => 'Guia';

  @override
  String get recordings => 'Gravações';

  @override
  String get schedule => 'Agenda';

  @override
  String get series => 'Séries';

  @override
  String get noItemsFound => 'Nenhum item encontrado';

  @override
  String get home => 'Início';

  @override
  String get browseAll => 'Ver Tudo';

  @override
  String get genres => 'Gêneros';

  @override
  String get collectionPlaceholder => 'Os itens da coleção aparecerão aqui';

  @override
  String get browseByLetter => 'Navegar por Letra';

  @override
  String get alphabeticalBrowsePlaceholder =>
      'A navegação alfabética aparecerá aqui';

  @override
  String get suggestions => 'Sugestões';

  @override
  String get suggestionsPlaceholder => 'Os itens sugeridos aparecerão aqui';

  @override
  String get failedToLoadLibraries => 'Falha ao carregar bibliotecas';

  @override
  String get noLibrariesFound => 'Nenhuma biblioteca encontrada';

  @override
  String get library => 'Biblioteca';

  @override
  String get displaySettings => 'Configurações de Exibição';

  @override
  String get allGenres => 'Todos os Gêneros';

  @override
  String get noGenresFound => 'Nenhum gênero encontrado';

  @override
  String failedToLoadFolderError(String error) {
    return 'Falha ao carregar pasta: $error';
  }

  @override
  String get thisFolderIsEmpty => 'Esta pasta está vazia';

  @override
  String itemCountLabel(int count) {
    return '$count itens';
  }

  @override
  String get failedToLoadFavorites => 'Falha ao carregar favoritos';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get noFavoritesYet => 'Nenhum favorito ainda';

  @override
  String get favorites => 'Favoritos';

  @override
  String totalCountItems(int count) {
    return '$count Itens';
  }

  @override
  String get continuing => 'Em andamento';

  @override
  String get ended => 'Encerrada';

  @override
  String get sortAndFilter => 'Ordenar e Filtrar';

  @override
  String get type => 'Tipo';

  @override
  String get sortBy => 'Ordenar Por';

  @override
  String get display => 'Exibição';

  @override
  String get imageType => 'Tipo de Imagem';

  @override
  String get posterSize => 'Tamanho do Pôster';

  @override
  String get small => 'Pequeno';

  @override
  String get medium => 'Médio';

  @override
  String get large => 'Grande';

  @override
  String get extraLarge => 'Extra Grande';

  @override
  String libraryGenresTitle(String name) {
    return '$name — Gêneros';
  }

  @override
  String get views => 'Visualizações';

  @override
  String get albums => 'Álbuns';

  @override
  String get albumArtists => 'Artistas de Álbum';

  @override
  String get artists => 'Artistas';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get noSavedBookmarks =>
      'Nenhum marcador salvo para este título ainda.';

  @override
  String get openBook => 'Abrir Livro';

  @override
  String get chapter => 'Capítulo';

  @override
  String get page => 'Página';

  @override
  String get bookmark => 'Marcador';

  @override
  String get justNow => 'Agora mesmo';

  @override
  String minutesAgo(int count) {
    return '${count}min atrás';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h atrás';
  }

  @override
  String daysAgo(int count) {
    return '${count}d atrás';
  }

  @override
  String get discoverySubjects => 'Assuntos para Descobrir';

  @override
  String get pickDiscoverySubjects =>
      'Escolha quais feeds de assunto exibir em Descobrir.';

  @override
  String get apply => 'Aplicar';

  @override
  String get audiobookGenres => 'Gêneros de Audiolivros';

  @override
  String get pickAudiobookGenres =>
      'Escolha quais gêneros exibir em Descobrir Audiolivros.';

  @override
  String get discoverAudiobooks => 'Descobrir Audiolivros';

  @override
  String get librivoxDescription =>
      'Títulos populares de domínio público do LibriVox.';

  @override
  String titlesCount(int count) {
    return '$count títulos';
  }

  @override
  String get scrollLeft => 'Rolar para a esquerda';

  @override
  String get scrollRight => 'Rolar para a direita';

  @override
  String get couldNotLoadGenre =>
      'Não foi possível carregar este gênero agora.';

  @override
  String get continueReading => 'Continuar Lendo';

  @override
  String get savedHighlights => 'Destaques Salvos';

  @override
  String get continueListening => 'Continuar Ouvindo';

  @override
  String get listen => 'Ouvir';

  @override
  String get resume => 'Continuar';

  @override
  String get failedToLoadLibrary => 'Falha ao carregar biblioteca';

  @override
  String get popularNow => 'Popular Agora';

  @override
  String get savedForLater => 'Salvos Para Depois';

  @override
  String get topListens => 'Mais Ouvidos';

  @override
  String get unreadDiscoveries => 'Descobertas Não Lidas';

  @override
  String get pickUpAgain => 'Retomar';

  @override
  String get bookHighlightsDescription =>
      'Seus livros com destaques, favoritos ou progresso de leitura.';

  @override
  String get handPickedFromLibrary => 'Selecionados da sua biblioteca.';

  @override
  String get handPickedFromListeningQueue =>
      'Selecionados da sua fila de audição.';

  @override
  String get booksWithHighlights =>
      'Livros com destaques, favoritos ou progresso de leitura.';

  @override
  String get jumpBackNarration =>
      'Retome a narração sem precisar procurar onde parou.';

  @override
  String get unreadBooksReady =>
      'Livros não lidos prontos para a próxima hora tranquila.';

  @override
  String get quickAccessFavorites =>
      'Acesso rápido aos livros que você sempre revisita.';

  @override
  String get searchAudiobooks => 'Pesquisar audiolivros';

  @override
  String get searchYourLibrary => 'Pesquisar sua biblioteca';

  @override
  String get pickUpStory => 'Continue a história de onde parou';

  @override
  String get savedPlacesChapters => 'Seus marcadores e capítulos inacabados';

  @override
  String authorsCount(int count) {
    return '$count autores';
  }

  @override
  String genresCount(int count) {
    return '$count gêneros';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% concluído';
  }

  @override
  String get readyWhenYouAre => 'Pronto quando você estiver';

  @override
  String get details => 'Detalhes';

  @override
  String get listeningRoom => 'Sala de Audição';

  @override
  String get bookmarksAndProgress => 'Marcadores e Progresso';

  @override
  String titlesArrangedForBrowsing(int count) {
    return '$count títulos organizados para navegação focada em leitura.';
  }

  @override
  String get titles => 'Títulos';

  @override
  String get allTitles => 'Todos os Títulos';

  @override
  String get authors => 'Autores';

  @override
  String get browseByAuthor => 'Navegar por Autor';

  @override
  String get browseByGenre => 'Navegar por Gênero';

  @override
  String get discover => 'Descobrir';

  @override
  String get trendingTitlesOpenLibrary =>
      'Títulos em alta por assunto do Open Library.';

  @override
  String get noBookmarkedItems => 'Nenhum item marcado ainda';

  @override
  String get nothingMatchesSection =>
      'Nada corresponde a esta seção ainda. Tente outra aba ou volte após a sincronização da biblioteca.';

  @override
  String get audiobooks => 'Audiolivros';

  @override
  String noLabelFound(String label) {
    return 'Nenhum $label encontrado';
  }

  @override
  String get folder => 'Pasta';

  @override
  String get filters => 'Filtros';

  @override
  String get readingStatus => 'Status de Leitura';

  @override
  String get playedStatus => 'Status de Reprodução';

  @override
  String get readStatus => 'Lido';

  @override
  String get watched => 'Assistido';

  @override
  String get unread => 'Não lido';

  @override
  String get unwatched => 'Não assistido';

  @override
  String get seriesStatus => 'Status da Série';

  @override
  String get allLibraries => 'Todas as Bibliotecas';

  @override
  String get books => 'Livros';

  @override
  String get author => 'Autor';

  @override
  String get unknownAuthor => 'Autor Desconhecido';

  @override
  String get uncategorized => 'Sem Categoria';

  @override
  String get overview => 'Sinopse';

  @override
  String get noLibrivoxDescription =>
      'Nenhuma descrição fornecida pelo LibriVox para este título ainda.';

  @override
  String get readers => 'Leitores';

  @override
  String get openLinks => 'Abrir Links';

  @override
  String get librivoxPage => 'Página do LibriVox';

  @override
  String get internetArchive => 'Internet Archive';

  @override
  String get rssFeed => 'Feed RSS';

  @override
  String get downloadZip => 'Baixar Zip';

  @override
  String sectionCountLabel(int count) {
    return '$count seções';
  }

  @override
  String firstPublished(int year) {
    return 'Publicado pela primeira vez em $year';
  }

  @override
  String get noOpenLibraryOverview =>
      'Nenhuma sinopse disponível do Open Library para este título ainda.';

  @override
  String get subjects => 'Assuntos';

  @override
  String get all => 'Todos';

  @override
  String booksCount(int count) {
    return '$count livros';
  }

  @override
  String get couldNotLoadSubject =>
      'Não foi possível carregar este assunto agora.';

  @override
  String get audiobookDetails => 'Detalhes do Audiolivro';

  @override
  String authorsCountTitle(int count) {
    return '$count Autores';
  }

  @override
  String audiobookCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count audiolivros',
      one: '1 audiolivro',
    );
    return '$_temp0';
  }

  @override
  String get trackList => 'Lista de Faixas';

  @override
  String get itemListPlaceholder => 'A lista de itens aparecerá aqui';

  @override
  String get favoriteTracksPlaceholder => 'As faixas favoritas aparecerão aqui';

  @override
  String get failedToLoad => 'Falha ao carregar';

  @override
  String get delete => 'Excluir';

  @override
  String get save => 'Salvar';

  @override
  String get moreLikeThis => 'Mais Como Este';

  @override
  String get castAndCrew => 'Elenco e Equipe';

  @override
  String get collection => 'Coleção';

  @override
  String get episodes => 'Episódios';

  @override
  String get nextUp => 'A Seguir';

  @override
  String get seasons => 'Temporadas';

  @override
  String get chapters => 'Capítulos';

  @override
  String get features => 'Extras';

  @override
  String get movies => 'Filmes';

  @override
  String get other => 'Outros';

  @override
  String get discography => 'Discografia';

  @override
  String get similarArtists => 'Artistas Semelhantes';

  @override
  String get tableOfContents => 'Índice';

  @override
  String get tracklist => 'Lista de Faixas';

  @override
  String get biography => 'Biografia';

  @override
  String get authorDetails => 'Detalhes do Autor';

  @override
  String get noOverviewAvailable =>
      'Nenhuma sinopse disponível para este título ainda.';

  @override
  String get noBiographyAvailable =>
      'Nenhuma biografia disponível para este autor.';

  @override
  String get noBooksFound => 'Nenhum livro encontrado para este autor.';

  @override
  String get unableToLoadAuthorDetails =>
      'Não foi possível carregar os detalhes do autor agora.';

  @override
  String published(int year) {
    return 'Publicado em $year';
  }

  @override
  String get publicationDateUnknown => 'Data de publicação desconhecida';

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Temporadas',
      one: '1 Temporada',
    );
    return '$_temp0';
  }

  @override
  String endsAt(String time) {
    return 'Termina às $time';
  }

  @override
  String get view => 'Visualizar';

  @override
  String get resumeReading => 'Continuar Lendo';

  @override
  String get read => 'Ler';

  @override
  String resumeFrom(String position) {
    return 'Continuar de $position';
  }

  @override
  String get play => 'Reproduzir';

  @override
  String get startOver => 'Recomeçar';

  @override
  String get restart => 'Reiniciar';

  @override
  String get readOffline => 'Ler Offline';

  @override
  String get playOffline => 'Reproduzir Offline';

  @override
  String get audio => 'Áudio';

  @override
  String get subtitles => 'Legendas';

  @override
  String get version => 'Versão';

  @override
  String get cast => 'Transmitir';

  @override
  String get trailer => 'Trailer';

  @override
  String get finished => 'Concluído';

  @override
  String get favorited => 'Favoritado';

  @override
  String get favorite => 'Favorito';

  @override
  String get playlist => 'Playlist';

  @override
  String get downloaded => 'Baixado';

  @override
  String get downloadAll => 'Baixar Tudo';

  @override
  String get download => 'Baixar';

  @override
  String get deleteDownloaded => 'Excluir Baixados';

  @override
  String get goToSeries => 'Ir para a Série';

  @override
  String get editMetadata => 'Editar Metadados';

  @override
  String get less => 'Menos';

  @override
  String get more => 'Mais';

  @override
  String get deleteItem => 'Excluir Item';

  @override
  String get deletePlaylist => 'Excluir Playlist';

  @override
  String get deletePlaylistMessage => 'Excluir esta playlist do servidor?';

  @override
  String get deleteItemMessage => 'Excluir este item do servidor?';

  @override
  String get failedToDeletePlaylist => 'Falha ao excluir playlist';

  @override
  String get failedToDeleteItem => 'Falha ao excluir item';

  @override
  String get renamePlaylist => 'Renomear Playlist';

  @override
  String get playlistName => 'Nome da playlist';

  @override
  String get deleteDownloadedAlbum => 'Excluir Álbum Baixado';

  @override
  String deleteDownloadedTracksMessage(String title) {
    return 'Excluir faixas baixadas de \"$title\"?';
  }

  @override
  String get downloadedTracksDeleted => 'Faixas baixadas excluídas';

  @override
  String get downloadedTracksDeleteFailed =>
      'Algumas faixas baixadas não puderam ser excluídas';

  @override
  String get noTracksLoaded => 'Nenhuma faixa carregada';

  @override
  String noItemsLoaded(String itemLabel) {
    return 'Nenhum $itemLabel carregado';
  }

  @override
  String downloadingTitle(String title, int count) {
    return 'Baixando $title ($count itens)...';
  }

  @override
  String deleteConfirmMessage(String name) {
    return 'Tem certeza que deseja excluir \"$name\" do servidor? Esta ação não pode ser desfeita.';
  }

  @override
  String get itemDeleted => 'Item excluído';

  @override
  String get noPlayableTrailerFound =>
      'Nenhum trailer reproduzível encontrado.';

  @override
  String unsupportedBookFormat(String extension) {
    return 'Formato de livro não suportado: .$extension';
  }

  @override
  String get audioTrack => 'Faixa de Áudio';

  @override
  String get subtitleTrack => 'Faixa de Legenda';

  @override
  String get none => 'Nenhum';

  @override
  String get downloadSubtitlesLabel => 'Baixar legendas...';

  @override
  String get searchOpenSubtitlesPlugin =>
      'Pesquisar usando o plugin OpenSubtitles';

  @override
  String get downloadSubtitles => 'Baixar Legendas';

  @override
  String get selectedSubtitleInvalid => 'A legenda selecionada é inválida.';

  @override
  String subtitleDownloadedSelected(String name) {
    return 'Legenda baixada e selecionada: $name';
  }

  @override
  String get subtitleDownloadedPending =>
      'Legenda baixada. Pode levar um momento para aparecer enquanto o Jellyfin atualiza o item.';

  @override
  String noRemoteSubtitlesFound(String language) {
    return 'Nenhuma legenda remota encontrada para $language.';
  }

  @override
  String get selectVersion => 'Selecionar Versão';

  @override
  String versionNumber(int number) {
    return 'Versão $number';
  }

  @override
  String get downloadAllQuality => 'Baixar Tudo - Qualidade';

  @override
  String get downloadQuality => 'Qualidade do Download';

  @override
  String get originalFileNoReencoding => 'Arquivo original, sem recodificação';

  @override
  String get originalFilesNoReencoding =>
      'Arquivos originais, sem recodificação';

  @override
  String get noEpisodesLoaded => 'Nenhum episódio carregado';

  @override
  String downloadingItem(String name, String quality) {
    return 'Baixando $name ($quality)...';
  }

  @override
  String get deleteDownloadedFiles => 'Excluir Arquivos Baixados';

  @override
  String deleteLocalFilesMessage(String typeLabel) {
    return 'Excluir arquivos locais de $typeLabel?\n\nIsso liberará espaço de armazenamento. Você pode baixar novamente depois.';
  }

  @override
  String get downloadedFilesDeleted => 'Arquivos baixados excluídos';

  @override
  String get failedToDeleteFiles => 'Falha ao excluir arquivos';

  @override
  String get deleteFiles => 'Excluir Arquivos';

  @override
  String get director => 'DIRETOR';

  @override
  String get writers => 'ROTEIRISTAS';

  @override
  String get studio => 'ESTÚDIO';

  @override
  String studioMoreCount(int count) {
    return '+$count mais';
  }

  @override
  String totalEpisodes(int count) {
    return '$count Episódios';
  }

  @override
  String episodeProgress(int watched, int total) {
    return '$watched / $total';
  }

  @override
  String episodeLabel(int number) {
    return 'Episódio $number';
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
      other: '$count faixas',
      one: '1 faixa',
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
    return 'Nascimento $date';
  }

  @override
  String died(String date) {
    return 'Falecimento $date';
  }

  @override
  String age(int age) {
    return 'Idade $age';
  }

  @override
  String get showLess => 'Mostrar Menos';

  @override
  String get readMore => 'Ler Mais';

  @override
  String get shuffle => 'Aleatório';

  @override
  String downloadsCount(int count) {
    return '$count downloads';
  }

  @override
  String get perfectMatch => 'Correspondência perfeita';

  @override
  String channelsCount(int count) {
    return '${count}ch';
  }

  @override
  String get mono => 'Mono';

  @override
  String get stereo => 'Estéreo';

  @override
  String remoteSubtitlePermissionError(String action) {
    return 'A ação de legenda remota $action requer permissão de gerenciamento de legendas do Jellyfin para este usuário.';
  }

  @override
  String remoteSubtitleNotFoundError(String action) {
    return 'Este item não foi encontrado no servidor para a ação de legenda remota $action.';
  }

  @override
  String remoteSubtitleDetailError(String action, String detail) {
    return 'A ação de legenda remota $action falhou: $detail';
  }

  @override
  String remoteSubtitleHttpError(String action, int status) {
    return 'A ação de legenda remota $action falhou (HTTP $status).';
  }

  @override
  String remoteSubtitleGenericError(String action) {
    return 'Falha ao $action legendas remotas.';
  }

  @override
  String deleteSeriesFiles(String name) {
    return 'todos os episódios baixados de \"$name\"';
  }

  @override
  String get deleteSeasonFiles => 'todos os episódios baixados desta temporada';

  @override
  String get stillWatching => 'Ainda Assistindo?';

  @override
  String get unableToLoadTrailerStream =>
      'Não foi possível carregar o stream do trailer.';

  @override
  String get trailerTimedOut => 'O trailer expirou durante o carregamento.';

  @override
  String get playbackFailedForTrailer =>
      'A reprodução falhou para este trailer.';

  @override
  String photoCountOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get castingUnavailableOffline =>
      'A transmissão não está disponível durante a reprodução offline.';

  @override
  String castActionFailed(String label, String error) {
    return 'A ação $label falhou: $error';
  }

  @override
  String failedToSetCastVolume(String error) {
    return 'Falha ao definir o volume da transmissão: $error';
  }

  @override
  String castControlsTitle(String label) {
    return 'Controles de $label';
  }

  @override
  String get deviceVolume => 'Volume do Dispositivo';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get pause => 'Pausar';

  @override
  String get syncPosition => 'Sincronizar Posição';

  @override
  String stopCast(String label) {
    return 'Parar $label';
  }

  @override
  String get queueIsEmpty => 'A fila está vazia';

  @override
  String trackNumber(int number) {
    return 'Faixa $number';
  }

  @override
  String get remotePlayback => 'Reprodução Remota';

  @override
  String get castingToGoogleCast => 'Transmitindo via Google Cast';

  @override
  String get castingViaAirPlay => 'Transmitindo via AirPlay';

  @override
  String get castingViaDlna => 'Transmitindo via DLNA';

  @override
  String secondsCount(int seconds) {
    return '$seconds segundos';
  }

  @override
  String get longPressToUnlock => 'Pressione e segure para desbloquear';

  @override
  String get off => 'Desligado';

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
  String get audioDelay => 'Atraso de Áudio';

  @override
  String get subtitleDelay => 'Atraso de Legenda';

  @override
  String get reset => 'Redefinir';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get playbackInformation => 'Informações de Reprodução';

  @override
  String get playback => 'Reprodução';

  @override
  String get playMethod => 'Método de Reprodução';

  @override
  String get directPlay => 'Reprodução Direta';

  @override
  String get directStream => 'Stream Direto';

  @override
  String get transcoding => 'Transcodificação';

  @override
  String get transcodeReasons => 'Motivos da Transcodificação';

  @override
  String get player => 'Reprodutor';

  @override
  String get container => 'Container';

  @override
  String get bitrate => 'Taxa de Bits';

  @override
  String get video => 'Vídeo';

  @override
  String get resolution => 'Resolução';

  @override
  String get hdr => 'HDR';

  @override
  String get codec => 'Codec';

  @override
  String get videoBitrate => 'Taxa de Bits do Vídeo';

  @override
  String get track => 'Faixa';

  @override
  String get channels => 'Canais';

  @override
  String get audioBitrate => 'Taxa de Bits do Áudio';

  @override
  String get sampleRate => 'Taxa de Amostragem';

  @override
  String get format => 'Formato';

  @override
  String get external => 'Externo';

  @override
  String get embedded => 'Embutido';

  @override
  String castSessionError(String protocol) {
    return 'Erro de sessão $protocol';
  }

  @override
  String failedToLoadBookDetails(String error) {
    return 'Falha ao carregar detalhes do livro: $error';
  }

  @override
  String get epubUnavailableOnPlatform =>
      'A renderização de EPUB no app ainda não está disponível nesta plataforma.';

  @override
  String formatCannotRenderInApp(String extension) {
    return 'Este formato (.$extension) ainda não pode ser renderizado no app.';
  }

  @override
  String get embeddedRenderingUnavailable =>
      'A renderização de documentos embutidos não está disponível nesta plataforma.';

  @override
  String get couldNotOpenExternalViewer =>
      'Não foi possível abrir o visualizador externo.';

  @override
  String failedToOpenInAppReader(String error) {
    return 'Falha ao abrir o leitor integrado: $error';
  }

  @override
  String bookmarkAlreadySaved(String label) {
    return 'Marcador já salvo em $label.';
  }

  @override
  String bookmarkAdded(String label) {
    return 'Marcador adicionado: $label';
  }

  @override
  String get noBookmarksYet =>
      'Nenhum marcador ainda.\nToque no ícone de marcador enquanto lê para salvar sua posição.';

  @override
  String get noTableOfContentsAvailable => 'Índice não disponível';

  @override
  String pageLabel(int number) {
    return 'Página $number';
  }

  @override
  String get position => 'Posição';

  @override
  String get bookReader => 'Leitor de Livros';

  @override
  String formatExtension(String extension) {
    return 'Formato: .$extension';
  }

  @override
  String percentRead(String percent) {
    return '$percent% lido';
  }

  @override
  String get updating => 'Atualizando...';

  @override
  String get markUnread => 'Marcar como Não Lido';

  @override
  String get markAsRead => 'Marcar como Lido';

  @override
  String get reloadReader => 'Recarregar Leitor';

  @override
  String get noPagesFound => 'Nenhuma página encontrada.';

  @override
  String get failedToDecodePageImage =>
      'Falha ao decodificar a imagem da página.';

  @override
  String resetZoom(String zoom) {
    return 'Redefinir Zoom (${zoom}x)';
  }

  @override
  String get singlePage => 'Página Única';

  @override
  String get twoPageSpread => 'Páginas Duplas';

  @override
  String get addBookmark => 'Adicionar Marcador';

  @override
  String get bookmarksEllipsis => 'Marcadores...';

  @override
  String get markedAsRead => 'Marcado como lido';

  @override
  String get markedAsUnread => 'Marcado como não lido';

  @override
  String failedToUpdateReadState(String error) {
    return 'Falha ao atualizar o estado de leitura: $error';
  }

  @override
  String get themeSystem => 'Tema: Sistema';

  @override
  String get themeLight => 'Tema: Claro';

  @override
  String get themeDark => 'Tema: Escuro';

  @override
  String get themeSepia => 'Tema: Sépia';

  @override
  String get invertColorsFixedLayout => 'Inverter Cores (layout fixo)';

  @override
  String get invertColorsPdf => 'Inverter Cores (PDF)';

  @override
  String get preparingInAppReader => 'Preparando leitor integrado...';

  @override
  String get pdfDataNotAvailable => 'Dados do PDF não disponíveis.';

  @override
  String get readerFallbackModeActive => 'Modo alternativo do leitor ativo';

  @override
  String platformCannotHostDocumentEngine(String extension) {
    return 'Esta plataforma não pode hospedar o motor de documentos embutido para arquivos $extension.';
  }

  @override
  String get reloadReaderPlatformHint =>
      'Use Recarregar Leitor após mudar para uma plataforma suportada (Android, iOS, macOS).';

  @override
  String get openExternally => 'Abrir Externamente';

  @override
  String get noEpubChaptersFound => 'Nenhum capítulo EPUB encontrado.';

  @override
  String get readerNotReady => 'Leitor não está pronto.';

  @override
  String get seriesRecordings => 'Gravações de Séries';

  @override
  String get now => 'Agora';

  @override
  String get sports => 'Esportes';

  @override
  String get news => 'Notícias';

  @override
  String get kids => 'Infantil';

  @override
  String get premiere => 'Estreia';

  @override
  String get guideTimeline => 'Linha do Tempo do Guia';

  @override
  String failedToLoadGuide(String error) {
    return 'Falha ao carregar o guia: $error';
  }

  @override
  String get noChannelsFound => 'Nenhum canal encontrado';

  @override
  String get liveBadge => 'AO VIVO';

  @override
  String get movie => 'Filme';

  @override
  String get removedFromFavoriteChannels => 'Removido dos canais favoritos';

  @override
  String get addedToFavoriteChannels => 'Adicionado aos canais favoritos';

  @override
  String get failedToUpdateFavoriteChannel =>
      'Falha ao atualizar canal favorito';

  @override
  String get unfavoriteChannel => 'Desfavoritar Canal';

  @override
  String get favoriteChannel => 'Favoritar Canal';

  @override
  String get watch => 'Assistir';

  @override
  String get close => 'Fechar';

  @override
  String failedToPlayChannel(String name) {
    return 'Falha ao reproduzir $name';
  }

  @override
  String get failedToLoadRecordings => 'Falha ao carregar gravações';

  @override
  String get scheduledInNext24Hours => 'Agendados nas Próximas 24 Horas';

  @override
  String get recentRecordings => 'Gravações Recentes';

  @override
  String get tvSeries => 'Séries de TV';

  @override
  String get failedToLoadSchedule => 'Falha ao carregar agenda';

  @override
  String get noScheduledRecordings => 'Nenhuma gravação agendada';

  @override
  String get cancelRecording => 'Cancelar Gravação?';

  @override
  String cancelScheduledRecordingOf(String name) {
    return 'Cancelar gravação agendada de \"$name\"?';
  }

  @override
  String get no => 'Não';

  @override
  String get yesCancel => 'Sim, Cancelar';

  @override
  String get failedToCancelRecording => 'Falha ao cancelar gravação';

  @override
  String get failedToLoadSeriesRecordings =>
      'Falha ao carregar gravações de séries';

  @override
  String get noSeriesRecordings => 'Nenhuma gravação de série';

  @override
  String get cancelSeriesRecording => 'Cancelar Gravação de Série';

  @override
  String get cancelSeriesRecordingQuestion => 'Cancelar Gravação de Série?';

  @override
  String stopRecordingName(String name) {
    return 'Parar de gravar \"$name\"?';
  }

  @override
  String get failedToCancelSeriesRecording =>
      'Falha ao cancelar gravação de série';

  @override
  String get searchThisLibrary => 'Pesquisar nesta biblioteca...';

  @override
  String get searchEllipsis => 'Pesquisar...';

  @override
  String noResultsForQuery(String query) {
    return 'Nenhum resultado para \"$query\"';
  }

  @override
  String searchFailedError(String error) {
    return 'A pesquisa falhou: $error';
  }

  @override
  String get seerr => 'Seerr';

  @override
  String get savedMedia => 'Mídia Salva';

  @override
  String get tvShows => 'Séries de TV';

  @override
  String get music => 'Música';

  @override
  String get musicAlbums => 'Álbuns de Música';

  @override
  String get noMediaInFilter => 'Nenhuma mídia neste filtro';

  @override
  String get noDownloadedMediaYet => 'Nenhuma mídia baixada ainda';

  @override
  String get browseLibrary => 'Navegar na Biblioteca';

  @override
  String get deleteDownload => 'Excluir Download';

  @override
  String removeItemAndFiles(String name) {
    return 'Remover \"$name\" e seus arquivos?';
  }

  @override
  String tracksCount(int count) {
    return '$count faixas';
  }

  @override
  String get album => 'Álbum';

  @override
  String get playAlbum => 'Reproduzir Álbum';

  @override
  String failedToLoadAlbum(String error) {
    return 'Falha ao carregar álbum: $error';
  }

  @override
  String noDownloadedTracksForAlbum(String name) {
    return 'Nenhuma faixa baixada encontrada para $name.';
  }

  @override
  String get season => 'Temporada';

  @override
  String get errorLoadingEpisodes => 'Erro ao carregar episódios';

  @override
  String get noDownloadedEpisodes => 'Nenhum episódio baixado';

  @override
  String get deleteEpisode => 'Excluir Episódio';

  @override
  String removeName(String name) {
    return 'Remover \"$name\"?';
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
    return 'Episódio $number';
  }

  @override
  String get seriesNotFound => 'Série não encontrada';

  @override
  String get errorLoadingSeries => 'Erro ao carregar série';

  @override
  String get downloadedEpisodes => 'Episódios Baixados';

  @override
  String seasonNumber(int number) {
    return 'Temporada $number';
  }

  @override
  String get specials => 'Especiais';

  @override
  String get deleteSeason => 'Excluir Temporada';

  @override
  String deleteAllEpisodesInSeason(String season) {
    return 'Excluir todos os episódios baixados em $season?';
  }

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episódios',
      one: '1 episódio',
    );
    return '$_temp0';
  }

  @override
  String get storageManagement => 'Gerenciamento de Armazenamento';

  @override
  String get storageBreakdown => 'Detalhamento do Armazenamento';

  @override
  String get downloadedItems => 'Itens Baixados';

  @override
  String get storageLimit => 'Limite de Armazenamento';

  @override
  String get noLimit => 'Sem limite';

  @override
  String get deleteAllDownloads => 'Excluir Todos os Downloads';

  @override
  String get deleteAllDownloadsWarning =>
      'Isso removerá todos os arquivos de mídia baixados e não pode ser desfeito.';

  @override
  String get deleteAll => 'Excluir Tudo';

  @override
  String get deleteSelected => 'Excluir Selecionados';

  @override
  String deleteSelectedCount(int count) {
    return 'Excluir $count itens baixados?';
  }

  @override
  String get musicAndAudiobooks => 'Música e Audiolivros';

  @override
  String get images => 'Imagens';

  @override
  String get database => 'Banco de Dados';

  @override
  String ofStorageLimit(String limit) {
    return 'de $limit de limite';
  }

  @override
  String get settings => 'Configurações';

  @override
  String get authentication => 'Autenticação';

  @override
  String get autoLoginServerManagement =>
      'Login automático, gerenciamento de servidores';

  @override
  String get pinCode => 'Código PIN';

  @override
  String get setUpPinCodeProtection => 'Configurar proteção por código PIN';

  @override
  String get parentalControls => 'Controles Parentais';

  @override
  String get contentRatingRestrictions =>
      'Restrições de classificação de conteúdo';

  @override
  String get bitRateResolutionBehavior =>
      'Taxa de bits, resolução, comportamento';

  @override
  String get languageSizeAppearance => 'Idioma, tamanho, aparência';

  @override
  String get qualityStorage => 'Qualidade, armazenamento';

  @override
  String get serverSyncAndPluginStatus =>
      'Sincronização do servidor e status do plugin';

  @override
  String get mediaRequestIntegration => 'Integração de solicitações de mídia';

  @override
  String get switchServer => 'Trocar Servidor';

  @override
  String get signOut => 'Sair';

  @override
  String get versionLicenses => 'Versão, licenças';

  @override
  String get account => 'Conta';

  @override
  String get signInAndSecurity => 'Login e segurança';

  @override
  String get administration => 'Administração';

  @override
  String get serverSettingsUsersLibraries =>
      'Configurações do servidor, usuários, bibliotecas';

  @override
  String get customization => 'Personalização';

  @override
  String get themeAndLayout => 'Tema e layout';

  @override
  String get videoAndSubtitles => 'Vídeo e legendas';

  @override
  String get integrations => 'Integrações';

  @override
  String get pluginAndRequests => 'Plugin e solicitações';

  @override
  String get customizeAccountPlaybackInterface =>
      'Personalize conta, reprodução e comportamento da interface';

  @override
  String optionsCount(int count) {
    return '$count opções';
  }

  @override
  String get themeAndAppearance => 'Tema e Aparência';

  @override
  String get focusBorderColor => 'Cor da Borda de Foco';

  @override
  String get watchedIndicators => 'Indicadores de Assistido';

  @override
  String get always => 'Sempre';

  @override
  String get hideUnwatched => 'Ocultar Não Assistidos';

  @override
  String get episodesOnly => 'Apenas Episódios';

  @override
  String get never => 'Nunca';

  @override
  String get focusExpansionAnimation => 'Animação de Expansão do Foco';

  @override
  String get scaleFocusedCards =>
      'Redimensionar cards focados ou com cursor sobre eles';

  @override
  String get backgroundBackdrops => 'Imagens de Fundo';

  @override
  String get showBackdropImages => 'Mostrar imagens de fundo atrás do conteúdo';

  @override
  String get seriesThumbnails => 'Miniaturas de Séries';

  @override
  String get seriesThumbnailsDescription =>
      'Apenas episódios: usar arte da série que corresponda ao tipo de imagem de cada linha';

  @override
  String get homeRowInfoOverlay => 'Sobreposição de Info na Tela Inicial';

  @override
  String get showTitleMetadataOnHomeRows =>
      'Mostrar título e metadados ao navegar as linhas da tela inicial';

  @override
  String get clockDisplay => 'Exibição do Relógio';

  @override
  String get inMenus => 'Nos Menus';

  @override
  String get inVideo => 'No Vídeo';

  @override
  String get seasonalEffects => 'Efeitos Sazonais';

  @override
  String get snow => 'Neve';

  @override
  String get fireworks => 'Fogos de Artifício';

  @override
  String get confetti => 'Confete';

  @override
  String get fallingLeaves => 'Folhas Caindo';

  @override
  String get themeMusic => 'Música Tema';

  @override
  String get playThemeMusicOnDetailPages =>
      'Reproduzir música tema nas páginas de detalhes';

  @override
  String get themeMusicVolume => 'Volume da Música Tema';

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String get themeMusicOnHomeRows => 'Música Tema nas Linhas Iniciais';

  @override
  String get playWhenBrowsingHomeScreen =>
      'Reproduzir ao navegar na tela inicial';

  @override
  String get detailsBackgroundBlur => 'Desfoque do Fundo de Detalhes';

  @override
  String pixelValue(int value) {
    return '${value}px';
  }

  @override
  String get browsingBackgroundBlur => 'Desfoque do Fundo de Navegação';

  @override
  String get maxStreamingBitrate => 'Taxa de Bits Máxima de Streaming';

  @override
  String get maxResolution => 'Resolução Máxima';

  @override
  String get playerZoomMode => 'Modo de Zoom do Reprodutor';

  @override
  String get fit => 'Ajustar';

  @override
  String get autoCrop => 'Corte Automático';

  @override
  String get stretch => 'Esticar';

  @override
  String get refreshRateSwitching => 'Troca de Taxa de Atualização';

  @override
  String get disabled => 'Desabilitado';

  @override
  String get scaleOnTv => 'Ajustar na TV';

  @override
  String get scaleOnDevice => 'Ajustar no Dispositivo';

  @override
  String get trickPlay => 'Trick Play';

  @override
  String get showPreviewThumbnailsWhenSeeking =>
      'Mostrar miniaturas de pré-visualização ao avançar';

  @override
  String get showDescriptionOnPause => 'Mostrar Descrição ao Pausar';

  @override
  String get dimVideoShowOverview =>
      'Escurecer vídeo e mostrar descrição enquanto pausado';

  @override
  String get osdLockButton => 'Botão de Bloqueio do OSD';

  @override
  String get osdLockButtonDescription =>
      'Mostrar um botão de bloqueio que bloqueia a entrada de toque até ser pressionado longamente';

  @override
  String get audioBehavior => 'Comportamento de Áudio';

  @override
  String get downmixToStereo => 'Reduzir para Estéreo';

  @override
  String get defaultAudioLanguage => 'Idioma de Áudio Padrão';

  @override
  String get autoServerDefault => 'Automático (Padrão do Servidor)';

  @override
  String get english => 'Inglês';

  @override
  String get spanish => 'Espanhol';

  @override
  String get french => 'Francês';

  @override
  String get german => 'Alemão';

  @override
  String get italian => 'Italiano';

  @override
  String get portuguese => 'Português';

  @override
  String get japanese => 'Japonês';

  @override
  String get korean => 'Coreano';

  @override
  String get chinese => 'Chinês';

  @override
  String get russian => 'Russo';

  @override
  String get arabic => 'Árabe';

  @override
  String get hindi => 'Híndi';

  @override
  String get dutch => 'Holandês';

  @override
  String get swedish => 'Sueco';

  @override
  String get norwegian => 'Norueguês';

  @override
  String get danish => 'Dinamarquês';

  @override
  String get finnish => 'Finlandês';

  @override
  String get polish => 'Polonês';

  @override
  String get ac3Passthrough => 'Passthrough AC3';

  @override
  String get trueHdSupport => 'Suporte a TrueHD';

  @override
  String get enableTrueHdAudio =>
      'Habilitar áudio TrueHD (pode não funcionar em todas as plataformas)';

  @override
  String get nightMode => 'Modo Noturno';

  @override
  String get compressDynamicRange => 'Comprimir faixa dinâmica';

  @override
  String get advancedMpv => 'mpv Avançado';

  @override
  String get enableCustomMpvConf => 'Habilitar mpv.conf Personalizado';

  @override
  String get applyMpvConfBeforePlayback =>
      'Aplicar um mpv.conf especificado pelo usuário antes de iniciar a reprodução';

  @override
  String get unsafeAdvancedMpvOptions => 'Opções Avançadas Inseguras do mpv';

  @override
  String get unsafeMpvOptionsDescription =>
      'Permitir um conjunto mais amplo de opções do mpv. Pode quebrar o comportamento da reprodução.';

  @override
  String get nextUpAndQueuing => 'A Seguir e Fila';

  @override
  String get nextUpBehavior => 'Comportamento do A Seguir';

  @override
  String get extended => 'Estendido';

  @override
  String get minimal => 'Mínimo';

  @override
  String get nextUpTimeout => 'Tempo Limite do A Seguir';

  @override
  String secondsValue(int value) {
    return '${value}s';
  }

  @override
  String get mediaQueuing => 'Enfileiramento de Mídia';

  @override
  String get autoQueueNextEpisodes =>
      'Enfileirar automaticamente os próximos episódios';

  @override
  String get stillWatchingPrompt => 'Aviso de Ainda Assistindo';

  @override
  String afterEpisodesAndHours(int episodes, double hours) {
    return 'Após $episodes episódios / ${hours}h';
  }

  @override
  String get resumeAndSkip => 'Retomar e Pular';

  @override
  String get resumeRewind => 'Retroceder ao Retomar';

  @override
  String get fiveSeconds => '5 segundos';

  @override
  String get tenSeconds => '10 segundos';

  @override
  String get fifteenSeconds => '15 segundos';

  @override
  String get thirtySeconds => '30 segundos';

  @override
  String get skipBackLength => 'Duração do Retrocesso';

  @override
  String get skipForwardLength => 'Duração do Avanço';

  @override
  String get customMpvConfPath => 'Caminho do mpv.conf Personalizado';

  @override
  String get notSetMpvConf =>
      'Não definido. O Moonfin tentará um mpv.conf padrão nas pastas do app/dados.';

  @override
  String get selectMpvConf => 'Selecionar mpv.conf';

  @override
  String get pathToMpvConf => '/caminho/para/mpv.conf';

  @override
  String get subtitleStyleDescription =>
      'As configurações de estilo (tamanho, cor, deslocamento) se aplicam a legendas baseadas em texto (SRT, VTT, TTML). Legendas ASS/SSA usam seu próprio estilo embutido, a menos que \"Reprodução Direta ASS/SSA\" esteja desativada. Legendas bitmap (PGS, DVB, VobSub) não podem ser reestilizadas.';

  @override
  String get defaultSubtitleLanguage => 'Idioma de Legenda Padrão';

  @override
  String get defaultToNoSubtitles => 'Padrão Sem Legendas';

  @override
  String get turnOffSubtitlesByDefault => 'Desativar legendas por padrão';

  @override
  String get subtitleSize => 'Tamanho da Legenda';

  @override
  String get textColor => 'Cor do Texto';

  @override
  String get backgroundColor => 'Cor de Fundo';

  @override
  String get strokeColor => 'Cor do Contorno';

  @override
  String get verticalOffset => 'Deslocamento Vertical';

  @override
  String get pgsDirectPlay => 'Reprodução Direta PGS';

  @override
  String get directPlayPgsSubtitles => 'Reproduzir diretamente legendas PGS';

  @override
  String get assSsaDirectPlay => 'Reprodução Direta ASS/SSA';

  @override
  String get directPlayAssSsaSubtitles =>
      'Reproduzir diretamente legendas ASS/SSA';

  @override
  String get white => 'Branco';

  @override
  String get black => 'Preto';

  @override
  String get yellow => 'Amarelo';

  @override
  String get green => 'Verde';

  @override
  String get cyan => 'Ciano';

  @override
  String get red => 'Vermelho';

  @override
  String get transparent => 'Transparente';

  @override
  String get semiTransparentBlack => 'Preto Semitransparente';

  @override
  String get global => 'Global';

  @override
  String get desktop => 'Desktop';

  @override
  String get mobile => 'Celular';

  @override
  String get tv => 'TV';

  @override
  String loadedProfileSettings(String profile) {
    return 'Configurações do perfil $profile carregadas.';
  }

  @override
  String failedToLoadProfileSettings(String profile) {
    return 'Falha ao carregar configurações do perfil $profile.';
  }

  @override
  String syncedSettingsToProfile(String profile) {
    return 'Configurações locais sincronizadas com o perfil $profile.';
  }

  @override
  String get customizationProfile => 'Perfil de Personalização';

  @override
  String get customizationProfileDescription =>
      'Escolha o perfil para carregar, editar e sincronizar. O Global se aplica em todos os lugares, a menos que um perfil de dispositivo o substitua. O ponto verde marca o perfil do seu dispositivo atual.';

  @override
  String get loadProfile => 'Carregar Perfil';

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get syncToProfile => 'Sincronizar com Perfil';

  @override
  String get profileSyncHidden => 'Sincronização de Perfil Oculta';

  @override
  String get enablePluginSyncDescription =>
      'Habilite a Sincronização do Plugin do Servidor nas configurações de Plugin para mostrar os controles de perfil aqui.';

  @override
  String get quality => 'Qualidade';

  @override
  String get defaultDownloadQuality => 'Qualidade de Download Padrão';

  @override
  String get network => 'Rede';

  @override
  String get wifiOnlyDownloads => 'Downloads Apenas por WiFi';

  @override
  String get onlyDownloadOnWifi => 'Baixar apenas quando conectado ao WiFi';

  @override
  String get storage => 'Armazenamento';

  @override
  String get storageUsed => 'Armazenamento Usado';

  @override
  String get manage => 'Gerenciar';

  @override
  String get calculating => 'Calculando...';

  @override
  String get downloadLocation => 'Local de Download';

  @override
  String get defaultLabel => 'Padrão';

  @override
  String get saveToDownloadsFolder => 'Salvar na pasta Downloads';

  @override
  String get downloadsVisibleToOtherApps =>
      'Downloads/Moonfin - visível para outros apps';

  @override
  String get dangerZone => 'Zona de Perigo';

  @override
  String get clearAllDownloads => 'Limpar Todos os Downloads';

  @override
  String get original => 'Original';

  @override
  String get changeDownloadLocation => 'Alterar Local de Download';

  @override
  String get changeDownloadLocationDescription =>
      'Novos downloads serão salvos na pasta selecionada. Downloads existentes permanecerão em seu local atual e podem ser gerenciados nas configurações de Armazenamento.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cannotWriteToFolder =>
      'Não é possível gravar na pasta selecionada. Escolha outro local ou conceda permissões de armazenamento.';

  @override
  String get saveToDownloadsFolderQuestion => 'Salvar na pasta Downloads?';

  @override
  String get saveToDownloadsFolderDescription =>
      'A mídia baixada será salva em Downloads/Moonfin no seu dispositivo. Esses arquivos serão visíveis para outros apps como sua galeria ou reprodutor de música.\n\nDownloads existentes permanecerão em seu local atual.';

  @override
  String get enable => 'Habilitar';

  @override
  String get clearAllDownloadsWarning =>
      'Isso excluirá todas as mídias baixadas e não pode ser desfeito.';

  @override
  String get clearAll => 'Limpar Tudo';

  @override
  String get navigationStyle => 'Estilo de Navegação';

  @override
  String get topBar => 'Barra Superior';

  @override
  String get leftSidebar => 'Barra Lateral Esquerda';

  @override
  String get showShuffleButton => 'Mostrar Botão Aleatório';

  @override
  String get showGenresButton => 'Mostrar Botão de Gêneros';

  @override
  String get showFavoritesButton => 'Mostrar Botão de Favoritos';

  @override
  String get showLibrariesInToolbar =>
      'Mostrar Bibliotecas na Barra de Ferramentas';

  @override
  String get navbarOpacity => 'Opacidade da Barra de Navegação';

  @override
  String get navbarColor => 'Cor da Barra de Navegação';

  @override
  String get gray => 'Cinza';

  @override
  String get darkBlue => 'Azul Escuro';

  @override
  String get purple => 'Roxo';

  @override
  String get teal => 'Azul-petróleo';

  @override
  String get navy => 'Azul Marinho';

  @override
  String get charcoal => 'Carvão';

  @override
  String get brown => 'Marrom';

  @override
  String get darkRed => 'Vermelho Escuro';

  @override
  String get darkGreen => 'Verde Escuro';

  @override
  String get slate => 'Ardósia';

  @override
  String get indigo => 'Índigo';

  @override
  String get libraryDisplay => 'Exibição da Biblioteca';

  @override
  String get posterLabel => 'Pôster';

  @override
  String get thumbnailLabel => 'Miniatura';

  @override
  String get bannerLabel => 'Banner';

  @override
  String get overridePerLibrarySettings =>
      'Substituir Configurações por Biblioteca';

  @override
  String get applyImageTypeToAllLibraries =>
      'Aplicar tipo de imagem a todas as bibliotecas';

  @override
  String get multiServerLibraries => 'Bibliotecas Multi-Servidor';

  @override
  String get showLibrariesFromAllServers =>
      'Mostrar bibliotecas de todos os servidores conectados';

  @override
  String get enableFolderView => 'Habilitar Visualização de Pastas';

  @override
  String get showFolderBrowsingOption =>
      'Mostrar opção de navegação por pastas';

  @override
  String get libraryVisibility => 'Visibilidade da Biblioteca';

  @override
  String get showInNavigation => 'Mostrar na navegação';

  @override
  String get showInLatestMedia => 'Mostrar nas mídias recentes';

  @override
  String get sourceLibraries => 'Bibliotecas de Origem';

  @override
  String get sourceCollections => 'Coleções de Origem';

  @override
  String get excludedGenres => 'Gêneros Excluídos';

  @override
  String get selectAll => 'Selecionar Tudo';

  @override
  String itemsSelected(int count) {
    return '$count selecionados';
  }

  @override
  String get mediaBar => 'Barra de Mídia';

  @override
  String get enableMediaBar => 'Habilitar Barra de Mídia';

  @override
  String get showFeaturedContentSlideshow =>
      'Mostrar apresentação de conteúdo em destaque na tela inicial';

  @override
  String get contentType => 'Tipo de Conteúdo';

  @override
  String get moviesAndTvShows => 'Filmes e Séries de TV';

  @override
  String get moviesOnly => 'Apenas Filmes';

  @override
  String get tvShowsOnly => 'Apenas Séries de TV';

  @override
  String get itemCount => 'Quantidade de Itens';

  @override
  String get noneSelected => 'Nenhum selecionado';

  @override
  String get noneExcluded => 'Nenhum excluído';

  @override
  String get autoAdvance => 'Avanço Automático';

  @override
  String get autoAdvanceSlides =>
      'Avançar automaticamente para o próximo slide';

  @override
  String get autoAdvanceInterval => 'Intervalo do Avanço Automático';

  @override
  String get trailerPreview => 'Pré-visualização do Trailer';

  @override
  String get autoPlayTrailers =>
      'Reproduzir trailers automaticamente na barra de mídia após 3 segundos';

  @override
  String get episodePreview => 'Pré-visualização de Episódio';

  @override
  String get episodePreviewDescription =>
      'Reproduzir uma pré-visualização de 30 segundos em cards focados, com cursor ou pressionados longamente';

  @override
  String get previewAudio => 'Áudio da Pré-visualização';

  @override
  String get enablePreviewAudio =>
      'Habilitar áudio para pré-visualizações de trailers e episódios';

  @override
  String get latestMedia => 'Mídias Recentes';

  @override
  String get recentlyReleased => 'Lançados Recentemente';

  @override
  String get myMedia => 'Minha Mídia';

  @override
  String get myMediaSmall => 'Minha Mídia (Pequeno)';

  @override
  String get continueWatching => 'Continuar Assistindo';

  @override
  String get resumeAudio => 'Retomar Áudio';

  @override
  String get resumeBooks => 'Retomar Livros';

  @override
  String get activeRecordings => 'Gravações Ativas';

  @override
  String get playlists => 'Playlists';

  @override
  String get liveTV => 'TV ao Vivo';

  @override
  String get homeSections => 'Seções Iniciais';

  @override
  String get resetToDefaults => 'Restaurar padrões';

  @override
  String get homeRowPosterSize => 'Tamanho do Pôster nas Linhas Iniciais';

  @override
  String get perRowImageTypeSelection => 'Seleção de Tipo de Imagem por Linha';

  @override
  String get configureImageTypeForEachRow =>
      'Configurar tipo de imagem para cada linha inicial habilitada';

  @override
  String get mergeContinueWatchingAndNextUp =>
      'Mesclar Continuar Assistindo e A Seguir';

  @override
  String get combineBothRows => 'Combinar ambas as linhas em uma única seção';

  @override
  String get perRowImageType => 'Tipo de Imagem por Linha';

  @override
  String get perRowSettings => 'Configurações por Linha';

  @override
  String get autoLogin => 'Login Automático';

  @override
  String get lastUser => 'Último Usuário';

  @override
  String get specificUser => 'Usuário Específico';

  @override
  String get alwaysAuthenticate => 'Sempre Autenticar';

  @override
  String get requirePasswordWithToken =>
      'Exigir senha mesmo com token armazenado';

  @override
  String get confirmExit => 'Confirmar Saída';

  @override
  String get showConfirmationBeforeExiting =>
      'Mostrar confirmação antes de sair';

  @override
  String get blockContentWithRatings =>
      'Bloquear conteúdo com as seguintes classificações:';

  @override
  String get noContentRatingsFound =>
      'Nenhuma classificação de conteúdo foi encontrada neste servidor ainda.';

  @override
  String get couldNotLoadServerRatings =>
      'Não foi possível carregar as classificações do servidor. Mostrando apenas classificações salvas.';

  @override
  String get couldNotRefreshRatings =>
      'Não foi possível atualizar as classificações do servidor. Mostrando classificações salvas.';

  @override
  String get enablePinCode => 'Habilitar Código PIN';

  @override
  String get requirePinToAccess => 'Exigir um PIN para acessar sua conta';

  @override
  String get changePin => 'Alterar PIN';

  @override
  String get setNewPinCode => 'Definir um novo código PIN';

  @override
  String get removePin => 'Remover PIN';

  @override
  String get removePinProtection => 'Remover proteção por código PIN';

  @override
  String get screensaver => 'Proteção de Tela';

  @override
  String get inAppScreensaver => 'Proteção de Tela do App';

  @override
  String get enableBuiltInScreensaver =>
      'Habilitar a proteção de tela integrada';

  @override
  String get mode => 'Modo';

  @override
  String get libraryArt => 'Arte da Biblioteca';

  @override
  String get logo => 'Logo';

  @override
  String get clock => 'Relógio';

  @override
  String get timeout => 'Tempo Limite';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get dimmingLevel => 'Nível de Escurecimento';

  @override
  String get maxAgeRating => 'Classificação Etária Máxima';

  @override
  String get any => 'Qualquer';

  @override
  String agePlusValue(int age) {
    return '$age+';
  }

  @override
  String get requireAgeRating => 'Exigir Classificação Etária';

  @override
  String get onlyShowRatedContent => 'Mostrar apenas conteúdo classificado';

  @override
  String get showClock => 'Mostrar Relógio';

  @override
  String get displayClockDuringScreensaver =>
      'Mostrar relógio durante a proteção de tela';

  @override
  String get rottenTomatoesCritics => 'Rotten Tomatoes (Críticos)';

  @override
  String get rottenTomatoesAudience => 'Rotten Tomatoes (Público)';

  @override
  String get imdb => 'IMDb';

  @override
  String get tmdb => 'TMDB';

  @override
  String get metacritic => 'Metacritic';

  @override
  String get metacriticUser => 'Metacritic (Usuários)';

  @override
  String get trakt => 'Trakt';

  @override
  String get letterboxd => 'Letterboxd';

  @override
  String get myAnimeList => 'MyAnimeList';

  @override
  String get aniList => 'AniList';

  @override
  String get communityRating => 'Avaliação da Comunidade';

  @override
  String get ratings => 'Avaliações';

  @override
  String get additionalRatings => 'Avaliações Adicionais';

  @override
  String get showMdbListAndTmdbRatings =>
      'Mostrar avaliações do MDBList e TMDB';

  @override
  String get ratingLabels => 'Rótulos de Avaliação';

  @override
  String get showLabelsNextToIcons =>
      'Mostrar rótulos ao lado dos ícones de avaliação';

  @override
  String get ratingBadges => 'Emblemas de Avaliação';

  @override
  String get showDecorativeBadges =>
      'Mostrar emblemas decorativos atrás das avaliações';

  @override
  String get episodeRatings => 'Avaliações de Episódios';

  @override
  String get showRatingsOnEpisodes =>
      'Mostrar avaliações em episódios individuais';

  @override
  String get ratingSources => 'Fontes de Avaliação';

  @override
  String get ratingSourcesDescription =>
      'Habilite e reordene as fontes de avaliação exibidas em todo o app';

  @override
  String get pluginLabel => 'Plugin';

  @override
  String get pluginDetected => 'Plugin Detectado';

  @override
  String get pluginNotDetected => 'Plugin Não Detectado';

  @override
  String get pluginDetectedDescription =>
      'Plugin do servidor detectado. A sincronização é habilitada automaticamente na primeira vez que o plugin é encontrado.';

  @override
  String get pluginNotDetectedDescription =>
      'O plugin do servidor não foi detectado. As configurações locais ainda usam seus valores salvos ou padrões.';

  @override
  String pluginStatusVersion(String status, String version) {
    return '$status\nVersão: $version';
  }

  @override
  String get availableServices => 'Serviços Disponíveis';

  @override
  String get serverPluginSync => 'Sincronização do Plugin do Servidor';

  @override
  String get syncSettingsWithPlugin =>
      'Sincronizar configurações com o plugin do servidor';

  @override
  String get whatSyncControls => 'O que a sincronização controla';

  @override
  String get syncControlsDescription =>
      'A sincronização controla apenas se as configurações do plugin são enviadas e recebidas do servidor. A seleção de perfil e ações de sincronização de perfil estão nas configurações de Personalização quando a sincronização do plugin está habilitada.';

  @override
  String get recentRequests => 'Solicitações Recentes';

  @override
  String get recentlyAdded => 'Adicionados Recentemente';

  @override
  String get trending => 'Em Alta';

  @override
  String get popularMovies => 'Filmes Populares';

  @override
  String get movieGenres => 'Gêneros de Filmes';

  @override
  String get upcomingMovies => 'Próximos Filmes';

  @override
  String get studios => 'Estúdios';

  @override
  String get popularSeries => 'Séries Populares';

  @override
  String get seriesGenres => 'Gêneros de Séries';

  @override
  String get upcomingSeries => 'Próximas Séries';

  @override
  String get networks => 'Emissoras';

  @override
  String get resetRowsToDefaults => 'Restaurar linhas para os padrões';

  @override
  String get enableSeerr => 'Habilitar Seerr';

  @override
  String get showSeerrInNavigation =>
      'Mostrar Seerr na navegação (requer plugin do servidor)';

  @override
  String get seerrUnavailable =>
      'Indisponível porque o suporte a Seerr do plugin do servidor está desativado.';

  @override
  String get nsfwFilter => 'Filtro NSFW';

  @override
  String get hideAdultContent => 'Ocultar conteúdo adulto nos resultados';

  @override
  String loggedInAs(String username) {
    return 'Conectado como: $username';
  }

  @override
  String get discoverRows => 'Linhas de Descoberta';

  @override
  String get discoverRowsDescriptionPlugin =>
      'Arraste para reordenar. Habilite ou desabilite linhas. A ordem das linhas habilitadas sincroniza com o plugin Moonfin.';

  @override
  String get discoverRowsDescription =>
      'Arraste para reordenar. Habilite ou desabilite linhas.';

  @override
  String get enabled => 'Habilitado';

  @override
  String get hidden => 'Oculto';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String versionValue(String version) {
    return 'Versão $version';
  }

  @override
  String get openSourceLicenses => 'Licenças de Código Aberto';

  @override
  String get sourceCode => 'Código Fonte';

  @override
  String get checkForUpdatesNow => 'Verificar Atualizações Agora';

  @override
  String get checksLatestDesktopRelease =>
      'Verifica a versão desktop mais recente para esta plataforma';

  @override
  String get youAreUpToDate => 'Você está atualizado.';

  @override
  String get couldNotCheckForUpdates =>
      'Não foi possível verificar atualizações agora.';

  @override
  String get noCompatibleUpdate =>
      'Nenhum pacote de atualização compatível encontrado para esta plataforma.';

  @override
  String get updateChecksNotSupported =>
      'Verificação de atualizações não é suportada nesta plataforma.';

  @override
  String get updateNotificationsDisabled =>
      'Notificações de atualização estão desabilitadas.';

  @override
  String get pleaseWaitBeforeChecking =>
      'Aguarde antes de verificar novamente.';

  @override
  String get latestUpdateAlreadyShown =>
      'A atualização mais recente já foi exibida.';

  @override
  String get updateAvailable => 'Atualização disponível.';

  @override
  String updateAvailableVersion(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String get updateNotifications => 'Notificações de Atualização';

  @override
  String get showWhenUpdatesAvailable =>
      'Mostrar quando atualizações estiverem disponíveis';

  @override
  String get navigation => 'Navegação';

  @override
  String get watchedIndicatorsBackdrops =>
      'Indicadores de assistido, panos de fundo';

  @override
  String get focusColorWatchedIndicatorsBackdrops =>
      'Cor de foco, indicadores de assistido, panos de fundo';

  @override
  String get navbarStyleToolbarAppearance =>
      'Estilo da barra de navegação, botões da barra de ferramentas, aparência';

  @override
  String get reorderToggleHomeRows => 'Reordenar e alternar linhas iniciais';

  @override
  String get featuredContentAppearance => 'Conteúdo em destaque, aparência';

  @override
  String get posterSizeImageTypeFolderView =>
      'Tamanho do pôster, tipo de imagem, visualização de pastas';

  @override
  String get mdbListTmdbRatingSources => 'MDBList, TMDB e fontes de avaliação';

  @override
  String gbValue(String value) {
    return '$value GB';
  }

  @override
  String get clear => 'Limpar';

  @override
  String get browse => 'Navegar';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get seerrAvailableStatus => 'Disponível';

  @override
  String get seerrRequestedStatus => 'Solicitado';

  @override
  String itemsCount(int count) {
    return '$count Itens';
  }

  @override
  String get seerrSettings => 'Configurações do Seerr';

  @override
  String get requestMore => 'Solicitar Mais';

  @override
  String get request => 'Solicitar';

  @override
  String get cancelRequest => 'Cancelar Solicitação';

  @override
  String get playInMoonfin => 'Reproduzir no Moonfin';

  @override
  String requestedByName(String name) {
    return 'Solicitado por $name';
  }

  @override
  String get approve => 'Aprovar';

  @override
  String get declineAction => 'Recusar';

  @override
  String get similar => 'Semelhantes';

  @override
  String get recommendations => 'Recomendações';

  @override
  String cancelRequestForTitle(String title) {
    return 'Cancelar solicitação de \"$title\"?';
  }

  @override
  String cancelCountRequestsForTitle(int count, String title) {
    return 'Cancelar $count solicitações de \"$title\"?';
  }

  @override
  String get keep => 'Manter';

  @override
  String get itemNotFoundInLibrary =>
      'Item não encontrado na sua biblioteca Moonfin';

  @override
  String get errorSearchingLibrary => 'Erro ao pesquisar biblioteca';

  @override
  String budgetAmount(String amount) {
    return 'Orçamento: \$$amount';
  }

  @override
  String revenueAmount(String amount) {
    return 'Receita: \$$amount';
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
  String get submitRequest => 'Enviar Solicitação';

  @override
  String get allSeasons => 'Todas as Temporadas';

  @override
  String get advancedOptions => 'Opções Avançadas';

  @override
  String get noServiceServersConfigured =>
      'Nenhum servidor de serviço configurado';

  @override
  String get server => 'Servidor';

  @override
  String get qualityProfile => 'Perfil de Qualidade';

  @override
  String get rootFolder => 'Pasta Raiz';

  @override
  String get showMore => 'Mostrar Mais';

  @override
  String get appearances => 'Aparições';

  @override
  String get crewSection => 'Equipe';

  @override
  String ageValue(int age) {
    return 'idade $age';
  }

  @override
  String get noRequests => 'Nenhuma solicitação';

  @override
  String get pendingStatus => 'Pendente';

  @override
  String get declinedStatus => 'Recusado';

  @override
  String get partiallyAvailable => 'Parcialmente Disponível';

  @override
  String get downloadingStatus => 'Baixando';

  @override
  String get approvedStatus => 'Aprovado';

  @override
  String get access => 'Acesso';

  @override
  String get add => 'Adicionar';

  @override
  String get address => 'Endereço';

  @override
  String get analytics => 'Análises';

  @override
  String get catalog => 'Catálogo';

  @override
  String get content => 'Conteúdo';

  @override
  String get copy => 'Copiar';

  @override
  String get create => 'Criar';

  @override
  String get disable => 'Desabilitar';

  @override
  String get done => 'Concluído';

  @override
  String get edit => 'Editar';

  @override
  String get encoding => 'Codificação';

  @override
  String get error => 'Erro';

  @override
  String get forward => 'Avançar';

  @override
  String get general => 'Geral';

  @override
  String get go => 'Ir';

  @override
  String get install => 'Instalar';

  @override
  String get installed => 'Instalado';

  @override
  String get interval => 'Intervalo';

  @override
  String get name => 'Nome';

  @override
  String get networking => 'Rede';

  @override
  String get next => 'Próximo';

  @override
  String get path => 'Caminho';

  @override
  String get paused => 'Pausado';

  @override
  String get permissions => 'Permissões';

  @override
  String get processing => 'Processando';

  @override
  String get profile => 'Perfil';

  @override
  String get provider => 'Provedor';

  @override
  String get refresh => 'Atualizar';

  @override
  String get remote => 'Remoto';

  @override
  String get rename => 'Renomear';

  @override
  String get revoke => 'Revogar';

  @override
  String get role => 'Papel';

  @override
  String get root => 'Raiz';

  @override
  String get run => 'Executar';

  @override
  String get search => 'Pesquisar';

  @override
  String get select => 'Selecionar';

  @override
  String get send => 'Enviar';

  @override
  String get sessions => 'Sessões';

  @override
  String get set => 'Definir';

  @override
  String get status => 'Status';

  @override
  String get stop => 'Parar';

  @override
  String get streaming => 'Transmissão';

  @override
  String get time => 'Hora';

  @override
  String get trickplay => 'Trickplay';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get up => 'Subir';

  @override
  String get update => 'Atualizar';

  @override
  String get upload => 'Enviar';

  @override
  String get unmute => 'Ativar som';

  @override
  String get mute => 'Silenciar';

  @override
  String get branding => 'Marca';

  @override
  String get adminDrawerDashboard => 'Painel';

  @override
  String get adminDrawerAnalytics => 'Análises';

  @override
  String get adminDrawerSettings => 'Configurações';

  @override
  String get adminDrawerBranding => 'Marca';

  @override
  String get adminDrawerUsers => 'Usuários';

  @override
  String get adminDrawerLibraries => 'Bibliotecas';

  @override
  String get adminDrawerTranscoding => 'Transcodificação';

  @override
  String get adminDrawerResume => 'Retomar';

  @override
  String get adminDrawerStreaming => 'Transmissão';

  @override
  String get adminDrawerTrickplay => 'Trickplay';

  @override
  String get adminDrawerDevices => 'Dispositivos';

  @override
  String get adminDrawerActivity => 'Atividade';

  @override
  String get adminDrawerNetworking => 'Rede';

  @override
  String get adminDrawerApiKeys => 'Chaves de API';

  @override
  String get adminDrawerBackups => 'Backups';

  @override
  String get adminDrawerLogs => 'Logs';

  @override
  String get adminDrawerScheduledTasks => 'Tarefas Agendadas';

  @override
  String get adminDrawerPlugins => 'Plugins';

  @override
  String get adminDrawerRepositories => 'Repositórios';

  @override
  String get adminDrawerLiveTv => 'TV ao Vivo';

  @override
  String get adminExitTooltip => 'Sair do Administrador';

  @override
  String get adminDashboardLoadFailed => 'Falha ao carregar o painel';

  @override
  String get adminMediaOverview => 'Visão Geral da Mídia';

  @override
  String get adminMediaTotalsError =>
      'Não foi possível carregar os totais de mídia do servidor.';

  @override
  String get adminMediaOverviewSubtitle =>
      'Uma visão rápida de quanto conteúdo há neste servidor.';

  @override
  String adminPluginUpdatesAvailable(int count) {
    return 'Atualizações de plugins disponíveis: $count';
  }

  @override
  String adminPluginsRequiringRestart(int count) {
    return 'Plugins que precisam de reinício: $count';
  }

  @override
  String adminFailedScheduledTasks(int count) {
    return 'Tarefas agendadas com falha: $count';
  }

  @override
  String adminRecentAlertEntries(int count) {
    return 'Entradas recentes de aviso/erro: $count';
  }

  @override
  String get analyticsMediaDistribution => 'Distribuição de Mídia';

  @override
  String get analyticsVideoCodecs => 'Codecs de Vídeo';

  @override
  String get analyticsAudioCodecs => 'Codecs de Áudio';

  @override
  String get analyticsContainers => 'Contêineres';

  @override
  String get analyticsTopGenres => 'Gêneros Principais';

  @override
  String get analyticsReleaseYears => 'Anos de Lançamento';

  @override
  String get analyticsContentRatings => 'Classificações de Conteúdo';

  @override
  String get analyticsRuntimeBuckets => 'Faixas de Duração';

  @override
  String get analyticsFileFormats => 'Formatos de Arquivo';

  @override
  String get analyticsNoData => 'Nenhum Dado Disponível.';

  @override
  String get adminServerInfo => 'Informações do Servidor';

  @override
  String get adminRestartPending => 'Reinício Pendente';

  @override
  String get adminServerPaths => 'Caminhos do Servidor';

  @override
  String get adminServerActions => 'Ações do Servidor';

  @override
  String get adminRestartServer => 'Reiniciar Servidor';

  @override
  String get adminShutdownServer => 'Desligar Servidor';

  @override
  String get adminScanLibraries => 'Escanear Bibliotecas';

  @override
  String get adminLibraryScanStarted => 'Escaneamento da biblioteca iniciado';

  @override
  String errorGeneric(String error) {
    return 'Erro: $error';
  }

  @override
  String get adminServerRebootInProgress => 'Reinício do servidor em andamento';

  @override
  String get adminServerRebootMessage =>
      'Reinício do servidor em andamento, por favor reinicie o Moonfin';

  @override
  String get adminActiveSessions => 'Sessões Ativas';

  @override
  String get adminSessionsLoadFailed => 'Falha ao carregar sessões';

  @override
  String get adminNoActiveSessions => 'Nenhuma sessão ativa';

  @override
  String get adminRecentActivity => 'Atividade Recente';

  @override
  String get adminNoRecentActivity => 'Nenhuma atividade recente';

  @override
  String adminCommandFailed(String error) {
    return 'Comando falhou: $error';
  }

  @override
  String get adminSendMessage => 'Enviar Mensagem';

  @override
  String get adminMessageTextHint => 'Texto da mensagem';

  @override
  String get adminSetVolume => 'Definir Volume';

  @override
  String get sessionPrev => 'Anterior';

  @override
  String get sessionRewind => 'Retroceder';

  @override
  String get sessionForward => 'Avançar';

  @override
  String get sessionNext => 'Próximo';

  @override
  String get sessionVolumeDown => 'Vol –';

  @override
  String get sessionVolumeUp => 'Vol +';

  @override
  String get nowPlaying => 'Reproduzindo Agora';

  @override
  String get volume => 'Volume';

  @override
  String get actions => 'Ações';

  @override
  String get videoCodec => 'Codec de Vídeo';

  @override
  String get audioCodec => 'Codec de Áudio';

  @override
  String get hwAccel => 'Aceleração HW';

  @override
  String get completion => 'Conclusão';

  @override
  String get direct => 'Direto';

  @override
  String get adminDisconnect => 'Desconectar';

  @override
  String get adminClearDates => 'Limpar datas';

  @override
  String adminActivityLoadFailed(String error) {
    return 'Falha ao carregar log de atividades: $error';
  }

  @override
  String get adminNoActivityEntries => 'Nenhuma entrada de atividade';

  @override
  String get adminEditDeviceName => 'Editar Nome do Dispositivo';

  @override
  String get adminCustomName => 'Nome Personalizado';

  @override
  String get adminDeviceNameUpdated => 'Nome do dispositivo atualizado';

  @override
  String adminDeviceUpdateFailed(String error) {
    return 'Falha ao atualizar dispositivo: $error';
  }

  @override
  String get adminDeleteDevice => 'Excluir Dispositivo';

  @override
  String get adminDeviceDeleted => 'Dispositivo excluído';

  @override
  String adminDeviceDeleteFailed(String error) {
    return 'Falha ao excluir dispositivo: $error';
  }

  @override
  String get adminDevicesLoadFailed => 'Falha ao carregar dispositivos';

  @override
  String get adminSearchDevices => 'Pesquisar dispositivos';

  @override
  String get adminThisDevice => 'Este Dispositivo';

  @override
  String get adminEditName => 'Editar Nome';

  @override
  String get adminLibrariesLoadFailed => 'Falha ao carregar bibliotecas';

  @override
  String get adminNoLibraries => 'Nenhuma biblioteca configurada';

  @override
  String get adminScanAllLibraries => 'Escanear Todas as Bibliotecas';

  @override
  String get adminAddLibrary => 'Adicionar Biblioteca';

  @override
  String adminScanFailed(String error) {
    return 'Falha ao iniciar escaneamento: $error';
  }

  @override
  String get adminRenameLibrary => 'Renomear Biblioteca';

  @override
  String get adminNewName => 'Novo nome';

  @override
  String adminLibraryRenamed(String name) {
    return 'Biblioteca renomeada para \"$name\"';
  }

  @override
  String adminRenameFailed(String error) {
    return 'Falha ao renomear: $error';
  }

  @override
  String get adminDeleteLibrary => 'Excluir Biblioteca';

  @override
  String adminLibraryDeleted(String name) {
    return 'Biblioteca \"$name\" excluída';
  }

  @override
  String adminLibraryDeleteFailed(String error) {
    return 'Falha ao excluir biblioteca: $error';
  }

  @override
  String adminAddPathFailed(String error) {
    return 'Falha ao adicionar caminho: $error';
  }

  @override
  String get adminRemovePath => 'Remover Caminho';

  @override
  String adminRemovePathConfirm(String path) {
    return 'Remover \"$path\" desta biblioteca?';
  }

  @override
  String adminRemovePathFailed(String error) {
    return 'Falha ao remover caminho: $error';
  }

  @override
  String get adminLibraryOptionsSaved => 'Opções da biblioteca salvas';

  @override
  String adminLibraryOptionsSaveFailed(String error) {
    return 'Falha ao salvar opções: $error';
  }

  @override
  String get adminLibraryLoadFailed => 'Falha ao carregar biblioteca';

  @override
  String get adminNoMediaPaths => 'Nenhum caminho de mídia configurado';

  @override
  String get adminAddPath => 'Adicionar Caminho';

  @override
  String get adminBrowseFilesystem =>
      'Navegar pelo sistema de arquivos do servidor:';

  @override
  String get adminSaveOptions => 'Salvar Opções';

  @override
  String get adminPreferredMetadataLanguage => 'Idioma preferido de metadados';

  @override
  String get adminMetadataLanguageHint => 'ex: en, de, fr';

  @override
  String get adminMetadataCountryCode => 'Código do país para metadados';

  @override
  String get adminMetadataCountryHint => 'ex: US, DE, FR';

  @override
  String get adminLibraryNameRequired => 'O nome da biblioteca é obrigatório';

  @override
  String adminLibraryCreateFailed(String error) {
    return 'Falha ao criar biblioteca: $error';
  }

  @override
  String get adminLibraryName => 'Nome da Biblioteca';

  @override
  String get adminSelectedPaths => 'Caminhos Selecionados:';

  @override
  String get adminNoPathsAdded =>
      'Nenhum caminho adicionado (pode ser adicionado depois)';

  @override
  String get adminCreateLibrary => 'Criar Biblioteca';

  @override
  String get paths => 'Caminhos:';

  @override
  String get adminDisableUser => 'Desabilitar Usuário';

  @override
  String get adminEnableUser => 'Habilitar Usuário';

  @override
  String adminDisableUserConfirm(String name) {
    return 'Desabilitar $name? Não poderá fazer login.';
  }

  @override
  String adminEnableUserConfirm(String name) {
    return 'Habilitar $name? Poderá fazer login novamente.';
  }

  @override
  String adminUserDisabled(String name) {
    return 'Usuário \"$name\" desabilitado';
  }

  @override
  String adminUserEnabled(String name) {
    return 'Usuário \"$name\" habilitado';
  }

  @override
  String adminUserPolicyUpdateFailed(String error) {
    return 'Falha ao atualizar política do usuário: $error';
  }

  @override
  String get adminUsersLoadFailed => 'Falha ao carregar usuários';

  @override
  String get adminSearchUsers => 'Pesquisar usuários';

  @override
  String get adminEditUser => 'Editar Usuário';

  @override
  String get adminAddUser => 'Adicionar Usuário';

  @override
  String adminUserCreateFailed(String error) {
    return 'Falha ao criar usuário: $error';
  }

  @override
  String get adminCreateUser => 'Criar Usuário';

  @override
  String get adminPasswordOptional => 'Senha (opcional)';

  @override
  String get adminUsernameRequired => 'O nome de usuário não pode estar vazio';

  @override
  String get adminNoProfileChanges => 'Nenhuma alteração de perfil para salvar';

  @override
  String get adminProfileSaved => 'Perfil salvo';

  @override
  String adminSaveFailed(String error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get adminPermissionsSaved => 'Permissões salvas';

  @override
  String get adminPasswordsMismatch => 'As senhas não coincidem';

  @override
  String adminFailed(String error) {
    return 'Falhou: $error';
  }

  @override
  String get adminUserLoadFailed => 'Falha ao carregar usuário';

  @override
  String get adminBackToUsers => 'Voltar para Usuários';

  @override
  String get adminSaveProfile => 'Salvar Perfil';

  @override
  String get adminDeleteUser => 'Excluir Usuário';

  @override
  String get admin => 'Administrador';

  @override
  String get adminFullAccessWarning =>
      'Administradores têm acesso completo ao servidor. Conceda com cautela.';

  @override
  String get administrator => 'Administrador';

  @override
  String get adminHiddenUser => 'Usuário oculto';

  @override
  String get adminAllowMediaPlayback => 'Permitir reprodução de mídia';

  @override
  String get adminAllowAudioTranscoding => 'Permitir transcodificação de áudio';

  @override
  String get adminAllowVideoTranscoding => 'Permitir transcodificação de vídeo';

  @override
  String get adminAllowRemuxing => 'Permitir remuxing';

  @override
  String get adminForceRemoteTranscoding =>
      'Forçar transcodificação de fonte remota';

  @override
  String get adminAllowContentDeletion => 'Permitir exclusão de conteúdo';

  @override
  String get adminAllowContentDownloading => 'Permitir download de conteúdo';

  @override
  String get adminAllowPublicSharing => 'Permitir compartilhamento público';

  @override
  String get adminAllowRemoteControl =>
      'Permitir controle remoto de outros usuários';

  @override
  String get adminAllowSharedDeviceControl =>
      'Permitir controle de dispositivo compartilhado';

  @override
  String get adminAllowRemoteAccess => 'Permitir acesso remoto';

  @override
  String get adminRemoteBitrateLimit =>
      'Limite de bitrate do cliente remoto (bps)';

  @override
  String get adminLeaveEmptyNoLimit => 'Deixe vazio para sem limite';

  @override
  String get adminMaxActiveSessions => 'Máximo de sessões ativas';

  @override
  String get adminAllowLiveTvAccess => 'Permitir acesso à TV ao Vivo';

  @override
  String get adminAllowLiveTvManagement =>
      'Permitir gerenciamento de TV ao Vivo';

  @override
  String get adminAllowCollectionManagement =>
      'Permitir gerenciamento de coleções';

  @override
  String get adminAllowSubtitleManagement =>
      'Permitir gerenciamento de legendas';

  @override
  String get adminAllowLyricManagement => 'Permitir gerenciamento de letras';

  @override
  String get adminSavePermissions => 'Salvar Permissões';

  @override
  String get adminEnableAllLibraryAccess =>
      'Habilitar acesso a todas as bibliotecas';

  @override
  String get adminSaveAccess => 'Salvar Acesso';

  @override
  String get adminChangePassword => 'Alterar Senha';

  @override
  String get adminNewPassword => 'Nova Senha';

  @override
  String get adminConfirmPassword => 'Confirmar Senha';

  @override
  String get adminSetPassword => 'Definir Senha';

  @override
  String get adminResetPassword => 'Redefinir Senha';

  @override
  String adminDeleteUserConfirm(String name) {
    return 'Tem certeza de que deseja excluir $name?';
  }

  @override
  String adminUserDeleted(String name) {
    return 'Usuário \"$name\" excluído';
  }

  @override
  String adminUserDeleteFailed(String error) {
    return 'Falha ao excluir usuário: $error';
  }

  @override
  String get adminCreateApiKey => 'Criar Chave de API';

  @override
  String get adminAppName => 'Nome do app';

  @override
  String get adminApiKeyCreated => 'Chave de API Criada';

  @override
  String get adminApiKeyCreatedNoToken =>
      'Chave criada com sucesso. O servidor não retornou o token. Verifique as chaves de API do servidor.';

  @override
  String get adminKeyCopied => 'Chave copiada para a área de transferência';

  @override
  String adminApiKeyCreateFailed(String error) {
    return 'Falha ao criar chave: $error';
  }

  @override
  String get adminKeyTokenMissing =>
      'Token da chave ausente na resposta do servidor';

  @override
  String get adminRevokeApiKey => 'Revogar Chave de API';

  @override
  String adminRevokeKeyConfirm(String name) {
    return 'Revogar chave para $name?';
  }

  @override
  String get adminApiKeyRevoked => 'Chave de API revogada';

  @override
  String adminApiKeyRevokeFailed(String error) {
    return 'Falha ao revogar chave: $error';
  }

  @override
  String get adminApiKeysLoadFailed => 'Falha ao carregar chaves de API';

  @override
  String get adminCreateKey => 'Criar Chave';

  @override
  String get adminNoApiKeys => 'Nenhuma chave de API encontrada';

  @override
  String get adminCreatingBackup => 'Criando backup...';

  @override
  String get adminBackupCreated => 'Backup criado com sucesso';

  @override
  String adminBackupCreateFailed(String error) {
    return 'Falha ao criar backup: $error';
  }

  @override
  String get adminBackupPathMissing =>
      'Caminho do backup ausente na resposta do servidor';

  @override
  String adminBackupManifest(String name) {
    return 'Manifesto: $name';
  }

  @override
  String adminManifestLoadFailed(String error) {
    return 'Falha ao carregar manifesto: $error';
  }

  @override
  String get adminConfirmRestore => 'Confirmar Restauração';

  @override
  String get adminRestoringBackup => 'Restaurando backup...';

  @override
  String adminRestoreFailed(String error) {
    return 'Falha ao restaurar backup: $error';
  }

  @override
  String get adminBackupsLoadFailed => 'Falha ao carregar backups';

  @override
  String get adminCreateBackup => 'Criar Backup';

  @override
  String get adminNoBackups => 'Nenhum backup encontrado';

  @override
  String get adminViewDetails => 'Ver Detalhes';

  @override
  String get restore => 'Restaurar';

  @override
  String get adminLogsLoadFailed => 'Falha ao carregar logs do servidor';

  @override
  String get adminNoLogFiles => 'Nenhum arquivo de log encontrado';

  @override
  String get adminLogCopied => 'Log copiado para a área de transferência';

  @override
  String get adminSaveLogFile => 'Salvar arquivo de log';

  @override
  String adminSavedTo(String path) {
    return 'Salvo em $path';
  }

  @override
  String adminFileSaveFailed(String error) {
    return 'Falha ao salvar arquivo: $error';
  }

  @override
  String adminLogFileLoadFailed(String fileName) {
    return 'Falha ao carregar $fileName';
  }

  @override
  String get adminSearchInLog => 'Pesquisar no log';

  @override
  String get adminNoMatchingLines => 'Nenhuma linha correspondente';

  @override
  String adminTasksLoadFailed(String error) {
    return 'Falha ao carregar tarefas: $error';
  }

  @override
  String get adminNoScheduledTasks => 'Nenhuma tarefa agendada encontrada';

  @override
  String get adminNoTasksMatchFilter =>
      'Nenhuma tarefa corresponde ao filtro atual';

  @override
  String adminTaskStartFailed(String error) {
    return 'Falha ao iniciar tarefa: $error';
  }

  @override
  String adminTaskStopFailed(String error) {
    return 'Falha ao parar tarefa: $error';
  }

  @override
  String adminTaskLoadFailed(String error) {
    return 'Falha ao carregar tarefa: $error';
  }

  @override
  String get adminRunNow => 'Executar Agora';

  @override
  String adminTriggerRemoveFailed(String error) {
    return 'Falha ao remover acionador: $error';
  }

  @override
  String adminTriggerAddFailed(String error) {
    return 'Falha ao adicionar acionador: $error';
  }

  @override
  String get adminLastExecution => 'Última Execução';

  @override
  String get adminTriggers => 'Acionadores';

  @override
  String get adminAddTrigger => 'Adicionar Acionador';

  @override
  String get adminNoTriggers => 'Nenhum acionador configurado';

  @override
  String get adminTriggerType => 'Tipo de Acionador';

  @override
  String get adminTimeLimit => 'Limite de tempo (opcional)';

  @override
  String get adminNoLimit => 'Sem limite';

  @override
  String adminHours(String hours) {
    return '$hours hora(s)';
  }

  @override
  String get adminDayOfWeek => 'Dia da semana';

  @override
  String get adminSearchPlugins => 'Pesquisar plugins...';

  @override
  String adminPluginToggleFailed(String error) {
    return 'Falha ao alternar plugin: $error';
  }

  @override
  String get adminUninstallPlugin => 'Desinstalar Plugin';

  @override
  String adminUninstallPluginConfirm(String name) {
    return 'Tem certeza de que deseja desinstalar \"$name\"?';
  }

  @override
  String adminPluginUninstallFailed(String error) {
    return 'Falha ao desinstalar plugin: $error';
  }

  @override
  String adminPackageInstallFailed(String error) {
    return 'Falha ao instalar pacote: $error';
  }

  @override
  String adminPluginUpdateFailed(String error) {
    return 'Falha ao instalar atualização: $error';
  }

  @override
  String adminPluginsLoadFailed(String error) {
    return 'Falha ao carregar plugins: $error';
  }

  @override
  String get adminNoPluginsMatchSearch =>
      'Nenhum plugin corresponde à sua pesquisa';

  @override
  String get adminNoPluginsInstalled => 'Nenhum plugin instalado';

  @override
  String adminInstallUpdate(String version) {
    return 'Instalar atualização (v$version)';
  }

  @override
  String adminCatalogLoadFailed(String error) {
    return 'Falha ao carregar catálogo: $error';
  }

  @override
  String get adminNoPackagesMatchSearch =>
      'Nenhum pacote corresponde à sua pesquisa';

  @override
  String get adminNoPackagesAvailable => 'Nenhum pacote disponível';

  @override
  String get adminExperimentalIntegration => 'Integração Experimental';

  @override
  String get adminExperimentalWarning =>
      'A integração de configurações de plugins ainda é experimental. Algumas páginas de configurações podem não ser renderizadas corretamente.';

  @override
  String get continueAction => 'Continuar';

  @override
  String adminPluginRemoveAfterRestart(String name) {
    return '\"$name\" será removido após reinício do servidor';
  }

  @override
  String adminUninstallFailed(String error) {
    return 'Falha ao desinstalar: $error';
  }

  @override
  String adminPluginUpdating(String name, String version) {
    return 'Atualizando \"$name\" para v$version...';
  }

  @override
  String get adminMissingAuthToken =>
      'Não foi possível abrir configurações: token de autenticação ausente.';

  @override
  String adminPluginLoadFailed(String error) {
    return 'Falha ao carregar plugin: $error';
  }

  @override
  String get adminPluginNotFound => 'Plugin não encontrado';

  @override
  String adminPluginVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get adminEnablePlugin => 'Habilitar Plugin';

  @override
  String get adminPluginSettingsPage => 'Página de configurações do plugin';

  @override
  String get adminRevisionHistory => 'Histórico de Revisões';

  @override
  String get adminNoChangelog => 'Nenhum changelog disponível.';

  @override
  String get adminRemoveRepository => 'Remover Repositório';

  @override
  String adminRemoveRepositoryConfirm(String name) {
    return 'Tem certeza de que deseja remover \"$name\"?';
  }

  @override
  String adminRepositoriesSaveFailed(String error) {
    return 'Falha ao salvar repositórios: $error';
  }

  @override
  String adminRepositoriesLoadFailed(String error) {
    return 'Falha ao carregar repositórios: $error';
  }

  @override
  String get adminRepositoryNameHint => 'ex: Jellyfin Stable';

  @override
  String get adminRepositoryUrl => 'URL do Repositório';

  @override
  String get adminAddEntry => 'Adicionar entrada';

  @override
  String get adminInvalidUrl => 'URL inválida';

  @override
  String adminPluginSettingsLoadFailed(String error) {
    return 'Não foi possível carregar configurações do plugin: $error';
  }

  @override
  String adminCouldNotOpenUrl(String uri) {
    return 'Não foi possível abrir $uri';
  }

  @override
  String get adminOpenInBrowser => 'Abrir no Navegador';

  @override
  String get adminOpenExternally => 'Abrir externamente';

  @override
  String get adminGeneralSettings => 'Configurações Gerais';

  @override
  String get adminServerName => 'Nome do servidor';

  @override
  String get adminPreferredMetadataCountry => 'País preferido para metadados';

  @override
  String get adminCachePath => 'Caminho do cache';

  @override
  String get adminMetadataPath => 'Caminho dos metadados';

  @override
  String get adminLibraryScanConcurrency =>
      'Concorrência de escaneamento de biblioteca';

  @override
  String get adminParallelImageEncodingLimit =>
      'Limite de codificação de imagens paralelas';

  @override
  String get adminSlowResponseThreshold => 'Limite de resposta lenta (ms)';

  @override
  String get adminBrandingSaved => 'Configurações de marca salvas';

  @override
  String get adminBrandingLoadFailed =>
      'Falha ao carregar configurações de marca';

  @override
  String get adminLoginDisclaimer => 'Aviso no login';

  @override
  String get adminLoginDisclaimerHint =>
      'HTML exibido abaixo do formulário de login';

  @override
  String get adminCustomCss => 'CSS Personalizado';

  @override
  String get adminCustomCssHint => 'CSS personalizado aplicado à interface web';

  @override
  String get adminEnableSplashScreen => 'Habilitar tela de apresentação';

  @override
  String get adminStreamingSaved => 'Configurações de transmissão salvas';

  @override
  String get adminStreamingLoadFailed =>
      'Falha ao carregar configurações de transmissão';

  @override
  String get adminStreamingDescription =>
      'Defina limites globais de bitrate de transmissão para conexões remotas.';

  @override
  String get adminRemoteBitrateLimitMbps =>
      'Limite de bitrate do cliente remoto (Mbps)';

  @override
  String get adminLeaveEmptyForUnlimited => 'Deixe vazio ou 0 para ilimitado';

  @override
  String get adminPlaybackSaved => 'Configurações de reprodução salvas';

  @override
  String get adminPlaybackLoadFailed =>
      'Falha ao carregar configurações de reprodução';

  @override
  String get adminPlaybackTranscoding => 'Reprodução / Transcodificação';

  @override
  String get adminHardwareAcceleration => 'Aceleração de hardware';

  @override
  String get adminVaapiDevice => 'Dispositivo VA-API';

  @override
  String get adminEnableHardwareEncoding =>
      'Habilitar codificação por hardware';

  @override
  String get adminEnableHardwareDecoding =>
      'Habilitar decodificação por hardware para:';

  @override
  String get adminEncodingThreads => 'Threads de codificação';

  @override
  String get adminAutomatic => '0 = automático';

  @override
  String get adminTranscodingTempPath =>
      'Caminho temporário de transcodificação';

  @override
  String get adminEnableFallbackFont => 'Habilitar fonte alternativa';

  @override
  String get adminFallbackFontPath => 'Caminho da fonte alternativa';

  @override
  String get adminAllowSegmentDeletion => 'Permitir exclusão de segmentos';

  @override
  String get adminSegmentKeepSeconds => 'Manter segmento (segundos)';

  @override
  String get adminThrottleBuffering => 'Limitar buffering';

  @override
  String get adminTrickplaySaved => 'Configurações de trickplay salvas';

  @override
  String get adminTrickplayLoadFailed =>
      'Falha ao carregar configurações de trickplay';

  @override
  String get adminEnableHardwareAcceleration =>
      'Habilitar aceleração de hardware';

  @override
  String get adminEnableKeyFrameExtraction =>
      'Habilitar extração apenas de quadros-chave';

  @override
  String get adminKeyFrameSubtitle => 'Mais rápido, mas menor precisão';

  @override
  String get adminScanBehavior => 'Comportamento de escaneamento';

  @override
  String get adminProcessPriority => 'Prioridade do processo';

  @override
  String get adminImageSettings => 'Configurações de Imagem';

  @override
  String get adminIntervalMs => 'Intervalo (ms)';

  @override
  String get adminCaptureFrameSubtitle => 'Frequência de captura de quadros';

  @override
  String get adminWidthResolutions => 'Resoluções de largura';

  @override
  String get adminTileWidth => 'Largura do mosaico';

  @override
  String get adminTileHeight => 'Altura do mosaico';

  @override
  String get adminQualitySubtitle =>
      'Valores menores = melhor qualidade, arquivos maiores';

  @override
  String get adminProcessThreads => 'Threads de processo';

  @override
  String get adminResumeSaved => 'Configurações de retomada salvas';

  @override
  String get adminResumeLoadFailed =>
      'Falha ao carregar configurações de retomada';

  @override
  String get adminResumeDescription =>
      'Configure quando o conteúdo deve ser marcado como parcialmente reproduzido ou totalmente reproduzido.';

  @override
  String get adminMinResumePercentage => 'Porcentagem mínima de retomada';

  @override
  String get adminMinResumeSubtitle =>
      'O conteúdo deve ser reproduzido além desta porcentagem para salvar o progresso';

  @override
  String get adminMaxResumePercentage => 'Porcentagem máxima de retomada';

  @override
  String get adminMaxResumeSubtitle =>
      'O conteúdo é considerado totalmente reproduzido após esta porcentagem';

  @override
  String get adminMinResumeDuration => 'Duração mínima de retomada (segundos)';

  @override
  String get adminMinResumeDurationSubtitle =>
      'Itens mais curtos que isso não são retomáveis';

  @override
  String get adminMinAudiobookResume =>
      'Porcentagem mínima de retomada de audiolivros';

  @override
  String get adminMaxAudiobookResume =>
      'Porcentagem máxima de retomada de audiolivros';

  @override
  String get adminNetworkingSaved =>
      'Configurações de rede salvas. Pode ser necessário reiniciar o servidor.';

  @override
  String get adminNetworkingLoadFailed =>
      'Falha ao carregar configurações de rede';

  @override
  String get adminNetworkingWarning =>
      'Alterações nas configurações de rede podem exigir reinício do servidor.';

  @override
  String get adminEnableRemoteAccess => 'Habilitar acesso remoto';

  @override
  String get ports => 'Portas';

  @override
  String get adminHttpPort => 'Porta HTTP';

  @override
  String get adminHttpsPort => 'Porta HTTPS';

  @override
  String get adminPublicHttpsPort => 'Porta HTTPS pública';

  @override
  String get adminBaseUrl => 'URL Base';

  @override
  String get adminBaseUrlHint => 'ex: /jellyfin';

  @override
  String get https => 'HTTPS';

  @override
  String get adminEnableHttps => 'Habilitar HTTPS';

  @override
  String get adminLocalNetwork => 'Rede Local';

  @override
  String get adminLocalNetworkAddresses => 'Endereços de rede local';

  @override
  String get adminKnownProxies => 'Proxies conhecidos';

  @override
  String get adminRemoteIpFilter => 'Filtro de IP Remoto';

  @override
  String get adminRemoteIpFilterEntries => 'Filtro de IP remoto';

  @override
  String get adminCertificatePath => 'Caminho do certificado';

  @override
  String get whitelist => 'Lista branca';

  @override
  String get blacklist => 'Lista negra';

  @override
  String get notSet => 'Não definido';

  @override
  String get adminMetadataSaved => 'Metadados salvos';

  @override
  String adminMetadataLoadFailed(String error) {
    return 'Falha ao carregar metadados: $error';
  }

  @override
  String adminMetadataSaveFailed(String error) {
    return 'Falha ao salvar metadados: $error';
  }

  @override
  String get adminRefreshMetadata => 'Atualizar Metadados';

  @override
  String get recursive => 'Recursivo';

  @override
  String get adminReplaceAllMetadata => 'Substituir todos os metadados';

  @override
  String get adminReplaceAllImages => 'Substituir todas as imagens';

  @override
  String get adminMetadataRefreshRequested =>
      'Atualização de metadados solicitada';

  @override
  String adminMetadataRefreshFailed(String error) {
    return 'Falha ao atualizar metadados: $error';
  }

  @override
  String get adminSearchRemotePerson => 'Pesquisar Pessoa Remota';

  @override
  String get adminNoRemoteMatches =>
      'Nenhuma correspondência remota encontrada';

  @override
  String get adminRemoteResults => 'Resultados Remotos';

  @override
  String get adminRemoteMetadataApplied => 'Metadados remotos aplicados';

  @override
  String adminRemoteSearchFailed(String error) {
    return 'Pesquisa remota falhou: $error';
  }

  @override
  String get adminUpdateContentType => 'Atualizar Tipo de Conteúdo';

  @override
  String get adminContentType => 'Tipo de conteúdo';

  @override
  String get adminContentTypeUpdated => 'Tipo de conteúdo atualizado';

  @override
  String adminContentTypeUpdateFailed(String error) {
    return 'Falha ao atualizar tipo de conteúdo: $error';
  }

  @override
  String get adminMetadataEditorLoadFailed =>
      'Falha ao carregar editor de metadados';

  @override
  String get adminNoPeopleEntries => 'Nenhuma entrada de pessoas';

  @override
  String get adminNoExternalIds => 'Nenhum ID externo disponível';

  @override
  String adminImageUpdated(String imageType) {
    return 'Imagem $imageType atualizada';
  }

  @override
  String adminImageDownloadFailed(String error) {
    return 'Falha ao baixar imagem: $error';
  }

  @override
  String get adminUnsupportedImageFormat => 'Formato de imagem não suportado';

  @override
  String get adminImageReadFailed => 'Falha ao ler a imagem selecionada';

  @override
  String adminImageUploaded(String imageType) {
    return 'Imagem $imageType enviada';
  }

  @override
  String adminImageUploadFailed(String error) {
    return 'Falha ao enviar imagem: $error';
  }

  @override
  String adminDeleteImage(String imageType) {
    return 'Excluir imagem $imageType';
  }

  @override
  String adminImageDeleted(String imageType) {
    return 'Imagem $imageType excluída';
  }

  @override
  String adminImageDeleteFailed(String error) {
    return 'Falha ao excluir imagem: $error';
  }

  @override
  String get adminAllProviders => 'Todos os provedores';

  @override
  String get adminNoRemoteImages => 'Nenhuma imagem remota encontrada';

  @override
  String adminTunerDiscoveryFailed(String error) {
    return 'Descoberta de sintonizador falhou: $error';
  }

  @override
  String get adminAddTuner => 'Adicionar Sintonizador';

  @override
  String get adminTunerType => 'Tipo de Sintonizador';

  @override
  String get adminTunerTypeHint => 'HDHomeRun, M3U, Outro';

  @override
  String get adminUrlPath => 'URL / Caminho';

  @override
  String get adminNameOptional => 'Nome (opcional)';

  @override
  String get adminTunerAdded => 'Sintonizador adicionado';

  @override
  String adminTunerAddFailed(String error) {
    return 'Falha ao adicionar sintonizador: $error';
  }

  @override
  String get adminAddGuideProvider => 'Adicionar Provedor de Guia';

  @override
  String get adminProviderType => 'Tipo de Provedor';

  @override
  String get adminProviderTypeHint => 'SchedulesDirect ou XMLTV';

  @override
  String get adminUsernameOptional => 'Nome de usuário (opcional)';

  @override
  String get adminRefreshInterval => 'Intervalo de atualização (horas)';

  @override
  String get adminProviderAdded => 'Provedor adicionado';

  @override
  String adminProviderAddFailed(String error) {
    return 'Falha ao adicionar provedor: $error';
  }

  @override
  String adminTunerRemoveFailed(String error) {
    return 'Falha ao remover sintonizador: $error';
  }

  @override
  String get adminTunerResetRequested =>
      'Redefinição do sintonizador solicitada';

  @override
  String adminTunerResetFailed(String error) {
    return 'Falha ao redefinir sintonizador: $error';
  }

  @override
  String adminProviderRemoveFailed(String error) {
    return 'Falha ao remover provedor: $error';
  }

  @override
  String get adminRecordingSettings => 'Configurações de Gravação';

  @override
  String get adminPrePadding => 'Pré-margem (minutos)';

  @override
  String get adminPostPadding => 'Pós-margem (minutos)';

  @override
  String get adminRecordingPath => 'Caminho de gravação';

  @override
  String get adminSeriesRecordingPath => 'Caminho de gravação de séries';

  @override
  String get adminRecordingSettingsSaved => 'Configurações de gravação salvas';

  @override
  String adminSettingsSaveFailed(String error) {
    return 'Falha ao salvar configurações: $error';
  }

  @override
  String get adminSetChannelMappings => 'Definir Mapeamentos de Canais';

  @override
  String get adminMappingJson => 'JSON de Mapeamento';

  @override
  String get adminChannelMappingsUpdated => 'Mapeamentos de canais atualizados';

  @override
  String adminMappingsUpdateFailed(String error) {
    return 'Falha ao atualizar mapeamentos: $error';
  }

  @override
  String get adminLiveTvLoadFailed =>
      'Falha ao carregar a administração de TV ao Vivo';

  @override
  String get adminTunerDevices => 'Dispositivos Sintonizadores';

  @override
  String get adminNoTunerHosts => 'Nenhum sintonizador configurado';

  @override
  String get adminGuideProviders => 'Provedores de Guia';

  @override
  String get adminAddProvider => 'Adicionar Provedor';

  @override
  String get adminNoListingProviders =>
      'Nenhum provedor de listagem configurado';

  @override
  String adminRecordingPathDisplay(String path) {
    return 'Caminho de gravação: $path';
  }

  @override
  String adminSeriesPathDisplay(String path) {
    return 'Caminho de séries: $path';
  }

  @override
  String adminPrePaddingDisplay(int minutes) {
    return 'Pré-margem: $minutes min';
  }

  @override
  String adminPostPaddingDisplay(int minutes) {
    return 'Pós-margem: $minutes min';
  }

  @override
  String get adminTunerDiscovery => 'Descoberta de Sintonizadores';

  @override
  String get adminChannelMappings => 'Mapeamentos de Canais';

  @override
  String get adminNoDiscoveredTuners => 'Nenhum sintonizador descoberto ainda';

  @override
  String get adminSettingsSaved => 'Configurações salvas';

  @override
  String get adminBackupsNotAvailable =>
      'Backups não estão disponíveis nesta versão do servidor.';

  @override
  String get adminRestoreWarning1 =>
      'A restauração substituirá TODOS os dados atuais do servidor pelos dados do backup.';

  @override
  String get adminRestoreWarning2 =>
      'Configurações, usuários e dados da biblioteca do servidor atual serão sobrescritos.';

  @override
  String get adminRestoreWarning3 =>
      'O servidor será reiniciado após a restauração.';

  @override
  String adminRestoreConfirmMessage(String name) {
    return 'Restaurar backup $name agora?';
  }

  @override
  String get adminRestoreRequested =>
      'Restauração solicitada. O reinício do servidor pode desconectar esta sessão.';

  @override
  String get adminBackupsTitle => 'Backups';

  @override
  String get adminUnknownDate => 'Data desconhecida';

  @override
  String get adminUnnamedBackup => 'Backup Sem Nome';

  @override
  String get adminLiveTvNotAvailable =>
      'A administração de TV ao Vivo não está disponível nesta versão do servidor.';

  @override
  String get adminLiveTvTitle => 'Administração de TV ao Vivo';

  @override
  String get adminApply => 'Aplicar';

  @override
  String get adminNotSet => 'Não definido';

  @override
  String get adminReset => 'Redefinir';

  @override
  String get adminLogsTitle => 'Logs do Servidor';

  @override
  String get adminLogsNewestFirst => 'Mais Recentes Primeiro';

  @override
  String get adminLogsOldestFirst => 'Mais Antigos Primeiro';

  @override
  String get adminLogsJustNow => 'Agora mesmo';

  @override
  String adminLogsMinutesAgo(int minutes) {
    return '${minutes}m atrás';
  }

  @override
  String adminLogsHoursAgo(int hours) {
    return '${hours}h atrás';
  }

  @override
  String adminLogsDaysAgo(int days) {
    return '${days}d atrás';
  }

  @override
  String adminLogViewerLoadFailed(String fileName) {
    return 'Falha ao carregar $fileName';
  }

  @override
  String adminLogViewerMatches(int count) {
    return '$count correspondências';
  }

  @override
  String get adminLogViewerNoMatches => 'Nenhuma linha correspondente';

  @override
  String get adminMetadataEditorTitle => 'Editor de Metadados';

  @override
  String get adminMetadataRemote => 'Remoto';

  @override
  String get adminMetadataType => 'Tipo';

  @override
  String get adminMetadataDetails => 'Detalhes';

  @override
  String get adminMetadataExternalIds => 'IDs Externos';

  @override
  String get adminMetadataImages => 'Imagens';

  @override
  String get adminMetadataFieldTitle => 'Título';

  @override
  String get adminMetadataFieldSortTitle => 'Título para ordenação';

  @override
  String get adminMetadataFieldOriginalTitle => 'Título original';

  @override
  String get adminMetadataFieldPremiereDate => 'Data de estreia (AAAA-MM-DD)';

  @override
  String get adminMetadataFieldEndDate => 'Data de encerramento (AAAA-MM-DD)';

  @override
  String get adminMetadataFieldProductionYear => 'Ano de produção';

  @override
  String get adminMetadataFieldOfficialRating => 'Classificação oficial';

  @override
  String get adminMetadataFieldCommunityRating => 'Avaliação da comunidade';

  @override
  String get adminMetadataFieldCriticRating => 'Avaliação da crítica';

  @override
  String get adminMetadataFieldTagline => 'Tagline';

  @override
  String get adminMetadataFieldOverview => 'Sinopse';

  @override
  String get adminMetadataGenres => 'Gêneros';

  @override
  String get adminMetadataTags => 'Tags';

  @override
  String get adminMetadataStudios => 'Estúdios';

  @override
  String get adminMetadataPeople => 'Pessoas';

  @override
  String get adminMetadataAddGenre => 'Adicionar gênero';

  @override
  String get adminMetadataAddTag => 'Adicionar tag';

  @override
  String get adminMetadataAddStudio => 'Adicionar estúdio';

  @override
  String get adminMetadataAddPerson => 'Adicionar Pessoa';

  @override
  String get adminMetadataEditPerson => 'Editar Pessoa';

  @override
  String get adminMetadataRole => 'Papel';

  @override
  String get adminMetadataImagePrimary => 'Principal';

  @override
  String get adminMetadataImageBackdrop => 'Pano de Fundo';

  @override
  String get adminMetadataImageLogo => 'Logo';

  @override
  String get adminMetadataImageBanner => 'Banner';

  @override
  String get adminMetadataImageThumb => 'Miniatura';

  @override
  String get adminMetadataRecursive => 'Recursivo';

  @override
  String get adminMetadataProvider => 'Provedor';

  @override
  String adminMetadataImageUpdated(String imageType) {
    return 'Imagem $imageType atualizada';
  }

  @override
  String adminMetadataImageUploaded(String imageType) {
    return 'Imagem $imageType enviada';
  }

  @override
  String adminMetadataImageDeleted(String imageType) {
    return 'Imagem $imageType excluída';
  }

  @override
  String adminMetadataImageDownloadFailed(String error) {
    return 'Falha ao baixar imagem: $error';
  }

  @override
  String get adminMetadataImageReadFailed =>
      'Falha ao ler a imagem selecionada';

  @override
  String adminMetadataImageUploadFailed(String error) {
    return 'Falha ao enviar imagem: $error';
  }

  @override
  String adminMetadataDeleteImageTitle(String imageType) {
    return 'Excluir imagem $imageType';
  }

  @override
  String get adminMetadataDeleteImageContent =>
      'Isso remove a imagem atual do item.';

  @override
  String adminMetadataImageDeleteFailed(String error) {
    return 'Falha ao excluir imagem: $error';
  }

  @override
  String adminMetadataChooseImage(String imageType) {
    return 'Escolher imagem $imageType';
  }

  @override
  String get adminMetadataUpload => 'Enviar';

  @override
  String get adminMetadataUpdate => 'Atualizar';

  @override
  String get adminMetadataRemoteImage => 'Imagem remota';

  @override
  String get adminPluginsInstalled => 'Instalados';

  @override
  String get adminPluginsCatalog => 'Catálogo';

  @override
  String get adminPluginsActive => 'Ativos';

  @override
  String get adminPluginsRestart => 'Reiniciar';

  @override
  String get adminPluginsNoSearchResults =>
      'Nenhum plugin corresponde à sua pesquisa';

  @override
  String get adminPluginsNoneInstalled => 'Nenhum plugin instalado';

  @override
  String adminPluginsUpdateAvailable(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String get adminPluginsUpdateAvailableGeneric => 'Atualização disponível';

  @override
  String get adminPluginsPendingRemoval => 'Remoção pendente após reinício';

  @override
  String get adminPluginsChangesPending => 'Alterações pendentes de reinício';

  @override
  String get adminPluginsEnable => 'Habilitar';

  @override
  String get adminPluginsDisable => 'Desabilitar';

  @override
  String get adminPluginsInstallUpdate => 'Instalar atualização';

  @override
  String adminPluginsInstallUpdateVersioned(String version) {
    return 'Instalar atualização (v$version)';
  }

  @override
  String get adminPluginsCatalogNoSearchResults =>
      'Nenhum pacote corresponde à sua pesquisa';

  @override
  String get adminPluginsCatalogEmpty => 'Nenhum pacote disponível';

  @override
  String adminPluginsInstalling(String name) {
    return '\"$name\" está sendo instalado...';
  }

  @override
  String get adminPluginDetailExperimental => 'Integração Experimental';

  @override
  String get adminPluginDetailExperimentalContent =>
      'A integração de configurações de plugins ainda é experimental. Alguns campos ou layouts podem não ser renderizados corretamente ainda.';

  @override
  String get adminPluginDetailToggle404 =>
      'Falha ao alternar plugin. O servidor não encontrou esta versão do plugin. Tente atualizar plugins e tente novamente.';

  @override
  String get adminPluginDetailToggleDioError =>
      'Falha ao alternar plugin. Verifique os logs do servidor para detalhes.';

  @override
  String adminPluginDetailSettingsTitle(String name) {
    return 'Configurações de $name';
  }

  @override
  String get adminPluginDetailDetails => 'Detalhes';

  @override
  String get adminPluginDetailDeveloper => 'Desenvolvedor';

  @override
  String get adminPluginDetailRepository => 'Repositório';

  @override
  String get adminPluginDetailBundled => 'Integrado';

  @override
  String get adminPluginDetailEnablePlugin => 'Habilitar Plugin';

  @override
  String get adminPluginDetailRestartRequired =>
      'É necessário reiniciar o servidor para que as alterações tenham efeito.';

  @override
  String get adminPluginDetailRemovalPending =>
      'Este plugin será removido após reinício do servidor.';

  @override
  String get adminPluginDetailMalfunctioned =>
      'Este plugin apresentou mau funcionamento e pode não funcionar corretamente.';

  @override
  String get adminPluginDetailNotSupported =>
      'Este plugin não é suportado pela versão atual do servidor.';

  @override
  String get adminPluginDetailSuperseded =>
      'Este plugin foi substituído por uma versão mais recente.';

  @override
  String adminReposLoadFailed(String error) {
    return 'Falha ao carregar repositórios: $error';
  }

  @override
  String get adminReposRemoveTitle => 'Remover Repositório';

  @override
  String adminReposRemoveConfirm(String name) {
    return 'Tem certeza de que deseja remover \"$name\"?';
  }

  @override
  String get adminReposRemove => 'Remover';

  @override
  String adminReposSaveFailed(String error) {
    return 'Falha ao salvar repositórios: $error';
  }

  @override
  String get adminReposEmpty => 'Nenhum repositório configurado';

  @override
  String get adminReposEmptySubtitle =>
      'Adicione um repositório para navegar pelos plugins disponíveis';

  @override
  String get adminReposUnnamed => '(sem nome)';

  @override
  String get adminReposEditTitle => 'Editar Repositório';

  @override
  String get adminReposAddTitle => 'Adicionar Repositório';

  @override
  String get adminReposUrl => 'URL do Repositório';

  @override
  String get adminReposNameHint => 'ex: Jellyfin Stable';

  @override
  String get adminPluginSettingsInvalidUrl => 'URL inválida';

  @override
  String get adminGeneralSettingsTitle => 'Configurações Gerais';

  @override
  String get adminGeneralMetadataLanguage => 'Idioma preferido de metadados';

  @override
  String get adminGeneralMetadataLanguageHint => 'ex: en, de, fr';

  @override
  String get adminGeneralMetadataCountry => 'País preferido para metadados';

  @override
  String get adminGeneralMetadataCountryHint => 'ex: US, DE, FR';

  @override
  String get adminGeneralLibraryScanConcurrency =>
      'Concorrência de escaneamento de biblioteca';

  @override
  String get adminGeneralImageEncodingLimit =>
      'Limite de codificação de imagens paralelas';

  @override
  String get adminUnknownError => 'Erro desconhecido';

  @override
  String get adminBrowse => 'Navegar';

  @override
  String get adminCloseBrowser => 'Fechar navegador';

  @override
  String get adminNetworkingTitle => 'Rede';

  @override
  String get adminNetworkingRestartWarning =>
      'Alterações nas configurações de rede podem exigir reinício do servidor.';

  @override
  String get adminNetworkingRemoteAccess => 'Habilitar acesso remoto';

  @override
  String get adminNetworkingPorts => 'Portas';

  @override
  String get adminNetworkingHttpPort => 'Porta HTTP';

  @override
  String get adminNetworkingHttpsPort => 'Porta HTTPS';

  @override
  String get adminNetworkingEnableHttps => 'Habilitar HTTPS';

  @override
  String get adminNetworkingLocalNetwork => 'Rede Local';

  @override
  String get adminNetworkingLocalAddresses => 'Endereços de rede local';

  @override
  String get adminNetworkingAddressHint => 'ex: 192.168.1.0/24';

  @override
  String get adminNetworkingKnownProxies => 'Proxies conhecidos';

  @override
  String get adminNetworkingProxyHint => 'ex: 10.0.0.1';

  @override
  String get adminNetworkingWhitelist => 'Lista branca';

  @override
  String get adminNetworkingBlacklist => 'Lista negra';

  @override
  String get adminNetworkingAddEntry => 'Adicionar entrada';

  @override
  String get adminBrandingTitle => 'Marca';

  @override
  String get adminBrandingLoginDisclaimer => 'Aviso no login';

  @override
  String get adminBrandingLoginDisclaimerHint =>
      'HTML exibido abaixo do formulário de login';

  @override
  String get adminBrandingCustomCss => 'CSS Personalizado';

  @override
  String get adminBrandingCustomCssHint =>
      'CSS personalizado aplicado à interface web';

  @override
  String get adminBrandingEnableSplash => 'Habilitar tela de apresentação';

  @override
  String get adminPlaybackHwAccel => 'Aceleração de Hardware';

  @override
  String get adminPlaybackHwAccelLabel => 'Aceleração de hardware';

  @override
  String get adminPlaybackEnableHwEncoding =>
      'Habilitar codificação por hardware';

  @override
  String get adminPlaybackEnableHwDecoding =>
      'Habilitar decodificação por hardware para:';

  @override
  String get adminPlaybackEncoding => 'Codificação';

  @override
  String get adminPlaybackEncodingThreads => 'Threads de codificação';

  @override
  String get adminPlaybackFallbackFont => 'Habilitar fonte alternativa';

  @override
  String get adminPlaybackFallbackFontPath => 'Caminho da fonte alternativa';

  @override
  String get adminPlaybackStreaming => 'Transmissão';

  @override
  String get adminResumeVideo => 'Vídeo';

  @override
  String get adminResumeAudiobooks => 'Audiolivros';

  @override
  String get adminResumeMinAudiobookPct =>
      'Porcentagem mínima de retomada de audiolivros';

  @override
  String get adminResumeMaxAudiobookPct =>
      'Porcentagem máxima de retomada de audiolivros';

  @override
  String get adminStreamingBitrateLimit =>
      'Limite de bitrate do cliente remoto (Mbps)';

  @override
  String get adminStreamingBitrateLimitHint =>
      'Deixe vazio ou 0 para ilimitado';

  @override
  String get adminTrickplayHwAccel => 'Habilitar aceleração de hardware';

  @override
  String get adminTrickplayHwEncoding => 'Habilitar codificação por hardware';

  @override
  String get adminTrickplayKeyFrameOnly =>
      'Habilitar extração apenas de quadros-chave';

  @override
  String get adminTrickplayKeyFrameOnlySubtitle =>
      'Mais rápido, mas menor precisão';

  @override
  String get adminTrickplayNonBlocking => 'Não Bloqueante';

  @override
  String get adminTrickplayBlocking => 'Bloqueante';

  @override
  String get adminTrickplayPriorityHigh => 'Alta';

  @override
  String get adminTrickplayPriorityAboveNormal => 'Acima do Normal';

  @override
  String get adminTrickplayPriorityNormal => 'Normal';

  @override
  String get adminTrickplayPriorityBelowNormal => 'Abaixo do Normal';

  @override
  String get adminTrickplayPriorityIdle => 'Inativo';

  @override
  String get adminTrickplayImageSettings => 'Configurações de Imagem';

  @override
  String get adminTrickplayInterval => 'Intervalo (ms)';

  @override
  String get adminTrickplayIntervalSubtitle =>
      'Frequência de captura de quadros';

  @override
  String get adminTrickplayWidthResolutionsHint =>
      'Larguras de pixel separadas por vírgula (ex: 320)';

  @override
  String get adminTrickplayQuality => 'Qualidade';

  @override
  String get adminTrickplayQScale => 'Escala de qualidade';

  @override
  String get adminTrickplayQScaleSubtitle =>
      'Valores menores = melhor qualidade, arquivos maiores';

  @override
  String get adminTrickplayJpegQuality => 'Qualidade JPEG';

  @override
  String get adminTrickplayProcessing => 'Processamento';

  @override
  String get adminTasksEmpty => 'Nenhuma tarefa agendada encontrada';

  @override
  String get adminTasksNoFilterMatch =>
      'Nenhuma tarefa corresponde ao filtro atual';

  @override
  String get adminTaskCancelling => 'Cancelando...';

  @override
  String get adminTaskRunning => 'Executando...';

  @override
  String get adminTaskNeverRun => 'Nunca executada';

  @override
  String get adminTaskStop => 'Parar';

  @override
  String get adminTaskRun => 'Executar';

  @override
  String get adminTaskDetailLastExecution => 'Última Execução';

  @override
  String get adminTaskDetailStarted => 'Iniciada';

  @override
  String get adminTaskDetailEnded => 'Encerrada';

  @override
  String get adminTaskDetailDuration => 'Duração';

  @override
  String get adminTaskDetailErrorLabel => 'Erro:';

  @override
  String adminTaskTriggerDaily(String time) {
    return 'Diariamente às $time';
  }

  @override
  String adminTaskTriggerWeekly(String day, String time) {
    return 'Toda $day às $time';
  }

  @override
  String adminTaskTriggerInterval(String duration) {
    return 'A cada $duration';
  }

  @override
  String get adminTaskTriggerStartup => 'Na inicialização do aplicativo';

  @override
  String get adminTaskTriggerTypeDaily => 'Diário';

  @override
  String get adminTaskTriggerTypeWeekly => 'Semanal';

  @override
  String get adminTaskTriggerTypeInterval => 'Em um intervalo';

  @override
  String get adminTaskTriggerIntervalLabel => 'Intervalo';

  @override
  String get adminTaskTriggerEveryHour => 'A cada hora';

  @override
  String get adminTaskTriggerEvery6Hours => 'A cada 6 horas';

  @override
  String get adminTaskTriggerEvery12Hours => 'A cada 12 horas';

  @override
  String get adminTaskTriggerEvery24Hours => 'A cada 24 horas';

  @override
  String get adminTaskTriggerEvery2Days => 'A cada 2 dias';

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
  String get adminTaskTriggerTime => 'Horário';

  @override
  String get adminTaskTriggerNoLimit => 'Sem limite';

  @override
  String get adminActivityJustNow => 'Agora mesmo';

  @override
  String get adminActivityLastHour => 'Última hora';

  @override
  String get adminActivityToday => 'Hoje';

  @override
  String get adminActivityYesterday => 'Ontem';

  @override
  String get adminActivityOlder => 'Mais antigos';

  @override
  String adminActivityDaysAgo(int days) {
    return '${days}d atrás';
  }

  @override
  String adminActivityHoursAgo(int hours) {
    return '${hours}h atrás';
  }

  @override
  String adminActivityMinutesAgo(int minutes) {
    return '${minutes}m atrás';
  }

  @override
  String get adminActivityNow => 'agora';

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
      'Configure a geração de imagens trickplay para miniaturas de pré-visualização ao buscar.';

  @override
  String get adminNetworkingPublicHttpsPort => 'Porta HTTPS pública';

  @override
  String get adminNetworkingBaseUrl => 'URL Base';

  @override
  String get adminNetworkingBaseUrlHint => 'ex: /jellyfin';

  @override
  String get adminNetworkingHttps => 'HTTPS';

  @override
  String get adminNetworkingCertPath => 'Caminho do certificado';

  @override
  String get adminNetworkingRemoteIpFilter => 'Filtro de IP Remoto';

  @override
  String get adminNetworkingRemoteIpFilterLabel => 'Filtro de IP remoto';

  @override
  String get adminPlaybackVaapiDevice => 'Dispositivo VA-API';

  @override
  String get adminPlaybackAutomatic => '0 = automático';

  @override
  String get adminPlaybackTranscodeTempPath =>
      'Caminho temporário de transcodificação';

  @override
  String get adminPlaybackSegmentDeletion => 'Permitir exclusão de segmentos';

  @override
  String get adminPlaybackSegmentKeep => 'Manter segmento (segundos)';

  @override
  String get adminPlaybackThrottleBuffering => 'Limitar buffering';

  @override
  String get adminResumeMinPct => 'Porcentagem mínima de retomada';

  @override
  String get adminResumeMinPctSubtitle =>
      'O conteúdo deve ser reproduzido além desta porcentagem para salvar o progresso';

  @override
  String get adminResumeMaxPct => 'Porcentagem máxima de retomada';

  @override
  String get adminResumeMaxPctSubtitle =>
      'O conteúdo é considerado totalmente reproduzido após esta porcentagem';

  @override
  String get adminResumeMinDuration => 'Duração mínima de retomada (segundos)';

  @override
  String get adminResumeMinDurationSubtitle =>
      'Itens mais curtos que isso não são retomáveis';

  @override
  String get adminTrickplayScanBehavior => 'Comportamento de escaneamento';

  @override
  String get adminTrickplayProcessPriority => 'Prioridade do processo';

  @override
  String get adminTrickplayTileWidth => 'Largura do mosaico';

  @override
  String get adminTrickplayTileHeight => 'Altura do mosaico';

  @override
  String get adminTrickplayProcessThreads => 'Threads de processo';

  @override
  String get adminTrickplayWidthResolutions => 'Resoluções de largura';

  @override
  String get adminMetadataDefault => 'Padrão';

  @override
  String get adminMetadataContentTypeUpdated => 'Tipo de conteúdo atualizado';

  @override
  String adminMetadataContentTypeFailed(String error) {
    return 'Falha ao atualizar tipo de conteúdo: $error';
  }

  @override
  String get adminGeneralSlowResponseThreshold =>
      'Limite de resposta lenta (ms)';

  @override
  String get adminGeneralCachePath => 'Caminho do cache';

  @override
  String get adminGeneralMetadataPath => 'Caminho dos metadados';

  @override
  String get adminGeneralServerName => 'Nome do servidor';

  @override
  String get adminSettingsLoadFailed => 'Falha ao carregar configurações';

  @override
  String get adminDiscover => 'Descobrir';

  @override
  String adminChannelMappingsUpdateFailed(String error) {
    return 'Falha ao atualizar mapeamentos: $error';
  }

  @override
  String adminTimeLimitDuration(String duration) {
    return 'Limite de tempo: $duration';
  }

  @override
  String get folders => 'Pastas';

  @override
  String get libraries => 'Bibliotecas';

  @override
  String get syncPlay => 'SyncPlay';

  @override
  String get jellyseerr => 'Jellyseerr';

  @override
  String get seeAll => 'Ver Tudo';

  @override
  String get noItems => 'Nenhum item';

  @override
  String get switchUser => 'Trocar Usuário';

  @override
  String get remoteControl => 'Controle Remoto';

  @override
  String get mediaBarLoading => 'Carregando barra de mídia...';

  @override
  String get mediaBarError => 'Falha ao carregar a barra de mídia';

  @override
  String get offlineServerUnavailable =>
      'Conectado à internet, mas o servidor atual está indisponível.';

  @override
  String get offlineNoInternet =>
      'Você está offline. Apenas conteúdo baixado está disponível.';

  @override
  String get offlineSwitchServer => 'Trocar Servidor';

  @override
  String get offlineSavedMedia => 'Mídia Salva';

  @override
  String get castGoogleCast => 'Google Cast';

  @override
  String get castAirPlay => 'AirPlay';

  @override
  String get castDlna => 'DLNA';

  @override
  String get castRemotePlayback => 'Reprodução Remota';

  @override
  String castControlFailed(String error) {
    return 'Falha no controle de transmissão: $error';
  }

  @override
  String castKindControls(String kind) {
    return 'Controles de $kind';
  }

  @override
  String get castDeviceVolume => 'Volume do Dispositivo';

  @override
  String get castVolumeUnavailable => 'Indisponível';

  @override
  String castStopKind(String kind) {
    return 'Parar $kind';
  }

  @override
  String get audioLabel => 'Áudio';

  @override
  String get subtitlesLabel => 'Legendas';

  @override
  String get pinConfirmTitle => 'Confirmar PIN';

  @override
  String get pinSetTitle => 'Definir PIN';

  @override
  String get pinEnterTitle => 'Digitar PIN';

  @override
  String get pinReenterToConfirm => 'Digite novamente o PIN para confirmar';

  @override
  String pinEnterNDigit(int length) {
    return 'Digite um PIN de $length dígitos';
  }

  @override
  String pinEnterYourNDigit(int length) {
    return 'Digite seu PIN de $length dígitos';
  }

  @override
  String get pinIncorrect => 'PIN incorreto';

  @override
  String get pinMismatch => 'Os PINs não coincidem';

  @override
  String get pinForgot => 'Esqueceu o PIN?';

  @override
  String get pinClear => 'Limpar';

  @override
  String get pinBackspace => 'Apagar';

  @override
  String get quickConnectAuthorized => 'Solicitação Quick Connect autorizada.';

  @override
  String get quickConnectInvalidOrExpired =>
      'O código Quick Connect é inválido ou expirou.';

  @override
  String get quickConnectNotSupported =>
      'Quick Connect não é suportado neste servidor.';

  @override
  String get quickConnectAuthorizeFailed =>
      'Falha ao autorizar código Quick Connect.';

  @override
  String get quickConnectDisabled =>
      'Quick Connect está desabilitado neste servidor.';

  @override
  String get quickConnectForbidden =>
      'Sua conta não pode autorizar esta solicitação Quick Connect.';

  @override
  String get quickConnectNotFound =>
      'Código Quick Connect não encontrado. Tente um novo código.';

  @override
  String quickConnectFailedWithMessage(String message) {
    return 'Quick Connect falhou: $message';
  }

  @override
  String get quickConnectEnterCode => 'Digitar código';

  @override
  String get quickConnectAuthorize => 'Autorizar';

  @override
  String remoteCommandFailed(String error) {
    return 'Comando falhou: $error';
  }

  @override
  String get remoteControlTitle => 'Controle Remoto';

  @override
  String get remoteFailedToLoadSessions => 'Falha ao carregar sessões';

  @override
  String get remoteNoSessions => 'Nenhuma sessão controlável';

  @override
  String get remoteStartPlayback => 'Iniciar reprodução em outro dispositivo';

  @override
  String get unknownUser => 'Desconhecido';

  @override
  String get unknownItem => 'Desconhecido';

  @override
  String get remoteNothingPlaying => 'Nada reproduzindo nesta sessão';

  @override
  String get castingStarted =>
      'Transmissão iniciada no dispositivo selecionado';

  @override
  String castingFailed(String error) {
    return 'Falha ao iniciar transmissão: $error';
  }

  @override
  String get noRemoteDevices =>
      'Nenhum dispositivo de reprodução remota disponível.';

  @override
  String get noRemoteDevicesIos =>
      'Nenhum dispositivo de reprodução remota disponível.\n\nNo iOS, destinos AirPlay podem estar indisponíveis no simulador.';

  @override
  String get trackActionPlayNext => 'Reproduzir a Seguir';

  @override
  String get trackActionAddToQueue => 'Adicionar à Fila';

  @override
  String get trackActionAddToPlaylist => 'Adicionar à Playlist';

  @override
  String get trackActionCancelDownload => 'Cancelar Download';

  @override
  String get trackActionDeleteFromPlaylist => 'Excluir da Playlist';

  @override
  String get trackActionMoveUp => 'Mover para Cima';

  @override
  String get trackActionMoveDown => 'Mover para Baixo';

  @override
  String get trackActionRemoveFromFavorites => 'Remover dos Favoritos';

  @override
  String get trackActionAddToFavorites => 'Adicionar aos Favoritos';

  @override
  String get trackActionGoToAlbum => 'Ir para o Álbum';

  @override
  String get trackActionGoToArtist => 'Ir para o Artista';

  @override
  String trackActionDownloading(String name) {
    return 'Baixando $name...';
  }

  @override
  String get trackActionDeletedFile => 'Arquivo baixado excluído';

  @override
  String get trackActionDeleteFileFailed =>
      'Não foi possível excluir o arquivo baixado';

  @override
  String get shuffleBy => 'Embaralhar Por';

  @override
  String get shuffleSelectLibrary => 'Selecionar Biblioteca';

  @override
  String get shuffleSelectGenre => 'Selecionar Gênero';

  @override
  String get shuffleLibrary => 'Biblioteca';

  @override
  String get shuffleGenre => 'Gênero';

  @override
  String get shuffleNoLibraries => 'Nenhuma biblioteca compatível disponível.';

  @override
  String get shuffleNoGenres =>
      'Nenhum gênero encontrado para este modo de embaralhamento.';

  @override
  String get posterDisplayTitle => 'Exibição';

  @override
  String get posterImageType => 'Tipo de Imagem';

  @override
  String get imageTypePoster => 'Pôster';

  @override
  String get imageTypeThumbnail => 'Miniatura';

  @override
  String get imageTypeBanner => 'Banner';

  @override
  String get playlistAddFailed => 'Falha ao adicionar à playlist';

  @override
  String get playlistCreateFailed => 'Falha ao criar playlist';

  @override
  String get playlistNew => 'Nova Playlist';

  @override
  String get playlistCreate => 'Criar';

  @override
  String get playlistCreateNew => 'Criar Nova Playlist';

  @override
  String get playlistNoneFound => 'Nenhuma playlist encontrada';

  @override
  String get addToPlaylist => 'Adicionar à Playlist';

  @override
  String get lyricsNotAvailable => 'Nenhuma letra disponível';

  @override
  String get upNext => 'A Seguir';

  @override
  String get playNext => 'Reproduzir a Seguir';

  @override
  String get stillWatchingContent =>
      'A reprodução foi pausada. Você ainda está assistindo?';

  @override
  String get stillWatchingStop => 'Parar';

  @override
  String get stillWatchingContinue => 'Continuar';

  @override
  String skipSegment(String segment) {
    return 'Pular $segment';
  }

  @override
  String get liveTv => 'TV ao Vivo';

  @override
  String get continueWatchingAndNextUp => 'Continuar Assistindo e A Seguir';

  @override
  String downloadingBatchProgress(int current, int total, String fileName) {
    return 'Baixando $current/$total — $fileName';
  }

  @override
  String downloadingFile(String fileName) {
    return 'Baixando $fileName';
  }

  @override
  String get nextEpisode => 'Próximo Episódio';

  @override
  String get moreFromThisSeason => 'Mais Desta Temporada';
}
