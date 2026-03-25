import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import 'admin_user_providers.dart';

class AdminMediaMetricDefinition {
  final String key;
  final String label;
  final List<String> includeItemTypes;

  const AdminMediaMetricDefinition(
    this.key,
    this.label,
    this.includeItemTypes,
  );
}

const adminMediaMetrics = <AdminMediaMetricDefinition>[
  AdminMediaMetricDefinition('movies', 'Movies', ['Movie']),
  AdminMediaMetricDefinition('series', 'Series', ['Series']),
  AdminMediaMetricDefinition('episodes', 'Episodes', ['Episode']),
  AdminMediaMetricDefinition('albums', 'Albums', ['MusicAlbum']),
  AdminMediaMetricDefinition('songs', 'Songs', ['Audio']),
  AdminMediaMetricDefinition('books', 'Books', ['Book']),
  AdminMediaMetricDefinition('audiobooks', 'Audiobooks', ['AudioBook']),
  AdminMediaMetricDefinition('collections', 'Collections', ['BoxSet']),
  AdminMediaMetricDefinition('musicVideos', 'Music Videos', ['MusicVideo']),
  AdminMediaMetricDefinition('photos', 'Photos', ['Photo']),
  AdminMediaMetricDefinition('videos', 'Videos', ['Video']),
];

class AdminMediaCountSummary {
  final Map<String, int> totals;

  const AdminMediaCountSummary({
    required this.totals,
  });

  int countFor(String key) => totals[key] ?? 0;

  int get totalTrackedItems => totals.values.fold(0, (sum, count) => sum + count);
}

class AdminLibraryMediaAnalytics {
  final String name;
  final String itemId;
  final String? collectionType;
  final Map<String, int> counts;
  final AdminLibraryInsights insights;

  const AdminLibraryMediaAnalytics({
    required this.name,
    required this.itemId,
    required this.collectionType,
    required this.counts,
    this.insights = const AdminLibraryInsights(),
  });

  int countFor(String key) => counts[key] ?? 0;

  int get totalTrackedItems => counts.values.fold(0, (sum, count) => sum + count);
}

class AdminLibraryInsights {
  final Map<String, int> genres;
  final Map<String, int> contributors;
  final Map<String, int> years;
  final Map<String, int> ratings;
  final Map<String, int> runtimeBuckets;
  final Map<String, int> containers;
  final Map<String, int> videoCodecs;
  final Map<String, int> audioCodecs;

  const AdminLibraryInsights({
    this.genres = const {},
    this.contributors = const {},
    this.years = const {},
    this.ratings = const {},
    this.runtimeBuckets = const {},
    this.containers = const {},
    this.videoCodecs = const {},
    this.audioCodecs = const {},
  });

  bool get hasData =>
      genres.isNotEmpty ||
      contributors.isNotEmpty ||
      years.isNotEmpty ||
      ratings.isNotEmpty ||
      runtimeBuckets.isNotEmpty ||
      containers.isNotEmpty ||
      videoCodecs.isNotEmpty ||
      audioCodecs.isNotEmpty;
}

class AdminMediaAnalyticsDetail {
  final AdminMediaCountSummary summary;
  final List<AdminLibraryMediaAnalytics> libraries;
  final AdminTechnicalProfile technicalProfile;

  const AdminMediaAnalyticsDetail({
    required this.summary,
    required this.libraries,
    required this.technicalProfile,
  });
}

class AdminTechnicalProfile {
  final int sampledItems;
  final int totalRecordCount;
  final Duration sampledRuntime;
  final Map<String, int> containers;
  final Map<String, int> videoCodecs;
  final Map<String, int> audioCodecs;

  const AdminTechnicalProfile({
    this.sampledItems = 0,
    this.totalRecordCount = 0,
    this.sampledRuntime = Duration.zero,
    this.containers = const {},
    this.videoCodecs = const {},
    this.audioCodecs = const {},
  });

  bool get hasData => sampledItems > 0;
}

final adminMediaSummaryProvider = FutureProvider<AdminMediaCountSummary>((ref) async {
  final client = GetIt.instance<MediaServerClient>();
  return _loadSummary(client);
});

