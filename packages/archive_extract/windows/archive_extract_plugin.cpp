#include "archive_extract_plugin.h"

#include "../shared/libarchive_extract.h"

#include <flutter/encodable_value.h>
#include <flutter/standard_method_codec.h>

#include <cstdlib>
#include <memory>
#include <string>

namespace archive_extract {

void ArchiveExtractPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.moonfin.archive_extract",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ArchiveExtractPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](
          const flutter::MethodCall<flutter::EncodableValue>& call,
          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
              result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ArchiveExtractPlugin::ArchiveExtractPlugin() {}

ArchiveExtractPlugin::~ArchiveExtractPlugin() {}

void ArchiveExtractPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "extract7z") {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args == nullptr) {
      result->Error("INVALID_ARGS",
                    "archivePath and destinationPath are required");
      return;
    }

    auto archive_it = args->find(flutter::EncodableValue("archivePath"));
    auto destination_it =
        args->find(flutter::EncodableValue("destinationPath"));

    if (archive_it == args->end() || destination_it == args->end()) {
      result->Error("INVALID_ARGS",
                    "archivePath and destinationPath are required");
      return;
    }

    const auto* archive_path =
        std::get_if<std::string>(&archive_it->second);
    const auto* destination_path =
        std::get_if<std::string>(&destination_it->second);

    if (archive_path == nullptr || destination_path == nullptr) {
      result->Error("INVALID_ARGS",
                    "archivePath and destinationPath must be strings");
      return;
    }

    char** extracted_files = nullptr;
    int extracted_count = 0;
    char* c_error = nullptr;

    const int rc = extract_7z_archive(archive_path->c_str(),
                                      destination_path->c_str(),
                                      &extracted_files,
                                      &extracted_count,
                                      &c_error);

    if (rc != 0) {
      std::string message = "Extraction failed";
      if (c_error != nullptr) {
        message = c_error;
        free(c_error);
      }
      free_extracted_files(extracted_files, extracted_count);
      result->Error("EXTRACTION_FAILED", message);
      return;
    }

    flutter::EncodableList paths;
    paths.reserve(extracted_count);
    for (int i = 0; i < extracted_count; i++) {
      if (extracted_files[i] != nullptr) {
        paths.emplace_back(std::string(extracted_files[i]));
      }
    }

    free_extracted_files(extracted_files, extracted_count);
    result->Success(paths);
    return;
  }

  if (method_call.method_name() == "isSupported") {
    result->Success(flutter::EncodableValue(true));
    return;
  }

  result->NotImplemented();
}

}  // namespace archive_extract
