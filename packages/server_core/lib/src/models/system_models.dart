import 'server_models.dart';

class PublicSystemInfo {
  final String serverName;
  final String version;
  final String? productName;
  final String id;
  final bool startupWizardCompleted;
  final String? localAddress;

  const PublicSystemInfo({
    required this.serverName,
    required this.version,
    this.productName,
    required this.id,
    this.startupWizardCompleted = false,
    this.localAddress,
  });

  factory PublicSystemInfo.fromJson(Map<String, dynamic> json) =>
      PublicSystemInfo(
        serverName: json['ServerName'] as String? ?? '',
        version: json['Version'] as String? ?? '',
        productName: json['ProductName'] as String?,
        id: json['Id'] as String? ?? '',
        startupWizardCompleted:
            json['StartupWizardCompleted'] as bool? ?? false,
        localAddress: json['LocalAddress'] as String?,
      );
}

class SystemInfo {
  final String serverName;
  final String version;
  final String? productName;
  final String id;
  final String? operatingSystem;
  final bool hasPendingRestart;
  final bool supportsLibraryMonitor;
  final bool canSelfRestart;

  const SystemInfo({
    required this.serverName,
    required this.version,
    this.productName,
    required this.id,
    this.operatingSystem,
    this.hasPendingRestart = false,
    this.supportsLibraryMonitor = false,
    this.canSelfRestart = false,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) => SystemInfo(
        serverName: json['ServerName'] as String? ?? '',
        version: json['Version'] as String? ?? '',
        productName: json['ProductName'] as String?,
        id: json['Id'] as String? ?? '',
        operatingSystem: json['OperatingSystem'] as String?,
        hasPendingRestart: json['HasPendingRestart'] as bool? ?? false,
        supportsLibraryMonitor:
            json['SupportsLibraryMonitor'] as bool? ?? false,
        canSelfRestart: json['CanSelfRestart'] as bool? ?? false,
      );
}

class AuthResult {
  final String accessToken;
  final ServerUser user;
  final String? serverId;

  const AuthResult({
    required this.accessToken,
    required this.user,
    this.serverId,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['AccessToken'] as String? ?? '',
        user: ServerUser.fromJson(
            json['User'] as Map<String, dynamic>? ?? const {}),
        serverId: json['ServerId'] as String?,
      );
}

class DisplayPreferences {
  final String id;
  final String? sortBy;
  final String? sortOrder;
  final String? viewType;
  final Map<String, String> customPrefs;

  const DisplayPreferences({
    required this.id,
    this.sortBy,
    this.sortOrder,
    this.viewType,
    this.customPrefs = const {},
  });

  factory DisplayPreferences.fromJson(Map<String, dynamic> json) =>
      DisplayPreferences(
        id: json['Id'] as String? ?? '',
        sortBy: json['SortBy'] as String?,
        sortOrder: json['SortOrder'] as String?,
        viewType: json['ViewType'] as String?,
        customPrefs: (json['CustomPrefs'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            const {},
      );

  Map<String, dynamic> toJson() => {
        'Id': id,
        if (sortBy != null) 'SortBy': sortBy,
        if (sortOrder != null) 'SortOrder': sortOrder,
        if (viewType != null) 'ViewType': viewType,
        'CustomPrefs': customPrefs,
      };
}
