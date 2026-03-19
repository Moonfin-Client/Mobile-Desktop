#include "include/archive_extract/archive_extract_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include "../shared/libarchive_extract.h"

#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

typedef struct _ArchiveExtractPlugin ArchiveExtractPlugin;
typedef struct _ArchiveExtractPluginClass ArchiveExtractPluginClass;

struct _ArchiveExtractPlugin {
  GObject parent_instance;
};

struct _ArchiveExtractPluginClass {
  GObjectClass parent_class;
};

typedef struct {
  FlMethodCall* method_call;
  gchar* archive_path;
  gchar* dest_path;
  gchar* error;
  std::vector<std::string> extracted_paths;
} Extract7zTaskData;

static void extract_7z_task_data_free(Extract7zTaskData* data) {
  if (!data) {
    return;
  }

  if (data->method_call != nullptr) {
    g_object_unref(data->method_call);
  }
  g_free(data->archive_path);
  g_free(data->dest_path);
  g_free(data->error);
  delete data;
}

static void extract_7z_task(GTask* task,
                            gpointer source_object,
                            gpointer task_data,
                            GCancellable* cancellable) {
  (void)source_object;
  (void)cancellable;
  Extract7zTaskData* data = static_cast<Extract7zTaskData*>(task_data);
  char** extracted_files = nullptr;
  int extracted_count = 0;
  char* c_error = nullptr;

  const int rc = extract_7z_archive(data->archive_path, data->dest_path,
                                    &extracted_files, &extracted_count,
                                    &c_error);

  if (rc == 0) {
    for (int i = 0; i < extracted_count; i++) {
      if (extracted_files[i] != nullptr) {
        data->extracted_paths.emplace_back(extracted_files[i]);
      }
    }
  } else {
    if (c_error != nullptr) {
      data->error = g_strdup(c_error);
      free(c_error);
    } else {
      data->error = g_strdup("Extraction failed");
    }
  }

  free_extracted_files(extracted_files, extracted_count);

  const bool success = rc == 0;
  g_task_return_boolean(task, success);
}

static void extract_7z_task_complete(GObject* source_object,
                                     GAsyncResult* res,
                                     gpointer user_data) {
  (void)source_object;
  GTask* task = G_TASK(res);
  Extract7zTaskData* data = static_cast<Extract7zTaskData*>(user_data);
  const gboolean success = g_task_propagate_boolean(task, nullptr);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (success) {
    g_autoptr(FlValue) list = fl_value_new_list();
    for (const auto& path : data->extracted_paths) {
      fl_value_append_take(list, fl_value_new_string(path.c_str()));
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(list));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "EXTRACTION_FAILED",
        data->error != nullptr ? data->error : "Extraction failed", nullptr));
  }

  fl_method_call_respond(data->method_call, response, nullptr);
}

G_DEFINE_TYPE(ArchiveExtractPlugin, archive_extract_plugin, g_object_get_type())

static void archive_extract_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(archive_extract_plugin_parent_class)->dispose(object);
}

static void archive_extract_plugin_class_init(
    ArchiveExtractPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = archive_extract_plugin_dispose;
}

static void archive_extract_plugin_init(ArchiveExtractPlugin* self) {
  (void)self;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  (void)channel;
  (void)user_data;
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "extract7z") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    FlValue* archive_val =
        fl_value_lookup_string(args, "archivePath");
    FlValue* dest_val =
        fl_value_lookup_string(args, "destinationPath");

    if (!archive_val || !dest_val) {
      g_autoptr(FlMethodResponse) resp = FL_METHOD_RESPONSE(
          fl_method_error_response_new(
              "INVALID_ARGS",
              "archivePath and destinationPath are required", nullptr));
      fl_method_call_respond(method_call, resp, nullptr);
      return;
    }

    const gchar* archive_path = fl_value_get_string(archive_val);
    const gchar* dest_path = fl_value_get_string(dest_val);

    auto* task_data = new Extract7zTaskData();
    task_data->method_call = FL_METHOD_CALL(g_object_ref(method_call));
    task_data->archive_path = g_strdup(archive_path);
    task_data->dest_path = g_strdup(dest_path);
    task_data->error = nullptr;

    g_autoptr(GTask) task = g_task_new(nullptr, nullptr, extract_7z_task_complete, task_data);
    g_task_set_task_data(task, task_data, reinterpret_cast<GDestroyNotify>(extract_7z_task_data_free));
    g_task_run_in_thread(task, extract_7z_task);
  } else if (strcmp(method, "isSupported") == 0) {
    g_autoptr(FlValue) val = fl_value_new_bool(TRUE);
    g_autoptr(FlMethodResponse) resp =
        FL_METHOD_RESPONSE(fl_method_success_response_new(val));
    fl_method_call_respond(method_call, resp, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

void archive_extract_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.moonfin.archive_extract", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, nullptr, nullptr);
}
