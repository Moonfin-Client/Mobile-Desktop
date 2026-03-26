#ifndef FLUTTER_PLUGIN_ARCHIVE_EXTRACT_PLUGIN_H_
#define FLUTTER_PLUGIN_ARCHIVE_EXTRACT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace archive_extract {

class ArchiveExtractPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  ArchiveExtractPlugin();
  ~ArchiveExtractPlugin() override;

  ArchiveExtractPlugin(const ArchiveExtractPlugin&) = delete;
  ArchiveExtractPlugin& operator=(const ArchiveExtractPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace archive_extract

#endif  // FLUTTER_PLUGIN_ARCHIVE_EXTRACT_PLUGIN_H_
