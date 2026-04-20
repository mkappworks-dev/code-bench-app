import 'dart:io';

/// Domain API for coding-tool filesystem reads/listings. Writes go through
/// [ApplyService.applyChange] instead (see `write_file` / `str_replace`
/// handlers in CodingToolsService).
abstract interface class CodingToolsRepository {
  Future<String> readTextFile(String path);
  Future<int> fileSizeBytes(String path);
  Future<bool> fileExists(String path);
  Future<bool> directoryExists(String path);
  Future<List<FileSystemEntity>> listDirectory(String path, {required bool recursive});
}
