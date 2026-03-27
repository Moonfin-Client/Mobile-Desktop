import 'package:json_annotation/json_annotation.dart';

part 'seerr_api_models.g.dart';

@JsonSerializable()
class SeerrRequest {
  static const statusPending = 1;
  static const statusApproved = 2;
  static const statusDeclined = 3;
  static const statusAvailable = 4;

  final int id;
  final int status;
  final String? createdAt;
  final String? updatedAt;
  final String type;
  final SeerrMedia? media;
  final SeerrUser? requestedBy;
  final int? seasonCount;
  final String? externalId;
  final bool is4k;
  final List<SeerrSeasonRequest>? seasons;

  const SeerrRequest({
    required this.id,
    required this.status,
    this.createdAt,
    this.updatedAt,
    required this.type,
    this.media,
    this.requestedBy,
    this.seasonCount,
    this.externalId,
    this.is4k = false,
    this.seasons,
  });

  factory SeerrRequest.fromJson(Map<String, dynamic> json) =>
      _$SeerrRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrRequestToJson(this);
}

@JsonSerializable()
class SeerrSeasonRequest {
  final int id;
  final int seasonNumber;
  final int status;
  final String? createdAt;
  final String? updatedAt;

  const SeerrSeasonRequest({
    required this.id,
    required this.seasonNumber,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory SeerrSeasonRequest.fromJson(Map<String, dynamic> json) =>
      _$SeerrSeasonRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrSeasonRequestToJson(this);
}

@JsonSerializable()
class SeerrMedia {
  final int id;
  final String? mediaType;
  final int? tmdbId;
  final int? tvdbId;
  final String? imdbId;
  final int? status;
  final int? status4k;
  final String? mediaAddedAt;
  final int? serviceId;
  final int? serviceId4k;
  final int? externalServiceId;
  final int? externalServiceId4k;
  final String? externalServiceSlug;
  final String? externalServiceSlug4k;
  final String? ratingKey;
  final String? ratingKey4k;
  final String? title;
  final String? name;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final String? releaseDate;
  final String? firstAirDate;
  final String? originalLanguage;
  final List<int>? genreIds;
  final double? voteAverage;
  final SeerrExternalIds? externalIds;
  @JsonKey(name: 'requests')
  final List<SeerrRequest>? requestList;

  const SeerrMedia({
    required this.id,
    this.mediaType,
    this.tmdbId,
    this.tvdbId,
    this.imdbId,
    this.status,
    this.status4k,
    this.mediaAddedAt,
    this.serviceId,
    this.serviceId4k,
    this.externalServiceId,
    this.externalServiceId4k,
    this.externalServiceSlug,
    this.externalServiceSlug4k,
    this.ratingKey,
    this.ratingKey4k,
    this.title,
    this.name,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.releaseDate,
    this.firstAirDate,
    this.originalLanguage,
    this.genreIds,
    this.voteAverage,
    this.externalIds,
    this.requestList,
  });

  factory SeerrMedia.fromJson(Map<String, dynamic> json) =>
      _$SeerrMediaFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrMediaToJson(this);
}

@JsonSerializable()
class SeerrExternalIds {
  final int? tvdbId;
  final int? tmdbId;
  final String? imdbId;

  const SeerrExternalIds({this.tvdbId, this.tmdbId, this.imdbId});

  factory SeerrExternalIds.fromJson(Map<String, dynamic> json) =>
      _$SeerrExternalIdsFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrExternalIdsToJson(this);
}

@JsonSerializable()
class SeerrUser {
  final int id;
  final String? displayName;
  final String? username;
  final String? email;
  final String? avatar;
  final String? apiKey;
  final int? permissions;

  const SeerrUser({
    required this.id,
    this.displayName,
    this.username,
    this.email,
    this.avatar,
    this.apiKey,
    this.permissions,
  });

  String get bestName => displayName ?? username ?? email ?? 'Unknown';

  bool get isOwner => id == 1;

  bool hasPermission(int permission) {
    final perms = permissions ?? 0;
    if (isOwner) return true;
    if (perms & SeerrPermission.admin != 0) return true;
    return perms & permission != 0;
  }

  bool get isAdmin => hasPermission(SeerrPermission.admin);

  bool get canRequest4k =>
      hasPermission(SeerrPermission.request4k) ||
      hasPermission(SeerrPermission.request4kMovie) ||
      hasPermission(SeerrPermission.request4kTv);

  bool get canRequest4kMovies =>
      hasPermission(SeerrPermission.request4k) ||
      hasPermission(SeerrPermission.request4kMovie);

  bool get canRequest4kTv =>
      hasPermission(SeerrPermission.request4k) ||
      hasPermission(SeerrPermission.request4kTv);

  bool get hasAdvancedRequestPermission =>
      hasPermission(SeerrPermission.requestAdvanced) ||
      hasPermission(SeerrPermission.manageRequests);

  bool get canViewAllRequests =>
      hasPermission(SeerrPermission.manageRequests) ||
      hasPermission(SeerrPermission.requestView);

  factory SeerrUser.fromJson(Map<String, dynamic> json) =>
      _$SeerrUserFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrUserToJson(this);
}

abstract final class SeerrPermission {
  static const none = 0;
  static const admin = 2;
  static const manageSettings = 4;
  static const manageUsers = 8;
  static const manageRequests = 16;
  static const request = 32;
  static const autoApprove = 128;
  static const request4k = 1024;
  static const request4kMovie = 2048;
  static const request4kTv = 4096;
  static const requestAdvanced = 8192;
  static const requestView = 16384;
  static const requestMovie = 262144;
  static const requestTv = 524288;
}

@JsonSerializable()
class SeerrDiscoverPage {
  final List<SeerrDiscoverItem> results;
  final int totalPages;
  final int totalResults;
  final int page;

  const SeerrDiscoverPage({
    this.results = const [],
    this.totalPages = 0,
    this.totalResults = 0,
    this.page = 1,
  });

  factory SeerrDiscoverPage.fromJson(Map<String, dynamic> json) =>
      _$SeerrDiscoverPageFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrDiscoverPageToJson(this);
}

@JsonSerializable()
class SeerrDiscoverItem {
  final int id;
  final String? mediaType;
  final String? title;
  final String? name;
  final String? originalTitle;
  final String? originalName;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final String? releaseDate;
  final String? firstAirDate;
  final String? originalLanguage;
  final List<int> genreIds;
  final double? voteAverage;
  final int? voteCount;
  final double? popularity;
  final bool adult;
  final SeerrMediaInfo? mediaInfo;
  final String? character;
  final String? job;
  final String? department;

  const SeerrDiscoverItem({
    required this.id,
    this.mediaType,
    this.title,
    this.name,
    this.originalTitle,
    this.originalName,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.releaseDate,
    this.firstAirDate,
    this.originalLanguage,
    this.genreIds = const [],
    this.voteAverage,
    this.voteCount,
    this.popularity,
    this.adult = false,
    this.mediaInfo,
    this.character,
    this.job,
    this.department,
  });

  String get displayTitle => title ?? name ?? '';

  bool get isAvailable =>
      mediaInfo?.status == 5 || mediaInfo?.status == 4;

  bool get isBlacklisted => mediaInfo?.status == 6;

  factory SeerrDiscoverItem.fromJson(Map<String, dynamic> json) =>
      _$SeerrDiscoverItemFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrDiscoverItemToJson(this);
}

@JsonSerializable()
class SeerrMovieDetails {
  final int id;
  final String? mediaType;
  final String title;
  final String? tagline;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final String? releaseDate;
  final String? status;
  final int? runtime;
  final int? budget;
  final int? revenue;
  final double? voteAverage;
  final int? voteCount;
  final List<SeerrGenre> genres;
  final SeerrCredits? credits;
  final SeerrExternalIds? externalIds;
  final SeerrMediaInfo? mediaInfo;
  final List<SeerrKeyword> keywords;

  const SeerrMovieDetails({
    required this.id,
    this.mediaType = 'movie',
    required this.title,
    this.tagline,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.releaseDate,
    this.status,
    this.runtime,
    this.budget,
    this.revenue,
    this.voteAverage,
    this.voteCount,
    this.genres = const [],
    this.credits,
    this.externalIds,
    this.mediaInfo,
    this.keywords = const [],
  });

  factory SeerrMovieDetails.fromJson(Map<String, dynamic> json) =>
      _$SeerrMovieDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrMovieDetailsToJson(this);
}

@JsonSerializable()
class SeerrTvDetails {
  final int id;
  final String? mediaType;
  final String? name;
  final String? title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final String? tagline;
  final String? firstAirDate;
  final String? lastAirDate;
  final String? status;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final double? voteAverage;
  final int? voteCount;
  final List<SeerrGenre> genres;
  final SeerrCredits? credits;
  final List<SeerrNetwork> networks;
  final SeerrExternalIds? externalIds;
  final SeerrMediaInfo? mediaInfo;
  final List<SeerrKeyword> keywords;

  const SeerrTvDetails({
    required this.id,
    this.mediaType = 'tv',
    this.name,
    this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.tagline,
    this.firstAirDate,
    this.lastAirDate,
    this.status,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.voteAverage,
    this.voteCount,
    this.genres = const [],
    this.credits,
    this.networks = const [],
    this.externalIds,
    this.mediaInfo,
    this.keywords = const [],
  });

  String get displayTitle => name ?? title ?? '';

  factory SeerrTvDetails.fromJson(Map<String, dynamic> json) =>
      _$SeerrTvDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrTvDetailsToJson(this);
}

@JsonSerializable()
class SeerrGenre {
  final int id;
  final String name;
  final List<String> backdrops;

  const SeerrGenre({
    required this.id,
    required this.name,
    this.backdrops = const [],
  });

  factory SeerrGenre.fromJson(Map<String, dynamic> json) =>
      _$SeerrGenreFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrGenreToJson(this);
}

@JsonSerializable()
class SeerrNetwork {
  final int id;
  final String name;
  final String? logoPath;
  final String? originCountry;

  const SeerrNetwork({
    required this.id,
    required this.name,
    this.logoPath,
    this.originCountry,
  });

  factory SeerrNetwork.fromJson(Map<String, dynamic> json) =>
      _$SeerrNetworkFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrNetworkToJson(this);
}

@JsonSerializable()
class SeerrStudio {
  final int id;
  final String name;
  final String? logoPath;

  const SeerrStudio({required this.id, required this.name, this.logoPath});

  factory SeerrStudio.fromJson(Map<String, dynamic> json) =>
      _$SeerrStudioFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrStudioToJson(this);
}

@JsonSerializable()
class SeerrKeyword {
  final int id;
  final String name;

  const SeerrKeyword({required this.id, required this.name});

  factory SeerrKeyword.fromJson(Map<String, dynamic> json) =>
      _$SeerrKeywordFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrKeywordToJson(this);
}

@JsonSerializable()
class SeerrCredits {
  final List<SeerrCastMember> cast;
  final List<SeerrCrewMember> crew;

  const SeerrCredits({this.cast = const [], this.crew = const []});

  factory SeerrCredits.fromJson(Map<String, dynamic> json) =>
      _$SeerrCreditsFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrCreditsToJson(this);
}

@JsonSerializable()
class SeerrCastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;
  final int? order;

  const SeerrCastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
    this.order,
  });

  factory SeerrCastMember.fromJson(Map<String, dynamic> json) =>
      _$SeerrCastMemberFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrCastMemberToJson(this);
}

