import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/services/github/github_api_service.dart';

/// A hand-rolled `HttpClientAdapter` that routes requests to a caller-
/// supplied handler. Chosen over `package:mockito` because it avoids the
/// build_runner codegen step for a handful of tests, and over
/// `http_mock_adapter` because no new dependency is needed.
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

ResponseBody _json(int status, Object? body, {Map<String, List<String>>? headers}) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      ...?headers,
    },
  );
}

Dio _dioWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'));
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  group('validateToken', () {
    test('returns login on 200 with a well-formed body', () async {
      final adapter = _FakeAdapter((opts) async {
        expect(opts.path, contains('/user'));
        return _json(200, {'login': 'octocat', 'id': 1});
      });
      final svc = GitHubApiService('tok', dio: _dioWith(adapter));
      expect(await svc.validateToken(), 'octocat');
    });

    test('returns null on 401', () async {
      final adapter = _FakeAdapter((_) async => _json(401, {'message': 'Bad credentials'}));
      final svc = GitHubApiService('bad', dio: _dioWith(adapter));
      expect(await svc.validateToken(), isNull);
    });

    test('returns null on 5xx', () async {
      final adapter = _FakeAdapter((_) async => _json(503, {'message': 'Service Unavailable'}));
      final svc = GitHubApiService('tok', dio: _dioWith(adapter));
      expect(await svc.validateToken(), isNull);
    });

    test('returns null on network timeout', () async {
      final adapter = _FakeAdapter((opts) async {
        throw DioException(requestOptions: opts, type: DioExceptionType.connectionTimeout);
      });
      final svc = GitHubApiService('tok', dio: _dioWith(adapter));
      expect(await svc.validateToken(), isNull);
    });

    test('propagates non-DioException so malformed responses are not hidden', () async {
      final adapter = _FakeAdapter((_) async => _json(200, 'not-a-map'));
      final svc = GitHubApiService('tok', dio: _dioWith(adapter));
      // The cast `response.data as Map<String, dynamic>` throws — we want
      // this to surface instead of being swallowed as "invalid token".
      expect(svc.validateToken(), throwsA(isA<TypeError>()));
    });
  });

  group('createPullRequest', () {
    test('POSTs the expected payload and returns html_url on 201', () async {
      late RequestOptions captured;
      final adapter = _FakeAdapter((opts) async {
        captured = opts;
        return _json(201, {'html_url': 'https://github.com/octo/hello/pull/7', 'number': 7});
      });
      final svc = GitHubApiService('tok', dio: _dioWith(adapter));

      final url = await svc.createPullRequest(
        owner: 'octo',
        repo: 'hello',
        title: 'Add greeting',
        body: '- adds hello()',
        head: 'feat/greet',
        base: 'main',
        draft: true,
      );

      expect(url, 'https://github.com/octo/hello/pull/7');
      expect(captured.method, 'POST');
      expect(captured.path, '/repos/octo/hello/pulls');
      final data = captured.data as Map<String, dynamic>;
      expect(data['title'], 'Add greeting');
      expect(data['body'], '- adds hello()');
      expect(data['head'], 'feat/greet');
      expect(data['base'], 'main');
      expect(data['draft'], true);
    });

    test('throws NetworkException with the status code on 422', () async {
      final adapter = _FakeAdapter((_) async => _json(422, {'message': 'Validation Failed'}));
      final svc = GitHubApiService('tok', dio: _dioWith(adapter));
      try {
        await svc.createPullRequest(owner: 'octo', repo: 'hello', title: 't', body: 'b', head: 'feat', base: 'main');
        fail('expected NetworkException');
      } on NetworkException catch (e) {
        expect(e.statusCode, 422);
      }
    });

    test('throws NetworkException on 401 (auth failure)', () async {
      final adapter = _FakeAdapter((_) async => _json(401, {'message': 'Bad credentials'}));
      final svc = GitHubApiService('bad', dio: _dioWith(adapter));
      expect(
        () => svc.createPullRequest(owner: 'octo', repo: 'hello', title: 't', body: 'b', head: 'feat', base: 'main'),
        throwsA(isA<NetworkException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });

  group('listBranches', () {
    test('passes per_page=50 and maps names', () async {
      late RequestOptions captured;
      final adapter = _FakeAdapter((opts) async {
        captured = opts;
        return _json(200, [
          {'name': 'main'},
          {'name': 'dev'},
          {'name': 'feat/2026-04-10-foo'},
        ]);
      });
      final svc = GitHubApiService('tok', dio: _dioWith(adapter));
      final branches = await svc.listBranches('octo', 'hello');
      expect(branches, ['main', 'dev', 'feat/2026-04-10-foo']);
      expect(captured.queryParameters['per_page'], 50);
      expect(captured.path, '/repos/octo/hello/branches');
    });

    test('throws NetworkException on 404', () async {
      final adapter = _FakeAdapter((_) async => _json(404, {'message': 'Not Found'}));
      final svc = GitHubApiService('tok', dio: _dioWith(adapter));
      expect(
        () => svc.listBranches('octo', 'missing'),
        throwsA(isA<NetworkException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}
