import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

import '../../data/models/aggregated_item.dart';
import '../../data/services/download_notification_service.dart';
import '../../data/services/media_server_client_factory.dart';
import '../../data/services/plugin_sync_service.dart';
import '../../data/services/socket_handler.dart';
import '../../di/modules/app_module.dart';
import '../../di/modules/playback_module.dart';
import '../../di/modules/server_module.dart';
import '../../preference/preference_constants.dart';
import '../store/authentication_preferences.dart';
import '../store/authentication_store.dart';
import '../store/credential_store.dart';
import 'server_repository.dart';
import 'user_repository.dart';

enum SessionState { ready, restoring, switching }

class SessionRepository {
  static const List<String> _supportedRemoteCommands = [
    'DisplayMessage',
    'SetVolume',
    'Mute',
    'Unmute',
    'ToggleMute',
    'SetAudioStreamIndex',
    'SetSubtitleStreamIndex',
    'SetRepeatMode',
    'SetShuffleQueue',
  ];

  final AuthenticationStore _authStore;
  final AuthenticationPreferences _authPrefs;
  final CredentialStore _credentialStore;
  final MediaServerClientFactory _clientFactory;
  final SocketHandler _socketHandler;
  final ServerRepository _serverRepository;
  final UserRepository _userRepository;
  final PluginSyncService _pluginSyncService;
  final _logger = Logger();

  String? _activeServerId;
  String? _activeUserId;
  SessionState _state = SessionState.ready;
  StreamSubscription<ServerWebSocketMessage>? _remoteCommandSubscription;
  double _lastUnmutedVolume = 100;
  bool _remoteMuted = false;

  final _stateController = StreamController<SessionState>.broadcast();

  SessionRepository(
    this._authStore,
    this._authPrefs,
    this._credentialStore,
    this._clientFactory,
    this._socketHandler,
    this._serverRepository,
    this._userRepository,
    this._pluginSyncService,
  );

  String? get activeServerId => _activeServerId;
  String? get activeUserId => _activeUserId;
  SessionState get state => _state;
  Stream<SessionState> get stateStream => _stateController.stream;

  Future<bool> restoreSession() async {
    _setState(SessionState.restoring);

    final behavior = _authPrefs.loginBehavior;
    String serverId;
    String userId;

    switch (behavior) {
      case UserSelectBehavior.disabled:
        _setState(SessionState.ready);
        return false;
      case UserSelectBehavior.lastUser:
        serverId = _authPrefs.savedLastServerId;
        userId = _authPrefs.savedLastUserId;
      case UserSelectBehavior.specificUser:
        serverId = _authPrefs.savedAutoLoginServerId;
        userId = _authPrefs.savedAutoLoginUserId;
    }

    if (serverId.isEmpty || userId.isEmpty) {
      _setState(SessionState.ready);
      return false;
    }

    return switchCurrentSession(serverId: serverId, userId: userId);
  }

  Future<bool> switchCurrentSession({
    required String serverId,
    required String userId,
    String? username,
    String? password,
  }) async {
    _setState(SessionState.switching);
    _pluginSyncService.resetState();

    final server = _serverRepository.getServer(serverId);
    if (server == null) {
      _logger.w('Server $serverId not found in stored servers');
      _setState(SessionState.ready);
      return false;
    }

    final users = _authStore.getUsers(serverId);
    final userIndex = users.indexWhere((u) => u.id == userId);
    if (userIndex < 0) {
      _logger.w('User $userId not found for server $serverId');
      _setState(SessionState.ready);
      return false;
    }
    final user = users[userIndex];

    final token = await _credentialStore.getToken(serverId);
    final accessToken = token ?? user.accessToken;

    final client = _clientFactory.getClient(
      serverId: serverId,
      serverType: server.serverType,
      baseUrl: server.address,
    );

    client.accessToken = accessToken;
    client.userId = userId;

    setActiveServerClient(client);
    resetUserScopedSingletons();
    setActiveStreamResolver(client);
    _socketHandler.connectTo(client);
    _bindRemoteCommandHandling();

    _activeServerId = serverId;
    _activeUserId = userId;

    await _reportRemoteCapabilities(client);

    var updatedUser = user;
    try {
      final serverUser = await client.usersApi.getCurrentUser();
      final isAdmin = serverUser.policy?.isAdministrator ?? false;
      final canDownload = serverUser.policy?.enableContentDownloading ?? false;

      if (isAdmin != user.isAdministrator || canDownload != user.canDownload) {
        updatedUser = user.copyWith(
          isAdministrator: isAdmin,
          canDownload: canDownload,
        );
        await _authStore.putUser(updatedUser);
      }
    } catch (_) {
    }

    _userRepository.setCurrentUser(updatedUser);
    await _authPrefs.setLastServerId(serverId);
    await _authPrefs.setLastUserId(userId);

    await _pluginSyncService.syncOnLogin(client);

    await _pluginSyncService.configureSeerr(
      client,
      username: username ?? user.name,
      password: password,
    );

    _setState(SessionState.ready);
    return true;
  }

