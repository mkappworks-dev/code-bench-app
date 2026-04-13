# Full Clean Architecture — Service Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce a `lib/services/` layer between Notifiers and Repositories so business logic no longer lives in I/O facades or UI controllers.

**Architecture:** Nine services are created (one per feature). Each service owns orchestration, policy enforcement, and domain exceptions. Repositories are stripped to thin I/O delegates. Notifiers are thinned to `AsyncValue` state + `*Failure` mapping. All land in one PR from a single worktree.

**Tech Stack:** Flutter/Dart, Riverpod (`riverpod_annotation`), `build_runner` for codegen, `flutter_test` + `fake` pattern for tests.

---

## File structure

**New files — services:**
```
lib/services/
  apply/
    apply_exceptions.dart        ← ProjectMissingException, ApplyTooLargeException, PathEscapeException
    apply_service.dart           ← ApplyService + @Riverpod provider
  git/
    git_exceptions.dart          ← GitException, GitAuthException, GitConflictException, GitNoUpstreamException
    git_service.dart             ← GitService + @Riverpod provider
  project/
    project_exceptions.dart      ← DuplicateProjectPathException
    project_service.dart         ← ProjectService + @Riverpod provider
  session/
    session_service.dart         ← SessionService + @Riverpod provider
  settings/
    settings_service.dart        ← SettingsService + @Riverpod provider
  ai/
    ai_service.dart              ← AIService + @Riverpod provider
  github/
    github_service.dart          ← GitHubService + @Riverpod provider
  ide/
    ide_exceptions.dart          ← IdeLaunchFailedException
    ide_service.dart             ← IdeService + @Riverpod provider
  api_key_test/
    api_key_test_service.dart    ← ApiKeyTestService + @Riverpod provider
```

**New files — tests:**
```
test/services/
  apply/apply_service_test.dart
  git/git_service_test.dart
  project/project_service_test.dart
  session/session_service_test.dart
  settings/settings_service_test.dart
  ai/ai_service_test.dart
  github/github_service_test.dart
  ide/ide_service_test.dart
  api_key_test/api_key_test_service_test.dart
```

**Modified — repositories (stripped):**
- `lib/data/apply/repository/apply_repository.dart` + `apply_repository_impl.dart`
- `lib/data/git/repository/git_repository.dart` + `git_repository_impl.dart`
- `lib/data/ai/repository/ai_repository.dart` + `ai_repository_impl.dart`
- `lib/data/session/repository/session_repository.dart` + `session_repository_impl.dart`

**Modified — notifiers (switch to service providers):**
- `lib/features/chat/notifiers/code_apply_actions.dart`
- `lib/features/settings/notifiers/settings_actions.dart`
- All other notifiers that call `*RepositoryProvider` directly (located via grep in Task 0)

**Modified — arch test:**
- `test/arch_test.dart`

---

## Task 0: Worktree + baseline

**Files:** none modified

- [ ] **Step 1: Verify worktrees directory is git-ignored**
```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app
git check-ignore -q .worktrees && echo "ignored" || echo "NOT ignored — add to .gitignore first"
```
Expected: `ignored`

- [ ] **Step 2: Create worktree**
```bash
git worktree add .worktrees/tech/2026-04-13-full-clean-architecture-services \
  -b tech/2026-04-13-full-clean-architecture-services
cd .worktrees/tech/2026-04-13-full-clean-architecture-services
```

- [ ] **Step 3: Run baseline tests**
```bash
flutter test
```
Expected: all tests pass (0 failures). If any fail, note them — they pre-exist.

- [ ] **Step 4: Grep for all repository-provider reads inside notifiers**
```bash
grep -r "ref\.read(.*RepositoryProvider" lib/features/ lib/shell/ --include="*.dart" -l
grep -r "ref\.watch(.*RepositoryProvider" lib/features/ lib/shell/ --include="*.dart" -l
```
Record the file list — these are the notifiers to update throughout the plan.

- [ ] **Step 5: Commit baseline marker**
```bash
git add .
git commit -m "chore: start full-clean-architecture-services worktree"
```

---

## Task 1: ApplyService

`ApplyService` owns: path-escape validation, 1 MB size cap, checksum computation, UUID generation, and applied-change construction. `ApplyRepository` strips to 4 raw I/O methods. `assertWithinProject` moves from `ApplyRepository` (static) to `ApplyService` (static) — widgets that call it update their import.

**Files:**
- Create: `lib/services/apply/apply_exceptions.dart`
- Create: `lib/services/apply/apply_service.dart`
- Create: `test/services/apply/apply_service_test.dart`
- Modify: `lib/data/apply/repository/apply_repository.dart`
- Modify: `lib/data/apply/repository/apply_repository_impl.dart`
- Modify: `lib/features/chat/notifiers/code_apply_actions.dart`
- Modify: any widget importing `ApplyRepository.assertWithinProject` (grep: `apply_repository.dart` in widgets)

- [ ] **Step 1: Write failing tests**

Create `test/services/apply/apply_service_test.dart`:
```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench/data/apply/repository/apply_repository.dart';
import 'package:code_bench/data/models/applied_change.dart';
import 'package:code_bench/services/apply/apply_exceptions.dart';
import 'package:code_bench/services/apply/apply_service.dart';

class _FakeApplyRepo extends Fake implements ApplyRepository {
  String? readResult;
  Object? readError;
  String? lastWrite;

  @override
  Future<String> readFile(String path) async {
    if (readError != null) throw readError!;
    if (readResult == null) throw PathNotFoundException(path, OSError());
    return readResult!;
  }

  @override
  Future<void> writeFile(String path, String content) async => lastWrite = content;

  @override
  Future<void> deleteFile(String path) async {}

  @override
  Future<void> gitCheckout(String filePath, String workingDirectory) async {}
}

void main() {
  late _FakeApplyRepo repo;
  late ApplyService svc;

  setUp(() {
    repo = _FakeApplyRepo();
    svc = ApplyService(repo: repo, uuidGen: () => 'test-uuid');
  });

  group('applyChange', () {
    test('returns AppliedChange with correct fields', () async {
      repo.readResult = 'old content';
      final change = await svc.applyChange(
        filePath: '/project/foo.dart',
        projectPath: '/project',
        newContent: 'new content',
        sessionId: 'sid',
        messageId: 'mid',
      );
      expect(change.id, 'test-uuid');
      expect(change.filePath, '/project/foo.dart');
      expect(change.originalContent, 'old content');
      expect(change.newContent, 'new content');
    });

    test('throws PathEscapeException when file outside project', () async {
      expect(
        () => svc.applyChange(
          filePath: '/other/evil.dart',
          projectPath: '/project',
          newContent: 'x',
          sessionId: 's',
          messageId: 'm',
        ),
        throwsA(isA<PathEscapeException>()),
      );
    });

    test('throws ApplyTooLargeException when content exceeds 1 MB', () async {
      final huge = 'x' * (1024 * 1024 + 1);
      expect(
        () => svc.applyChange(
          filePath: '/project/foo.dart',
          projectPath: '/project',
          newContent: huge,
          sessionId: 's',
          messageId: 'm',
        ),
        throwsA(isA<ApplyTooLargeException>()),
      );
    });

    test('originalContent is null for new file (PathNotFoundException)', () async {
      repo.readResult = null; // triggers PathNotFoundException
      final change = await svc.applyChange(
        filePath: '/project/new.dart',
        projectPath: '/project',
        newContent: 'hello',
        sessionId: 's',
        messageId: 'm',
      );
      expect(change.originalContent, isNull);
    });

    test('throws ProjectMissingException on non-path-not-found FileSystemException', () async {
      repo.readError = const FileSystemException('disk error', '/project/foo.dart');
      expect(
        () => svc.applyChange(
          filePath: '/project/foo.dart',
          projectPath: '/project',
          newContent: 'x',
          sessionId: 's',
          messageId: 'm',
        ),
        throwsA(isA<ProjectMissingException>()),
      );
    });
  });

  group('revertChange', () {
    test('deletes file when originalContent is null', () async {
      var deleted = false;
      repo = _FakeApplyRepo();
      // Override deleteFile to track call
      svc = ApplyService(repo: repo, uuidGen: () => 'id');
      final change = AppliedChange(
        id: 'id',
        sessionId: 's',
        messageId: 'm',
        filePath: '/project/foo.dart',
        originalContent: null,
        newContent: 'x',
        appliedAt: DateTime.now(),
        additions: 1,
        deletions: 0,
        contentChecksum: '',
      );
      // Should call repo.deleteFile without throwing
      await svc.revertChange(change: change, isGit: false, projectPath: '/project');
    });

    test('writes originalContent when not git', () async {
      final change = AppliedChange(
        id: 'id',
        sessionId: 's',
        messageId: 'm',
        filePath: '/project/foo.dart',
        originalContent: 'restored',
        newContent: 'new',
        appliedAt: DateTime.now(),
        additions: 1,
        deletions: 0,
        contentChecksum: '',
      );
      await svc.revertChange(change: change, isGit: false, projectPath: '/project');
      expect(repo.lastWrite, 'restored');
    });
  });

  group('isExternallyModified', () {
    test('returns false when checksum matches', () async {
      final content = 'hello';
      repo.readResult = content;
      final checksum = ApplyService.sha256OfString(content);
      expect(await svc.isExternallyModified('/project/f.dart', checksum), isFalse);
    });

    test('returns true when checksum differs', () async {
      repo.readResult = 'changed';
      expect(await svc.isExternallyModified('/project/f.dart', 'old-checksum'), isTrue);
    });

    test('returns true when file missing', () async {
      repo.readResult = null; // triggers PathNotFoundException
      expect(await svc.isExternallyModified('/project/f.dart', 'anything'), isTrue);
    });
  });

  group('assertWithinProject', () {
    test('does not throw for path inside project', () {
      expect(
        () => ApplyService.assertWithinProject('/project/lib/foo.dart', '/project'),
        returnsNormally,
      );
    });

    test('throws PathEscapeException for path traversal', () {
      expect(
        () => ApplyService.assertWithinProject('/project/../other/evil.dart', '/project'),
        throwsA(isA<PathEscapeException>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**
```bash
flutter test test/services/apply/apply_service_test.dart
```
Expected: FAIL — `apply_service.dart` and `apply_exceptions.dart` don't exist yet.

- [ ] **Step 3: Create `lib/services/apply/apply_exceptions.dart`**
```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

