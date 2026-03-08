import 'package:get_it/get_it.dart';

import '../../data/repositories/user_views_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/repositories/item_mutation_repository.dart';
import '../../data/services/socket_handler.dart';

final _getIt = GetIt.instance;

void registerAppModule() {
  _getIt.registerLazySingleton(() => UserViewsRepository(_getIt()));
  _getIt.registerLazySingleton(() => SearchRepository(_getIt()));
  _getIt.registerLazySingleton(() => ItemMutationRepository(_getIt()));
  _getIt.registerLazySingleton(() => SocketHandler());
}
