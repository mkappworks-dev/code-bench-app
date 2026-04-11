import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/errors/app_exception.dart';
import '../../data/datasources/local/secure_storage_source.dart';
import '../../data/models/repository.dart';

part 'github_api_service.g.dart';

@Riverpod(keepAlive: true)
Future<GitHubApiService?> githubApiService(Ref ref) async {
  final storage = ref.watch(secureStorageSourceProvider);
  final token = await storage.readGitHubToken();
  if (token == null) return null;
  return GitHubApiService(token);
}

class GitHubApiService {
  GitHubApiService(String token, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.githubApiBaseUrl,
              headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github.v3+json'},
            ),
          );

  // SECURITY: Do NOT attach `LogInterceptor(requestHeader: true)` or any
  // logger that dumps request headers. The `Authorization` header above
  // contains the user's GitHub Personal Access Token, and anything that
  // prints it to the console is one `debugPrint` away from a leak.

  final Dio _dio;

  Future<List<Repository>> listRepositories({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/user/repos',
        queryParameters: {'sort': 'updated', 'per_page': 30, 'page': page},
      );
      return (response.data as List).map((r) => _repoFromGitHub(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw NetworkException('Failed to list repositories', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  Future<List<Repository>> searchRepositories(String query) async {
    try {
      final response = await _dio.get('/search/repositories', queryParameters: {'q': query, 'per_page': 20});
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List).map((r) => _repoFromGitHub(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw NetworkException('Search failed', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  /// Returns the GitHub username if the token is valid, null otherwise.
  /// Only catches [DioException] — a malformed response (bad JSON shape,
  /// missing `login` field) will propagate so the caller can distinguish
  /// "token rejected" from "GitHub returned something unexpected".
  Future<String?> validateToken() async {
    try {
      final response = await _dio.get('/user');
      final data = response.data as Map<String, dynamic>;
      return data['login'] as String?;
    } on DioException catch (e) {
      // Only log the exception type to avoid any risk of a future
      // `toString()` override leaking the Authorization header.
      dLog('[GitHubApiService] validateToken failed: ${e.type} ${e.response?.statusCode}');
      return null;
    }
  }

  Repository _repoFromGitHub(Map<String, dynamic> r) {
    final ownerData = r['owner'] as Map<String, dynamic>?;
    return Repository(
      id: r['id'] as int,
      name: r['name'] as String,
      owner: ownerData?['login'] as String? ?? '',
      defaultBranch: r['default_branch'] as String? ?? 'main',
      isPrivate: r['private'] as bool? ?? false,
      language: r['language'] as String?,
      starCount: r['stargazers_count'] as int? ?? 0,
      description: r['description'] as String?,
      htmlUrl: r['html_url'] as String?,
      updatedAt: r['updated_at'] != null ? DateTime.tryParse(r['updated_at'] as String) : null,
    );
  }

  Future<List<GitTreeItem>> getRepositoryTree(String owner, String repo, String branch) async {
    try {
      final response = await _dio.get('/repos/$owner/$repo/git/trees/$branch', queryParameters: {'recursive': '1'});
      final data = response.data as Map<String, dynamic>;
      return (data['tree'] as List).map((t) => GitTreeItem.fromJson(t as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw NetworkException('Failed to get repository tree', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  Future<String> getFileContent(String owner, String repo, String path, String branch) async {
    try {
      final response = await _dio.get('/repos/$owner/$repo/contents/$path', queryParameters: {'ref': branch});
      final data = response.data as Map<String, dynamic>;
      final encoded = data['content'] as String;
      return utf8.decode(base64.decode(encoded.replaceAll('\n', '')));
    } on DioException catch (e) {
      throw NetworkException('Failed to get file content', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  // Branch/ref names that are safe to render in UI and (future-proofing)
  // feed to `git` argv. Matches the loose subset of git check-ref-format:
  // ASCII word chars, `.`, `/`, `-`, no leading `-`, bounded length.
  // A hostile fork that returns an exotic ref name will be silently
  // dropped from the picker rather than risking a shell-injection bug
  // the next time a caller wires these into a Process.run call.
  static final _safeBranchName = RegExp(r'^[A-Za-z0-9._/-]{1,255}$');

  Future<List<String>> listBranches(String owner, String repo) async {
    try {
      final response = await _dio.get('/repos/$owner/$repo/branches', queryParameters: {'per_page': 50});
      return (response.data as List)
          .map((b) => b['name'] as String)
          .where((name) => !name.startsWith('-') && _safeBranchName.hasMatch(name))
          .toList();
    } on DioException catch (e) {
      throw NetworkException('Failed to list branches', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  Future<List<Map<String, dynamic>>> listPullRequests(String owner, String repo, {String state = 'open'}) async {
    try {
      final response = await _dio.get('/repos/$owner/$repo/pulls', queryParameters: {'state': state, 'per_page': 50});
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw NetworkException('Failed to list pull requests', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  /// Fetches a single pull request by number. Returns the raw GitHub
  /// payload — callers that only need a handful of fields are cheaper
  /// to feed raw maps than to maintain a typed PR model for fields we
  /// don't strongly typecheck yet.
  Future<Map<String, dynamic>> getPullRequest(String owner, String repo, int number) async {
    try {
      final response = await _dio.get('/repos/$owner/$repo/pulls/$number');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException('Failed to get PR', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  /// Lists check-runs (CI statuses) for a commit SHA. Used by the PR card
  /// to render CI chips next to the PR title.
  Future<List<Map<String, dynamic>>> getCheckRuns(String owner, String repo, String sha) async {
    try {
      final response = await _dio.get('/repos/$owner/$repo/commits/$sha/check-runs');
      final data = response.data as Map<String, dynamic>;
      return (data['check_runs'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw NetworkException('Failed to get check runs', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  /// Posts an APPROVE review on a pull request.
  Future<void> approvePullRequest(String owner, String repo, int number) async {
    try {
      await _dio.post('/repos/$owner/$repo/pulls/$number/reviews', data: {'event': 'APPROVE'});
    } on DioException catch (e) {
      throw NetworkException('Failed to approve PR', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  /// Merges a pull request. Uses the default merge strategy configured
  /// on the repo — we deliberately don't expose strategy as a parameter
  /// until there is UI that lets the user pick one.
  Future<void> mergePullRequest(String owner, String repo, int number) async {
    try {
      await _dio.put('/repos/$owner/$repo/pulls/$number/merge');
    } on DioException catch (e) {
      throw NetworkException('Failed to merge PR', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  /// Creates a pull request. Returns the HTML URL of the created PR.
  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
  }) async {
    try {
      final response = await _dio.post(
        '/repos/$owner/$repo/pulls',
        data: {'title': title, 'body': body, 'head': head, 'base': base, 'draft': draft},
      );
      final data = response.data as Map<String, dynamic>;
      return data['html_url'] as String;
    } on DioException catch (e) {
      throw NetworkException('Failed to create pull request', statusCode: e.response?.statusCode, originalError: e);
    }
  }
}
