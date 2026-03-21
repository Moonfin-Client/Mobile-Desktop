import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../preference/preference_constants.dart';
import '../../preference/user_preferences.dart';
import '../models/aggregated_item.dart';
import '../repositories/mdblist_repository.dart';
import '../utils/playlist_utils.dart';

enum LibraryBrowseState { loading, ready, error }

class LibraryBrowseViewModel extends ChangeNotifier {
  final MediaServerClient _client;
  final UserPreferences _prefs;
  final MdbListRepository _mdbListRepository;
  final String libraryId;
  final String? genreId;
  final String? overrideName;
  final List<String>? includeItemTypes;

  static const _pageSize = 100;

  LibraryBrowseState _state = LibraryBrowseState.loading;
  LibraryBrowseState get state => _state;

  List<AggregatedItem> _items = const [];
  List<AggregatedItem> get items => _items;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  bool get hasMore => _items.length < _totalCount;

  String _libraryName = '';
  String get libraryName => _libraryName;

  String? _collectionType;
  bool _initialLibraryFilterSet = false;
  bool _imageTypeSynced = false;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  late LibrarySortBy _sortBy;
  LibrarySortBy get sortBy => _sortBy;

  late SortDirection _sortDirection;
  SortDirection get sortDirection => _sortDirection;

  late PlayedStatusFilter _playedFilter;
  PlayedStatusFilter get playedFilter => _playedFilter;

  late SeriesStatusFilter _seriesFilter;
  SeriesStatusFilter get seriesFilter => _seriesFilter;

  late bool _favoriteFilter;
  bool get favoriteFilter => _favoriteFilter;

  late String _letterFilter;
  String get letterFilter => _letterFilter;

  String? _libraryFilter;
  String? get libraryFilter => _libraryFilter;

  List<Map<String, dynamic>> _libraries = const [];
  List<Map<String, dynamic>> get libraries => _libraries;

  bool get isGenreBrowse => genreId != null;

  late ImageType _imageType;
  ImageType get imageType => _imageType;

  late PosterSize _posterSize;
  PosterSize get posterSize => _posterSize;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AggregatedItem? _focusedItem;
  AggregatedItem? get focusedItem => _focusedItem;

  Map<String, double> _focusedRatings = const {};
  Map<String, double> get focusedRatings => _focusedRatings;

  ImageApi get imageApi => _client.imageApi;

  Future<List<AggregatedItem>> _filterLibraryItems(
    List<AggregatedItem> items,
  ) async {
    if (!isPlaylistBrowse) return items;

    return filterBrowsablePlaylists(
      _client,
      items,
      assumeNonEmptyWhenUnknown: true,
    );
  }

  void setFocusedItem(AggregatedItem? item) {
    _focusedItem = item;
    _focusedRatings = const {};
    notifyListeners();
    if (item != null) _loadFocusedRatings(item);
  }

  Future<void> _loadFocusedRatings(AggregatedItem item) async {
    if (!_prefs.get(UserPreferences.enableAdditionalRatings)) return;
    final tmdbId = item.tmdbId;
    if (tmdbId == null) return;
    final mediaType = item.type;
    if (mediaType == null) return;
    final ratings = await _mdbListRepository.getRatings(
      tmdbId: tmdbId,
      mediaType: mediaType,
    );
    if (ratings != null && ratings.isNotEmpty && _focusedItem?.id == item.id) {
      _focusedRatings = ratings;
      notifyListeners();
    }
  }

  LibraryBrowseViewModel({
    required this.libraryId,
    required MediaServerClient client,
    required UserPreferences prefs,
    required MdbListRepository mdbListRepository,
    this.genreId,
    this.overrideName,
    this.includeItemTypes,
  }) : _client = client,
       _prefs = prefs,
       _mdbListRepository = mdbListRepository {
    _sortBy = _prefs.get(UserPreferences.librarySortBy(_prefKey));
    _sortDirection = _prefs.get(UserPreferences.librarySortDirection(_prefKey));
    _playedFilter = _prefs.get(UserPreferences.libraryPlayedFilter(_prefKey));
    _seriesFilter = _prefs.get(UserPreferences.librarySeriesFilter(_prefKey));
    _favoriteFilter = _prefs.get(
      UserPreferences.libraryFavoriteFilter(_prefKey),
    );
    _letterFilter = _prefs.get(UserPreferences.libraryLetterFilter(_prefKey));
    _imageType = _prefs.get(UserPreferences.libraryImageType(_prefKey));
    _posterSize = _prefs.get(UserPreferences.posterSize);
  }

