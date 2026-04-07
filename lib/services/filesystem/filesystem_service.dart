import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart' as app_errors;

part 'filesystem_service.g.dart';

@Riverpod(keepAlive: true)
FilesystemService filesystemService(Ref ref) => FilesystemService();

class FileNode {
  const FileNode({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.children,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final List<FileNode>? children;

  bool get isExpanded => children != null;
}

class FilesystemService {
  Future<List<FileNode>> listDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      final entries = await dir.list().toList();
      final nodes = entries.map((e) {
        final name = p.basename(e.path);
        final isDir = e is Directory;
        return FileNode(path: e.path, name: name, isDirectory: isDir);
      }).toList();

      // Sort: directories first, then files, both alphabetically
      nodes.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      // Filter hidden files (starting with .)
      return nodes.where((n) => !n.name.startsWith('.')).toList();
    } catch (e) {
      throw app_errors.FileSystemException(
        'Failed to list directory: $dirPath',
        path: dirPath,
        originalError: e,
      );
    }
  }

  Future<String> readFile(String filePath) async {
    try {
      return await File(filePath).readAsString();
    } catch (e) {
      throw app_errors.FileSystemException(
        'Failed to read file: $filePath',
        path: filePath,
        originalError: e,
      );
    }
  }

  Future<void> writeFile(String filePath, String content) async {
    try {
      await File(filePath).writeAsString(content);
    } catch (e) {
      throw app_errors.FileSystemException(
        'Failed to write file: $filePath',
        path: filePath,
        originalError: e,
      );
    }
  }

  Future<void> createFile(String filePath) async {
    try {
      await File(filePath).create(recursive: true);
    } catch (e) {
      throw app_errors.FileSystemException(
        'Failed to create file: $filePath',
        path: filePath,
        originalError: e,
      );
    }
  }

  Future<void> createDirectory(String dirPath) async {
    try {
      await Directory(dirPath).create(recursive: true);
    } catch (e) {
      throw app_errors.FileSystemException(
        'Failed to create directory: $dirPath',
        path: dirPath,
        originalError: e,
      );
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      await File(filePath).delete();
    } catch (e) {
      throw app_errors.FileSystemException(
        'Failed to delete: $filePath',
        path: filePath,
        originalError: e,
      );
    }
  }

  Future<void> renameFile(String oldPath, String newPath) async {
    try {
      await File(oldPath).rename(newPath);
    } catch (e) {
      throw app_errors.FileSystemException(
        'Failed to rename: $oldPath',
        path: oldPath,
        originalError: e,
      );
    }
  }

  Stream<FileSystemEvent> watchDirectory(String dirPath) {
    return Directory(dirPath).watch(recursive: false);
  }

  String detectLanguage(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    const map = {
      '.dart': 'dart',
      '.js': 'javascript',
      '.ts': 'typescript',
      '.tsx': 'typescript',
      '.jsx': 'javascript',
      '.py': 'python',
      '.rb': 'ruby',
      '.go': 'go',
      '.rs': 'rust',
      '.java': 'java',
      '.kt': 'kotlin',
      '.swift': 'swift',
      '.cpp': 'cpp',
      '.c': 'c',
      '.h': 'c',
      '.cs': 'csharp',
      '.php': 'php',
      '.html': 'html',
      '.css': 'css',
      '.scss': 'scss',
      '.json': 'json',
      '.yaml': 'yaml',
      '.yml': 'yaml',
      '.xml': 'xml',
      '.md': 'markdown',
      '.sh': 'bash',
      '.bash': 'bash',
      '.sql': 'sql',
      '.graphql': 'graphql',
      '.toml': 'toml',
    };
    return map[ext] ?? 'plaintext';
  }
}
