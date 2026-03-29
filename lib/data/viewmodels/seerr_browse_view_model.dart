import 'package:flutter/foundation.dart';

import '../repositories/seerr_repository.dart';
import '../services/seerr/seerr_api_models.dart';

enum SeerrBrowseFilter { all, available, requested }

class SeerrSortOption {
  final String label;
  final String value;
  const SeerrSortOption(this.label, this.value);
}

const seerrSortOptions = [
  SeerrSortOption('Popularity', 'popularity.desc'),
  SeerrSortOption('Rating', 'vote_average.desc'),
  SeerrSortOption('Release Date', 'primary_release_date.desc'),
  SeerrSortOption('Title', 'original_title.asc'),
  SeerrSortOption('Revenue', 'revenue.desc'),
];

class SeerrBrowseState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<SeerrDiscoverItem> items;
  final int currentPage;
  final int totalPages;
  final SeerrSortOption sortBy;
  final SeerrBrowseFilter filter;
  final String letterFilter;

  const SeerrBrowseState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.items = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.sortBy = const SeerrSortOption('Popularity', 'popularity.desc'),
    this.filter = SeerrBrowseFilter.all,
    this.letterFilter = '',
  });

  bool get canLoadMore => currentPage < totalPages && !isLoadingMore;

  SeerrBrowseState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<SeerrDiscoverItem>? items,
    int? currentPage,
    int? totalPages,
    SeerrSortOption? sortBy,
    SeerrBrowseFilter? filter,
    String? letterFilter,
  }) =>
      SeerrBrowseState(
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        items: items ?? this.items,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        sortBy: sortBy ?? this.sortBy,
        filter: filter ?? this.filter,
        letterFilter: letterFilter ?? this.letterFilter,
      );
}

class SeerrBrowseViewModel extends ChangeNotifier {
  final SeerrRepository _repo;
  final String? filterId;
  final String mediaType;
  final String? filterType;

  bool _requestLookupLoaded = false;
  final Map<int, List<SeerrRequest>> _requestsByMediaId = {};
  final Map<int, List<SeerrRequest>> _requestsByTmdbId = {};

  SeerrBrowseState _state = const SeerrBrowseState();
  SeerrBrowseState get state => _state;

  SeerrBrowseViewModel(
    this._repo, {
    this.filterId,
    required this.mediaType,
    this.filterType,
  });

  Future<void> load() async {
    _state = SeerrBrowseState(
      isLoading: true,
      sortBy: _state.sortBy,
      filter: _state.filter,
      letterFilter: _state.letterFilter,
    );
    notifyListeners();

    try {
      await _repo.ensureInitialized();
      final page = await _fetchPage(1);
      await _ensureRequestLookup();
      final enriched = _attachRequesters(page.results);
      _state = _state.copyWith(
        isLoading: false,
        items: _applyFilter(enriched),
        currentPage: page.page,
        totalPages: page.totalPages,
      );
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_state.canLoadMore) return;

    _state = _state.copyWith(isLoadingMore: true);
    notifyListeners();

    try {
      final nextPage = _state.currentPage + 1;
      final page = await _fetchPage(nextPage);
      await _ensureRequestLookup();
      final enriched = _attachRequesters(page.results);
      _state = _state.copyWith(
        isLoadingMore: false,
        items: [..._state.items, ..._applyFilter(enriched)],
        currentPage: page.page,
        totalPages: page.totalPages,
      );
    } catch (e) {
      _state = _state.copyWith(isLoadingMore: false);
    }
    notifyListeners();
  }

  void setSortBy(SeerrSortOption option) {
    if (option.value == _state.sortBy.value) return;
    _state = _state.copyWith(sortBy: option);
    load();
  }

  void setFilter(SeerrBrowseFilter filter) {
    if (filter == _state.filter) return;
    _state = _state.copyWith(filter: filter);
    load();
  }

  void setLetterFilter(String letter) {
    if (letter == _state.letterFilter) return;
    _state = _state.copyWith(letterFilter: letter);
    load();
  }

