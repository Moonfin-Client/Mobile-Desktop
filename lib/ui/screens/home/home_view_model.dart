import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/home_row.dart';
import '../../../data/services/row_data_source.dart';
import '../../../data/viewmodels/media_bar_view_model.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';

class HomeViewModel extends ChangeNotifier {
  final RowDataSource _dataSource;
  final UserPreferences _prefs;
  final MediaServerClient _client;
  final MediaBarViewModel _mediaBarViewModel;

  List<HomeRow> _rows = [];
  List<HomeRow> get rows => _rows;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get _serverId => _client.baseUrl;
  ImageApi get imageApi => _dataSource.imageApi;
  MediaBarViewModel get mediaBarViewModel => _mediaBarViewModel;

  HomeViewModel({
    required RowDataSource dataSource,
    required UserPreferences prefs,
    required MediaServerClient client,
    required MediaBarViewModel mediaBarViewModel,
  })  : _dataSource = dataSource,
        _prefs = prefs,
        _client = client,
        _mediaBarViewModel = mediaBarViewModel;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    final sections = _prefs.activeHomeSections;
    final placeholders = <HomeRow>[];
    for (final section in sections) {
      final placeholder = _placeholderForSection(section);
      if (placeholder != null) placeholders.add(placeholder);
    }
    _rows = placeholders;
    notifyListeners();

    final loaded = <HomeRow>[];
    for (final section in sections) {
      try {
        final sectionRows = await _loadSection(section);
        loaded.addAll(sectionRows);
      } catch (e) {
        debugPrint('Failed to load section $section: $e');
      }
    }

    _rows = loaded.where((r) => r.items.isNotEmpty).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _rows = [];
    notifyListeners();
    await load();
  }

  Future<void> loadMoreForRow(int rowIndex) async {
    if (rowIndex < 0 || rowIndex >= _rows.length) return;
    final row = _rows[rowIndex];
    if (!row.hasMore) return;

    try {
      final items = await _dataSource.loadMore(row: row, serverId: _serverId);
      _rows = List.of(_rows);
      _rows[rowIndex] = row.copyWith(items: items);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load more for ${row.id}: $e');
    }
  }

  Future<List<HomeRow>> _loadSection(HomeSectionType section) async {
    switch (section) {
      case HomeSectionType.resume:
        return [await _dataSource.loadResume(_serverId)];
      case HomeSectionType.resumeAudio:
        return [await _dataSource.loadResumeAudio(_serverId)];
      case HomeSectionType.nextUp:
        return [await _dataSource.loadNextUp(_serverId)];
      case HomeSectionType.latestMedia:
        return _loadLatestMediaRows();
      case HomeSectionType.playlists:
        return [await _dataSource.loadPlaylists(_serverId)];
      case HomeSectionType.libraryTilesSmall:
      case HomeSectionType.libraryButtons:
        return [await _dataSource.loadLibraryTiles(_serverId)];
      case HomeSectionType.liveTv:
        return [
          const HomeRow(
            id: 'liveTv',
            title: 'Live TV',
            rowType: HomeRowType.liveTv,
          ),
        ];
      case HomeSectionType.activeRecordings:
        return [
          const HomeRow(
            id: 'activeRecordings',
            title: 'Active Recordings',
            rowType: HomeRowType.activeRecordings,
          ),
        ];
      case HomeSectionType.mediaBar:
        _mediaBarViewModel.load();
        return [];
      case HomeSectionType.recentlyReleased:
      case HomeSectionType.resumeBook:
      case HomeSectionType.none:
        return [];
    }
  }

  Future<List<HomeRow>> _loadLatestMediaRows() async {
    final viewsResponse = await _client.userViewsApi.getUserViews();
    final views = viewsResponse['Items'] as List? ?? [];
    final rows = <HomeRow>[];

    for (final view in views) {
      final data = view as Map<String, dynamic>;
      final collectionType = data['CollectionType'] as String?;
      if (collectionType == 'music' ||
          collectionType == 'books' ||
          collectionType == 'playlists' ||
          collectionType == 'boxsets') {
        continue;
      }
      final id = data['Id'] as String;
      final name = data['Name'] as String? ?? '';
      try {
        final row = await _dataSource.loadLatestMedia(id, name, _serverId);
        if (row.items.isNotEmpty) rows.add(row);
      } catch (e) {
        debugPrint('Failed to load latest for $name: $e');
      }
    }
    return rows;
  }

  HomeRow? _placeholderForSection(HomeSectionType section) {
    switch (section) {
      case HomeSectionType.resume:
        return const HomeRow(
          id: 'resume', title: 'Continue Watching',
          rowType: HomeRowType.resume, isLoading: true,
        );
      case HomeSectionType.resumeAudio:
        return const HomeRow(
          id: 'resumeAudio', title: 'Continue Listening',
          rowType: HomeRowType.resumeAudio, isLoading: true,
        );
      case HomeSectionType.nextUp:
        return const HomeRow(
          id: 'nextUp', title: 'Next Up',
          rowType: HomeRowType.nextUp, isLoading: true,
        );
      case HomeSectionType.latestMedia:
        return const HomeRow(
          id: 'latestMedia', title: 'Latest Media',
          rowType: HomeRowType.latestMedia, isLoading: true,
        );
      case HomeSectionType.playlists:
        return const HomeRow(
          id: 'playlists', title: 'Playlists',
          rowType: HomeRowType.playlists, isLoading: true,
        );
      case HomeSectionType.libraryTilesSmall:
      case HomeSectionType.libraryButtons:
        return const HomeRow(
          id: 'libraryTiles', title: 'My Libraries',
          rowType: HomeRowType.libraryTiles, isLoading: true,
        );
      case HomeSectionType.liveTv:
      case HomeSectionType.activeRecordings:
      case HomeSectionType.mediaBar:
      case HomeSectionType.recentlyReleased:
      case HomeSectionType.resumeBook:
      case HomeSectionType.none:
        return null;
    }
  }
}
