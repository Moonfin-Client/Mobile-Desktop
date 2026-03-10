import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';
import '../models/home_row.dart';
import '../services/row_data_source.dart';

class MusicBrowseViewModel extends ChangeNotifier {
  final RowDataSource _dataSource;
  final MediaServerClient _client;
  final String libraryId;

  List<HomeRow> _rows = [];
  List<HomeRow> get rows => _rows;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _libraryName = '';
  String get libraryName => _libraryName;

  AggregatedItem? _focusedItem;
  AggregatedItem? get focusedItem => _focusedItem;

  String get _serverId => _client.baseUrl;
  ImageApi get imageApi => _dataSource.imageApi;

  MusicBrowseViewModel({
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
      _libraryName = itemData['Name'] as String? ?? 'Music';
    } catch (e) {
      debugPrint('Failed to load library info: $e');
    }

    try {
      final results = await Future.wait([
        _dataSource.loadLatestMedia(libraryId, _libraryName, _serverId),
        _dataSource.loadLibraryLastPlayed(libraryId, _serverId,
            includeItemTypes: ['Audio']),
        _dataSource.loadLibraryFavorites(libraryId, _serverId,
            includeItemTypes: ['MusicAlbum']),
        _dataSource.loadPlaylists(_serverId),
      ]);

      _rows = results.where((r) => r.items.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Failed to load music rows: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _rows = [];
    notifyListeners();
    await load();
  }

  String getMusicSubtitle(AggregatedItem item) {
    switch (item.type) {
      case 'Audio':
      case 'MusicAlbum':
        if (item.artists.isNotEmpty) return item.artists.join(', ');
        if (item.albumArtists.isNotEmpty) {
          return item.albumArtists
              .map((a) => a['Name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .join(', ');
        }
        return item.albumArtist ?? '';
      case 'Playlist':
        final count = item.childCount;
        return count != null && count > 0 ? '$count items' : '';
      case 'MusicArtist':
        final count = item.recursiveItemCount;
        return count != null && count > 0 ? '$count albums' : '';
      default:
        return '';
    }
  }

  String? getMusicImageUrl(AggregatedItem item) {
    final albumPrimaryTag = item.rawData['AlbumPrimaryImageTag'] as String?;
    final albumId = item.rawData['AlbumId'] as String?;
    if (item.type == 'Audio' && albumPrimaryTag != null && albumId != null) {
      return imageApi.getPrimaryImageUrl(albumId,
          maxHeight: 300, tag: albumPrimaryTag);
    }
    if (item.primaryImageTag != null) {
      return imageApi.getPrimaryImageUrl(item.id,
          maxHeight: 300, tag: item.primaryImageTag);
    }
    final parentPrimaryTag =
        (item.rawData['ParentPrimaryImageTag'] as String?) ??
            (item.rawData['ImageTags'] as Map?)?['ParentPrimary'] as String?;
    final parentPrimaryId =
        item.rawData['ParentPrimaryImageItemId'] as String? ?? item.parentId;
    if (parentPrimaryTag != null && parentPrimaryId != null) {
      return imageApi.getPrimaryImageUrl(parentPrimaryId,
          maxHeight: 300, tag: parentPrimaryTag);
    }
    return null;
  }
}