final adminMediaAnalyticsProvider = FutureProvider<AdminMediaAnalyticsDetail>((ref) async {
  final client = GetIt.instance<MediaServerClient>();
  final librariesFuture = ref.watch(adminLibrariesProvider.future);
  final summaryFuture = _loadSummary(client);
  final technicalFuture = _loadTechnicalProfile(client);

  final libraries = await librariesFuture;
  final summary = await summaryFuture;
  final technicalProfile = await technicalFuture;

  final libraryAnalytics = await Future.wait(
    libraries.map((library) => _loadLibraryAnalytics(client, library)),
  );

  libraryAnalytics.sort((a, b) {
    final totalCompare = b.totalTrackedItems.compareTo(a.totalTrackedItems);
    if (totalCompare != 0) {
      return totalCompare;
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return AdminMediaAnalyticsDetail(
    summary: summary,
    libraries: libraryAnalytics,
    technicalProfile: technicalProfile,
  );
});

Future<AdminMediaCountSummary> _loadSummary(MediaServerClient client) async {
  final entries = await Future.wait(
    adminMediaMetrics.map((metric) async {
      final count = await _safeFetchCount(
        client,
        includeItemTypes: metric.includeItemTypes,
      );
      return MapEntry(metric.key, count);
    }),
  );

  return AdminMediaCountSummary(
    totals: {
      for (final entry in entries) entry.key: entry.value,
    },
  );
}

Future<AdminLibraryMediaAnalytics> _loadLibraryAnalytics(
  MediaServerClient client,
  VirtualFolderInfo library,
) async {
  if (library.itemId.isEmpty) {
    return AdminLibraryMediaAnalytics(
      name: library.name,
      itemId: library.itemId,
      collectionType: library.collectionType,
      counts: {
        for (final metric in adminMediaMetrics) metric.key: 0,
      },
      insights: const AdminLibraryInsights(),
    );
  }

  final relevantMetrics = _metricsForCollectionType(library.collectionType);
  final countEntries = await Future.wait(
    relevantMetrics.map((metric) async {
      final count = await _safeFetchCount(
        client,
        parentId: library.itemId,
        includeItemTypes: metric.includeItemTypes,
      );
      return MapEntry(metric.key, count);
    }),
  );

  final insights = await _loadLibraryInsights(client, library);

  return AdminLibraryMediaAnalytics(
    name: library.name,
    itemId: library.itemId,
    collectionType: library.collectionType,
    counts: {
      for (final metric in adminMediaMetrics) metric.key: 0,
      for (final entry in countEntries) entry.key: entry.value,
    },
    insights: insights,
  );
}

Future<int> _safeFetchCount(
  MediaServerClient client, {
  String? parentId,
  required List<String> includeItemTypes,
}) async {
  try {
    return await _fetchCount(
      client,
      parentId: parentId,
      includeItemTypes: includeItemTypes,
    );
  } catch (_) {
    return 0;
  }
}

Future<int> _fetchCount(
  MediaServerClient client, {
  String? parentId,
  required List<String> includeItemTypes,
}) async {
  final response = await client.itemsApi.getItems(
    parentId: parentId,
    includeItemTypes: includeItemTypes,
    recursive: true,
    limit: 1,
    enableTotalRecordCount: true,
  );

  final totalRecordCount = response['TotalRecordCount'];
  if (totalRecordCount is num) {
    return totalRecordCount.toInt();
  }

  final items = response['Items'];
  if (items is List) {
    return items.length;
  }

  return 0;
}

List<AdminMediaMetricDefinition> _metricsForCollectionType(String? collectionType) {
  switch ((collectionType ?? '').toLowerCase()) {
    case 'movies':
      return _metricsForKeys(['movies']);
    case 'tvshows':
      return _metricsForKeys(['series', 'episodes']);
    case 'music':
      return _metricsForKeys(['albums', 'songs']);
    case 'musicvideos':
      return _metricsForKeys(['musicVideos']);
    case 'books':
      return _metricsForKeys(['books', 'audiobooks']);
    case 'photos':
      return _metricsForKeys(['photos']);
    case 'homevideos':
      return _metricsForKeys(['videos']);
    case 'boxsets':
      return const [];
    default:
      return adminMediaMetrics
          .where((metric) => metric.key != 'collections')
          .toList();
  }
}

List<AdminMediaMetricDefinition> _metricsForKeys(List<String> keys) {
  return adminMediaMetrics.where((metric) => keys.contains(metric.key)).toList();
}

Future<AdminLibraryInsights> _loadLibraryInsights(
  MediaServerClient client,
  VirtualFolderInfo library,
) async {
  final collectionType = (library.collectionType ?? '').toLowerCase();
  List<String> includeItemTypes;
  String fields;

  switch (collectionType) {
    case 'movies':
      includeItemTypes = const ['Movie'];
      fields =
          'Genres,ProductionYear,OfficialRating,RunTimeTicks,Container,MediaSources,MediaStreams';
    case 'tvshows':
      includeItemTypes = const ['Series', 'Episode'];
      fields =
          'Genres,ProductionYear,OfficialRating,RunTimeTicks,Container,MediaSources,MediaStreams';
    case 'music':
      includeItemTypes = const ['Audio', 'MusicAlbum'];
      fields =
          'Genres,Artists,AlbumArtists,ProductionYear,Container,MediaSources,MediaStreams';
    case 'books':
      includeItemTypes = const ['Book', 'AudioBook'];
      fields =
          'Genres,People,Authors,ProductionYear,Path,Container,MediaSources,MediaStreams';
    default:
      return const AdminLibraryInsights();
  }

  try {
    final response = await client.itemsApi.getItems(
      parentId: library.itemId,
      includeItemTypes: includeItemTypes,
      recursive: true,
      fields: fields,
      sortBy: 'DateCreated',
      sortOrder: 'Descending',
      limit: 500,
      enableTotalRecordCount: false,
    );

    final rawItems = response['Items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const <Map<String, dynamic>>[];

    final genres = <String, int>{};
    final contributors = <String, int>{};
    final years = <String, int>{};
    final ratings = <String, int>{};
    final runtimeBuckets = <String, int>{};
    final containers = <String, int>{};
    final videoCodecs = <String, int>{};
    final audioCodecs = <String, int>{};

    for (final item in items) {
      for (final genre in _extractStringList(item['Genres'])) {
        _incrementDisplayCount(genres, genre);
      }

      final productionYear = item['ProductionYear'];
      if (productionYear is num && productionYear > 0) {
        _incrementDisplayCount(years, productionYear.toInt().toString());
      }

      var hasContainer = false;
      final mediaSources = _mapList(item['MediaSources']);
      for (final source in mediaSources) {
        if (collectionType == 'books') {
          final sourcePathFormat = _bookFormatFromPath(source['Path']);
          if (sourcePathFormat != null) {
            _incrementCount(containers, sourcePathFormat);
            hasContainer = true;
          }
        }

        final sourceContainer = _normalizeToken(source['Container']);
        if (sourceContainer != null && !(collectionType == 'books' && hasContainer)) {
          _incrementCount(containers, sourceContainer);
          hasContainer = true;
        }

        var hasVideoStream = false;
        var hasAudioStream = false;
        final mediaStreams = _mapList(source['MediaStreams']);
        for (final stream in mediaStreams) {
          final streamType = _normalizeToken(stream['Type']);
          final streamCodec = _normalizeToken(stream['Codec']);
          if (streamCodec == null) {
            continue;
          }

          if (streamType == 'video') {
            _incrementCount(videoCodecs, streamCodec);
            hasVideoStream = true;
          } else if (streamType == 'audio') {
            _incrementCount(audioCodecs, streamCodec);
            hasAudioStream = true;
          }
        }

        if (!hasVideoStream) {
          final sourceVideoCodec = _normalizeToken(source['VideoCodec']);
          if (sourceVideoCodec != null) {
            _incrementCount(videoCodecs, sourceVideoCodec);
          }
        }

        if (!hasAudioStream) {
          final sourceAudioCodec = _normalizeToken(source['AudioCodec']);
          if (sourceAudioCodec != null) {
            _incrementCount(audioCodecs, sourceAudioCodec);
          }
        }
      }

      if (!hasContainer) {
        if (collectionType == 'books') {
          final itemPathFormat = _bookFormatFromPath(item['Path']);
          if (itemPathFormat != null) {
            _incrementCount(containers, itemPathFormat);
            hasContainer = true;
          }
        }

        final itemContainer = _normalizeToken(item['Container']);
        if (itemContainer != null && !(collectionType == 'books' && hasContainer)) {
          _incrementCount(containers, itemContainer);
        }
      }

      if (mediaSources.isEmpty) {
        final itemStreams = _mapList(item['MediaStreams']);
        for (final stream in itemStreams) {
          final streamType = _normalizeToken(stream['Type']);
          final streamCodec = _normalizeToken(stream['Codec']);
          if (streamCodec == null) {
            continue;
          }

          if (streamType == 'video') {
            _incrementCount(videoCodecs, streamCodec);
          } else if (streamType == 'audio') {
            _incrementCount(audioCodecs, streamCodec);
          }
        }
      }

      if (collectionType == 'movies' || collectionType == 'tvshows') {
        final officialRating = item['OfficialRating']?.toString().trim();
        if (officialRating != null && officialRating.isNotEmpty) {
          _incrementDisplayCount(ratings, officialRating.toUpperCase());
        }

        final runTimeTicks = item['RunTimeTicks'];
        if (runTimeTicks is num && runTimeTicks > 0) {
          final runtime = Duration(microseconds: runTimeTicks.toInt() ~/ 10);
          _incrementDisplayCount(runtimeBuckets, _runtimeBucket(runtime));
        }
      }

      if (collectionType == 'music') {
        for (final artist in _extractStringList(item['Artists'])) {
          _incrementDisplayCount(contributors, artist);
        }
        final albumArtists = _mapList(item['AlbumArtists']);
        for (final albumArtist in albumArtists) {
          final name = albumArtist['Name'];
          if (name != null) {
            _incrementDisplayCount(contributors, name.toString());
          }
        }
      } else {
        for (final author in _extractStringList(item['Authors'])) {
          _incrementDisplayCount(contributors, author);
        }
        final people = _mapList(item['People']);
        for (final person in people) {
          final role = (person['Type'] ?? '').toString().toLowerCase();
          if (role == 'writer' || role == 'author') {
            final name = person['Name'];
            if (name != null) {
              _incrementDisplayCount(contributors, name.toString());
            }
          }
        }
      }
    }

    return AdminLibraryInsights(
      genres: genres,
      contributors: contributors,
      years: years,
      ratings: ratings,
      runtimeBuckets: runtimeBuckets,
      containers: containers,
      videoCodecs: videoCodecs,
      audioCodecs: audioCodecs,
    );
  } catch (_) {
    return const AdminLibraryInsights();
  }
}

String _runtimeBucket(Duration runtime) {
  final minutes = runtime.inMinutes;
  if (minutes < 15) {
    return '<15m';
  }
  if (minutes < 30) {
    return '15-29m';
  }
  if (minutes < 45) {
    return '30-44m';
  }
  if (minutes < 60) {
    return '45-59m';
  }
  if (minutes < 90) {
    return '60-89m';
  }
  if (minutes < 120) {
    return '90-119m';
  }
  return '120m+';
}

Future<AdminTechnicalProfile> _loadTechnicalProfile(MediaServerClient client) async {
  try {
    final response = await client.itemsApi.getItems(
      includeItemTypes: const ['Movie', 'Episode', 'Video', 'MusicVideo', 'Audio'],
      recursive: true,
      fields: 'MediaSources,MediaStreams,RunTimeTicks,Container',
      sortBy: 'DateCreated',
      sortOrder: 'Descending',
      limit: 500,
      enableTotalRecordCount: true,
    );

    final rawItems = response['Items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const <Map<String, dynamic>>[];
    final total = response['TotalRecordCount'] is num
        ? (response['TotalRecordCount'] as num).toInt()
        : items.length;

    final containers = <String, int>{};
    final videoCodecs = <String, int>{};
    final audioCodecs = <String, int>{};
    var sampledRuntimeMicros = 0;

    for (final item in items) {
      final runTimeTicks = item['RunTimeTicks'];
      if (runTimeTicks is num && runTimeTicks > 0) {
        sampledRuntimeMicros += runTimeTicks.toInt() ~/ 10;
      }

      var containerAdded = false;
      final mediaSources = _mapList(item['MediaSources']);
      for (final source in mediaSources) {
        final sourceContainer = _normalizeToken(source['Container']);
        if (sourceContainer != null) {
          _incrementCount(containers, sourceContainer);
          containerAdded = true;
        }

        final mediaStreams = _mapList(source['MediaStreams']);
        var hasVideoStream = false;
        var hasAudioStream = false;
        for (final stream in mediaStreams) {
          final type = _normalizeToken(stream['Type']);
          final codec = _normalizeToken(stream['Codec']);
          if (codec == null) {
            continue;
          }

          if (type == 'video') {
            _incrementCount(videoCodecs, codec);
            hasVideoStream = true;
          } else if (type == 'audio') {
            _incrementCount(audioCodecs, codec);
            hasAudioStream = true;
          }
        }

        if (!hasVideoStream) {
          final sourceVideoCodec = _normalizeToken(source['VideoCodec']);
          if (sourceVideoCodec != null) {
            _incrementCount(videoCodecs, sourceVideoCodec);
          }
        }

        if (!hasAudioStream) {
          final sourceAudioCodec = _normalizeToken(source['AudioCodec']);
          if (sourceAudioCodec != null) {
            _incrementCount(audioCodecs, sourceAudioCodec);
          }
        }
      }

      if (!containerAdded) {
        final itemContainer = _normalizeToken(item['Container']);
        if (itemContainer != null) {
          _incrementCount(containers, itemContainer);
        }
      }
    }

    return AdminTechnicalProfile(
      sampledItems: items.length,
      totalRecordCount: total,
      sampledRuntime: Duration(microseconds: sampledRuntimeMicros),
      containers: containers,
      videoCodecs: videoCodecs,
      audioCodecs: audioCodecs,
    );
  } catch (_) {
    return const AdminTechnicalProfile();
  }
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

void _incrementCount(Map<String, int> map, String key) {
  map[key] = (map[key] ?? 0) + 1;
}

void _incrementDisplayCount(Map<String, int> map, String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return;
  }

  String? existingKey;
  for (final key in map.keys) {
    if (key.toLowerCase() == normalized.toLowerCase()) {
      existingKey = key;
      break;
    }
  }

  final targetKey = existingKey ?? normalized;
  map[targetKey] = (map[targetKey] ?? 0) + 1;
}

List<String> _extractStringList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((entry) => entry?.toString().trim() ?? '')
      .where((entry) => entry.isNotEmpty)
      .toList();
}

String? _normalizeToken(Object? value) {
  if (value == null) {
    return null;
  }

  final raw = value.toString().trim().toLowerCase();
  if (raw.isEmpty) {
    return null;
  }

  final parts = raw.split(RegExp(r'[,;|/ ]+')).where((part) => part.isNotEmpty);
  if (parts.isEmpty) {
    return null;
  }

  return parts.first;
}

String? _bookFormatFromPath(Object? pathValue) {
  final extension = _fileExtensionFromPath(pathValue);
  if (extension == null) {
    return null;
  }

  const knownFormats = <String>{
    'epub',
    'pdf',
    'cbr',
    'cbz',
    'cb7',
    'cbt',
    'cba',
    'mobi',
    'azw',
    'azw3',
    'fb2',
    'djvu',
    'm4b',
    'mp3',
    'aac',
    'flac',
    'opus',
    'ogg',
    'wav',
  };

  return knownFormats.contains(extension) ? extension : null;
}

String? _fileExtensionFromPath(Object? pathValue) {
  if (pathValue == null) {
    return null;
  }

  final path = pathValue.toString().trim().toLowerCase();
  if (path.isEmpty) {
    return null;
  }

  final slash = path.lastIndexOf(RegExp(r'[\\/]'));
  final filename = slash >= 0 ? path.substring(slash + 1) : path;
  final dot = filename.lastIndexOf('.');
  if (dot <= 0 || dot == filename.length - 1) {
    return null;
  }

  return filename.substring(dot + 1);
}