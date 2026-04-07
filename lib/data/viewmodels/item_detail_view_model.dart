import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';
import '../models/lyrics.dart';
import '../repositories/item_mutation_repository.dart';
import '../repositories/mdblist_repository.dart';
import '../utils/playlist_utils.dart';

enum ItemDetailState { loading, ready, error }

class ItemDetailViewModel extends ChangeNotifier {
  static const _episodeOverviewFields = 'Overview';

  final MediaServerClient _client;
  final ItemMutationRepository _mutations;
  final MdbListRepository _mdbListRepository;

  final String itemId;

  ItemDetailState _state = ItemDetailState.loading;
  ItemDetailState get state => _state;

  AggregatedItem? _item;
  AggregatedItem? get item => _item;

  List<AggregatedItem> _similar = const [];
  List<AggregatedItem> get similar => _similar;

  List<AggregatedItem> _filmography = const [];
  List<AggregatedItem> get filmography => _filmography;

  List<AggregatedItem> _seasons = const [];
  List<AggregatedItem> get seasons => _seasons;

  List<AggregatedItem> _episodes = const [];
  List<AggregatedItem> get episodes => _episodes;

  AggregatedItem? _nextUp;
  AggregatedItem? get nextUp => _nextUp;

  Map<String, double> _ratings = const {};
  Map<String, double> get ratings => _ratings;

  List<AggregatedItem> _albums = const [];
  List<AggregatedItem> get albums => _albums;

  List<AggregatedItem> _tracks = const [];
  List<AggregatedItem> get tracks => _tracks;

  List<AggregatedItem> _collectionItems = const [];
  List<AggregatedItem> get collectionItems => _collectionItems;

  String? _parentCollectionName;
  String? get parentCollectionName => _parentCollectionName;

  List<AggregatedItem> _parentCollectionItems = const [];
  List<AggregatedItem> get parentCollectionItems => _parentCollectionItems;

  List<AggregatedItem> _features = const [];
  List<AggregatedItem> get features => _features;

  LyricsData _lyrics = LyricsData.empty;
  LyricsData get lyrics => _lyrics;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ImageApi get imageApi => _client.imageApi;
  String get baseUrl => _client.baseUrl;

  bool get canManagePlaylistTracks =>
      _item?.type == 'Playlist' &&
      _tracks.isNotEmpty &&
      _tracks.every(hasPlaylistEntryId);

  final String? _serverId;

  ItemDetailViewModel({
    required this.itemId,
    String? serverId,
    required MediaServerClient client,
    required ItemMutationRepository mutations,
    required MdbListRepository mdbListRepository,
  }) : _serverId = serverId,
       _client = client,
       _mutations = mutations,
       _mdbListRepository = mdbListRepository;

  Future<void> load() async {
    _state = ItemDetailState.loading;
    _collectionItems = const [];
    _parentCollectionItems = const [];
    _parentCollectionName = null;
    notifyListeners();

    try {
      final data = await _client.itemsApi.getItem(itemId);
      _item = AggregatedItem(
        id: itemId,
        serverId: _serverId ?? _client.baseUrl,
        rawData: data,
      );
      _lyrics = LyricsData.empty;
      _state = ItemDetailState.ready;
      notifyListeners();

      _loadSecondary();
    } catch (e) {
      _errorMessage = e.toString();
      _state = ItemDetailState.error;
      notifyListeners();
    }
  }

  Future<void> _loadSecondary() async {
    final type = _item?.type;
    final futures = <Future>[];
    if (type == 'Person') {
      futures.add(_loadFilmography());
    } else if (type == 'Series') {
      futures.add(_loadRatings());
      futures.add(_loadSeasons());
      futures.add(_loadNextUp());
      futures.add(_loadSimilar());
    } else if (type == 'Season') {
      futures.add(_loadRatings());
      futures.add(_loadEpisodes());
    } else if (type == 'Episode') {
      futures.add(_loadRatings());
      futures.add(_loadEpisodes());
      futures.add(_loadSimilar());
      futures.add(_loadFeatures());
    } else if (type == 'MusicArtist') {
      futures.add(_loadAlbums());
      futures.add(_loadSimilar());
    } else if (type == 'MusicAlbum' || type == 'Playlist') {
      futures.add(_loadTracks());
    } else if (type == 'AudioBook') {
      futures.add(_loadRatings());
      futures.add(_loadSimilar());
    } else if (type == 'Audio') {
      futures.add(_loadLyrics());
    } else if (type == 'BoxSet') {
      futures.add(_loadCollectionItems());
    } else if (type == 'Movie' || type == 'Trailer' || type == 'Video') {
      futures.add(_loadRatings());
      futures.add(_loadSimilar());
      futures.add(_loadFeatures());
      futures.add(_loadParentCollection());
    } else {
      futures.add(_loadRatings());
      futures.add(_loadSimilar());
    }
    await Future.wait(futures);
  }

