// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoonfinStatusResponse _$MoonfinStatusResponseFromJson(
  Map<String, dynamic> json,
) => MoonfinStatusResponse(
  enabled: json['enabled'] as bool? ?? false,
  authenticated: json['authenticated'] as bool? ?? false,
  url: json['url'] as String?,
  jellyseerrUserId: (json['jellyseerrUserId'] as num?)?.toInt(),
  displayName: json['displayName'] as String?,
  avatar: json['avatar'] as String?,
  permissions: (json['permissions'] as num?)?.toInt() ?? 0,
  sessionCreated: (json['sessionCreated'] as num?)?.toInt(),
  lastValidated: (json['lastValidated'] as num?)?.toInt(),
);

Map<String, dynamic> _$MoonfinStatusResponseToJson(
  MoonfinStatusResponse instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'authenticated': instance.authenticated,
  'url': instance.url,
  'jellyseerrUserId': instance.jellyseerrUserId,
  'displayName': instance.displayName,
  'avatar': instance.avatar,
  'permissions': instance.permissions,
  'sessionCreated': instance.sessionCreated,
  'lastValidated': instance.lastValidated,
};

MoonfinLoginRequest _$MoonfinLoginRequestFromJson(Map<String, dynamic> json) =>
    MoonfinLoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
      authType: json['authType'] as String? ?? 'jellyfin',
    );

Map<String, dynamic> _$MoonfinLoginRequestToJson(
  MoonfinLoginRequest instance,
) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
  'authType': instance.authType,
};

MoonfinLoginResponse _$MoonfinLoginResponseFromJson(
  Map<String, dynamic> json,
) => MoonfinLoginResponse(
  success: json['success'] as bool? ?? false,
  error: json['error'] as String?,
  jellyseerrUserId: (json['jellyseerrUserId'] as num?)?.toInt(),
  displayName: json['displayName'] as String?,
  avatar: json['avatar'] as String?,
  permissions: (json['permissions'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MoonfinLoginResponseToJson(
  MoonfinLoginResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'error': instance.error,
  'jellyseerrUserId': instance.jellyseerrUserId,
  'displayName': instance.displayName,
  'avatar': instance.avatar,
  'permissions': instance.permissions,
};

MoonfinValidateResponse _$MoonfinValidateResponseFromJson(
  Map<String, dynamic> json,
) => MoonfinValidateResponse(
  valid: json['valid'] as bool? ?? false,
  lastValidated: (json['lastValidated'] as num?)?.toInt(),
);

Map<String, dynamic> _$MoonfinValidateResponseToJson(
  MoonfinValidateResponse instance,
) => <String, dynamic>{
  'valid': instance.valid,
  'lastValidated': instance.lastValidated,
};

SeerrMainSettings _$SeerrMainSettingsFromJson(Map<String, dynamic> json) =>
    SeerrMainSettings(apiKey: json['apiKey'] as String);

Map<String, dynamic> _$SeerrMainSettingsToJson(SeerrMainSettings instance) =>
    <String, dynamic>{'apiKey': instance.apiKey};

SeerrStatus _$SeerrStatusFromJson(Map<String, dynamic> json) => SeerrStatus(
  version: json['version'] as String?,
  commitTag: (json['commitTag'] as num?)?.toInt(),
  updateAvailable: (json['updateAvailable'] as num?)?.toInt(),
  commitsBehind: (json['commitsBehind'] as num?)?.toInt(),
);

Map<String, dynamic> _$SeerrStatusToJson(SeerrStatus instance) =>
    <String, dynamic>{
      'version': instance.version,
      'commitTag': instance.commitTag,
      'updateAvailable': instance.updateAvailable,
      'commitsBehind': instance.commitsBehind,
    };
