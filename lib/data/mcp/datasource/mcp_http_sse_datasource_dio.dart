// lib/data/mcp/datasource/mcp_http_sse_datasource_dio.dart
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/utils/debug_logger.dart';
import '../models/mcp_server_config.dart';
import 'mcp_transport_datasource.dart';

class McpHttpSseDatasourceDio implements McpTransportDatasource {
  McpHttpSseDatasourceDio({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  final _pending = <int, Completer<Map<String, dynamic>>>{};
  int _nextId = 1;
  String? _postUrl;
  StreamSubscription<_SseEvent>? _sseSub;
  bool _dead = false;

  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  @override
  Future<void> connect(McpServerConfig config) => _connectSse(config.url!, attempt: 0);

  Future<void> _connectSse(String sseUrl, {required int attempt}) async {
    try {
      final response = await _dio.get<ResponseBody>(
        sseUrl,
        options: Options(
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
          responseType: ResponseType.stream,
        ),
      );
      final events = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .transform(const _SseLineDecoder());

      _sseSub = events.listen(
        _onEvent,
        onError: (Object e) async {
          dLog('[McpHttpSse] SSE error: $e');
          await _maybeReconnect(sseUrl, attempt);
        },
        onDone: () async => _maybeReconnect(sseUrl, attempt),
      );
    } on DioException catch (e) {
      dLog('[McpHttpSse] connect failed (attempt $attempt): $e');
      if (attempt < _maxRetries) {
        await Future<void>.delayed(_retryDelay);
        return _connectSse(sseUrl, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  Future<void> _maybeReconnect(String sseUrl, int attempt) async {
    if (_dead) return;
    if (attempt < _maxRetries) {
      await Future<void>.delayed(_retryDelay);
      await _connectSse(sseUrl, attempt: attempt + 1);
    } else {
      _dead = true;
      _failPending('MCP server disconnected after $_maxRetries retries');
    }
  }

  @override
  Future<Map<String, dynamic>> sendRequest(String method, [Map<String, dynamic>? params]) async {
    if (_dead) throw StateError('MCP server disconnected');
    if (_postUrl == null) {
      throw StateError('MCP endpoint not yet received from SSE');
    }
    final id = _nextId++;
    // Register BEFORE sending so SSE responses arriving mid-await are not dropped.
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    try {
      final body = jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': ?params});
      await _dio.post<void>(
        _postUrl!,
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } catch (e) {
      // Remove the pending completer so _failPending does not double-complete
      // it later. Rethrow so the caller receives the error directly — the
      // completer future is abandoned and must not be completed separately.
      _pending.remove(id);
      rethrow;
    }
    return completer.future;
  }

  @override
  void sendNotification(String method, [Map<String, dynamic>? params]) {
    if (_dead || _postUrl == null) return;
    final body = jsonEncode({'jsonrpc': '2.0', 'method': method, 'params': ?params});
    _dio.post<void>(
      _postUrl!,
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  @override
  Future<void> close() async {
    _dead = true;
    await _sseSub?.cancel();
    _failPending('MCP connection closed');
  }

  void _onEvent(_SseEvent event) {
    if (event.type == 'endpoint') {
      final raw = event.data.trim();
      final uri = Uri.tryParse(raw);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        _postUrl = raw;
      } else {
        dLog('[McpHttpSse] rejected endpoint URL with invalid scheme: $raw');
        sLog('[McpHttpSse] rejected endpoint URL with invalid scheme: ${uri?.scheme}');
      }
      return;
    }
    if (event.data.isEmpty) return;
    try {
      final msg = jsonDecode(event.data) as Map<String, dynamic>;
      final id = msg['id'];
      if (id is int) _pending.remove(id)?.complete(msg);
    } catch (e) {
      dLog('[McpHttpSse] JSON parse error: $e');
    }
  }

  void _failPending(String reason) {
    for (final c in _pending.values) {
      c.completeError(StateError(reason));
    }
    _pending.clear();
  }
}

class _SseEvent {
  _SseEvent({required this.type, required this.data});
  final String type;
  final String data;
}

class _SseLineDecoder extends StreamTransformerBase<String, _SseEvent> {
  const _SseLineDecoder();

  @override
  Stream<_SseEvent> bind(Stream<String> stream) async* {
    String? type;
    final dataBuf = StringBuffer();
    await for (final line in stream) {
      if (line.isEmpty) {
        if (dataBuf.isNotEmpty) {
          yield _SseEvent(type: type ?? 'message', data: dataBuf.toString());
          type = null;
          dataBuf.clear();
        }
      } else if (line.startsWith('event: ')) {
        type = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        if (dataBuf.isNotEmpty) dataBuf.write('\n');
        dataBuf.write(line.substring(6));
      }
    }
  }
}
