import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:server_core/server_core.dart';

import '../../preference/user_preferences.dart';
import '../models/media_bar_slide_item.dart';
import '../models/media_bar_state.dart';
import '../repositories/mdblist_repository.dart';
import '../repositories/media_bar_repository.dart';

class MediaBarViewModel extends ChangeNotifier {
  final MediaBarRepository _repository;
  final MdbListRepository _mdbListRepository;
  final UserPreferences _prefs;
  final MediaServerClient _client;

  MediaBarState _state = const MediaBarLoading();
  MediaBarState get state => _state;

  final _ratings = <String, Map<String, double>>{};

  String get baseUrl => _client.baseUrl;

  List<MediaBarSlideItem> get items =>
      _state is MediaBarReady ? (_state as MediaBarReady).items : const [];

  Map<String, double> ratingsFor(String itemId) =>
      _ratings[itemId] ?? const {};

  MediaBarViewModel(
    this._repository,
    this._mdbListRepository,
    this._prefs,
    this._client,
  );

  Future<void> load({BuildContext? context}) async {
    _state = const MediaBarLoading();
    notifyListeners();

    _state = await _repository.loadItems();
    notifyListeners();

    if (context != null && context.mounted && _state is MediaBarReady) {
      _repository.precacheImages(context, (_state as MediaBarReady).items);
    }

    if (_state is MediaBarReady) {
      _loadRatings((_state as MediaBarReady).items);
    }
  }

  Future<void> _loadRatings(List<MediaBarSlideItem> items) async {
    if (!_prefs.get(UserPreferences.enableAdditionalRatings)) return;

    final futures = <Future<void>>[];
    for (final item in items) {
      if (item.tmdbId == null) continue;
      futures.add(_loadItemRatings(item));
    }
    await Future.wait(futures);
  }

  Future<void> _loadItemRatings(MediaBarSlideItem item) async {
    try {
      final result = await _mdbListRepository.getRatings(
        tmdbId: item.tmdbId!,
        mediaType: item.itemType,
      );
      if (result != null && result.isNotEmpty) {
        _ratings[item.itemId] = result;
        notifyListeners();
      }
    } catch (_) {}
  }
}