@JsonSerializable()
class SeerrCrewMember {
  final int id;
  final String name;
  final String? department;
  final String? job;
  final String? profilePath;

  const SeerrCrewMember({
    required this.id,
    required this.name,
    this.department,
    this.job,
    this.profilePath,
  });

  factory SeerrCrewMember.fromJson(Map<String, dynamic> json) =>
      _$SeerrCrewMemberFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrCrewMemberToJson(this);
}

@JsonSerializable()
class SeerrMediaInfo {
  final int? id;
  final int? tmdbId;
  final int? tvdbId;
  final int? status;
  final int? status4k;
  final List<SeerrRequest>? requests;

  const SeerrMediaInfo({
    this.id,
    this.tmdbId,
    this.tvdbId,
    this.status,
    this.status4k,
    this.requests,
  });

  factory SeerrMediaInfo.fromJson(Map<String, dynamic> json) =>
      _$SeerrMediaInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrMediaInfoToJson(this);
}

@JsonSerializable()
class SeerrPersonDetails {
  final int id;
  final String name;
  final String? biography;
  final String? birthday;
  final String? deathday;
  final String? placeOfBirth;
  final String? profilePath;
  final String? knownForDepartment;
  final double? popularity;

  const SeerrPersonDetails({
    required this.id,
    required this.name,
    this.biography,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    this.profilePath,
    this.knownForDepartment,
    this.popularity,
  });

