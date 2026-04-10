import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/applied_change.dart';
import '../../features/chat/chat_notifier.dart';
import '../filesystem/filesystem_service.dart';

part 'apply_service.g.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
});

@Riverpod(keepAlive: true)
ApplyService applyService(Ref ref) {
  return ApplyService(
    fs: ref.read(filesystemServiceProvider),
    notifier: ref.read(appliedChangesProvider.notifier),
  );
}

class ApplyService {
  ApplyService({
    required FilesystemService fs,
    required AppliedChanges notifier,
    String Function()? uuidGen,
    ProcessRunner? processRunner,
  })  : _fs = fs,
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
      throw StateError(
        'Path "$filePath" is outside project root "$projectPath"',
      );
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
    final probeReal = probe.resolveSymbolicLinksSync();
    final rootRealWithSep = rootReal + p.separator;
    if (probeReal != rootReal && !probeReal.startsWith(rootRealWithSep)) {
      throw StateError(
        'Path "$filePath" resolves outside project root via a symlink',
      );
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
    final file = File(filePath);
    String? originalContent;
    if (file.existsSync()) {
      originalContent = await _fs.readFile(filePath);
    }

    if (originalContent == null) {
      await _fs.createDirectory(p.dirname(filePath));
    }
    await _fs.writeFile(filePath, newContent);

    _notifier.apply(AppliedChange(
      id: _uuidGen(),
      sessionId: sessionId,
      messageId: messageId,
      filePath: filePath,
      originalContent: originalContent,
      newContent: newContent,
      appliedAt: DateTime.now(),
    ));
  }

  Future<void> revertChange({
    required AppliedChange change,
    required bool isGit,
    required String projectPath,
  }) async {
    assertWithinProject(change.filePath, projectPath);
    if (change.originalContent == null) {
      // File was created by Apply — delete it
      await _fs.deleteFile(change.filePath);
    } else if (isGit) {
      final result = await _processRunner(
        'git',
        ['checkout', '--', change.filePath],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) {
        throw StateError(
          'git checkout failed (exit ${result.exitCode}): ${result.stderr}',
        );
      }
    } else {
      await _fs.writeFile(change.filePath, change.originalContent!);
    }

    _notifier.revert(change.id);
  }
}
