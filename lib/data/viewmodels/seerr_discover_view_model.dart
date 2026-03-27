import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../preference/preference_constants.dart';
import '../../preference/seerr_preferences.dart';
import '../repositories/seerr_repository.dart';
import '../services/seerr/seerr_api_models.dart';

class SeerrDiscoverRow {
  final SeerrRowType type;
  final String title;
  final List<SeerrDiscoverItem> items;
  final List<SeerrGenre> genres;
  final List<SeerrNetwork> networks;
  final List<SeerrStudio> studios;
  final bool isLoading;
  final int page;
  final int totalPages;

  const SeerrDiscoverRow({
    required this.type,
    required this.title,
    this.items = const [],
    this.genres = const [],
    this.networks = const [],
    this.studios = const [],
    this.isLoading = false,
    this.page = 1,
    this.totalPages = 1,
  });

  SeerrDiscoverRow copyWith({
    List<SeerrDiscoverItem>? items,
    List<SeerrGenre>? genres,
    List<SeerrNetwork>? networks,
    List<SeerrStudio>? studios,
    bool? isLoading,
    int? page,
    int? totalPages,
  }) =>
      SeerrDiscoverRow(
        type: type,
        title: title,
        items: items ?? this.items,
        genres: genres ?? this.genres,
        networks: networks ?? this.networks,
        studios: studios ?? this.studios,
        isLoading: isLoading ?? this.isLoading,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
      );

  bool get hasMore => page < totalPages;
  bool get isGenreRow => type == SeerrRowType.movieGenres || type == SeerrRowType.seriesGenres;
  bool get isNetworkRow => type == SeerrRowType.networks;
  bool get isStudioRow => type == SeerrRowType.studios;
  bool get isMediaRow => !isGenreRow && !isNetworkRow && !isStudioRow;
}

class SeerrDiscoverViewModel extends ChangeNotifier {
  final SeerrRepository _repo;
  final SeerrPreferences _prefs;

  List<SeerrDiscoverRow> _rows = [];
  List<SeerrDiscoverRow> get rows => _rows;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  SeerrDiscoverViewModel(this._repo, this._prefs);

  static const _nsfwKeywords = [
    r'\bsex\b', 'sexual', r'\bporn\b', 'erotic', r'\bnude\b', 'nudity',
    r'\bxxx\b', 'adult film', 'prostitute', 'stripper', r'\bescort\b',
    'seduction', r'\baffair\b', 'threesome', r'\borgy\b', 'kinky',
    'fetish', r'\bbdsm\b', 'dominatrix',
  ];

  static final _nsfwPatterns =
      _nsfwKeywords.map((k) => RegExp(k, caseSensitive: false)).toList();

