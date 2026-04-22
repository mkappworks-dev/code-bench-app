import 'dart:io';

import 'package:code_bench_app/data/apply/repository/apply_repository.dart';
import 'package:code_bench_app/data/apply/models/applied_change.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake ApplyRepository ────────────────────────────────────────────────────

class FakeApplyRepository implements ApplyRepository {
  String? _readContent; // null means file not found
  String? _writtenContent;
  bool _deleted = false;
  bool _gitCheckedOut = false;
  bool _shouldThrowDiskError = false;

  void setReadContent(String content) => _readContent = content;

  /// Makes [readFile] throw [ApplyDiskException] (simulates a disk I/O error).
  void setReadThrowsApplyDiskException() => _shouldThrowDiskError = true;

  String? get writtenContent => _writtenContent;
  bool get deleted => _deleted;
  bool get gitCheckedOut => _gitCheckedOut;

  @override
  Future<String?> readFile(String path) async {
    if (_shouldThrowDiskError) throw ApplyDiskException('Disk read error');
    return _readContent; // null = file not found
  }

  @override
  Future<void> writeFile(String path, String content) async {
    _writtenContent = content;
  }

  @override
  Future<void> deleteFile(String path) async {
    _deleted = true;
  }

  @override
  Future<void> gitCheckout(String filePath, String workingDirectory) async {
    _gitCheckedOut = true;
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

ApplyService makeService({FakeApplyRepository? repo, String Function()? uuidGen}) {
  return ApplyService(repo: repo ?? FakeApplyRepository(), uuidGen: uuidGen);
}

const String _insideProjectPath = '/tmp/myproject';
const String _fileOutsideProject = '/tmp/other/evil.dart';

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ApplyService.applyChange', () {
    test('returns correct AppliedChange fields', () async {
      final repo = FakeApplyRepository();
      repo.setReadContent('original content');
      const fixedId = 'fixed-uuid-1234';
      final service = makeService(repo: repo, uuidGen: () => fixedId);

      // Use a real directory that exists
      const tmpProject = '/tmp';
      const tmpFile = '/tmp/test_main.dart';

      final change = await service.applyChange(
        filePath: tmpFile,
        projectPath: tmpProject,
        newContent: 'new content',
        sessionId: 'session-1',
        messageId: 'msg-1',
      );

      expect(change.id, fixedId);
      expect(change.sessionId, 'session-1');
      expect(change.messageId, 'msg-1');
      expect(change.filePath, tmpFile);
      expect(change.originalContent, 'original content');
      expect(change.newContent, 'new content');
      expect(change.contentChecksum, ApplyRepository.sha256OfString('new content'));
    });

    test('throws PathEscapeException for path outside project', () async {
      final service = makeService();

      await expectLater(
        () => service.applyChange(
          filePath: _fileOutsideProject,
          projectPath: _insideProjectPath,
          newContent: 'content',
          sessionId: 's',
          messageId: 'm',
        ),
        throwsA(isA<PathEscapeException>()),
      );
    });

    test('throws ApplyTooLargeException when content > 1MB', () async {
      final repo = FakeApplyRepository();
      repo.setReadContent('small');
      final service = makeService(repo: repo);

      const tmpProject = '/tmp';
      const tmpFile = '/tmp/big_file.dart';
      final bigContent = 'x' * (kMaxApplyContentBytes + 1);

      await expectLater(
        () => service.applyChange(
          filePath: tmpFile,
          projectPath: tmpProject,
          newContent: bigContent,
          sessionId: 's',
          messageId: 'm',
        ),
        throwsA(isA<ApplyTooLargeException>()),
      );
    });

    test('sets originalContent=null for new file', () async {
      final repo = FakeApplyRepository(); // no content set → readFile returns null
      final service = makeService(repo: repo);

      const tmpProject = '/tmp';
      const tmpFile = '/tmp/new_file.dart';

      final change = await service.applyChange(
        filePath: tmpFile,
        projectPath: tmpProject,
        newContent: 'brand new',
        sessionId: 's',
        messageId: 'm',
      );

      expect(change.originalContent, isNull);
    });

    test('throws ApplyDiskException for disk I/O error', () async {
      final repo = FakeApplyRepository();
      repo.setReadThrowsApplyDiskException();
      final service = makeService(repo: repo);

      const tmpProject = '/tmp';
      const tmpFile = '/tmp/error_file.dart';

      await expectLater(
        () => service.applyChange(
          filePath: tmpFile,
          projectPath: tmpProject,
          newContent: 'content',
          sessionId: 's',
          messageId: 'm',
        ),
        throwsA(isA<ApplyDiskException>()),
      );
    });
  });

  group('ApplyService.revertChange', () {
    test('deletes file when originalContent is null', () async {
      final repo = FakeApplyRepository();
      final service = makeService(repo: repo);

      final change = AppliedChange(
        id: 'id-1',
        sessionId: 's',
        messageId: 'm',
        filePath: '/tmp/some_file.dart',
        originalContent: null,
        newContent: 'new',
        appliedAt: DateTime.now(),
        additions: 1,
        deletions: 0,
        contentChecksum: 'abc',
      );

      await service.revertChange(change: change, isGit: false, projectPath: '/tmp');
      expect(repo.deleted, isTrue);
      expect(repo.gitCheckedOut, isFalse);
    });

    test('writes originalContent when not git', () async {
      final repo = FakeApplyRepository();
      final service = makeService(repo: repo);

      final change = AppliedChange(
        id: 'id-2',
        sessionId: 's',
        messageId: 'm',
        filePath: '/tmp/some_file.dart',
        originalContent: 'original',
        newContent: 'new',
        appliedAt: DateTime.now(),
        additions: 1,
        deletions: 1,
        contentChecksum: 'abc',
      );

      await service.revertChange(change: change, isGit: false, projectPath: '/tmp');
      expect(repo.writtenContent, 'original');
      expect(repo.deleted, isFalse);
      expect(repo.gitCheckedOut, isFalse);
    });

    test('calls gitCheckout when isGit is true', () async {
      final repo = FakeApplyRepository();
      final service = makeService(repo: repo);

      final change = AppliedChange(
        id: 'id-3',
        sessionId: 's',
        messageId: 'm',
        filePath: '/tmp/some_file.dart',
        originalContent: 'original',
        newContent: 'new',
        appliedAt: DateTime.now(),
        additions: 1,
        deletions: 1,
        contentChecksum: 'abc',
      );

      await service.revertChange(change: change, isGit: true, projectPath: '/tmp');
      expect(repo.gitCheckedOut, isTrue);
      expect(repo.deleted, isFalse);
    });

    test('throws PathEscapeException for filePath outside projectPath', () async {
      final service = makeService();

      final change = AppliedChange(
        id: 'id-escape',
        sessionId: 's',
        messageId: 'm',
        filePath: '/etc/passwd',
        originalContent: 'original',
        newContent: 'new',
        appliedAt: DateTime.now(),
        additions: 1,
        deletions: 1,
        contentChecksum: 'abc',
      );

      await expectLater(
        () => service.revertChange(change: change, isGit: false, projectPath: '/tmp'),
        throwsA(isA<PathEscapeException>()),
      );
    });
  });

  group('ApplyService.isExternallyModified', () {
    test('returns false when checksum matches', () async {
      const content = 'hello world';
      final repo = FakeApplyRepository();
      repo.setReadContent(content);
      final service = makeService(repo: repo);

      final checksum = ApplyRepository.sha256OfString(content);
      final result = await service.isExternallyModified('/tmp/file.dart', checksum);
      expect(result, isFalse);
    });

    test('returns true when checksum differs', () async {
      final repo = FakeApplyRepository();
      repo.setReadContent('modified content');
      final service = makeService(repo: repo);

      final result = await service.isExternallyModified('/tmp/file.dart', 'old-checksum');
      expect(result, isTrue);
    });

    test('returns true when file missing', () async {
      final repo = FakeApplyRepository(); // no content → readFile returns null
      final service = makeService(repo: repo);

      final result = await service.isExternallyModified('/tmp/missing.dart', 'any-checksum');
      expect(result, isTrue);
    });
  });

  group('ApplyRepository.assertWithinProject (static)', () {
    late Directory tmpProj;

    setUp(() async {
      tmpProj = await Directory.systemTemp.createTemp('apply_svc_assert_test_');
    });

    tearDown(() async {
      await tmpProj.delete(recursive: true);
    });

    test('does not throw for path inside project', () {
      expect(() => ApplyRepository.assertWithinProject('${tmpProj.path}/src/file.dart', tmpProj.path), returnsNormally);
    });

    test('throws PathEscapeException for traversal', () {
      expect(
        () => ApplyRepository.assertWithinProject('/tmp/other/evil.dart', tmpProj.path),
        throwsA(isA<PathEscapeException>()),
      );
    });

    test('throws PathEscapeException for path equal to project root', () {
      expect(
        () => ApplyRepository.assertWithinProject(tmpProj.path, tmpProj.path),
        throwsA(isA<PathEscapeException>()),
      );
    });
  });

  group('ApplyRepository.sha256OfString (static)', () {
    test('produces consistent hex digest', () {
      final digest1 = ApplyRepository.sha256OfString('hello');
      final digest2 = ApplyRepository.sha256OfString('hello');
      expect(digest1, digest2);
      expect(digest1, hasLength(64));
    });

    test('differs for different inputs', () {
      final d1 = ApplyRepository.sha256OfString('a');
      final d2 = ApplyRepository.sha256OfString('b');
      expect(d1, isNot(equals(d2)));
    });
  });

  group('ApplyService.readFileContent', () {
    test('returns content when file exists', () async {
      final repo = FakeApplyRepository();
      repo.setReadContent('file content');
      final service = makeService(repo: repo);

      final result = await service.readFileContent('/tmp/file.dart', '/tmp');
      expect(result, 'file content');
    });

    test('returns null when file not found', () async {
      final repo = FakeApplyRepository(); // readFile returns null
      final service = makeService(repo: repo);

      final result = await service.readFileContent('/tmp/missing.dart', '/tmp');
      expect(result, isNull);
    });
  });

  group('applyChange — checksum guard', () {
    test('throws ApplyContentChangedException when expectedChecksum does not match on-disk content', () async {
      final repo = FakeApplyRepository();
      repo.setReadContent('original');
      final service = makeService(repo: repo);

      await expectLater(
        () => service.applyChange(
          filePath: '/tmp/guarded.txt',
          projectPath: '/tmp',
          newContent: 'updated',
          sessionId: 's',
          messageId: 'm',
          expectedChecksum: ApplyRepository.sha256OfString('different content'),
        ),
        throwsA(isA<ApplyContentChangedException>()),
      );
      // file not written
      expect(repo.writtenContent, isNull);
    });

    test('succeeds when expectedChecksum matches on-disk content', () async {
      final repo = FakeApplyRepository();
      repo.setReadContent('original');
      final service = makeService(repo: repo);

      final change = await service.applyChange(
        filePath: '/tmp/guarded2.txt',
        projectPath: '/tmp',
        newContent: 'updated',
        sessionId: 's',
        messageId: 'm',
        expectedChecksum: ApplyRepository.sha256OfString('original'),
      );
      expect(repo.writtenContent, 'updated');
      expect(change.originalContent, 'original');
    });

    test('succeeds when expectedChecksum is null (no guard)', () async {
      final repo = FakeApplyRepository();
      repo.setReadContent('original');
      final service = makeService(repo: repo);

      await service.applyChange(
        filePath: '/tmp/guarded3.txt',
        projectPath: '/tmp',
        newContent: 'updated',
        sessionId: 's',
        messageId: 'm',
      );
      expect(repo.writtenContent, 'updated');
    });
  });

  group('ApplyService.readOriginalForDiff', () {
    test('returns content when file exists', () async {
      final repo = FakeApplyRepository();
      repo.setReadContent('original');
      final service = makeService(repo: repo);

      final result = await service.readOriginalForDiff('/tmp/file.dart', '/tmp');
      expect(result, 'original');
    });

    test('returns null for new file', () async {
      final repo = FakeApplyRepository(); // readFile returns null
      final service = makeService(repo: repo);

      final result = await service.readOriginalForDiff('/tmp/new_file.dart', '/tmp');
      expect(result, isNull);
    });

    test('rethrows ApplyDiskException (unlike readFileContent which swallows it)', () async {
      final repo = FakeApplyRepository();
      repo.setReadThrowsApplyDiskException();
      final service = makeService(repo: repo);

      await expectLater(
        () => service.readOriginalForDiff('/tmp/file.dart', '/tmp'),
        throwsA(isA<ApplyDiskException>()),
      );
    });
  });
}
