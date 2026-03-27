#include "include/rar/rar_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "rar_plugin.h"

void RarPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  rar::RarPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
