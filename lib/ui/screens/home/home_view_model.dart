import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/models/home_row.dart';
import '../../../data/repositories/multi_server_repository.dart';
import '../../../data/services/row_data_source.dart';
import '../../../data/viewmodels/media_bar_view_model.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';

class HomeViewModel extends ChangeNotifier {
  final RowDataSource _dataSource;
  final UserPreferences _prefs;
  final MediaServerClient _client;
  final MediaBarViewModel _mediaBarViewModel;
  final MultiServerRepository _multiServerRepo;

  List<HomeRow> _rows = [];
  List<HomeRow> get rows => _rows;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get _serverId => _client.baseUrl;
  MediaBarViewModel get mediaBarViewModel => _mediaBarViewModel;

  bool get _multiServerEnabled =>
      _prefs.get(UserPreferences.enableMultiServerLibraries);

  ImageApi imageApiForServer(String serverId) {
    if (!_multiServerEnabled) return _dataSource.imageApi;
    return _multiServerRepo.getImageApiForServer(serverId);
  }

  HomeViewModel({
    required RowDataSource dataSource,
    required UserPreferences prefs,
    required MediaServerClient client,
    required MediaBarViewModel mediaBarViewModel,
    required MultiServerRepository multiServerRepo,
  })  : _dataSource = dataSource,
        _prefs = prefs,
        _client = client,
        _mediaBarViewModel = mediaBarViewModel,
        _multiServerRepo = multiServerRepo;

  Future<void> load({bool preserveExisting = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    _mediaBarViewModel.load();

    final activeSections = _prefs.activeHomeSections;
    final sections = activeSections.isEmpty
        ? const [
            HomeSectionType.resume,
            HomeSectionType.nextUp,
            HomeSectionType.latestMedia,
          ]
      : activeSections;
    final merge = _prefs.get(UserPreferences.mergeContinueWatchingNextUp);

    if (!preserveExisting || _rows.isEmpty) {
      final placeholders = <HomeRow>[];
      for (final section in sections) {
        if (merge && section == HomeSectionType.nextUp) continue;
        final placeholder = _placeholderForSection(section);
        if (placeholder != null) {
          if (merge && section == HomeSectionType.resume) {
            placeholders.add(placeholder.copyWith(
              title: 'Continue Watching & Next Up',
            ));
          } else {
            placeholders.add(placeholder);
          }
        }
      }
      _rows = placeholders;
      notifyListeners();
    }

    final effectiveSections = sections
        .where((section) => !(merge && section == HomeSectionType.nextUp))
        .toList();

    final nonResumeEffectiveSections = merge
        ? effectiveSections.where((s) => s != HomeSectionType.resume).toList()
        : effectiveSections;

    final sectionTasks = nonResumeEffectiveSections.map((section) async {
      try {
        final sectionRows = await _loadSection(section);
        return sectionRows;
      } catch (_) {
        return const <HomeRow>[];
      }
    }).toList();

    final sectionResults = await Future.wait(sectionTasks);
    final loaded = sectionResults.expand((rows) => rows).toList();

    _rows = loaded.where((r) => r.items.isNotEmpty || r.rowType == HomeRowType.liveTv).toList();
    
    if (merge) {
      final resumePlaceholder = _placeholderForSection(HomeSectionType.resume);
      if (resumePlaceholder != null && !_rows.any((r) => r.id == 'resume')) {
        _rows.insert(0, resumePlaceholder.copyWith(
          title: 'Continue Watching & Next Up',
        ));
      }
    }
    
    _isLoading = false;
    notifyListeners();

    if (merge) {
      _loadResumeAndNextUpInBackground();
    }
  }

  Future<void> refresh({bool preserveExisting = true}) async {
    await load(preserveExisting: preserveExisting);
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
    } catch (_) {}
  }

