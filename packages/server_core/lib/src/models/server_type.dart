enum ServerType {
  jellyfin,
  emby;

  static ServerType detect(String? productName, String? version) {
    if (productName != null) {
      final lower = productName.toLowerCase();
      if (lower.contains('jellyfin')) return ServerType.jellyfin;
      if (lower.contains('emby')) return ServerType.emby;
    }
    if (version != null) {
      final parts = version.split('.');
      final major = int.tryParse(parts.firstOrNull ?? '');
      if (major != null && parts.length >= 4 && major < 10) return ServerType.emby;
    }
    return ServerType.jellyfin;
  }
}
