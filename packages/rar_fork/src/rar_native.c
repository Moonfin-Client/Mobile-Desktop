// src/rar_native.c
//
// Native C implementation for RAR archive handling.
// Uses libarchive for cross-platform RAR support.
//
// Library: libarchive (https://libarchive.org/)
// License: BSD 2-Clause
// RAR Support: libarchive includes unrar code for reading RAR archives
//
// This implementation is shared across Linux, macOS, and Windows.
// Each platform's build system compiles this file and links with libarchive.

#include "rar_native.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <errno.h>

// libarchive headers
#include <archive.h>
#include <archive_entry.h>

#ifdef _WIN32
#include <windows.h>
#include <direct.h>
#define mkdir(path, mode) _mkdir(path)
#define PATH_SEP '\\'
#else
#include <unistd.h>
#define PATH_SEP '/'
#endif

// Buffer size for extraction
#define BUFFER_SIZE 65536

// Error messages
static const char* error_messages[] = {
    "Success",
    "RAR file not found",
    "Failed to open RAR archive",
    "Failed to create output file",
    "Memory allocation error",
    "Corrupt or invalid RAR archive",
    "Unknown archive format (not a valid RAR file)",
    "Incorrect password or password required",
    "Data error in archive (CRC check failed)",
    "Unknown error"
};

// Get error message for code
RAR_EXPORT const char* rar_get_error_message(int error_code) {
    if (error_code < 0 || error_code > RAR_UNKNOWN_ERROR) {
        return error_messages[RAR_UNKNOWN_ERROR];
    }
    return error_messages[error_code];
}

// Helper: Create directory and parent directories
static int create_directory_recursive(const char* path) {
    char* path_copy = strdup(path);
    if (!path_copy) return -1;

    char* p = path_copy;

#ifdef _WIN32
    // Skip drive letter on Windows
    if (p[0] && p[1] == ':') {
        p += 2;
    }
#endif

    // Skip leading separator
    if (*p == PATH_SEP) p++;

    while (*p) {
        // Find next separator
        while (*p && *p != PATH_SEP && *p != '/') p++;

        if (*p) {
            char saved = *p;
            *p = '\0';

            // Create directory (ignore errors for existing directories)
            #ifdef _WIN32
            _mkdir(path_copy);
            #else
            mkdir(path_copy, 0755);
            #endif

            *p = saved;
            p++;
        }
    }

    // Create final directory
    #ifdef _WIN32
    int result = _mkdir(path_copy);
    #else
    int result = mkdir(path_copy, 0755);
    #endif

    free(path_copy);

    // Success if created or already exists
    return (result == 0 || errno == EEXIST) ? 0 : -1;
}

// Helper: Get parent directory of a path
static char* get_parent_directory(const char* path) {
    char* result = strdup(path);
    if (!result) return NULL;

    // Find last separator
    char* last_sep = strrchr(result, PATH_SEP);
    if (!last_sep) {
        last_sep = strrchr(result, '/');
    }

    if (last_sep && last_sep != result) {
        *last_sep = '\0';
    }

    return result;
}

// Helper: Copy archive data to file
static int copy_data(struct archive* ar, struct archive* aw) {
    const void* buff;
    size_t size;
    int64_t offset;
    int r;

    for (;;) {
        r = archive_read_data_block(ar, &buff, &size, &offset);
        if (r == ARCHIVE_EOF) return ARCHIVE_OK;
        if (r != ARCHIVE_OK) return r;

        r = archive_write_data_block(aw, buff, size, offset);
        if (r != ARCHIVE_OK) return r;
    }
}

// Helper: Map libarchive error to our error codes
static int map_archive_error(struct archive* a, rar_error_callback error_cb) {
    int err = archive_errno(a);
    const char* err_str = archive_error_string(a);

    if (error_cb && err_str) {
        error_cb(err_str);
    }

    // Map common errors
    if (err == ENOENT) return RAR_FILE_NOT_FOUND;
    if (err == ENOMEM) return RAR_MEMORY_ERROR;

    // Check error string for hints
    if (err_str) {
        if (strstr(err_str, "password") || strstr(err_str, "Password") ||
            strstr(err_str, "encrypted") || strstr(err_str, "Encrypted")) {
            return RAR_BAD_PASSWORD;
        }
        if (strstr(err_str, "corrupt") || strstr(err_str, "Corrupt") ||
            strstr(err_str, "invalid") || strstr(err_str, "Invalid")) {
            return RAR_BAD_ARCHIVE;
        }
        if (strstr(err_str, "CRC") || strstr(err_str, "checksum")) {
            return RAR_BAD_DATA;
        }
        if (strstr(err_str, "format") || strstr(err_str, "Format")) {
            return RAR_UNKNOWN_FORMAT;
        }
    }

    return RAR_UNKNOWN_ERROR;
}