  static const _popularNetworks = [
    SeerrNetwork(id: 213, name: 'Netflix', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/wwemzKWzjKYJFfCeiB57q3r4Bcm.png'),
    SeerrNetwork(id: 2739, name: 'Disney+', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/gJ8VX6JSu3ciXHuC2dDGAo2lvwM.png'),
    SeerrNetwork(id: 1024, name: 'Prime Video', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/ifhbNuuVnlwYy5oXA5VIb2YR8AZ.png'),
    SeerrNetwork(id: 2552, name: 'Apple TV+', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/4KAy34EHvRM25Ih8wb82AuGU7zJ.png'),
    SeerrNetwork(id: 453, name: 'Hulu', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/pqUTCleNUiTLAVlelGxUgWn1ELh.png'),
    SeerrNetwork(id: 49, name: 'HBO', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/tuomPhY2UtuPTqqFnKMVHvSb724.png'),
    SeerrNetwork(id: 4353, name: 'Discovery+', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/1D1bS3Dyw4ScYnFWTlBOvJXC3nb.png'),
    SeerrNetwork(id: 2, name: 'ABC', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/ndAvF4JLsliGreX87jAc9GdjmJY.png'),
    SeerrNetwork(id: 19, name: 'FOX', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/1DSpHrWyOORkL9N2QHX7Adt31mQ.png'),
    SeerrNetwork(id: 359, name: 'Cinemax', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/6mSHSquNpfLgDdv6VnOOvC5Uz2h.png'),
    SeerrNetwork(id: 174, name: 'AMC', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/pmvRmATOCaDykE6JrVoeYxlFHw3.png'),
    SeerrNetwork(id: 67, name: 'Showtime', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/Allse9kbjiP6ExaQrnSpIhkurEi.png'),
    SeerrNetwork(id: 318, name: 'Starz', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/8GJjw3HHsAJYwIWKIPBPfqMxlEa.png'),
    SeerrNetwork(id: 71, name: 'The CW', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/ge9hzeaU7nMtQ4PjkFlc68dGAJ9.png'),
    SeerrNetwork(id: 6, name: 'NBC', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/o3OedEP0f9mfZr33jz2BfXOUK5.png'),
    SeerrNetwork(id: 16, name: 'CBS', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/nm8d7P7MJNiBLdgIzUK0gkuEA4r.png'),
    SeerrNetwork(id: 4330, name: 'Paramount+', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/fi83B1oztoS47xxcemFdPMhIzK.png'),
    SeerrNetwork(id: 4, name: 'BBC One', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/mVn7xESaTNmjBUyUtGNvDQd3CT1.png'),
    SeerrNetwork(id: 56, name: 'Cartoon Network', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/c5OC6oVCg6QP4eqzW6XIq17CQjI.png'),
    SeerrNetwork(id: 80, name: 'Adult Swim', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/9AKyspxVzywuaMuZ1Bvilu8sXly.png'),
    SeerrNetwork(id: 13, name: 'Nickelodeon', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/ikZXxg6GnwpzqiZbRPhJGaZapqB.png'),
    SeerrNetwork(id: 3353, name: 'Peacock', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/gIAcGTjKKr0KOHL5s4O36roJ8p7.png'),
  ];

  static const _popularStudios = [
    SeerrStudio(id: 2, name: 'Disney', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/wdrCwmRnLFJhEoH8GSfymY85KHT.png'),
    SeerrStudio(id: 127928, name: '20th Century Studios', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/h0rjX5vjW5r8yEnUBStFarjcLT4.png'),
    SeerrStudio(id: 34, name: 'Sony Pictures', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/GagSvqWlyPdkFHMfQ3pNq6ix9P.png'),
    SeerrStudio(id: 174, name: 'Warner Bros. Pictures', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/ky0xOc5OrhzkZ1N6KyUxacfQsCk.png'),
    SeerrStudio(id: 33, name: 'Universal', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/8lvHyhjr8oUKOOy2dKXoALWKdp0.png'),
    SeerrStudio(id: 4, name: 'Paramount', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/fycMZt242LVjagMByZOLUGbCvv3.png'),
    SeerrStudio(id: 3, name: 'Pixar', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/1TjvGVDMYsj6JBxOAkUHpPEwLf7.png'),
    SeerrStudio(id: 521, name: 'DreamWorks', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/kP7t6RwGz2AvvTkvnI1uteEwHet.png'),
    SeerrStudio(id: 420, name: 'Marvel Studios', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/hUzeosd33nzE5MCNsZxCGEKTXaQ.png'),
    SeerrStudio(id: 9993, name: 'DC', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/2Tc1P3Ac8M479naPp1kYT3izLS5.png'),
    SeerrStudio(id: 41077, name: 'A24', logoPath: 'https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)/1ZXsGaFPgrgS6ZZGS37AqD5uU12.png'),
  ];

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.ensureInitialized();
      if (!_repo.isAvailable) {
        _isLoading = false;
        _error = 'Seerr is not configured or unavailable';
        notifyListeners();
        return;
      }

      final activeRows = _prefs.activeRows;
      _rows = activeRows.map((type) => SeerrDiscoverRow(
        type: type,
        title: _titleForRowType(type),
        isLoading: true,
      )).toList();
      notifyListeners();

      await _loadAllRows();
    } catch (e) {
      _error = e.toString();
      debugPrint('[SeerrDiscover] Failed to load: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _rows = [];
    notifyListeners();
    await load();
  }

  Future<void> loadMore(int rowIndex) async {
    if (rowIndex < 0 || rowIndex >= _rows.length) return;
    final row = _rows[rowIndex];
    if (!row.hasMore || row.isLoading || !row.isMediaRow) return;

    _rows = List.of(_rows);
    _rows[rowIndex] = row.copyWith(isLoading: true);
    notifyListeners();

    try {
      final page = await _loadPage(row.type, row.page + 1);
      if (page != null) {
        final filtered = _filterItems(page.results);
        _rows = List.of(_rows);
        _rows[rowIndex] = row.copyWith(
          items: [...row.items, ...filtered],
          page: page.page,
          totalPages: page.totalPages,
          isLoading: false,
        );
      } else {
        _rows = List.of(_rows);
        _rows[rowIndex] = row.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('[SeerrDiscover] Failed to load more for ${row.type}: $e');
      _rows = List.of(_rows);
      _rows[rowIndex] = row.copyWith(isLoading: false);
    }
    notifyListeners();
  }

  Future<void> _loadAllRows() async {
    final futures = <Future<void>>[];
    for (var i = 0; i < _rows.length; i++) {
      futures.add(_loadRow(i));
    }
    await Future.wait(futures);
  }

  Future<void> _loadRow(int index) async {
    final row = _rows[index];
    try {
      switch (row.type) {
        case SeerrRowType.recentRequests:
          await _loadRecentRequests(index);
        case SeerrRowType.movieGenres:
          await _loadGenres(index, isMovie: true);
        case SeerrRowType.seriesGenres:
          await _loadGenres(index, isMovie: false);
        case SeerrRowType.networks:
          _updateRow(index, row.copyWith(
            networks: _popularNetworks,
            isLoading: false,
          ));
        case SeerrRowType.studios:
          _updateRow(index, row.copyWith(
            studios: _popularStudios,
            isLoading: false,
          ));
        default:
          final page = await _loadPage(row.type, 1);
          if (page != null) {
            final filtered = _filterItems(page.results);
            _updateRow(index, row.copyWith(
              items: filtered,
              page: page.page,
              totalPages: page.totalPages,
              isLoading: false,
            ));
          } else {
            _updateRow(index, row.copyWith(isLoading: false));
          }
      }
    } catch (e) {
      debugPrint('[SeerrDiscover] Failed to load row ${row.type}: $e');
      _updateRow(index, row.copyWith(isLoading: false));
    }
  }

  Future<void> _loadRecentRequests(int index) async {
    final row = _rows[index];
    try {
      final user = await _repo.getCurrentUser();
      final response = await _repo.getRequests(
        requestedBy: user.canViewAllRequests ? null : user.id,
        limit: _prefs.fetchLimit.limit,
      );

      final rawItems = response.results
          .where((r) => r.media != null)
          .map((r) {
            final media = r.media!;
            return SeerrDiscoverItem(
              id: media.tmdbId ?? media.id,
              title: media.title ?? media.name,
              name: media.name ?? media.title,
              overview: media.overview,
              releaseDate: media.releaseDate,
              firstAirDate: media.firstAirDate,
              mediaType: r.type,
              posterPath: media.posterPath,
              backdropPath: media.backdropPath,
              mediaInfo: SeerrMediaInfo(
                id: media.id,
                tmdbId: media.tmdbId,
                status: media.status,
              ),
            );
          })
          .toList();

      final items = await Future.wait(rawItems.map(_enrichRequestItem));

      _updateRow(index, row.copyWith(items: items, isLoading: false));
    } catch (e) {
      debugPrint('[SeerrDiscover] Failed to load requests: $e');
      _updateRow(index, row.copyWith(isLoading: false));
    }
  }

  Future<SeerrDiscoverItem> _enrichRequestItem(SeerrDiscoverItem item) async {
    if (item.posterPath != null || item.backdropPath != null) {
      return item;
    }

    final tmdbId = item.mediaInfo?.tmdbId ?? item.id;
    if (tmdbId <= 0) return item;

    try {
      if (item.mediaType == 'tv') {
        final details = await _repo.getTvDetails(tmdbId);
        return SeerrDiscoverItem(
          id: item.id,
          mediaType: item.mediaType,
          title: item.title,
          name: item.name,
          originalTitle: item.originalTitle,
          originalName: item.originalName,
          posterPath: details.posterPath ?? item.posterPath,
          backdropPath: details.backdropPath ?? item.backdropPath,
          overview: item.overview,
          releaseDate: item.releaseDate,
          firstAirDate: item.firstAirDate,
          originalLanguage: item.originalLanguage,
          genreIds: item.genreIds,
          voteAverage: item.voteAverage,
          voteCount: item.voteCount,
          popularity: item.popularity,
          adult: item.adult,
          mediaInfo: item.mediaInfo,
          character: item.character,
          job: item.job,
          department: item.department,
        );
      }

      final details = await _repo.getMovieDetails(tmdbId);
      return SeerrDiscoverItem(
        id: item.id,
        mediaType: item.mediaType,
        title: item.title,
        name: item.name,
        originalTitle: item.originalTitle,
        originalName: item.originalName,
        posterPath: details.posterPath ?? item.posterPath,
        backdropPath: details.backdropPath ?? item.backdropPath,
        overview: item.overview,
        releaseDate: item.releaseDate,
        firstAirDate: item.firstAirDate,
        originalLanguage: item.originalLanguage,
        genreIds: item.genreIds,
        voteAverage: item.voteAverage,
        voteCount: item.voteCount,
        popularity: item.popularity,
        adult: item.adult,
        mediaInfo: item.mediaInfo,
        character: item.character,
        job: item.job,
        department: item.department,
      );
    } catch (_) {
      return item;
    }
  }

  Future<void> _loadGenres(int index, {required bool isMovie}) async {
    final row = _rows[index];
    try {
      final genres = isMovie
          ? await _repo.getGenreSliderMovies()
          : await _repo.getGenreSliderTv();
      _updateRow(index, row.copyWith(genres: genres, isLoading: false));
    } catch (e) {
      debugPrint('[SeerrDiscover] Failed to load genres: $e');
      _updateRow(index, row.copyWith(isLoading: false));
    }
  }

  Future<SeerrDiscoverPage?> _loadPage(SeerrRowType type, int page) async {
    final limit = _prefs.fetchLimit.limit;
    final offset = (page - 1) * limit;
    switch (type) {
      case SeerrRowType.trending:
        return _repo.getTrending(limit: limit, offset: offset);
      case SeerrRowType.popularMovies:
        return _repo.getTrendingMovies(limit: limit, offset: offset);
      case SeerrRowType.popularSeries:
        return _repo.getTrendingTv(limit: limit, offset: offset);
      case SeerrRowType.upcomingMovies:
        return _repo.getUpcomingMovies();
      case SeerrRowType.upcomingSeries:
        return _repo.getUpcomingTv();
      default:
        return null;
    }
  }

  List<SeerrDiscoverItem> _filterItems(List<SeerrDiscoverItem> items) {
    final blockNsfw = _prefs.blockNsfw;
    return items.where((item) {
      if (item.isAvailable || item.isBlacklisted) return false;
      if (blockNsfw && _isNsfw(item)) return false;
      return true;
    }).toList();
  }

  bool _isNsfw(SeerrDiscoverItem item) {
    if (item.adult) return true;
    final text = '${item.displayTitle} ${item.overview ?? ''}';
    return _nsfwPatterns.any((p) => p.hasMatch(text));
  }

  void _updateRow(int index, SeerrDiscoverRow row) {
    _rows = List.of(_rows);
    _rows[index] = row;
    notifyListeners();
  }

  static String _titleForRowType(SeerrRowType type) => switch (type) {
    SeerrRowType.recentRequests => 'Recent Requests',
    SeerrRowType.trending => 'Trending',
    SeerrRowType.popularMovies => 'Popular Movies',
    SeerrRowType.movieGenres => 'Movie Genres',
    SeerrRowType.upcomingMovies => 'Upcoming Movies',
    SeerrRowType.studios => 'Studios',
    SeerrRowType.popularSeries => 'Popular Series',
    SeerrRowType.seriesGenres => 'Series Genres',
    SeerrRowType.upcomingSeries => 'Upcoming Series',
    SeerrRowType.networks => 'Networks',
  };
}
