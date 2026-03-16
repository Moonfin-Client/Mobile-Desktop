import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/repositories/session_repository.dart';
import '../../auth/store/authentication_store.dart';
import '../../auth/store/credential_store.dart';
import '../../data/repositories/mdblist_repository.dart';
import '../../data/repositories/multi_server_repository.dart';
import '../../data/repositories/media_bar_repository.dart';
import '../../data/services/media_server_client_factory.dart';
import '../../data/repositories/seerr_repository.dart';
import '../../data/repositories/tmdb_repository.dart';
import '../../data/repositories/user_views_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/repositories/item_mutation_repository.dart';
import '../../data/services/background_service.dart';
import '../../data/services/plugin_sync_service.dart';
import '../../data/services/row_data_source.dart';
import '../../data/services/seerr/seerr_cookie_jar.dart';
import '../../data/services/socket_handler.dart';
import '../../data/services/theme_music_service.dart';
import '../../data/viewmodels/media_bar_view_model.dart';
import '../../data/viewmodels/seerr_discover_view_model.dart';
import '../../preference/seerr_preferences.dart';
import '../../preference/user_preferences.dart';
import '../../ui/screens/home/home_view_model.dart';

final _getIt = GetIt.instance;

void resetUserScopedSingletons() {
  void unregister<T extends Object>() {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
  }

  unregister<SeerrDiscoverViewModel>();
  unregister<SeerrRepository>();
  unregister<HomeViewModel>();
  unregister<MediaBarViewModel>();
  unregister<MultiServerRepository>();
  unregister<ThemeMusicService>();
  unregister<MediaBarRepository>();
  unregister<TmdbRepository>();
  unregister<MdbListRepository>();
  unregister<RowDataSource>();
  unregister<ItemMutationRepository>();
  unregister<SearchRepository>();
  unregister<UserViewsRepository>();

  _registerUserScopedSingletons();
}

void registerAppModule() {
  _getIt.registerLazySingletonAsync(() async =>
      SeerrCookieJar(await SharedPreferences.getInstance()));
  _getIt.registerLazySingleton(() => SocketHandler());
  _getIt.registerLazySingleton(() => BackgroundService());
  _getIt.registerLazySingleton(() => PluginSyncService(
        _getIt<UserPreferences>(),
        _getIt(),
      ));
  _getIt.registerLazySingleton(() => SeerrPreferences(
        _getIt<PreferenceStore>(),
        _getIt<SessionRepository>(),
      ));

  _registerUserScopedSingletons();
}

void _registerUserScopedSingletons() {
  _getIt.registerLazySingleton(() => MultiServerRepository(
        _getIt<AuthenticationStore>(),
        _getIt<CredentialStore>(),
        _getIt<MediaServerClientFactory>(),
        _getIt<SessionRepository>(),
      ));
  _getIt.registerLazySingleton(() => UserViewsRepository(_getIt()));
  _getIt.registerLazySingleton(() => SearchRepository(_getIt()));
  _getIt.registerLazySingleton(() => ItemMutationRepository(_getIt()));
  _getIt.registerLazySingleton(() => RowDataSource(_getIt<MediaServerClient>()));
  _getIt.registerLazySingleton(() => MdbListRepository(_getIt<MediaServerClient>()));
  _getIt.registerLazySingleton(() => TmdbRepository(_getIt<MediaServerClient>()));
  _getIt.registerLazySingleton(() => MediaBarRepository(
        _getIt<MediaServerClient>(),
        _getIt<UserPreferences>(),
      ));
  _getIt.registerLazySingleton(() => MediaBarViewModel(
        _getIt<MediaBarRepository>(),
        _getIt<MdbListRepository>(),
        _getIt<UserPreferences>(),
        _getIt<MediaServerClient>(),
      ));
  _getIt.registerLazySingleton(() => HomeViewModel(
        dataSource: _getIt<RowDataSource>(),
        prefs: _getIt<UserPreferences>(),
        client: _getIt<MediaServerClient>(),
        mediaBarViewModel: _getIt<MediaBarViewModel>(),
        multiServerRepo: _getIt<MultiServerRepository>(),
      ));
  _getIt.registerLazySingleton(() => ThemeMusicService(
        _getIt<MediaServerClient>(),
        _getIt<UserPreferences>(),
      ));
  _getIt.registerLazySingletonAsync<SeerrRepository>(() async => SeerrRepository(
        _getIt<PreferenceStore>(),
        _getIt<SessionRepository>(),
        await _getIt.getAsync<SeerrCookieJar>(),
        _getIt<MediaServerClient>(),
      ));
  _getIt.registerLazySingletonAsync<SeerrDiscoverViewModel>(() async =>
      SeerrDiscoverViewModel(
        await _getIt.getAsync<SeerrRepository>(),
        _getIt<SeerrPreferences>(),
      ));
}
