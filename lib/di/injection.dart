import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';
import 'package:uuid/uuid.dart';

import 'modules/app_module.dart';
import 'modules/auth_module.dart';
import 'modules/server_module.dart';
import 'modules/playback_module.dart';
import 'modules/preference_module.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final preferenceStore = PreferenceStore();
  await preferenceStore.init();

  var deviceId = preferenceStore.getString('device_id');
  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await preferenceStore.setString('device_id', deviceId);
  }

  getIt.registerSingleton<DeviceInfo>(DeviceInfo(
    id: deviceId,
    name: 'Moonfin',
    appName: 'Moonfin',
    appVersion: '0.1.0',
  ));

  registerPreferenceModule(preferenceStore);

  registerServerModule();
  registerAuthModule();
  registerPlaybackModule();
  registerAppModule();
}
