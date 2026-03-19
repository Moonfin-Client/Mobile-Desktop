#ifndef LIBARCHIVE_EXTRACT_H
#define LIBARCHIVE_EXTRACT_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Extract an archive to a destination directory.
 *
 * @param archive_path      Path to the archive file (e.g. .7z, .cb7, .rar,
 *                          .cbr when supported by libarchive).
 * @param destination_path  Directory to extract into (created if absent).
 * @param files_out         On success, set to a malloc'd array of malloc'd
 *                          C-string paths. Caller must call
 *                          free_extracted_files() to release.
 * @param count_out         Number of entries written to files_out.
 * @param error_out         On failure, set to a malloc'd error message.
 *                          Caller must free().
 * @return 0 on success, non-zero on failure.
 */
int extract_7z_archive(const char *archive_path,
                       const char *destination_path,
                       char ***files_out,
                       int *count_out,
                       char **error_out);

/** Free the array returned by extract_7z_archive(). */
void free_extracted_files(char **files, int count);

#ifdef __cplusplus
}
#endif

#endif /* LIBARCHIVE_EXTRACT_H */