  factory SeerrPersonDetails.fromJson(Map<String, dynamic> json) =>
      _$SeerrPersonDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrPersonDetailsToJson(this);
}

@JsonSerializable()
class SeerrPersonCombinedCredits {
  final List<SeerrDiscoverItem> cast;
  final List<SeerrDiscoverItem> crew;

  const SeerrPersonCombinedCredits({
    this.cast = const [],
    this.crew = const [],
  });

  factory SeerrPersonCombinedCredits.fromJson(Map<String, dynamic> json) =>
      _$SeerrPersonCombinedCreditsFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrPersonCombinedCreditsToJson(this);
}

@JsonSerializable()
class SeerrPageInfo {
  final int pages;
  final int pageSize;
  final int results;
  final int page;

  const SeerrPageInfo({
    required this.pages,
    required this.pageSize,
    required this.results,
    required this.page,
  });

  factory SeerrPageInfo.fromJson(Map<String, dynamic> json) =>
      _$SeerrPageInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrPageInfoToJson(this);
}

@JsonSerializable()
class SeerrRequestListResponse {
  final SeerrPageInfo? pageInfo;
  final List<SeerrRequest> results;

  const SeerrRequestListResponse({this.pageInfo, this.results = const []});

  factory SeerrRequestListResponse.fromJson(Map<String, dynamic> json) =>
      _$SeerrRequestListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrRequestListResponseToJson(this);
}

