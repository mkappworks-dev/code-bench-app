import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../_core/http/dio_factory.dart';
import '../../_core/secure_storage.dart';
import '../models/device_code_response.dart';
import '../models/repository.dart';
import 'github_auth_datasource.dart';

part 'github_auth_datasource_web_dio.g.dart';

@Riverpod(keepAlive: true)
GitHubAuthDatasource githubAuthDatasource(Ref ref) => GitHubAuthDatasourceWeb(ref.watch(secureStorageProvider));

/// Device-Flow-backed implementation of [GitHubAuthDatasource].
///
/// Holds two pre-configured Dio instances: one for github.com (auth
/// endpoints) and one for api.github.com (user lookup). Tests inject
/// stub adapters via [GitHubAuthDatasourceWeb.withDios].
class GitHubAuthDatasourceWeb implements GitHubAuthDatasource {
  GitHubAuthDatasourceWeb(this._storage)
    : _githubDio = DioFactory.create(baseUrl: 'https://github.com'),
      _apiDio = DioFactory.create(baseUrl: ApiConstants.githubApiBaseUrl);

  /// Test-only constructor — accepts pre-configured [Dio] instances so tests
  /// can inject a fake [HttpClientAdapter] without hitting real GitHub.
  @visibleForTesting
  GitHubAuthDatasourceWeb.withDios(this._storage, this._githubDio, this._apiDio);

  final SecureStorage _storage;
  final Dio _githubDio;
  final Dio _apiDio;

  @override
  Future<DeviceCodeResponse> requestDeviceCode() async {
    try {
      final response = await _githubDio.post(
        '/login/device/code',
        data: {'client_id': ApiConstants.githubClientId},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return DeviceCodeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      dLog(
        '[GitHubAuthDatasource] requestDeviceCode failed '
        '(${e.type}, status=$status, body=$body)',
      );

      // GitHub returns the error machine-readable when it can — surface that
      // to the user so they can fix the misconfiguration (e.g. "device flow
      // not enabled on this app", "bad client_id"). This endpoint never sees
      // user secrets in either request or response, so quoting the body is
      // safe.
      var message = 'Failed to request device code';
      if (body is Map) {
        final desc = body['error_description'] ?? body['error'];
        if (desc is String && desc.isNotEmpty) {
          message = 'GitHub rejected device code request: $desc';
        }
      }
      throw AuthException(message, originalError: e);
    }
  }

  @override
  Future<GitHubAccount?> pollForUserToken(
    String deviceCode,
    int intervalSeconds,
    int expiresIn, {
    Future<void>? cancelSignal,
  }) async {
    var interval = Duration(seconds: intervalSeconds);
    const maxInterval = Duration(seconds: 60);
    final deadline = DateTime.now().add(Duration(seconds: expiresIn));

    while (true) {
      // Local expiry guard — catches the case where slow_down bumps push us
      // past the device code lifetime before GitHub returns expired_token.
      if (DateTime.now().isAfter(deadline)) {
        throw const AuthException('Device code expired — please try signing in again');
      }

      final cancelled = await _waitOrCancel(interval, cancelSignal);
      if (cancelled) return null;

      final Response<dynamic> response;
      try {
        response = await _githubDio.post(
          '/login/oauth/access_token',
          data: {
            'client_id': ApiConstants.githubClientId,
            'device_code': deviceCode,
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          },
          options: Options(headers: {'Accept': 'application/json'}),
        );
      } on DioException catch (e) {
        // Network errors (timeout, connection refused, DNS failure) are
        // transient — wait the current interval and retry rather than tearing
        // down the session. The deadline guard above bounds the retry window.
        dLog('[GitHubAuthDatasource] poll transient error (${e.type}) — retrying');
        continue;
      }

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token != null) {
        await _storage.writeGitHubToken(token);
        final account = await _fetchUserInfo(token);
        await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
        return account;
      }

      final error = data['error'] as String?;
      switch (error) {
        case 'authorization_pending':
          continue;
        case 'slow_down':
          interval += const Duration(seconds: 5);
          if (interval > maxInterval) interval = maxInterval;
          continue;
        case 'expired_token':
          throw const AuthException('Device code expired — please try signing in again');
        case 'access_denied':
          throw const AuthException('Authorization denied');
        default:
          if (error != null) {
            final desc = data['error_description'];
            throw AuthException(desc is String && desc.isNotEmpty ? desc : 'Device flow failed: $error');
          }
          // Neither access_token nor error — unexpected response shape.
          dLog('[GitHubAuthDatasource] poll: unexpected response (no token, no error field)');
          throw const AuthException('Unexpected response from GitHub during sign-in. Please try again.');
      }
    }
  }