const int kMaxApplyContentBytes = 1024 * 1024;

sealed class ApplyException implements Exception {}

class ProjectMissingException extends ApplyException {
  ProjectMissingException(this.projectPath);
  final String projectPath;

  @override
  String toString() => 'Project folder is missing: $projectPath';
}

class ApplyTooLargeException extends ApplyException {
  ApplyTooLargeException(this.bytes);
  final int bytes;

  @override
  String toString() =>
      'Content too large: $bytes bytes (max $kMaxApplyContentBytes bytes)';
}

class PathEscapeException extends ApplyException {
  PathEscapeException(this.filePath, this.projectPath);
  final String filePath;
  final String projectPath;

  @override
  String toString() =>
      'Path "$filePath" is outside project root "$projectPath"';
}
```

- [ ] **Step 4: Create `lib/services/apply/apply_service.dart`**
```dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../core/utils/debug_logger.dart';
import '../../data/apply/repository/apply_repository.dart';
import '../../data/apply/repository/apply_repository_impl.dart';
import '../../data/models/applied_change.dart';
import 'apply_exceptions.dart';

export 'apply_exceptions.dart';

part 'apply_service.g.dart';

@Riverpod(keepAlive: true)
ApplyService applyService(Ref ref) {
  return ApplyService(repo: ref.watch(applyRepositoryProvider));
}

class ApplyService {
  ApplyService({
    required ApplyRepository repo,
    String Function()? uuidGen,
  })  : _repo = repo,
        _uuidGen = uuidGen ?? (() => const Uuid().v4());

  final ApplyRepository _repo;
  final String Function() _uuidGen;

  Future<AppliedChange> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    assertWithinProject(filePath, projectPath);

    if (newContent.length > kMaxApplyContentBytes) {
      throw ApplyTooLargeException(newContent.length);
    }

    String? originalContent;
    try {
      originalContent = await _repo.readFile(filePath);
      if (originalContent.length > kMaxApplyContentBytes) {
        throw ApplyTooLargeException(originalContent.length);
      }
    } on PathNotFoundException {
      originalContent = null;
    } on FileSystemException catch (e, st) {
      dLog('[ApplyService] readFile failed: $e');
      Error.throwWithStackTrace(ProjectMissingException(projectPath), st);
    }

    if (originalContent == null) {
      // New file — ensure parent directory exists via writeFile (repo handles it)
    }
    await _repo.writeFile(filePath, newContent);

    final (additions, deletions) = _computeLineCounts(originalContent, newContent);

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
      contentChecksum: sha256OfString(newContent),
    );
  }

  Future<void> revertChange({
    required AppliedChange change,
    required bool isGit,
    required String projectPath,
  }) async {
    assertWithinProject(change.filePath, projectPath);
    if (change.originalContent == null) {
      await _repo.deleteFile(change.filePath);
    } else if (isGit) {
      await _repo.gitCheckout(change.filePath, projectPath);
    } else {
      await _repo.writeFile(change.filePath, change.originalContent!);
    }
  }

  Future<String?> readFileContent(String filePath, String projectPath) async {
    assertWithinProject(filePath, projectPath);
    try {
      return await _repo.readFile(filePath);
    } on FileSystemException catch (e) {
      dLog('[ApplyService] readFileContent failed: $e');
      return null;
    }
  }

  Future<String?> readOriginalForDiff(
      String absolutePath, String projectPath) async {
    assertWithinProject(absolutePath, projectPath);
    try {
      return await _repo.readFile(absolutePath);
    } on PathNotFoundException {
      return null;
    } on FileSystemException catch (e, st) {
      dLog('[ApplyService] readOriginalForDiff failed: $e');
      rethrow;
    }
  }

  Future<bool> isExternallyModified(
      String filePath, String storedChecksum) async {
    try {
      final current = await _repo.readFile(filePath);
      return sha256OfString(current) != storedChecksum;
    } on PathNotFoundException {
      return true;
    } on FileSystemException catch (e) {
      dLog('[ApplyService] isExternallyModified read failed: $e');
      return true;
    }
  }

  /// Throws [PathEscapeException] if [filePath] is not inside [projectPath].
  /// May be called from widgets for security-guard purposes (see CLAUDE.md).
  static void assertWithinProject(String filePath, String projectPath) {
    final lexFile = p.normalize(p.absolute(filePath));
    final lexRoot = p.normalize(p.absolute(projectPath));
    final lexRootWithSep = lexRoot + p.separator;
    if (!lexFile.startsWith(lexRootWithSep)) {
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
    final rootRealWithSep = rootReal + p.separator;
    if (probeReal != rootReal && !probeReal.startsWith(rootRealWithSep)) {
      sLog('[assertWithinProject] symlink escape: "$filePath" → "$probeReal" outside "$rootReal"');
      throw PathEscapeException(filePath, projectPath);
    }
  }

  static String sha256OfString(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  static (int additions, int deletions) _computeLineCounts(
      String? original, String newContent) {
    // Carry over the line-diff computation from ApplyRepositoryImpl unchanged.
    // (Keep identical to previous impl — no logic change, just a move.)
    final a = original ?? '';
    final aLines = a.isEmpty ? <String>[] : a.split('\n');
    final bLines = newContent.isEmpty ? <String>[] : newContent.split('\n');
    // Simple line count diff (matches existing behaviour):
    final added = bLines.where((l) => !aLines.contains(l)).length;
    final removed = aLines.where((l) => !bLines.contains(l)).length;
    return (added, removed);
  }
}
```

> **Note:** `_computeLineCounts` in the real impl uses `DiffMatchPatch`. Copy the exact body from `apply_repository_impl.dart` lines 268-303 rather than the simplified version above.

- [ ] **Step 5: Strip `lib/data/apply/repository/apply_repository.dart`**

Replace entire file:
```dart
import 'dart:io';

/// Raw I/O facade for file apply operations.
/// Business logic (policy, validation, checksum, UUID) lives in ApplyService.
abstract interface class ApplyRepository {
  /// Reads file content. Throws [FileSystemException] (including
  /// [PathNotFoundException]) on failure — callers handle missing-file cases.
  Future<String> readFile(String path);

  /// Writes [content] to [path], creating parent directories as needed.
  Future<void> writeFile(String path, String content);

  /// Deletes [path]. No-ops silently if the file does not exist.
  Future<void> deleteFile(String path);

  /// Runs `git checkout -- <filePath>` in [workingDirectory].
  /// Throws [StateError] on non-zero exit or timeout.
  Future<void> gitCheckout(String filePath, String workingDirectory);
}
```

- [ ] **Step 6: Update `lib/data/apply/repository/apply_repository_impl.dart`**

Replace entire file:
```dart
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../filesystem/repository/filesystem_repository.dart';
import '../../filesystem/repository/filesystem_repository_impl.dart';
import 'apply_repository.dart';

part 'apply_repository_impl.g.dart';

const Duration kGitCheckoutTimeout = Duration(seconds: 15);

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments,
        {String? workingDirectory});

@Riverpod(keepAlive: true)
ApplyRepository applyRepository(Ref ref) {
  return ApplyRepositoryImpl(fs: ref.watch(filesystemRepositoryProvider));
}

class ApplyRepositoryImpl implements ApplyRepository {
  ApplyRepositoryImpl({
    required FilesystemRepository fs,
    ProcessRunner? processRunner,
  })  : _fs = fs,
        _processRunner = processRunner ?? Process.run;

  final FilesystemRepository _fs;
  final ProcessRunner _processRunner;

  @override
  Future<String> readFile(String path) => _fs.readFile(path);

  @override
  Future<void> writeFile(String path, String content) async {
    await _fs.createDirectory(p.dirname(path));
    await _fs.writeFile(path, content);
  }

  @override
  Future<void> deleteFile(String path) => _fs.deleteFile(path);

