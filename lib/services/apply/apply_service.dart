import 'dart:async';
import 'dart:io';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/applied_change.dart';
import '../../features/chat/chat_notifier.dart';
import '../filesystem/filesystem_service.dart';

part 'apply_service.g.dart';

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments, {String? workingDirectory});

/// Hard cap on the size of content that can be applied in a single operation.
/// Prevents an AI-generated multi-megabyte blob from pinning memory inside
/// the [AppliedChange] snapshot (which keeps both original and new content
/// for revert). 1 MiB is ~30k lines of source — comfortably above any
/// realistic single-file code change.
const int kMaxApplyContentBytes = 1024 * 1024;

/// Timeout for `git checkout --` during revert. Keeps the UI responsive if
/// the git process hangs (lock contention, dead credential helper, etc.).
const Duration kGitCheckoutTimeout = Duration(seconds: 15);

@Riverpod(keepAlive: true)
ApplyService applyService(Ref ref) {
  return ApplyService(fs: ref.watch(filesystemServiceProvider), notifier: ref.watch(appliedChangesProvider.notifier));
}

class ApplyService {
  ApplyService({
    required FilesystemService fs,
    required AppliedChanges notifier,
    String Function()? uuidGen,
    ProcessRunner? processRunner,
  }) : _fs = fs,
       _notifier = notifier,
       _uuidGen = uuidGen ?? (() => const Uuid().v4()),
       _processRunner = processRunner ?? Process.run;

  final FilesystemService _fs;
  final AppliedChanges _notifier;
  final String Function() _uuidGen;
  final ProcessRunner _processRunner;

  /// Throws [StateError] if [filePath] is not inside [projectPath].
  ///
  /// Guards against path-traversal attacks from AI-controlled filenames.
  /// Performs **two** checks:
  ///   1. Lexical — `p.normalize` strips `..` / `.` / duplicate separators
  ///      and verifies the result starts with the project root.
  ///   2. Physical — resolves symlinks on the deepest existing ancestor
  ///      and verifies the real path is still inside the real project root.
  ///      This blocks symlink-escape attacks where a link inside the
  ///      project tree points to somewhere outside (e.g. `lib/x -> /etc`).
  static void assertWithinProject(String filePath, String projectPath) {
    // Lexical check — cheap, blocks obvious ../ before any I/O
    final lexFile = p.normalize(p.absolute(filePath));
    final lexRoot = p.normalize(p.absolute(projectPath));
    final lexRootWithSep = lexRoot + p.separator;
    if (!lexFile.startsWith(lexRootWithSep)) {
      throw StateError('Path "$filePath" is outside project root "$projectPath"');
    }

    // Physical check — resolve symlinks on both root and deepest existing
    // ancestor of the target. We cannot resolve the target itself because
    // the file may not exist yet (creating a new file is a normal case).
    final rootDir = Directory(lexRoot);
    if (!rootDir.existsSync()) {
      throw StateError('Project root does not exist: "$projectPath"');
    }
    final rootReal = rootDir.resolveSymbolicLinksSync();

    var probe = Directory(p.dirname(lexFile));
    while (!probe.existsSync()) {
      final parent = probe.parent;
      if (parent.path == probe.path) break; // reached filesystem root
      probe = parent;
    }
    String probeReal;
    try {
      probeReal = probe.resolveSymbolicLinksSync();
    } on FileSystemException {
      throw StateError('Could not resolve real path for "$filePath"');
    }
    final rootRealWithSep = rootReal + p.separator;
    if (probeReal != rootReal && !probeReal.startsWith(rootRealWithSep)) {
      throw StateError('Path "$filePath" resolves outside project root via a symlink');
    }
  }

  Future<void> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    assertWithinProject(filePath, projectPath);

    // Reject oversized content before we touch disk. We count UTF-16 code
    // units (String.length) as a cheap proxy for byte size — worst case
    // for multi-byte encodings, real byte size is ≤ 3× this, and the cap
    // is generous enough (1 MiB ≈ 30k lines) to never hit legitimate code.
    if (newContent.length > kMaxApplyContentBytes) {
      throw StateError(
        'Content too large to apply: ${newContent.length} bytes exceeds '
        'limit of $kMaxApplyContentBytes bytes',
      );
    }