@JsonSerializable()
class SeerrCreateRequest {
  final int mediaId;
  final String mediaType;
  @JsonKey(toJson: _seasonsToJson, fromJson: _seasonsFromJson)
  final Object? seasons;
  final int? tvdbId;
  final String? imdbId;
  final bool is4k;
  final int? profileId;
  final int? rootFolderId;
  final int? serverId;

  const SeerrCreateRequest({
    required this.mediaId,
    required this.mediaType,
    this.seasons,
    this.tvdbId,
    this.imdbId,
    this.is4k = false,
    this.profileId,
    this.rootFolderId,
    this.serverId,
  });

  factory SeerrCreateRequest.allSeasons({
    required int mediaId,
    required String mediaType,
    bool is4k = false,
    int? profileId,
    int? rootFolderId,
    int? serverId,
  }) =>
      SeerrCreateRequest(
        mediaId: mediaId,
        mediaType: mediaType,
        seasons: 'all',
        is4k: is4k,
        profileId: profileId,
        rootFolderId: rootFolderId,
        serverId: serverId,
      );

  factory SeerrCreateRequest.specificSeasons({
    required int mediaId,
    required String mediaType,
    required List<int> seasonNumbers,
    bool is4k = false,
    int? profileId,
    int? rootFolderId,
    int? serverId,
  }) =>
      SeerrCreateRequest(
        mediaId: mediaId,
        mediaType: mediaType,
        seasons: seasonNumbers,
        is4k: is4k,
        profileId: profileId,
        rootFolderId: rootFolderId,
        serverId: serverId,
      );