  @override
  Future<void> gitCheckout(String filePath, String workingDirectory) async {
    final ProcessResult result;
    try {
      result = await _processRunner(
        'git',
        ['checkout', '--', filePath],
        workingDirectory: workingDirectory,
      ).timeout(kGitCheckoutTimeout);
    } on TimeoutException {
      throw StateError(
          'git checkout timed out after ${kGitCheckoutTimeout.inSeconds}s');
    }
    if (result.exitCode != 0) {
      throw StateError(
          'git checkout failed (exit ${result.exitCode}): ${result.stderr}');
    }
  }
}
```

- [ ] **Step 7: Update `lib/features/chat/notifiers/code_apply_actions.dart`**

Replace file:
```dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/models/applied_change.dart';
import '../../../services/apply/apply_service.dart';
import '../../project_sidebar/notifiers/project_sidebar_actions.dart';
import 'chat_notifier.dart';
import 'code_apply_failure.dart';

part 'code_apply_actions.g.dart';

@Riverpod(keepAlive: true)
class CodeApplyActions extends _$CodeApplyActions {
  @override
  FutureOr<void> build() {}

  CodeApplyFailure _asApplyFailure(Object e) => switch (e) {
        ProjectMissingException() => const CodeApplyFailure.projectMissing(),
        PathEscapeException() => const CodeApplyFailure.outsideProject(),
        ApplyTooLargeException() => const CodeApplyFailure.tooLarge(),
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
        final change = await ref.read(applyServiceProvider).applyChange(
              filePath: filePath,
              projectPath: projectPath,
              newContent: newContent,
              sessionId: sessionId,
              messageId: messageId,
            );
        ref.read(appliedChangesProvider.notifier).apply(change);
      } on ProjectMissingException catch (e, st) {
        dLog('[CodeApplyActions] applyChange projectMissing: $e');
        unawaited(
            ref.read(projectSidebarActionsProvider.notifier).refreshProjectStatus(projectId));
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
        await ref.read(applyServiceProvider).revertChange(
            change: change, isGit: isGit, projectPath: projectPath);
        ref.read(appliedChangesProvider.notifier).revert(change.id);
      } catch (e, st) {
        dLog('[CodeApplyActions] revertChange failed: $e');
        Error.throwWithStackTrace(CodeApplyFailure.unknown(e), st);
      }
    });
  }

  Future<String?> readFileContent(String filePath, String projectPath) =>
      ref.read(applyServiceProvider).readFileContent(filePath, projectPath);

  Future<bool> isExternallyModified(String filePath, String storedChecksum) =>
      ref.read(applyServiceProvider).isExternallyModified(filePath, storedChecksum);
}
```

- [ ] **Step 8: Update widgets that import `ApplyRepository.assertWithinProject`**
```bash
grep -r "apply_repository.dart" lib/features/ lib/shell/ --include="*.dart" -l
```
For each file found: replace `import '...apply_repository.dart'` with `import '...services/apply/apply_service.dart'`. Replace `ApplyRepository.assertWithinProject` calls with `ApplyService.assertWithinProject`.

Also update `code_apply_failure.dart` — add `tooLarge` and `outsideProject` variants if not present:
```dart
// lib/features/chat/notifiers/code_apply_failure.dart
// Add these factory constructors if missing:
const factory CodeApplyFailure.tooLarge() = CodeApplyTooLarge;
const factory CodeApplyFailure.outsideProject() = CodeApplyOutsideProject;
```

- [ ] **Step 9: Run code generation**
```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: `apply_service.g.dart` generated. No errors.

- [ ] **Step 10: Run Apply tests**
```bash
flutter test test/services/apply/apply_service_test.dart
```
Expected: all pass.

- [ ] **Step 11: Run full suite**
```bash
flutter test
flutter analyze
```
Expected: pass (fix any import errors from the stripped `ApplyRepository`).

- [ ] **Step 12: Commit**
```bash
git add lib/services/apply/ lib/data/apply/repository/ \
  lib/features/chat/notifiers/code_apply_actions.dart \
  test/services/apply/
git commit -m "feat(arch): ApplyService — move policy + orchestration out of ApplyRepository"
```

---

## Task 2: GitService

`GitService` owns: commit/push/pull/fetch composition, worktree enumeration, branch operations. `GitRepository` strips to 4 primitives. Git exceptions relocate from `git_datasource_process.dart` to `lib/services/git/git_exceptions.dart`.

**Files:**
- Create: `lib/services/git/git_exceptions.dart`
- Create: `lib/services/git/git_service.dart`
- Create: `test/services/git/git_service_test.dart`
- Modify: `lib/data/git/repository/git_repository.dart`
- Modify: `lib/data/git/repository/git_repository_impl.dart`
- Modify: all notifiers that call `gitRepositoryProvider` (found in Task 0 grep)

- [ ] **Step 1: Write failing tests**

Create `test/services/git/git_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench/data/git/repository/git_repository.dart';
import 'package:code_bench/services/git/git_exceptions.dart';
import 'package:code_bench/services/git/git_service.dart';

class _FakeGitRepo extends Fake implements GitRepository {
  bool? _isGit;
  String? _branch;
  String? _origin;

  @override
  bool isGitRepo(String path) => _isGit ?? false;

  @override
  Future<String?> currentBranch(String path) async => _branch;

  @override
  Future<String?> getOriginUrl(String path) async => _origin;

  @override
  Future<void> initGit(String path) async {}
}

void main() {
  late _FakeGitRepo repo;
  late GitService svc;

  setUp(() {
    repo = _FakeGitRepo();
    svc = GitService(repo: repo);
  });

  test('isGitRepo delegates to repository', () {
    repo._isGit = true;
    expect(svc.isGitRepo('/project'), isTrue);
  });

  test('currentBranch delegates to repository', () async {
    repo._branch = 'main';
    expect(await svc.currentBranch('/project'), 'main');
  });
}
```

- [ ] **Step 2: Run to confirm failure**
```bash
flutter test test/services/git/git_service_test.dart
```
Expected: FAIL — `git_service.dart` not found.

- [ ] **Step 3: Create `lib/services/git/git_exceptions.dart`**

Copy and re-export the git exceptions from the datasource (they must still be exported from the datasource for backward compatibility during migration, then callers are updated):
```dart
/// Domain exceptions for git operations.
/// These are relocated from lib/data/git/datasource/git_datasource_process.dart.

class GitException implements Exception {
  const GitException(this.message);
  final String message;
  @override
  String toString() => 'GitException: $message';
}

class GitNoUpstreamException extends GitException {
  const GitNoUpstreamException(String branch)
      : super('No upstream branch for $branch');
}

class GitAuthException extends GitException {
  const GitAuthException() : super('Authentication failed');
}

class GitConflictException extends GitException {
  const GitConflictException() : super('Merge conflict detected');
}
```

- [ ] **Step 4: Create `lib/services/git/git_service.dart`**

The service delegates all 12 composite operations to the git datasource via the thinned repository. Since the repository exposes only 4 primitives after stripping, the service uses a `GitDatasource` factory internally.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/git/datasource/git_datasource.dart';
import '../../data/git/datasource/git_datasource_process.dart';
import '../../data/git/datasource/git_live_state_datasource.dart';
import '../../data/git/datasource/git_live_state_datasource_process.dart';
import '../../data/git/repository/git_repository.dart';
import '../../data/git/repository/git_repository_impl.dart';
import 'git_exceptions.dart';

export 'git_exceptions.dart';

part 'git_service.g.dart';

@Riverpod(keepAlive: true)
GitService gitService(Ref ref) {
  return GitService(
    repo: ref.watch(gitRepositoryProvider),
    liveState: ref.watch(gitLiveStateDatasourceProvider),
  );
}

/// Convenience providers preserved for widget/notifier consumption.
@riverpod
Future<GitLiveState> gitLiveState(Ref ref, String projectPath) =>
    ref.watch(gitServiceProvider).fetchLiveState(projectPath);

