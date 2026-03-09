import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../data/repositories/media_bar_repository.dart';
import '../../data/repositories/user_views_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/repositories/item_mutation_repository.dart';
import '../../data/services/background_service.dart';
import '../../data/services/row_data_source.dart';
import '../../data/services/socket_handler.dart';
import '../../data/viewmodels/media_bar_view_model.dart';
import '../../preference/user_preferences.dart';
import '../../ui/screens/home/home_view_model.dart';

final _getIt = GetIt.instance;

void registerAppModule() {
  _getIt.registerLazySingleton(() => UserViewsRepository(_getIt()));
  _getIt.registerLazySingleton(() => SearchRepository(_getIt()));
  _getIt.registerLazySingleton(() => ItemMutationRepository(_getIt()));
  _getIt.registerLazySingleton(() => SocketHandler());
  _getIt.registerLazySingleton(() => BackgroundService());
  _getIt.registerLazySingleton(() => RowDataSource(_getIt<MediaServerClient>()));
  _getIt.registerLazySingleton(() => MediaBarRepository(
        _getIt<MediaServerClient>(),
        _getIt<UserPreferences>(),
      ));
  _getIt.registerLazySingleton(() => MediaBarViewModel(_getIt<MediaBarRepository>()));
  _getIt.registerLazySingleton(() => HomeViewModel(
        dataSource: _getIt<RowDataSource>(),
        prefs: _getIt<UserPreferences>(),
        client: _getIt<MediaServerClient>(),
        mediaBarViewModel: _getIt<MediaBarViewModel>(),
      ));
}
