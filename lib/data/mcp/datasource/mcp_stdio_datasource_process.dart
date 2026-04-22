import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';
import '../models/mcp_server_config.dart';
import 'mcp_transport_datasource.dart';

class McpStdioDatasourceProcess implements McpTransportDatasource {
  Process? _process;
  StreamSubscription<Map<String, dynamic>>? _sub;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  int _nextId = 1;

  @override
  Future<void> connect(McpServerConfig config) async {
    final parts = _splitCommand(config.command ?? '');
    if (parts.isEmpty) {
      throw ArgumentError('MCP stdio config "${config.name}" has no command');
    }
    final executable = parts.first;
    final extraArgs = [...parts.skip(1), ...config.args];

    try {
      _process = await Process.start(
        executable,
        extraArgs,
        environment: config.env.isEmpty ? null : config.env,
        runInShell: false,
      );
    } on ProcessException catch (e) {
      sLog('[McpStdio] Process.start failed for "${config.name}": $e');
      rethrow;
    } on IOException catch (e) {
      sLog('[McpStdio] IO error starting "${config.name}": $e');
      rethrow;
    }

    final responseStream = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(_McpFrameDecoder());

    _sub = responseStream.listen(
      _onMessage,
      onError: (Object e) => dLog('[McpStdio] stdout error for "${config.name}": $e'),
    );
  }

  @override
  Future<Map<String, dynamic>> sendRequest(String method, [Map<String, dynamic>? params]) {
    final id = _nextId++;
    _writeMessage({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': ?params});
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    return completer.future;
  }

  @override
  void sendNotification(String method, [Map<String, dynamic>? params]) {
    _writeMessage({'jsonrpc': '2.0', 'method': method, 'params': ?params});
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _process?.kill(ProcessSignal.sigterm);
    await _process?.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _process?.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    _failPending('MCP connection closed');
  }

  void _onMessage(Map<String, dynamic> msg) {
    final id = msg['id'];
    if (id is int) _pending.remove(id)?.complete(msg);
  }

  void _writeMessage(Map<String, dynamic> msg) {
    final body = utf8.encode(jsonEncode(msg));
    _process!.stdin.add(utf8.encode('Content-Length: ${body.length}\r\n\r\n'));
    _process!.stdin.add(body);
  }

  void _failPending(String reason) {
    for (final c in _pending.values) {
      c.completeError(StateError(reason));
    }
    _pending.clear();
  }

  // Splits "npx -y @scope/pkg" into ["npx", "-y", "@scope/pkg"],
  // respecting single and double quotes.
  static List<String> _splitCommand(String command) {
    final parts = <String>[];
    final buf = StringBuffer();
    var inSingle = false;
    var inDouble = false;
    for (var i = 0; i < command.length; i++) {
      final ch = command[i];
      if (ch == "'" && !inDouble) {
        inSingle = !inSingle;
      } else if (ch == '"' && !inSingle) {
        inDouble = !inDouble;
      } else if (ch == ' ' && !inSingle && !inDouble) {
        if (buf.isNotEmpty) {
          parts.add(buf.toString());
          buf.clear();
        }
      } else {
        buf.write(ch);
      }
    }
    if (buf.isNotEmpty) parts.add(buf.toString());
    return parts;
  }
}

// Decodes Content-Length-framed lines from stdout into JSON-RPC messages.
// Expects output from LineSplitter: header line, blank line, JSON body line.
class _McpFrameDecoder extends StreamTransformerBase<String, Map<String, dynamic>> {
  const _McpFrameDecoder();

  @override
  Stream<Map<String, dynamic>> bind(Stream<String> stream) async* {
    int? pendingLength;
    await for (final line in stream) {
      if (pendingLength == null) {
        if (line.startsWith('Content-Length: ')) {
          pendingLength = int.tryParse(line.substring(16).trim());
        }
      } else if (line.trim().isEmpty) {
        // blank separator — next non-empty line is the body
      } else {
        try {
          yield jsonDecode(line) as Map<String, dynamic>;
        } catch (e) {
          dLog('[McpFrameDecoder] JSON parse error: $e');
        }
        pendingLength = null;
      }
    }
  }
}
