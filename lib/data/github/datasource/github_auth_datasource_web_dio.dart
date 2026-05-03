import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  Future<GitHubAccount?> pollForUserToken(String deviceCode, int intervalSeconds, {Future<void>? cancelSignal}) async {
    var interval = Duration(seconds: intervalSeconds);

    while (true) {
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
        dLog('[GitHubAuthDatasource] poll failed (${e.type})');
        throw AuthException('Device flow polling failed', originalError: e);
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
          continue;
        case 'expired_token':
          throw const AuthException('Device code expired — please try signing in again');
        case 'access_denied':
          throw const AuthException('Authorization denied');
        default:
          throw AuthException('Device flow failed: ${data['error_description'] ?? error}');
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
    final response = await _apiDio.get(
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
      dLog('[GitHubAuthDatasource] signInWithPat failed (${e.runtimeType}) — original suppressed for PAT safety');
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
    try {
      final account = await _fetchUserInfo(token);
      await _storage.writeGitHubAccount(jsonEncode(account.toJson()));
      return account;
    } catch (e) {
      dLog('[GitHubAuthDatasource] getStoredAccount network fallback failed (${e.runtimeType})');
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
