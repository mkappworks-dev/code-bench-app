import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/debug_logger.dart';
import 'ai_provider_datasource.dart';

part 'codex_sdk_datasource_process.g.dart';

@riverpod
AIProviderDatasource codexSdkDatasourceProcess(Ref ref) {
  // TODO: read binaryPath from settings once settings model is updated
  return CodexSdkDatasourceProcess(binaryPath: 'codex');
}

/// AI provider that connects to Codex via the `codex app-server` JSON-RPC 2.0
/// interface.
///
/// Protocol lifecycle per session:
///   1. Spawn `codex app-server` (once per working directory)
///   2. Send `initialize` request → receive userAgent (version)
///   3. Send `initialized` notification
///   4. Send `account/read` to check auth
///   5. Send `thread/start` to create a session
///   6. Send `turn/start` for each user message
///   7. Receive streaming notifications (text, reasoning, tool events)
///   8. Server may send approval requests — respond via [respondToRequest]
class CodexSdkDatasourceProcess implements AIProviderDatasource {
  CodexSdkDatasourceProcess({required this.binaryPath});

  final String binaryPath;

  Process? _process;
  String? _workingDirectory;
  int _nextId = 1;

  /// Pending client→server requests, keyed by request ID.
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};

  /// Pending server→client approval requests, keyed by request ID.
  /// The server sends these and we forward them to the UI; the UI resolves
  /// the completer when the user approves or denies.
  final Map<dynamic, Completer<Map<String, dynamic>>> _pendingApprovals = {};

  StreamController<ProviderRuntimeEvent>? _streamController;
  StreamSubscription<String>? _stdoutSubscription;

  String? _providerThreadId;
  String? _version;

  @override
  String get id => 'codex';

  @override
  String get displayName => 'Codex';

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run('which', [binaryPath]).timeout(const Duration(seconds: 2));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getVersion() async {
    // Version is extracted from the `initialize` response during first
    // connection. Return cached value if already connected.
    return _version;
  }

  @override
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
  }) {
    _streamController = StreamController<ProviderRuntimeEvent>.broadcast();
    _send(prompt, sessionId, workingDirectory);
    return _streamController!.stream;
  }

  Future<void> _send(String prompt, String sessionId, String workingDirectory) async {
    try {
      _streamController?.add(ProviderInit(provider: id));

      // Spawn or reuse the app-server process
      await _ensureProcess(workingDirectory);

      // Initialize if this is a fresh process
      if (_version == null) {
        await _initialize();
        await _checkAuth();
      }

      // Start or resume a Codex thread
      _providerThreadId ??= await _startThread(sessionId, workingDirectory);

      // Send the user's turn
      await _sendTurn(prompt);

      // Events stream back via notifications; [_handleNotification] drives
      // the StreamController. We wait here until turn/completed or an error.
    } catch (e, st) {
      dLog('[CodexSdk] send failed: $e\n$st');
      _streamController?.add(ProviderStreamFailure(error: e));
      await _streamController?.close();
    }
  }

  // ─── Process management ─────────────────────────────────────────────────

  Future<void> _ensureProcess(String workingDirectory) async {
    if (_process != null && _workingDirectory == workingDirectory) return;

    // Kill existing process if working directory changed
    if (_process != null) {
      _process!.kill();
      await _process!.exitCode;
      _process = null;
      _version = null;
      _providerThreadId = null;
    }

    dLog('[CodexSdk] spawning codex app-server in $workingDirectory');
    _process = await Process.start(
      binaryPath,
      ['app-server'],
      workingDirectory: workingDirectory,
      // Do NOT use runInShell — we construct args explicitly
    );
    _workingDirectory = workingDirectory;

    // Wire stdout → JSON-RPC message handler
    _stdoutSubscription = _process!.stdout
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(
          _handleLine,
          onError: (Object e) => dLog('[CodexSdk] stdout error: $e'),
          onDone: () {
            dLog('[CodexSdk] app-server stdout closed');
            _streamController?.add(const ProviderStreamFailure(error: 'Codex process exited'));
            _streamController?.close();
            _reset();
          },
        );

    // Log stderr for debugging; don't close the stream on stderr
    _process!.stderr
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen((line) => dLog('[CodexProvider.stderr] $line'));

    // If the process exits unexpectedly, clean up
    _process!.exitCode.then((code) {
      if (code != 0) {
        dLog('[CodexSdk] app-server exited with code $code');
        _streamController?.add(ProviderStreamFailure(error: 'Codex exited with code $code'));
        _streamController?.close();
      }
      _reset();
    });
  }

  // ─── JSON-RPC protocol ──────────────────────────────────────────────────

  /// Send a client→server request and await the response.
  Future<Map<String, dynamic>> _request(String method, Map<String, dynamic> params) {
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    final message = jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params});
    dLog('[CodexSdk] → $method ($id)');
    _process?.stdin.writeln(message);

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('Codex request $method (id=$id) timed out');
      },
    );
  }

  /// Send a client→server notification (no response expected).
  void _notify(String method, [Map<String, dynamic>? params]) {
    final message = jsonEncode({'jsonrpc': '2.0', 'method': method, 'params': params});
    dLog('[CodexSdk] → $method (notification)');
    _process?.stdin.writeln(message);
  }

  /// Respond to a server→client request (approval, user-input, etc.).
  void _respond(dynamic id, Map<String, dynamic> result) {
    final message = jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result});
    dLog('[CodexSdk] → response to server request $id');
    _process?.stdin.writeln(message);
  }

  // ─── Incoming message routing ────────────────────────────────────────────

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(line) as Map<String, dynamic>;
    } catch (e) {
      dLog('[CodexSdk] JSON parse error: $e on: $line');
      return;
    }

    final id = json['id'];
    final method = json['method'] as String?;
    final result = json['result'];
    final error = json['error'];

    if (id != null && result != null) {
      // Client→server response (our pending request resolved)
      _handleResponse(id, result as Map<String, dynamic>);
    } else if (id != null && error != null) {
      // Error response to our request
      _handleErrorResponse(id, error as Map<String, dynamic>);
    } else if (id != null && method != null) {
      // Server→client request (e.g. approval, user-input)
      _handleServerRequest(id, method, json['params'] as Map<String, dynamic>?);
    } else if (method != null) {
      // Server→client notification (no id)
      _handleNotification(method, json['params'] as Map<String, dynamic>?);
    }
  }

  void _handleResponse(dynamic id, Map<String, dynamic> result) {
    final completer = _pendingRequests.remove(id);
    if (completer != null) {
      completer.complete(result);
    } else {
      dLog('[CodexSdk] No pending request for id $id');
    }
  }

  void _handleErrorResponse(dynamic id, Map<String, dynamic> error) {
    final completer = _pendingRequests.remove(id);
    final message = error['message'] as String? ?? 'Unknown error';
    if (completer != null) {
      completer.completeError(Exception('Codex error: $message'));
    }
    _streamController?.add(ProviderStreamFailure(error: 'Codex error: $message'));
  }

  /// Handle a request that the Codex server sends TO US (approval, user-input).
  void _handleServerRequest(dynamic id, String method, Map<String, dynamic>? params) {
    dLog('[CodexSdk] ← server request: $method (id=$id)');

    switch (method) {
      case 'item/commandExecution/requestApproval':
      case 'item/fileRead/requestApproval':
      case 'item/fileChange/requestApproval':
      case 'applyPatchApproval':
      case 'execCommandApproval':
        _emitPermissionRequest(id, method, params);

      case 'item/tool/requestUserInput':
        // User-input questions — emit as permission request for now
        // TODO: dedicated user-input event type
        _emitPermissionRequest(id, method, params);

      case 'account/chatgptAuthTokens/refresh':
        // Auth token refresh — auto-approve for now
        _respond(id, {'ok': true});

      default:
        dLog('[CodexSdk] Unknown server request: $method — auto-denying');
        _respond(id, {'decision': 'denied'});
    }
  }

  void _emitPermissionRequest(dynamic id, String method, Map<String, dynamic>? params) {
    final requestId = id.toString();

    // Store completer so [respondToRequest] can resolve it
    final completer = Completer<Map<String, dynamic>>();
    _pendingApprovals[requestId] = completer;

    _streamController?.add(
      ProviderPermissionRequest(requestId: requestId, toolName: _methodToToolName(method), toolInput: params ?? {}),
    );

    // When the UI resolves the approval, send the response back to Codex
    completer.future.then(
      (result) => _respond(id, result),
      onError: (Object e) {
        dLog('[CodexSdk] Approval error: $e — denying');
        _respond(id, {'decision': 'denied'});
      },
    );
  }

  /// Handle a server→client notification (no response expected).
  void _handleNotification(String method, Map<String, dynamic>? params) {
    switch (method) {
      // ── Text streaming ─────────────────────────────────────────────────
      case 'item/agentMessage/delta':
        final delta = params?['delta'] as String?;
        if (delta != null && delta.isNotEmpty) {
          _streamController?.add(ProviderTextDelta(text: delta));
        }

      // ── Reasoning / thinking ───────────────────────────────────────────
      case 'item/reasoning/textDelta':
      case 'item/reasoning/summaryTextDelta':
        final delta = params?['delta'] as String?;
        if (delta != null && delta.isNotEmpty) {
          _streamController?.add(ProviderThinkingDelta(thinking: delta));
        }

      // ── Turn lifecycle ─────────────────────────────────────────────────
      case 'turn/started':
        dLog('[CodexSdk] Turn started');

      case 'turn/completed':
        dLog('[CodexSdk] Turn completed');
        _streamController?.add(const ProviderStreamDone());
        _streamController?.close();

      case 'turn/aborted':
        final reason = params?['reason'] as String? ?? 'Turn aborted';
        dLog('[CodexSdk] Turn aborted: $reason');
        _streamController?.add(ProviderStreamFailure(error: reason));
        _streamController?.close();

      // ── Session lifecycle ──────────────────────────────────────────────
      case 'session/connecting':
        dLog('[CodexSdk] Session connecting');
      case 'session/ready':
        dLog('[CodexSdk] Session ready');
      case 'session/started':
        dLog('[CodexSdk] Session started');
      case 'session/exited':
      case 'session/closed':
        dLog('[CodexSdk] Session exited/closed');
        _reset();

      // ── Item lifecycle (tool calls) ────────────────────────────────────
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

      // ── Thread lifecycle ───────────────────────────────────────────────
      case 'thread/started':
        final thread = params?['thread'] as Map<String, dynamic>?;
        _providerThreadId = thread?['id'] as String?;
        dLog('[CodexSdk] Thread started: $_providerThreadId');

      case 'thread/tokenUsage/updated':
        // Token usage — ignore for now
        break;

      // ── Errors / warnings ─────────────────────────────────────────────
      case 'error':
        final errorPayload = params?['error'] as Map<String, dynamic>?;
        final message = errorPayload?['message'] as String? ?? params?['message'] as String? ?? 'Provider error';
        final willRetry = params?['willRetry'] == true;
        if (!willRetry) {
          _streamController?.add(ProviderStreamFailure(error: message));
          _streamController?.close();
        } else {
          dLog('[CodexSdk] Recoverable error (will retry): $message');
        }

      case 'process/stderr':
        final message = params?['message'] as String? ?? '';
        dLog('[CodexProvider.internal-stderr] $message');

      default:
        dLog('[CodexSdk] Ignoring notification: $method');
    }
  }

  // ─── Protocol steps ──────────────────────────────────────────────────────

  Future<void> _initialize() async {
    final result = await _request('initialize', {
      'clientInfo': {'name': 'code_bench', 'title': 'Code Bench', 'version': '1.0.0'},
      'capabilities': {'experimentalApi': true},
    });

    // Extract version from userAgent: "codex/1.2.3 other-info"
    final userAgent = result['userAgent'] as String?;
    if (userAgent != null) {
      final match = RegExp(r'/([^\s]+)').firstMatch(userAgent);
      _version = match?.group(1);
    }
    dLog('[CodexSdk] version: $_version');

    // Required acknowledgement after initialize
    _notify('initialized');
  }

  Future<void> _checkAuth() async {
    final result = await _request('account/read', {});
    final requiresAuth = result['requiresOpenaiAuth'] as bool? ?? false;
    if (requiresAuth) {
      throw Exception('Codex is not authenticated. Run `codex login` in your terminal.');
    }
    dLog('[CodexSdk] Auth ok');
  }

  Future<String> _startThread(String sessionId, String workingDirectory) async {
    final result = await _request('thread/start', {
      'cwd': workingDirectory,
      // Use sessionId as a resume cursor if available
      if (sessionId.isNotEmpty) 'resumeThreadId': sessionId,
    });
    final threadId = result['thread']?['id'] as String? ?? const Uuid().v4();
    dLog('[CodexSdk] Thread started: $threadId');
    return threadId;
  }

  Future<void> _sendTurn(String prompt) async {
    await _request('turn/start', {'input': prompt});
    dLog('[CodexSdk] Turn started');
  }

  // ─── Public approval API ──────────────────────────────────────────────────

  /// Called by the chat notifier when the user approves or denies a
  /// permission request. [decision] is one of: "approved", "denied".
  @override
  void respondToPermissionRequest(String requestId, {required bool approved}) {
    final completer = _pendingApprovals.remove(requestId);
    if (completer == null) {
      dLog('[CodexSdk] No pending approval for requestId $requestId');
      return;
    }
    completer.complete({'decision': approved ? 'approved' : 'denied'});
  }

  // ─── Cancel / cleanup ─────────────────────────────────────────────────────

  @override
  void cancel() {
    dLog('[CodexSdk] Cancelling in-flight turn');
    // Interrupt the current turn if one is running
    if (_providerThreadId != null) {
      _notify('turn/interrupt', {'threadId': _providerThreadId});
    }
    _streamController?.close();
  }

  void _reset() {
    _process = null;
    _workingDirectory = null;
    _version = null;
    _providerThreadId = null;
    _pendingRequests.clear();
    _pendingApprovals.clear();
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

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
