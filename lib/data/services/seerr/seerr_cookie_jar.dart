import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeerrCookieJar implements CookieJar {
  final SharedPreferences _prefs;
  String? _userId;

  @override
  final bool ignoreExpires = false;

  SeerrCookieJar(this._prefs);

  String get _storageKey =>
      _userId != null ? 'seerr_cookies_$_userId' : 'seerr_cookies';

  void switchToUser(String userId) {
    _userId = userId;
  }

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    final stored = _loadAll();
    final host = uri.host;

    for (final cookie in cookies) {
      final key = '${cookie.name}_$host';
      stored[key] = _serializeCookie(cookie, host);
    }

    _removeExpired(stored);
    await _saveAll(stored);
  }

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    final stored = _loadAll();
    _removeExpired(stored);

    final host = uri.host;
    final path = uri.path;
    final result = <Cookie>[];

    for (final entry in stored.values) {
      try {
        final data = jsonDecode(entry) as Map<String, dynamic>;
        final domain = data['domain'] as String? ?? '';
        final cookiePath = data['path'] as String? ?? '/';

        if (!_matchesDomain(domain, host)) continue;
        if (!path.startsWith(cookiePath)) continue;

        result.add(Cookie(data['name'] as String, data['value'] as String)
          ..domain = domain.isEmpty ? null : domain
          ..path = cookiePath
          ..secure = data['secure'] as bool? ?? false
          ..httpOnly = data['httpOnly'] as bool? ?? false);
      } catch (e) {
        debugPrint('[SeerrCookieJar] Bad cookie entry: $e');
      }
    }

    return result;
  }

  @override
  Future<void> deleteAll() async {
    await _prefs.remove(_storageKey);
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {
    final stored = _loadAll();
    final host = uri.host;
    stored.removeWhere((key, _) => key.endsWith('_$host'));
    await _saveAll(stored);
  }

  String? getCsrfToken(String host) {
    final stored = _loadAll();
    for (final entry in stored.values) {
      try {
        final data = jsonDecode(entry) as Map<String, dynamic>;
        if (data['name'] == 'XSRF-TOKEN' && _matchesDomain(data['domain'] as String? ?? '', host)) {
          return data['value'] as String;
        }
      } catch (_) {}
    }
    return null;
  }

  Map<String, String> _loadAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAll(Map<String, String> data) async {
    await _prefs.setString(_storageKey, jsonEncode(data));
  }

  void _removeExpired(Map<String, String> stored) {
    final now = DateTime.now();
    stored.removeWhere((key, value) {
      try {
        final data = jsonDecode(value) as Map<String, dynamic>;
        final expires = data['expires'] as int?;
        if (expires == null || expires == 0) return false;
        return DateTime.fromMillisecondsSinceEpoch(expires).isBefore(now);
      } catch (_) {
        return true;
      }
    });
  }

  bool _matchesDomain(String domain, String host) {
    if (domain.isEmpty) return true;
    final d = domain.toLowerCase();
    final h = host.toLowerCase();
    if (d.startsWith('.')) {
      return h == d.substring(1) || h.endsWith(d);
    }
    return h == d;
  }

  String _serializeCookie(Cookie cookie, String host) {
    return jsonEncode({
      'name': cookie.name,
      'value': cookie.value,
      'domain': cookie.domain ?? host,
      'path': cookie.path ?? '/',
      'expires': cookie.expires?.millisecondsSinceEpoch ?? 0,
      'secure': cookie.secure,
      'httpOnly': cookie.httpOnly,
    });
  }
}
