import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ide/repository/ide_launch_repository.dart';
import 'package:code_bench_app/services/ide/ide_service.dart';

class _SuccessRepo extends Fake implements IdeLaunchRepository {
  @override
  Future<String?> openVsCode(String path) async => null;
  @override
  Future<String?> openCursor(String path) async => null;
  @override
  Future<String?> openInFinder(String path) async => null;
  @override
  Future<String?> openInTerminal(String path) async => null;
}

class _FailRepo extends Fake implements IdeLaunchRepository {
  @override
  Future<String?> openVsCode(String path) async => 'VS Code not found';
  @override
  Future<String?> openCursor(String path) async => 'Cursor not found';
  @override
  Future<String?> openInFinder(String path) async => 'Finder error';
  @override
  Future<String?> openInTerminal(String path) async => 'Terminal error';
}

void main() {
  test('openVsCode does not throw on success', () async {
    final svc = IdeService(repo: _SuccessRepo());
    await expectLater(svc.openVsCode('/project'), completes);
  });

  test('openVsCode throws IdeLaunchFailedException on error', () {
    final svc = IdeService(repo: _FailRepo());
    expect(() => svc.openVsCode('/project'), throwsA(isA<IdeLaunchFailedException>()));
  });

  test('openCursor throws IdeLaunchFailedException on error', () {
    final svc = IdeService(repo: _FailRepo());
    expect(() => svc.openCursor('/project'), throwsA(isA<IdeLaunchFailedException>()));
  });

  test('openInFinder throws IdeLaunchFailedException on error', () {
    final svc = IdeService(repo: _FailRepo());
    expect(() => svc.openInFinder('/project'), throwsA(isA<IdeLaunchFailedException>()));
  });

  test('openInTerminal throws IdeLaunchFailedException on error', () {
    final svc = IdeService(repo: _FailRepo());
    expect(() => svc.openInTerminal('/project'), throwsA(isA<IdeLaunchFailedException>()));
  });
}
