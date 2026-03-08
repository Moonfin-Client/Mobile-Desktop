import 'enums.dart';

class ServerUser {
  final String id;
  final String? name;
  final String? serverId;
  final String? primaryImageTag;
  final bool hasPassword;

  const ServerUser({
    required this.id,
    this.name,
    this.serverId,
    this.primaryImageTag,
    this.hasPassword = false,
  });

  factory ServerUser.fromJson(Map<String, dynamic> json) => ServerUser(
        id: json['Id'] as String? ?? '',
        name: json['Name'] as String?,
        serverId: json['ServerId'] as String?,
        primaryImageTag: json['PrimaryImageTag'] as String?,
        hasPassword: json['HasPassword'] as bool? ?? false,
      );
}

class ServerPerson {
  final String id;
  final String? name;
  final PersonType type;
  final String? role;
  final String? primaryImageTag;

  const ServerPerson({
    required this.id,
    this.name,
    this.type = PersonType.unknown,
    this.role,
    this.primaryImageTag,
  });

  factory ServerPerson.fromJson(Map<String, dynamic> json) => ServerPerson(
        id: json['Id'] as String? ?? '',
        name: json['Name'] as String?,
        type: PersonType.fromServerString(json['Type'] as String?),
        role: json['Role'] as String?,
        primaryImageTag: json['PrimaryImageTag'] as String?,
      );
}

class ServerMediaStream {
  final int index;
  final StreamType type;
  final String? codec;
  final String? language;
  final String? displayTitle;
  final String? title;
  final bool isDefault;
  final bool isForced;
  final bool isExternal;
  final int? width;
  final int? height;
  final int? channels;
  final int? bitRate;
  final String? profile;
  final String? pixelFormat;
  final String? colorSpace;

  const ServerMediaStream({
    required this.index,
    this.type = StreamType.unknown,
    this.codec,
    this.language,
    this.displayTitle,
    this.title,
    this.isDefault = false,
    this.isForced = false,
    this.isExternal = false,
    this.width,
    this.height,
    this.channels,
    this.bitRate,
    this.profile,
    this.pixelFormat,
    this.colorSpace,
  });

  factory ServerMediaStream.fromJson(Map<String, dynamic> json) =>
      ServerMediaStream(
        index: json['Index'] as int? ?? 0,
        type: StreamType.fromServerString(json['Type'] as String?),
        codec: json['Codec'] as String?,
        language: json['Language'] as String?,
        displayTitle: json['DisplayTitle'] as String?,
        title: json['Title'] as String?,
        isDefault: json['IsDefault'] as bool? ?? false,
        isForced: json['IsForced'] as bool? ?? false,
        isExternal: json['IsExternal'] as bool? ?? false,
        width: json['Width'] as int?,
        height: json['Height'] as int?,
        channels: json['Channels'] as int?,
        bitRate: json['BitRate'] as int?,
        profile: json['Profile'] as String?,
        pixelFormat: json['PixelFormat'] as String?,
        colorSpace: json['ColorSpace'] as String?,
      );
}

class ServerMediaSource {
  final String id;
  final String? name;
  final String? path;
  final String? container;
  final int? bitrate;
  final int? size;
  final bool supportsDirectPlay;
  final bool supportsDirectStream;
  final bool supportsTranscoding;
  final String? transcodingUrl;
  final String? directStreamUrl;
  final List<ServerMediaStream> mediaStreams;

  const ServerMediaSource({
    required this.id,
    this.name,
    this.path,
    this.container,
    this.bitrate,
    this.size,
    this.supportsDirectPlay = false,
    this.supportsDirectStream = false,
    this.supportsTranscoding = false,
    this.transcodingUrl,
    this.directStreamUrl,
    this.mediaStreams = const [],
  });

