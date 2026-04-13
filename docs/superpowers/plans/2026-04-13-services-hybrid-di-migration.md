# Services Hybrid DI Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `lib/services/apply/apply_service.dart` and `lib/services/api_key_test_service.dart` to the hybrid DI pattern already used in `lib/data/` — plain Dart classes with constructor injection, wired by `@Riverpod` provider functions.

**Architecture:** `ApplyService` becomes `ApplyRepository` (abstract interface) + `ApplyRepositoryImpl` (constructor-injected impl) living in `lib/data/apply/repository/`. The notifier dependency is removed: `applyChange` returns `AppliedChange` and `CodeApplyActions` calls `appliedChangesProvider.notifier` directly. `ApiKeyTestService` gets a constructor param for its datasource. All callers of static `ApplyService` methods are rerouted through the provider or the notifier layer.

**Tech Stack:** Dart 3, Flutter, Riverpod (`riverpod_annotation`), `build_runner`, `diff_match_patch`, `crypto`, `path`

---

## File Map

**Create:**
- `lib/data/apply/repository/apply_repository.dart` — abstract interface + `ProjectMissingException`
- `lib/data/apply/repository/apply_repository_impl.dart` — `ApplyRepositoryImpl` class + `@Riverpod(keepAlive: true)` provider function

**Modify:**
- `lib/services/api_key_test_service.dart` — inject `ApiKeyTestDatasourceDio` via constructor
- `lib/features/chat/notifiers/code_apply_actions.dart` — use `applyRepositoryProvider`; call `appliedChangesProvider.notifier` directly; add `isExternallyModified` method
- `lib/features/chat/notifiers/code_diff_provider.dart` — replace static `ApplyService.readOriginalForDiff` with `ref.read(applyRepositoryProvider).readOriginalForDiff`
- `lib/features/chat/widgets/changes_panel.dart` — replace static `ApplyService.isExternallyModified` in `initState` with `ref.read(codeApplyActionsProvider.notifier).isExternallyModified`
- `test/services/apply/apply_service_test.dart` → move + rewrite as `test/data/apply/apply_repository_test.dart`
- `test/services/apply/apply_service_checksum_test.dart` → move + rewrite as `test/data/apply/apply_repository_checksum_test.dart`
- `test/features/chat/notifiers/code_apply_actions_test.dart` — swap `_FakeApplyService` for `_FakeApplyRepository`

**Delete (after all callers updated):**
- `lib/services/apply/apply_service.dart`
- `lib/services/apply/apply_service.g.dart`

---

## Task 1: Create `ApplyRepository` interface

**Files:**
- Create: `lib/data/apply/repository/apply_repository.dart`

This interface is the contract for the apply subsystem. `ProjectMissingException` moves here (away from the service file) so all callers import from one place. Static utilities (`assertWithinProject`, `sha256OfString`) stay as statics on the interface — Dart 3 allows static members in `abstract interface class`.

- [ ] **Step 1: Create the interface file**

```dart
// lib/data/apply/repository/apply_repository.dart
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
  Future<void> revertChange({
    required AppliedChange change,
    required bool isGit,
    required String projectPath,
  });

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
```

- [ ] **Step 2: Verify file compiles**

```bash
cd /path/to/repo && dart analyze lib/data/apply/repository/apply_repository.dart
```

Expected: no errors (file has no generated parts, no `build_runner` needed yet).

---

## Task 2: Create `ApplyRepositoryImpl` with provider function

**Files:**
- Create: `lib/data/apply/repository/apply_repository_impl.dart`

`ApplyRepositoryImpl` is constructor-injected — no `Ref` stored on the class. The `@Riverpod` annotation belongs only on the provider function that wires it. `applyChange` returns `AppliedChange` (no notifier dependency); callers decide what to do with the result.

- [ ] **Step 1: Create the implementation file**

