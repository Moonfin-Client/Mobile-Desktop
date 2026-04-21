import 'package:flutter/services.dart';

extension KeyEventActionable on KeyEvent {
  bool get isActionable => this is KeyDownEvent || this is KeyRepeatEvent;
}

final Set<LogicalKeyboardKey> _selectKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.numpadEnter,
  LogicalKeyboardKey.gameButtonA,
};

final Set<LogicalKeyboardKey> _backKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.goBack,
  LogicalKeyboardKey.browserBack,
  LogicalKeyboardKey.gameButtonB,
};

final Set<LogicalKeyboardKey> _contextMenuKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.contextMenu,
  LogicalKeyboardKey.gameButtonX,
};

extension DpadKeyExtension on LogicalKeyboardKey {
  bool get isUpKey => this == LogicalKeyboardKey.arrowUp;
  bool get isDownKey => this == LogicalKeyboardKey.arrowDown;
  bool get isLeftKey => this == LogicalKeyboardKey.arrowLeft;
  bool get isRightKey => this == LogicalKeyboardKey.arrowRight;
  bool get isSelectKey => _selectKeys.contains(this);
  bool get isBackKey => _backKeys.contains(this);
  bool get isContextMenuKey => _contextMenuKeys.contains(this);
  bool get isDirectional => isUpKey || isDownKey || isLeftKey || isRightKey;
}
