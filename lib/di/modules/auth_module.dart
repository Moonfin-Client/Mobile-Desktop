import 'package:get_it/get_it.dart';

import '../../auth/repositories/auth_repository.dart';
import '../../auth/repositories/server_repository.dart';
import '../../auth/repositories/server_user_repository.dart';
import '../../auth/repositories/session_repository.dart';
import '../../auth/repositories/user_repository.dart';
import '../../auth/store/authentication_preferences.dart';
import '../../auth/store/authentication_store.dart';
import '../../auth/store/credential_store.dart';
import '../../data/services/plugin_sync_service.dart';

final _getIt = GetIt.instance;

void registerAuthModule() {
  _getIt.registerLazySingleton(() => CredentialStore());
  _getIt.registerLazySingleton(() => AuthenticationStore());
  _getIt.registerLazySingleton(() => AuthenticationPreferences(_getIt()));
  _getIt.registerLazySingleton(() => UserRepository());
  _getIt.registerLazySingleton(
    () => ServerRepository(_getIt(), _getIt()),
  );
  _getIt.registerLazySingleton(
    () => ServerUserRepository(_getIt()),
  );
  _getIt.registerLazySingleton(
    () => SessionRepository(
      _getIt(),
      _getIt(),
      _getIt(),
      _getIt(),
      _getIt(),
      _getIt(),
      _getIt(),
      _getIt<PluginSyncService>(),
    ),
  );
  _getIt.registerLazySingleton(
    () => AuthRepository(_getIt(), _getIt(), _getIt(), _getIt()),
  );
}
