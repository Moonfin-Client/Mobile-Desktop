#include "libarchive_extract.h"

#include <archive.h>
#include <archive_entry.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <direct.h>
#define MKDIR(path) _mkdir(path)
#define strdup _strdup
#else
#include <sys/stat.h>
#define MKDIR(path) mkdir(path, 0755)
#endif

static int is_path_safe(const char *name) {
    if (!name || name[0] == '\0' || name[0] == '/' || name[0] == '\\') return 0;
    if (((name[0] >= 'A' && name[0] <= 'Z') || (name[0] >= 'a' && name[0] <= 'z')) &&
        name[1] == ':') {
        return 0;
    }
    const char *p = name;
    while (*p) {
        if (p[0] == '.' && p[1] == '.') {
            if ((p == name || p[-1] == '/' || p[-1] == '\\') &&
                (p[2] == '/' || p[2] == '\\' || p[2] == '\0'))
                return 0;
        }
        p++;
    }
    return 1;
}

static void mkdirs(const char *path) {
    char *tmp = strdup(path);
    if (!tmp) return;
    for (char *p = tmp + 1; *p; p++) {
        if (*p == '/' || *p == '\\') {
            const char sep = *p;
            *p = '\0';
            MKDIR(tmp);
            *p = sep;
        }
    }
    MKDIR(tmp);
    free(tmp);
}

static char *path_join(const char *dir, const char *name) {
#ifdef _WIN32
    const char sep = '\\';
#else
    const char sep = '/';
#endif
    size_t len = strlen(dir) + 1 + strlen(name) + 1;
    char *buf = (char *)malloc(len);
    if (buf) snprintf(buf, len, "%s%c%s", dir, sep, name);
    return buf;
}

static char *parent_dir(const char *path) {
    char *dup = strdup(path);
    if (!dup) return NULL;
    char *slash = strrchr(dup, '/');
    char *backslash = strrchr(dup, '\\');
    if (!slash || (backslash && backslash > slash)) {
        slash = backslash;
    }
    if (slash) *slash = '\0';
    else { free(dup); return NULL; }
    return dup;
}

int extract_7z_archive(const char *archive_path,
                       const char *destination_path,
                       char ***files_out,
                       int *count_out,
                       char **error_out) {
    *files_out  = NULL;
    *count_out  = 0;
    *error_out  = NULL;

    struct archive *a = archive_read_new();
    if (!a) {
        *error_out = strdup("archive_read_new() failed");
        return -1;
    }

    archive_read_support_format_all(a);
    archive_read_support_filter_all(a);

    if (archive_read_open_filename(a, archive_path, 10240) != ARCHIVE_OK) {
        const char *e = archive_error_string(a);
        *error_out = strdup(e ? e : "Failed to open archive");
        archive_read_free(a);
        return -1;
    }

    int capacity = 64;
    int count    = 0;
    char **files = (char **)malloc((size_t)capacity * sizeof(char *));
    if (!files) {
        *error_out = strdup("Out of memory");
        archive_read_free(a);
        return -1;
    }

    struct archive_entry *entry;

    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        if (archive_entry_filetype(entry) != AE_IFREG) {
            archive_read_data_skip(a);
            continue;
        }

        const char *name = archive_entry_pathname(entry);
        if (!is_path_safe(name)) {
            archive_read_data_skip(a);
            continue;
        }

        char *out_path = path_join(destination_path, name);
        if (!out_path) {
            archive_read_data_skip(a);
            continue;
        }

        char *pdir = parent_dir(out_path);
        if (pdir) { mkdirs(pdir); free(pdir); }

        FILE *f = fopen(out_path, "wb");
        if (!f) {
            free(out_path);
            archive_read_data_skip(a);
            continue;
        }

        const void *buf;
        size_t      size;
        la_int64_t  offset;
        while (archive_read_data_block(a, &buf, &size, &offset) == ARCHIVE_OK) {
            if (buf && size > 0) fwrite(buf, 1, size, f);
        }
        fclose(f);

        if (count >= capacity) {
            capacity *= 2;
            char **tmp = (char **)realloc(files, (size_t)capacity * sizeof(char *));
            if (!tmp) { free(out_path); continue; }
            files = tmp;
        }
        files[count++] = out_path;
    }

    archive_read_free(a);
    *files_out = files;
    *count_out = count;
    return 0;
}

void free_extracted_files(char **files, int count) {
    if (!files) return;
    for (int i = 0; i < count; i++) free(files[i]);
    free(files);
}