```dart
// lib/data/apply/repository/apply_repository_impl.dart
import 'dart:async';
import 'dart:io';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart' as app_errors;
import '../../../core/utils/debug_logger.dart';
import '../../../data/models/applied_change.dart';
import '../../filesystem/repository/filesystem_repository.dart';
import '../../filesystem/repository/filesystem_repository_impl.dart';
import 'apply_repository.dart';

part 'apply_repository_impl.g.dart';

/// Hard cap on the size of content that can be applied in a single operation.
const int kMaxApplyContentBytes = 1024 * 1024;

/// Timeout for `git checkout --` during revert.
const Duration kGitCheckoutTimeout = Duration(seconds: 15);

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments, {String? workingDirectory});

@Riverpod(keepAlive: true)
ApplyRepository applyRepository(Ref ref) {
  return ApplyRepositoryImpl(
    fs: ref.watch(filesystemRepositoryProvider),
  );
}

class ApplyRepositoryImpl implements ApplyRepository {
  ApplyRepositoryImpl({
    required FilesystemRepository fs,
    String Function()? uuidGen,
    ProcessRunner? processRunner,
  }) : _fs = fs,
       _uuidGen = uuidGen ?? (() => const Uuid().v4()),
       _processRunner = processRunner ?? Process.run;

  final FilesystemRepository _fs;
  final String Function() _uuidGen;
  final ProcessRunner _processRunner;

  @override
  Future<AppliedChange> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    ApplyRepository.assertWithinProject(filePath, projectPath);

    if (newContent.length > kMaxApplyContentBytes) {
      throw StateError(
        'Content too large to apply: ${newContent.length} bytes exceeds '
        'limit of $kMaxApplyContentBytes bytes',
      );
    }

    String? originalContent;
    try {
      originalContent = await _fs.readFile(filePath);
    } on app_errors.FileSystemException catch (e) {
      if (e.originalError is PathNotFoundException) {
        originalContent = null;
      } else {
        rethrow;
      }
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
    final checksum = ApplyRepository.sha256OfString(newContent);

    return AppliedChange(
      id: _uuidGen(),
      sessionId: sessionId,
      messageId: messageId,
      filePath: filePath,
      originalContent: originalContent,
      newContent: newContent,
      appliedAt: DateTime.now(),
      additions: additions,
      deletions: deletions,
      contentChecksum: checksum,
    );
  }

  @override
  Future<void> revertChange({
    required AppliedChange change,
    required bool isGit,
    required String projectPath,
  }) async {
    ApplyRepository.assertWithinProject(change.filePath, projectPath);
    if (change.originalContent == null) {
      await _fs.deleteFile(change.filePath);
    } else if (isGit) {
      final ProcessResult result;
      try {
        result = await _processRunner(
          'git',
          ['checkout', '--', change.filePath],
          workingDirectory: projectPath,
        ).timeout(kGitCheckoutTimeout);
      } on TimeoutException {
        throw StateError('git checkout timed out after ${kGitCheckoutTimeout.inSeconds}s');
      }
      if (result.exitCode != 0) {
        throw StateError('git checkout failed (exit ${result.exitCode}): ${result.stderr}');
      }
    } else {
      await _fs.writeFile(change.filePath, change.originalContent!);
    }
  }

  @override
  Future<String?> readFileContent(String filePath, String projectPath) async {
    ApplyRepository.assertWithinProject(filePath, projectPath);
    try {
      return await _fs.readFile(filePath);
    } on app_errors.FileSystemException catch (e) {
      dLog('[ApplyRepositoryImpl] readFileContent failed: $e');
      return null;
    }
  }

  @override
  Future<String?> readOriginalForDiff(String absolutePath, String projectPath) async {
    ApplyRepository.assertWithinProject(absolutePath, projectPath);
    try {
      return await File(absolutePath).readAsString();
    } on PathNotFoundException {
      return null;
    } on FileSystemException catch (e) {
      dLog('[ApplyRepositoryImpl] readOriginalForDiff failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> isExternallyModified(String filePath, String storedChecksum) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return true;
      final current = await file.readAsString();
      return ApplyRepository.sha256OfString(current) != storedChecksum;
    } catch (e) {
      dLog('[ApplyRepositoryImpl] isExternallyModified read failed: ${e.runtimeType}');
      return true;
    }
  }

  static (int additions, int deletions) _computeLineCounts(String? original, String newContent) {
    final a = original ?? '';
    final aLines = a.isEmpty ? <String>[] : a.split('\n');
    final bLines = newContent.isEmpty ? <String>[] : newContent.split('\n');

    final lineToChar = <String, String>{};
    final charArray = <String>[''];
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
      if (d.operation == DIFF_INSERT) additions += d.text.length;
      else if (d.operation == DIFF_DELETE) deletions += d.text.length;
    }
    return (additions, deletions);
  }
}
```