  Future<void> destroyCurrentSession() async {
    final serverId = _activeServerId;
    final userId = _activeUserId;
    _pluginSyncService.resetState();

    // Revoke the token server-side
    if (serverId != null) {
      try {
        final client = _clientFactory.getClientIfExists(serverId);
        await client?.authApi.logout();
      } catch (_) {}
    }

    _remoteCommandSubscription?.cancel();
    _remoteCommandSubscription = null;
    _socketHandler.disconnect();

    if (serverId != null) {
      await _credentialStore.deleteToken(serverId);
      if (userId != null) {
        await _authStore.removeUser(serverId, userId);
      }
      _clientFactory.removeClient(serverId);
    }

    await _authPrefs.setLastServerId('');
    await _authPrefs.setLastUserId('');
    await _authPrefs.clearAutoLogin();

    _activeServerId = null;
    _activeUserId = null;
    _userRepository.setCurrentUser(null);
    _setState(SessionState.ready);
  }

  void _setState(SessionState state) {
    _state = state;
    _stateController.add(state);
  }

  void _bindRemoteCommandHandling() {
    _remoteCommandSubscription?.cancel();
    _remoteCommandSubscription = _socketHandler.events.listen(
      (event) => unawaited(_handleRemoteCommand(event)),
    );
  }

  Future<void> _reportRemoteCapabilities(MediaServerClient client) async {
    try {
      await client.sessionApi.reportCapabilities({
        'PlayableMediaTypes': const ['Audio', 'Video'],
        'SupportsMediaControl': true,
        'SupportedCommands': _supportedRemoteCommands,
      });
    } catch (_) {}
  }

  Future<void> _handleRemoteCommand(ServerWebSocketMessage event) async {
    switch (event) {
      case PlayMessage():
        await _handlePlayMessage(event);
      case PlaystateMessage():
        await _handlePlaystateMessage(event);
      case GeneralCommandMessage():
        await _handleGeneralCommandMessage(event);
      default:
        break;
    }
  }

  int? _parseIntArg(Map<String, String> args, String key) {
    final value = args[key];
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }

  Future<void> _setLocalVolume(PlaybackManager manager, double volume) async {
    final backend = manager.backend;
    if (backend == null) {
      return;
    }
    await backend.setVolume(volume.clamp(0, 100));
  }

  double _normalizeVolume(String raw) {
    final parsed = double.tryParse(raw) ?? 100;
    if (parsed <= 1) {
      return (parsed * 100).clamp(0, 100).toDouble();
    }
    return parsed.clamp(0, 100).toDouble();
  }

  Future<void> _setRepeatMode(PlaybackManager manager, String mode) async {
    final target = switch (mode) {
      'repeatall' => RepeatMode.repeatAll,
      'repeatone' => RepeatMode.repeatOne,
      _ => RepeatMode.none,
    };

    var attempts = 0;
    while (manager.state.repeatMode != target && attempts < 3) {
      manager.toggleRepeat();
      attempts++;
    }
  }

