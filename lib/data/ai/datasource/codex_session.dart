import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';
import '../models/provider_runtime_event.dart';
import '../models/provider_turn_settings.dart';
import '../util/setting_mappers.dart';
import 'process_launcher.dart';
import 'provider_input_guards.dart';

/// Owns one Codex `app-server` process bound to one chat session; first [sendAndStream] spawns + handshakes, [dispose] tears down.
class CodexSession {
  CodexSession({
    required this.sessionId,
    required this.workingDirectory,
    required this.exePath,
    required this.env,
    ProcessLauncher? processLauncher,
  }) : _processLauncher = processLauncher ?? defaultProcessLauncher,
       _lastActiveAt = DateTime.now();

  final String sessionId;
  final String workingDirectory;
  final String exePath;
  final Map<String, String> env;
  final ProcessLauncher _processLauncher;

  static const int _stderrCap = 64 * 1024;
  static const int _consecutiveParseFailureLimit = 5;

  Process? _process;
  String? _version;
  String? _providerThreadId;
  StreamController<ProviderRuntimeEvent>? _streamController;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  final StringBuffer _stderrBuffer = StringBuffer();
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final Map<dynamic, Completer<Map<String, dynamic>>> _pendingApprovals = {};
  int _nextId = 1;
  int _consecutiveJsonParseFailures = 0;
  DateTime _lastActiveAt;
  bool _disposed = false;

  DateTime get lastActiveAt => _lastActiveAt;
  bool get isInFlight => _streamController?.isClosed == false;
  bool get hasPendingApprovals => _pendingApprovals.isNotEmpty;

  Stream<ProviderRuntimeEvent> sendAndStream({required String prompt, ProviderTurnSettings? settings}) {
    if (_disposed) throw StateError('CodexSession disposed');
    _lastActiveAt = DateTime.now();
    final previous = _streamController;
    if (previous != null && !previous.isClosed) {
      // Surface the swap so a still-listening consumer sees a terminal event rather than `onDone` masquerading as success.
      previous.add(const ProviderStreamFailure(error: 'preempted by new turn'));
      _resetTurn();
    }
    // Single-subscription so ProviderInit buffers until `await for` subscribes.
    _streamController = StreamController<ProviderRuntimeEvent>();
    _send(prompt, settings);
    return _streamController!.stream;
  }

  void cancel() {
    if (_providerThreadId != null && _process != null) {
      _notify('turn/interrupt', {'threadId': _providerThreadId});
    }
    _resetTurn();
  }

  void respondToPermissionRequest(String requestId, {required bool approved}) {
    final completer = _pendingApprovals.remove(requestId);
    if (completer == null) {
      dLog('[CodexSession] No pending approval for requestId $requestId');
      return;
    }
    completer.complete({'decision': approved ? 'approved' : 'denied'});
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _resetTurn();
    _process?.kill();
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
    _stderrBuffer.clear();
    _process = null;
    _providerThreadId = null;
    _version = null;
  }

  Future<void> _send(String prompt, ProviderTurnSettings? settings) async {
    final controller = _streamController;
    if (controller == null) return;
    try {
      controller.add(ProviderInit(provider: 'codex', modelId: settings?.modelId));

      // sessionId guard — a non-UUID value could resume a foreign thread or allow attacker-shaped input at the RPC boundary.
      if (!uuidV4Regex.hasMatch(sessionId)) {
        sLog('[CodexCli] rejected non-UUID sessionId at RPC boundary');
        controller.add(const ProviderStreamFailure(error: 'invalid sessionId shape'));
        return;
      }

      // workingDirectory guard — `/` or a stale path would give Codex tool-use access outside the project.
      if (!workingDirectory.startsWith('/') || workingDirectory == '/' || !Directory(workingDirectory).existsSync()) {
        sLog('[CodexCli] rejected workingDirectory: $workingDirectory');
        controller.add(const ProviderStreamFailure(error: 'invalid workingDirectory'));
        return;
      }

      await _ensureProcess();

      if (_version == null) {
        await _initialize();
      }

      _providerThreadId ??= await _startThread(settings?.systemPrompt);

      await _sendTurn(prompt, settings);
    } catch (e, st) {
      // Bail if a newer turn replaced the controller mid-await (preempt path); otherwise a "codex turn ended" StateError leaks onto the new turn.
      if (!identical(_streamController, controller)) return;
      dLog('[CodexCli] send failed: ${redactSecrets('$e')}\n$st');
      controller.add(ProviderStreamFailure(error: e));
      // _resetTurn not _resetProcess — keep the process alive; exitCode handler calls _resetProcess if it died.
      _resetTurn();
    }
  }

