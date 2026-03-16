import 'dart:async';

import 'package:logger/logger.dart';
import 'package:server_core/server_core.dart';

import '../../auth/models/server.dart';
import '../../auth/repositories/session_repository.dart';
import '../../auth/store/authentication_store.dart';
import '../../auth/store/credential_store.dart';
import '../models/aggregated_item.dart';
import '../models/aggregated_library.dart';
import '../models/home_row.dart';
import '../services/media_server_client_factory.dart';

class ServerUserSession {
  final Server server;
  final String userId;
  final MediaServerClient client;

  const ServerUserSession({
    required this.server,
    required this.userId,
    required this.client,
  });
}

class MultiServerRepository {
  final AuthenticationStore _authStore;
  final CredentialStore _credentialStore;
  final MediaServerClientFactory _clientFactory;
  final SessionRepository _sessionRepo;
  final _logger = Logger();

  static const _sessionCacheDuration = Duration(seconds: 5);
  static const _serverTimeout = Duration(seconds: 8);
  static const _fields =
      'PrimaryImageAspectRatio,BasicSyncInfo,Overview,Genres,CommunityRating,'
      'CriticRating,OfficialRating,RunTimeTicks,ProductionYear,SeriesName,'
      'ParentIndexNumber,IndexNumber,Status,ImageTags,BackdropImageTags,'
      'ParentBackdropItemId,ParentBackdropImageTags,ProviderIds';
  static const _defaultLimit = 15;

  List<ServerUserSession>? _cachedSessions;
  DateTime _cacheExpiry = DateTime(0);

  MultiServerRepository(
    this._authStore,
    this._credentialStore,
    this._clientFactory,
    this._sessionRepo,
  );

  ImageApi getImageApiForServer(String serverId) {
    final client = _clientFactory.getClientIfExists(serverId);
    return client?.imageApi ?? _clientFactory.getActiveClient().imageApi;
  }

  Future<List<ServerUserSession>> getLoggedInServers() async {
    if (_cachedSessions != null && DateTime.now().isBefore(_cacheExpiry)) {
      return _cachedSessions!;
    }

    final servers = _authStore.getServers();
    final activeServerId = _sessionRepo.activeServerId;

    final sessions = <ServerUserSession>[];

    for (final server in servers) {
      try {
        final users = _authStore.getUsers(server.id);
        if (users.isEmpty) continue;

        String? userId;
        String? accessToken;

        if (server.id == activeServerId && _sessionRepo.activeUserId != null) {
          final activeUser = users.where((u) => u.id == _sessionRepo.activeUserId).firstOrNull;
          if (activeUser != null && activeUser.accessToken.isNotEmpty) {
            userId = activeUser.id;
            accessToken = activeUser.accessToken;
          }
        }

        if (userId == null) {
          final token = await _credentialStore.getToken(server.id);
          for (final user in users) {
            final userToken = token ?? user.accessToken;
            if (userToken.isNotEmpty) {
              userId = user.id;
              accessToken = userToken;
              break;
            }
          }
        }

        if (userId == null || accessToken == null || accessToken.isEmpty) continue;

        final client = _clientFactory.getClient(
          serverId: server.id,
          serverType: server.serverType,
          baseUrl: server.address,
        );
        client.accessToken = accessToken;
        client.userId = userId;

        sessions.add(ServerUserSession(
          server: server,
          userId: userId,
          client: client,
        ));
      } catch (e) {
        _logger.w('MultiServer: Error checking server ${server.name}: $e');
      }
    }

    _cachedSessions = sessions;
    _cacheExpiry = DateTime.now().add(_sessionCacheDuration);
    return sessions;
  }

