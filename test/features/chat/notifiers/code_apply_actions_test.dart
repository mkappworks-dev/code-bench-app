import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/models/applied_change.dart';
import 'package:code_bench_app/features/chat/notifiers/code_apply_actions.dart';
import 'package:code_bench_app/features/chat/notifiers/code_apply_failure.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_actions.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';

// ── Fake ApplyService ─────────────────────────────────────────────────────────

class _FakeApplyService extends Fake implements ApplyService {
  Object? _applyError;
  Object? _revertError;

  void throwOnApply(Object error) => _applyError = error;
  void throwOnRevert(Object error) => _revertError = error;

  @override
  Future<void> applyChange({
    required String filePath,
    required String projectPath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    if (_applyError != null) throw _applyError!;
  }

  @override
  Future<void> revertChange({required AppliedChange change, required bool isGit, required String projectPath}) async {
    if (_revertError != null) throw _revertError!;
  }

  @override
  Future<String> readFileContent(String path) async {
    try {
      return await File(path).readAsString();
    } on IOException {
      return '(file unreadable)';
    }
  }
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
    test('happy path — state becomes AsyncData', () async {
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

    test('StateError → CodeApplyOutsideProject', () async {
      fakeService.throwOnApply(StateError('outside'));

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
    test('happy path — state becomes AsyncData', () async {
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
      final content = await c.read(codeApplyActionsProvider.notifier).readFileContent(file.path);
      expect(content, equals('hello'));
    });

    test('returns fallback string for missing file', () async {
      final c = makeContainer();
      final content = await c.read(codeApplyActionsProvider.notifier).readFileContent('/nonexistent/file.dart');
      expect(content, equals('(file unreadable)'));
    });
  });
}
