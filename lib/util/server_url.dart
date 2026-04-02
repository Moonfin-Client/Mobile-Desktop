final _schemeRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');

String normalizeServerBaseUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';

  final hasScheme = _schemeRegex.hasMatch(trimmed);
  final parseTarget = hasScheme ? trimmed : 'https://$trimmed';

  Uri uri;
  try {
    uri = Uri.parse(parseTarget);
  } catch (_) {
    return _stripTrailingSlash(trimmed);
  }

  final normalizedPath = _normalizeServerPath(uri.pathSegments);
  final normalized = uri.replace(
    path: normalizedPath,
    query: null,
    fragment: null,
  );

  if (hasScheme) {
    return _stripTrailingSlash(normalized.toString());
  }

  if (normalized.host.isEmpty) {
    return _stripTrailingSlash(trimmed);
  }

  final authority = normalized.hasPort
      ? '${normalized.host}:${normalized.port}'
      : normalized.host;

  return _stripTrailingSlash(
    normalizedPath.isEmpty ? authority : '$authority$normalizedPath',
  );
}

String _normalizeServerPath(List<String> pathSegments) {
  final segments = pathSegments.where((segment) => segment.isNotEmpty).toList();
  if (segments.isEmpty) return '';

  final lower = segments.map((s) => s.toLowerCase()).toList();

  if (lower.length >= 2 &&
      lower[lower.length - 2] == 'web' &&
      lower.last == 'index.html') {
    segments.removeRange(segments.length - 2, segments.length);
  } else if (lower.last == 'web') {
    segments.removeLast();
  }

  if (segments.isEmpty) return '';
  return '/${segments.join('/')}';
}

String _stripTrailingSlash(String value) {
  if (value.endsWith('/')) {
    return value.substring(0, value.length - 1);
  }
  return value;
}
