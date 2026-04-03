import 'dart:convert';

import '../database/offline_database.dart';

class AggregatedItem {
  final String id;
  final String serverId;
  final Map<String, dynamic> rawData;

  const AggregatedItem({
    required this.id,
    required this.serverId,
    required this.rawData,
  });

  factory AggregatedItem.fromOffline(DownloadedItem row) {
    final rawData = jsonDecode(row.metadataJson) as Map<String, dynamic>;
    return AggregatedItem(id: row.itemId, serverId: row.serverId, rawData: rawData);
  }

  String get name => rawData['Name'] as String? ?? '';
  String? get type => rawData['Type'] as String?;
  bool get canDelete => rawData['CanDelete'] as bool? ?? false;
  String? get seriesName => rawData['SeriesName'] as String?;
  int? get productionYear => rawData['ProductionYear'] as int?;
  double? get communityRating => (rawData['CommunityRating'] as num?)?.toDouble();
  String? get overview => rawData['Overview'] as String?;
  String? get officialRating => rawData['OfficialRating'] as String?;
  int? get indexNumber => rawData['IndexNumber'] as int?;
  int? get parentIndexNumber => rawData['ParentIndexNumber'] as int?;

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int? get runTimeTicks => _toInt(rawData['RunTimeTicks']);
  Duration? get runtime => runTimeTicks != null
      ? Duration(microseconds: runTimeTicks! ~/ 10)
      : null;

  List<String> get genres =>
      (rawData['Genres'] as List?)?.cast<String>() ?? const [];

  String? get primaryImageTag =>
      (rawData['ImageTags'] as Map?)?['Primary'] as String?;

  String? get thumbImageTag =>
      (rawData['ImageTags'] as Map?)?['Thumb'] as String?;

  String? get primaryImageTagField =>
      rawData['PrimaryImageTag'] as String?;

  String? get primaryImageItemId =>
      rawData['PrimaryImageItemId'] as String?;

  List<String> get backdropImageTags =>
      (rawData['BackdropImageTags'] as List?)?.cast<String>() ?? const [];

  String? get parentBackdropItemId =>
      rawData['ParentBackdropItemId'] as String?;

  List<String> get parentBackdropImageTags =>
      (rawData['ParentBackdropImageTags'] as List?)?.cast<String>() ?? const [];

  String? get logoImageTag =>
      (rawData['ImageTags'] as Map?)?['Logo'] as String?;

  Map? get _userData => rawData['UserData'] as Map?;

  double? get playedPercentage =>
      (_userData?['PlayedPercentage'] as num?)?.toDouble();

  bool get isPlayed =>
      _userData?['Played'] as bool? ?? false;

  bool get isFavorite =>
      _userData?['IsFavorite'] as bool? ?? false;

  int? get playbackPositionTicks =>
      _toInt(_userData?['PlaybackPositionTicks']);

  Duration? get playbackPosition => playbackPositionTicks != null
      ? Duration(microseconds: playbackPositionTicks! ~/ 10)
      : null;

  int? get unplayedItemCount =>
      _userData?['UnplayedItemCount'] as int?;

  int? get criticRating => rawData['CriticRating'] as int?;

  String? get tagline {
    final taglines = rawData['Taglines'] as List?;
    return taglines != null && taglines.isNotEmpty ? taglines.first as String? : null;
  }

  String? get subtitle {
    if (type == 'Episode') {
      final s = parentIndexNumber;
      final e = indexNumber;
      final series = seriesName?.trim();
      final episodeInfo = switch ((s, e)) {
        (final season?, final episode?) => 'S$season:E$episode',
        _ => null,
      };

      if (episodeInfo != null && series != null && series.isNotEmpty) {
        return '$episodeInfo - $series';
      }
      if (episodeInfo != null) {
        return episodeInfo;
      }
      if (series != null && series.isNotEmpty) {
        return series;
      }
    }
    return productionYear?.toString();
  }

  String? get seriesId => rawData['SeriesId'] as String?;
  String? get seasonId => rawData['SeasonId'] as String?;
  String? get seriesPrimaryImageTag =>
      rawData['SeriesPrimaryImageTag'] as String?;
  String? get seriesThumbImageTag =>
      rawData['SeriesThumbImageTag'] as String?;
  String? get parentPrimaryImageTag =>
      rawData['ParentPrimaryImageTag'] as String?;
  String? get parentPrimaryImageItemId =>
      rawData['ParentPrimaryImageItemId'] as String?;
  String? get parentThumbItemId =>
      rawData['ParentThumbItemId'] as String?;
  String? get parentThumbImageTag =>
      rawData['ParentThumbImageTag'] as String?;
  String? get status => rawData['Status'] as String?;
  int? get childCount => rawData['ChildCount'] as int?;

  DateTime? get premiereDate {
    final v = rawData['PremiereDate'] as String?;
    return v != null ? DateTime.tryParse(v) : null;
  }