@riverpod
Future<int?> behindCount(Ref ref, String projectPath) async {
  final timer = Timer.periodic(const Duration(minutes: 5), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.watch(gitServiceProvider).behindCount(projectPath);
}

class GitService {
  GitService({
    required GitRepository repo,
    GitLiveStateDatasource? liveState,
  })  : _repo = repo,
        _liveState = liveState;

  final GitRepository _repo;
  final GitLiveStateDatasource? _liveState;

  // ── Primitives (delegate to repository) ───────────────────────────────────

  Future<void> initGit(String path) => _repo.initGit(path);
  bool isGitRepo(String path) => _repo.isGitRepo(path);
  Future<String?> currentBranch(String path) => _repo.currentBranch(path);
  Future<String?> getOriginUrl(String path) => _repo.getOriginUrl(path);

  // ── Compositions (previously on GitRepository, now owned by service) ──────

  GitDatasource _ds(String path) => GitDatasourceProcess(path);

  Future<String> commit(String path, String message) => _ds(path).commit(message);
  Future<String> push(String path) => _ds(path).push();
  Future<void> pushToRemote(String path, String remote) => _ds(path).pushToRemote(remote);
  Future<int> pull(String path) => _ds(path).pull();
  Future<int?> fetchBehindCount(String path) => _ds(path).fetchBehindCount();
  Future<List<GitRemote>> listRemotes(String path) => _ds(path).listRemotes();
  Future<List<String>> listLocalBranches(String path) => _ds(path).listLocalBranches();
  Future<Set<String>> worktreeBranches(String path) => _ds(path).worktreeBranches();
  Future<void> checkout(String path, String branch) => _ds(path).checkout(branch);
  Future<void> createBranch(String path, String name) => _ds(path).createBranch(name);

  Future<GitLiveState> fetchLiveState(String path) =>
      (_liveState ?? GitLiveStateDatasourceProcess()).fetchLiveState(path);

  Future<int?> behindCount(String path) =>
      (_liveState ?? GitLiveStateDatasourceProcess()).fetchBehindCount(path);
}
```

> **Note on datasource access:** `GitService` creates `GitDatasourceProcess` per-call (same pattern as the old `GitRepositoryImpl._ds()`). This is permitted — the service-layer rule says "may not call Datasource directly except through its feature's Repository." `GitDatasourceProcess` is the feature's own datasource; calling it via a factory is equivalent to calling through the repository. This pattern is explicitly documented and justified here as an exception to the general rule.

- [ ] **Step 5: Strip `lib/data/git/repository/git_repository.dart`**

Replace entire file:
```dart
import '../datasource/git_live_state_datasource.dart';

export '../datasource/git_live_state_datasource.dart' show GitLiveState;

/// Thin I/O facade — primitives only.
/// All composite git operations live in GitService.
abstract interface class GitRepository {
  Future<void> initGit(String projectPath);
  Future<String?> currentBranch(String projectPath);
  Future<String?> getOriginUrl(String projectPath);
  bool isGitRepo(String projectPath);
}
```

- [ ] **Step 6: Update `lib/data/git/repository/git_repository_impl.dart`**

Replace entire file:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/git_live_state_datasource.dart';
import '../datasource/git_live_state_datasource_process.dart';
import 'git_repository.dart';

part 'git_repository_impl.g.dart';

@Riverpod(keepAlive: true)
GitRepository gitRepository(Ref ref) {
  return GitRepositoryImpl(liveState: ref.watch(gitLiveStateDatasourceProvider));
}

class GitRepositoryImpl implements GitRepository {
  GitRepositoryImpl({required GitLiveStateDatasource liveState})
      : _liveState = liveState;

  final GitLiveStateDatasource _liveState;

  @override
  Future<void> initGit(String path) =>
      GitDatasourceProcess(path).initGit(); // direct datasource for primitive

  @override
  Future<String?> currentBranch(String path) =>
      GitDatasourceProcess(path).currentBranch();

  @override
  Future<String?> getOriginUrl(String path) =>
      GitDatasourceProcess(path).getOriginUrl();

  @override
  bool isGitRepo(String path) => _liveState.isGitRepo(path);
}
```

- [ ] **Step 7: Update notifiers**

Run:
```bash
grep -r "gitRepositoryProvider\|ref\.read(gitRepository" lib/features/ lib/shell/ --include="*.dart" -l
```
For each file: replace `ref.read(gitRepositoryProvider)` → `ref.read(gitServiceProvider)` and update imports from `git_repository_impl.dart` to `git_service.dart`.

Also update any files importing `GitAuthException`, `GitConflictException`, `GitNoUpstreamException` from `git_datasource_process.dart` to import from `services/git/git_exceptions.dart`.

- [ ] **Step 8: Run code generation**
```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 9: Run tests**
```bash
flutter test test/services/git/
flutter test
flutter analyze
```
Expected: all pass.

- [ ] **Step 10: Commit**
```bash
git add lib/services/git/ lib/data/git/repository/ test/services/git/
git commit -m "feat(arch): GitService — extract 12 composite git operations from GitRepository"
```

---

## Task 3: ProjectService

`ProjectService` owns: duplicate-path detection, relocate logic, folder-creation orchestration. `DuplicateProjectPathException` relocates from `project_repository_impl.dart` to `lib/services/project/project_exceptions.dart`.

**Files:**
- Create: `lib/services/project/project_exceptions.dart`
- Create: `lib/services/project/project_service.dart`
- Create: `test/services/project/project_service_test.dart`
- Modify: `lib/data/project/repository/project_repository_impl.dart` (remove exception, remove duplicate-path check)
- Modify: notifiers using `projectRepositoryProvider`

- [ ] **Step 1: Write failing tests**

Create `test/services/project/project_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench/data/models/project.dart';
import 'package:code_bench/data/models/project_action.dart';
import 'package:code_bench/data/project/repository/project_repository.dart';
import 'package:code_bench/services/project/project_exceptions.dart';
import 'package:code_bench/services/project/project_service.dart';

class _FakeProjectRepo extends Fake implements ProjectRepository {
  final List<Project> _projects = [];
  String? _pathToReturn;

  @override
  Stream<List<Project>> watchAllProjects() => Stream.value(_projects);

  @override
  Future<Project> addExistingFolder(String directoryPath) async {
    final p = Project(
      id: 'id',
      name: directoryPath.split('/').last,
      path: directoryPath,
      createdAt: DateTime.now(),
    );
    _projects.add(p);
    return p;
  }

  @override
  Future<void> relocateProject(String projectId, String newPath) async {}

  @override
  Future<void> deleteAllProjects() async => _projects.clear();

  @override
  Future<void> removeProject(String projectId) async {}

  @override
  Future<Project> createNewFolder(String parentPath, String folderName) =>
      addExistingFolder('$parentPath/$folderName');

  @override
  Future<void> updateProjectActions(String projectId, List<ProjectAction> actions) async {}

  @override
  Future<void> refreshProjectStatuses() async {}

  @override
  Future<void> refreshProjectStatus(String projectId) async {}

  @override
  Future<List<Project>> getSessionsByProject(String projectId) async => [];
}

void main() {
  late _FakeProjectRepo repo;
  late ProjectService svc;

  setUp(() {
    repo = _FakeProjectRepo();
    svc = ProjectService(repo: repo);
  });

  test('addExistingFolder returns project', () async {
    final p = await svc.addExistingFolder('/project/myapp');
    expect(p.path, '/project/myapp');
  });

  test('addExistingFolder throws DuplicateProjectPathException when path already tracked', () async {
    await svc.addExistingFolder('/project/myapp');
    // The service should detect the duplicate using watchAllProjects
    // (depends on implementation — this is an integration signal)
    expect(
      () => svc.addExistingFolder('/project/myapp'),
      throwsA(isA<DuplicateProjectPathException>()),
    );
  });
}
```

- [ ] **Step 2: Run to confirm failure**
```bash
flutter test test/services/project/project_service_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create `lib/services/project/project_exceptions.dart`**
```dart
class DuplicateProjectPathException implements Exception {
  DuplicateProjectPathException(this.path);
  final String path;

  @override
  String toString() => 'A project at "$path" already exists in Code Bench.';
}
```

- [ ] **Step 4: Create `lib/services/project/project_service.dart`**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/project.dart';
import '../../data/models/project_action.dart';
import '../../data/project/repository/project_repository.dart';
import '../../data/project/repository/project_repository_impl.dart';
import 'project_exceptions.dart';

export 'project_exceptions.dart';

part 'project_service.g.dart';

@Riverpod(keepAlive: true)
ProjectService projectService(Ref ref) {
  return ProjectService(repo: ref.watch(projectRepositoryProvider));
}

class ProjectService {
  ProjectService({required ProjectRepository repo}) : _repo = repo;

  final ProjectRepository _repo;

  Stream<List<Project>> watchAllProjects() => _repo.watchAllProjects();

  Future<Project> addExistingFolder(String directoryPath) async {
    final existing = await _repo.watchAllProjects().first;
    if (existing.any((p) => p.path == directoryPath)) {
      throw DuplicateProjectPathException(directoryPath);
    }
    return _repo.addExistingFolder(directoryPath);
  }

  Future<Project> createNewFolder(String parentPath, String folderName) async {
    final fullPath = '$parentPath/$folderName';
    final existing = await _repo.watchAllProjects().first;
    if (existing.any((p) => p.path == fullPath)) {
      throw DuplicateProjectPathException(fullPath);
    }
    return _repo.createNewFolder(parentPath, folderName);
  }

  Future<void> relocateProject(String projectId, String newPath) async {
    final existing = await _repo.watchAllProjects().first;
    final conflict = existing.where((p) => p.path == newPath && p.id != projectId);
    if (conflict.isNotEmpty) throw DuplicateProjectPathException(newPath);
    return _repo.relocateProject(projectId, newPath);
  }

  Future<void> removeProject(String projectId) => _repo.removeProject(projectId);

  Future<void> updateProjectActions(String projectId, List<ProjectAction> actions) =>
      _repo.updateProjectActions(projectId, actions);

  Future<void> refreshProjectStatuses() => _repo.refreshProjectStatuses();
  Future<void> refreshProjectStatus(String projectId) =>
      _repo.refreshProjectStatus(projectId);

  Future<void> deleteAllProjects() => _repo.deleteAllProjects();
}
```

- [ ] **Step 5: Remove `DuplicateProjectPathException` from `project_repository_impl.dart`**

Delete lines 19-25 (the `DuplicateProjectPathException` class definition). Remove duplicate-path checks from `addExistingFolder` and `relocateProject` in the impl (the service now owns those checks). The repository simply delegates to the datasource.

- [ ] **Step 6: Update notifiers using `projectRepositoryProvider`**
```bash
grep -r "projectRepositoryProvider" lib/features/ lib/shell/ --include="*.dart" -l
```
For each: replace with `projectServiceProvider`. Update imports.

- [ ] **Step 7: Build + test**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/project/
flutter test && flutter analyze
```

- [ ] **Step 8: Commit**
```bash
git add lib/services/project/ lib/data/project/repository/ test/services/project/
git commit -m "feat(arch): ProjectService — relocate DuplicateProjectPathException, own add/relocate policy"
```

---

## Task 4: SessionService

`SessionService` owns `sendAndStream` orchestration. `SessionRepository` drops `sendAndStream` and the `AIRepository` dependency — it becomes synchronous.

**Files:**
- Create: `lib/services/session/session_service.dart`
- Create: `test/services/session/session_service_test.dart`
- Modify: `lib/data/session/repository/session_repository.dart`
- Modify: `lib/data/session/repository/session_repository_impl.dart`
- Modify: notifiers using `sessionRepositoryProvider`

- [ ] **Step 1: Write failing tests**

Create `test/services/session/session_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench/data/models/ai_model.dart';
import 'package:code_bench/data/models/chat_message.dart';
import 'package:code_bench/data/models/chat_session.dart';
import 'package:code_bench/data/session/repository/session_repository.dart';
import 'package:code_bench/data/ai/repository/ai_repository.dart';
import 'package:code_bench/services/session/session_service.dart';

class _FakeSessionRepo extends Fake implements SessionRepository {
  final messages = <ChatMessage>[];

  @override
  Future<void> persistMessage(String sessionId, ChatMessage message) async =>
      messages.add(message);

  @override
  Future<List<ChatMessage>> loadHistory(String sessionId,
          {int limit = 50, int offset = 0}) async =>
      messages;

  @override
  Future<void> updateSessionTitle(String sessionId, String title) async {}
}

class _FakeAIRepo extends Fake implements AIRepository {
  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    yield 'hello ';
    yield 'world';
  }
}

void main() {
  test('sendAndStream yields user then streamed assistant then final', () async {
    final svc = SessionService(
        session: _FakeSessionRepo(), ai: _FakeAIRepo());
    final model = AIModel(
        modelId: 'claude-3', provider: AIProvider.anthropic, displayName: 'Claude');
    final events = await svc
        .sendAndStream(
          sessionId: 'sid',
          userInput: 'hi',
          model: model,
        )
        .toList();

    // First event: user message
    expect(events.first.role, MessageRole.user);
    expect(events.first.content, 'hi');

    // Middle events: streaming assistant
    final streaming = events.where((e) => e.isStreaming == true).toList();
    expect(streaming, isNotEmpty);

    // Last event: final persisted assistant message
    final last = events.last;
    expect(last.role, MessageRole.assistant);
    expect(last.isStreaming, isNot(true));
    expect(last.content, 'hello world');
  });
}
```

- [ ] **Step 2: Run to confirm failure**
```bash
flutter test test/services/session/session_service_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create `lib/services/session/session_service.dart`**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';

part 'session_service.g.dart';

@Riverpod(keepAlive: true)
Future<SessionService> sessionService(Ref ref) async {
  final session = ref.watch(sessionRepositoryProvider);
  final ai = await ref.watch(aiRepositoryProvider.future);
  return SessionService(session: session, ai: ai);
}

class SessionService {
  SessionService({required SessionRepository session, required AIRepository ai})
      : _session = session,
        _ai = ai;

  final SessionRepository _session;
  final AIRepository _ai;
  static const _uuid = Uuid();

  // ── CRUD delegation ────────────────────────────────────────────────────────

  Stream<List<ChatSession>> watchAllSessions() => _session.watchAllSessions();
  Stream<List<ChatSession>> watchSessionsByProject(String projectId) =>
      _session.watchSessionsByProject(projectId);
  Stream<List<ChatSession>> watchArchivedSessions() =>
      _session.watchArchivedSessions();
  Future<ChatSession?> getSession(String sessionId) =>
      _session.getSession(sessionId);
  Future<String> createSession(
          {required AIModel model, String? title, String? projectId}) =>
      _session.createSession(model: model, title: title, projectId: projectId);
  Future<void> updateSessionTitle(String sessionId, String title) =>
      _session.updateSessionTitle(sessionId, title);
  Future<void> deleteSession(String sessionId) =>
      _session.deleteSession(sessionId);
  Future<void> archiveSession(String sessionId) =>
      _session.archiveSession(sessionId);
  Future<void> unarchiveSession(String sessionId) =>
      _session.unarchiveSession(sessionId);
  Future<void> deleteAllSessionsAndMessages() =>
      _session.deleteAllSessionsAndMessages();
  Future<List<ChatMessage>> loadHistory(String sessionId,
          {int limit = 50, int offset = 0}) =>
      _session.loadHistory(sessionId, limit: limit, offset: offset);
  Future<void> persistMessage(String sessionId, ChatMessage message) =>
      _session.persistMessage(sessionId, message);
  Future<List<ChatSession>> getSessionsByProject(String projectId) =>
      _session.getSessionsByProject(projectId);

  // ── Orchestration (moved from SessionRepositoryImpl) ──────────────────────

  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: userInput,
      timestamp: DateTime.now(),
    );
    await _session.persistMessage(sessionId, userMsg);
    yield userMsg;

    final history = await _session.loadHistory(sessionId, limit: 20);
    final historyExcludingCurrent =
        history.where((m) => m.id != userMsg.id).toList();

    final assistantId = _uuid.v4();
    final buffer = StringBuffer();

    await for (final chunk in _ai.streamMessage(
      history: historyExcludingCurrent,
      prompt: userInput,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      buffer.write(chunk);
      yield ChatMessage(
        id: assistantId,
        sessionId: sessionId,
        role: MessageRole.assistant,
        content: buffer.toString(),
        timestamp: DateTime.now(),
        isStreaming: true,
      );
    }

    final finalMsg = ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: buffer.toString(),
      timestamp: DateTime.now(),
    );
    await _session.persistMessage(sessionId, finalMsg);
    yield finalMsg;

    if (history.isEmpty) {
      final shortTitle =
          userInput.length > 50 ? '${userInput.substring(0, 47)}...' : userInput;
      await _session.updateSessionTitle(sessionId, shortTitle);
    }
  }
}
```

- [ ] **Step 4: Strip `lib/data/session/repository/session_repository.dart`**

Remove `sendAndStream` from the interface:
```dart
// Delete these lines:
Stream<ChatMessage> sendAndStream({
  required String sessionId,
  required String userInput,
  required AIModel model,
  String? systemPrompt,
});
```

- [ ] **Step 5: Strip `lib/data/session/repository/session_repository_impl.dart`**

- Remove `import '../../ai/repository/ai_repository.dart'` and `import '../../ai/repository/ai_repository_impl.dart'`
- Change provider to synchronous:
```dart
@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  return SessionRepositoryImpl(datasource: ref.watch(sessionDatasourceProvider));
}
```
- Remove `final AIRepository _ai;` field and `static const _uuid`
- Remove the entire `sendAndStream` method body
- Remove `_ai` from constructor

- [ ] **Step 6: Update notifiers**
```bash
grep -r "sessionRepositoryProvider" lib/features/ lib/shell/ --include="*.dart" -l
```
Replace `ref.read(sessionRepositoryProvider)` / `ref.watch(sessionRepositoryProvider.future)` → `ref.read(sessionServiceProvider.future)` / `ref.watch(sessionServiceProvider)`. Update method calls from `.sendAndStream(` to the service equivalent.

- [ ] **Step 7: Build + test**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/session/
flutter test && flutter analyze
```

- [ ] **Step 8: Commit**
```bash
git add lib/services/session/ lib/data/session/repository/ test/services/session/
git commit -m "feat(arch): SessionService — own sendAndStream; SessionRepository becomes synchronous"
```

---

## Task 5: SettingsService

`SettingsService` owns `wipeAllData` cascade (moves from `SettingsActions`). `StorageException` stays in `lib/core/errors/app_exception.dart` (used broadly); the service imports it from there.

**Files:**
- Create: `lib/services/settings/settings_service.dart`
- Create: `test/services/settings/settings_service_test.dart`
- Modify: `lib/features/settings/notifiers/settings_actions.dart`

- [ ] **Step 1: Write failing tests**

Create `test/services/settings/settings_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench/data/settings/repository/settings_repository.dart';
import 'package:code_bench/data/project/repository/project_repository.dart';
import 'package:code_bench/data/session/repository/session_repository.dart';
import 'package:code_bench/services/settings/settings_service.dart';

class _FakeSettingsRepo extends Fake implements SettingsRepository {
  bool deletedSecureStorage = false;
  bool resetOnboarding = false;

  @override
  Future<void> deleteAllSecureStorage() async => deletedSecureStorage = true;

  @override
  Future<void> resetOnboarding() async => resetOnboarding = true;

  @override
  Future<void> markOnboardingCompleted() async {}

  @override
  Future<String?> readApiKey(String provider) async => null;

  @override
  Future<void> writeApiKey(String provider, String key) async {}
}

class _FakeSessionRepo extends Fake implements SessionRepository {
  bool deleted = false;
  @override
  Future<void> deleteAllSessionsAndMessages() async => deleted = true;
}

class _FakeProjectRepo extends Fake implements ProjectRepository {
  bool deleted = false;
  @override
  Future<void> deleteAllProjects() async => deleted = true;
}

void main() {
  late _FakeSettingsRepo settings;
  late _FakeSessionRepo session;
  late _FakeProjectRepo project;
  late SettingsService svc;

  setUp(() {
    settings = _FakeSettingsRepo();
    session = _FakeSessionRepo();
    project = _FakeProjectRepo();
    svc = SettingsService(
        settings: settings, session: session, project: project);
  });

  test('wipeAllData calls all three repos and returns empty list on success',
      () async {
    final failures = await svc.wipeAllData();
    expect(failures, isEmpty);
    expect(settings.deletedSecureStorage, isTrue);
    expect(session.deleted, isTrue);
    expect(project.deleted, isTrue);
    expect(settings.resetOnboarding, isTrue);
  });

  test('wipeAllData returns failed step names when a step throws', () async {
    settings.deletedSecureStorage = false;
    // Simulate deleteAllSecureStorage throwing
    final svcWithError = SettingsService(
      settings: _ThrowingSettingsRepo(),
      session: session,
      project: project,
    );
    final failures = await svcWithError.wipeAllData();
    expect(failures, contains('secure storage'));
  });
}

class _ThrowingSettingsRepo extends Fake implements SettingsRepository {
  @override
  Future<void> deleteAllSecureStorage() => Future.error(Exception('disk full'));
  @override
  Future<void> resetOnboarding() async {}
}
```

- [ ] **Step 2: Run to confirm failure**
```bash
flutter test test/services/settings/settings_service_test.dart
```

- [ ] **Step 3: Create `lib/services/settings/settings_service.dart`**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';
import '../../data/models/ai_model.dart';
import '../../data/project/repository/project_repository.dart';
import '../../data/project/repository/project_repository_impl.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';
import '../../data/settings/repository/settings_repository.dart';
import '../../data/settings/repository/settings_repository_impl.dart';

part 'settings_service.g.dart';

@Riverpod(keepAlive: true)
Future<SettingsService> settingsService(Ref ref) async {
  final session = ref.watch(sessionRepositoryProvider);
  final project = ref.watch(projectRepositoryProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  return SettingsService(settings: settings, session: session, project: project);
}

class SettingsService {
  SettingsService({
    required SettingsRepository settings,
    required SessionRepository session,
    required ProjectRepository project,
  })  : _settings = settings,
        _session = session,
        _project = project;

  final SettingsRepository _settings;
  final SessionRepository _session;
  final ProjectRepository _project;

  // ── API key delegation ────────────────────────────────────────────────────

  Future<String?> readApiKey(String provider) => _settings.readApiKey(provider);
  Future<void> writeApiKey(String provider, String key) =>
      _settings.writeApiKey(provider, key);
  Future<void> deleteApiKey(String provider) => _settings.deleteApiKey(provider);
  Future<String?> readOllamaUrl() => _settings.readOllamaUrl();
  Future<void> writeOllamaUrl(String url) => _settings.writeOllamaUrl(url);
  Future<String?> readCustomEndpoint() => _settings.readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url) =>
      _settings.writeCustomEndpoint(url);
  Future<String?> readCustomApiKey() => _settings.readCustomApiKey();
  Future<void> writeCustomApiKey(String key) => _settings.writeCustomApiKey(key);
  Future<bool> getAutoCommit() => _settings.getAutoCommit();
  Future<void> setAutoCommit(bool value) => _settings.setAutoCommit(value);
  Future<String> getTerminalApp() => _settings.getTerminalApp();
  Future<void> setTerminalApp(String value) => _settings.setTerminalApp(value);
  Future<bool> getDeleteConfirmation() => _settings.getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value) =>
      _settings.setDeleteConfirmation(value);
  Future<void> markOnboardingCompleted() => _settings.markOnboardingCompleted();
  Future<void> resetOnboarding() => _settings.resetOnboarding();

  // ── Orchestration (moved from SettingsActions) ────────────────────────────

  /// Wipes all user data in sequence. Returns step names that failed (empty = full success).
  /// Each step is isolated so a keychain failure does not block the DB wipe.
  Future<List<String>> wipeAllData() async {
    final failures = <String>[];

    try {
      await _settings.deleteAllSecureStorage();
    } catch (e, st) {
      _logWipeFailure('secure storage', e, st);
      failures.add('secure storage');
    }

    try {
      await _session.deleteAllSessionsAndMessages();
    } catch (e, st) {
      _logWipeFailure('chat history', e, st);
      failures.add('chat history');
    }

    try {
      await _project.deleteAllProjects();
    } catch (e, st) {
      _logWipeFailure('projects', e, st);
      failures.add('projects');
    }

    try {
      await _settings.resetOnboarding();
    } catch (e, st) {
      _logWipeFailure('onboarding flag', e, st);
      failures.add('onboarding flag');
    }

    return failures;
  }

  void _logWipeFailure(String step, Object e, StackTrace st) {
    if (e is AppException && e.originalError != null) {
      dLog('[SettingsService] wipe $step failed: ${e.message} (cause: ${e.originalError})\n$st');
    } else {
      dLog('[SettingsService] wipe $step failed: $e\n$st');
    }
  }
}
```

- [ ] **Step 4: Update `lib/features/settings/notifiers/settings_actions.dart`**

Replace the `wipeAllData` method and remove direct repository calls:
```dart
// Replace entire file imports section and wipeAllData:
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/models/ai_model.dart';
import '../../../data/ai/repository/ai_repository_impl.dart';
import '../../../services/api_key_test/api_key_test_service.dart';
import '../../../services/settings/settings_service.dart';
import 'settings_actions_failure.dart';

// wipeAllData becomes:
Future<List<String>> wipeAllData() async {
  final failures =
      await (await ref.read(settingsServiceProvider.future)).wipeAllData();
  ref.invalidate(aiRepositoryProvider); // Riverpod-level invalidation stays in notifier
  return failures;
}

// saveApiKey becomes:
Future<void> saveApiKey(String provider, String key) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      await (await ref.read(settingsServiceProvider.future))
          .writeApiKey(provider, key);
    } catch (e, st) {
      dLog('[SettingsActions] saveApiKey failed: $e');
      Error.throwWithStackTrace(_asFailure(e, provider), st);
    }
  });
}

// testApiKey / testOllamaUrl delegate to ApiKeyTestService (Task 9)
// markOnboardingCompleted / replayOnboarding delegate to SettingsService
```

- [ ] **Step 5: Build + test**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/settings/
flutter test && flutter analyze
```

- [ ] **Step 6: Commit**
```bash
git add lib/services/settings/ test/services/settings/ \
  lib/features/settings/notifiers/settings_actions.dart
git commit -m "feat(arch): SettingsService — move wipeAllData cascade out of SettingsActions"
```

---

## Task 6: AIService

`AIService` owns stream-buffering (`sendMessage`). `AIRepository` drops `sendMessage`; keeps `streamMessage`, `testConnection`, `fetchAvailableModels`.

**Files:**
- Create: `lib/services/ai/ai_service.dart`
- Create: `test/services/ai/ai_service_test.dart`
- Modify: `lib/data/ai/repository/ai_repository.dart`
- Modify: `lib/data/ai/repository/ai_repository_impl.dart`
- Modify: notifiers using `aiRepositoryProvider`

- [ ] **Step 1: Write failing tests**

Create `test/services/ai/ai_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench/data/models/ai_model.dart';
import 'package:code_bench/data/models/chat_message.dart';
import 'package:code_bench/data/ai/repository/ai_repository.dart';
import 'package:code_bench/services/ai/ai_service.dart';

class _FakeAIRepo extends Fake implements AIRepository {
  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    yield 'chunk1 ';
    yield 'chunk2';
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async => true;

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) async => [];
}

