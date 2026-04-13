import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/debug_logger.dart';
import '../../models/applied_change.dart';

/// Thrown when a write is attempted against a project whose root folder
/// has been deleted or moved. The UI should catch this and prompt the
/// user to Relocate or Remove.
class ProjectMissingException implements Exception {
  ProjectMissingException(this.projectPath);
  final String projectPath;

  @override
  String toString() => 'Project folder is missing: $projectPath';
}

abstract interface class ApplyRepository {
  /// Applies [newContent] to [filePath], snapshots the original for revert,
  /// and returns the recorded [AppliedChange]. Throws [StateError] for
  /// path-traversal or size violations, [ProjectMissingException] when the
  /// project root is gone, and [FileSystemException] on disk write failure.
  Future<AppliedChange> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  });

  /// Reverts [change] using git checkout (when [isGit]) or by restoring
  /// [AppliedChange.originalContent]. Deletes the file when originalContent
  /// is null (file was created by apply). Throws [StateError] on git failure.
  Future<void> revertChange({required AppliedChange change, required bool isGit, required String projectPath});

  /// Returns current on-disk content of [filePath] for the conflict-merge
  /// view. Returns `null` if the file cannot be read.
  Future<String?> readFileContent(String filePath, String projectPath);

  /// Returns current on-disk content of [absolutePath] for diff rendering.
  /// Returns `null` when the file does not exist yet (new-file apply).
  /// Runs [assertWithinProject] first; propagates [StateError] and
  /// [ProjectMissingException] unchanged.
  Future<String?> readOriginalForDiff(String absolutePath, String projectPath);

  /// Returns `true` if [filePath] no longer matches [storedChecksum].
  /// A missing file or read error also returns `true` — erring on the side
  /// of prompting the user rather than silently reverting over unknown state.
  Future<bool> isExternallyModified(String filePath, String storedChecksum);

  // ── Static utilities ───────────────────────────────────────────────────────

  /// Throws [StateError] if [filePath] is not lexically and physically inside
  /// [projectPath]. Guards against path-traversal attacks from AI-controlled
  /// filenames. Permitted in widgets per CLAUDE.md.
  static void assertWithinProject(String filePath, String projectPath) {
    final lexFile = p.normalize(p.absolute(filePath));
    final lexRoot = p.normalize(p.absolute(projectPath));
    final lexRootWithSep = lexRoot + p.separator;
    if (!lexFile.startsWith(lexRootWithSep)) {
      sLog('[assertWithinProject] lexical reject: "$filePath" outside "$projectPath"');
      throw StateError('Path "$filePath" is outside project root "$projectPath"');
    }

    final rootDir = Directory(lexRoot);
    if (!rootDir.existsSync()) {
      throw ProjectMissingException(projectPath);
    }
    final rootReal = rootDir.resolveSymbolicLinksSync();

    var probe = Directory(p.dirname(lexFile));
    while (!probe.existsSync()) {
      final parent = probe.parent;
      if (parent.path == probe.path) break;
      probe = parent;
    }
    String probeReal;
    try {
      probeReal = probe.resolveSymbolicLinksSync();
    } on FileSystemException {
      sLog('[assertWithinProject] symlink resolve failed: "$filePath"');
      throw StateError('Could not resolve real path for "$filePath"');
    }
    final rootRealWithSep = rootReal + p.separator;
    if (probeReal != rootReal && !probeReal.startsWith(rootRealWithSep)) {
      sLog('[assertWithinProject] symlink escape: "$filePath" → "$probeReal" outside "$rootReal"');
      throw StateError('Path "$filePath" resolves outside project root via a symlink');
    }
  }

  /// Returns the SHA-256 hex digest of [content].
  static String sha256OfString(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }
}