  factory SeerrCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$SeerrCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrCreateRequestToJson(this);
}

Object? _seasonsToJson(Object? seasons) => seasons;

Object? _seasonsFromJson(Object? json) => json;

@JsonSerializable()
class SeerrMainSettingsDto {
  final String apiKey;
  final String? appLanguage;
  final String? applicationTitle;
  final String? applicationUrl;
  final bool? hideAvailable;
  final bool? partialRequestsEnabled;
  final bool? localLogin;
  final int? mediaServerType;
  final bool? newPlexLogin;
  final int? defaultPermissions;
  final bool? enableSpecialEpisodes;

  const SeerrMainSettingsDto({
    required this.apiKey,
    this.appLanguage,
    this.applicationTitle,
    this.applicationUrl,
    this.hideAvailable,
    this.partialRequestsEnabled,
    this.localLogin,
    this.mediaServerType,
    this.newPlexLogin,
    this.defaultPermissions,
    this.enableSpecialEpisodes,
  });

  factory SeerrMainSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$SeerrMainSettingsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrMainSettingsDtoToJson(this);
}

@JsonSerializable()
class SeerrStatusDto {
  final SeerrAppData? appData;

  const SeerrStatusDto({this.appData});

  factory SeerrStatusDto.fromJson(Map<String, dynamic> json) =>
      _$SeerrStatusDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrStatusDtoToJson(this);
}

@JsonSerializable()
class SeerrAppData {
  final String? version;
  final bool initialized;

  const SeerrAppData({this.version, this.initialized = false});

  factory SeerrAppData.fromJson(Map<String, dynamic> json) =>
      _$SeerrAppDataFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrAppDataToJson(this);
}

@JsonSerializable()
class SeerrRadarrSettings {
  final int id;
  final String name;
  final String hostname;
  final int port;
  final String apiKey;
  final bool useSsl;
  final String? baseUrl;
  final int activeProfileId;
  final String activeProfileName;
  final String activeDirectory;
  final int? activeAnimeProfileId;
  final String? activeAnimeProfileName;
  final String? activeAnimeDirectory;
  final bool is4k;
  final String minimumAvailability;
  final bool isDefault;
  final String? externalUrl;
  final bool syncEnabled;
  final bool preventSearch;
  final bool tagRequests;
  final List<int> tags;
  final List<SeerrQualityProfile> profiles;
  final List<SeerrRootFolder> rootFolders;

  const SeerrRadarrSettings({
    required this.id,
    required this.name,
    required this.hostname,
    required this.port,
    required this.apiKey,
    this.useSsl = false,
    this.baseUrl,
    required this.activeProfileId,
    required this.activeProfileName,
    required this.activeDirectory,
    this.activeAnimeProfileId,
    this.activeAnimeProfileName,
    this.activeAnimeDirectory,
    this.is4k = false,
    required this.minimumAvailability,
    this.isDefault = false,
    this.externalUrl,
    this.syncEnabled = false,
    this.preventSearch = false,
    this.tagRequests = false,
    this.tags = const [],
    this.profiles = const [],
    this.rootFolders = const [],
  });

  factory SeerrRadarrSettings.fromJson(Map<String, dynamic> json) =>
      _$SeerrRadarrSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrRadarrSettingsToJson(this);
}

@JsonSerializable()
class SeerrSonarrSettings {
  final int id;
  final String name;
  final String hostname;
  final int port;
  final String apiKey;
  final bool useSsl;
  final String? baseUrl;
  final int activeProfileId;
  final String activeProfileName;
  final String activeDirectory;
  final int? activeAnimeProfileId;
  final String? activeAnimeProfileName;
  final String? activeAnimeDirectory;
  final int? activeLanguageProfileId;
  final bool is4k;
  final bool enableSeasonFolders;
  final bool isDefault;
  final String? externalUrl;
  final bool syncEnabled;
  final bool preventSearch;
  final bool tagRequests;
  final List<int> tags;
  final List<SeerrQualityProfile> profiles;
  final List<SeerrRootFolder> rootFolders;