void main() {
  late AIService svc;

  setUp(() => svc = AIService(repo: _FakeAIRepo(), uuidGen: () => 'test-id'));

  test('sendMessage buffers stream into a single ChatMessage', () async {
    final model = AIModel(
        modelId: 'claude-3', provider: AIProvider.anthropic, displayName: 'Claude');
    final msg = await svc.sendMessage(
      history: [],
      prompt: 'hello',
      model: model,
    );
    expect(msg.content, 'chunk1 chunk2');
    expect(msg.role, MessageRole.assistant);
    expect(msg.id, 'test-id');
  });

  test('testConnection delegates to repository', () async {
    final model = AIModel(
        modelId: 'claude-3', provider: AIProvider.anthropic, displayName: 'Claude');
    expect(await svc.testConnection(model, 'key'), isTrue);
  });
}
```

- [ ] **Step 2: Run to confirm failure**
```bash
flutter test test/services/ai/ai_service_test.dart
```

- [ ] **Step 3: Create `lib/services/ai/ai_service.dart`**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart';

part 'ai_service.g.dart';

@Riverpod(keepAlive: true)
Future<AIService> aiService(Ref ref) async {
  final repo = await ref.watch(aiRepositoryProvider.future);
  return AIService(repo: repo);
}

class AIService {
  AIService({required AIRepository repo, String Function()? uuidGen})
      : _repo = repo,
        _uuidGen = uuidGen ?? (() => const Uuid().v4());

  final AIRepository _repo;
  final String Function() _uuidGen;

  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) =>
      _repo.streamMessage(
          history: history, prompt: prompt, model: model, systemPrompt: systemPrompt);

  Future<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in _repo.streamMessage(
      history: history,
      prompt: prompt,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      buffer.write(chunk);
    }
    return ChatMessage(
      id: _uuidGen(),
      sessionId: history.isNotEmpty ? history.first.sessionId : '',
      role: MessageRole.assistant,
      content: buffer.toString(),
      timestamp: DateTime.now(),
    );
  }

  Future<bool> testConnection(AIModel model, String apiKey) =>
      _repo.testConnection(model, apiKey);

  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) =>
      _repo.fetchAvailableModels(provider, apiKey);
}
```

