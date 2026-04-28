import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:server_core/server_core.dart';

import '../repositories/multi_server_repository.dart';

/// Snapshot of the third-party "Home Screen Sections" plugin
/// (GUID [homeScreenSectionsPluginGuid]) capability for a single server.
@immutable
class HomeScreenSectionsCapability {
  final String serverId;
  final bool installed;
  final bool enabled;
  final String? pluginVersion;
  final List<HomeScreenSectionInfo> sections;
  final Object? lastError;

  const HomeScreenSectionsCapability({
    required this.serverId,
    required this.installed,
    required this.enabled,
    this.pluginVersion,
    this.sections = const [],
    this.lastError,
  });

  bool get isAvailable => installed && enabled;

  const HomeScreenSectionsCapability.unavailable({
    required this.serverId,
    this.lastError,
  })  : installed = false,
        enabled = false,
        pluginVersion = null,
        sections = const [];
}

/// Probes each Jellyfin server for the Home Screen Sections plugin and caches
/// the result. UI layers can listen for changes to render Settings screens
/// reactively.
class HomeScreenSectionsService extends ChangeNotifier {
  HomeScreenSectionsService(this._multiServer);

  final MultiServerRepository _multiServer;
  final _logger = Logger();

  final Map<String, HomeScreenSectionsCapability> _byServer = {};
  bool _disposed = false;

  Iterable<HomeScreenSectionsCapability> get availableServers =>
      _byServer.values.where((c) => c.isAvailable);

  /// All probed servers, including those without the plugin installed. Used
  /// by the integrations status screen to explain why a server isn't listed.
  Iterable<HomeScreenSectionsCapability> get allCapabilities =>
      _byServer.values;

  /// Probe every logged-in Jellyfin server. Failures are recorded as
  /// "unavailable" rather than propagated.
  Future<void> refreshAll() async {
    final sessions = await _multiServer.getLoggedInServers();
    await Future.wait(sessions.map((s) async {
      // Snapshots are keyed by baseUrl so they line up with the serverId
      // stored on HomeRow / AggregatedItem entries elsewhere in the app.
      final key = s.client.baseUrl;
      if (s.client.homeScreenSectionsApi == null) {
        _byServer[key] =
            HomeScreenSectionsCapability.unavailable(serverId: key);
        return;
      }
      await _probe(key, s.client);
    }));
    if (!_disposed) notifyListeners();
  }

  Future<void> _probe(String serverId, MediaServerClient client) async {
    final api = client.homeScreenSectionsApi;
    if (api == null) {
      _byServer[serverId] =
          HomeScreenSectionsCapability.unavailable(serverId: serverId);
      return;
    }

    // Confirm install via the standard plugin API; non-admin users will
    // silently fail this and rely on /HomeScreen/Meta below.
    String? installedVersion;
    try {
      final plugins = await client.adminPluginsApi.getInstalledPlugins();
      for (final p in plugins) {
        if (p.id.toLowerCase() == homeScreenSectionsPluginGuid) {
          installedVersion = p.version;
          break;
        }
      }
    } catch (_) {}

    HomeScreenMeta? meta;
    Object? metaError;
    try {
      meta = await api.getMeta();
    } catch (e) {
      metaError = e;
    }

    final installed = installedVersion != null || meta != null;
    final enabled = meta?.enabled ?? false;

    var sections = const <HomeScreenSectionInfo>[];
    if (installed && enabled) {
      try {
        sections = await api.getUserSections();
      } catch (e) {
        _logger.w('HSS: getUserSections failed for $serverId: $e');
      }
    }

    _byServer[serverId] = HomeScreenSectionsCapability(
      serverId: serverId,
      installed: installed,
      enabled: enabled,
      pluginVersion: installedVersion,
      sections: sections,
      lastError: metaError,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