// Extract RAR archive
RAR_EXPORT int rar_extract(
    const char* rar_path,
    const char* dest_path,
    const char* password,
    rar_error_callback error_cb
) {
    struct archive* a = NULL;
    struct archive* ext = NULL;
    struct archive_entry* entry;
    int r;
    int result = RAR_SUCCESS;

    // Check if file exists
    FILE* f = fopen(rar_path, "rb");
    if (!f) {
        if (error_cb) error_cb("RAR file not found");
        return RAR_FILE_NOT_FOUND;
    }
    fclose(f);

    // Create destination directory
    if (create_directory_recursive(dest_path) != 0) {
        if (error_cb) error_cb("Failed to create destination directory");
        return RAR_CREATE_ERROR;
    }

    // Create archive reader
    a = archive_read_new();
    if (!a) {
        if (error_cb) error_cb("Failed to create archive reader");
        return RAR_MEMORY_ERROR;
    }

    // Enable RAR format support
    archive_read_support_format_rar(a);
    archive_read_support_format_rar5(a);

    // Enable all filters/compressions
    archive_read_support_filter_all(a);

    // Set password if provided
    if (password && strlen(password) > 0) {
        archive_read_add_passphrase(a, password);
    }

    // Create disk writer
    ext = archive_write_disk_new();
    if (!ext) {
        archive_read_free(a);
        if (error_cb) error_cb("Failed to create disk writer");
        return RAR_MEMORY_ERROR;
    }

    // Set extraction options
    int flags = ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS;
    archive_write_disk_set_options(ext, flags);
    archive_write_disk_set_standard_lookup(ext);

    // Open archive
    r = archive_read_open_filename(a, rar_path, BUFFER_SIZE);
    if (r != ARCHIVE_OK) {
        result = map_archive_error(a, error_cb);
        archive_read_free(a);
        archive_write_free(ext);
        return result;
    }

    // Extract each entry
    while ((r = archive_read_next_header(a, &entry)) == ARCHIVE_OK) {
        // Build full output path
        const char* entry_path = archive_entry_pathname(entry);
        size_t full_path_len = strlen(dest_path) + strlen(entry_path) + 2;
        char* full_path = malloc(full_path_len);
        if (!full_path) {
            result = RAR_MEMORY_ERROR;
            if (error_cb) error_cb("Memory allocation failed");
            break;
        }
        snprintf(full_path, full_path_len, "%s%c%s", dest_path, PATH_SEP, entry_path);

        // Update entry pathname
        archive_entry_set_pathname(entry, full_path);

        // Create parent directory if needed
        char* parent = get_parent_directory(full_path);
        if (parent) {
            create_directory_recursive(parent);
            free(parent);
        }

        // Write header
        r = archive_write_header(ext, entry);
        if (r != ARCHIVE_OK) {
            result = map_archive_error(ext, error_cb);
            free(full_path);
            break;
        }

        // Copy data if it's a regular file
        if (archive_entry_size(entry) > 0) {
            r = copy_data(a, ext);
            if (r != ARCHIVE_OK) {
                result = map_archive_error(a, error_cb);
                free(full_path);
                break;
            }
        }

        // Finish entry
        r = archive_write_finish_entry(ext);
        if (r != ARCHIVE_OK) {
            result = map_archive_error(ext, error_cb);
            free(full_path);
            break;
        }

        free(full_path);
    }

    // Check for read errors
    if (r != ARCHIVE_EOF && result == RAR_SUCCESS) {
        result = map_archive_error(a, error_cb);
    }

    // Cleanup
    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);

    return result;
}

// List RAR archive contents
RAR_EXPORT int rar_list(
    const char* rar_path,
    const char* password,
    rar_list_callback list_cb,
    rar_error_callback error_cb
) {
    struct archive* a = NULL;
    struct archive_entry* entry;
    int r;
    int result = RAR_SUCCESS;

    // Check if file exists
    FILE* f = fopen(rar_path, "rb");
    if (!f) {
        if (error_cb) error_cb("RAR file not found");
        return RAR_FILE_NOT_FOUND;
    }
    fclose(f);

    // Create archive reader
    a = archive_read_new();
    if (!a) {
        if (error_cb) error_cb("Failed to create archive reader");
        return RAR_MEMORY_ERROR;
    }

    // Enable RAR format support
    archive_read_support_format_rar(a);
    archive_read_support_format_rar5(a);

    // Enable all filters
    archive_read_support_filter_all(a);

    // Set password if provided
    if (password && strlen(password) > 0) {
        archive_read_add_passphrase(a, password);
    }

    // Open archive
    r = archive_read_open_filename(a, rar_path, BUFFER_SIZE);
    if (r != ARCHIVE_OK) {
        result = map_archive_error(a, error_cb);
        archive_read_free(a);
        return result;
    }

    // List each entry
    while ((r = archive_read_next_header(a, &entry)) == ARCHIVE_OK) {
        const char* pathname = archive_entry_pathname(entry);
        if (pathname && list_cb) {
            list_cb(pathname);
        }

        // Skip data (we only need headers for listing)
        archive_read_data_skip(a);
    }

    // Check for read errors
    if (r != ARCHIVE_EOF) {
        result = map_archive_error(a, error_cb);
    }

    // Cleanup
    archive_read_close(a);
    archive_read_free(a);

    return result;
}
