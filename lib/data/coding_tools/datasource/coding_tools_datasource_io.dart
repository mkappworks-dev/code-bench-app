import 'dart:io';
import 'dart:typed_data';

import '../coding_tools_exceptions.dart';
import '../models/directory_entry.dart';

/// Raw filesystem I/O for the coding tools. Translates dart:io exceptions into
/// [CodingToolsNotFoundException] / [CodingToolsDiskException] so callers above
/// the datasource layer need no dart:io import. No path guards — callers
/// (`CodingToolsRepository` + `ApplyRepository.assertWithinProject`) own that.
class CodingToolsDatasourceIo {
  Future<Uint8List> readFileBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } on PathNotFoundException {
      throw CodingToolsNotFoundException(path);
    } on FileSystemException catch (e) {
      throw CodingToolsDiskException(e.message);
    }
  }

  Future<int> fileSizeBytes(String path) async {
    try {
      return await File(path).length();
    } on PathNotFoundException {
      throw CodingToolsNotFoundException(path);
    } on FileSystemException catch (e) {
      throw CodingToolsDiskException(e.message);
    }
  }

  Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } on FileSystemException catch (e) {
      throw CodingToolsDiskException(e.message);
    }
  }

  Future<bool> directoryExists(String path) async {
    try {
      return await Directory(path).exists();
    } on FileSystemException catch (e) {
      throw CodingToolsDiskException(e.message);
    }
  }

  /// Lists directory entries. When [recursive] is true, walks all subdirs
  /// without depth limit — the caller (service) is responsible for capping.
  Future<List<DirectoryEntry>> listDirectoryEntries(String path, {required bool recursive}) async {
    try {
      final entities = await Directory(path).list(recursive: recursive, followLinks: false).toList();
      return entities.map((e) {
        final String entityType;
        if (e is Directory) {
          entityType = 'directory';
        } else if (e is Link) {
          entityType = 'link';
        } else {
          entityType = 'file';
        }
        return (path: e.path, entityType: entityType);
      }).toList();
    } on FileSystemException catch (e) {
      throw CodingToolsDiskException(e.message);
    }
  }
}
