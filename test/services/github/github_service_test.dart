import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/github/repository/github_repository.dart';
import 'package:code_bench_app/services/github/github_service.dart';

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