  Future<List<HomeRow>> _loadSection(HomeSectionType section) async {
    switch (section) {
      case HomeSectionType.resume:
        return [_multiServerEnabled
            ? await _multiServerRepo.getAggregatedResume()
            : await _dataSource.loadResume(_serverId)];
      case HomeSectionType.resumeAudio:
        return [_multiServerEnabled
            ? await _multiServerRepo.getAggregatedResumeAudio()
            : await _dataSource.loadResumeAudio(_serverId)];
      case HomeSectionType.nextUp:
        return [_multiServerEnabled
            ? await _multiServerRepo.getAggregatedNextUp()
            : await _dataSource.loadNextUp(_serverId)];
      case HomeSectionType.latestMedia:
        return _multiServerEnabled
            ? await _multiServerRepo.getAggregatedLatestMediaRows()
            : _loadLatestMediaRows();
      case HomeSectionType.playlists:
        return [_multiServerEnabled
            ? await _multiServerRepo.getAggregatedPlaylists()
            : await _dataSource.loadPlaylists(_serverId)];
      case HomeSectionType.libraryTilesSmall:
        return [_multiServerEnabled
            ? await _multiServerRepo.getAggregatedLibraryTiles(rowType: HomeRowType.libraryTiles)
            : await _dataSource.loadLibraryTiles(_serverId, HomeRowType.libraryTiles)];
      case HomeSectionType.libraryButtons:
        return [_multiServerEnabled
            ? await _multiServerRepo.getAggregatedLibraryTiles(rowType: HomeRowType.libraryTilesSmall)
            : await _dataSource.loadLibraryTiles(_serverId, HomeRowType.libraryTilesSmall)];
      case HomeSectionType.liveTv:
        final rows = <HomeRow>[
          const HomeRow(
            id: 'liveTv',
            title: 'Live TV',
            rowType: HomeRowType.liveTv,
            items: [],
          ),
        ];
        try {
          final onNow = await _dataSource.loadOnNow(_serverId);
          if (onNow.items.isNotEmpty) rows.add(onNow);
        } catch (_) {}
        return rows;
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

    Set<String> latestExcludes = const {};
    try {
      final config = await _client.usersApi.getUserConfiguration();
      latestExcludes = config.latestItemsExcludes.toSet();
    } catch (_) {}

    final filteredViews = views
        .cast<Map<String, dynamic>>()
        .where((data) {
          final id = data['Id'] as String;
          final collectionType = data['CollectionType'] as String?;
          if (collectionType == 'music' ||
              collectionType == 'books' ||
              collectionType == 'playlists' ||
              collectionType == 'boxsets' ||
              collectionType == 'livetv') {
            return false;
          }
          return !latestExcludes.contains(id);
        })
        .toList();

    final tasks = filteredViews.map((data) async {
      final id = data['Id'] as String;
      final name = data['Name'] as String? ?? '';
      try {
        final row = await _dataSource.loadLatestMedia(id, name, _serverId);
        return row.items.isNotEmpty ? row : null;
      } catch (_) {
        return null;
      }
    }).toList();

    final resolved = await Future.wait(tasks);
    final rows = resolved.whereType<HomeRow>().toList();
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
        return const HomeRow(
          id: 'libraryTiles', title: 'My Media',
          rowType: HomeRowType.libraryTiles, isLoading: true,
        );
      case HomeSectionType.libraryButtons:
        return const HomeRow(
          id: 'libraryTilesSmall', title: 'My Media',
          rowType: HomeRowType.libraryTilesSmall, isLoading: true,
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

  void _loadResumeAndNextUpInBackground() {
    unawaited(() async {
      try {
        if (_multiServerEnabled) {
          final resumeFuture = _multiServerRepo.getAggregatedResume();
          final nextUpFuture = () async {
            try {
              return await _multiServerRepo.getAggregatedNextUp();
            } catch (_) {
              return null;
            }
          }();

          final resumeRow = await resumeFuture;
          final nextUpRow = await nextUpFuture;

          final mergedItemsMap = <String, AggregatedItem>{};
          for (final item in resumeRow.items) {
            mergedItemsMap[item.id] = item;
          }
          for (final item in nextUpRow?.items ?? []) {
            mergedItemsMap.putIfAbsent(item.id, () => item);
          }
          final mergedItems = mergedItemsMap.values.toList();

          const resumeId = 'resume';
          final resumeIndex = _rows.indexWhere((r) => r.id == resumeId);
          if (resumeIndex >= 0) {
            _rows = List.of(_rows);
            _rows[resumeIndex] = _rows[resumeIndex].copyWith(
              items: mergedItems,
              isLoading: false,
            );
            notifyListeners();
          }
        } else {
          final relaxedRows = await Future.wait([
            _dataSource.loadResumeRelaxed(_serverId),
            _dataSource.loadNextUpRelaxed(_serverId),
          ]);
          final resumeRow = relaxedRows[0];
          final nextUpRow = relaxedRows[1];
          final mergedItemsMap = <String, AggregatedItem>{};
          for (final item in resumeRow.items) {
            mergedItemsMap[item.id] = item;
          }
          for (final item in nextUpRow.items) {
            mergedItemsMap.putIfAbsent(item.id, () => item);
          }
          final mergedItems = mergedItemsMap.values.toList();

          const resumeId = 'resume';
          final resumeIndex = _rows.indexWhere((r) => r.id == resumeId);
          if (resumeIndex >= 0) {
            _rows = List.of(_rows);
            _rows[resumeIndex] = _rows[resumeIndex].copyWith(
              items: mergedItems,
              isLoading: false,
            );
            notifyListeners();
          }
        }
      } catch (_) {}
    }());
  }
}

