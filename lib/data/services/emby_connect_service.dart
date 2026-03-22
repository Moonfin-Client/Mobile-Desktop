import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbyConnectService {
  static const _connectBaseUrl = 'https://connect.emby.media/service';

  final DeviceInfo _deviceInfo;
  final Dio _dio;

  EmbyConnectService({required DeviceInfo deviceInfo})
    : _deviceInfo = deviceInfo,
      _dio = Dio(
        BaseOptions(
          baseUrl: _connectBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ) {
    configureServerDio(_dio);
  }

  String get _applicationHeader =>
      '${_deviceInfo.appName}/${_deviceInfo.appVersion}';

  Future<EmbyConnectAuthResult> authenticate({
    required String username,
    required String password,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-Application': _applicationHeader,
    };

    final queryVariants = <Map<String, String>>[
      {'nameOrEmail': username, 'rawpw': password},
      {'nameOrEmail': username, 'pw': password},
      {'username': username, 'pw': password},
      {'name': username, 'pw': password},
    ];

    DioException? firstError;

    for (final query in queryVariants) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          '/user/authenticate',
          queryParameters: query,
          options: Options(headers: headers),
        );

        final data = response.data;
        if (data == null) {
          throw const FormatException('Invalid Emby Connect response');
        }
        return EmbyConnectAuthResult.fromJson(data);
      } on DioException catch (e) {
        firstError ??= e;
        // 401 can still indicate wrong credentials; keep trying known variants.
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          break;
        }
      }
    }

    // Keep compatibility for deployments that still accept POST auth payload.
    final fallbackBodies = <Map<String, String>>[
      {'nameOrEmail': username, 'rawpw': password},
      {'nameOrEmail': username, 'pw': password},
      {'username': username, 'pw': password},
      {'name': username, 'pw': password},
      {'Username': username, 'Pw': password},
    ];

    for (final body in fallbackBodies) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '/user/authenticate',
          options: Options(headers: headers),
          data: body,
        );
        final data = response.data;
        if (data == null) {
          continue;
        }
        return EmbyConnectAuthResult.fromJson(data);
      } on DioException catch (e) {
        firstError ??= e;
      }
    }

    if (firstError != null) throw firstError;
    throw const FormatException('Invalid Emby Connect response');
  }

  Future<List<EmbyConnectServer>> getServers({
    required String connectUserId,
    required String connectAccessToken,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/servers',
      queryParameters: {'userId': connectUserId},
      options: Options(
        headers: {
          'X-Application': _applicationHeader,
          'X-Connect-UserToken': connectAccessToken,
        },
      ),
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Invalid Emby Connect servers response');
    }

    return data
      .whereType<Map>()
      .map((entry) => EmbyConnectServer.fromJson(Map<String, dynamic>.from(entry)))
      .toList(growable: false);
  }

  Future<EmbyConnectExchangeResult> exchange({
    required String serverAddress,
    required String connectUserId,
    required String accessKey,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    configureServerDio(dio);

    DioException? lastDioError;
    Object? lastError;

    try {
      for (final exchangeUri in _exchangeUris(serverAddress)) {
        try {
          final response = await dio.getUri<Map<String, dynamic>>(
            exchangeUri.replace(
              queryParameters: {
                ...exchangeUri.queryParameters,
                'format': 'json',
                'ConnectUserId': connectUserId,
              },
            ),
            options: Options(
              headers: {
                'X-Emby-Token': accessKey,
                'X-Emby-Authorization': buildServerAuthorizationHeader(
                  scheme: 'Emby',
                  deviceInfo: _deviceInfo,
                ),
              },
            ),
          );

          final data = response.data;
          if (data == null) {
            throw const FormatException('Invalid exchange response');
          }

          return EmbyConnectExchangeResult.fromJson(data);
        } on DioException catch (e) {
          lastDioError = e;
          lastError = e;
          continue;
        } catch (e) {
          lastError = e;
          continue;
        }
      }

      if (lastDioError != null) throw lastDioError;
      throw lastError ?? const FormatException('Invalid exchange response');
    } finally {
      dio.close();
    }
  }

  Iterable<Uri> _exchangeUris(String serverAddress) sync* {
    final normalized = serverAddress.endsWith('/') ? serverAddress : '$serverAddress/';
    final base = Uri.parse(normalized);

    // Keep any existing base path from Emby Connect (for example, /emby).
    yield base.resolve('Connect/Exchange');

    // Some servers expose exchange under /emby even when base path is root.
    final root = base.replace(path: '/', query: '', fragment: '');
    yield root.resolve('emby/Connect/Exchange');
  }
}

class EmbyConnectAuthResult {
  final String accessToken;
  final EmbyConnectUser user;

  const EmbyConnectAuthResult({required this.accessToken, required this.user});

  factory EmbyConnectAuthResult.fromJson(Map<String, dynamic> json) {
    return EmbyConnectAuthResult(
      accessToken: json['AccessToken'] as String? ?? '',
      user: EmbyConnectUser.fromJson(
        (json['User'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }
}

class EmbyConnectUser {
  final String id;
  final String name;

  const EmbyConnectUser({required this.id, required this.name});

  factory EmbyConnectUser.fromJson(Map<String, dynamic> json) {
    return EmbyConnectUser(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
    );
  }
}

class EmbyConnectServer {
  final String accessKey;
  final String systemId;
  final String name;
  final String? url;
  final String? localAddress;

  const EmbyConnectServer({
    required this.accessKey,
    required this.systemId,
    required this.name,
    required this.url,
    required this.localAddress,
  });

  List<String> get candidateAddresses {
    final seen = <String>{};
    final addresses = <String>[];
    for (final candidate in [url, localAddress]) {
      final trimmed = candidate?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        continue;
      }
      for (final normalized in _normalizedCandidates(trimmed)) {
        if (seen.add(normalized.toLowerCase())) {
          addresses.add(normalized);
        }
      }
    }
    return addresses;
  }

  Iterable<String> _normalizedCandidates(String value) sync* {
    final sanitized = value.endsWith('/') ? value.substring(0, value.length - 1) : value;

    if (sanitized.startsWith('http://') || sanitized.startsWith('https://')) {
      yield sanitized;
      return;
    }

    // Emby Connect can return host:port without scheme; try both transports.
    yield 'https://$sanitized';
    yield 'http://$sanitized';
  }

  factory EmbyConnectServer.fromJson(Map<String, dynamic> json) {
    return EmbyConnectServer(
      accessKey: json['AccessKey'] as String? ?? '',
      systemId: json['SystemId'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      url: json['Url'] as String?,
      localAddress: json['LocalAddress'] as String?,
    );
  }
}

class EmbyConnectExchangeResult {
  final String localUserId;
  final String accessToken;

  const EmbyConnectExchangeResult({
    required this.localUserId,
    required this.accessToken,
  });

  factory EmbyConnectExchangeResult.fromJson(Map<String, dynamic> json) {
    return EmbyConnectExchangeResult(
      localUserId: json['LocalUserId'] as String? ?? '',
      accessToken: json['AccessToken'] as String? ?? '',
    );
  }
}
