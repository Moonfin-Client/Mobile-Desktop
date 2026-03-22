import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:server_core/server_core.dart';

import '../models/server.dart';
import '../models/user.dart';
import '../store/authentication_store.dart';

class ServerUserRepository {
  final AuthenticationStore _authStore;
  final _logger = Logger();

  ServerUserRepository(this._authStore);

  List<PrivateUser> getStoredServerUsers(String serverId) {
    return _authStore.getUsers(serverId);
  }

  Future<List<PublicUser>> getPublicServerUsers(Server server) async {
    final dio = Dio(BaseOptions(
      baseUrl: server.address,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    configureServerDio(dio);

    try {
      final response = await dio.get('/Users/Public');
      final list = response.data as List<dynamic>;
      return list.map((json) {
        final map = json as Map<String, dynamic>;
        return PublicUser(
          id: map['Id'] as String,
          name: map['Name'] as String? ?? '',
          serverId: server.id,
          hasPassword: map['HasPassword'] as bool? ?? true,
          imageTag:
              (map['PrimaryImageTag'] as String?) ??
              ((map['ImageTags'] as Map<String, dynamic>?)?['Primary']
                  as String?),
        );
      }).toList();
    } catch (e) {
      _logger.e('Failed to fetch public users', error: e);
      return [];
    } finally {
      dio.close();
    }
  }

  Future<void> deleteStoredUser(String serverId, String userId) async {
    await _authStore.removeUser(serverId, userId);
  }
}