  /// Returns true if [cancelSignal] completed before [interval] elapsed.
  Future<bool> _waitOrCancel(Duration interval, Future<void>? cancelSignal) async {
    if (cancelSignal == null) {
      await Future<void>.delayed(interval);
      return false;
    }
    final delay = Future<void>.delayed(interval).then((_) => false);
    final cancel = cancelSignal.then((_) => true);
    return Future.any([delay, cancel]);
  }

  Future<GitHubAccount> _fetchUserInfo(String token) async {
    final Response<dynamic> response;
    try {
      response = await _apiDio.get(
        '/user',
        options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github.v3+json'}),
      );
    } on DioException catch (e) {
      dLog('[GitHubAuthDatasource] _fetchUserInfo failed: ${e.type} ${e.response?.statusCode}');
      throw AuthException('Failed to fetch GitHub user info', originalError: e);
    }
    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      dLog('[GitHubAuthDatasource] _fetchUserInfo: unexpected response shape (${raw.runtimeType})');
      throw const AuthException('GitHub returned an unexpected user-info shape');
    }
    final login = raw['login'];
    final avatarUrl = raw['avatar_url'];
    if (login is! String || avatarUrl is! String) {
      dLog('[GitHubAuthDatasource] _fetchUserInfo: missing required fields');
      throw const AuthException('GitHub returned an unexpected user-info shape');
    }
    return GitHubAccount(
      username: login,
      avatarUrl: avatarUrl,
      email: raw['email'] as String?,
      name: raw['name'] as String?,
    );
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
    // Only swallow network/transient failures — identified by the wrapped
    // DioException in originalError. Shape mismatches and storage errors are
    // real bugs and should propagate rather than silently returning null.
    try {
      final account = await _fetchUserInfo(token);
      await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
      return account;
    } on AuthException catch (e) {
      if (e.originalError is! DioException) rethrow;
      dLog('[GitHubAuthDatasource] getStoredAccount network fallback failed: ${e.runtimeType}');
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.readGitHubToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<bool> validateStoredToken() async {
    final token = await _storage.readGitHubToken();
    if (token == null) {
      throw StateError('No stored token to validate');
    }
    try {
      await _apiDio.get(
        '/user',
        options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github.v3+json'}),
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Logged at exception-type only — never log the response body
        // since GitHub may echo headers in error responses.
        dLog('[GitHubAuthDatasource] validateStoredToken: token rejected (401)');
        return false;
      }
      // Transient (5xx, network) — let the caller decide. Don't sign the
      // user out because the wifi blinked.
      dLog('[GitHubAuthDatasource] validateStoredToken transient failure: ${e.type} ${e.response?.statusCode}');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    // NOTE: Local-only revocation. Device Flow (RFC 8628) issues no
    // client_secret, so this client cannot authenticate a call to
    // GitHub's POST /applications/{client_id}/token DELETE endpoint —
    // the server-side grant remains live until the user revokes the
    // app at github.com/settings/applications, the token is naturally
    // expired by GitHub, or the app owner revokes it. The
    // disconnected-card UI surfaces a "Revoke on GitHub" affordance to
    // close that gap user-side.
    await _storage.deleteGitHubToken();
    await _storage.deleteGitHubAccount();
  }
}
