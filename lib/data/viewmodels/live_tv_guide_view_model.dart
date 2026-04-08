import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

class GuideChannel {
  final String id;
  final String name;
  final String? number;
  final String? imageTag;
  final bool isFavorite;
  final Map<String, dynamic> rawData;

  const GuideChannel({
    required this.id,
    required this.name,
    this.number,
    this.imageTag,
    this.isFavorite = false,
    required this.rawData,
  });
}

class GuideProgram {
  final String id;
  final String channelId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? overview;
  final String? episodeTitle;
  final bool isMovie;
  final bool isSeries;
  final bool isSports;
  final bool isNews;
  final bool isKids;
  final bool isPremiere;
  final bool hasTimer;
  final Map<String, dynamic> rawData;

  const GuideProgram({
    required this.id,
    required this.channelId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.overview,
    this.episodeTitle,
    this.isMovie = false,
    this.isSeries = false,
    this.isSports = false,
    this.isNews = false,
    this.isKids = false,
    this.isPremiere = false,
    this.hasTimer = false,
    required this.rawData,
  });

  Duration get duration => endDate.difference(startDate);

  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  double progressAt(DateTime now) {
    if (now.isBefore(startDate)) return 0;
    if (now.isAfter(endDate)) return 1;
    return now.difference(startDate).inSeconds / duration.inSeconds;
  }
}

enum GuideFilter { all, movies, series, sports, news, kids, premiere, favorites }

enum GuideState { loading, ready, error }

class LiveTvGuideViewModel extends ChangeNotifier {
  final MediaServerClient _client;

  static const _defaultGuideWindowHours = 3;
  static const _fields = 'ImageTags,Overview';

  int _guideWindowHours = _defaultGuideWindowHours;
  int get guideWindowHours => _guideWindowHours;

  LiveTvGuideViewModel(this._client);

  ImageApi get imageApi => _client.imageApi;

  GuideState _state = GuideState.loading;
  GuideState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<GuideChannel> _channels = const [];

  Map<String, List<GuideProgram>> _programsByChannel = const {};

  GuideFilter _filter = GuideFilter.all;
  GuideFilter get filter => _filter;

  DateTime _guideDate = DateTime.now();
  DateTime get guideDate => _guideDate;

  DateTime _windowStart = DateTime.now();
  DateTime get windowStart => _windowStart;

  DateTime _windowEnd = DateTime.now();
  DateTime get windowEnd => _windowEnd;

  List<GuideChannel> get filteredChannels {
    if (_filter == GuideFilter.all) return _channels;
    if (_filter == GuideFilter.favorites) {
      return _channels.where((ch) => ch.isFavorite).toList();
    }
    return _channels.where((ch) {
      final programs = _programsByChannel[ch.id] ?? [];
      return programs.any((p) => _matchesFilter(p));
    }).toList();
  }

  List<GuideProgram> programsForChannel(String channelId) {
    final all = _programsByChannel[channelId] ?? [];
    if (_filter == GuideFilter.all || _filter == GuideFilter.favorites) return all;
    return all.where(_matchesFilter).toList();
  }

  GuideChannel? channelForId(String channelId) {
    for (final channel in _channels) {
      if (channel.id == channelId) return channel;
    }
    return null;
  }

  bool _matchesFilter(GuideProgram p) => switch (_filter) {
    GuideFilter.all => true,
    GuideFilter.movies => p.isMovie,
    GuideFilter.series => p.isSeries,
    GuideFilter.sports => p.isSports,
    GuideFilter.news => p.isNews,
    GuideFilter.kids => p.isKids,
    GuideFilter.premiere => p.isPremiere,
    GuideFilter.favorites => true,
  };

