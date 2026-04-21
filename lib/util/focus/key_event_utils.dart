import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'back_key_coordinator.dart';
import 'dpad_keys.dart';

typedef FocusOnKeyEventCallback = KeyEventResult Function(FocusNode node, KeyEvent event);

class _SelectKeyUpSuppressor {
  static int _suppressCount = 0;

  static void markPressed() => _suppressCount++;

  static bool consumeIfSuppressed(KeyEvent event) {
    if (event is! KeyUpEvent) return false;
    if (!event.logicalKey.isSelectKey) return false;
    if (_suppressCount == 0) return false;
    _suppressCount--;
    return true;
  }
}

KeyEventResult handleOneShotSelect(KeyEvent event, VoidCallback onSelect) {
  if (event is KeyDownEvent && event.logicalKey.isSelectKey) {
    _SelectKeyUpSuppressor.markPressed();
    onSelect();
    return KeyEventResult.handled;
  }
  if (_SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}

KeyEventResult handleBackKeyAction(KeyEvent event, VoidCallback onBack) {
  if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;
  if (event is KeyDownEvent) {
    BackKeyCoordinator.markHandled();
    onBack();
    return KeyEventResult.handled;
  }
  if (event is KeyUpEvent) return KeyEventResult.handled;
  return KeyEventResult.ignored;
}

FocusOnKeyEventCallback dpadKeyHandler({
  VoidCallback? onUp,
  VoidCallback? onDown,
  VoidCallback? onLeft,
  VoidCallback? onRight,
  VoidCallback? onSelect,
}) {
  return (FocusNode node, KeyEvent event) {
    if (onSelect != null) {
      final r = handleOneShotSelect(event, onSelect);
      if (r != KeyEventResult.ignored) return r;
    }
    if (!event.isActionable) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k.isUpKey && onUp != null) {
      onUp();
      return KeyEventResult.handled;
    }
    if (k.isDownKey && onDown != null) {
      onDown();
      return KeyEventResult.handled;
    }
    if (k.isLeftKey && onLeft != null) {
      onLeft();
      return KeyEventResult.handled;
    }
    if (k.isRightKey && onRight != null) {
      onRight();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  };
}
