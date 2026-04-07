import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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
  static const _browseFields =
      'PrimaryImageAspectRatio,SortName,Type,IsFolder,ChildCount,UserData,CommunityRating,OfficialRating,RunTimeTicks,ProductionYear,Status,ImageTags,BackdropImageTags,ParentBackdropItemId,ParentBackdropImageTags,ParentThumbItemId,ParentThumbImageTag,SeriesId,SeriesPrimaryImageTag,CriticRating,Author,Authors,AlbumArtist,Artists,People';

  LibraryBrowseState _state = LibraryBrowseState.loading;
  LibraryBrowseState get state => _state;

  List<AggregatedItem> _items = const [];
  List<AggregatedItem> get items => _items;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  bool _totalCountKnown = true;
  bool _hasMoreFromPageSize = false;

  bool get hasMore => _totalCountKnown ? _items.length < _totalCount : _hasMoreFromPageSize;

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

  final Map<String, String?> _tmdbIdByItemId = {};

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
    var tmdbId = item.tmdbId;
    if (tmdbId == null) {
      if (_tmdbIdByItemId.containsKey(item.id)) {
        tmdbId = _tmdbIdByItemId[item.id];
      } else {
        try {
          final details = await _client.itemsApi.getItem(item.id);
          tmdbId = (details['ProviderIds'] as Map?)?['Tmdb'] as String?;
        } catch (_) {
          tmdbId = null;
        }
        _tmdbIdByItemId[item.id] = tmdbId;
      }
    }

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
    _imageType = _prefs.get(UserPreferences.libraryImageType(_imagePrefKey));
    _posterSize = _prefs.get(UserPreferences.posterSize);
  }

  String get _prefKey => genreId ?? libraryId;

  String get _imagePrefKey {
    if (genreId != null && libraryId.isNotEmpty) {
      return libraryId;
    }
    return _prefKey;
  }

  Future<void> load() async {
    _state = LibraryBrowseState.loading;
    _items = const [];
    _totalCount = 0;
    _totalCountKnown = true;
    _hasMoreFromPageSize = false;
    _tmdbIdByItemId.clear();
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
            _collectionType = (parentData['CollectionType'] as String?)
                ?.toLowerCase();
          } catch (_) {}
        }
      } else {
        final parentData = await _client.itemsApi.getItem(libraryId);
        _libraryName = parentData['Name'] as String? ?? '';
        _collectionType = (parentData['CollectionType'] as String?)
            ?.toLowerCase();
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
        default:
          collapseBoxSets = false;
          break;
      }
    }

    if (isBookLibrary) {
      recursive = true;
      includeTypes = ['Book', 'Audio', 'AudioBook'];
      sortBy = 'SortName';
    } else if (isHomeVideosLibrary || isMixedContentLibrary) {
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
        sortOrder: _sortDirection == SortDirection.ascending
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
        sortOrder: _sortDirection == SortDirection.ascending
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
      response = await _fetchItemsWithFallback(
        parentId: _effectiveParentId,
        genreIds: genreId != null ? [genreId!] : null,
        includeItemTypes: includeTypes,
        excludeItemTypes: excludeTypes,
        collapseBoxSetItems: collapseBoxSets,
        sortBy: sortBy,
        sortOrder: _sortDirection == SortDirection.ascending
            ? 'Ascending'
            : 'Descending',
        startIndex: startIndex,
        recursive: recursive,
        fields: _browseFields,
        filters: filters.isEmpty ? null : filters,
        seriesStatus: seriesStatus.isEmpty ? null : seriesStatus,
        nameStartsWith: _letterFilter.isEmpty ? null : _letterFilter,
        isFavorite: _favoriteFilter ? true : null,
      );
    }

    final rawItems = (response['Items'] as List?) ?? [];
    final totalFromServer = response['TotalRecordCount'] as int?;
    _totalCountKnown = totalFromServer != null;
    if (_totalCountKnown) {
      _totalCount = totalFromServer!;
      _hasMoreFromPageSize = _items.length + rawItems.length < _totalCount;
    } else {
      _hasMoreFromPageSize = rawItems.length == _pageSize;
      final loadedCount = startIndex + rawItems.length;
      _totalCount = loadedCount + (_hasMoreFromPageSize ? 1 : 0);
    }

    final mapped = rawItems
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

  Future<Map<String, dynamic>> _fetchItemsWithFallback({
    String? parentId,
    List<String>? genreIds,
    List<String>? includeItemTypes,
    List<String>? excludeItemTypes,
    bool? collapseBoxSetItems,
    required String sortBy,
    required String sortOrder,
    required int startIndex,
    required bool recursive,
    required String fields,
    List<String>? filters,
    List<String>? seriesStatus,
    String? nameStartsWith,
    bool? isFavorite,
  }) async {
    try {
      return await _client.itemsApi.getItems(
        parentId: parentId,
        genreIds: genreIds,
        includeItemTypes: includeItemTypes,
        excludeItemTypes: excludeItemTypes,
        collapseBoxSetItems: collapseBoxSetItems,
        sortBy: sortBy,
        sortOrder: sortOrder,
        startIndex: startIndex,
        limit: _pageSize,
        recursive: recursive,
        fields: fields,
        filters: filters,
        seriesStatus: seriesStatus,
        nameStartsWith: nameStartsWith,
        isFavorite: isFavorite,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final isServerError = statusCode >= 500;
      if (!isServerError) {
        rethrow;
      }

      final fallbackSort = sortBy.toLowerCase().contains('isfolder')
          ? 'SortName'
          : sortBy;

      return _client.itemsApi.getItems(
        parentId: parentId,
        genreIds: genreIds,
        includeItemTypes: includeItemTypes,
        excludeItemTypes: excludeItemTypes,
        collapseBoxSetItems: collapseBoxSetItems,
        sortBy: fallbackSort,
        sortOrder: sortOrder,
        startIndex: startIndex,
        limit: _pageSize,
        recursive: recursive,
        fields: fields,
        filters: filters,
        seriesStatus: seriesStatus,
        nameStartsWith: nameStartsWith,
        isFavorite: isFavorite,
        enableTotalRecordCount: false,
      );
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
      _libraries = items.cast<Map<String, dynamic>>().where((lib) {
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
        _collectionType = (parentData['CollectionType'] as String?)
            ?.toLowerCase();
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
    await _prefs.set(UserPreferences.libraryImageType(_imagePrefKey), value);
    notifyListeners();
    _syncImageTypeToServer(value);
  }

  Future<void> _syncImageTypeFromServer() async {
    if (_imagePrefKey.isEmpty) return;
    try {
      final dp = await _client.displayPreferencesApi.getDisplayPreferences(
        _imagePrefKey,
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
            UserPreferences.libraryImageType(_imagePrefKey),
            _imageType,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _syncImageTypeToServer(ImageType value) async {
    if (_imagePrefKey.isEmpty) return;
    try {
      final dp = await _client.displayPreferencesApi.getDisplayPreferences(
        _imagePrefKey,
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
        _imagePrefKey,
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

  bool get isHomeVideosLibrary =>
      !isGenreBrowse &&
      includeItemTypes == null &&
      _collectionType == 'homevideos';

  bool get isMixedContentLibrary =>
      !isGenreBrowse &&
      includeItemTypes == null &&
      (_collectionType == null ||
          _collectionType!.isEmpty ||
          _collectionType == 'mixed');

  bool isNavigableFolder(AggregatedItem item) {
    final type = item.type;
    if (type == 'Series' || type == 'BoxSet' || type == 'Playlist') {
      return false;
    }

    final isFolder = item.rawData['IsFolder'] as bool? ?? false;
    if (isFolder) return true;

    return switch (type) {
      'Folder' || 'CollectionFolder' || 'UserView' => true,
      _ => false,
    };
  }

  String get statusText {
    final parts = <String>[];
    if (_favoriteFilter) parts.add('Favorites');
    if (_playedFilter == PlayedStatusFilter.watched) {
      parts.add(isBookLibrary ? 'Read' : 'Watched');
    }
    if (_playedFilter == PlayedStatusFilter.unwatched) {
      parts.add(isBookLibrary ? 'Unread' : 'Unwatched');
    }
    if (_seriesFilter == SeriesStatusFilter.continuing) parts.add('Continuing');
    if (_seriesFilter == SeriesStatusFilter.ended) parts.add('Ended');
    if (_letterFilter.isNotEmpty) parts.add('Starting with $_letterFilter');
    final filterDesc = parts.isEmpty ? 'All items' : parts.join(' ');
    return "Showing $filterDesc from '$_libraryName' sorted by ${_sortBy.displayName}";
  }

  String get counterText => '${_items.length} | $_totalCount';
}
