import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';

class BookReaderService {
  static const Set<String> supportedExtensions = {
    'azw',
    'azw3',
    'cb7',
    'cbr',
    'cbt',
    'cbz',
    'epub',
    'mobi',
    'pdf',
    'zip',
  };

  static String? detectExtension(AggregatedItem item) {
    final directCandidates = <Object?>[
      item.rawData['Path'],
      item.rawData['FileName'],
      item.rawData['FilePath'],
      item.rawData['Name'],
      item.name,
    ];

    for (final candidate in directCandidates) {
      final value = _extractExtension(candidate);
      if (value != null) {
        return value;
      }
    }

    final directContainer = _fromContainer(item.rawData['Container']);
    if (directContainer != null) {
      return directContainer;
    }

    for (final source in item.mediaSources) {
      final sourceCandidates = <Object?>[
        source['Path'],
        source['Name'],
        source['FileName'],
        source['FilePath'],
      ];

      for (final candidate in sourceCandidates) {
        final fromValue = _extractExtension(candidate);
        if (fromValue != null) {
          return fromValue;
        }
      }

      final container = _fromContainer(source['Container']);
      if (container != null) {
        return container;
      }
    }

    return null;
  }

  static bool isSupportedExtension(String? extension) {
    return extension != null && supportedExtensions.contains(extension);
  }

  static List<Uri> buildDownloadUris(MediaServerClient client, AggregatedItem item) {
    final itemId = Uri.encodeComponent(item.id);
    final sourceId = _firstMediaSourceId(item);
    final token = client.accessToken;
    final query = <String, String>{
      if (sourceId != null) 'MediaSourceId': sourceId,
      if (token != null && token.isNotEmpty) 'api_key': token,
    };
    final videoQuery = <String, String>{
      ...query,
      'Static': 'true',
    };

    final candidates = <Uri>[
      Uri.parse('${client.baseUrl}/Items/$itemId/Download').replace(
        queryParameters: query.isEmpty ? null : query,
      ),
      Uri.parse('${client.baseUrl}/Items/$itemId/File').replace(
        queryParameters: query.isEmpty ? null : query,
      ),
      Uri.parse('${client.baseUrl}/Videos/$itemId/stream').replace(
        queryParameters: videoQuery,
      ),
    ];

    final unique = <String>{};
    return candidates.where((uri) => unique.add(uri.toString())).toList(growable: false);
  }

  static Map<String, String> buildAuthHeaders(MediaServerClient client) {
    final token = client.accessToken;
    if (token == null || token.isEmpty) {
      return const {};
    }

    return {
      'X-Emby-Token': token,
      'Authorization': 'MediaBrowser Token="$token"',
    };
  }

  static String? _firstMediaSourceId(AggregatedItem item) {
    for (final source in item.mediaSources) {
      final id = source['Id'];
      if (id is String && id.isNotEmpty) {
        return id;
      }
    }
    return null;
  }

  static String? _extractExtension(Object? value) {
    final raw = _normalize(value);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final clean = _stripUriSuffix(raw);
    if (clean.isEmpty) {
      return null;
    }

    final slash = clean.lastIndexOf('/');
    final start = slash >= 0 ? slash + 1 : 0;
    final filePart = clean.substring(start);
    final dot = filePart.lastIndexOf('.');
    if (dot < 0 || dot == filePart.length - 1) {
      return null;
    }

    return filePart.substring(dot + 1);
  }

  static String? _fromContainer(Object? value) {
    final container = _normalize(value);
    if (container == null || container.isEmpty) {
      return null;
    }

    final mapped = extensionFromMime(container) ?? container;

    if (supportedExtensions.contains(mapped)) {
      return mapped;
    }

    return _extractExtension(mapped);
  }

  static String? extensionFromMime(String? mime) {
    if (mime == null || mime.isEmpty) {
      return null;
    }

    return switch (mime.toLowerCase()) {
      'application/epub+zip' => 'epub',
      'application/pdf' => 'pdf',
      'application/x-cbr' => 'cbr',
      'application/x-cbz' => 'cbz',
      'application/x-cb7' => 'cb7',
      'application/x-cbt' => 'cbt',
      'application/vnd.comicbook+zip' => 'cbz',
      'application/vnd.comicbook-rar' => 'cbr',
      'application/x-rar-compressed' => 'cbr',
      'application/vnd.rar' => 'cbr',
      'application/x-7z-compressed' => 'cb7',
      'application/x-tar' => 'cbt',
      'application/x-compressed-tar' => 'cbt',
      'application/x-mobipocket-ebook' => 'mobi',
      _ => null,
    };
  }

  static String? extractExtensionFromContentDisposition(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final decodedMatch = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(value);
    if (decodedMatch != null) {
      final decoded = Uri.decodeComponent(decodedMatch.group(1)!);
      final ext = extractExtensionFromFileName(decoded);
      if (ext != null) {
        return ext;
      }
    }

    final plainMatch = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(value);
    if (plainMatch != null) {
      return extractExtensionFromFileName(plainMatch.group(1)!);
    }

    return null;
  }

  static String? extractExtensionFromFileName(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) {
      return null;
    }

    final clean = _stripUriSuffix(fileName.trim().toLowerCase());
    final dotIndex = clean.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == clean.length - 1) {
      return null;
    }

    return clean.substring(dotIndex + 1);
  }

  static String _stripUriSuffix(String value) {
    final query = value.indexOf('?');
    final fragment = value.indexOf('#');

    var cut = value.length;
    if (query >= 0 && query < cut) {
      cut = query;
    }
    if (fragment >= 0 && fragment < cut) {
      cut = fragment;
    }

    return value.substring(0, cut);
  }

  static String? _normalize(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed.toLowerCase();
  }
}
