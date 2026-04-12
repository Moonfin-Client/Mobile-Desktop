import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';
import '../models/home_row.dart';
import '../services/row_data_source.dart';

class LibraryViewViewModel extends ChangeNotifier {
  final RowDataSource _dataSource;
  final MediaServerClient _client;
  final String libraryId;

  List<HomeRow> _rows = [];
  List<HomeRow> get rows => _rows;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _libraryName = '';
  String get libraryName => _libraryName;

  String? _collectionType;
  String? get collectionType => _collectionType;

  AggregatedItem? _focusedItem;
  AggregatedItem? get focusedItem => _focusedItem;

  String get _serverId => _client.baseUrl;
  ImageApi get imageApi => _dataSource.imageApi;

  LibraryViewViewModel({
    required this.libraryId,
    required RowDataSource dataSource,
    required MediaServerClient client,
  })  : _dataSource = dataSource,
        _client = client;

  void setFocusedItem(AggregatedItem? item) {
    _focusedItem = item;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final itemData = await _client.itemsApi.getItem(libraryId);
      _libraryName = itemData['Name'] as String? ?? '';
      _collectionType = (itemData['CollectionType'] as String?)?.toLowerCase();
    } catch (e) {
      debugPrint('Failed to load library info: $e');
    }

    try {
      final rows = await _loadRowsForType();
      _rows = rows.where((r) => r.items.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Failed to load library rows: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<HomeRow>> _loadRowsForType() async {
    switch (_collectionType) {
      case 'movies':
        return Future.wait([
          _dataSource.loadLibraryResume(libraryId, _serverId),
          _dataSource.loadLatestMedia(
            libraryId,
            _libraryName,
            _serverId,
            includeItemTypes: const ['Movie'],
          ),
          _dataSource.loadLibraryFavorites(libraryId, _serverId,
              includeItemTypes: ['Movie']),
          _dataSource.loadLibraryCollections(libraryId, _serverId),
        ]);
      case 'tvshows':
        return Future.wait([
          _dataSource.loadLibraryResume(libraryId, _serverId),
          _dataSource.loadLibraryNextUp(libraryId, _serverId),
          _dataSource.loadLatestMedia(
            libraryId,
            _libraryName,
            _serverId,
            includeItemTypes: const ['Series'],
          ),
          _dataSource.loadLibraryFavorites(libraryId, _serverId,
              includeItemTypes: ['Series']),
        ]);
      case 'music':
        return Future.wait([
          _dataSource.loadLatestMedia(
            libraryId,
            _libraryName,
            _serverId,
            includeItemTypes: const ['MusicAlbum'],
          ),
          _dataSource.loadLibraryLastPlayed(libraryId, _serverId,
              includeItemTypes: ['Audio']),
          _dataSource.loadLibraryFavorites(libraryId, _serverId,
              includeItemTypes: ['MusicAlbum']),
          _dataSource.loadPlaylists(_serverId, mediaType: 'Audio'),
          _dataSource.loadLibraryItemsByType(libraryId, _serverId,
              title: 'Album Artists',
              includeItemTypes: ['AlbumArtist'],
              sortBy: 'SortName'),
          _dataSource.loadLibraryItemsByType(libraryId, _serverId,
              title: 'Artists',
              includeItemTypes: ['MusicArtist'],
              sortBy: 'SortName'),
          _dataSource.loadLibraryItemsByType(libraryId, _serverId,
              title: 'Albums',
              includeItemTypes: ['MusicAlbum'],
              sortBy: 'DateCreated',
              sortOrder: 'Descending'),
        ]);
      default:
        return Future.wait([
          _dataSource.loadLatestMedia(libraryId, _libraryName, _serverId),
          _dataSource.loadLibraryFavorites(libraryId, _serverId),
        ]);
    }
  }

  Future<void> refresh() async {
    _rows = [];
    notifyListeners();
    await load();
  }
}
