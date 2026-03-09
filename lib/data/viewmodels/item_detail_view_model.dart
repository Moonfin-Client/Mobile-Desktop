import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';
import '../repositories/item_mutation_repository.dart';
import '../repositories/mdblist_repository.dart';

enum ItemDetailState { loading, ready, error }

class ItemDetailViewModel extends ChangeNotifier {
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

  Map<String, double> _ratings = const {};
  Map<String, double> get ratings => _ratings;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ImageApi get imageApi => _client.imageApi;
  String get baseUrl => _client.baseUrl;

  ItemDetailViewModel({
    required this.itemId,
    required MediaServerClient client,
    required ItemMutationRepository mutations,
    required MdbListRepository mdbListRepository,
  })  : _client = client,
        _mutations = mutations,
        _mdbListRepository = mdbListRepository;

  Future<void> load() async {
    _state = ItemDetailState.loading;
    notifyListeners();

    try {
      final data = await _client.itemsApi.getItem(itemId);
      _item = AggregatedItem(
        id: itemId,
        serverId: _client.baseUrl,
        rawData: data,
      );
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
    await Future.wait([
      _loadSimilar(),
      _loadRatings(),
    ]);
  }

  Future<void> _loadSimilar() async {
    try {
      final data = await _client.itemsApi.getSimilarItems(itemId, limit: 12);
      final items = (data['Items'] as List?) ?? [];
      _similar = items
          .cast<Map<String, dynamic>>()
          .map((raw) => AggregatedItem(
                id: raw['Id'] as String,
                serverId: _client.baseUrl,
                rawData: raw,
              ))
          .toList();
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
    try {
      await _mutations.setFavorite(itemId, isFavorite: newState);
      await _reload();
    } catch (_) {}
  }

  Future<void> togglePlayed() async {
    final item = _item;
    if (item == null) return;
    final newState = !item.isPlayed;
    try {
      await _mutations.setPlayed(itemId, isPlayed: newState);
      await _reload();
    } catch (_) {}
  }

  Future<void> _reload() async {
    try {
      final data = await _client.itemsApi.getItem(itemId);
      _item = AggregatedItem(
        id: itemId,
        serverId: _client.baseUrl,
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
}
