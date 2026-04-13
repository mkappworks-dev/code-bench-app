import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/github/repository/github_repository.dart';
import 'package:code_bench_app/services/github/github_service.dart';

class _FakeGitHubRepo extends Fake implements GitHubRepository {
  // Last createPullRequest call is captured here for assertion.
  Map<String, dynamic>? lastCreatePrArgs;
  String _createPrResult = 'https://github.com/owner/repo/pull/42';

  void setCreatePrResult(String url) => _createPrResult = url;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<List<Repository>> listRepositories({int page = 1}) async => [];

  @override
  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
  }) async {
    lastCreatePrArgs = {
      'owner': owner,
      'repo': repo,
      'title': title,
      'body': body,
      'head': head,
      'base': base,
      'draft': draft,
    };
    return _createPrResult;
  }
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

  test('createPullRequest passes all parameters through to repository', () async {
    final fakeRepo = _FakeGitHubRepo();
    final svc = GitHubService(repo: fakeRepo);

    final url = await svc.createPullRequest(
      owner: 'acme',
      repo: 'widget',
      title: 'feat: add button',
      body: 'Description here',
      head: 'feat/my-branch',
      base: 'main',
      draft: true,
    );

    expect(url, 'https://github.com/owner/repo/pull/42');
    expect(fakeRepo.lastCreatePrArgs, {
      'owner': 'acme',
      'repo': 'widget',
      'title': 'feat: add button',
      'body': 'Description here',
      'head': 'feat/my-branch',
      'base': 'main',
      'draft': true,
    });
  });

  test('createPullRequest uses draft=false as default', () async {
    final fakeRepo = _FakeGitHubRepo();
    final svc = GitHubService(repo: fakeRepo);

    await svc.createPullRequest(
      owner: 'acme',
      repo: 'widget',
      title: 'fix: typo',
      body: '',
      head: 'fix/typo',
      base: 'main',
    );

    expect(fakeRepo.lastCreatePrArgs?['draft'], isFalse);
  });
}