  DateTime? get endDate {
    final v = rawData['EndDate'] as String?;
    return v != null ? DateTime.tryParse(v) : null;
  }

  List<String> get productionLocations =>
      (rawData['ProductionLocations'] as List?)?.cast<String>() ?? const [];

  String? get albumArtist => rawData['AlbumArtist'] as String?;
  String? get album => rawData['Album'] as String?;
  String? get albumId => rawData['AlbumId'] as String?;
  String? get albumPrimaryImageTag =>
      rawData['AlbumPrimaryImageTag'] as String?;
  List<String> get artists =>
      (rawData['Artists'] as List?)?.cast<String>() ?? const [];
  String? get parentId => rawData['ParentId'] as String?;
  int? get recursiveItemCount => rawData['RecursiveItemCount'] as int?;
  List<Map<String, dynamic>> get albumArtists =>
      (rawData['AlbumArtists'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  Map<String, String> get providerIds {
    final ids = rawData['ProviderIds'] as Map?;
    return ids?.cast<String, String>() ?? const {};
  }

  String? get tmdbId => providerIds['Tmdb'];
  String? get imdbId => providerIds['Imdb'];

  List<Map<String, dynamic>> get people =>
      (rawData['People'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  List<Map<String, dynamic>> get studios =>
      (rawData['Studios'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  List<Map<String, dynamic>> get mediaSources =>
      (rawData['MediaSources'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  List<Map<String, dynamic>> get mediaStreams =>
      (rawData['MediaStreams'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  List<Map<String, dynamic>> get remoteTrailers =>
      (rawData['RemoteTrailers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  List<Map<String, dynamic>> get chapters =>
      (rawData['Chapters'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  String? get videoResolution {
    for (final stream in mediaStreams) {
      if (stream['Type'] == 'Video') {
        final width = stream['Width'] as int?;
        final height = stream['Height'] as int?;
        if (width == null || height == null) return null;
        final interlaced = stream['IsInterlaced'] == true;
        final suffix = interlaced ? 'i' : 'p';

        if (width >= 7600 || height >= 4300) return '8K';
        if (width >= 3800 || height >= 2000) return '4K';
        if (width >= 2500 || height >= 1400) return '1440$suffix';
        if (width >= 1800 || height >= 1000) return '1080$suffix';
        if (width >= 1200 || height >= 700) return '720$suffix';
        if (width >= 600 || height >= 400) return '480$suffix';
        return 'SD';
      }
    }
    return null;
  }

  int? get sourceVideoWidth {
    for (final stream in mediaStreams) {
      if (stream['Type'] == 'Video') return stream['Width'] as int?;
    }
    return null;
  }

  String? get videoCodec {
    for (final stream in mediaStreams) {
      if (stream['Type'] == 'Video') return stream['Codec'] as String?;
    }
    return null;
  }

  String? get hdrType {
    for (final stream in mediaStreams) {
      if (stream['Type'] == 'Video') {
        final rangeType = stream['VideoRangeType'] as String?;
        if (rangeType != null && rangeType != 'SDR') return rangeType;
        final range = stream['VideoRange'] as String?;
        if (range != null && range != 'SDR') return range;
      }
    }
    return null;
  }

  Map<String, dynamic>? get _defaultAudioStream {
    Map<String, dynamic>? first;
    for (final stream in mediaStreams) {
      if (stream['Type'] == 'Audio') {
        first ??= stream;
        if (stream['IsDefault'] == true) return stream;
      }
    }
    return first;
  }

  String? get audioCodec => _defaultAudioStream?['Codec'] as String?;

  String? get audioProfile => _defaultAudioStream?['Profile'] as String?;

  int? get audioChannels => _defaultAudioStream?['Channels'] as int?;

  String? get channelLayout {
    final channels = audioChannels;
    if (channels == null) return null;
    return switch (channels) {
      1 => 'Mono',
      2 => 'Stereo',
      6 => '5.1',
      8 => '7.1',
      _ => '${channels}ch',
    };
  }

  String? endsAt({bool use24Hour = false}) {
    final ticks = runTimeTicks;
    if (ticks == null) return null;
    final remaining = runtime!;
    final percentage = playedPercentage;
    final Duration left;
    if (percentage != null && percentage > 0) {
      left = Duration(microseconds: (remaining.inMicroseconds * (1.0 - percentage / 100.0)).round());
    } else {
      left = remaining;
    }
    final end = DateTime.now().add(left);
    final hour = end.hour;
    final minute = end.minute.toString().padLeft(2, '0');
    if (use24Hour) {
      return '${hour.toString().padLeft(2, '0')}:$minute';
    }
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h12:$minute $amPm';
  }

  String get displayTitle {
    if (type == 'Episode') {
      final series = seriesName ?? '';
      final s = parentIndexNumber;
      final e = indexNumber;
      if (series.isNotEmpty && s != null && e != null) {
        return '$series - S${s}E$e - $name';
      }
    }
    return name;
  }
}
