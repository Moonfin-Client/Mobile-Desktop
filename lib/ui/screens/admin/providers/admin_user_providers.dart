import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

final adminUsersListProvider = FutureProvider<List<ServerUser>>((ref) async {
  final client = GetIt.instance<MediaServerClient>();
  return client.adminUsersApi.getUsers();
});

final adminUserProvider =
    FutureProvider.family<ServerUser, String>((ref, userId) async {
  final client = GetIt.instance<MediaServerClient>();
  return client.adminUsersApi.getUserById(userId);
});

final adminLibrariesProvider =
    FutureProvider<List<VirtualFolderInfo>>((ref) async {
  final client = GetIt.instance<MediaServerClient>();
  return client.adminLibraryApi.getVirtualFolders();
});
