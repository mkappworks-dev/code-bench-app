import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/http/dio_factory.dart';
import '../../../data/_core/secure_storage.dart';
import '../models/app_installation.dart';
import '../models/repository.dart';
import 'github_api_datasource.dart';

part 'github_api_datasource_dio.g.dart';

// onUnauthorized clears the token and self-invalidates — cascades up through repo → service → auth notifier automatically.
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

/// SECURITY: Do NOT attach `LogInterceptor(requestHeader: true)` — the `Authorization` header contains the PAT.
// onUnauthorized fires once per instance on real 401s; new instance per rebuild means no cross-session leakage.
class GitHubApiDatasourceDio implements GitHubApiDatasource {
  GitHubApiDatasourceDio(String token, {Future<void> Function()? onUnauthorized})
    : _onUnauthorized = onUnauthorized,
      _dio = DioFactory.create(
        baseUrl: ApiConstants.githubApiBaseUrl,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github.v3+json'},
      ) {
    _attachUnauthorizedInterceptor();
  }

  @visibleForTesting
  GitHubApiDatasourceDio.withDio(Dio dio, {Future<void> Function()? onUnauthorized})
    : _onUnauthorized = onUnauthorized,
      _dio = dio {
    _attachUnauthorizedInterceptor();
  }

  // Opts a request out of the 401 → onUnauthorized handler — validateToken has its own "401 means no" path.
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
  @override
  Future<String?> validateToken() async {
    try {
      final response = await _dio.get('/user', options: Options(extra: const {_skipUnauthorizedHandlerKey: true}));
      final data = response.data as Map<String, dynamic>;
      return data['login'] as String?;
    } on DioException catch (e) {
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

  @override
  Future<void> approvePullRequest(String owner, String repo, int number) async {
    try {
      await _dio.post('/repos/$owner/$repo/pulls/$number/reviews', data: {'event': 'APPROVE'});
    } on DioException catch (e) {
      throw NetworkException('Failed to approve PR', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  @override
  Future<void> mergePullRequest(String owner, String repo, int number) async {
    try {
      await _dio.put('/repos/$owner/$repo/pulls/$number/merge');
    } on DioException catch (e) {
      throw NetworkException('Failed to merge PR', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  @override
  Future<List<GitHubAppInstallation>> getInstallations() async {
    try {
      final response = await _dio.get('/user/installations', queryParameters: {'per_page': 100});
      final data = response.data as Map<String, dynamic>;
      final items = (data['installations'] as List?) ?? [];
      return items.map((item) {
        final i = item as Map<String, dynamic>;
        final account = i['account'] as Map<String, dynamic>? ?? {};
        return GitHubAppInstallation(
          id: i['id'] as int,
          accountLogin: account['login'] as String? ?? '',
          isOrg: (account['type'] as String?)?.toLowerCase() == 'organization',
        );
      }).toList();
    } on DioException catch (e) {
      throw NetworkException('Failed to get app installations', statusCode: e.response?.statusCode, originalError: e);
    } catch (e) {
      // Catches TypeError/cast failures from unexpected GitHub response shapes.
      dLog('[GitHubApiDatasourceDio] getInstallations parse error: ${e.runtimeType}');
      rethrow;
    }
  }

  @override
  Future<String?> findOpenPrUrlForBranch(String owner, String repo, String branch) async {
    try {
      final response = await _dio.get(
        '/repos/$owner/$repo/pulls',
        queryParameters: {'state': 'open', 'head': '$owner:$branch', 'per_page': 1},
      );
      final items = response.data as List;
      if (items.isEmpty) return null;
      final url = (items.first as Map<String, dynamic>)['html_url'] as String?;
      // Guard: missing html_url would silently re-enable "Create PR" against an already-open PR.
      if (url == null) {
        dLog('[GitHubApiDatasourceDio] findOpenPrUrlForBranch: html_url missing from PR payload');
      }
      return url;
    } on DioException catch (e) {
      throw NetworkException('Failed to check existing PRs', statusCode: e.response?.statusCode, originalError: e);
    }
  }

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
