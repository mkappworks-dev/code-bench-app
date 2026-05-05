import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/github/models/app_installation.dart';
import '../../data/github/models/device_code_response.dart';
import '../../data/github/repository/github_repository.dart';
import '../../data/github/repository/github_repository_impl.dart';
import '../../data/github/models/repository.dart';

export '../../data/github/datasource/github_api_datasource_dio.dart' show githubApiDatasourceProvider;
export '../../data/github/models/app_installation.dart' show GitHubAppInstallation;
export '../../data/github/models/repository.dart' show GitHubAccount, GitTreeItem, Repository;

part 'github_service.g.dart';

@Riverpod(keepAlive: true)
Future<GitHubService> githubService(Ref ref) async {
  final repo = await ref.watch(githubRepositoryProvider.future);
  return GitHubService(repo: repo);
}

/// Thin delegation service for GitHub operations.
///
/// All GitHub business logic that requires composition lives here.
/// [GitHubRepository] retains the primitives.
class GitHubService {
  GitHubService({required GitHubRepository repo}) : _repo = repo;

  final GitHubRepository _repo;

  Future<DeviceCodeResponse> requestDeviceCode() => _repo.requestDeviceCode();
  Future<GitHubAccount?> pollForUserToken(
    String deviceCode,
    int intervalSeconds,
    int expiresIn, {
    Future<void>? cancelSignal,
  }) => _repo.pollForUserToken(deviceCode, intervalSeconds, expiresIn, cancelSignal: cancelSignal);
  Future<GitHubAccount?> getStoredAccount() => _repo.getStoredAccount();
  Future<bool> isAuthenticated() => _repo.isAuthenticated();
  Future<bool> validateStoredToken() => _repo.validateStoredToken();
  Future<void> signOut() => _repo.signOut();
  Future<List<Repository>> listRepositories({int page = 1}) => _repo.listRepositories(page: page);
  Future<List<Repository>> searchRepositories(String query) => _repo.searchRepositories(query);
  Future<String?> validateToken() => _repo.validateToken();
  Future<List<GitTreeItem>> getRepositoryTree(String owner, String repo, String branch) =>
      _repo.getRepositoryTree(owner, repo, branch);
  Future<String> getFileContent(String owner, String repo, String path, String branch) =>
      _repo.getFileContent(owner, repo, path, branch);
  Future<List<String>> listBranches(String owner, String repo) => _repo.listBranches(owner, repo);
  Future<List<Map<String, dynamic>>> listPullRequests(String owner, String repo, {String state = 'open'}) =>
      _repo.listPullRequests(owner, repo, state: state);
  Future<Map<String, dynamic>> getPullRequest(String owner, String repo, int number) =>
      _repo.getPullRequest(owner, repo, number);
  Future<List<Map<String, dynamic>>> getCheckRuns(String owner, String repo, String sha) =>
      _repo.getCheckRuns(owner, repo, sha);
  Future<void> approvePullRequest(String owner, String repo, int number) =>
      _repo.approvePullRequest(owner, repo, number);
  Future<void> mergePullRequest(String owner, String repo, int number) => _repo.mergePullRequest(owner, repo, number);
  Future<List<GitHubAppInstallation>> getInstallations() => _repo.getInstallations();
  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
  }) =>
      _repo.createPullRequest(owner: owner, repo: repo, title: title, body: body, head: head, base: base, draft: draft);
}
