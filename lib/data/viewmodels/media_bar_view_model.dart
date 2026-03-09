import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/media_bar_slide_item.dart';
import '../models/media_bar_state.dart';
import '../repositories/media_bar_repository.dart';

class MediaBarViewModel extends ChangeNotifier {
  final MediaBarRepository _repository;

  MediaBarState _state = const MediaBarLoading();
  MediaBarState get state => _state;

  List<MediaBarSlideItem> get items =>
      _state is MediaBarReady ? (_state as MediaBarReady).items : const [];

  MediaBarViewModel(this._repository);

  Future<void> load({BuildContext? context}) async {
    _state = const MediaBarLoading();
    notifyListeners();

    _state = await _repository.loadItems();
    notifyListeners();

    if (context != null && context.mounted && _state is MediaBarReady) {
      _repository.precacheImages(context, (_state as MediaBarReady).items);
    }
  }
}
