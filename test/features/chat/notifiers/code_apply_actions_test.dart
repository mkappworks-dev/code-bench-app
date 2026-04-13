import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/models/applied_change.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/chat/notifiers/code_apply_actions.dart';
import 'package:code_bench_app/features/chat/notifiers/code_apply_failure.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_actions.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';

// ── Fake ApplyService ─────────────────────────────────────────────────────────

class _FakeApplyService extends Fake implements ApplyService {
  Object? _applyError;
  Object? _revertError;

  void throwOnApply(Object error) => _applyError = error;
  void throwOnRevert(Object error) => _revertError = error;

  @override
  Future<AppliedChange> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    if (_applyError != null) throw _applyError!;
    return AppliedChange(
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
  Future<void> revertChange({required AppliedChange change, required bool isGit, required String projectPath}) async {
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
  late _FakeApplyService fakeService;
  late _FakeProjectSidebarActions fakeSidebar;

  setUp(() {
    fakeService = _FakeApplyService();
    fakeSidebar = _FakeProjectSidebarActions();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        applyServiceProvider.overrideWithValue(fakeService),
        projectSidebarActionsProvider.overrideWith(() => fakeSidebar),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  // ── applyChange ─────────────────────────────────────────────────────────────

  group('applyChange', () {
    test('happy path — state becomes AsyncData and change is recorded', () async {
      final c = makeContainer();
      await c
          .read(codeApplyActionsProvider.notifier)
          .applyChange(
            projectId: 'p',
            filePath: '/p/f.dart',
            projectPath: '/p',
            newContent: 'x',
            sessionId: 's',
            messageId: 'm',
          );
      expect(c.read(codeApplyActionsProvider), isA<AsyncData<void>>());
      // CodeApplyActions now calls appliedChangesProvider.notifier.apply() directly
      expect(c.read(appliedChangesProvider)['s'], isNotEmpty);
    });

    test('ProjectMissingException → CodeApplyProjectMissing', () async {
      fakeService.throwOnApply(ProjectMissingException('p'));

      final c = makeContainer();
      await c
          .read(codeApplyActionsProvider.notifier)
          .applyChange(
            projectId: 'p',
            filePath: '/p/f.dart',
            projectPath: '/p',
            newContent: 'x',
            sessionId: 's',
            messageId: 'm',
          );
      expect(c.read(codeApplyActionsProvider).error, isA<CodeApplyProjectMissing>());
    });

    test('ProjectMissingException triggers refreshProjectStatus', () async {
      fakeService.throwOnApply(ProjectMissingException('p'));

      final c = makeContainer();
      // Pre-read so fakeSidebar is the active notifier instance.
      c.read(projectSidebarActionsProvider);

      await c
          .read(codeApplyActionsProvider.notifier)
          .applyChange(
            projectId: 'p',
            filePath: '/p/f.dart',
            projectPath: '/p',
            newContent: 'x',
            sessionId: 's',
            messageId: 'm',
          );

      // Give the unawaited fire-and-forget a chance to complete.
      await Future<void>.delayed(Duration.zero);
      expect(fakeSidebar.refreshCalls, equals(1));
    });

    test('PathEscapeException → CodeApplyOutsideProject', () async {
      fakeService.throwOnApply(PathEscapeException('/p/f.dart', '/other'));

      final c = makeContainer();
      await c
          .read(codeApplyActionsProvider.notifier)
          .applyChange(
            projectId: 'p',
            filePath: '/p/f.dart',
            projectPath: '/p',
            newContent: 'x',
            sessionId: 's',
            messageId: 'm',
          );
      expect(c.read(codeApplyActionsProvider).error, isA<CodeApplyOutsideProject>());
    });

    test('ApplyTooLargeException → CodeApplyTooLarge', () async {
      fakeService.throwOnApply(ApplyTooLargeException(2 * 1024 * 1024));

      final c = makeContainer();
      await c
          .read(codeApplyActionsProvider.notifier)
          .applyChange(
            projectId: 'p',
            filePath: '/p/f.dart',
            projectPath: '/p',
            newContent: 'x',
            sessionId: 's',
            messageId: 'm',
          );
      expect(c.read(codeApplyActionsProvider).error, isA<CodeApplyTooLarge>());
    });

    test('FileSystemException → CodeApplyDiskWrite', () async {
      fakeService.throwOnApply(const FileSystemException('disk full', '/p/f.dart'));

      final c = makeContainer();
      await c
          .read(codeApplyActionsProvider.notifier)
          .applyChange(
            projectId: 'p',
            filePath: '/p/f.dart',
            projectPath: '/p',
            newContent: 'x',
            sessionId: 's',
            messageId: 'm',
          );
      expect(c.read(codeApplyActionsProvider).error, isA<CodeApplyDiskWrite>());
    });

    test('generic exception → CodeApplyUnknownError', () async {
      fakeService.throwOnApply(Exception('boom'));

      final c = makeContainer();
      await c
          .read(codeApplyActionsProvider.notifier)
          .applyChange(
            projectId: 'p',
            filePath: '/p/f.dart',
            projectPath: '/p',
            newContent: 'x',
            sessionId: 's',
            messageId: 'm',
          );
      expect(c.read(codeApplyActionsProvider).error, isA<CodeApplyUnknownError>());
    });
  });

  // ── revertChange ────────────────────────────────────────────────────────────

  group('revertChange', () {
    test('happy path — state becomes AsyncData and change is removed', () async {
      final c = makeContainer();
      // First apply a change so appliedChangesProvider has it.
      await c
          .read(codeApplyActionsProvider.notifier)
          .applyChange(
            projectId: 'p',
            filePath: '/p/f.dart',
            projectPath: '/p',
            newContent: 'x',
            sessionId: 's',
            messageId: 'm',
          );
      expect(c.read(appliedChangesProvider)['s'], isNotEmpty);

      // Now revert — the change should be removed from appliedChangesProvider.
      final applied = c.read(appliedChangesProvider)['s']!.first;
      await c.read(codeApplyActionsProvider.notifier).revertChange(change: applied, isGit: false, projectPath: '/p');
      expect(c.read(codeApplyActionsProvider), isA<AsyncData<void>>());
      expect(c.read(appliedChangesProvider)['s'] ?? [], isEmpty);
    });

    test('revertChange with standalone change — state becomes AsyncData', () async {
      final c = makeContainer();
      await c
          .read(codeApplyActionsProvider.notifier)
          .revertChange(change: _makeChange(), isGit: false, projectPath: '/p');
      expect(c.read(codeApplyActionsProvider), isA<AsyncData<void>>());
    });

    test('exception → CodeApplyUnknownError', () async {
      fakeService.throwOnRevert(Exception('boom'));

      final c = makeContainer();
      await c
          .read(codeApplyActionsProvider.notifier)
          .revertChange(change: _makeChange(), isGit: false, projectPath: '/p');
      expect(c.read(codeApplyActionsProvider).error, isA<CodeApplyUnknownError>());
    });
  });

  // ── readFileContent ─────────────────────────────────────────────────────────

  group('readFileContent', () {
    test('returns file content on success', () async {
      final dir = await Directory.systemTemp.createTemp();
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/test.dart')..writeAsStringSync('hello');

      final c = makeContainer();
      final content = await c.read(codeApplyActionsProvider.notifier).readFileContent(file.path, dir.path);
      expect(content, equals('hello'));
    });

    test('returns null for missing file', () async {
      final dir = await Directory.systemTemp.createTemp();
      addTearDown(() => dir.delete(recursive: true));
      final c = makeContainer();
      final content = await c
          .read(codeApplyActionsProvider.notifier)
          .readFileContent('${dir.path}/nonexistent.dart', dir.path);
      expect(content, isNull);
    });
  });
}
