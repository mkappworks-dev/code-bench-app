import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/http/dio_factory.dart';
import '../../../data/_core/secure_storage.dart';
import '../models/repository.dart';
import 'github_api_datasource.dart';

part 'github_api_datasource_dio.g.dart';

/// Provides a [GitHubApiDatasource] initialised with the stored token,
/// or `null` when no token is available.
///
/// Wires an `onUnauthorized` callback that fires when GitHub rejects the
/// token on a real API call (not a deliberate `validateToken()` probe).
/// The callback clears the stored credential and self-invalidates this
/// provider. Because [githubRepositoryProvider] watches this provider,
/// and [githubServiceProvider] watches the repo, and [gitHubAuthProvider]
/// watches the service, the invalidation cascades up the reactive graph
/// and the UI transitions to the disconnected state automatically — with
/// no cross-layer import required.
@Riverpod(keepAlive: true)
Future<GitHubApiDatasource?> githubApiDatasource(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  final token = await storage.readGitHubToken();
  if (token == null) return null;
  return GitHubApiDatasourceDio(
    token,
    onUnauthorized: () async {
      await storage.deleteGitHubToken();
      await storage.deleteGitHubAccount();
      // Self-invalidate — cascades up through repo → service → auth notifier.
      ref.invalidate(githubApiDatasourceProvider);
    },
  );
}

/// Dio-backed implementation of [GitHubApiDatasource].
///
/// SECURITY: Do NOT attach `LogInterceptor(requestHeader: true)` or any
/// logger that dumps request headers. The `Authorization` header contains
/// the user's GitHub Personal Access Token, and anything that prints it
/// to the console is one `debugPrint` away from a leak.
///
/// On any 401 response from a "real" API call (not a deliberate
/// `validateToken()` probe — that path opts out via
/// [_skipUnauthorizedHandlerKey]), the optional [onUnauthorized] callback
/// fires exactly once per instance. Because a new instance is constructed
/// on every provider rebuild after sign-out, the once-per-instance guard
/// is sufficient for de-duping a 401-cluster without leaking across
/// sessions.
class GitHubApiDatasourceDio implements GitHubApiDatasource {
  GitHubApiDatasourceDio(String token, {Future<void> Function()? onUnauthorized})
    : _onUnauthorized = onUnauthorized,
      _dio = DioFactory.create(
        baseUrl: ApiConstants.githubApiBaseUrl,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github.v3+json'},
      ) {
    _attachUnauthorizedInterceptor();
  }

  /// Test-only constructor that accepts a pre-configured [Dio] instance so
  /// tests can inject a fake [HttpClientAdapter] without hitting real GitHub.
  @visibleForTesting
  GitHubApiDatasourceDio.withDio(Dio dio, {Future<void> Function()? onUnauthorized})
    : _onUnauthorized = onUnauthorized,
      _dio = dio {
    _attachUnauthorizedInterceptor();
  }

  /// `Options.extra` key that opts a request out of the 401 → onUnauthorized
  /// handler. Used by [validateToken] which has its own "401 means no" path
  /// (returns `null`) — surfacing that 401 to the global handler would
  /// trigger sign-out from a probe instead of from a user-facing failure.
  static const String _skipUnauthorizedHandlerKey = 'skipUnauthorizedHandler';

  final Dio _dio;
  final Future<void> Function()? _onUnauthorized;
  bool _firedOnce = false;

  void _attachUnauthorizedInterceptor() {
    final cb = _onUnauthorized;
    if (cb == null) return;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          final skip = e.requestOptions.extra[_skipUnauthorizedHandlerKey] == true;
          if (e.response?.statusCode == 401 && !skip && !_firedOnce) {
            _firedOnce = true;
            try {
              await cb();
            } catch (cbErr) {
              // Reset so a subsequent 401 can retry the cleanup (e.g. if
              // the keychain was temporarily locked).
              _firedOnce = false;
              sLog('[GitHubApiDatasourceDio] onUnauthorized cleanup failed: ${cbErr.runtimeType}');
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  @override
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

  @override
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
  @override
  Future<String?> validateToken() async {
    try {
      final response = await _dio.get(
        '/user',
        // Probe path — opt out of the 401 → onUnauthorized handler so a
        // stale token detected here triggers sign-out via the deliberate
        // path (the caller decides what to do with `null`), not as a side
        // effect of the probe itself.
        options: Options(extra: const {_skipUnauthorizedHandlerKey: true}),
      );
      final data = response.data as Map<String, dynamic>;
      return data['login'] as String?;
    } on DioException catch (e) {
      // Only log the exception type to avoid any risk of a future
      // `toString()` override leaking the Authorization header.
      dLog('[GitHubApiDatasourceDio] validateToken failed: ${e.type} ${e.response?.statusCode}');
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

  @override
  Future<List<GitTreeItem>> getRepositoryTree(String owner, String repo, String branch) async {
    try {
      final response = await _dio.get('/repos/$owner/$repo/git/trees/$branch', queryParameters: {'recursive': '1'});
      final data = response.data as Map<String, dynamic>;
      return (data['tree'] as List).map((t) => GitTreeItem.fromJson(t as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw NetworkException('Failed to get repository tree', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  @override
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

  @override
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

  @override
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
  @override
  Future<Map<String, dynamic>> getPullRequest(String owner, String repo, int number) async {
    try {
      final response = await _dio.get('/repos/$owner/$repo/pulls/$number');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException('Failed to get PR', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  // Validates commit SHAs before interpolating them into API paths.
  // Accepts 7–40 hex chars (full or abbreviated SHA). A hostile payload
  // with path segments (e.g. "../pulls") is rejected here.
  static final _safeSha = RegExp(r'^[0-9a-f]{7,40}$');

  /// Lists check-runs (CI statuses) for a commit SHA. Used by the PR card
  /// to render CI chips next to the PR title.
  @override
  Future<List<Map<String, dynamic>>> getCheckRuns(String owner, String repo, String sha) async {
    if (!_safeSha.hasMatch(sha)) {
      sLog('[getCheckRuns] non-hex SHA rejected: "$sha"');
      throw ArgumentError('Invalid commit SHA: $sha');
    }
    try {
      final response = await _dio.get('/repos/$owner/$repo/commits/$sha/check-runs');
      final data = response.data as Map<String, dynamic>;
      return (data['check_runs'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw NetworkException('Failed to get check runs', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  /// Posts an APPROVE review on a pull request.
  @override
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
  @override
  Future<void> mergePullRequest(String owner, String repo, int number) async {
    try {
      await _dio.put('/repos/$owner/$repo/pulls/$number/merge');
    } on DioException catch (e) {
      throw NetworkException('Failed to merge PR', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  /// Creates a pull request. Returns the HTML URL of the created PR.
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