  String get _prefKey => genreId ?? libraryId;

  Future<void> load() async {
    _state = LibraryBrowseState.loading;
    _items = const [];
    _totalCount = 0;
    notifyListeners();

    try {
      if (genreId != null) {
        _libraryName = overrideName ?? '';
        if (!_initialLibraryFilterSet) {
          _libraryFilter = libraryId.isEmpty ? null : libraryId;
          _initialLibraryFilterSet = true;
        }
        if (_libraries.isEmpty) _loadLibraries();
        if (libraryId.isNotEmpty) {
          try {
            final parentData = await _client.itemsApi.getItem(libraryId);
            _collectionType =
                (parentData['CollectionType'] as String?)?.toLowerCase();
          } catch (_) {}
        }
      } else {
        final parentData = await _client.itemsApi.getItem(libraryId);
        _libraryName = parentData['Name'] as String? ?? '';
        _collectionType =
            (parentData['CollectionType'] as String?)?.toLowerCase();
      }

      if (!_imageTypeSynced) {
        await _syncImageTypeFromServer();
        _imageTypeSynced = true;
      }
      await _fetchPage(0);
      _state = LibraryBrowseState.ready;
    } catch (e) {
      _errorMessage = e.toString();
      _state = LibraryBrowseState.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();

    try {
      await _fetchPage(_items.length);
    } catch (_) {}

    _loadingMore = false;
    notifyListeners();
  }

  Future<void> _fetchPage(int startIndex) async {
    final filters = <String>[];
    if (_playedFilter == PlayedStatusFilter.watched) {
      filters.add('IsPlayed');
    } else if (_playedFilter == PlayedStatusFilter.unwatched) {
      filters.add('IsUnplayed');
    }

    final seriesStatus = <String>[];
    if (_seriesFilter == SeriesStatusFilter.continuing) {
      seriesStatus.add('Continuing');
    } else if (_seriesFilter == SeriesStatusFilter.ended) {
      seriesStatus.add('Ended');
    }

    List<String>? includeTypes;
    List<String>? excludeTypes;
    bool? collapseBoxSets;
    bool recursive = true;
    String sortBy = _sortBy.apiValue;
    final isAlbumArtistBrowse =
        includeItemTypes != null &&
        includeItemTypes!.length == 1 &&
        includeItemTypes!.first == 'AlbumArtist';
    final isArtistBrowse =
        includeItemTypes != null &&
        includeItemTypes!.length == 1 &&
        includeItemTypes!.first == 'MusicArtist';
    if (includeItemTypes != null) {
      includeTypes = includeItemTypes;
    } else {
      switch (_collectionType) {
        case 'movies':
          includeTypes = ['Movie'];
          excludeTypes = ['BoxSet'];
          collapseBoxSets = false;
          break;
        case 'tvshows':
          includeTypes = ['Series'];
          collapseBoxSets = false;
          break;
        case 'playlists':
          includeTypes = ['Playlist'];
          break;
        case 'boxsets':
          recursive = false;
          break;
        case 'books':
          recursive = false;
          sortBy = 'IsFolder,SortName';
          break;
        default:
          collapseBoxSets = false;
          break;
      }
    }

    if (isBookLibrary) {
      recursive = false;
      sortBy = 'IsFolder,SortName';
    }

    if (isMixedContentLibrary) {
      recursive = false;
      sortBy = 'IsFolder,SortName';
    }

    if (genreId != null &&
        _collectionType == 'music' &&
        includeItemTypes == null) {
      includeTypes = ['MusicAlbum'];
    }

    if (isAlbumArtistBrowse || isArtistBrowse) {
      includeTypes = null;
      excludeTypes = null;
      collapseBoxSets = null;
      recursive = true;
      sortBy = 'SortName';
    }

    final Map<String, dynamic> response;
    if (isAlbumArtistBrowse) {
      response = await _client.itemsApi.getAlbumArtists(
        parentId: _effectiveParentId,
        userId: _client.userId,
        sortBy: sortBy,
        sortOrder:
            _sortDirection == SortDirection.ascending
                ? 'Ascending'
                : 'Descending',
        startIndex: startIndex,
        limit: _pageSize,
        recursive: recursive,
        fields: 'PrimaryImageAspectRatio,SortName',
        nameStartsWith: _letterFilter.isEmpty ? null : _letterFilter,
        isFavorite: _favoriteFilter ? true : null,
      );
    } else if (isArtistBrowse) {
      response = await _client.itemsApi.getArtists(
        parentId: _effectiveParentId,
        userId: _client.userId,
        sortBy: sortBy,
        sortOrder:
            _sortDirection == SortDirection.ascending
                ? 'Ascending'
                : 'Descending',
        startIndex: startIndex,
        limit: _pageSize,
        recursive: recursive,
        fields: 'PrimaryImageAspectRatio,SortName',
        nameStartsWith: _letterFilter.isEmpty ? null : _letterFilter,
        isFavorite: _favoriteFilter ? true : null,
      );
    } else {
      response = await _client.itemsApi.getItems(
        parentId: _effectiveParentId,
        genreIds: genreId != null ? [genreId!] : null,
        includeItemTypes: includeTypes,
        excludeItemTypes: excludeTypes,
        collapseBoxSetItems: collapseBoxSets,
        sortBy: sortBy,
        sortOrder:
            _sortDirection == SortDirection.ascending
                ? 'Ascending'
                : 'Descending',
        startIndex: startIndex,
        limit: _pageSize,
        recursive: recursive,
        fields:
          'PrimaryImageAspectRatio,BasicSyncInfo,Overview,Genres,CommunityRating,OfficialRating,RunTimeTicks,ProductionYear,Status,ImageTags,BackdropImageTags,ParentBackdropItemId,ParentBackdropImageTags,ParentThumbItemId,ParentThumbImageTag,SeriesId,SeriesPrimaryImageTag,CriticRating,ProviderIds',
        filters: filters.isEmpty ? null : filters,
        seriesStatus: seriesStatus.isEmpty ? null : seriesStatus,
        nameStartsWith: _letterFilter.isEmpty ? null : _letterFilter,
        isFavorite: _favoriteFilter ? true : null,
      );
    }

    final rawItems = (response['Items'] as List?) ?? [];
    _totalCount = response['TotalRecordCount'] as int? ?? rawItems.length;

    final mapped =
        rawItems
            .cast<Map<String, dynamic>>()
            .map(
              (raw) => AggregatedItem(
                id: raw['Id'] as String,
                serverId: _client.baseUrl,
                rawData: raw,
              ),
            )
            .toList();

    final filtered = await _filterLibraryItems(mapped);

    if (startIndex == 0) {
      _items = filtered;
    } else {
      _items = [..._items, ...filtered];
    }
  }

  String? get _effectiveParentId {
    if (genreId != null) return _libraryFilter;
    return libraryId.isEmpty ? null : libraryId;
  }

  Future<void> _loadLibraries() async {
    try {
      final response = await _client.userViewsApi.getUserViews();
      final items = (response['Items'] as List?) ?? [];
      _libraries =
          items.cast<Map<String, dynamic>>().where((lib) {
            final type = lib['CollectionType'] as String?;
            return type == 'movies' || type == 'tvshows' || type == null;
          }).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLibraryFilter(String? value) async {
    if (_libraryFilter == value) return;
    _libraryFilter = value;
    _collectionType = null;
    if (value != null) {
      try {
        final parentData = await _client.itemsApi.getItem(value);
        _collectionType =
            (parentData['CollectionType'] as String?)?.toLowerCase();
      } catch (_) {}
    }
    await load();
  }

  Future<void> setSortBy(LibrarySortBy value) async {
    if (_sortBy == value) return;
    _sortBy = value;
    await _prefs.set(UserPreferences.librarySortBy(_prefKey), value);
    await load();
  }

  Future<void> setSortDirection(SortDirection value) async {
    if (_sortDirection == value) return;
    _sortDirection = value;
    await _prefs.set(UserPreferences.librarySortDirection(_prefKey), value);
    await load();
  }

  Future<void> toggleSortDirection() => setSortDirection(
    _sortDirection == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending,
  );

  Future<void> setPlayedFilter(PlayedStatusFilter value) async {
    if (_playedFilter == value) return;
    _playedFilter = value;
    await _prefs.set(UserPreferences.libraryPlayedFilter(_prefKey), value);
    await load();
  }

  Future<void> setSeriesFilter(SeriesStatusFilter value) async {
    if (_seriesFilter == value) return;
    _seriesFilter = value;
    await _prefs.set(UserPreferences.librarySeriesFilter(_prefKey), value);
    await load();
  }

  Future<void> setFavoriteFilter(bool value) async {
    if (_favoriteFilter == value) return;
    _favoriteFilter = value;
    await _prefs.set(UserPreferences.libraryFavoriteFilter(_prefKey), value);
    await load();
  }

  Future<void> setLetterFilter(String value) async {
    if (_letterFilter == value) return;
    _letterFilter = value;
    await _prefs.set(UserPreferences.libraryLetterFilter(_prefKey), value);
    await load();
  }

  Future<void> setImageType(ImageType value) async {
    if (_imageType == value) return;
    _imageType = value;
    await _prefs.set(UserPreferences.libraryImageType(_prefKey), value);
    notifyListeners();
    _syncImageTypeToServer(value);
  }

  Future<void> _syncImageTypeFromServer() async {
    if (_prefKey.isEmpty) return;
    try {
      final dp = await _client.displayPreferencesApi.getDisplayPreferences(
        _prefKey,
        client: 'moonfin',
      );
      final serverType = dp.customPrefs['imageType'];
      if (serverType != null) {
        final match = ImageType.values.where(
          (t) => t.name.toLowerCase() == serverType.toLowerCase(),
        );
        if (match.isNotEmpty && match.first != _imageType) {
          _imageType = match.first;
          await _prefs.set(
            UserPreferences.libraryImageType(_prefKey),
            _imageType,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _syncImageTypeToServer(ImageType value) async {
    if (_prefKey.isEmpty) return;
    try {
      final dp = await _client.displayPreferencesApi.getDisplayPreferences(
        _prefKey,
        client: 'moonfin',
      );
      final updated = DisplayPreferences(
        id: dp.id,
        sortBy: dp.sortBy,
        sortOrder: dp.sortOrder,
        viewType: dp.viewType,
        customPrefs: {...dp.customPrefs, 'imageType': value.name},
      );
      await _client.displayPreferencesApi.saveDisplayPreferences(
        _prefKey,
        updated,
        client: 'moonfin',
      );
    } catch (_) {}
  }

  Future<void> setPosterSize(PosterSize value) async {
    if (_posterSize == value) return;
    _posterSize = value;
    await _prefs.set(UserPreferences.posterSize, value);
    notifyListeners();
  }

  bool get isSeriesLibrary =>
      _collectionType == 'tvshows' ||
      (includeItemTypes != null && includeItemTypes!.contains('Series'));

  bool get isMusicBrowse =>
      _collectionType == 'music' ||
      (includeItemTypes != null &&
          includeItemTypes!.any(
            (t) =>
                t == 'MusicAlbum' ||
                t == 'MusicArtist' ||
                t == 'AlbumArtist' ||
                t == 'Audio',
          ));

  bool get isPlaylistBrowse =>
      _collectionType == 'playlists' ||
      (includeItemTypes != null && includeItemTypes!.contains('Playlist'));

  bool get isBookLibrary =>
      _collectionType == 'books' ||
      (includeItemTypes != null && includeItemTypes!.contains('Book'));

  bool get isMixedContentLibrary =>
      !isGenreBrowse &&
      includeItemTypes == null &&
      _collectionType == null;

  bool isNavigableFolder(AggregatedItem item) {
    final type = item.type;
    return type == 'Folder' || type == 'CollectionFolder' || type == 'UserView';
  }

  String get statusText {
    final parts = <String>[];
    if (_favoriteFilter) parts.add('Favorites');
    if (_playedFilter == PlayedStatusFilter.watched) parts.add('Watched');
    if (_playedFilter == PlayedStatusFilter.unwatched) parts.add('Unwatched');
    if (_seriesFilter == SeriesStatusFilter.continuing) parts.add('Continuing');
    if (_seriesFilter == SeriesStatusFilter.ended) parts.add('Ended');
    if (_letterFilter.isNotEmpty) parts.add('Starting with $_letterFilter');
    final filterDesc = parts.isEmpty ? 'All items' : parts.join(' ');
    return "Showing $filterDesc from '$_libraryName' sorted by ${_sortBy.displayName}";
  }

  String get counterText => '${_items.length} | $_totalCount';
}
