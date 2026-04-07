import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';
import '../repositories/search_repository.dart';
import '../repositories/seerr_repository.dart';
import '../services/seerr/seerr_api_models.dart';

class SearchResultGroup {
  final String title;
  final List<String> itemTypes;
  final List<AggregatedItem> items;

  const SearchResultGroup({
    required this.title,
    required this.itemTypes,
    this.items = const [],
  });

  SearchResultGroup copyWith({List<AggregatedItem>? items}) =>
      SearchResultGroup(title: title, itemTypes: itemTypes, items: items ?? this.items);
}

enum SearchState { idle, loading, ready, error }

class SearchViewModel extends ChangeNotifier {
  final SearchRepository _searchRepository;
  final MediaServerClient _client;
  final String? _scopedParentId;
  SeerrRepository? _seerrRepository;

  SearchViewModel(
    this._searchRepository,
    this._client, {
    SeerrRepository? seerrRepository,
    String? scopedParentId,
  }) : _seerrRepository = seerrRepository,
       _scopedParentId =
           (scopedParentId != null && scopedParentId.isNotEmpty)
               ? scopedParentId
               : null;

  void setSeerrRepository(SeerrRepository repo) {
    _seerrRepository = repo;
  }

  ImageApi get imageApi => _client.imageApi;

  SearchState _state = SearchState.idle;
  SearchState get state => _state;

  String _query = '';
  String get query => _query;

  List<SearchResultGroup> _results = const [];
  List<SearchResultGroup> get results => _results;

  List<SeerrDiscoverItem> _seerrResults = const [];
  List<SeerrDiscoverItem> get seerrResults => _seerrResults;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Timer? _debounceTimer;

  static const _debounceMs = 600;
  static const _resultLimit = 24;

  static const _bookSearchGroups = [
    SearchResultGroup(title: 'Books', itemTypes: ['Book']),
    SearchResultGroup(title: 'Audiobooks', itemTypes: ['AudioBook']),
  ];

  static const _searchGroups = [
    SearchResultGroup(title: 'Books', itemTypes: ['Book']),
    SearchResultGroup(title: 'Movies', itemTypes: ['Movie']),
    SearchResultGroup(title: 'Series', itemTypes: ['Series']),
    SearchResultGroup(title: 'Episodes', itemTypes: ['Episode']),
    SearchResultGroup(title: 'Videos', itemTypes: ['Video']),
    SearchResultGroup(title: 'Programs', itemTypes: ['Program']),
    SearchResultGroup(title: 'Channels', itemTypes: ['LiveTvChannel']),
    SearchResultGroup(title: 'Playlists', itemTypes: ['Playlist']),
    SearchResultGroup(title: 'Artists', itemTypes: ['MusicArtist']),
    SearchResultGroup(title: 'Albums', itemTypes: ['MusicAlbum']),
    SearchResultGroup(title: 'Songs', itemTypes: ['Audio']),
    SearchResultGroup(title: 'Photo Albums', itemTypes: ['PhotoAlbum']),
    SearchResultGroup(title: 'Photos', itemTypes: ['Photo']),
    SearchResultGroup(title: 'Collections', itemTypes: ['BoxSet']),
    SearchResultGroup(title: 'People', itemTypes: ['Person']),
  ];

  void searchDebounced(String query) {
    final trimmed = query.trim();
    if (trimmed == _query) return;
    _query = trimmed;

    _debounceTimer?.cancel();

    if (trimmed.isEmpty) {
      _results = const [];
      _seerrResults = const [];
      _state = SearchState.idle;
      notifyListeners();
      return;
    }

    _state = SearchState.loading;
    notifyListeners();

    _debounceTimer = Timer(
      const Duration(milliseconds: _debounceMs),
      () => _executeSearch(trimmed),
    );
  }

  void searchImmediate(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _query = trimmed;
    _debounceTimer?.cancel();
    _state = SearchState.loading;
    notifyListeners();
    _executeSearch(trimmed);
  }

  Future<void> _executeSearch(String query) async {
    if (query != _query) return;

    try {
      final activeGroups = _scopedParentId != null ? _bookSearchGroups : _searchGroups;
      final futures = activeGroups.map((group) async {
        final items = await _searchRepository.search(
          query,
          includeItemTypes: group.itemTypes,
          parentId: _scopedParentId,
          limit: _resultLimit,
        );
        return group.copyWith(items: items);
      });

      final seerrFuture = _fetchSeerrResults(query);

      final groups = await Future.wait(futures);
      final seerr = await seerrFuture;

      if (query != _query) return;

      _results = groups.where((g) => g.items.isNotEmpty).toList();
      _seerrResults = seerr;
      _state = SearchState.ready;
    } catch (e) {
      if (query != _query) return;
      _errorMessage = e.toString();
      _state = SearchState.error;
    }
    notifyListeners();
  }

  Future<List<SeerrDiscoverItem>> _fetchSeerrResults(String query) async {
    if (_scopedParentId != null) return const [];
    final repo = _seerrRepository;
    if (repo == null) return const [];
    try {
      await repo.ensureInitialized();
      if (!repo.isAvailable) return const [];
      final page = await repo.search(query, limit: _resultLimit);
      return page.results;
    } catch (_) {
      return const [];
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
