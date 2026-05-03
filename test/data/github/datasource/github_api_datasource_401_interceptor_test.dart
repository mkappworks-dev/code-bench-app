import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/github/datasource/github_api_datasource_dio.dart';
import 'package:code_bench_app/data/github/models/repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) =>
      handler(options);
}

ResponseBody _statusOnly(int status) => ResponseBody.fromBytes([], status);

GitHubApiDatasourceDio _datasource({Future<void> Function()? onUnauthorized, required int responseStatus}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'));
  dio.httpClientAdapter = _FakeAdapter((_) async => _statusOnly(responseStatus));
  return GitHubApiDatasourceDio.withDio(dio, onUnauthorized: onUnauthorized);
}

void main() {
  group('401 interceptor', () {
    test('fires onUnauthorized exactly once on 401', () async {
      var fired = 0;
      final ds = _datasource(onUnauthorized: () async => fired++, responseStatus: 401);

      await expectLater(ds.listRepositories(), throwsA(isA<Exception>()));
      await expectLater(ds.listRepositories(), throwsA(isA<Exception>()));

      expect(fired, 1, reason: 'callback must fire exactly once per instance');
    });

    test('does not fire onUnauthorized for validateToken 401 (skip-flag path)', () async {
      var fired = 0;
      final ds = _datasource(onUnauthorized: () async => fired++, responseStatus: 401);

      final result = await ds.validateToken();
      expect(result, isNull);
      expect(fired, 0, reason: 'validateToken opts out of the interceptor');
    });

    test('does not fire onUnauthorized for non-401 errors', () async {
      var fired = 0;
      final ds = _datasource(onUnauthorized: () async => fired++, responseStatus: 403);

      await expectLater(ds.listRepositories(), throwsA(isA<Exception>()));
      expect(fired, 0);
    });

    test('resets _firedOnce when callback throws so next 401 retries cleanup', () async {
      var attempts = 0;
      final ds = _datasource(
        onUnauthorized: () async {
          attempts++;
          if (attempts == 1) throw Exception('keychain locked');
        },
        responseStatus: 401,
      );

      // First 401 — callback throws, _firedOnce resets.
      await expectLater(ds.listRepositories(), throwsA(isA<Exception>()));
      // Second 401 — callback should fire again.
      await expectLater(ds.listRepositories(), throwsA(isA<Exception>()));

      expect(attempts, 2, reason: '_firedOnce must reset after callback failure');
    });

    test('concurrent 401s only fire callback once', () async {
      var fired = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'));
      // Both requests return 401 simultaneously.
      dio.httpClientAdapter = _FakeAdapter((_) async => _statusOnly(401));
      final ds = GitHubApiDatasourceDio.withDio(dio, onUnauthorized: () async => fired++);

      await Future.wait([
        ds.listRepositories().catchError((_) => <Repository>[]),
        ds.searchRepositories('test').catchError((_) => <Repository>[]),
      ]);

      expect(fired, 1, reason: 'concurrent 401s must only trigger callback once');
    });
  });
}
