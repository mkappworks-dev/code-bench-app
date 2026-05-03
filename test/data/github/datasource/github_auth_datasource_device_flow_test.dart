import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/data/_core/secure_storage.dart';
import 'package:code_bench_app/data/github/datasource/github_auth_datasource_web_dio.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }
}

ResponseBody _json(int status, Object? body) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

class _InMemorySecureStorage extends Fake implements SecureStorage {
  String? token;
  String? account;

  @override
  Future<void> writeGitHubToken(String t) async => token = t;

  @override
  Future<void> writeGitHubAccount(String json) async => account = json;
}

GitHubAuthDatasourceWeb _datasource(_FakeAdapter githubAdapter, _FakeAdapter apiAdapter, {SecureStorage? storage}) {
  final githubDio = Dio(BaseOptions(baseUrl: 'https://github.com'));
  githubDio.httpClientAdapter = githubAdapter;
  final apiDio = Dio(BaseOptions(baseUrl: 'https://api.github.com'));
  apiDio.httpClientAdapter = apiAdapter;
  return GitHubAuthDatasourceWeb.withDios(storage ?? _InMemorySecureStorage(), githubDio, apiDio);
}

void main() {
  group('requestDeviceCode', () {
    test('parses the GitHub response into DeviceCodeResponse', () async {
      final githubAdapter = _FakeAdapter((opts) async {
        expect(opts.path, contains('/login/device/code'));
        expect(opts.method, 'POST');
        return _json(200, {
          'device_code': 'dev-xyz',
          'user_code': 'WDJB-MJHT',
          'verification_uri': 'https://github.com/login/device',
          'interval': 5,
          'expires_in': 900,
        });
      });
      final apiAdapter = _FakeAdapter((_) async => fail('api should not be called'));

      final ds = _datasource(githubAdapter, apiAdapter);
      final code = await ds.requestDeviceCode();

      expect(code.userCode, 'WDJB-MJHT');
      expect(code.verificationUri, 'https://github.com/login/device');
      expect(code.deviceCode, 'dev-xyz');
      expect(code.interval, 5);
      expect(code.expiresIn, 900);
    });

    test('surfaces GitHub error_description in the AuthException', () async {
      final githubAdapter = _FakeAdapter((opts) async {
        return _json(403, {
          'error': 'unauthorized_client',
          'error_description': 'Device flow is not enabled for this app.',
        });
      });
      final apiAdapter = _FakeAdapter((_) async => fail('api should not be called'));

      final ds = _datasource(githubAdapter, apiAdapter);

      await expectLater(
        ds.requestDeviceCode(),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Device flow is not enabled'))),
      );
    });
  });

  group('pollForUserToken', () {
    test('returns GitHubAccount when /access_token returns access_token', () async {
      final storage = _InMemorySecureStorage();
      final githubAdapter = _FakeAdapter((opts) async {
        expect(opts.path, contains('/login/oauth/access_token'));
        return _json(200, {'access_token': 'gho_xxx', 'token_type': 'bearer'});
      });
      final apiAdapter = _FakeAdapter((opts) async {
        expect(opts.path, contains('/user'));
        return _json(200, {
          'login': 'octocat',
          'avatar_url': 'https://example.com/a.png',
          'name': 'Octocat',
          'email': 'oct@cat.com',
        });
      });

      final ds = _datasource(githubAdapter, apiAdapter, storage: storage);
      final account = await ds.pollForUserToken('dev-xyz', 0);

      expect(account, isNotNull);
      expect(account!.username, 'octocat');
      expect(storage.token, 'gho_xxx');
    });

    test('retries on authorization_pending then returns account', () async {
      var calls = 0;
      final githubAdapter = _FakeAdapter((opts) async {
        calls++;
        if (calls == 1) return _json(200, {'error': 'authorization_pending'});
        return _json(200, {'access_token': 'gho_xxx', 'token_type': 'bearer'});
      });
      final apiAdapter = _FakeAdapter((_) async {
        return _json(200, {'login': 'octocat', 'avatar_url': 'a', 'name': 'O', 'email': null});
      });

      final ds = _datasource(githubAdapter, apiAdapter);
      final account = await ds.pollForUserToken('dev-xyz', 0);

      expect(calls, 2);
      expect(account!.username, 'octocat');
    });

    test('throws AuthException on expired_token', () async {
      final githubAdapter = _FakeAdapter((_) async => _json(200, {'error': 'expired_token'}));
      final apiAdapter = _FakeAdapter((_) async => fail('api should not be called'));

      final ds = _datasource(githubAdapter, apiAdapter);

      expect(() => ds.pollForUserToken('dev-xyz', 0), throwsA(isA<AuthException>()));
    });

    test('throws AuthException on access_denied', () async {
      final githubAdapter = _FakeAdapter((_) async => _json(200, {'error': 'access_denied'}));
      final apiAdapter = _FakeAdapter((_) async => fail('api should not be called'));

      final ds = _datasource(githubAdapter, apiAdapter);

      expect(() => ds.pollForUserToken('dev-xyz', 0), throwsA(isA<AuthException>()));
    });

    test('returns null when cancelSignal completes', () async {
      final cancel = Completer<void>();
      final githubAdapter = _FakeAdapter((_) async {
        return _json(200, {'error': 'authorization_pending'});
      });
      final apiAdapter = _FakeAdapter((_) async => fail('api should not be called'));

      final ds = _datasource(githubAdapter, apiAdapter);
      final future = ds.pollForUserToken('dev-xyz', 1, cancelSignal: cancel.future);

      // Cancel after a brief moment to let one poll fire if any
      await Future.delayed(const Duration(milliseconds: 10));
      cancel.complete();

      final result = await future;
      expect(result, isNull);
    });
  });
}
