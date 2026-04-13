import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:code_bench_app/data/models/applied_change.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/filesystem/filesystem_service.dart';

void main() {
  late Directory tmpDir;
  late ProviderContainer container;
  late ApplyService service;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('apply_test_');
    container = ProviderContainer();
    service = ApplyService(
      fs: FilesystemService(),
      notifier: container.read(appliedChangesProvider.notifier),
      uuidGen: () => 'test-uuid',
    );
  });

  tearDown(() async {
    container.dispose();
    await tmpDir.delete(recursive: true);
  });

  test('apply creates file and records change when file did not exist', () async {
    final filePath = '${tmpDir.path}/new_file.dart';
    await service.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'void main() {}',
      sessionId: 'sid',
      messageId: 'mid',
    );

    // File is written to disk
    expect(File(filePath).existsSync(), true);
    expect(File(filePath).readAsStringSync(), 'void main() {}');

    // Change is recorded with null originalContent (file didn't exist)
    final changes = container.read(appliedChangesProvider)['sid']!;
    expect(changes.length, 1);
    expect(changes.first.originalContent, isNull);
    expect(changes.first.newContent, 'void main() {}');
    expect(changes.first.filePath, filePath);
    expect(changes.first.id, 'test-uuid');
    // New file: all lines count as additions, none as deletions.
    expect(changes.first.additions, 1);
    expect(changes.first.deletions, 0);
  });

  test('apply records line counts when replacing content line-for-line', () async {
    final filePath = '${tmpDir.path}/swap.dart';
    File(filePath).writeAsStringSync('a\nb\nc\n');

    await service.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'x\ny\nz\n',
      sessionId: 'sid',
      messageId: 'mid',
    );

    final change = container.read(appliedChangesProvider)['sid']!.first;
    // Line-level diff: 3 old lines deleted, 3 new lines added.
    expect(change.additions, 3);
    expect(change.deletions, 3);
  });

  test('apply counts inline edits as single-line changes', () async {
    // Renaming a token mid-line should report +1 −1, not inflate via
    // char-level partial-line double-counting.
    final filePath = '${tmpDir.path}/rename.dart';
    File(filePath).writeAsStringSync('final foo = 42;\n');

    await service.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'final bar = 42;\n',
      sessionId: 'sid',
      messageId: 'mid',
    );

    final change = container.read(appliedChangesProvider)['sid']!.first;
    expect(change.additions, 1);
    expect(change.deletions, 1);
  });

  test('apply rejects content larger than kMaxApplyContentBytes', () async {
    final filePath = '${tmpDir.path}/huge.dart';
    final oversized = 'a' * (kMaxApplyContentBytes + 1);

    await expectLater(
      () => service.applyChange(
        filePath: filePath,
        projectPath: tmpDir.path,
        newContent: oversized,
        sessionId: 'sid',
        messageId: 'mid',
      ),
      throwsA(isA<StateError>()),
    );

    // Nothing written, nothing tracked
    expect(File(filePath).existsSync(), false);
    expect(container.read(appliedChangesProvider)['sid'], isNull);
  });

  test('apply rejects oversized original file snapshot', () async {
    final filePath = '${tmpDir.path}/legacy_huge.dart';
    // Write an over-cap file directly to disk to simulate a pre-existing
    // huge file the user tries to apply a small change to.
    File(filePath).writeAsStringSync('a' * (kMaxApplyContentBytes + 1));

    await expectLater(
      () => service.applyChange(
        filePath: filePath,
        projectPath: tmpDir.path,
        newContent: 'small',
        sessionId: 'sid',
        messageId: 'mid',
      ),
      throwsA(isA<StateError>()),
    );

    // Original content must NOT have been overwritten
    expect(File(filePath).readAsStringSync().length, kMaxApplyContentBytes + 1);
    expect(container.read(appliedChangesProvider)['sid'], isNull);
  });

  test('apply treats a deleted-between-check-and-read file as new', () async {
    // This is the TOCTOU scenario: in a pre-fix world, applyChange used
    // `existsSync` + `readFile`. If the file vanished in that window, the
    // read would throw a confusing wrapped FileSystemException instead of
    // falling through to "new file" handling. After the fix, applyChange
    // reads directly and catches PathNotFoundException, so a non-existent
    // file is correctly treated as a new-file creation.
    final filePath = '${tmpDir.path}/vanished.dart';
    // File does NOT exist on disk.
    expect(File(filePath).existsSync(), false);

    await service.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'void main() {}',
      sessionId: 'sid',
      messageId: 'mid',
    );

    // File is created, change tracked as new-file (null originalContent).
    expect(File(filePath).existsSync(), true);
    final change = container.read(appliedChangesProvider)['sid']!.first;
    expect(change.originalContent, isNull);
  });

  test('apply snapshots original content when file exists', () async {
    final filePath = '${tmpDir.path}/existing.dart';
    File(filePath).writeAsStringSync('original content');

    await service.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'updated content',
      sessionId: 'sid',
      messageId: 'mid',
    );

    final changes = container.read(appliedChangesProvider)['sid']!;
    expect(changes.first.originalContent, 'original content');
    expect(File(filePath).readAsStringSync(), 'updated content');
  });

  test('revert (non-git) writes back original content', () async {
    final filePath = '${tmpDir.path}/file.dart';
    File(filePath).writeAsStringSync('original');

    await service.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'changed',
      sessionId: 'sid',
      messageId: 'mid',
    );

    final change = container.read(appliedChangesProvider)['sid']!.first;
    await service.revertChange(change: change, isGit: false, projectPath: tmpDir.path);

    expect(File(filePath).readAsStringSync(), 'original');

    // Entry removed from notifier
    final remaining = container.read(appliedChangesProvider)['sid'] ?? [];
    expect(remaining, isEmpty);
  });

  test('revert (non-git) deletes file when originalContent is null', () async {
    final filePath = '${tmpDir.path}/new.dart';
    await service.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'new file content',
      sessionId: 'sid',
      messageId: 'mid',
    );

    final change = container.read(appliedChangesProvider)['sid']!.first;
    await service.revertChange(change: change, isGit: false, projectPath: tmpDir.path);

    expect(File(filePath).existsSync(), false);
  });

  test('revert (git) calls git checkout and removes notifier entry on success', () async {
    final filePath = '${tmpDir.path}/file.dart';
    File(filePath).writeAsStringSync('original');

    var capturedArgs = <String>[];
    String? capturedWorkingDir;
    final gitService = ApplyService(
      fs: FilesystemService(),
      notifier: container.read(appliedChangesProvider.notifier),
      uuidGen: () => 'git-uuid',
      processRunner: (exe, args, {workingDirectory}) async {
        capturedArgs = [exe, ...args];
        capturedWorkingDir = workingDirectory;
        return ProcessResult(0, 0, '', '');
      },
    );

    await gitService.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'changed',
      sessionId: 'sid',
      messageId: 'mid',
    );

    final change = container.read(appliedChangesProvider)['sid']!.first;
    await gitService.revertChange(change: change, isGit: true, projectPath: tmpDir.path);

    expect(capturedArgs, ['git', 'checkout', '--', filePath]);
    expect(capturedWorkingDir, tmpDir.path);
    // Notifier entry removed
    expect(container.read(appliedChangesProvider)['sid'], isNull);
  });

  test('revert (git) wraps TimeoutException as StateError', () async {
    final filePath = '${tmpDir.path}/file.dart';
    File(filePath).writeAsStringSync('original');

    final timeoutService = ApplyService(
      fs: FilesystemService(),
      notifier: container.read(appliedChangesProvider.notifier),
      uuidGen: () => 'timeout-direct-uuid',
      // Throw TimeoutException directly to exercise the catch branch
      // without actually waiting the 15s timer.
      processRunner: (exe, args, {workingDirectory}) =>
          Future.delayed(const Duration(milliseconds: 1)).then((_) => throw TimeoutException('simulated hang')),
    );

    await timeoutService.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'changed',
      sessionId: 'sid',
      messageId: 'mid',
    );

    final change = container.read(appliedChangesProvider)['sid']!.first;

    await expectLater(
      () => timeoutService.revertChange(change: change, isGit: true, projectPath: tmpDir.path),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('timed out'))),
    );

    // Notifier entry preserved on failure
    expect(container.read(appliedChangesProvider)['sid'], isNotNull);
  });

  test('revert (git) throws and does NOT remove notifier entry when git fails', () async {
    final filePath = '${tmpDir.path}/file.dart';
    File(filePath).writeAsStringSync('original');

    final gitService = ApplyService(
      fs: FilesystemService(),
      notifier: container.read(appliedChangesProvider.notifier),
      uuidGen: () => 'git-fail-uuid',
      processRunner: (exe, args, {workingDirectory}) async => ProcessResult(0, 1, '', 'error: pathspec did not match'),
    );

    await gitService.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'changed',
      sessionId: 'sid',
      messageId: 'mid',
    );

    final change = container.read(appliedChangesProvider)['sid']!.first;

    await expectLater(
      () => gitService.revertChange(change: change, isGit: true, projectPath: tmpDir.path),
      throwsA(isA<StateError>()),
    );

    // Notifier entry should still be there (revert did not complete)
    await Future.delayed(Duration.zero);
    expect(container.read(appliedChangesProvider)['sid'], isNotNull);
  });

  test('applyChange throws StateError for path outside project root', () async {
    await expectLater(
      () => service.applyChange(
        filePath: '${tmpDir.path}/../../etc/passwd',
        projectPath: tmpDir.path,
        newContent: 'malicious',
        sessionId: 'sid',
        messageId: 'mid',
      ),
      throwsA(isA<StateError>()),
    );

    // Nothing written, nothing tracked
    expect(container.read(appliedChangesProvider)['sid'], isNull);
  });

  test('revertChange throws StateError for path outside project root', () async {
    // Manually construct an AppliedChange whose filePath escapes the project
    // root. This simulates an attacker who tampers with in-memory state to
    // trick revertChange into writing outside the sandbox.
    final maliciousChange = AppliedChange(
      id: 'evil',
      sessionId: 'sid',
      messageId: 'mid',
      filePath: '${tmpDir.path}/../../etc/passwd',
      originalContent: 'hacked',
      newContent: 'owned',
      appliedAt: DateTime.now(),
    );

    await expectLater(
      () => service.revertChange(change: maliciousChange, isGit: false, projectPath: tmpDir.path),
      throwsA(isA<StateError>()),
    );
  });

  test('revertChange rejects symlink-escaped path', () async {
    final outside = await Directory.systemTemp.createTemp('revert_outside_');
    try {
      // Symlink inside project → outside directory
      final linkPath = p.join(tmpDir.path, 'escape');
      await Link(linkPath).create(outside.path);

      final maliciousChange = AppliedChange(
        id: 'sym-evil',
        sessionId: 'sid',
        messageId: 'mid',
        filePath: p.join(linkPath, 'evil.txt'),
        originalContent: 'hacked',
        newContent: 'owned',
        appliedAt: DateTime.now(),
      );

      await expectLater(
        () => service.revertChange(change: maliciousChange, isGit: false, projectPath: tmpDir.path),
        throwsA(isA<StateError>()),
      );
    } finally {
      await outside.delete(recursive: true);
    }
  });

  test('assertWithinProject allows paths inside project root', () {
    expect(() => ApplyService.assertWithinProject('${tmpDir.path}/lib/main.dart', tmpDir.path), returnsNormally);
  });

  test('assertWithinProject blocks symlink escape', () async {
    // Create a sibling directory OUTSIDE the project
    final outside = await Directory.systemTemp.createTemp('apply_outside_');
    try {
      // Create a symlink INSIDE the project pointing OUT
      final linkPath = p.join(tmpDir.path, 'escape');
      await Link(linkPath).create(outside.path);

      // Attempting to write through the symlink must be blocked even though
      // the lexical path "<project>/escape/evil.txt" starts with the project root
      expect(
        () => ApplyService.assertWithinProject(p.join(linkPath, 'evil.txt'), tmpDir.path),
        throwsA(isA<StateError>()),
      );
    } finally {
      await outside.delete(recursive: true);
    }
  });

  test('assertWithinProject blocks sibling-prefix attack', () {
    // Project is /tmp/foo, attacker tries /tmp/foo-evil/x.dart
    final siblingPath = '${tmpDir.path}-evil/x.dart';
    expect(() => ApplyService.assertWithinProject(siblingPath, tmpDir.path), throwsA(isA<StateError>()));
  });
}
