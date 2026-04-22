import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/debug_logger.dart';
import '../apply_exceptions.dart';

/// Raw I/O facade for file apply operations.
/// Business logic (policy, validation, UUID) lives in ApplyService.
abstract interface class ApplyRepository {
  /// Returns the file content, or `null` if the file does not exist.
  /// Throws [ApplyDiskException] on other I/O failures.
  Future<String?> readFile(String path);
  Future<void> writeFile(String path, String content);
  Future<void> deleteFile(String path);
  Future<void> gitCheckout(String filePath, String workingDirectory);

  /// Throws [PathEscapeException] if [filePath] escapes [projectPath]
  /// (lexical and symlink checks). Throws [ProjectMissingException] if
  /// the project root is gone. Documented exception to the arch rule —
  /// this static security guard may be called from widgets, notifiers,
  /// and any data-layer code that needs to validate a path.
  static void assertWithinProject(String filePath, String projectPath) {
    final lexFile = p.normalize(p.absolute(filePath));
    final lexRoot = p.normalize(p.absolute(projectPath));
    final lexRootWithSep = lexRoot + p.separator;

    // On macOS, default APFS volumes are case-insensitive. Normalise to
    // lowercase before the lexical containment check so that paths with
    // differing capitalisation (e.g. /Users/mk vs /users/mk) are accepted.
    // Case-sensitive APFS volumes exist but are uncommon; they will see
    // false-negatives for same-directory paths with different casing, which
    // is acceptable — they'll still pass the symlink check below.
    final compareFile = Platform.isMacOS ? lexFile.toLowerCase() : lexFile;
    final compareRoot = Platform.isMacOS ? lexRootWithSep.toLowerCase() : lexRootWithSep;

    if (!compareFile.startsWith(compareRoot)) {
      sLog('[assertWithinProject] lexical reject: "$filePath" outside "$projectPath"');
      throw PathEscapeException(filePath, projectPath);
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
      throw PathEscapeException(filePath, projectPath);
    }
    // resolveSymbolicLinksSync returns OS-canonical casing on macOS, so the
    // real paths will share the same casing — no additional toLowerCase needed.
    final rootRealWithSep = rootReal + p.separator;
    if (probeReal != rootReal && !probeReal.startsWith(rootRealWithSep)) {
      sLog('[assertWithinProject] symlink escape: "$filePath" → "$probeReal" outside "$rootReal"');
      throw PathEscapeException(filePath, projectPath);
    }
  }

  /// Returns the SHA-256 hex digest of [content].
  static String sha256OfString(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }
}
