import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
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
  GitHubApiService(String token)
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.githubApiBaseUrl,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/vnd.github.v3+json',
            },
          ),
        );

  final Dio _dio;

  Future<List<Repository>> listRepositories({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/user/repos',
        queryParameters: {'sort': 'updated', 'per_page': 30, 'page': page},
      );
      return (response.data as List)
          .map((r) => _repoFromGitHub(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to list repositories',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<List<Repository>> searchRepositories(String query) async {
    try {
      final response = await _dio.get(
        '/search/repositories',
        queryParameters: {'q': query, 'per_page': 20},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List)
          .map((r) => _repoFromGitHub(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkException(
        'Search failed',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
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
      updatedAt: r['updated_at'] != null
          ? DateTime.tryParse(r['updated_at'] as String)
          : null,
    );
  }

  Future<List<GitTreeItem>> getRepositoryTree(
    String owner,
    String repo,
    String branch,
  ) async {
    try {
      final response = await _dio.get(
        '/repos/$owner/$repo/git/trees/$branch',
        queryParameters: {'recursive': '1'},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['tree'] as List)
          .map((t) => GitTreeItem.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to get repository tree',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<String> getFileContent(
    String owner,
    String repo,
    String path,
    String branch,
  ) async {
    try {
      final response = await _dio.get(
        '/repos/$owner/$repo/contents/$path',
        queryParameters: {'ref': branch},
      );
      final data = response.data as Map<String, dynamic>;
      final encoded = data['content'] as String;
      return utf8.decode(base64.decode(encoded.replaceAll('\n', '')));
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to get file content',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<List<String>> listBranches(String owner, String repo) async {
    try {
      final response = await _dio.get('/repos/$owner/$repo/branches');
      return (response.data as List).map((b) => b['name'] as String).toList();
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to list branches',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> listPullRequests(
    String owner,
    String repo, {
    String state = 'open',
  }) async {
    try {
      final response = await _dio.get(
        '/repos/$owner/$repo/pulls',
        queryParameters: {'state': state, 'per_page': 50},
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to list pull requests',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createPullRequest({
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
        data: {
          'title': title,
          'body': body,
          'head': head,
          'base': base,
          'draft': draft,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to create pull request',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }
}
