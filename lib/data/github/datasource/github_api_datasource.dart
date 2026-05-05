import '../models/app_installation.dart';
import '../models/repository.dart';

abstract interface class GitHubApiDatasource {
  Future<List<Repository>> listRepositories({int page = 1});

  Future<List<Repository>> searchRepositories(String query);

  /// Returns the GitHub username if the token is valid, null otherwise.
  Future<String?> validateToken();

  Future<List<GitTreeItem>> getRepositoryTree(String owner, String repo, String branch);

  Future<String> getFileContent(String owner, String repo, String path, String branch);

  Future<List<String>> listBranches(String owner, String repo);

  Future<List<Map<String, dynamic>>> listPullRequests(String owner, String repo, {String state = 'open'});

  Future<Map<String, dynamic>> getPullRequest(String owner, String repo, int number);

  Future<List<Map<String, dynamic>>> getCheckRuns(String owner, String repo, String sha);

  Future<void> approvePullRequest(String owner, String repo, int number);

  Future<void> mergePullRequest(String owner, String repo, int number);

  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
  });

  Future<List<GitHubAppInstallation>> getInstallations();

  /// Returns the `html_url` of the first open PR whose head matches
  /// `{owner}:{branch}`, or `null` when none exists.
  Future<String?> findOpenPrUrlForBranch(String owner, String repo, String branch);
}
