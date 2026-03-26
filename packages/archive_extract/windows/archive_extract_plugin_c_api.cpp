#include "include/archive_extract/archive_extract_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "archive_extract_plugin.h"

void ArchiveExtractPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  archive_extract::ArchiveExtractPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
