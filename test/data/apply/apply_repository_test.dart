import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/data/models/applied_change.dart';

void main() {
  late Directory tmpDir;
  late ApplyRepositoryImpl repo;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('apply_repo_test_');
    repo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()), uuidGen: () => 'test-uuid');
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

    final change = await repo.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'content',
      sessionId: 's',
      messageId: 'm',
    );
    // Simulate it was a new-file apply by constructing a change with null originalContent
    final newFileChange = AppliedChange(
      id: change.id,
      sessionId: change.sessionId,
      messageId: change.messageId,
      filePath: change.filePath,
      originalContent: null,
      newContent: change.newContent,
      appliedAt: change.appliedAt,
      additions: change.additions,
      deletions: change.deletions,
      contentChecksum: change.contentChecksum,
    );

    await repo.revertChange(change: newFileChange, isGit: false, projectPath: tmpDir.path);

    expect(File(filePath).existsSync(), false);
  });

  test('revertChange restores originalContent when not git', () async {
    final filePath = '${tmpDir.path}/restore.dart';
    File(filePath).writeAsStringSync('original');

    // Apply a change
    final change = await repo.applyChange(
      filePath: filePath,
      projectPath: tmpDir.path,
      newContent: 'new content',
      sessionId: 's',
      messageId: 'm',
    );

    // Revert it
    await repo.revertChange(change: change, isGit: false, projectPath: tmpDir.path);

    expect(File(filePath).readAsStringSync(), 'original');
  });

  test('readOriginalForDiff returns null for non-existent file', () async {
    final result = await repo.readOriginalForDiff('${tmpDir.path}/nonexistent.dart', tmpDir.path);
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
    expect(await repo.isExternallyModified('${tmpDir.path}/gone.txt', 'any'), isTrue);
  });
}