  Future<List<AggregatedLibrary>> getAggregatedLibraries() async {
    final sessions = await getLoggedInServers();
    final hasMultiple = sessions.length > 1;

    final results = await Future.wait(
      sessions.map((session) => _withTimeout(() async {
        final response = await session.client.userViewsApi.getUserViews();
        final items = response['Items'] as List? ?? [];
        return items.map((item) {
          final data = item as Map<String, dynamic>;
          final name = data['Name'] as String? ?? '';
          return AggregatedLibrary(
            id: data['Id'] as String,
            name: hasMultiple ? '$name (${session.server.name})' : name,
            collectionType: data['CollectionType'] as String? ?? '',
            serverId: session.server.id,
          );
        }).toList();
      }, label: 'libraries from ${session.server.name}')),
    );

    return results.expand((e) => e).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<HomeRow> getAggregatedResume({int limit = _defaultLimit}) async {
    final sessions = await getLoggedInServers();
    final perServer = (limit * 3).clamp(1, 100);

    final results = await Future.wait(
      sessions.map((session) => _withTimeout(() async {
        final response = await session.client.itemsApi.getResumeItems(
          includeItemTypes: ['Movie', 'Episode'],
          limit: perServer,
          fields: _fields,
        );
        return _parseItems(response, session.server.id);
      }, label: 'resume from ${session.server.name}')),
    );

    final all = results.expand((e) => e).toList()..sort(_compareByLastPlayed);

    return HomeRow(
      id: 'resume',
      title: 'Continue Watching',
      items: all.take(limit).toList(),
      rowType: HomeRowType.resume,
    );
  }

  Future<HomeRow> getAggregatedResumeAudio({int limit = _defaultLimit}) async {
    final sessions = await getLoggedInServers();
    final perServer = (limit * 3).clamp(1, 100);

    final results = await Future.wait(
      sessions.map((session) => _withTimeout(() async {
        final response = await session.client.itemsApi.getResumeItems(
          includeItemTypes: ['Audio'],
          limit: perServer,
          fields: _fields,
        );
        return _parseItems(response, session.server.id);
      }, label: 'resume audio from ${session.server.name}')),
    );

    final all = results.expand((e) => e).toList()..sort(_compareByLastPlayed);

    return HomeRow(
      id: 'resumeAudio',
      title: 'Continue Listening',
      items: all.take(limit).toList(),
      rowType: HomeRowType.resumeAudio,
    );
  }

  Future<HomeRow> getAggregatedNextUp({int limit = _defaultLimit}) async {
    final sessions = await getLoggedInServers();
    final perServer = (limit * 3).clamp(1, 100);

    final results = await Future.wait(
      sessions.map((session) => _withTimeout(() async {
        final response = await session.client.itemsApi.getNextUp(
          limit: perServer,
          fields: _fields,
          enableResumable: false,
        );
        return _parseItems(response, session.server.id);
      }, label: 'next up from ${session.server.name}')),
    );

    final all = results.expand((e) => e).toList()..sort(_compareByLastPlayed);

    return HomeRow(
      id: 'nextUp',
      title: 'Next Up',
      items: all.take(limit).toList(),
      rowType: HomeRowType.nextUp,
    );
  }

  Future<HomeRow> getAggregatedPlaylists({int limit = _defaultLimit}) async {
    final sessions = await getLoggedInServers();

    final results = await Future.wait(
      sessions.map((session) => _withTimeout(() async {
        final response = await session.client.itemsApi.getItems(
          includeItemTypes: ['Playlist'],
          sortBy: 'SortName',
          sortOrder: 'Ascending',
          recursive: true,
          limit: limit,
          fields: _fields,
        );
        return _parseItems(response, session.server.id);
      }, label: 'playlists from ${session.server.name}')),
    );

    final all = results.expand((e) => e).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return HomeRow(
      id: 'playlists',
      title: 'Playlists',
      items: all.take(limit).toList(),
      rowType: HomeRowType.playlists,
    );
  }

  Future<HomeRow> getAggregatedLibraryTiles({
    HomeRowType rowType = HomeRowType.libraryTiles,
  }) async {
    final libraries = await getAggregatedLibraries();
    final items = libraries.map((lib) => AggregatedItem(
      id: lib.id,
      serverId: lib.serverId,
      rawData: {
        'Id': lib.id,
        'Name': lib.name,
        'CollectionType': lib.collectionType,
        'Type': 'CollectionFolder',
      },
    )).toList();

    return HomeRow(
      id: rowType == HomeRowType.libraryTilesSmall ? 'libraryTilesSmall' : 'libraryTiles',
      title: 'My Media',
      items: items,
      rowType: rowType,
    );
  }

  Future<List<HomeRow>> getAggregatedLatestMediaRows() async {
    final sessions = await getLoggedInServers();
    final hasMultiple = sessions.length > 1;
    final rows = <HomeRow>[];

    for (final session in sessions) {
      try {
        final viewsResponse = await _withTimeout(
          () => session.client.userViewsApi.getUserViews(),
          label: 'views from ${session.server.name}',
        );
        final views = viewsResponse['Items'] as List? ?? [];

        Set<String> latestExcludes = const {};
        try {
          final config = await session.client.usersApi.getUserConfiguration();
          latestExcludes = config.latestItemsExcludes.toSet();
        } catch (_) {}

        for (final view in views) {
          final data = view as Map<String, dynamic>;
          final id = data['Id'] as String;
          final collectionType = data['CollectionType'] as String?;
          if (collectionType == 'music' ||
              collectionType == 'books' ||
              collectionType == 'playlists' ||
              collectionType == 'boxsets' ||
              collectionType == 'livetv') {
            continue;
          }
          if (latestExcludes.contains(id)) continue;

          final name = data['Name'] as String? ?? '';
          final displayName = hasMultiple ? '$name (${session.server.name})' : name;

          try {
            final latestResponse = await _withTimeout(
              () => session.client.itemsApi.getLatestItems(
                parentId: id,
                limit: _defaultLimit,
                fields: _fields,
              ),
              label: 'latest $name from ${session.server.name}',
            );

            final items = _parseItems(latestResponse, session.server.id);
            if (items.isNotEmpty) {
              rows.add(HomeRow(
                id: 'latest_${session.server.id}_$id',
                title: 'Latest $displayName',
                items: items,
                rowType: HomeRowType.latestMedia,
              ));
            }
          } catch (e) {
            _logger.w('MultiServer: Failed to load latest for $name: $e');
          }
        }
      } catch (e) {
        _logger.w('MultiServer: Failed to load views from ${session.server.name}: $e');
      }
    }

    return rows;
  }

  Future<T> _withTimeout<T>(
    Future<T> Function() fn, {
    required String label,
  }) async {
    try {
      return await fn().timeout(_serverTimeout);
    } on TimeoutException {
      _logger.w('MultiServer: Timeout $label');
      rethrow;
    }
  }

  List<AggregatedItem> _parseItems(
    Map<String, dynamic> response,
    String serverId,
  ) {
    final rawItems = response['Items'] as List? ?? [];
    return rawItems.map((item) {
      final data = item as Map<String, dynamic>;
      return AggregatedItem(
        id: data['Id'] as String,
        serverId: serverId,
        rawData: data,
      );
    }).toList();
  }

  static int _compareByLastPlayed(AggregatedItem a, AggregatedItem b) {
    final aDate = a.rawData['UserData']?['LastPlayedDate'] as String? ?? '';
    final bDate = b.rawData['UserData']?['LastPlayedDate'] as String? ?? '';
    return bDate.compareTo(aDate);
  }
}