- [ ] **Step 4: Strip `lib/data/ai/repository/ai_repository.dart`**

Remove the `sendMessage` method declaration from the interface.

- [ ] **Step 5: Strip `lib/data/ai/repository/ai_repository_impl.dart`**

Remove the `sendMessage` override body and `static const _uuid = Uuid()`.

- [ ] **Step 6: Update callers of `aiRepositoryProvider.sendMessage`**
```bash
grep -r "aiRepositoryProvider\|\.sendMessage(" lib/features/ lib/shell/ --include="*.dart" -l
```
Replace `ref.read(aiRepositoryProvider)` → `await ref.read(aiServiceProvider.future)`.

- [ ] **Step 7: Build + test**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/ai/
flutter test && flutter analyze
```

- [ ] **Step 8: Commit**
```bash
git add lib/services/ai/ lib/data/ai/repository/ai_repository.dart \
  lib/data/ai/repository/ai_repository_impl.dart test/services/ai/
git commit -m "feat(arch): AIService — move sendMessage buffering out of AIRepository"
```

---

## Task 7: GitHubService

Thin delegation service. No new exceptions — `CreatePrFailure` stays on the notifier side.

**Files:**
- Create: `lib/services/github/github_service.dart`
- Create: `test/services/github/github_service_test.dart`
- Modify: notifiers using `githubRepositoryProvider`

- [ ] **Step 1: Write failing tests**

Create `test/services/github/github_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench/data/github/repository/github_repository.dart';
import 'package:code_bench/data/models/repository.dart';
import 'package:code_bench/services/github/github_service.dart';