  Future<SeerrDiscoverPage> _fetchPage(int page) {
    final id = filterId != null ? int.tryParse(filterId!) : null;
    if (mediaType == 'tv') {
      return _repo.discoverTv(
        page: page,
        sortBy: _state.sortBy.value,
        genre: filterType == 'genre' ? id : null,
        network: filterType == 'network' ? id : null,
        keywords: filterType == 'keyword' ? id : null,
      );
    }
    return _repo.discoverMovies(
      page: page,
      sortBy: _state.sortBy.value,
      genre: filterType == 'genre' ? id : null,
      studio: filterType == 'studio' ? id : null,
      keywords: filterType == 'keyword' ? id : null,
    );
  }

  Future<void> _ensureRequestLookup() async {
    if (_requestLookupLoaded) return;
    try {
      final user = await _repo.getCurrentUser();
      const pageSize = 200;
      const maxItems = 1000;
      var offset = 0;

      while (offset < maxItems) {
        final response = await _repo.getRequests(
          requestedBy: user.canViewAllRequests ? null : user.id,
          limit: pageSize,
          offset: offset,
        );

        for (final req in response.results) {
          if (req.status != SeerrRequest.statusPending &&
              req.status != SeerrRequest.statusApproved) {
            continue;
          }

          final media = req.media;
          if (media == null) continue;

          _requestsByMediaId.putIfAbsent(media.id, () => []).add(req);
          final tmdbId = media.tmdbId;
          if (tmdbId != null) {
            _requestsByTmdbId.putIfAbsent(tmdbId, () => []).add(req);
          }
        }

        if (response.results.length < pageSize) {
          break;
        }

        offset += pageSize;
      }
    } catch (_) {
    } finally {
      _requestLookupLoaded = true;
    }
  }

  List<SeerrDiscoverItem> _attachRequesters(List<SeerrDiscoverItem> items) {
    if (_requestsByMediaId.isEmpty && _requestsByTmdbId.isEmpty) {
      return items;
    }

    return items.map((item) {
      final status = item.mediaInfo?.status;
      if (status != 2 && status != 3) {
        return item;
      }

      final mediaInfo = item.mediaInfo;
      if (mediaInfo == null || (mediaInfo.requests?.isNotEmpty ?? false)) {
        return item;
      }

      final byMediaId = mediaInfo.id != null ? _requestsByMediaId[mediaInfo.id!] : null;
      final byTmdbId = mediaInfo.tmdbId != null
          ? _requestsByTmdbId[mediaInfo.tmdbId!]
          : _requestsByTmdbId[item.id];
      final requests = byMediaId ?? byTmdbId;

      if (requests == null || requests.isEmpty) {
        return item;
      }

      return SeerrDiscoverItem(
        id: item.id,
        mediaType: item.mediaType,
        title: item.title,
        name: item.name,
        originalTitle: item.originalTitle,
        originalName: item.originalName,
        posterPath: item.posterPath,
        backdropPath: item.backdropPath,
        overview: item.overview,
        releaseDate: item.releaseDate,
        firstAirDate: item.firstAirDate,
        originalLanguage: item.originalLanguage,
        genreIds: item.genreIds,
        voteAverage: item.voteAverage,
        voteCount: item.voteCount,
        popularity: item.popularity,
        adult: item.adult,
        mediaInfo: SeerrMediaInfo(
          id: mediaInfo.id,
          tmdbId: mediaInfo.tmdbId,
          tvdbId: mediaInfo.tvdbId,
          status: mediaInfo.status,
          status4k: mediaInfo.status4k,
          requests: requests,
        ),
        character: item.character,
        job: item.job,
        department: item.department,
      );
    }).toList();
  }

  List<SeerrDiscoverItem> _applyFilter(List<SeerrDiscoverItem> items) {
    final letterFilter = _state.letterFilter;
    return items.where((item) {
      final matchesStatus = switch (_state.filter) {
        SeerrBrowseFilter.available =>
          item.mediaInfo?.status == 4 || item.mediaInfo?.status == 5,
        SeerrBrowseFilter.requested =>
          item.mediaInfo?.status == 2 || item.mediaInfo?.status == 3,
        SeerrBrowseFilter.all => true,
      };

      if (!matchesStatus) {
        return false;
      }

      if (letterFilter.isEmpty) {
        return true;
      }

      final title = item.displayTitle.trim();
      if (title.isEmpty) {
        return false;
      }

      final first = title[0].toUpperCase();
      if (letterFilter == '#') {
        return !RegExp(r'[A-Z]').hasMatch(first);
      }

      return first == letterFilter;
    }).toList();
  }
}