  Future<void> _ensureProcess() async {
    if (_process != null) return;

    dLog('[CodexCli] spawning codex app-server in $workingDirectory');

    final spawned = await _processLauncher(
      exePath,
      const ['app-server'],
      workingDirectory: workingDirectory,
      runInShell: false,
      includeParentEnvironment: false,
      environment: env,
    );
    _process = spawned;

    // allowMalformed so a multi-byte char split across reads doesn't kill the stream.
    _stdoutSubscription = spawned.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          _handleLine,
          onError: (Object e) {
            // Short-circuit late callbacks fired after dispose() or a process swap so they don't surface failures on a controller that belongs to a different lifecycle.
            if (_disposed || !identical(_process, spawned)) return;
            dLog('[CodexCli] stdout error: ${redactSecrets('$e')}');
            _streamController?.add(ProviderStreamFailure(error: 'Codex stdout error: ${e.runtimeType}'));
            _resetProcess();
          },
          onDone: () {
            if (_disposed || !identical(_process, spawned)) return;
            dLog('[CodexCli] app-server stdout closed');
            _streamController?.add(const ProviderStreamFailure(error: 'Codex process exited'));
            _resetProcess();
          },
        );

    _stderrSubscription = spawned.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((line) {
          dLog('[CodexProvider.stderr] ${redactSecrets(line)}');
          if (_stderrBuffer.length >= _stderrCap) return;
          final remaining = _stderrCap - _stderrBuffer.length;
          final out = line.length <= remaining ? line : line.substring(0, remaining);
          _stderrBuffer.writeln(out);
        });

