/// Raw I/O facade for file apply operations.
/// Business logic (policy, validation, checksum, UUID) lives in ApplyService.
abstract interface class ApplyRepository {
  Future<String> readFile(String path);
  Future<void> writeFile(String path, String content);
  Future<void> deleteFile(String path);
  Future<void> gitCheckout(String filePath, String workingDirectory);
}
