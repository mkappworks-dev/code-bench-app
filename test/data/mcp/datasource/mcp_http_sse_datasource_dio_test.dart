// test/data/mcp/datasource/mcp_http_sse_datasource_dio_test.dart
//
// Tests for McpHttpSseDatasourceDio — focuses on the HTTP/SSE race where an
// SSE message arrives before sendRequest registers the completer.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:code_bench_app/data/mcp/datasource/mcp_http_sse_datasource_dio.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake Dio — implements just enough of the Dio interface for these tests.
// Uses noSuchMethod to handle all other members (tests never call them).
// ---------------------------------------------------------------------------

class _FakeDio implements Dio {
  _FakeDio(this._sseController, this._onPost);

  final StreamController<Uint8List> _sseController;

  /// Called synchronously *inside* post(), before returning.
  /// The test uses this to emit an SSE response mid-await, exposing the race.
  final void Function(int requestId) _onPost;

  // -- GET: return a streaming SSE response backed by [_sseController] ------

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final responseBody = ResponseBody(
      _sseController.stream,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
    return Response<T>(
      data: responseBody as T,
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }

  // -- POST: emit SSE response synchronously (exposes the race) -------------

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final body = data as String;
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final requestId = decoded['id'] as int;

    // Emit the SSE response synchronously — before sendRequest can register
    // the completer. This is the race condition the fix must handle.
    _onPost(requestId);

    return Response<T>(requestOptions: RequestOptions(path: path), statusCode: 202);
  }

  // -- Everything else is unimplemented (noSuchMethod handles it) -----------

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not implemented');

  // The `options` field is accessed by RequestOptions internally; satisfy it.
  @override
  BaseOptions options = BaseOptions();

  @override
  Interceptors get interceptors => Interceptors();

  @override
  HttpClientAdapter get httpClientAdapter => throw UnimplementedError();

  @override
  set httpClientAdapter(HttpClientAdapter value) => throw UnimplementedError();

  @override
  Transformer get transformer => throw UnimplementedError();

  @override
  set transformer(Transformer value) => throw UnimplementedError();

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// Helper: encode SSE frames as Uint8List
// ---------------------------------------------------------------------------

Uint8List _sseFrame(Map<String, dynamic> json) => Uint8List.fromList(utf8.encode('data: ${jsonEncode(json)}\n\n'));

Uint8List _sseEndpointFrame(String url) => Uint8List.fromList(utf8.encode('event: endpoint\ndata: $url\n\n'));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('McpHttpSseDatasourceDio', () {
    test('sendRequest resolves even when SSE response arrives synchronously '
        'during the POST (before completer is registered in _pending) — '
        'verifies the HTTP/SSE race fix', () async {
      final sseController = StreamController<Uint8List>();

      void onPost(int requestId) {
        // Emit the SSE reply synchronously inside post().
        // In the buggy code the completer is NOT in _pending yet at this
        // point, so _onEvent drops the message and the future hangs.
        final reply = {
          'jsonrpc': '2.0',
          'id': requestId,
          'result': {'ok': true},
        };
        sseController.add(_sseFrame(reply));
      }

      final fakeDio = _FakeDio(sseController, onPost);
      final datasource = McpHttpSseDatasourceDio(dio: fakeDio);

      // Establish SSE connection.
      await datasource.connect(
        const McpServerConfig(
          id: 'test',
          name: 'test',
          transport: McpTransport.httpSse,
          url: 'http://localhost:9999/sse',
        ),
      );

      // Provide the endpoint URL so _postUrl is set.
      sseController.add(_sseEndpointFrame('http://localhost:9999/message'));

      // Let the stream listener process the endpoint event.
      await Future<void>.delayed(Duration.zero);

      // This must complete even though the SSE reply was emitted
      // synchronously during post() — before the completer was registered.
      final result = await datasource.sendRequest('tools/list').timeout(const Duration(seconds: 3));

      expect(result['result'], {'ok': true});

      await sseController.close();
      await datasource.close();
    });

    test('sendRequest propagates POST errors and removes the pending completer', () async {
      final sseController = StreamController<Uint8List>();

      void onPost(int _) {
        throw DioException(
          requestOptions: RequestOptions(path: '/message'),
          message: 'network error',
        );
      }

      final fakeDio = _FakeDio(sseController, onPost);
      final datasource = McpHttpSseDatasourceDio(dio: fakeDio);

      await datasource.connect(
        const McpServerConfig(
          id: 'test',
          name: 'test',
          transport: McpTransport.httpSse,
          url: 'http://localhost:9999/sse',
        ),
      );

      sseController.add(_sseEndpointFrame('http://localhost:9999/message'));
      await Future<void>.delayed(Duration.zero);

      await expectLater(() => datasource.sendRequest('tools/list'), throwsA(isA<DioException>()));

      await sseController.close();
      await datasource.close();
    });
  });
}
