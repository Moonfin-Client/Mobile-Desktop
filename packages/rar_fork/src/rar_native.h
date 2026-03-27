// src/rar_native.h
//
// Common C API header for the RAR native library.
// This header defines the FFI interface used by all desktop platforms.
//
// Native Implementation: Uses libarchive for RAR extraction/listing
// License: libarchive is BSD licensed, UnRAR code within is free for decompression
//
// The same API is implemented by each platform's native code:
// - Linux: rar_native.c compiled with CMake
// - macOS: rar_native.c compiled with CMake/CocoaPods
// - Windows: rar_native.c compiled with CMake/Visual Studio

#ifndef RAR_NATIVE_H
#define RAR_NATIVE_H

#include <stdint.h>

#ifdef _WIN32
#  ifdef RAR_NATIVE_EXPORTS
#    define RAR_EXPORT __declspec(dllexport)
#  else
#    define RAR_EXPORT __declspec(dllimport)
#  endif
#else
#  define RAR_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Error codes
#define RAR_SUCCESS          0
#define RAR_FILE_NOT_FOUND   1
#define RAR_OPEN_ERROR       2
#define RAR_CREATE_ERROR     3
#define RAR_MEMORY_ERROR     4
#define RAR_BAD_ARCHIVE      5
#define RAR_UNKNOWN_FORMAT   6
#define RAR_BAD_PASSWORD     7
#define RAR_BAD_DATA         8
#define RAR_UNKNOWN_ERROR    9

// Callback types
typedef void (*rar_list_callback)(const char* filename);
typedef void (*rar_error_callback)(const char* error);

/**
 * Extract all files from a RAR archive to a destination directory.
 *
 * @param rar_path Path to the RAR archive file (UTF-8 encoded)
 * @param dest_path Path to the destination directory (UTF-8 encoded)
 * @param password Optional password for encrypted archives (UTF-8, NULL if none)
 * @param error_cb Callback for error messages (can be NULL)
 * @return RAR_SUCCESS on success, error code on failure
 */
RAR_EXPORT int rar_extract(
    const char* rar_path,
    const char* dest_path,
    const char* password,
    rar_error_callback error_cb
);

/**
 * List all files in a RAR archive.
 *
 * @param rar_path Path to the RAR archive file (UTF-8 encoded)
 * @param password Optional password for encrypted archives (UTF-8, NULL if none)
 * @param list_cb Callback called for each file in the archive
 * @param error_cb Callback for error messages (can be NULL)
 * @return RAR_SUCCESS on success, error code on failure
 */
RAR_EXPORT int rar_list(
    const char* rar_path,
    const char* password,
    rar_list_callback list_cb,
    rar_error_callback error_cb
);

/**
 * Get a human-readable error message for an error code.
 *
 * @param error_code The error code returned by rar_extract or rar_list
 * @return A static string describing the error (do not free)
 */
RAR_EXPORT const char* rar_get_error_message(int error_code);

#ifdef __cplusplus
}
#endif

#endif // RAR_NATIVE_H
