import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_installation.dart';
import '../models/device_code_response.dart';
import '../models/repository.dart';
import '../datasource/github_api_datasource.dart';
import '../datasource/github_api_datasource_dio.dart';
import '../datasource/github_auth_datasource.dart';
import '../datasource/github_auth_datasource_web_dio.dart';
import 'github_repository.dart';

part 'github_repository_impl.g.dart';

@Riverpod(keepAlive: true)
Future<GitHubRepository> githubRepository(Ref ref) async {
  final auth = ref.watch(githubAuthDatasourceProvider);
  final api = await ref.watch(githubApiDatasourceProvider.future);
  return GitHubRepositoryImpl(auth: auth, api: api);
}

class GitHubRepositoryImpl implements GitHubRepository {
  GitHubRepositoryImpl({required GitHubAuthDatasource auth, GitHubApiDatasource? api}) : _auth = auth, _api = api;

  final GitHubAuthDatasource _auth;
  final GitHubApiDatasource? _api;

  GitHubApiDatasource get _requireApi {
    final api = _api;
    if (api == null) throw StateError('GitHub API datasource is not available — no token stored');
    return api;
  }

  @override
  Future<DeviceCodeResponse> requestDeviceCode() => _auth.requestDeviceCode();

  @override
  Future<GitHubAccount?> pollForUserToken(
    String deviceCode,
    int intervalSeconds,
    int expiresIn, {
    Future<void>? cancelSignal,
  }) => _auth.pollForUserToken(deviceCode, intervalSeconds, expiresIn, cancelSignal: cancelSignal);

  @override
  Future<GitHubAccount?> getStoredAccount() => _auth.getStoredAccount();

  @override
  Future<bool> isAuthenticated() => _auth.isAuthenticated();

  @override
  Future<bool> validateStoredToken() => _auth.validateStoredToken();

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<List<Repository>> listRepositories({int page = 1}) => _requireApi.listRepositories(page: page);

  @override
  Future<List<Repository>> searchRepositories(String query) => _requireApi.searchRepositories(query);

  @override
  Future<String?> validateToken() => _requireApi.validateToken();

  @override
  Future<List<GitTreeItem>> getRepositoryTree(String owner, String repo, String branch) =>
      _requireApi.getRepositoryTree(owner, repo, branch);

  @override
  Future<String> getFileContent(String owner, String repo, String path, String branch) =>
      _requireApi.getFileContent(owner, repo, path, branch);

  @override
  Future<List<String>> listBranches(String owner, String repo) => _requireApi.listBranches(owner, repo);

  @override
  Future<List<Map<String, dynamic>>> listPullRequests(String owner, String repo, {String state = 'open'}) =>
      _requireApi.listPullRequests(owner, repo, state: state);

  @override
  Future<Map<String, dynamic>> getPullRequest(String owner, String repo, int number) =>
      _requireApi.getPullRequest(owner, repo, number);

  @override
  Future<List<Map<String, dynamic>>> getCheckRuns(String owner, String repo, String sha) =>
      _requireApi.getCheckRuns(owner, repo, sha);

  @override
  Future<void> approvePullRequest(String owner, String repo, int number) =>
      _requireApi.approvePullRequest(owner, repo, number);

  @override
  Future<void> mergePullRequest(String owner, String repo, int number) =>
      _requireApi.mergePullRequest(owner, repo, number);

  @override
  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
  }) => _requireApi.createPullRequest(
    owner: owner,
    repo: repo,
    title: title,
    body: body,
    head: head,
    base: base,
    draft: draft,
  );

  @override
  Future<List<GitHubAppInstallation>> getInstallations() => _requireApi.getInstallations();

  @override
  Future<String?> findOpenPrUrlForBranch(String owner, String repo, String branch) =>
      _requireApi.findOpenPrUrlForBranch(owner, repo, branch);
}
