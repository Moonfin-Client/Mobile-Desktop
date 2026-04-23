#include "rar_plugin.h"

#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "rar_native.h"

namespace rar {

// static
void RarPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.lkrjangid.rar",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<RarPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

RarPlugin::RarPlugin() {}
RarPlugin::~RarPlugin() {}

void RarPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  const auto &method = method_call.method_name();

  if (method == "extractRarFile") {
    const auto *args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Expected map arguments");
      return;
    }

    auto get_string = [&](const std::string &key) -> std::string {
      auto it = args->find(flutter::EncodableValue(key));
      if (it == args->end()) return {};
      const auto *val = std::get_if<std::string>(&it->second);
      return val ? *val : std::string{};
    };

    std::string rar_path = get_string("rarFilePath");
    std::string dest_path = get_string("destinationPath");
    std::string password = get_string("password");

    if (rar_path.empty() || dest_path.empty()) {
      result->Error("INVALID_ARGS", "rarFilePath and destinationPath required");
      return;
    }

    int rc = rar_extract(
        rar_path.c_str(),
        dest_path.c_str(),
        password.empty() ? nullptr : password.c_str(),
        nullptr);

    flutter::EncodableMap response;
    if (rc == RAR_SUCCESS) {
      response[flutter::EncodableValue("success")] =
          flutter::EncodableValue(true);
      response[flutter::EncodableValue("message")] =
          flutter::EncodableValue(std::string("Extraction completed successfully"));
    } else {
      const char* emsg = rar_get_error_message(rc);
      std::string msg = emsg ? emsg : "Unknown error";
      response[flutter::EncodableValue("success")] =
          flutter::EncodableValue(false);
      response[flutter::EncodableValue("message")] =
          flutter::EncodableValue(msg);
    }
    result->Success(flutter::EncodableValue(response));

  } else if (method == "listRarContents") {
    const auto *args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Expected map arguments");
      return;
    }

    auto get_string = [&](const std::string &key) -> std::string {
      auto it = args->find(flutter::EncodableValue(key));
      if (it == args->end()) return {};
      const auto *val = std::get_if<std::string>(&it->second);
      return val ? *val : std::string{};
    };

    std::string rar_path = get_string("rarFilePath");
    std::string password = get_string("password");

    if (rar_path.empty()) {
      result->Error("INVALID_ARGS", "rarFilePath required");
      return;
    }

    flutter::EncodableList files;

    // rar_list uses a simple callback signature with no user-data pointer.
    // This implementation assumes rar_list invokes callbacks synchronously on
    // the calling thread. If callbacks may occur on other threads, the native API
    // should be extended to accept a user-data pointer and this trampoline
    // replaced with a context-based callback.
    files.clear();
    static thread_local flutter::EncodableList *tl_files = nullptr;
    tl_files = &files;
    int rc = rar_list(
        rar_path.c_str(),
        password.empty() ? nullptr : password.c_str(),
        [](const char *name) {
          if (tl_files && name)
            tl_files->push_back(flutter::EncodableValue(std::string(name)));
        },
        nullptr);

    flutter::EncodableMap response;
    if (rc == RAR_SUCCESS) {
      response[flutter::EncodableValue("success")] =
          flutter::EncodableValue(true);
      response[flutter::EncodableValue("message")] =
          flutter::EncodableValue(std::string("Successfully listed RAR contents"));
      response[flutter::EncodableValue("files")] =
          flutter::EncodableValue(files);
    } else {
      response[flutter::EncodableValue("success")] =
          flutter::EncodableValue(false);
      response[flutter::EncodableValue("message")] =
          flutter::EncodableValue(std::string(rar_get_error_message(rc)));
      response[flutter::EncodableValue("files")] =
          flutter::EncodableValue(flutter::EncodableList{});
    }
    result->Success(flutter::EncodableValue(response));

  } else if (method == "createRarArchive") {
    flutter::EncodableMap response;
    response[flutter::EncodableValue("success")] =
        flutter::EncodableValue(false);
    response[flutter::EncodableValue("message")] =
        flutter::EncodableValue(std::string(
            "RAR creation is not supported. Consider using ZIP format instead."));
    result->Success(flutter::EncodableValue(response));

  } else {
    result->NotImplemented();
  }
}

}  // namespace rar
