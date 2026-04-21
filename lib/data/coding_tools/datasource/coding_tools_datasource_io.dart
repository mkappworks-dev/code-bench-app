import 'dart:io';
import 'dart:typed_data';

/// Raw filesystem I/O for the coding tools. No path guards — callers
/// (`CodingToolsRepository` + `ApplyRepository.assertWithinProject`) own that.
class CodingToolsDatasourceIo {
  Future<Uint8List> readFileBytes(String path) => File(path).readAsBytes();
  Future<int> fileSizeBytes(String path) => File(path).length();
  Future<bool> fileExists(String path) => File(path).exists();
  Future<bool> directoryExists(String path) => Directory(path).exists();

  /// Lists directory entries. When [recursive] is true, walks all subdirs
  /// without depth limit — the caller (service) is responsible for capping.
  Future<List<FileSystemEntity>> listDirectoryEntries(String path, {required bool recursive}) {
    return Directory(path).list(recursive: recursive, followLinks: false).toList();
  }
}