    // TOCTOU-safe read: attempt the read directly and fall back to "new
    // file" on PathNotFoundException. A plain `existsSync` + `readFile`
    // races the filesystem between the stat and the read; a file that
    // vanishes in between would surface as a confusing error. We bypass
    // [FilesystemService.readFile] here because its wrapping hides the
    // native exception type we need to discriminate on.
    String? originalContent;
    try {
      originalContent = await File(filePath).readAsString();
    } on PathNotFoundException {
      originalContent = null;
    }

    if (originalContent != null && originalContent.length > kMaxApplyContentBytes) {
      throw StateError(
        'Original file too large to snapshot for revert: '
        '${originalContent.length} bytes exceeds limit of '
        '$kMaxApplyContentBytes bytes',
      );
    }

    if (originalContent == null) {
      await _fs.createDirectory(p.dirname(filePath));
    }
    await _fs.writeFile(filePath, newContent);

    final (additions, deletions) = _computeLineCounts(originalContent, newContent);

    _notifier.apply(
      AppliedChange(
        id: _uuidGen(),
        sessionId: sessionId,
        messageId: messageId,
        filePath: filePath,
        originalContent: originalContent,
        newContent: newContent,
        appliedAt: DateTime.now(),
        additions: additions,
        deletions: deletions,
      ),
    );
  }

  Future<void> revertChange({required AppliedChange change, required bool isGit, required String projectPath}) async {
    assertWithinProject(change.filePath, projectPath);
    if (change.originalContent == null) {
      // File was created by Apply — delete it
      await _fs.deleteFile(change.filePath);
    } else if (isGit) {
      final ProcessResult result;
      try {
        result = await _processRunner('git', [
          'checkout',
          '--',
          change.filePath,
        ], workingDirectory: projectPath).timeout(kGitCheckoutTimeout);
      } on TimeoutException {
        throw StateError('git checkout timed out after ${kGitCheckoutTimeout.inSeconds}s');
      }
      if (result.exitCode != 0) {
        throw StateError('git checkout failed (exit ${result.exitCode}): ${result.stderr}');
      }
    } else {
      await _fs.writeFile(change.filePath, change.originalContent!);
    }

    _notifier.revert(change.id);
  }

  /// Counts line-level additions and deletions using a true line diff.
  ///
  /// Encodes each unique line as a single character, diffs the encoded
  /// strings (giving line-granularity results), then counts inserted and
  /// deleted characters (each representing one line). This avoids the
  /// double-counting that a char-level diff produces when inline edits
  /// straddle line boundaries.
  static (int additions, int deletions) _computeLineCounts(String? original, String newContent) {
    final a = original ?? '';
    final aLines = a.isEmpty ? <String>[] : a.split('\n');
    final bLines = newContent.isEmpty ? <String>[] : newContent.split('\n');

    // Map each unique line to a single code-unit so DiffMatchPatch operates
    // at line granularity. Start at code-unit 1 to avoid null-byte issues.
    final lineToChar = <String, String>{};
    final charArray = <String>['']; // index 0 unused
    String encode(List<String> lines) {
      final buf = StringBuffer();
      for (final line in lines) {
        if (!lineToChar.containsKey(line)) {
          charArray.add(line);
          lineToChar[line] = String.fromCharCode(charArray.length - 1);
        }
        buf.write(lineToChar[line]);
      }
      return buf.toString();
    }

    final encA = encode(aLines);
    final encB = encode(bLines);

    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(encA, encB, false);
    dmp.diffCleanupSemantic(diffs);

    var additions = 0;
    var deletions = 0;
    for (final d in diffs) {
      if (d.operation == DIFF_INSERT) {
        additions += d.text.length;
      } else if (d.operation == DIFF_DELETE) {
        deletions += d.text.length;
      }
    }
    return (additions, deletions);
  }
}