- [ ] **Step 2: Run `build_runner` to generate `apply_repository_impl.g.dart`**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/data/apply/repository/apply_repository_impl.g.dart` is created. No other generated files change.

---

## Task 3: Write `apply_repository_test.dart` (replaces `apply_service_test.dart`)

**Files:**
- Create: `test/data/apply/apply_repository_test.dart`

The new test directly instantiates `ApplyRepositoryImpl` — no `ProviderContainer` needed because the impl has no Riverpod dependency. `applyChange` now returns `AppliedChange` so assertions are on the return value, not on `appliedChangesProvider`.

- [ ] **Step 1: Create test file**

```dart
// test/data/apply/apply_repository_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:code_bench_app/data/models/applied_change.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';

void main() {
  late Directory tmpDir;
  late ApplyRepositoryImpl repo;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('apply_repo_test_');
    repo = ApplyRepositoryImpl(
      fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()),
      uuidGen: () => 'test-uuid',
    );
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  test('applyChange creates file and returns change when file did not exist', () async {
    final filePath = '${tmpDir.path}/new_file.dart';
    final change = await repo.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'void main() {}',
      sessionId: 'sid',
      messageId: 'mid',
    );

    expect(File(filePath).existsSync(), true);
    expect(File(filePath).readAsStringSync(), 'void main() {}');
    expect(change.originalContent, isNull);
    expect(change.newContent, 'void main() {}');
    expect(change.filePath, filePath);
    expect(change.id, 'test-uuid');
    expect(change.additions, 1);
    expect(change.deletions, 0);
  });

  test('applyChange records line counts when replacing content line-for-line', () async {
    final filePath = '${tmpDir.path}/swap.dart';
    File(filePath).writeAsStringSync('a\nb\nc\n');

    final change = await repo.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'x\ny\nz\n',
      sessionId: 'sid',
      messageId: 'mid',
    );

    expect(change.additions, 3);
    expect(change.deletions, 3);
  });

  test('applyChange counts inline edits as single-line changes', () async {
    final filePath = '${tmpDir.path}/rename.dart';
    File(filePath).writeAsStringSync('final foo = 42;\n');

    final change = await repo.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'final bar = 42;\n',
      sessionId: 'sid',
      messageId: 'mid',
    );

    expect(change.additions, 1);
    expect(change.deletions, 1);
  });

  test('applyChange rejects content larger than kMaxApplyContentBytes', () async {
    final filePath = '${tmpDir.path}/huge.dart';
    final oversized = 'a' * (kMaxApplyContentBytes + 1);

    await expectLater(
      () => repo.applyChange(
        filePath: filePath,
        projectPath: tmpDir.path,
        newContent: oversized,
        sessionId: 'sid',
        messageId: 'mid',
      ),
      throwsA(isA<StateError>()),
    );

    expect(File(filePath).existsSync(), false);
  });

  test('applyChange rejects oversized original file snapshot', () async {
    final filePath = '${tmpDir.path}/legacy_huge.dart';
    File(filePath).writeAsStringSync('a' * (kMaxApplyContentBytes + 1));

    await expectLater(
      () => repo.applyChange(
        filePath: filePath,
        projectPath: tmpDir.path,
        newContent: 'small',
        sessionId: 'sid',
        messageId: 'mid',
      ),
      throwsA(isA<StateError>()),
    );

    expect(File(filePath).readAsStringSync().length, kMaxApplyContentBytes + 1);
  });

  test('applyChange rejects path outside project', () async {
    await expectLater(
      () => repo.applyChange(
        filePath: '/etc/passwd',
        projectPath: tmpDir.path,
        newContent: 'x',
        sessionId: 's',
        messageId: 'm',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('revertChange deletes file when originalContent is null', () async {
    final filePath = '${tmpDir.path}/to_delete.dart';
    File(filePath).writeAsStringSync('content');

    final change = AppliedChange(
      id: 'id',
      sessionId: 's',
      messageId: 'm',
      filePath: filePath,
      originalContent: null,
      newContent: 'content',
      appliedAt: DateTime(2024),
      additions: 1,
      deletions: 0,
    );

    await repo.revertChange(change: change, isGit: false, projectPath: tmpDir.path);

    expect(File(filePath).existsSync(), false);
  });

  test('revertChange restores originalContent when not git', () async {
    final filePath = '${tmpDir.path}/restore.dart';
    File(filePath).writeAsStringSync('new content');

    final change = AppliedChange(
      id: 'id',
      sessionId: 's',
      messageId: 'm',
      filePath: filePath,
      originalContent: 'original',
      newContent: 'new content',
      appliedAt: DateTime(2024),
      additions: 1,
      deletions: 1,
    );

    await repo.revertChange(change: change, isGit: false, projectPath: tmpDir.path);

    expect(File(filePath).readAsStringSync(), 'original');
  });

  test('readOriginalForDiff returns null for non-existent file', () async {
    final result = await repo.readOriginalForDiff(
      '${tmpDir.path}/nonexistent.dart',
      tmpDir.path,
    );
    expect(result, isNull);
  });

  test('readOriginalForDiff returns content for existing file', () async {
    final filePath = '${tmpDir.path}/existing.dart';
    File(filePath).writeAsStringSync('hello');

    final result = await repo.readOriginalForDiff(filePath, tmpDir.path);
    expect(result, 'hello');
  });

  test('isExternallyModified returns false when checksums match', () async {
    final filePath = '${tmpDir.path}/same.txt';
    File(filePath).writeAsStringSync('same');
    final checksum = ApplyRepository.sha256OfString('same');

    expect(await repo.isExternallyModified(filePath, checksum), isFalse);
  });

  test('isExternallyModified returns true when file changed', () async {
    final filePath = '${tmpDir.path}/changed.txt';
    File(filePath).writeAsStringSync('changed');
    final checksum = ApplyRepository.sha256OfString('original');

    expect(await repo.isExternallyModified(filePath, checksum), isTrue);
  });

  test('isExternallyModified returns true when file is missing', () async {
    expect(
      await repo.isExternallyModified('${tmpDir.path}/gone.txt', 'any'),
      isTrue,
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they pass**

```bash
flutter test test/data/apply/apply_repository_test.dart
```

Expected: all tests pass.

---

## Task 4: Write `apply_repository_checksum_test.dart` (replaces checksum test)

**Files:**
- Create: `test/data/apply/apply_repository_checksum_test.dart`

The static utility methods moved from `ApplyService` to `ApplyRepository`. Update call sites.

- [ ] **Step 1: Create test file**

```dart
// test/data/apply/apply_repository_checksum_test.dart
import 'package:code_bench_app/data/apply/repository/apply_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sha256OfString returns non-empty hex string', () {
    final hash = ApplyRepository.sha256OfString('hello world');
    expect(hash, isNotEmpty);
    expect(hash.length, 64);
  });

  test('same content produces same checksum', () {
    expect(
      ApplyRepository.sha256OfString('content'),
      equals(ApplyRepository.sha256OfString('content')),
    );
  });

  test('different content produces different checksum', () {
    expect(
      ApplyRepository.sha256OfString('content a'),
      isNot(equals(ApplyRepository.sha256OfString('content b'))),
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they pass**

```bash
flutter test test/data/apply/apply_repository_checksum_test.dart
```

Expected: all tests pass.

---

## Task 5: Update `CodeApplyActions` to use `ApplyRepository`

**Files:**
- Modify: `lib/features/chat/notifiers/code_apply_actions.dart`

Three changes:
1. `applyServiceProvider` → `applyRepositoryProvider`; the returned `AppliedChange` is passed to `appliedChangesProvider.notifier.apply()`
2. `revertChange` calls the repo then calls `appliedChangesProvider.notifier.revert()`
3. New forwarding method `isExternallyModified` for `changes_panel.dart` to call

- [ ] **Step 1: Rewrite `code_apply_actions.dart`**

```dart
// lib/features/chat/notifiers/code_apply_actions.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/apply/repository/apply_repository.dart';
import '../../../data/apply/repository/apply_repository_impl.dart';
import '../../../data/models/applied_change.dart';
import '../../project_sidebar/notifiers/project_sidebar_actions.dart';
import '../notifiers/chat_notifier.dart';
import 'code_apply_failure.dart';

part 'code_apply_actions.g.dart';

/// Command notifier for code-apply and revert operations.
///
/// Widgets never reach [ApplyRepository] directly — they call methods here.
/// State is [AsyncValue<void>]: loading/error/data are driven by each method.
/// Typed failures are emitted as [AsyncError] carrying a [CodeApplyFailure].
///
/// On [ProjectMissingException], [applyChange] also triggers a project-status
/// refresh so the sidebar reflects the missing state without the widget needing
/// to know about [ProjectSidebarActions].
@Riverpod(keepAlive: true)
class CodeApplyActions extends _$CodeApplyActions {
  @override
  FutureOr<void> build() {}

  CodeApplyFailure _asApplyFailure(Object e) => switch (e) {
    ProjectMissingException() => const CodeApplyFailure.projectMissing(),
    StateError() => const CodeApplyFailure.outsideProject(),
    FileSystemException(:final message) => CodeApplyFailure.diskWrite(message),
    _ => CodeApplyFailure.unknown(e),
  };

  Future<void> applyChange({
    required String projectId,
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final change = await ref.read(applyRepositoryProvider).applyChange(
          filePath: filePath,
          projectPath: projectPath,
          newContent: newContent,
          sessionId: sessionId,
          messageId: messageId,
        );
        ref.read(appliedChangesProvider.notifier).apply(change);
      } on ProjectMissingException catch (e, st) {
        dLog('[CodeApplyActions] applyChange projectMissing: $e');
        unawaited(ref.read(projectSidebarActionsProvider.notifier).refreshProjectStatus(projectId));
        Error.throwWithStackTrace(_asApplyFailure(e), st);
      } catch (e, st) {
        dLog('[CodeApplyActions] applyChange failed: $e');
        Error.throwWithStackTrace(_asApplyFailure(e), st);
      }
    });
  }

  Future<void> revertChange({
    required AppliedChange change,
    required bool isGit,
    required String projectPath,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(applyRepositoryProvider).revertChange(
          change: change,
          isGit: isGit,
          projectPath: projectPath,
        );
        ref.read(appliedChangesProvider.notifier).revert(change.id);
      } catch (e, st) {
        dLog('[CodeApplyActions] revertChange failed: $e');
        Error.throwWithStackTrace(CodeApplyFailure.unknown(e), st);
      }
    });
  }

  Future<String?> readFileContent(String filePath, String projectPath) =>
      ref.read(applyRepositoryProvider).readFileContent(filePath, projectPath);

  /// Checks whether [filePath] has been modified since [storedChecksum] was
  /// recorded. Called from [ChangesPanel] via `ref.read(.notifier)` in
  /// `initState` — routing through the notifier keeps dart:io out of widgets.
  Future<bool> isExternallyModified(String filePath, String storedChecksum) =>
      ref.read(applyRepositoryProvider).isExternallyModified(filePath, storedChecksum);
}
```

- [ ] **Step 2: Run `build_runner`**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/features/chat/notifiers/code_apply_actions.g.dart` regenerates. No errors.

---

## Task 6: Update `code_apply_actions_test.dart`

**Files:**
- Modify: `test/features/chat/notifiers/code_apply_actions_test.dart`

Swap `_FakeApplyService` for `_FakeApplyRepository`, update the provider override, and add an assertion that `appliedChangesProvider` is populated on success (because `CodeApplyActions` now calls the notifier directly).

- [ ] **Step 1: Rewrite the fake and test setup**

Replace the top of the file (up through `makeContainer`) with:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/apply/repository/apply_repository.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/models/applied_change.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/chat/notifiers/code_apply_actions.dart';
import 'package:code_bench_app/features/chat/notifiers/code_apply_failure.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_actions.dart';

// ── Fake ApplyRepository ──────────────────────────────────────────────────────

class _FakeApplyRepository extends Fake implements ApplyRepository {
  Object? _applyError;
  Object? _revertError;
  AppliedChange? _applyResult;

  void throwOnApply(Object error) => _applyError = error;
  void throwOnRevert(Object error) => _revertError = error;
  void returnOnApply(AppliedChange change) => _applyResult = change;

  @override
  Future<AppliedChange> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    if (_applyError != null) throw _applyError!;
    return _applyResult ??
        AppliedChange(
          id: 'fake-id',
          sessionId: sessionId,
          messageId: messageId,
          filePath: filePath,
          originalContent: null,
          newContent: newContent,
          appliedAt: DateTime(2024),
          additions: 0,
          deletions: 0,
        );
  }

  @override
  Future<void> revertChange({
    required AppliedChange change,
    required bool isGit,
    required String projectPath,
  }) async {
    if (_revertError != null) throw _revertError!;
  }

  @override
  Future<String?> readFileContent(String filePath, String projectPath) async {
    try {
      return await File(filePath).readAsString();
    } on IOException {
      return null;
    }
  }

  @override
  Future<String?> readOriginalForDiff(String absolutePath, String projectPath) async => null;

  @override
  Future<bool> isExternallyModified(String filePath, String storedChecksum) async => false;
}

// ── Fake ProjectSidebarActions ────────────────────────────────────────────────

class _FakeProjectSidebarActions extends ProjectSidebarActions {
  int refreshCalls = 0;

  @override
  Future<void> refreshProjectStatus(String id) async {
    refreshCalls++;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

AppliedChange _makeChange() => AppliedChange(
  id: 'id',
  sessionId: 's',
  messageId: 'm',
  filePath: '/p/f.dart',
  originalContent: '',
  newContent: '',
  appliedAt: DateTime(2024),
  additions: 0,
  deletions: 0,
);

void main() {
  late _FakeApplyRepository fakeRepo;
  late _FakeProjectSidebarActions fakeSidebar;

  setUp(() {
    fakeRepo = _FakeApplyRepository();
    fakeSidebar = _FakeProjectSidebarActions();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        applyRepositoryProvider.overrideWithValue(fakeRepo),
        projectSidebarActionsProvider.overrideWith(() => fakeSidebar),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }
```

- [ ] **Step 2: Update the test bodies**

In `applyChange` happy-path test, add a check that `appliedChangesProvider` received the change:

```dart
test('happy path — state becomes AsyncData and change is recorded', () async {
  final c = makeContainer();
  await c.read(codeApplyActionsProvider.notifier).applyChange(
    projectId: 'p',
    filePath: '/p/f.dart',
    projectPath: '/p',
    newContent: 'x',
    sessionId: 's',
    messageId: 'm',
  );
  expect(c.read(codeApplyActionsProvider), isA<AsyncData<void>>());
  // notifier populates appliedChangesProvider with the returned change
  expect(c.read(appliedChangesProvider)['s'], isNotEmpty);
});
```

Replace all remaining references to `applyServiceProvider` with `applyRepositoryProvider`.

- [ ] **Step 3: Run updated tests**

```bash
flutter test test/features/chat/notifiers/code_apply_actions_test.dart
```

Expected: all tests pass.

---

## Task 7: Update `code_diff_provider.dart`

**Files:**
- Modify: `lib/features/chat/notifiers/code_diff_provider.dart`

Replace the static `ApplyService.readOriginalForDiff(...)` call with an instance call via `applyRepositoryProvider`.

- [ ] **Step 1: Update the file**

```dart
// lib/features/chat/notifiers/code_diff_provider.dart
import 'dart:io';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/apply/repository/apply_repository_impl.dart';

part 'code_diff_provider.freezed.dart';
part 'code_diff_provider.g.dart';

@freezed
abstract class DiffResult with _$DiffResult {
  const factory DiffResult({required String? originalContent, required List<Diff> diffs}) = _DiffResult;
}

/// Computes a diff between the on-disk file and [newContent].
/// Returns `null` on any error (outside-project, unreadable file, etc.).
@riverpod
Future<DiffResult?> codeDiff(
  Ref ref, {
  required String absolutePath,
  required String projectPath,
  required String newContent,
}) async {
  try {
    final original = await ref
        .read(applyRepositoryProvider)
        .readOriginalForDiff(absolutePath, projectPath);
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(original ?? '', newContent);
    dmp.diffCleanupSemantic(diffs);
    return DiffResult(originalContent: original, diffs: diffs);
  } on StateError {
    return null;
  } on IOException {
    return null;
  } catch (_) {
    return null;
  }
}
```

- [ ] **Step 2: Run `build_runner`**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `code_diff_provider.g.dart` regenerates cleanly.

---

## Task 8: Update `changes_panel.dart`

**Files:**
- Modify: `lib/features/chat/widgets/changes_panel.dart`

Replace the static `ApplyService.isExternallyModified(...)` call in `initState` with a `ref.read(codeApplyActionsProvider.notifier).isExternallyModified(...)` call. `ConsumerState.initState` has access to `ref` and `ref.read` is allowed there per CLAUDE.md.

- [ ] **Step 1: Update the import and `initState` in `_ChangeEntryState`**

Remove the `import 'apply_service.dart'` line. Update `initState`:

```dart
// Remove this import:
// import '../../../services/apply/apply_service.dart';

// In _ChangeEntryState.initState:
@override
void initState() {
  super.initState();
  final checksum = widget.change.contentChecksum;
  _editedFuture = checksum == null
      ? Future.value(false)
      : ref.read(codeApplyActionsProvider.notifier).isExternallyModified(
          widget.change.filePath,
          checksum,
        );
}
```

- [ ] **Step 2: Verify no remaining `ApplyService` imports in `changes_panel.dart`**

```bash
grep "ApplyService\|apply_service" lib/features/chat/widgets/changes_panel.dart
```

Expected: no output.

---

## Task 9: Fix `ApiKeyTestService` constructor injection

**Files:**
- Modify: `lib/services/api_key_test_service.dart`

The datasource is currently created as a class field. Add a constructor parameter so it can be swapped in tests.

- [ ] **Step 1: Update the file**

```dart
// lib/services/api_key_test_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/ai/datasource/api_key_test_datasource_dio.dart';
import '../data/models/ai_model.dart';

part 'api_key_test_service.g.dart';

@Riverpod(keepAlive: true)
ApiKeyTestService apiKeyTestService(Ref ref) =>
    ApiKeyTestService(datasource: ApiKeyTestDatasourceDio());

/// Validates AI provider credentials and local Ollama connectivity via live
/// HTTP probes. Delegates all Dio usage to [ApiKeyTestDatasourceDio] to keep
/// the service layer clean of direct HTTP instantiation.
class ApiKeyTestService {
  ApiKeyTestService({required ApiKeyTestDatasourceDio datasource})
      : _datasource = datasource;

  final ApiKeyTestDatasourceDio _datasource;

  /// Returns `true` when [key] is accepted by [provider]'s API.
  Future<bool> testApiKey(AIProvider provider, String key) =>
      _datasource.testApiKey(provider, key);

  /// Returns `true` when an Ollama instance is reachable at [url].
  Future<bool> testOllamaUrl(String url) => _datasource.testOllamaUrl(url);
}
```

- [ ] **Step 2: Run `build_runner`**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `api_key_test_service.g.dart` regenerates cleanly.

---

## Task 10: Delete old `apply_service.dart` and verify

**Files:**
- Delete: `lib/services/apply/apply_service.dart`
- Delete: `lib/services/apply/apply_service.g.dart`
- Delete: `test/services/apply/apply_service_test.dart`
- Delete: `test/services/apply/apply_service_checksum_test.dart`

- [ ] **Step 1: Verify no remaining imports of `apply_service.dart`**

```bash
grep -r "apply_service" lib/ test/ --include="*.dart" | grep -v "\.g\.dart"
```

Expected: no output. If there are matches, fix each import before deleting.

- [ ] **Step 2: Delete the old files**

```bash
rm lib/services/apply/apply_service.dart lib/services/apply/apply_service.g.dart
rm test/services/apply/apply_service_test.dart test/services/apply/apply_service_checksum_test.dart
```

- [ ] **Step 3: Run `build_runner` to clean up orphaned generated output**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: no errors.

---

## Task 11: Final verification

- [ ] **Step 1: Format**

```bash
dart format lib/ test/
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 3: Full test suite**

```bash
flutter test
```

Expected: all tests pass, including the new `test/data/apply/` tests.

- [ ] **Step 4: Update `CLAUDE.md`**

In the `## Architecture` section, update the reference from `ApplyService.assertWithinProject` to `ApplyRepository.assertWithinProject`:

```
// Find:
The one exception is `ApplyService.assertWithinProject` (a static security guard), which may be called from widgets...

// Replace with:
The one exception is `ApplyRepository.assertWithinProject` (a static security guard), which may be called from widgets...
```

Also update the `dart:io` exception note to reference `ApplyRepositoryImpl` instead of `ApplyService`.

- [ ] **Step 5: Commit**

```bash
git add lib/data/apply/ lib/services/api_key_test_service.dart \
  lib/features/chat/notifiers/code_apply_actions.dart \
  lib/features/chat/notifiers/code_diff_provider.dart \
  lib/features/chat/widgets/changes_panel.dart \
  test/data/apply/ CLAUDE.md
git rm lib/services/apply/apply_service.dart lib/services/apply/apply_service.g.dart \
  test/services/apply/apply_service_test.dart \
  test/services/apply/apply_service_checksum_test.dart
git commit -m "refactor(di): migrate ApplyService and ApiKeyTestService to hybrid constructor injection"
```
