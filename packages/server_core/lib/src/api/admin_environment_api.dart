abstract class AdminEnvironmentApi {
  Future<List<Map<String, dynamic>>> getDirectoryContents(
    String path, {
    bool? includeFiles,
    bool? includeDirectories,
  });
  Future<void> validatePath(String path);
  Future<List<Map<String, dynamic>>> getDrives();
  Future<String?> getParentPath(String path);
}
