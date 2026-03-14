import 'dart:async';
import 'dart:math';

enum RepeatMode { none, repeatOne, repeatAll }

class QueueService {
  final List<dynamic> _items = [];
  final List<dynamic> _originalOrder = [];
  int _currentIndex = -1;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _shuffled = false;

  final _queueChangedController = StreamController<void>.broadcast();

  Stream<void> get queueChangedStream => _queueChangedController.stream;

  List<dynamic> get items => List.unmodifiable(_items);

  dynamic get currentItem =>
      (_currentIndex >= 0 && _currentIndex < _items.length)
          ? _items[_currentIndex]
          : null;

  int get currentIndex => _currentIndex;
  int get length => _items.length;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffled => _shuffled;

  bool get hasNext {
    if (_repeatMode == RepeatMode.repeatAll) return _items.isNotEmpty;
    return _currentIndex < _items.length - 1;
  }

  bool get hasPrevious {
    if (_repeatMode == RepeatMode.repeatAll) return _items.isNotEmpty;
    return _currentIndex > 0;
  }

  void setQueue(List<dynamic> items, {int startIndex = 0}) {
    _items
      ..clear()
      ..addAll(items);
    _originalOrder
      ..clear()
      ..addAll(items);
    _shuffled = false;
    _currentIndex = items.isEmpty ? -1 : startIndex.clamp(0, _items.length - 1);
    _queueChangedController.add(null);
  }

  void addItems(List<dynamic> items) {
    _items.addAll(items);
    _originalOrder.addAll(items);
    _queueChangedController.add(null);
  }

  bool next() {
    if (_items.isEmpty) return false;
    if (_repeatMode == RepeatMode.repeatOne) return true;
    if (_currentIndex < _items.length - 1) {
      _currentIndex++;
      _queueChangedController.add(null);
      return true;
    }
    if (_repeatMode == RepeatMode.repeatAll) {
      _currentIndex = 0;
      _queueChangedController.add(null);
      return true;
    }
    return false;
  }

  bool previous() {
    if (_items.isEmpty) return false;
    if (_currentIndex > 0) {
      _currentIndex--;
      _queueChangedController.add(null);
      return true;
    }
    if (_repeatMode == RepeatMode.repeatAll) {
      _currentIndex = _items.length - 1;
      _queueChangedController.add(null);
      return true;
    }
    return false;
  }

  void jumpTo(int index) {
    if (index >= 0 && index < _items.length) {
      _currentIndex = index;
      _queueChangedController.add(null);
    }
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final removedItem = _items.removeAt(index);
    _originalOrder.remove(removedItem);
    if (_items.isEmpty) {
      _currentIndex = -1;
    } else if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      _currentIndex = _currentIndex.clamp(0, _items.length - 1);
    }
    _queueChangedController.add(null);
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.repeatAll;
      case RepeatMode.repeatAll:
        _repeatMode = RepeatMode.repeatOne;
      case RepeatMode.repeatOne:
        _repeatMode = RepeatMode.none;
    }
    _queueChangedController.add(null);
  }

  void toggleShuffle() {
    if (_shuffled) {
      _unshuffle();
    } else {
      _shuffle();
    }
    _queueChangedController.add(null);
  }

  void _shuffle() {
    if (_items.length <= 1) return;
    final current = currentItem;
    final rest = List.from(_items)..remove(current);
    rest.shuffle(Random());
    _items
      ..clear()
      ..add(current)
      ..addAll(rest);
    _currentIndex = 0;
    _shuffled = true;
  }

  void _unshuffle() {
    final current = currentItem;
    _items
      ..clear()
      ..addAll(_originalOrder);
    final idx = _items.indexOf(current);
    _currentIndex = idx >= 0 ? idx : 0;
    _shuffled = false;
  }

  void clear() {
    _items.clear();
    _originalOrder.clear();
    _currentIndex = -1;
    _shuffled = false;
    _repeatMode = RepeatMode.none;
    _queueChangedController.add(null);
  }

  void dispose() {
    _queueChangedController.close();
  }
}
