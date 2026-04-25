import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../preference/preference_constants.dart';
import '../../preference/user_preferences.dart';
import '../models/aggregated_item.dart';
import '../repositories/mdblist_repository.dart';

enum FavoritesState { loading, ready, error }

class FavoritesViewModel extends ChangeNotifier {
  final MediaServerClient _client;
  final UserPreferences _prefs;
  final MdbListRepository _mdbListRepository;

  static const _pageSize = 100;
  static const _prefKey = 'favorites';
  static const _browseFields =
      'Type,UserData,CommunityRating,OfficialRating,RunTimeTicks,ProductionYear,Status,ImageTags,BackdropImageTags,ParentBackdropItemId,ParentBackdropImageTags,CriticRating';

  FavoritesState _state = FavoritesState.loading;
  FavoritesState get state => _state;

  List<AggregatedItem> _items = const [];
  List<AggregatedItem> get items => _items;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  bool _totalCountKnown = true;
  bool _hasMoreFromPageSize = false;

  bool get hasMore => _totalCountKnown ? _items.length < _totalCount : _hasMoreFromPageSize;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  late LibrarySortBy _sortBy;
  LibrarySortBy get sortBy => _sortBy;

  late SortDirection _sortDirection;
  SortDirection get sortDirection => _sortDirection;

  late ImageType _imageType;
  ImageType get imageType => _imageType;

  late PosterSize _posterSize;
  PosterSize get posterSize => _posterSize;

  late FavoriteTypeFilter _typeFilter;
  FavoriteTypeFilter get typeFilter => _typeFilter;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AggregatedItem? _focusedItem;
  AggregatedItem? get focusedItem => _focusedItem;

  Map<String, double> _focusedRatings = const {};
  Map<String, double> get focusedRatings => _focusedRatings;

  final Map<String, String?> _tmdbIdByItemId = {};

  ImageApi get imageApi => _client.imageApi;

  FavoritesViewModel({
    required MediaServerClient client,
    required UserPreferences prefs,
    required MdbListRepository mdbListRepository,
  })  : _client = client,
        _prefs = prefs,
        _mdbListRepository = mdbListRepository {
    _sortBy = _prefs.get(UserPreferences.librarySortBy(_prefKey));
    _sortDirection = _prefs.get(UserPreferences.librarySortDirection(_prefKey));
    _imageType = _prefs.get(UserPreferences.libraryImageType(_prefKey));
    _posterSize = _prefs.get(UserPreferences.posterSize);
    _typeFilter = _prefs.get(UserPreferences.favoriteTypeFilter);
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

  Future<void> load() async {
    _state = FavoritesState.loading;
    _items = const [];
    _totalCount = 0;
    _totalCountKnown = true;
    _hasMoreFromPageSize = false;
    _tmdbIdByItemId.clear();
    notifyListeners();

    try {
      await _fetchPage(0);
      _state = FavoritesState.ready;
    } catch (e) {
      _errorMessage = e.toString();
      _state = FavoritesState.error;
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
    final response = await _fetchItemsWithFallback(startIndex: startIndex);

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

    final mapped = rawItems.cast<Map<String, dynamic>>().map((raw) => AggregatedItem(
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

  Future<Map<String, dynamic>> _fetchItemsWithFallback({
    required int startIndex,
  }) async {
    try {
      return await _client.itemsApi.getItems(
        sortBy: _sortBy.apiValue,
        sortOrder: _sortDirection == SortDirection.ascending
            ? 'Ascending'
            : 'Descending',
        startIndex: startIndex,
        limit: _pageSize,
        recursive: true,
        isFavorite: true,
        includeItemTypes: _resolvedIncludeItemTypes(),
        fields: _browseFields,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode < 500) {
        rethrow;
      }

      final fallbackSort = _sortBy.apiValue.toLowerCase().contains('isfolder')
          ? 'SortName'
          : _sortBy.apiValue;

      return _client.itemsApi.getItems(
        sortBy: fallbackSort,
        sortOrder: _sortDirection == SortDirection.ascending
            ? 'Ascending'
            : 'Descending',
        startIndex: startIndex,
        limit: _pageSize,
        recursive: true,
        isFavorite: true,
        includeItemTypes: _resolvedIncludeItemTypes(),
        fields: _browseFields,
        enableTotalRecordCount: false,
      );
    }
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

  Future<void> setImageType(ImageType value) async {
    if (_imageType == value) return;
    _imageType = value;
    await _prefs.set(UserPreferences.libraryImageType(_prefKey), value);
    notifyListeners();
  }

  Future<void> setPosterSize(PosterSize value) async {
    if (_posterSize == value) return;
    _posterSize = value;
    await _prefs.set(UserPreferences.posterSize, value);
    notifyListeners();
  }

  Future<void> setTypeFilter(FavoriteTypeFilter value) async {
    if (_typeFilter == value) return;
    _typeFilter = value;
    _focusedItem = null;
    await _prefs.set(UserPreferences.favoriteTypeFilter, value);
    await load();
  }

  List<String>? _resolvedIncludeItemTypes() {
    if (_typeFilter != FavoriteTypeFilter.all) {
      return _typeFilter.itemTypes;
    }
    final csv = _prefs.get(UserPreferences.defaultFavoritesFilter);
    if (csv.trim().isEmpty) return null;
    final selected = csv
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (selected.contains(FavoriteTypeFilter.all.name)) return null;
    final types = <String>{};
    for (final filter in FavoriteTypeFilter.values) {
      if (selected.contains(filter.name)) {
        final typesForFilter = filter.itemTypes;
        if (typesForFilter == null) return null;
        types.addAll(typesForFilter);
      }
    }
    return types.isEmpty ? null : types.toList();
  }

  String get statusText {
    final typeLabel = _typeFilter == FavoriteTypeFilter.all
        ? 'all favorites'
        : '${_typeFilter.displayName} favorites';
    return 'Showing $typeLabel sorted by ${_sortBy.displayName}';
  }

  String get counterText => '${_items.length} | $_totalCount';
}
