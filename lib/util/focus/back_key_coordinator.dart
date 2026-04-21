class BackKeyCoordinator {
  static bool _handled = false;

  static void markHandled() {
    _handled = true;
    Future.microtask(() => _handled = false);
  }

  static bool consumeIfHandled() {
    final v = _handled;
    _handled = false;
    return v;
  }
}
