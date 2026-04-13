class FileNode {
  const FileNode({required this.name, required this.path, required this.isDirectory, this.children});

  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode>? children;

  bool get isExpanded => children != null;
}

abstract interface class FilesystemDatasource {
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
