import '../datasource/filesystem_datasource.dart';

export '../datasource/filesystem_datasource.dart' show FileNode;

abstract interface class FilesystemRepository {
  Future<List<FileNode>> listDirectory(String dirPath);
  Future<String> readFile(String filePath);
  Future<void> writeFile(String filePath, String content);
  Future<void> createFile(String filePath);
  Future<void> createDirectory(String dirPath);
  Future<void> deleteFile(String filePath);
  Future<void> renameFile(String oldPath, String newPath);
  // Yields dart:io FileSystemEvent — cast in consumers that need the concrete type.
  Stream<dynamic> watchDirectory(String dirPath);
  String detectLanguage(String filePath);
}