  factory ServerMediaSource.fromJson(Map<String, dynamic> json) =>
      ServerMediaSource(
        id: json['Id'] as String? ?? '',
        name: json['Name'] as String?,
        path: json['Path'] as String?,
        container: json['Container'] as String?,
        bitrate: json['Bitrate'] as int?,
        size: json['Size'] as int?,
        supportsDirectPlay: json['SupportsDirectPlay'] as bool? ?? false,
        supportsDirectStream: json['SupportsDirectStream'] as bool? ?? false,
        supportsTranscoding: json['SupportsTranscoding'] as bool? ?? false,
        transcodingUrl: json['TranscodingUrl'] as String?,
        directStreamUrl: json['DirectStreamUrl'] as String?,
        mediaStreams: (json['MediaStreams'] as List<dynamic>?)
                ?.map((e) =>
                    ServerMediaStream.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class UserItemData {
  final double? playedPercentage;
  final int? playbackPositionTicks;
  final int playCount;
  final bool isFavorite;
  final bool played;
  final DateTime? lastPlayedDate;

  const UserItemData({
    this.playedPercentage,
    this.playbackPositionTicks,
    this.playCount = 0,
    this.isFavorite = false,
    this.played = false,
    this.lastPlayedDate,
  });

  factory UserItemData.fromJson(Map<String, dynamic> json) => UserItemData(
        playedPercentage: (json['PlayedPercentage'] as num?)?.toDouble(),
        playbackPositionTicks: json['PlaybackPositionTicks'] as int?,
        playCount: json['PlayCount'] as int? ?? 0,
        isFavorite: json['IsFavorite'] as bool? ?? false,
        played: json['Played'] as bool? ?? false,
        lastPlayedDate: json['LastPlayedDate'] != null
            ? DateTime.tryParse(json['LastPlayedDate'] as String)
            : null,
      );
}

class ServerItem {
  final String id;
  final String? serverId;
  final String? name;
  final String? sortName;
  final String? originalTitle;
  final ItemType type;
  final MediaType? mediaType;
  final String? overview;
  final int? productionYear;
  final String? officialRating;
  final double? communityRating;
  final double? criticRating;
  final int? runTimeTicks;
  final String? seriesId;
  final String? seriesName;
  final String? seasonId;
  final String? seasonName;
  final int? indexNumber;
  final int? parentIndexNumber;
  final String? parentId;
  final String? albumId;
  final String? albumArtist;
  final List<String> artists;
  final List<String> genres;
  final List<String> tags;
  final List<ServerPerson> people;
  final List<ServerMediaSource> mediaSources;
  final Map<String, String> imageTagsMap;
  final List<String> backdropImageTags;
  final String? parentBackdropItemId;
  final List<String> parentBackdropImageTags;
  final UserItemData? userData;
  final int? childCount;
  final int? recursiveItemCount;
  final String? collectionType;
  final DateTime? premiereDate;
  final DateTime? dateCreated;
  final bool isFolder;
  final String? status;
  final String? path;
  final List<Map<String, dynamic>> remoteTrailers;
  final Map<String, String> providerIds;

  const ServerItem({
    required this.id,
    this.serverId,
    this.name,
    this.sortName,
    this.originalTitle,
    this.type = ItemType.unknown,
    this.mediaType,
    this.overview,
    this.productionYear,
    this.officialRating,
    this.communityRating,
    this.criticRating,
    this.runTimeTicks,
    this.seriesId,
    this.seriesName,
    this.seasonId,
    this.seasonName,
    this.indexNumber,
    this.parentIndexNumber,
    this.parentId,
    this.albumId,
    this.albumArtist,
    this.artists = const [],
    this.genres = const [],
    this.tags = const [],
    this.people = const [],
    this.mediaSources = const [],
    this.imageTagsMap = const {},
    this.backdropImageTags = const [],
    this.parentBackdropItemId,
    this.parentBackdropImageTags = const [],
    this.userData,
    this.childCount,
    this.recursiveItemCount,
    this.collectionType,
    this.premiereDate,
    this.dateCreated,
    this.isFolder = false,
    this.status,
    this.path,
    this.remoteTrailers = const [],
    this.providerIds = const {},
  });

  String? get primaryImageTag => imageTagsMap['Primary'];

  factory ServerItem.fromJson(Map<String, dynamic> json) => ServerItem(
        id: json['Id'] as String? ?? '',
        serverId: json['ServerId'] as String?,
        name: json['Name'] as String?,
        sortName: json['SortName'] as String?,
        originalTitle: json['OriginalTitle'] as String?,
        type: ItemType.fromServerString(json['Type'] as String?),
        mediaType:
            MediaType.fromServerString(json['MediaType'] as String?),
        overview: json['Overview'] as String?,
        productionYear: json['ProductionYear'] as int?,
        officialRating: json['OfficialRating'] as String?,
        communityRating: (json['CommunityRating'] as num?)?.toDouble(),
        criticRating: (json['CriticRating'] as num?)?.toDouble(),
        runTimeTicks: json['RunTimeTicks'] as int?,
        seriesId: json['SeriesId'] as String?,
        seriesName: json['SeriesName'] as String?,
        seasonId: json['SeasonId'] as String?,
        seasonName: json['SeasonName'] as String?,
        indexNumber: json['IndexNumber'] as int?,
        parentIndexNumber: json['ParentIndexNumber'] as int?,
        parentId: json['ParentId'] as String?,
        albumId: json['AlbumId'] as String?,
        albumArtist: json['AlbumArtist'] as String?,
        artists: (json['Artists'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        genres: (json['Genres'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        tags: (json['Tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        people: (json['People'] as List<dynamic>?)
                ?.map((e) => ServerPerson.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        mediaSources: (json['MediaSources'] as List<dynamic>?)
                ?.map(
                    (e) => ServerMediaSource.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        imageTagsMap: (json['ImageTags'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            const {},
        backdropImageTags: (json['BackdropImageTags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        parentBackdropItemId: json['ParentBackdropItemId'] as String?,
        parentBackdropImageTags:
            (json['ParentBackdropImageTags'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                const [],
        userData: json['UserData'] != null
            ? UserItemData.fromJson(json['UserData'] as Map<String, dynamic>)
            : null,
        childCount: json['ChildCount'] as int?,
        recursiveItemCount: json['RecursiveItemCount'] as int?,
        collectionType: json['CollectionType'] as String?,
        premiereDate: json['PremiereDate'] != null
            ? DateTime.tryParse(json['PremiereDate'] as String)
            : null,
        dateCreated: json['DateCreated'] != null
            ? DateTime.tryParse(json['DateCreated'] as String)
            : null,
        isFolder: json['IsFolder'] as bool? ?? false,
        status: json['Status'] as String?,
        path: json['Path'] as String?,
        remoteTrailers: (json['RemoteTrailers'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            const [],
        providerIds: (json['ProviderIds'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            const {},
      );
}
