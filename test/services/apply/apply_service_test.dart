import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:code_bench_app/features/chat/chat_notifier.dart';
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
    await service.revertChange(
      change: change,
      isGit: false,
      projectPath: tmpDir.path,
    );

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
    await service.revertChange(
      change: change,
      isGit: false,
      projectPath: tmpDir.path,
    );

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
    await gitService.revertChange(
      change: change,
      isGit: true,
      projectPath: tmpDir.path,
    );

    expect(capturedArgs, ['git', 'checkout', '--', filePath]);
    expect(capturedWorkingDir, tmpDir.path);
    // Notifier entry removed
    expect(container.read(appliedChangesProvider)['sid'], isNull);
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
      () => gitService.revertChange(
        change: change,
        isGit: true,
        projectPath: tmpDir.path,
      ),
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

  test('assertWithinProject allows paths inside project root', () {
    expect(
      () => ApplyService.assertWithinProject(
        '${tmpDir.path}/lib/main.dart',
        tmpDir.path,
      ),
      returnsNormally,
    );
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
        () => ApplyService.assertWithinProject(
          p.join(linkPath, 'evil.txt'),
          tmpDir.path,
        ),
        throwsA(isA<StateError>()),
      );
    } finally {
      await outside.delete(recursive: true);
    }
  });

  test('assertWithinProject blocks sibling-prefix attack', () {
    // Project is /tmp/foo, attacker tries /tmp/foo-evil/x.dart
    final siblingPath = '${tmpDir.path}-evil/x.dart';
    expect(
      () => ApplyService.assertWithinProject(siblingPath, tmpDir.path),
      throwsA(isA<StateError>()),
    );
  });
}
