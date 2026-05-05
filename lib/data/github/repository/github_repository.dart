import '../models/app_installation.dart';
import '../models/device_code_response.dart';
import '../models/repository.dart';

abstract interface class GitHubRepository {
  // Auth methods
  Future<DeviceCodeResponse> requestDeviceCode();

  Future<GitHubAccount?> pollForUserToken(
    String deviceCode,
    int intervalSeconds,
    int expiresIn, {
    Future<void>? cancelSignal,
  });

  Future<GitHubAccount?> getStoredAccount();

  Future<bool> isAuthenticated();

  /// Verifies the stored token against GitHub. Returns `true` on 200,
  /// `false` on 401, rethrows on transient failures. See
  /// `GitHubAuthDatasource.validateStoredToken` for the full contract.
  Future<bool> validateStoredToken();

  Future<void> signOut();

  // API methods
  Future<List<Repository>> listRepositories({int page = 1});

  Future<List<Repository>> searchRepositories(String query);

  /// Returns the GitHub username if the token is valid, null otherwise.
  Future<String?> validateToken();

  Future<List<GitTreeItem>> getRepositoryTree(String owner, String repo, String branch);

  Future<String> getFileContent(String owner, String repo, String path, String branch);

  Future<List<String>> listBranches(String owner, String repo);

  Future<List<Map<String, dynamic>>> listPullRequests(String owner, String repo, {String state = 'open'});

  /// Fetches a single pull request by number. Returns the raw GitHub payload.
  Future<Map<String, dynamic>> getPullRequest(String owner, String repo, int number);

  /// Lists check-runs (CI statuses) for a commit SHA.
  Future<List<Map<String, dynamic>>> getCheckRuns(String owner, String repo, String sha);

  /// Posts an APPROVE review on a pull request.
  Future<void> approvePullRequest(String owner, String repo, int number);

  /// Merges a pull request.
  Future<void> mergePullRequest(String owner, String repo, int number);

  /// Creates a pull request. Returns the HTML URL of the created PR.
  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
  });

  /// Returns all installations of this GitHub App accessible to the
  /// authenticated user. See [GitHubApiDatasource.getInstallations].
  Future<List<GitHubAppInstallation>> getInstallations();

  /// Returns the `html_url` of the first open PR whose head matches
  /// `{owner}:{branch}`, or `null` when none exists.
  Future<String?> findOpenPrUrlForBranch(String owner, String repo, String branch);
}