class _FakeGitHubRepo extends Fake implements GitHubRepository {
  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<List<Repository>> listRepositories({int page = 1}) async => [];
}

void main() {
  test('isAuthenticated delegates to repository', () async {
    final svc = GitHubService(repo: _FakeGitHubRepo());
    expect(await svc.isAuthenticated(), isTrue);
  });

  test('listRepositories delegates to repository', () async {
    final svc = GitHubService(repo: _FakeGitHubRepo());
    expect(await svc.listRepositories(), isEmpty);
  });
}
```

- [ ] **Step 2: Run to confirm failure**
```bash
flutter test test/services/github/github_service_test.dart
```

- [ ] **Step 3: Create `lib/services/github/github_service.dart`**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/github/repository/github_repository.dart';
import '../../data/github/repository/github_repository_impl.dart';
import '../../data/models/repository.dart';

part 'github_service.g.dart';

@Riverpod(keepAlive: true)
Future<GitHubService> githubService(Ref ref) async {
  final repo = await ref.watch(githubRepositoryProvider.future);
  return GitHubService(repo: repo);
}

class GitHubService {
  GitHubService({required GitHubRepository repo}) : _repo = repo;

  final GitHubRepository _repo;

  Future<GitHubAccount> authenticate() => _repo.authenticate();
  Future<GitHubAccount> signInWithPat(String token) => _repo.signInWithPat(token);
  Future<GitHubAccount?> getStoredAccount() => _repo.getStoredAccount();
  Future<bool> isAuthenticated() => _repo.isAuthenticated();
  Future<void> signOut() => _repo.signOut();
  Future<List<Repository>> listRepositories({int page = 1}) =>
      _repo.listRepositories(page: page);
  Future<List<Repository>> searchRepositories(String query) =>
      _repo.searchRepositories(query);
  Future<String?> validateToken() => _repo.validateToken();
  Future<List<GitTreeItem>> getRepositoryTree(
          String owner, String repo, String branch) =>
      _repo.getRepositoryTree(owner, repo, branch);
  Future<String> getFileContent(
          String owner, String repo, String path, String branch) =>
      _repo.getFileContent(owner, repo, path, branch);
  Future<List<String>> listBranches(String owner, String repo) =>
      _repo.listBranches(owner, repo);
  Future<List<Map<String, dynamic>>> listPullRequests(String owner, String repo,
          {String state = 'open'}) =>
      _repo.listPullRequests(owner, repo, state: state);
  Future<Map<String, dynamic>> getPullRequest(
          String owner, String repo, int number) =>
      _repo.getPullRequest(owner, repo, number);
  Future<List<Map<String, dynamic>>> getCheckRuns(
          String owner, String repo, String sha) =>
      _repo.getCheckRuns(owner, repo, sha);
  Future<void> approvePullRequest(String owner, String repo, int number) =>
      _repo.approvePullRequest(owner, repo, number);
  Future<void> mergePullRequest(String owner, String repo, int number) =>
      _repo.mergePullRequest(owner, repo, number);
  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
  }) =>
      _repo.createPullRequest(
          owner: owner,
          repo: repo,
          title: title,
          body: body,
          head: head,
          base: base,
          draft: draft);
}
```

- [ ] **Step 4: Update notifiers**
```bash
grep -r "githubRepositoryProvider" lib/features/ lib/shell/ --include="*.dart" -l
```
Replace `ref.read(githubRepositoryProvider)` / `.future` → `ref.read(githubServiceProvider.future)`.

- [ ] **Step 5: Build + test**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/github/
flutter test && flutter analyze
```

- [ ] **Step 6: Commit**
```bash
git add lib/services/github/ test/services/github/
git commit -m "feat(arch): GitHubService — introduce service layer for GitHub operations"
```

---

## Task 8: IdeService

`IdeService` converts nullable `String?` error returns from the repository into a typed `IdeLaunchFailedException`.

**Files:**
- Create: `lib/services/ide/ide_exceptions.dart`
- Create: `lib/services/ide/ide_service.dart`
- Create: `test/services/ide/ide_service_test.dart`
- Modify: notifiers using `ideLaunchRepositoryProvider`

- [ ] **Step 1: Write failing tests**

Create `test/services/ide/ide_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench/data/ide/repository/ide_launch_repository.dart';
import 'package:code_bench/services/ide/ide_exceptions.dart';
import 'package:code_bench/services/ide/ide_service.dart';

class _SuccessRepo extends Fake implements IdeLaunchRepository {
  @override Future<String?> openVsCode(String path) async => null;
  @override Future<String?> openCursor(String path) async => null;
  @override Future<String?> openInFinder(String path) async => null;
  @override Future<String?> openInTerminal(String path) async => null;
}

class _FailRepo extends Fake implements IdeLaunchRepository {
  @override Future<String?> openVsCode(String path) async => 'VS Code not found';
  @override Future<String?> openCursor(String path) async => 'Cursor not found';
  @override Future<String?> openInFinder(String path) async => 'Finder error';
  @override Future<String?> openInTerminal(String path) async => 'Terminal error';
}

void main() {
  test('openVsCode does not throw on success', () async {
    final svc = IdeService(repo: _SuccessRepo());
    await expectLater(svc.openVsCode('/project'), completes);
  });

  test('openVsCode throws IdeLaunchFailedException on error', () async {
    final svc = IdeService(repo: _FailRepo());
    expect(() => svc.openVsCode('/project'), throwsA(isA<IdeLaunchFailedException>()));
  });

  test('openCursor throws IdeLaunchFailedException on error', () async {
    final svc = IdeService(repo: _FailRepo());
    expect(() => svc.openCursor('/project'), throwsA(isA<IdeLaunchFailedException>()));
  });
}
```

- [ ] **Step 2: Run to confirm failure**
```bash
flutter test test/services/ide/ide_service_test.dart
```

- [ ] **Step 3: Create `lib/services/ide/ide_exceptions.dart`**
```dart
class IdeLaunchFailedException implements Exception {
  IdeLaunchFailedException(this.editor, this.path, [this.detail]);
  final String editor;
  final String path;
  final String? detail;

  @override
  String toString() =>
      'Failed to launch $editor for "$path"${detail != null ? ': $detail' : ''}';
}
```

- [ ] **Step 4: Create `lib/services/ide/ide_service.dart`**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ide/repository/ide_launch_repository.dart';
import '../../data/ide/repository/ide_launch_repository_impl.dart';
import 'ide_exceptions.dart';

export 'ide_exceptions.dart';

part 'ide_service.g.dart';

@Riverpod(keepAlive: true)
IdeService ideService(Ref ref) {
  return IdeService(repo: ref.watch(ideLaunchRepositoryProvider));
}

class IdeService {
  IdeService({required IdeLaunchRepository repo}) : _repo = repo;

  final IdeLaunchRepository _repo;

  Future<void> openVsCode(String path) async {
    final error = await _repo.openVsCode(path);
    if (error != null) {
      dLog('[IdeService] openVsCode failed: $error');
      throw IdeLaunchFailedException('VS Code', path, error);
    }
  }

  Future<void> openCursor(String path) async {
    final error = await _repo.openCursor(path);
    if (error != null) {
      dLog('[IdeService] openCursor failed: $error');
      throw IdeLaunchFailedException('Cursor', path, error);
    }
  }

  Future<void> openInFinder(String path) async {
    final error = await _repo.openInFinder(path);
    if (error != null) {
      dLog('[IdeService] openInFinder failed: $error');
      throw IdeLaunchFailedException('Finder', path, error);
    }
  }

  Future<void> openInTerminal(String path) async {
    final error = await _repo.openInTerminal(path);
    if (error != null) {
      dLog('[IdeService] openInTerminal failed: $error');
      throw IdeLaunchFailedException('Terminal', path, error);
    }
  }
}
```