  Future<void> toggleChannelFavorite(String channelId) async {
    final index = _channels.indexWhere((c) => c.id == channelId);
    if (index < 0) return;

    final current = _channels[index];
    final next = !current.isFavorite;

    final optimisticRaw = Map<String, dynamic>.from(current.rawData);
    final userData = Map<String, dynamic>.from(
      (optimisticRaw['UserData'] as Map?) ?? const <String, dynamic>{},
    );
    userData['IsFavorite'] = next;
    optimisticRaw['UserData'] = userData;

    final updated = GuideChannel(
      id: current.id,
      name: current.name,
      number: current.number,
      imageTag: current.imageTag,
      isFavorite: next,
      rawData: optimisticRaw,
    );

    final channels = List<GuideChannel>.from(_channels);
    channels[index] = updated;
    _channels = channels;
    notifyListeners();

    try {
      if (next) {
        await _client.userLibraryApi.markFavorite(channelId);
      } else {
        await _client.userLibraryApi.unmarkFavorite(channelId);
      }
    } catch (_) {
      final reverted = List<GuideChannel>.from(_channels);
      reverted[index] = current;
      _channels = reverted;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> load({int? windowHours}) async {
    if (windowHours != null) _guideWindowHours = windowHours;
    _state = GuideState.loading;
    notifyListeners();

    try {
      await _fetchChannels();

      _windowStart = DateTime(
        _guideDate.year,
        _guideDate.month,
        _guideDate.day,
        DateTime.now().hour,
      );
      _windowEnd = _windowStart.add(Duration(hours: _guideWindowHours));

      await _fetchPrograms();
      _state = GuideState.ready;
    } catch (e) {
      _errorMessage = e.toString();
      _state = GuideState.error;
    }
    notifyListeners();
  }

  void setFilter(GuideFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  Future<void> setDate(DateTime date) async {
    _guideDate = date;
    _windowStart = DateTime(date.year, date.month, date.day, _windowStart.hour);
    _windowEnd = _windowStart.add(Duration(hours: _guideWindowHours));
    await _reloadPrograms();
  }

  Future<void> shiftWindow(int hours) async {
    _windowStart = _windowStart.add(Duration(hours: hours));
    _windowEnd = _windowStart.add(Duration(hours: _guideWindowHours));
    _guideDate = _windowStart;
    await _reloadPrograms();
  }

  Future<void> setWindowHours(int hours) async {
    if (hours == _guideWindowHours) return;
    _guideWindowHours = hours;
    _windowEnd = _windowStart.add(Duration(hours: _guideWindowHours));
    await _reloadPrograms();
  }

  Future<void> _reloadPrograms() async {
    _state = GuideState.loading;
    notifyListeners();

    try {
      await _fetchPrograms();
      _state = GuideState.ready;
    } catch (e) {
      _errorMessage = e.toString();
      _state = GuideState.error;
    }
    notifyListeners();
  }

  Future<void> goToNow() async {
    _guideDate = DateTime.now();
    await load(windowHours: _guideWindowHours);
  }

  Future<void> _fetchChannels() async {
    final response = await _client.liveTvApi.getChannels(
      sortBy: 'SortName',
      sortOrder: 'Ascending',
      fields: 'ImageTags,UserData',
      enableTotalRecordCount: false,
      userId: _client.userId,
    );
    final items = (response['Items'] as List?) ?? [];
    _channels = items.cast<Map<String, dynamic>>().map((raw) {
      return GuideChannel(
        id: raw['Id'] as String,
        name: raw['Name'] as String? ?? '',
        number: raw['ChannelNumber'] as String?,
        imageTag: (raw['ImageTags'] as Map?)?['Primary'] as String?,
        isFavorite: ((raw['UserData'] as Map?)?['IsFavorite'] == true),
        rawData: raw,
      );
    }).toList();
  }

  Future<void> _fetchPrograms() async {
    if (_channels.isEmpty) {
      _programsByChannel = const {};
      return;
    }

    final channelIds = _channels.map((c) => c.id).toList();
    final response = await _client.liveTvApi.getGuide(
      startDate: _windowStart,
      endDate: _windowEnd,
      channelIds: channelIds,
      fields: _fields,
      enableTotalRecordCount: false,
      userId: _client.userId,
    );

    final items = (response['Items'] as List?) ?? [];
    final map = <String, List<GuideProgram>>{};

    for (final raw in items.cast<Map<String, dynamic>>()) {
      final channelId = raw['ChannelId'] as String?;
      if (channelId == null) continue;

      final startStr = raw['StartDate'] as String?;
      final endStr = raw['EndDate'] as String?;
      if (startStr == null || endStr == null) continue;

      final program = GuideProgram(
        id: raw['Id'] as String,
        channelId: channelId,
        name: raw['Name'] as String? ?? '',
        startDate: DateTime.parse(startStr).toLocal(),
        endDate: DateTime.parse(endStr).toLocal(),
        overview: raw['Overview'] as String?,
        episodeTitle: raw['EpisodeTitle'] as String?,
        isMovie: raw['IsMovie'] == true,
        isSeries: raw['IsSeries'] == true,
        isSports: raw['IsSports'] == true,
        isNews: raw['IsNews'] == true,
        isKids: raw['IsKids'] == true,
        isPremiere: raw['IsPremiere'] == true,
        hasTimer: raw['TimerId'] != null,
        rawData: raw,
      );

      map.putIfAbsent(channelId, () => []).add(program);
    }

    for (final list in map.values) {
      list.sort((a, b) => a.startDate.compareTo(b.startDate));
    }

    _programsByChannel = map;
  }
}
