class AggregatedItem {
  final String id;
  final String serverId;
  final Map<String, dynamic> rawData;

  const AggregatedItem({
    required this.id,
    required this.serverId,
    required this.rawData,
  });

  String get name => rawData['Name'] as String? ?? '';
  String? get type => rawData['Type'] as String?;
  String? get seriesName => rawData['SeriesName'] as String?;
  int? get productionYear => rawData['ProductionYear'] as int?;
  double? get communityRating => rawData['CommunityRating'] as double?;
  String? get overview => rawData['Overview'] as String?;
  String? get officialRating => rawData['OfficialRating'] as String?;
  int? get indexNumber => rawData['IndexNumber'] as int?;
  int? get parentIndexNumber => rawData['ParentIndexNumber'] as int?;

  int? get runTimeTicks => rawData['RunTimeTicks'] as int?;
  Duration? get runtime => runTimeTicks != null
      ? Duration(microseconds: runTimeTicks! ~/ 10)
      : null;

  List<String> get genres =>
      (rawData['Genres'] as List?)?.cast<String>() ?? const [];

  String? get primaryImageTag =>
      (rawData['ImageTags'] as Map?)?['Primary'] as String?;

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
      _userData?['PlayedPercentage'] as double?;

  bool get isPlayed =>
      _userData?['Played'] as bool? ?? false;

  bool get isFavorite =>
      _userData?['IsFavorite'] as bool? ?? false;

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
      if (s != null && e != null) return 'S$s:E$e';
    }
    return productionYear?.toString();
  }

  String? get seriesId => rawData['SeriesId'] as String?;
  String? get seasonId => rawData['SeasonId'] as String?;
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

  String? get videoResolution {
    for (final stream in mediaStreams) {
      if (stream['Type'] == 'Video') {
        final width = stream['Width'] as int?;
        if (width == null) return null;
        if (width >= 3840) return '4K';
        if (width >= 1920) return '1080p';
        if (width >= 1280) return '720p';
        if (width >= 720) return '480p';
        return '${width}p';
      }
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

  String? get endsAt {
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
