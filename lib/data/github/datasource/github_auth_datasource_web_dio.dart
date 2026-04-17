import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../_core/http/dio_factory.dart';
import '../../_core/secure_storage.dart';
import '../models/repository.dart';
import 'github_auth_datasource.dart';

part 'github_auth_datasource_web_dio.g.dart';

@Riverpod(keepAlive: true)
GitHubAuthDatasource githubAuthDatasource(Ref ref) => GitHubAuthDatasourceWeb(ref.watch(secureStorageProvider));

/// Web/OAuth-backed implementation of [GitHubAuthDatasource].
class GitHubAuthDatasourceWeb implements GitHubAuthDatasource {
  GitHubAuthDatasourceWeb(this._storage);

  final SecureStorage _storage;

  // NOTE: In production, store client credentials server-side.
  // For this desktop app they are embedded (common for desktop OAuth apps).
  static const _clientId = 'YOUR_GITHUB_CLIENT_ID';

  @override
  Future<GitHubAccount> authenticate() async {
    try {
      // Build authorization URL
      final authUrl = Uri.parse(ApiConstants.githubAuthUrl).replace(
        queryParameters: {
          'client_id': _clientId,
          'scope': ApiConstants.githubScopes,
          'redirect_uri': AppConstants.oauthCallbackUrl,
        },
      );

      // Launch browser and wait for callback
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: AppConstants.oauthScheme,
      );

      // Extract code from callback
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw const AuthException('OAuth callback missing code');

      // Exchange code for token
      final token = await _exchangeCodeForToken(code);
      await _storage.writeGitHubToken(token);

      // Fetch user info and cache for offline startup
      final account = await _fetchUserInfo(token);
      await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
      return account;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('GitHub authentication failed', originalError: e);
    }
  }

  Future<String> _exchangeCodeForToken(String code) async {
    final dio = DioFactory.create(baseUrl: 'https://github.com');
    final response = await dio.post(
      '/login/oauth/access_token',
      data: {'client_id': _clientId, 'code': code, 'redirect_uri': AppConstants.oauthCallbackUrl},
      options: Options(headers: {'Accept': 'application/json'}),
    );
    final data = response.data as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null) {
      throw AuthException('Failed to obtain access token: ${data['error_description'] ?? data['error']}');
    }
    return token;
  }

  Future<GitHubAccount> _fetchUserInfo(String token) async {
    final dio = DioFactory.create(baseUrl: ApiConstants.githubApiBaseUrl);
    final response = await dio.get(
      '/user',
      options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github.v3+json'}),
    );
    final data = response.data as Map<String, dynamic>;
    return GitHubAccount(
      username: data['login'] as String,
      avatarUrl: data['avatar_url'] as String,
      email: data['email'] as String?,
      name: data['name'] as String?,
    );
  }

  /// Signs in using a user-provided Personal Access Token.
  ///
  /// Validates the token by calling `/user`, persists it to secure storage
  /// on success, and returns the populated account. Throws [AuthException]
  /// if the token is rejected or the request fails — callers must handle
  /// errors and must not persist the token themselves.
  @override
  Future<GitHubAccount> signInWithPat(String token) async {
    try {
      final account = await _fetchUserInfo(token);
      await _storage.writeGitHubToken(token);
      await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
      return account;
    } on AuthException {
      rethrow;
    } catch (e) {
      // Deliberately do NOT interpolate `e` here — a Dio error's toString()
      // can surface request headers (including the PAT). See
      // macos/Runner/README.md threat model.
      throw const AuthException('GitHub token rejected');
    }
  }

  @override
  Future<GitHubAccount?> getStoredAccount() async {
    final token = await _storage.readGitHubToken();
    if (token == null) return null;
    final json = await _storage.readGitHubAccount();
    if (json != null) {
      try {
        return GitHubAccount.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (e) {
        dLog('[GitHubAuthDatasource] cached account parse failed, falling back to network: $e');
      }
    }
    // Fallback for first launch after upgrade (no cached account yet)
    try {
      final account = await _fetchUserInfo(token);
      await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
      return account;
    } on DioException catch (e) {
      dLog('[GitHubAuthDatasource] getStoredAccount network fallback failed: ${e.type} ${e.response?.statusCode}');
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.readGitHubToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> signOut() async {
    await _storage.deleteGitHubToken();
    await _storage.deleteGitHubAccount();
  }
}
