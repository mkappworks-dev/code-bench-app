import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../data/datasources/local/secure_storage_source.dart';
import '../../data/models/repository.dart';

part 'github_auth_service.g.dart';

@Riverpod(keepAlive: true)
GitHubAuthService githubAuthService(Ref ref) {
  return GitHubAuthService(ref.watch(secureStorageSourceProvider));
}

class GitHubAuthService {
  GitHubAuthService(this._storage);

  final SecureStorageSource _storage;

  // NOTE: In production, store client credentials server-side.
  // For this desktop app they are embedded (common for desktop OAuth apps).
  static const _clientId = 'YOUR_GITHUB_CLIENT_ID';

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

      // Fetch user info
      return await _fetchUserInfo(token);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('GitHub authentication failed', originalError: e);
    }
  }

  Future<String> _exchangeCodeForToken(String code) async {
    final dio = Dio();
    final response = await dio.post(
      ApiConstants.githubTokenUrl,
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
    final dio = Dio();
    final response = await dio.get(
      '${ApiConstants.githubApiBaseUrl}/user',
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

  Future<GitHubAccount?> getStoredAccount() async {
    final token = await _storage.readGitHubToken();
    if (token == null) return null;
    try {
      return await _fetchUserInfo(token);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.readGitHubToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> signOut() async {
    await _storage.deleteGitHubToken();
  }
}