  Future<void> _loadSeasons() async {
    try {
      final data = await _client.itemsApi.getSeasons(itemId);
      final items = (data['Items'] as List?) ?? [];
      _seasons = _mapItems(items);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadEpisodes() async {
    final item = _item;
    if (item == null) return;
    final seriesId = item.seriesId ?? itemId;
    try {
      final data = await _client.itemsApi.getEpisodes(
        seriesId,
        seasonId: item.type == 'Season' ? itemId : item.seasonId,
        fields: _episodeOverviewFields,
      );
      final items = (data['Items'] as List?) ?? [];
      _episodes = _mapItems(items);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadNextUp() async {
    try {
      final data = await _client.itemsApi.getNextUp(
        seriesId: itemId,
        limit: 1,
        fields: _episodeOverviewFields,
      );
      final items = (data['Items'] as List?) ?? [];
      if (items.isNotEmpty) {
        final raw = items.first as Map<String, dynamic>;
        _nextUp = AggregatedItem(
          id: raw['Id'] as String,
          serverId: _serverId ?? _client.baseUrl,
          rawData: raw,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  List<AggregatedItem> _mapItems(List items) {
    return items
        .cast<Map<String, dynamic>>()
        .map(
          (raw) => AggregatedItem(
            id: raw['Id'] as String,
            serverId: _serverId ?? _client.baseUrl,
            rawData: raw,
          ),
        )
        .toList();
  }

  Future<void> _loadAlbums() async {
    try {
      final data = await _client.itemsApi.getItems(
        artistIds: [itemId],
        includeItemTypes: ['MusicAlbum'],
        sortBy: 'ProductionYear,SortName',
        sortOrder: 'Descending',
        recursive: true,
        fields: 'PrimaryImageAspectRatio,BasicSyncInfo',
      );
      final items = (data['Items'] as List?) ?? [];
      _albums = _mapItems(items);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadTracks() async {
    try {
      final data =
          _item?.type == 'Playlist'
              ? await _client.itemsApi.getPlaylistItems(itemId)
              : await _client.itemsApi.getItems(
                parentId: itemId,
                includeItemTypes: ['Audio'],
                sortBy: 'IndexNumber',
                fields: 'PrimaryImageAspectRatio,BasicSyncInfo',
              );
      final items = (data['Items'] as List?) ?? [];
      _tracks = _mapItems(items);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadLyrics() async {
    try {
      final data = await _client.itemsApi.getLyrics(itemId);
      _lyrics = LyricsData.fromJson(data);
      notifyListeners();
    } catch (_) {
      _lyrics = LyricsData.empty;
      notifyListeners();
    }
  }

  String? _playlistEntryId(AggregatedItem track) =>
      track.rawData['PlaylistItemId'] as String?;

  Future<void> removeTrackFromPlaylist(AggregatedItem track) async {
    if (_item?.type != 'Playlist') return;
    final entryId = _playlistEntryId(track);
    if (entryId == null) return;

    final previousTracks = List<AggregatedItem>.from(_tracks);
    _tracks =
        _tracks.where((t) {
          final sameId = t.id == track.id;
          final sameEntry = _playlistEntryId(t) == entryId;
          return !(sameId && sameEntry);
        }).toList();
    notifyListeners();

    try {
      await _client.itemsApi.removeFromPlaylist(itemId, [entryId]);
      await _loadTracks();
      await _reload();
    } catch (_) {
      _tracks = previousTracks;
      notifyListeners();
    }
  }

  Future<void> reorderPlaylistTrack(int oldIndex, int newIndex) async {
    if (_item?.type != 'Playlist') return;
    if (oldIndex < 0 || oldIndex >= _tracks.length) {
      return;
    }
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex -= 1;
    if (targetIndex < 0 || targetIndex >= _tracks.length) {
      return;
    }

    final moved = _tracks[oldIndex];
    final entryId = _playlistEntryId(moved);
    if (entryId == null) return;

    final previousTracks = List<AggregatedItem>.from(_tracks);
    final reordered = List<AggregatedItem>.from(_tracks);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(targetIndex, item);
    _tracks = reordered;
    notifyListeners();

    try {
      await _client.itemsApi.movePlaylistItem(itemId, entryId, targetIndex);
      await _loadTracks();
    } catch (_) {
      _tracks = previousTracks;
      notifyListeners();
    }
  }

  Future<void> renamePlaylist(String name) async {
    final item = _item;
    if (item == null || item.type != 'Playlist') return;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == item.name) return;

    final previous = item.name;
    final patched = Map<String, dynamic>.from(item.rawData)..['Name'] = trimmed;
    _item = AggregatedItem(
      id: item.id,
      serverId: item.serverId,
      rawData: patched,
    );
    notifyListeners();

    try {
      await _client.itemsApi.renamePlaylist(itemId, trimmed);
      await _reload();
    } catch (_) {
      final reverted = Map<String, dynamic>.from(item.rawData)
        ..['Name'] = previous;
      _item = AggregatedItem(
        id: item.id,
        serverId: item.serverId,
        rawData: reverted,
      );
      notifyListeners();
    }
  }

  Future<bool> deleteItem() async {
    try {
      await _client.itemsApi.deleteItem(itemId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadCollectionItems() async {
    try {
      final data = await _client.itemsApi.getItems(
        parentId: itemId,
        sortBy: 'SortName',
        fields: 'PrimaryImageAspectRatio,BasicSyncInfo',
      );
      final items = (data['Items'] as List?) ?? [];
      _collectionItems = _mapItems(items);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadParentCollection() async {
    final item = _item;
    if (item == null) {
      return;
    }

    try {
      final ancestors = await _client.itemsApi.getAncestors(item.id);
      var boxSet = ancestors.firstWhere(
        (ancestor) => ancestor['Type'] == 'BoxSet',
        orElse: () => const <String, dynamic>{},
      );

      if (boxSet.isEmpty) {
        final collapsed = await _client.itemsApi.getItems(
          ids: [item.id],
          includeItemTypes: ['Movie', 'Series', 'BoxSet'],
          recursive: true,
          collapseBoxSetItems: true,
          fields: 'BasicSyncInfo',
        );
        final collapsedItems = (collapsed['Items'] as List?) ?? const [];
        boxSet = collapsedItems
            .whereType<Map>()
            .map((entry) => entry.cast<String, dynamic>())
            .firstWhere(
              (entry) => entry['Type'] == 'BoxSet',
              orElse: () => const <String, dynamic>{},
            );
      }

      final boxSetId = boxSet['Id'] as String?;
      String? resolvedBoxSetId;
      if (boxSetId != null && boxSetId.isNotEmpty) {
        final isMember = await _boxSetContainsItem(boxSetId, item.id);
        if (isMember) {
          resolvedBoxSetId = boxSetId;
        }
      }
      resolvedBoxSetId ??= await _findParentCollectionByScanningBoxSets(item.id);
      if (resolvedBoxSetId == null || resolvedBoxSetId.isEmpty) {
        return;
      }

      final data = await _client.itemsApi.getItems(
        parentId: resolvedBoxSetId,
        sortBy: 'PremiereDate,SortName',
        sortOrder: 'Ascending',
        fields: 'PrimaryImageAspectRatio,BasicSyncInfo',
      );

      final items = (data['Items'] as List?) ?? [];
        final resolvedName =
          (boxSetId != null && boxSetId == resolvedBoxSetId)
            ? boxSet['Name'] as String?
            : null;
        _parentCollectionName =
          resolvedName ??
          (await _client.itemsApi.getItem(resolvedBoxSetId))['Name'] as String?;
        _parentCollectionItems = _sortCollectionByReleaseOrder(_mapItems(items));
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> _boxSetContainsItem(String boxSetId, String itemId) async {
    try {
      final membership = await _client.itemsApi.getItems(
        parentId: boxSetId,
        fields: 'BasicSyncInfo',
      );
      final members = (membership['Items'] as List?) ?? const [];
      return members.whereType<Map>().any((entry) {
        final map = entry.cast<String, dynamic>();
        return map['Id'] == itemId;
      });
    } catch (_) {
      return false;
    }
  }

  Future<String?> _findParentCollectionByScanningBoxSets(String itemId) async {
    try {
      const pageSize = 200;
      var startIndex = 0;

      while (true) {
        final data = await _client.itemsApi.getItems(
          includeItemTypes: ['BoxSet'],
          recursive: true,
          sortBy: 'SortName',
          fields: 'BasicSyncInfo',
          startIndex: startIndex,
          limit: pageSize,
          enableTotalRecordCount: true,
        );
        final boxSets = (data['Items'] as List?) ?? const [];
        if (boxSets.isEmpty) {
          break;
        }

        for (final raw in boxSets.whereType<Map>()) {
          final boxSet = raw.cast<String, dynamic>();
          final boxSetId = boxSet['Id'] as String?;
          if (boxSetId == null || boxSetId.isEmpty) {
            continue;
          }

          final membership = await _client.itemsApi.getItems(
            parentId: boxSetId,
            fields: 'BasicSyncInfo',
          );
          final members = (membership['Items'] as List?) ?? const [];
          final hasItem = members.whereType<Map>().any((entry) {
            final map = entry.cast<String, dynamic>();
            return map['Id'] == itemId;
          });
          if (hasItem) {
            return boxSetId;
          }
        }

        if (boxSets.length < pageSize) {
          break;
        }
        startIndex += boxSets.length;
      }
    } catch (_) {}

    return null;
  }

  List<AggregatedItem> _sortCollectionByReleaseOrder(
    List<AggregatedItem> items,
  ) {
    final sorted = List<AggregatedItem>.from(items);
    sorted.sort((a, b) {
      final aDate = a.premiereDate;
      final bDate = b.premiereDate;
      if (aDate != null && bDate != null) {
        final byDate = aDate.compareTo(bDate);
        if (byDate != 0) {
          return byDate;
        }
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }

      final aYear = a.productionYear;
      final bYear = b.productionYear;
      if (aYear != null && bYear != null) {
        final byYear = aYear.compareTo(bYear);
        if (byYear != 0) {
          return byYear;
        }
      } else if (aYear != null) {
        return -1;
      } else if (bYear != null) {
        return 1;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  Future<void> _loadFeatures() async {
    try {
      final items = await _client.itemsApi.getSpecialFeatures(itemId);
      _features =
          _mapItems(items)
              .where((item) => item.id != itemId)
              .toList(growable: false);
      notifyListeners();
    } catch (_) {
      _features = const [];
      notifyListeners();
    }
  }

  Future<void> _loadFilmography() async {
    try {
      final data = await _client.itemsApi.getItems(
        personIds: [itemId],
        includeItemTypes: ['Movie', 'Series'],
        sortBy: 'PremiereDate',
        sortOrder: 'Descending',
        recursive: true,
        limit: 50,
        fields: 'PrimaryImageAspectRatio,BasicSyncInfo',
      );
      final items = (data['Items'] as List?) ?? [];
      _filmography = _mapItems(items);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadSimilar() async {
    try {
      final data = await _client.itemsApi.getSimilarItems(itemId, limit: 12);
      final items = (data['Items'] as List?) ?? [];
      _similar = _mapItems(items);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadRatings() async {
    final item = _item;
    if (item == null) return;
    final tmdbId = item.tmdbId;
    if (tmdbId == null) return;
    final mediaType = item.type ?? 'Movie';

    try {
      final result = await _mdbListRepository.getRatings(
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      if (result != null && result.isNotEmpty) {
        _ratings = result;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleFavorite() async {
    final item = _item;
    if (item == null) return;
    final newState = !item.isFavorite;
    _applyOptimisticUpdate({'IsFavorite': newState});
    try {
      await _mutations.setFavorite(itemId, isFavorite: newState);
      await _reload();
    } catch (_) {
      _applyOptimisticUpdate({'IsFavorite': !newState});
    }
  }

  Future<void> togglePlayed() async {
    final item = _item;
    if (item == null) return;
    final newState = !item.isPlayed;
    _applyOptimisticUpdate({'Played': newState});
    try {
      await _mutations.setPlayed(itemId, isPlayed: newState);
      await _reload();
    } catch (_) {
      _applyOptimisticUpdate({'Played': !newState});
    }
  }

  void _applyOptimisticUpdate(Map<String, dynamic> userDataPatch) {
    final item = _item;
    if (item == null) return;
    final updatedRaw = Map<String, dynamic>.from(item.rawData);
    final userData = Map<String, dynamic>.from(
      (updatedRaw['UserData'] as Map?) ?? {},
    );
    userData.addAll(userDataPatch);
    updatedRaw['UserData'] = userData;
    _item = AggregatedItem(
      id: item.id,
      serverId: item.serverId,
      rawData: updatedRaw,
    );
    notifyListeners();
  }

  Future<void> _reload() async {
    try {
      final data = await _client.itemsApi.getItem(itemId);
      _item = AggregatedItem(
        id: itemId,
        serverId: _serverId ?? _client.baseUrl,
        rawData: data,
      );
      notifyListeners();
    } catch (_) {}
  }

  List<Map<String, dynamic>> get directors =>
      _item?.people.where((p) => p['Type'] == 'Director').toList() ?? const [];

  List<Map<String, dynamic>> get writers =>
      _item?.people.where((p) => p['Type'] == 'Writer').toList() ?? const [];

  List<Map<String, dynamic>> get actors =>
      _item?.people.where((p) => p['Type'] == 'Actor').toList() ?? const [];

  List<AggregatedItem> get filmographyMovies =>
      _filmography.where((i) => i.type == 'Movie').toList();

  List<AggregatedItem> get filmographySeries =>
      _filmography.where((i) => i.type == 'Series').toList();
}