  Future<void> _setShuffleMode(PlaybackManager manager, String mode) async {
    final wantsShuffle = mode.toLowerCase() == 'shuffle';
    if (manager.state.isShuffled != wantsShuffle) {
      manager.toggleShuffle();
    }
  }

  Duration? _durationFromTicks(int? ticks) {
    if (ticks == null || ticks <= 0) {
      return null;
    }
    return Duration(microseconds: ticks ~/ 10);
  }

  Future<void> _handlePlayMessage(PlayMessage message) async {
    final serverId = _activeServerId;
    if (serverId == null || message.itemIds.isEmpty) {
      return;
    }

    final client = _clientFactory.getClientIfExists(serverId);
    if (client == null) {
      return;
    }

    final loaded = await Future.wait(
      message.itemIds.map((itemId) async {
        try {
          final itemData = await client.itemsApi.getItem(itemId);
          return AggregatedItem(
            id: itemId,
            serverId: serverId,
            rawData: itemData,
          );
        } catch (_) {
          return null;
        }
      }),
    );
    final items = loaded.whereType<AggregatedItem>().toList(growable: false);

    if (items.isEmpty) {
      return;
    }

    final manager = GetIt.instance<PlaybackManager>();
    await manager.playItems(
      items,
      startPosition: _durationFromTicks(message.startPositionTicks) ?? Duration.zero,
    );
  }

  Future<void> _handlePlaystateMessage(PlaystateMessage message) async {
    final manager = GetIt.instance<PlaybackManager>();
    switch (message.command.toLowerCase()) {
      case 'pause':
        await manager.pause();
      case 'unpause':
      case 'play':
        await manager.resume();
      case 'stop':
        await manager.stop();
      case 'seek':
        final seek = _durationFromTicks(message.seekPositionTicks);
        if (seek != null) {
          await manager.seekTo(seek);
        }
      case 'nexttrack':
        await manager.next();
      case 'previoustrack':
        await manager.previous();
      default:
        break;
    }
  }

  Future<void> _handleGeneralCommandMessage(GeneralCommandMessage message) async {
    final manager = GetIt.instance<PlaybackManager>();
    switch (message.name.toLowerCase()) {
      case 'displaymessage':
        final text = message.arguments['Text'];
        if (text != null && text.trim().isNotEmpty) {
          await GetIt.instance<DownloadNotificationService>().showRemoteMessage(
            text: text,
            header: message.arguments['Header'],
          );
        }
      case 'setvolume':
        final raw = message.arguments['Volume'];
        if (raw != null) {
          final volume = _normalizeVolume(raw);
          await _setLocalVolume(manager, volume);
          if (volume > 0) {
            _lastUnmutedVolume = volume;
            _remoteMuted = false;
          } else {
            _remoteMuted = true;
          }
        }
      case 'mute':
        if (!_remoteMuted) {
          _remoteMuted = true;
          await _setLocalVolume(manager, 0);
        }
      case 'unmute':
        _remoteMuted = false;
        await _setLocalVolume(manager, _lastUnmutedVolume);
      case 'togglemute':
        _remoteMuted = !_remoteMuted;
        await _setLocalVolume(manager, _remoteMuted ? 0 : _lastUnmutedVolume);
      case 'setaudiostreamindex':
        final index = _parseIntArg(message.arguments, 'Index');
        if (index != null) {
          await manager.changeAudioTrack(index);
        }
      case 'setsubtitlestreamindex':
        final index = _parseIntArg(message.arguments, 'Index');
        if (index == null) {
          return;
        }
        if (index < 0) {
          await manager.disableSubtitles();
          return;
        }
        await manager.changeSubtitleTrack(index);
      case 'setrepeatmode':
        final mode = message.arguments['RepeatMode'];
        if (mode != null) {
          await _setRepeatMode(manager, mode.toLowerCase());
        }
      case 'setshufflequeue':
        final mode = message.arguments['ShuffleMode'];
        if (mode != null) {
          await _setShuffleMode(manager, mode);
        }
      default:
        break;
    }
  }

  void dispose() {
    _remoteCommandSubscription?.cancel();
    _stateController.close();
  }
}
