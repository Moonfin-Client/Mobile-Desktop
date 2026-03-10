import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../preference/preference_constants.dart';
import '../../preference/user_preferences.dart';
import '../models/aggregated_item.dart';
import '../repositories/mdblist_repository.dart';

enum LibraryBrowseState { loading, ready, error }

class LibraryBrowseViewModel extends ChangeNotifier {
  final MediaServerClient _client;
  final UserPreferences _prefs;
  final MdbListRepository _mdbListRepository;
  final String libraryId;

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
  })  : _client = client,
        _prefs = prefs,
        _mdbListRepository = mdbListRepository {
    _sortBy = _prefs.get(UserPreferences.librarySortBy(libraryId));
    _sortDirection = _prefs.get(UserPreferences.librarySortDirection(libraryId));
    _playedFilter = _prefs.get(UserPreferences.libraryPlayedFilter(libraryId));
    _seriesFilter = _prefs.get(UserPreferences.librarySeriesFilter(libraryId));
    _favoriteFilter = _prefs.get(UserPreferences.libraryFavoriteFilter(libraryId));
    _letterFilter = _prefs.get(UserPreferences.libraryLetterFilter(libraryId));
    _imageType = _prefs.get(UserPreferences.libraryImageType(libraryId));
    _posterSize = _prefs.get(UserPreferences.posterSize);
  }

  Future<void> load() async {
    _state = LibraryBrowseState.loading;
    _items = const [];
    _totalCount = 0;
    notifyListeners();

    try {
      final parentData = await _client.itemsApi.getItem(libraryId);
      _libraryName = parentData['Name'] as String? ?? '';
      _collectionType = (parentData['CollectionType'] as String?)?.toLowerCase();

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
    bool? collapseBoxSets;
    switch (_collectionType) {
      case 'movies':
        includeTypes = ['Movie'];
        collapseBoxSets = false;
        break;
      case 'tvshows':
        includeTypes = ['Series'];
        collapseBoxSets = false;
        break;
      case 'boxsets':
        break;
      default:
        collapseBoxSets = false;
        break;
    }

    final response = await _client.itemsApi.getItems(
      parentId: libraryId,
      includeItemTypes: includeTypes,
      collapseBoxSetItems: collapseBoxSets,
      sortBy: _sortBy.apiValue,
      sortOrder: _sortDirection == SortDirection.ascending ? 'Ascending' : 'Descending',
      startIndex: startIndex,
      limit: _pageSize,
      recursive: true,
      fields: 'PrimaryImageAspectRatio,BasicSyncInfo,Overview,Genres,CommunityRating,OfficialRating,RunTimeTicks,ProductionYear,Status,ImageTags,BackdropImageTags,ParentBackdropItemId,ParentBackdropImageTags,CriticRating,ProviderIds',
      filters: filters.isEmpty ? null : filters,
      seriesStatus: seriesStatus.isEmpty ? null : seriesStatus,
      nameStartsWith: _letterFilter.isEmpty ? null : _letterFilter,
      isFavorite: _favoriteFilter ? true : null,
    );

    final rawItems = (response['Items'] as List?) ?? [];
    _totalCount = response['TotalRecordCount'] as int? ?? rawItems.length;

    final filtered = _collectionType != 'boxsets'
        ? rawItems.cast<Map<String, dynamic>>().where((raw) => raw['Type'] != 'BoxSet').toList()
        : rawItems.cast<Map<String, dynamic>>().toList();

    if (filtered.length < rawItems.length) {
      _totalCount -= (rawItems.length - filtered.length);
    }

    final mapped = filtered.map((raw) => AggregatedItem(
      id: raw['Id'] as String,
      serverId: _client.baseUrl,
      rawData: raw,
    )).toList();

    if (startIndex == 0) {
      _items = mapped;
    } else {
      _items = [..._items, ...mapped];
    }
  }

  Future<void> setSortBy(LibrarySortBy value) async {
    if (_sortBy == value) return;
    _sortBy = value;
    await _prefs.set(UserPreferences.librarySortBy(libraryId), value);
    await load();
  }

  Future<void> setSortDirection(SortDirection value) async {
    if (_sortDirection == value) return;
    _sortDirection = value;
    await _prefs.set(UserPreferences.librarySortDirection(libraryId), value);
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
    await _prefs.set(UserPreferences.libraryPlayedFilter(libraryId), value);
    await load();
  }

  Future<void> setSeriesFilter(SeriesStatusFilter value) async {
    if (_seriesFilter == value) return;
    _seriesFilter = value;
    await _prefs.set(UserPreferences.librarySeriesFilter(libraryId), value);
    await load();
  }

  Future<void> setFavoriteFilter(bool value) async {
    if (_favoriteFilter == value) return;
    _favoriteFilter = value;
    await _prefs.set(UserPreferences.libraryFavoriteFilter(libraryId), value);
    await load();
  }

  Future<void> setLetterFilter(String value) async {
    if (_letterFilter == value) return;
    _letterFilter = value;
    await _prefs.set(UserPreferences.libraryLetterFilter(libraryId), value);
    await load();
  }

  Future<void> setImageType(ImageType value) async {
    if (_imageType == value) return;
    _imageType = value;
    await _prefs.set(UserPreferences.libraryImageType(libraryId), value);
    notifyListeners();
  }

  Future<void> setPosterSize(PosterSize value) async {
    if (_posterSize == value) return;
    _posterSize = value;
    await _prefs.set(UserPreferences.posterSize, value);
    notifyListeners();
  }

  bool get isSeriesLibrary => _collectionType == 'tvshows';

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