    unawaited(
      spawned.exitCode
          .then((code) {
            if (_disposed || !identical(_process, spawned)) return;
            if (code != 0) {
              dLog('[CodexCli] app-server exited with code $code\nstderr=${redactSecrets(_stderrBuffer.toString())}');
              _streamController?.add(
                ProviderStreamFailure(
                  error: 'Codex exited with code $code',
                  details: redactSecrets(_stderrBuffer.toString()),
                ),
              );
            } else if (_providerThreadId != null) {
              // exit 0 mid-turn — surface so the caller doesn't hang waiting for turn/completed.
              dLog('[CodexCli] app-server exited 0 unexpectedly mid-turn');
              _streamController?.add(const ProviderStreamFailure(error: 'Codex process exited unexpectedly'));
            }
            _resetProcess();
          })
          .catchError((Object e) {
            if (_disposed || !identical(_process, spawned)) return;
            dLog('[CodexCli] exitCode handler threw: ${redactSecrets('$e')}');
            _resetProcess();
          }),
    );
  }

  Future<void> _initialize() async {
    final result = await _request('initialize', {
      'clientInfo': {'name': 'code_bench', 'title': 'Code Bench', 'version': '1.0.0'},
      'capabilities': {'experimentalApi': true},
    });

    final userAgent = result['userAgent'] as String?;
    if (userAgent != null) {
      final match = RegExp(r'/([^\s]+)').firstMatch(userAgent);
      _version = match?.group(1);
    }
    dLog('[CodexCli] version: $_version');

    _notify('initialized');
  }

  Future<String> _startThread(String? developerInstructions) async {
    final result = await _request('thread/start', {
      'cwd': workingDirectory,
      if (sessionId.isNotEmpty) 'resumeThreadId': sessionId,
      if (developerInstructions != null && developerInstructions.isNotEmpty)
        'developerInstructions': developerInstructions,
    });
    final threadId = result['thread']?['id'] as String?;
    if (threadId == null) {
      dLog('[CodexCli] thread/start response missing thread.id: $result');
      throw Exception('Codex thread/start returned no thread ID');
    }
    dLog('[CodexCli] Thread started: $threadId');
    return threadId;
  }

  Future<void> _sendTurn(String prompt, ProviderTurnSettings? settings) async {
    final effort = settings?.effort;
    final permission = settings?.permission;
    await _request('turn/start', {
      'threadId': _providerThreadId!,
      'input': [
        {'type': 'text', 'text': prompt},
      ],
      'model': ?settings?.modelId,
      if (effort != null) 'effort': mapCodexEffort(effort),
      if (permission != null) 'sandboxPolicy': mapCodexSandboxPolicy(permission),
      if (permission != null) 'approvalPolicy': mapCodexApprovalPolicy(permission),
    });
    dLog('[CodexCli] Turn started');
  }

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(line) as Map<String, dynamic>;
      _consecutiveJsonParseFailures = 0;
    } catch (e) {
      _consecutiveJsonParseFailures++;
      // Cap preview at 64 chars — redactSecrets only strips known token shapes; a 256-char window can leak prompt text or file contents that the model just read.
      final preview = line.length > 64 ? '${line.substring(0, 64)}…' : line;
      dLog(
        '[CodexCli] JSON parse error ($_consecutiveJsonParseFailures/$_consecutiveParseFailureLimit): '
        '$e on: ${redactSecrets(preview)}',
      );
      if (_consecutiveJsonParseFailures >= _consecutiveParseFailureLimit) {
        _streamController?.add(const ProviderStreamFailure(error: 'Codex output unparseable'));
        _process?.kill(ProcessSignal.sigterm);
        _resetTurn();
      }
      return;
    }

    final id = json['id'];
    final method = json['method'] as String?;
    final result = json['result'];
    final error = json['error'];

    if (id != null && result != null) {
      _handleResponse(id, result as Map<String, dynamic>);
    } else if (id != null && error != null) {
      _handleErrorResponse(id, error as Map<String, dynamic>);
    } else if (id != null && method != null) {
      _handleServerRequest(id, method, json['params'] as Map<String, dynamic>?);
    } else if (method != null) {
      _handleNotification(method, json['params'] as Map<String, dynamic>?);
    }
  }

  void _handleResponse(dynamic id, Map<String, dynamic> result) {
    final completer = _pendingRequests.remove(_coerceId(id));
    if (completer != null) {
      completer.complete(result);
    } else {
      dLog('[CodexCli] No pending request for id $id');
    }
  }

  void _handleErrorResponse(dynamic id, Map<String, dynamic> error) {
    final completer = _pendingRequests.remove(_coerceId(id));
    final message = error['message'] as String? ?? 'Unknown error';
    if (completer != null) {
      // Don't also emit on the controller — _send's catch already maps the completer's error to a ProviderStreamFailure; double-emit produces two failure events for one error.
      completer.completeError(Exception('Codex error: $message'));
    } else {
      // Server-acknowledged error with no pending caller: surface it directly so the user sees something rather than the turn quietly stalling.
      dLog('[CodexCli] No pending request for error id $id (server-acknowledged: $message)');
      _streamController?.add(ProviderStreamFailure(error: 'Codex error: $message'));
    }
  }

  void _handleServerRequest(dynamic id, String method, Map<String, dynamic>? params) {
    dLog('[CodexCli] ← server request: $method (id=$id)');

    switch (method) {
      case 'item/commandExecution/requestApproval':
      case 'item/fileRead/requestApproval':
      case 'item/fileChange/requestApproval':
      case 'applyPatchApproval':
      case 'execCommandApproval':
        _emitPermissionRequest(id, method, params);

      case 'item/tool/requestUserInput':
        _emitPermissionRequest(id, method, params);

      case 'account/chatgptAuthTokens/refresh':
        // Gate on `_version` (not `_providerThreadId`) — token can expire between `initialized` and `thread/start`.
        if (_version == null) {
          sLog('[CodexCli] denying account/chatgptAuthTokens/refresh — process not yet initialized (id=$id)');
          _respond(id, {'ok': false});
        } else {
          sLog('[CodexCli] auto-approving account/chatgptAuthTokens/refresh (id=$id)');
          _respond(id, {'ok': true});
        }

      default:
        // Unknown server request — deny and surface so the user sees a "please update" error rather than a silent hang.
        sLog('[CodexCli] unknown server request: $method — denying and aborting turn');
        _respond(id, {'decision': 'denied'});
        _streamController?.add(
          ProviderStreamFailure(error: 'Unsupported codex approval method: $method — please update Code Bench'),
        );
    }
  }

  void _emitPermissionRequest(dynamic id, String method, Map<String, dynamic>? params) {
    // Coerce id before stringifying — num `5.0` and int `5` must produce the same key.
    final normalized = _coerceId(id);
    final requestId = (normalized ?? id).toString();

    final completer = Completer<Map<String, dynamic>>();
    _pendingApprovals[requestId] = completer;

    _streamController?.add(
      ProviderPermissionRequest(requestId: requestId, toolName: _methodToToolName(method), toolInput: params ?? {}),
    );

    // Guard on still-live process — a dead pipe throws asynchronously and the error would be unhandled.
    completer.future.then(
      (result) {
        if (_process == null) {
          sLog('[CodexCli] Approval response dropped — process gone (id=$id)');
          return;
        }
        _respond(id, result);
      },
      onError: (Object e) {
        dLog('[CodexCli] Approval error: ${redactSecrets('$e')} — denying');
        if (_process == null) {
          sLog('[CodexCli] Approval auto-deny dropped — process gone (id=$id)');
          return;
        }
        _respond(id, {'decision': 'denied'});
      },
    );
  }

  void _handleNotification(String method, Map<String, dynamic>? params) {
    switch (method) {
      case 'item/agentMessage/delta':
        final delta = params?['delta'] as String?;
        if (delta != null && delta.isNotEmpty) {
          _streamController?.add(ProviderTextDelta(text: delta));
        }

      case 'item/reasoning/textDelta':
      case 'item/reasoning/summaryTextDelta':
        final delta = params?['delta'] as String?;
        if (delta != null && delta.isNotEmpty) {
          _streamController?.add(ProviderThinkingDelta(thinking: delta));
        }

      case 'turn/started':
        dLog('[CodexCli] Turn started');

      case 'turn/completed':
        dLog('[CodexCli] Turn completed');
        _streamController?.add(const ProviderStreamDone());
        _resetTurn();

      case 'turn/aborted':
        final reason = params?['reason'] as String? ?? 'Turn aborted';
        dLog('[CodexCli] Turn aborted: $reason');
        _streamController?.add(ProviderStreamFailure(error: reason));
        _resetTurn();

      case 'session/connecting':
        dLog('[CodexCli] Session connecting');
      case 'session/ready':
        dLog('[CodexCli] Session ready');
      case 'session/started':
        dLog('[CodexCli] Session started');
      case 'session/exited':
      case 'session/closed':
        dLog('[CodexCli] Session exited/closed');
        _resetProcess();

      case 'item/started':
        final item = params?['item'] as Map<String, dynamic>?;
        final itemType = item?['type'] as String?;
        final itemId = item?['id'] as String?;
        if (itemId != null && itemType != null) {
          _streamController?.add(ProviderToolUseStart(toolId: itemId, toolName: _normalizeItemType(itemType)));
        }

      case 'item/completed':
        final item = params?['item'] as Map<String, dynamic>?;
        final itemId = item?['id'] as String?;
        if (itemId != null) {
          _streamController?.add(ProviderToolUseComplete(toolId: itemId, input: item ?? {}));
        }

      case 'thread/started':
        final thread = params?['thread'] as Map<String, dynamic>?;
        _providerThreadId = thread?['id'] as String?;
        dLog('[CodexCli] Thread started: $_providerThreadId');

      case 'thread/tokenUsage/updated':
        break;

      case 'error':
        final errorPayload = params?['error'] as Map<String, dynamic>?;
        final message = errorPayload?['message'] as String? ?? params?['message'] as String? ?? 'Provider error';
        final willRetry = params?['willRetry'] == true;
        if (!willRetry) {
          _streamController?.add(ProviderStreamFailure(error: message));
          _resetTurn();
        } else {
          dLog('[CodexCli] Recoverable error (will retry): ${redactSecrets(message)}');
        }

      case 'process/stderr':
        final message = params?['message'] as String? ?? '';
        dLog('[CodexProvider.internal-stderr] ${redactSecrets(message)}');

      default:
        // Unknown notification — sLog so post-release builds catch new protocol additions.
        sLog('[CodexCli] ignoring unknown notification: $method');
    }
  }

  void _writeStdin(String message) {
    final stdin = _process?.stdin;
    if (stdin == null) {
      dLog('[CodexCli] write skipped — process is gone');
      return;
    }
    try {
      stdin.writeln(message);
    } catch (e) {
      dLog('[CodexCli] stdin write failed: ${redactSecrets('$e')}');
      _streamController?.add(ProviderStreamFailure(error: 'Codex stdin write failed: ${e.runtimeType}'));
      _resetProcess();
    }
  }

  Future<Map<String, dynamic>> _request(String method, Map<String, dynamic> params) {
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    final message = jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params});
    dLog('[CodexCli] → $method ($id)');
    _writeStdin(message);

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('Codex request $method (id=$id) timed out');
      },
    );
  }

  void _notify(String method, [Map<String, dynamic>? params]) {
    final message = jsonEncode({'jsonrpc': '2.0', 'method': method, 'params': params});
    dLog('[CodexCli] → $method (notification)');
    _writeStdin(message);
  }

  void _respond(dynamic id, Map<String, dynamic> result) {
    final message = jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result});
    dLog('[CodexCli] → response to server request $id');
    _writeStdin(message);
  }

  void _resetTurn() {
    if (_streamController?.isClosed == false) {
      _streamController?.close();
    }
    _streamController = null;
    _consecutiveJsonParseFailures = 0;
    for (final c in _pendingApprovals.values) {
      if (!c.isCompleted) c.completeError(StateError('codex turn ended'));
    }
    _pendingApprovals.clear();
    for (final c in _pendingRequests.values) {
      if (!c.isCompleted) c.completeError(StateError('codex turn ended'));
    }
    _pendingRequests.clear();
    _lastActiveAt = DateTime.now();
  }

  void _resetProcess() {
    _resetTurn();
    _process = null;
    _version = null;
    _providerThreadId = null;
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription?.cancel();
    _stderrSubscription = null;
    _stderrBuffer.clear();
  }

  /// `_pendingRequests` is `Map<int, Completer>` but the JSON decoder may
  /// hand back a num (e.g. `1.0`) for the response id depending on how the
  /// peer encodes it. Coerce to int defensively so the map lookup never
  /// silently misses and hangs the request until the 30s timeout.
  int? _coerceId(dynamic id) {
    if (id is int) return id;
    if (id is num) return id.toInt();
    if (id is String) return int.tryParse(id);
    return null;
  }

  String _methodToToolName(String method) {
    return switch (method) {
      'item/commandExecution/requestApproval' => 'command_execution',
      'item/fileRead/requestApproval' => 'file_read',
      'item/fileChange/requestApproval' => 'file_change',
      'applyPatchApproval' => 'apply_patch',
      'execCommandApproval' => 'exec_command',
      'item/tool/requestUserInput' => 'tool_user_input',
      _ => method,
    };
  }

  String _normalizeItemType(String raw) {
    return raw
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll(RegExp(r'[._/-]'), ' ')
        .trim()
        .toLowerCase();
  }
}
