import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/debug_logger.dart';
import 'project_file_scan_datasource.dart';

part 'project_file_scan_datasource_io.g.dart';

/// Hard cap on how many files the picker's scan will collect. Short-circuits
/// the walk once reached — a bigger list would blow the autocomplete popover's
/// budget anyway and tells us the project is huge enough that substring
/// filtering is the wrong UX.
const int kMaxScanFiles = 2000;

/// Extensions considered "code" for the @-mention file picker. Kept
/// intentionally narrow: we want the picker to surface source files, not
/// build artifacts, lockfiles, or generated binaries.
const Set<String> kCodeExtensions = {
  '.dart',
  '.ts',
  '.tsx',
  '.js',
  '.jsx',
  '.py',
  '.go',
  '.rs',
  '.java',
  '.kt',
  '.swift',
  '.rb',
  '.c',
  '.cpp',
  '.cc',
  '.h',
  '.hpp',
  '.cs',
  '.json',
  '.yaml',
  '.yml',
  '.toml',
  '.md',
  '.sh',
  '.html',
  '.css',
  '.scss',
};

/// Directory basenames pruned at the walk level, not after. Stat-ing the
/// millions of entries inside `node_modules` / `.dart_tool` before filtering
/// would make the picker visibly sluggish on any real project.
const Set<String> kSkipDirs = {'.git', '.dart_tool', 'build', 'node_modules', '.worktrees', '.idea', '.vscode'};

@Riverpod(keepAlive: true)
ProjectFileScanDatasource projectFileScanDatasource(Ref ref) => ProjectFileScanDatasourceIo();

/// Walks a project root and returns repo-relative paths of code files.
///
/// Pruning happens at the directory level (vs. filtering yielded files from
/// `Directory.list(recursive: true)`) so heavy trees like `node_modules`
/// never hit the OS scan. Short-circuits at [kMaxScanFiles].
class ProjectFileScanDatasourceIo implements ProjectFileScanDatasource {
  /// Returns repo-relative paths of code files under [rootPath].
  ///
  /// Propagates [FileSystemException] when the root itself cannot be listed
  /// — the caller can decide whether that's a user-visible error or a
  /// silently-skipped subtree.
  @override
  Future<List<String>> scanCodeFiles(String rootPath) async {
    final out = <String>[];
    await _walk(Directory(rootPath), rootPath, out);
    return out;
  }

  Future<void> _walk(Directory dir, String rootPath, List<String> out) async {
    if (out.length >= kMaxScanFiles) return;
    final List<FileSystemEntity> entries;
    try {
      entries = await dir.list(followLinks: false).toList();
    } on FileSystemException catch (e) {
      // Permission-denied on a subdirectory: skip it but continue the
      // walk. Only a root-level failure should bubble up as a scan error.
      if (dir.path == rootPath) rethrow;
      dLog('[ProjectFileScanDatasource] skipping ${dir.path}: ${e.runtimeType}');
      return;
    }
    for (final entity in entries) {
      if (out.length >= kMaxScanFiles) return;
      if (entity is Directory) {
        final base = p.basename(entity.path);
        if (kSkipDirs.contains(base)) continue;
        await _walk(entity, rootPath, out);
      } else if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (!kCodeExtensions.contains(ext)) continue;
        out.add(p.relative(entity.path, from: rootPath));
      }
    }
  }
}