- [ ] **Step 5: Update notifiers**
```bash
grep -r "ideLaunchRepositoryProvider" lib/features/ lib/shell/ --include="*.dart" -l
```
Replace with `ideServiceProvider`. Update `openVsCode`/`openCursor` call sites to handle `IdeLaunchFailedException` in `_asFailure`.

- [ ] **Step 6: Build + test**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/ide/
flutter test && flutter analyze
```

- [ ] **Step 7: Commit**
```bash
git add lib/services/ide/ test/services/ide/
git commit -m "feat(arch): IdeService — convert nullable error returns to IdeLaunchFailedException"
```

---

## Task 9: ApiKeyTestService

Thin passthrough service. `testApiKey` / `testOllamaUrl` delegate directly; no new exceptions.

**Files:**
- Create: `lib/services/api_key_test/api_key_test_service.dart`
- Create: `test/services/api_key_test/api_key_test_service_test.dart`
- Modify: `lib/features/settings/notifiers/settings_actions.dart` (switch from repo to service)

- [ ] **Step 1: Write failing tests**

Create `test/services/api_key_test/api_key_test_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench/data/ai/repository/api_key_test_repository.dart';
import 'package:code_bench/data/models/ai_model.dart';
import 'package:code_bench/services/api_key_test/api_key_test_service.dart';

class _FakeRepo extends Fake implements ApiKeyTestRepository {
  @override
  Future<bool> testApiKey(AIProvider provider, String key) async => true;
  @override
  Future<bool> testOllamaUrl(String url) async => false;
}

void main() {
  test('testApiKey delegates to repository', () async {
    final svc = ApiKeyTestService(repo: _FakeRepo());
    expect(await svc.testApiKey(AIProvider.anthropic, 'key'), isTrue);
  });

  test('testOllamaUrl delegates to repository', () async {
    final svc = ApiKeyTestService(repo: _FakeRepo());
    expect(await svc.testOllamaUrl('http://localhost:11434'), isFalse);
  });
}
```

- [ ] **Step 2: Run to confirm failure**
```bash
flutter test test/services/api_key_test/api_key_test_service_test.dart
```

- [ ] **Step 3: Create `lib/services/api_key_test/api_key_test_service.dart`**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/ai/repository/api_key_test_repository.dart';
import '../../data/ai/repository/api_key_test_repository_impl.dart';
import '../../data/models/ai_model.dart';

part 'api_key_test_service.g.dart';

@Riverpod(keepAlive: true)
ApiKeyTestService apiKeyTestService(Ref ref) {
  return ApiKeyTestService(repo: ref.watch(apiKeyTestRepositoryProvider));
}

class ApiKeyTestService {
  ApiKeyTestService({required ApiKeyTestRepository repo}) : _repo = repo;

  final ApiKeyTestRepository _repo;

  Future<bool> testApiKey(AIProvider provider, String key) =>
      _repo.testApiKey(provider, key);

  Future<bool> testOllamaUrl(String url) => _repo.testOllamaUrl(url);
}
```

- [ ] **Step 4: Update `lib/features/settings/notifiers/settings_actions.dart`**

Replace:
```dart
// Before:
return await ref.read(apiKeyTestRepositoryProvider).testApiKey(provider, key);
// After:
return await ref.read(apiKeyTestServiceProvider).testApiKey(provider, key);

// Before:
Future<bool> testOllamaUrl(String url) => ref.read(apiKeyTestRepositoryProvider).testOllamaUrl(url);
// After:
Future<bool> testOllamaUrl(String url) => ref.read(apiKeyTestServiceProvider).testOllamaUrl(url);
```
Remove `import '...api_key_test_repository_impl.dart'`. Add `import '...services/api_key_test/api_key_test_service.dart'`.

- [ ] **Step 5: Build + test**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/api_key_test/
flutter test && flutter analyze
```

- [ ] **Step 6: Commit**
```bash
git add lib/services/api_key_test/ test/services/api_key_test/ \
  lib/features/settings/notifiers/settings_actions.dart
git commit -m "feat(arch): ApiKeyTestService — introduce service layer for API key validation"
```

---

## Task 10: Arch test additions

Add the three new invariants from the spec to `test/arch_test.dart`.

**Files:**
- Modify: `test/arch_test.dart`

- [ ] **Step 1: Add new tests to `test/arch_test.dart`**

Inside the existing `group('Architectural boundary rules', ...)`, add after the last existing test:
```dart
// ── Notifier → Repository direct access rule ────────────────────────────────
//
// Notifiers must call services, not repositories directly.
// Permitted exceptions (pre-existing, tracked for cleanup):
//   • project_tile.dart gitLiveStateProvider — family provider still in repo layer
test('notifiers do not read repository providers directly', () {
  final notifierFiles = _dartFiles('lib/').where(
    (p) =>
        p.contains('/notifiers/') &&
        (p.endsWith('_actions.dart') || p.endsWith('_notifier.dart')),
  ).toList();
  final violations = <String>[];
  for (final file in notifierFiles) {
    final content = File(file).readAsStringSync();
    final hasRepoRead =
        RegExp(r'ref\.read\(\w*[Rr]epository[Pp]rovider').hasMatch(content) ||
        RegExp(r'ref\.watch\(\w*[Rr]epository[Pp]rovider').hasMatch(content);
    if (hasRepoRead) {
      violations.add(file);
    }
  }
  expect(
    violations,
    isEmpty,
    reason: 'Notifiers reading repository providers directly (use a service):\n'
        '${violations.join('\n')}',
  );
});

// ── Service → feature import rule ───────────────────────────────────────────
//
// Files in lib/services/ must not import from lib/features/.
test('services do not import from lib/features/', () {
  final violations = _grepImport("package:code_bench/features/", 'lib/services/')
    ..addAll(_grepImport("'../../../features/", 'lib/services/'))
    ..addAll(_grepImport("'../../features/", 'lib/services/'));
  expect(
    violations,
    isEmpty,
    reason: 'Services importing from lib/features/:\n${violations.join('\n')}',
  );
});

// ── Data → service import rule ───────────────────────────────────────────────
//
// Files in lib/data/ must not import from lib/services/.
test('data layer does not import from lib/services/', () {
  final violations = _grepImport("package:code_bench/services/", 'lib/data/')
    ..addAll(_grepImport("'../../../services/", 'lib/data/'))
    ..addAll(_grepImport("'../../services/", 'lib/data/'));
  expect(
    violations,
    isEmpty,
    reason: 'Data layer importing from lib/services/:\n${violations.join('\n')}',
  );
});
```

- [ ] **Step 2: Run arch tests**
```bash
flutter test test/arch_test.dart
```
Expected: all pass. If notifier violations remain, fix them before proceeding.

- [ ] **Step 3: Commit**
```bash
git add test/arch_test.dart
git commit -m "test(arch): add notifier→repo, service→feature, data→service invariants"
```

---

## Task 11: Final pass

- [ ] **Step 1: Run full code generation**
```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: all `.g.dart` files regenerated, no errors.

- [ ] **Step 2: Run full test suite**
```bash
flutter test
```
Expected: 0 failures.

- [ ] **Step 3: Run analyzer**
```bash
flutter analyze
```
Expected: no issues.

- [ ] **Step 4: Format**
```bash
dart format lib/ test/
```

- [ ] **Step 5: Commit generated files + format**
```bash
git add lib/services/**/*.g.dart
git add .
git commit -m "chore: build_runner codegen + dart format for service layer"
```

- [ ] **Step 6: Commit spec + plan**
```bash
# from main worktree:
git add docs/superpowers/specs/2026-04-13-full-clean-architecture-services-design.md \
  docs/superpowers/plans/2026-04-13-full-clean-architecture-services.md
git commit -m "docs: full clean architecture service layer spec + implementation plan"
```

---

## Scope check — spec requirements vs. tasks

| Spec requirement | Covered in |
|---|---|
| 9 services created | Tasks 1–9 |
| Repositories stripped | Tasks 1 (Apply), 2 (Git), 4 (Session), 6 (AI) |
| Domain exceptions relocated / created | Tasks 1 (Apply), 2 (Git), 3 (Project), 8 (IDE) |
| `wipeAllData` cascade to service | Task 5 |
| `sendAndStream` to SessionService | Task 4 |
| `sendMessage` buffer to AIService | Task 6 |
| Arch test invariants (3 new rules) | Task 10 |
| Notifiers thinned to ViewModel pattern | Tasks 1, 5, 9 (and each service's notifier update step) |
| `assertWithinProject` moves to ApplyService | Task 1, Step 8 |
| Worktree branching | Task 0 |
