// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeerrRequest _$SeerrRequestFromJson(Map<String, dynamic> json) => SeerrRequest(
  id: (json['id'] as num).toInt(),
  status: (json['status'] as num).toInt(),
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  type: json['type'] as String,
  media:
      json['media'] == null
          ? null
          : SeerrMedia.fromJson(json['media'] as Map<String, dynamic>),
  requestedBy:
      json['requestedBy'] == null
          ? null
          : SeerrUser.fromJson(json['requestedBy'] as Map<String, dynamic>),
  seasonCount: (json['seasonCount'] as num?)?.toInt(),
  externalId: json['externalId'] as String?,
  is4k: json['is4k'] as bool? ?? false,
  seasons:
      (json['seasons'] as List<dynamic>?)
          ?.map((e) => SeerrSeasonRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$SeerrRequestToJson(SeerrRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'type': instance.type,
      'media': instance.media,
      'requestedBy': instance.requestedBy,
      'seasonCount': instance.seasonCount,
      'externalId': instance.externalId,
      'is4k': instance.is4k,
      'seasons': instance.seasons,
    };

SeerrSeasonRequest _$SeerrSeasonRequestFromJson(Map<String, dynamic> json) =>
    SeerrSeasonRequest(
      id: (json['id'] as num).toInt(),
      seasonNumber: (json['seasonNumber'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$SeerrSeasonRequestToJson(SeerrSeasonRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seasonNumber': instance.seasonNumber,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

SeerrMedia _$SeerrMediaFromJson(Map<String, dynamic> json) => SeerrMedia(
  id: (json['id'] as num).toInt(),
  mediaType: json['mediaType'] as String?,
  tmdbId: (json['tmdbId'] as num?)?.toInt(),
  tvdbId: (json['tvdbId'] as num?)?.toInt(),
  imdbId: json['imdbId'] as String?,
  status: (json['status'] as num?)?.toInt(),
  status4k: (json['status4k'] as num?)?.toInt(),
  mediaAddedAt: json['mediaAddedAt'] as String?,
  serviceId: (json['serviceId'] as num?)?.toInt(),
  serviceId4k: (json['serviceId4k'] as num?)?.toInt(),
  externalServiceId: (json['externalServiceId'] as num?)?.toInt(),
  externalServiceId4k: (json['externalServiceId4k'] as num?)?.toInt(),
  externalServiceSlug: json['externalServiceSlug'] as String?,
  externalServiceSlug4k: json['externalServiceSlug4k'] as String?,
  ratingKey: json['ratingKey'] as String?,
  ratingKey4k: json['ratingKey4k'] as String?,
  title: json['title'] as String?,
  name: json['name'] as String?,
  posterPath: json['posterPath'] as String?,
  backdropPath: json['backdropPath'] as String?,
  overview: json['overview'] as String?,
  releaseDate: json['releaseDate'] as String?,
  firstAirDate: json['firstAirDate'] as String?,
  originalLanguage: json['originalLanguage'] as String?,
  genreIds:
      (json['genreIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
  voteAverage: (json['voteAverage'] as num?)?.toDouble(),
  externalIds:
      json['externalIds'] == null
          ? null
          : SeerrExternalIds.fromJson(
            json['externalIds'] as Map<String, dynamic>,
          ),
  requestList:
      (json['requests'] as List<dynamic>?)
          ?.map((e) => SeerrRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$SeerrMediaToJson(SeerrMedia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaType': instance.mediaType,
      'tmdbId': instance.tmdbId,
      'tvdbId': instance.tvdbId,
      'imdbId': instance.imdbId,
      'status': instance.status,
      'status4k': instance.status4k,
      'mediaAddedAt': instance.mediaAddedAt,
      'serviceId': instance.serviceId,
      'serviceId4k': instance.serviceId4k,
      'externalServiceId': instance.externalServiceId,
      'externalServiceId4k': instance.externalServiceId4k,
      'externalServiceSlug': instance.externalServiceSlug,
      'externalServiceSlug4k': instance.externalServiceSlug4k,
      'ratingKey': instance.ratingKey,
      'ratingKey4k': instance.ratingKey4k,
      'title': instance.title,
      'name': instance.name,
      'posterPath': instance.posterPath,
      'backdropPath': instance.backdropPath,
      'overview': instance.overview,
      'releaseDate': instance.releaseDate,
      'firstAirDate': instance.firstAirDate,
      'originalLanguage': instance.originalLanguage,
      'genreIds': instance.genreIds,
      'voteAverage': instance.voteAverage,
      'externalIds': instance.externalIds,
      'requests': instance.requestList,
    };

SeerrExternalIds _$SeerrExternalIdsFromJson(Map<String, dynamic> json) =>
    SeerrExternalIds(
      tvdbId: (json['tvdbId'] as num?)?.toInt(),
      tmdbId: (json['tmdbId'] as num?)?.toInt(),
      imdbId: json['imdbId'] as String?,
    );

Map<String, dynamic> _$SeerrExternalIdsToJson(SeerrExternalIds instance) =>
    <String, dynamic>{
      'tvdbId': instance.tvdbId,
      'tmdbId': instance.tmdbId,
      'imdbId': instance.imdbId,
    };

SeerrUser _$SeerrUserFromJson(Map<String, dynamic> json) => SeerrUser(
  id: (json['id'] as num).toInt(),
  displayName: json['displayName'] as String?,
  username: json['username'] as String?,
  email: json['email'] as String?,
  avatar: json['avatar'] as String?,
  apiKey: json['apiKey'] as String?,
  permissions: (json['permissions'] as num?)?.toInt(),
);

Map<String, dynamic> _$SeerrUserToJson(SeerrUser instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'username': instance.username,
  'email': instance.email,
  'avatar': instance.avatar,
  'apiKey': instance.apiKey,
  'permissions': instance.permissions,
};

SeerrDiscoverPage _$SeerrDiscoverPageFromJson(Map<String, dynamic> json) =>
    SeerrDiscoverPage(
      results:
          (json['results'] as List<dynamic>?)
              ?.map(
                (e) => SeerrDiscoverItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalResults: (json['totalResults'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$SeerrDiscoverPageToJson(SeerrDiscoverPage instance) =>
    <String, dynamic>{
      'results': instance.results,
      'totalPages': instance.totalPages,
      'totalResults': instance.totalResults,
      'page': instance.page,
    };

SeerrDiscoverItem _$SeerrDiscoverItemFromJson(Map<String, dynamic> json) =>
    SeerrDiscoverItem(
      id: (json['id'] as num).toInt(),
      mediaType: json['mediaType'] as String?,
      title: json['title'] as String?,
      name: json['name'] as String?,
      originalTitle: json['originalTitle'] as String?,
      originalName: json['originalName'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      overview: json['overview'] as String?,
      releaseDate: json['releaseDate'] as String?,
      firstAirDate: json['firstAirDate'] as String?,
      originalLanguage: json['originalLanguage'] as String?,
      genreIds:
          (json['genreIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt(),
      popularity: (json['popularity'] as num?)?.toDouble(),
      adult: json['adult'] as bool? ?? false,
      mediaInfo:
          json['mediaInfo'] == null
              ? null
              : SeerrMediaInfo.fromJson(
                json['mediaInfo'] as Map<String, dynamic>,
              ),
      character: json['character'] as String?,
      job: json['job'] as String?,
      department: json['department'] as String?,
    );

Map<String, dynamic> _$SeerrDiscoverItemToJson(SeerrDiscoverItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaType': instance.mediaType,
      'title': instance.title,
      'name': instance.name,
      'originalTitle': instance.originalTitle,
      'originalName': instance.originalName,
      'posterPath': instance.posterPath,
      'backdropPath': instance.backdropPath,
      'overview': instance.overview,
      'releaseDate': instance.releaseDate,
      'firstAirDate': instance.firstAirDate,
      'originalLanguage': instance.originalLanguage,
      'genreIds': instance.genreIds,
      'voteAverage': instance.voteAverage,
      'voteCount': instance.voteCount,
      'popularity': instance.popularity,
      'adult': instance.adult,
      'mediaInfo': instance.mediaInfo,
      'character': instance.character,
      'job': instance.job,
      'department': instance.department,
    };

SeerrMovieDetails _$SeerrMovieDetailsFromJson(Map<String, dynamic> json) =>
    SeerrMovieDetails(
      id: (json['id'] as num).toInt(),
      mediaType: json['mediaType'] as String? ?? 'movie',
      title: json['title'] as String,
      tagline: json['tagline'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      overview: json['overview'] as String?,
      releaseDate: json['releaseDate'] as String?,
      status: json['status'] as String?,
      runtime: (json['runtime'] as num?)?.toInt(),
      budget: (json['budget'] as num?)?.toInt(),
      revenue: (json['revenue'] as num?)?.toInt(),
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt(),
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => SeerrGenre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      credits:
          json['credits'] == null
              ? null
              : SeerrCredits.fromJson(json['credits'] as Map<String, dynamic>),
      externalIds:
          json['externalIds'] == null
              ? null
              : SeerrExternalIds.fromJson(
                json['externalIds'] as Map<String, dynamic>,
              ),
      mediaInfo:
          json['mediaInfo'] == null
              ? null
              : SeerrMediaInfo.fromJson(
                json['mediaInfo'] as Map<String, dynamic>,
              ),
      keywords:
          (json['keywords'] as List<dynamic>?)
              ?.map((e) => SeerrKeyword.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SeerrMovieDetailsToJson(SeerrMovieDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaType': instance.mediaType,
      'title': instance.title,
      'tagline': instance.tagline,
      'posterPath': instance.posterPath,
      'backdropPath': instance.backdropPath,
      'overview': instance.overview,
      'releaseDate': instance.releaseDate,
      'status': instance.status,
      'runtime': instance.runtime,
      'budget': instance.budget,
      'revenue': instance.revenue,
      'voteAverage': instance.voteAverage,
      'voteCount': instance.voteCount,
      'genres': instance.genres,
      'credits': instance.credits,
      'externalIds': instance.externalIds,
      'mediaInfo': instance.mediaInfo,
      'keywords': instance.keywords,
    };

SeerrTvDetails _$SeerrTvDetailsFromJson(Map<String, dynamic> json) =>
    SeerrTvDetails(
      id: (json['id'] as num).toInt(),
      mediaType: json['mediaType'] as String? ?? 'tv',
      name: json['name'] as String?,
      title: json['title'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      overview: json['overview'] as String?,
      tagline: json['tagline'] as String?,
      firstAirDate: json['firstAirDate'] as String?,
      lastAirDate: json['lastAirDate'] as String?,
      status: json['status'] as String?,
      numberOfSeasons: (json['numberOfSeasons'] as num?)?.toInt(),
      numberOfEpisodes: (json['numberOfEpisodes'] as num?)?.toInt(),
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt(),
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => SeerrGenre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      credits:
          json['credits'] == null
              ? null
              : SeerrCredits.fromJson(json['credits'] as Map<String, dynamic>),
      networks:
          (json['networks'] as List<dynamic>?)
              ?.map((e) => SeerrNetwork.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      externalIds:
          json['externalIds'] == null
              ? null
              : SeerrExternalIds.fromJson(
                json['externalIds'] as Map<String, dynamic>,
              ),
      mediaInfo:
          json['mediaInfo'] == null
              ? null
              : SeerrMediaInfo.fromJson(
                json['mediaInfo'] as Map<String, dynamic>,
              ),
      keywords:
          (json['keywords'] as List<dynamic>?)
              ?.map((e) => SeerrKeyword.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SeerrTvDetailsToJson(SeerrTvDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaType': instance.mediaType,
      'name': instance.name,
      'title': instance.title,
      'posterPath': instance.posterPath,
      'backdropPath': instance.backdropPath,
      'overview': instance.overview,
      'tagline': instance.tagline,
      'firstAirDate': instance.firstAirDate,
      'lastAirDate': instance.lastAirDate,
      'status': instance.status,
      'numberOfSeasons': instance.numberOfSeasons,
      'numberOfEpisodes': instance.numberOfEpisodes,
      'voteAverage': instance.voteAverage,
      'voteCount': instance.voteCount,
      'genres': instance.genres,
      'credits': instance.credits,
      'networks': instance.networks,
      'externalIds': instance.externalIds,
      'mediaInfo': instance.mediaInfo,
      'keywords': instance.keywords,
    };

SeerrGenre _$SeerrGenreFromJson(Map<String, dynamic> json) => SeerrGenre(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  backdrops:
      (json['backdrops'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$SeerrGenreToJson(SeerrGenre instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'backdrops': instance.backdrops,
    };

SeerrNetwork _$SeerrNetworkFromJson(Map<String, dynamic> json) => SeerrNetwork(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  logoPath: json['logoPath'] as String?,
  originCountry: json['originCountry'] as String?,
);

Map<String, dynamic> _$SeerrNetworkToJson(SeerrNetwork instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logoPath': instance.logoPath,
      'originCountry': instance.originCountry,
    };

SeerrStudio _$SeerrStudioFromJson(Map<String, dynamic> json) => SeerrStudio(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  logoPath: json['logoPath'] as String?,
);

Map<String, dynamic> _$SeerrStudioToJson(SeerrStudio instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logoPath': instance.logoPath,
    };

SeerrKeyword _$SeerrKeywordFromJson(Map<String, dynamic> json) =>
    SeerrKeyword(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$SeerrKeywordToJson(SeerrKeyword instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

SeerrCredits _$SeerrCreditsFromJson(Map<String, dynamic> json) => SeerrCredits(
  cast:
      (json['cast'] as List<dynamic>?)
          ?.map((e) => SeerrCastMember.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  crew:
      (json['crew'] as List<dynamic>?)
          ?.map((e) => SeerrCrewMember.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SeerrCreditsToJson(SeerrCredits instance) =>
    <String, dynamic>{'cast': instance.cast, 'crew': instance.crew};

SeerrCastMember _$SeerrCastMemberFromJson(Map<String, dynamic> json) =>
    SeerrCastMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      character: json['character'] as String?,
      profilePath: json['profilePath'] as String?,
      order: (json['order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SeerrCastMemberToJson(SeerrCastMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'character': instance.character,
      'profilePath': instance.profilePath,
      'order': instance.order,
    };

SeerrCrewMember _$SeerrCrewMemberFromJson(Map<String, dynamic> json) =>
    SeerrCrewMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      department: json['department'] as String?,
      job: json['job'] as String?,
      profilePath: json['profilePath'] as String?,
    );

Map<String, dynamic> _$SeerrCrewMemberToJson(SeerrCrewMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'department': instance.department,
      'job': instance.job,
      'profilePath': instance.profilePath,
    };

SeerrMediaInfo _$SeerrMediaInfoFromJson(Map<String, dynamic> json) =>
    SeerrMediaInfo(
      id: (json['id'] as num?)?.toInt(),
      tmdbId: (json['tmdbId'] as num?)?.toInt(),
      tvdbId: (json['tvdbId'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
      status4k: (json['status4k'] as num?)?.toInt(),
      requests:
          (json['requests'] as List<dynamic>?)
              ?.map((e) => SeerrRequest.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$SeerrMediaInfoToJson(SeerrMediaInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tmdbId': instance.tmdbId,
      'tvdbId': instance.tvdbId,
      'status': instance.status,
      'status4k': instance.status4k,
      'requests': instance.requests,
    };

SeerrPersonDetails _$SeerrPersonDetailsFromJson(Map<String, dynamic> json) =>
    SeerrPersonDetails(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      biography: json['biography'] as String?,
      birthday: json['birthday'] as String?,
      deathday: json['deathday'] as String?,
      placeOfBirth: json['placeOfBirth'] as String?,
      profilePath: json['profilePath'] as String?,
      knownForDepartment: json['knownForDepartment'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SeerrPersonDetailsToJson(SeerrPersonDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'biography': instance.biography,
      'birthday': instance.birthday,
      'deathday': instance.deathday,
      'placeOfBirth': instance.placeOfBirth,
      'profilePath': instance.profilePath,
      'knownForDepartment': instance.knownForDepartment,
      'popularity': instance.popularity,
    };

SeerrPersonCombinedCredits _$SeerrPersonCombinedCreditsFromJson(
  Map<String, dynamic> json,
) => SeerrPersonCombinedCredits(
  cast:
      (json['cast'] as List<dynamic>?)
          ?.map((e) => SeerrDiscoverItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  crew:
      (json['crew'] as List<dynamic>?)
          ?.map((e) => SeerrDiscoverItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SeerrPersonCombinedCreditsToJson(
  SeerrPersonCombinedCredits instance,
) => <String, dynamic>{'cast': instance.cast, 'crew': instance.crew};

SeerrPageInfo _$SeerrPageInfoFromJson(Map<String, dynamic> json) =>
    SeerrPageInfo(
      pages: (json['pages'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      results: (json['results'] as num).toInt(),
      page: (json['page'] as num).toInt(),
    );

Map<String, dynamic> _$SeerrPageInfoToJson(SeerrPageInfo instance) =>
    <String, dynamic>{
      'pages': instance.pages,
      'pageSize': instance.pageSize,
      'results': instance.results,
      'page': instance.page,
    };

SeerrRequestListResponse _$SeerrRequestListResponseFromJson(
  Map<String, dynamic> json,
) => SeerrRequestListResponse(
  pageInfo:
      json['pageInfo'] == null
          ? null
          : SeerrPageInfo.fromJson(json['pageInfo'] as Map<String, dynamic>),
  results:
      (json['results'] as List<dynamic>?)
          ?.map((e) => SeerrRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SeerrRequestListResponseToJson(
  SeerrRequestListResponse instance,
) => <String, dynamic>{
  'pageInfo': instance.pageInfo,
  'results': instance.results,
};

SeerrCreateRequest _$SeerrCreateRequestFromJson(Map<String, dynamic> json) =>
    SeerrCreateRequest(
      mediaId: (json['mediaId'] as num).toInt(),
      mediaType: json['mediaType'] as String,
      seasons: _seasonsFromJson(json['seasons']),
      tvdbId: (json['tvdbId'] as num?)?.toInt(),
      imdbId: json['imdbId'] as String?,
      is4k: json['is4k'] as bool? ?? false,
      profileId: (json['profileId'] as num?)?.toInt(),
      rootFolderId: (json['rootFolderId'] as num?)?.toInt(),
      serverId: (json['serverId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SeerrCreateRequestToJson(SeerrCreateRequest instance) =>
    <String, dynamic>{
      'mediaId': instance.mediaId,
      'mediaType': instance.mediaType,
      'seasons': _seasonsToJson(instance.seasons),
      'tvdbId': instance.tvdbId,
      'imdbId': instance.imdbId,
      'is4k': instance.is4k,
      'profileId': instance.profileId,
      'rootFolderId': instance.rootFolderId,
      'serverId': instance.serverId,
    };

SeerrMainSettingsDto _$SeerrMainSettingsDtoFromJson(
  Map<String, dynamic> json,
) => SeerrMainSettingsDto(
  apiKey: json['apiKey'] as String,
  appLanguage: json['appLanguage'] as String?,
  applicationTitle: json['applicationTitle'] as String?,
  applicationUrl: json['applicationUrl'] as String?,
  hideAvailable: json['hideAvailable'] as bool?,
  partialRequestsEnabled: json['partialRequestsEnabled'] as bool?,
  localLogin: json['localLogin'] as bool?,
  mediaServerType: (json['mediaServerType'] as num?)?.toInt(),
  newPlexLogin: json['newPlexLogin'] as bool?,
  defaultPermissions: (json['defaultPermissions'] as num?)?.toInt(),
  enableSpecialEpisodes: json['enableSpecialEpisodes'] as bool?,
);

Map<String, dynamic> _$SeerrMainSettingsDtoToJson(
  SeerrMainSettingsDto instance,
) => <String, dynamic>{
  'apiKey': instance.apiKey,
  'appLanguage': instance.appLanguage,
  'applicationTitle': instance.applicationTitle,
  'applicationUrl': instance.applicationUrl,
  'hideAvailable': instance.hideAvailable,
  'partialRequestsEnabled': instance.partialRequestsEnabled,
  'localLogin': instance.localLogin,
  'mediaServerType': instance.mediaServerType,
  'newPlexLogin': instance.newPlexLogin,
  'defaultPermissions': instance.defaultPermissions,
  'enableSpecialEpisodes': instance.enableSpecialEpisodes,
};

SeerrStatusDto _$SeerrStatusDtoFromJson(Map<String, dynamic> json) =>
    SeerrStatusDto(
      appData:
          json['appData'] == null
              ? null
              : SeerrAppData.fromJson(json['appData'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SeerrStatusDtoToJson(SeerrStatusDto instance) =>
    <String, dynamic>{'appData': instance.appData};

SeerrAppData _$SeerrAppDataFromJson(Map<String, dynamic> json) => SeerrAppData(
  version: json['version'] as String?,
  initialized: json['initialized'] as bool? ?? false,
);

Map<String, dynamic> _$SeerrAppDataToJson(SeerrAppData instance) =>
    <String, dynamic>{
      'version': instance.version,
      'initialized': instance.initialized,
    };

SeerrRadarrSettings _$SeerrRadarrSettingsFromJson(Map<String, dynamic> json) =>
    SeerrRadarrSettings(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      hostname: json['hostname'] as String,
      port: (json['port'] as num).toInt(),
      apiKey: json['apiKey'] as String,
      useSsl: json['useSsl'] as bool? ?? false,
      baseUrl: json['baseUrl'] as String?,
      activeProfileId: (json['activeProfileId'] as num).toInt(),
      activeProfileName: json['activeProfileName'] as String,
      activeDirectory: json['activeDirectory'] as String,
      activeAnimeProfileId: (json['activeAnimeProfileId'] as num?)?.toInt(),
      activeAnimeProfileName: json['activeAnimeProfileName'] as String?,
      activeAnimeDirectory: json['activeAnimeDirectory'] as String?,
      is4k: json['is4k'] as bool? ?? false,
      minimumAvailability: json['minimumAvailability'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      externalUrl: json['externalUrl'] as String?,
      syncEnabled: json['syncEnabled'] as bool? ?? false,
      preventSearch: json['preventSearch'] as bool? ?? false,
      tagRequests: json['tagRequests'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      profiles:
          (json['profiles'] as List<dynamic>?)
              ?.map(
                (e) => SeerrQualityProfile.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      rootFolders:
          (json['rootFolders'] as List<dynamic>?)
              ?.map((e) => SeerrRootFolder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SeerrRadarrSettingsToJson(
  SeerrRadarrSettings instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'hostname': instance.hostname,
  'port': instance.port,
  'apiKey': instance.apiKey,
  'useSsl': instance.useSsl,
  'baseUrl': instance.baseUrl,
  'activeProfileId': instance.activeProfileId,
  'activeProfileName': instance.activeProfileName,
  'activeDirectory': instance.activeDirectory,
  'activeAnimeProfileId': instance.activeAnimeProfileId,
  'activeAnimeProfileName': instance.activeAnimeProfileName,
  'activeAnimeDirectory': instance.activeAnimeDirectory,
  'is4k': instance.is4k,
  'minimumAvailability': instance.minimumAvailability,
  'isDefault': instance.isDefault,
  'externalUrl': instance.externalUrl,
  'syncEnabled': instance.syncEnabled,
  'preventSearch': instance.preventSearch,
  'tagRequests': instance.tagRequests,
  'tags': instance.tags,
  'profiles': instance.profiles,
  'rootFolders': instance.rootFolders,
};

SeerrSonarrSettings _$SeerrSonarrSettingsFromJson(
  Map<String, dynamic> json,
) => SeerrSonarrSettings(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  hostname: json['hostname'] as String,
  port: (json['port'] as num).toInt(),
  apiKey: json['apiKey'] as String,
  useSsl: json['useSsl'] as bool? ?? false,
  baseUrl: json['baseUrl'] as String?,
  activeProfileId: (json['activeProfileId'] as num).toInt(),
  activeProfileName: json['activeProfileName'] as String,
  activeDirectory: json['activeDirectory'] as String,
  activeAnimeProfileId: (json['activeAnimeProfileId'] as num?)?.toInt(),
  activeAnimeProfileName: json['activeAnimeProfileName'] as String?,
  activeAnimeDirectory: json['activeAnimeDirectory'] as String?,
  activeLanguageProfileId: (json['activeLanguageProfileId'] as num?)?.toInt(),
  is4k: json['is4k'] as bool? ?? false,
  enableSeasonFolders: json['enableSeasonFolders'] as bool? ?? false,
  isDefault: json['isDefault'] as bool? ?? false,
  externalUrl: json['externalUrl'] as String?,
  syncEnabled: json['syncEnabled'] as bool? ?? false,
  preventSearch: json['preventSearch'] as bool? ?? false,
  tagRequests: json['tagRequests'] as bool? ?? false,
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  profiles:
      (json['profiles'] as List<dynamic>?)
          ?.map((e) => SeerrQualityProfile.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  rootFolders:
      (json['rootFolders'] as List<dynamic>?)
          ?.map((e) => SeerrRootFolder.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SeerrSonarrSettingsToJson(
  SeerrSonarrSettings instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'hostname': instance.hostname,
  'port': instance.port,
  'apiKey': instance.apiKey,
  'useSsl': instance.useSsl,
  'baseUrl': instance.baseUrl,
  'activeProfileId': instance.activeProfileId,
  'activeProfileName': instance.activeProfileName,
  'activeDirectory': instance.activeDirectory,
  'activeAnimeProfileId': instance.activeAnimeProfileId,
  'activeAnimeProfileName': instance.activeAnimeProfileName,
  'activeAnimeDirectory': instance.activeAnimeDirectory,
  'activeLanguageProfileId': instance.activeLanguageProfileId,
  'is4k': instance.is4k,
  'enableSeasonFolders': instance.enableSeasonFolders,
  'isDefault': instance.isDefault,
  'externalUrl': instance.externalUrl,
  'syncEnabled': instance.syncEnabled,
  'preventSearch': instance.preventSearch,
  'tagRequests': instance.tagRequests,
  'tags': instance.tags,
  'profiles': instance.profiles,
  'rootFolders': instance.rootFolders,
};

SeerrQualityProfile _$SeerrQualityProfileFromJson(Map<String, dynamic> json) =>
    SeerrQualityProfile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$SeerrQualityProfileToJson(
  SeerrQualityProfile instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

SeerrRootFolder _$SeerrRootFolderFromJson(Map<String, dynamic> json) =>
    SeerrRootFolder(
      id: (json['id'] as num).toInt(),
      path: json['path'] as String,
      freeSpace: (json['freeSpace'] as num?)?.toInt(),
      totalSpace: (json['totalSpace'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SeerrRootFolderToJson(SeerrRootFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'freeSpace': instance.freeSpace,
      'totalSpace': instance.totalSpace,
    };

SeerrTag _$SeerrTagFromJson(Map<String, dynamic> json) =>
    SeerrTag(id: (json['id'] as num).toInt(), label: json['label'] as String);

Map<String, dynamic> _$SeerrTagToJson(SeerrTag instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
};

SeerrServiceServer _$SeerrServiceServerFromJson(Map<String, dynamic> json) =>
    SeerrServiceServer(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      is4k: json['is4k'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
      activeProfileId: (json['activeProfileId'] as num).toInt(),
      activeDirectory: json['activeDirectory'] as String,
      activeAnimeProfileId: (json['activeAnimeProfileId'] as num?)?.toInt(),
      activeAnimeDirectory: json['activeAnimeDirectory'] as String?,
      activeLanguageProfileId:
          (json['activeLanguageProfileId'] as num?)?.toInt(),
      activeAnimeLanguageProfileId:
          (json['activeAnimeLanguageProfileId'] as num?)?.toInt(),
      activeTags:
          (json['activeTags'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      activeAnimeTags:
          (json['activeAnimeTags'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(),
    );

Map<String, dynamic> _$SeerrServiceServerToJson(SeerrServiceServer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is4k': instance.is4k,
      'isDefault': instance.isDefault,
      'activeProfileId': instance.activeProfileId,
      'activeDirectory': instance.activeDirectory,
      'activeAnimeProfileId': instance.activeAnimeProfileId,
      'activeAnimeDirectory': instance.activeAnimeDirectory,
      'activeLanguageProfileId': instance.activeLanguageProfileId,
      'activeAnimeLanguageProfileId': instance.activeAnimeLanguageProfileId,
      'activeTags': instance.activeTags,
      'activeAnimeTags': instance.activeAnimeTags,
    };

SeerrServiceServerDetails _$SeerrServiceServerDetailsFromJson(
  Map<String, dynamic> json,
) => SeerrServiceServerDetails(
  server: SeerrServiceServer.fromJson(json['server'] as Map<String, dynamic>),
  profiles:
      (json['profiles'] as List<dynamic>?)
          ?.map((e) => SeerrQualityProfile.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  rootFolders:
      (json['rootFolders'] as List<dynamic>?)
          ?.map((e) => SeerrRootFolder.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  languageProfiles:
      (json['languageProfiles'] as List<dynamic>?)
          ?.map((e) => SeerrLanguageProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => SeerrTag.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SeerrServiceServerDetailsToJson(
  SeerrServiceServerDetails instance,
) => <String, dynamic>{
  'server': instance.server,
  'profiles': instance.profiles,
  'rootFolders': instance.rootFolders,
  'languageProfiles': instance.languageProfiles,
  'tags': instance.tags,
};

SeerrLanguageProfile _$SeerrLanguageProfileFromJson(
  Map<String, dynamic> json,
) => SeerrLanguageProfile(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$SeerrLanguageProfileToJson(
  SeerrLanguageProfile instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};
