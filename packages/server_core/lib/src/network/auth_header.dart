import '../models/device_info.dart';

String buildServerAuthorizationHeader({
  required String scheme,
  required DeviceInfo deviceInfo,
  String? accessToken,
}) {
  final client = _sanitizeHeaderValue(deviceInfo.appName);
  final device = _sanitizeHeaderValue(deviceInfo.name);
  final deviceId = _sanitizeHeaderValue(deviceInfo.id);
  final version = _sanitizeHeaderValue(deviceInfo.appVersion);

  final authHeader = StringBuffer(
    '$scheme Client="$client", '
    'Device="$device", '
    'DeviceId="$deviceId", '
    'Version="$version"',
  );

  if (accessToken != null && accessToken.isNotEmpty) {
    authHeader.write(', Token="${_sanitizeHeaderValue(accessToken)}"');
  }

  return authHeader.toString();
}

String _sanitizeHeaderValue(String value) {
  final asciiOnly = value.replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');
  final noQuotes = asciiOnly
      .replaceAll('"', '')
      .replaceAll('\\', '')
      .replaceAll(',', ' ')
      .replaceAll(RegExp(r'[\r\n\t]'), ' ');

  final collapsed = noQuotes.replaceAll(RegExp(r'\s+'), ' ').trim();
  return collapsed.isEmpty ? 'Unknown' : collapsed;
}