  const SeerrSonarrSettings({
    required this.id,
    required this.name,
    required this.hostname,
    required this.port,
    required this.apiKey,
    this.useSsl = false,
    this.baseUrl,
    required this.activeProfileId,
    required this.activeProfileName,
    required this.activeDirectory,
    this.activeAnimeProfileId,
    this.activeAnimeProfileName,
    this.activeAnimeDirectory,
    this.activeLanguageProfileId,
    this.is4k = false,
    this.enableSeasonFolders = false,
    this.isDefault = false,
    this.externalUrl,
    this.syncEnabled = false,
    this.preventSearch = false,
    this.tagRequests = false,
    this.tags = const [],
    this.profiles = const [],
    this.rootFolders = const [],
  });

  factory SeerrSonarrSettings.fromJson(Map<String, dynamic> json) =>
      _$SeerrSonarrSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrSonarrSettingsToJson(this);
}

@JsonSerializable()
class SeerrQualityProfile {
  final int id;
  final String name;

  const SeerrQualityProfile({required this.id, required this.name});

  factory SeerrQualityProfile.fromJson(Map<String, dynamic> json) =>
      _$SeerrQualityProfileFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrQualityProfileToJson(this);
}

@JsonSerializable()
class SeerrRootFolder {
  final int id;
  final String path;
  final int? freeSpace;
  final int? totalSpace;

  const SeerrRootFolder({
    required this.id,
    required this.path,
    this.freeSpace,
    this.totalSpace,
  });

  factory SeerrRootFolder.fromJson(Map<String, dynamic> json) =>
      _$SeerrRootFolderFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrRootFolderToJson(this);
}

@JsonSerializable()
class SeerrTag {
  final int id;
  final String label;

  const SeerrTag({required this.id, required this.label});

  factory SeerrTag.fromJson(Map<String, dynamic> json) =>
      _$SeerrTagFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrTagToJson(this);
}

@JsonSerializable()
class SeerrServiceServer {
  final int id;
  final String name;
  final bool is4k;
  final bool isDefault;
  final int activeProfileId;
  final String activeDirectory;
  final int? activeAnimeProfileId;
  final String? activeAnimeDirectory;
  final int? activeLanguageProfileId;
  final int? activeAnimeLanguageProfileId;
  final List<int> activeTags;
  final List<int>? activeAnimeTags;

  const SeerrServiceServer({
    required this.id,
    required this.name,
    this.is4k = false,
    this.isDefault = false,
    required this.activeProfileId,
    required this.activeDirectory,
    this.activeAnimeProfileId,
    this.activeAnimeDirectory,
    this.activeLanguageProfileId,
    this.activeAnimeLanguageProfileId,
    this.activeTags = const [],
    this.activeAnimeTags,
  });

  factory SeerrServiceServer.fromJson(Map<String, dynamic> json) =>
      _$SeerrServiceServerFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrServiceServerToJson(this);
}

@JsonSerializable()
class SeerrServiceServerDetails {
  final SeerrServiceServer server;
  final List<SeerrQualityProfile> profiles;
  final List<SeerrRootFolder> rootFolders;
  final List<SeerrLanguageProfile>? languageProfiles;
  final List<SeerrTag> tags;

  const SeerrServiceServerDetails({
    required this.server,
    this.profiles = const [],
    this.rootFolders = const [],
    this.languageProfiles,
    this.tags = const [],
  });

  factory SeerrServiceServerDetails.fromJson(Map<String, dynamic> json) =>
      _$SeerrServiceServerDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrServiceServerDetailsToJson(this);
}

@JsonSerializable()
class SeerrLanguageProfile {
  final int id;
  final String name;

  const SeerrLanguageProfile({required this.id, required this.name});

  factory SeerrLanguageProfile.fromJson(Map<String, dynamic> json) =>
      _$SeerrLanguageProfileFromJson(json);

  Map<String, dynamic> toJson() => _$SeerrLanguageProfileToJson(this);
}
