import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../shared/ai_model.dart';
import '../../shared/session_settings.dart';
import '../util/setting_mappers.dart';
import 'ai_provider_datasource.dart';
import 'binary_resolver_process.dart';
import 'provider_input_guards.dart';

part 'codex_cli_datasource_process.g.dart';

@visibleForTesting
const int codexAuthOutputSizeLimit = 64 * 1024;

// Reject parenthesised qualifiers like "(expired)" / "(read-only)" so a
// degraded session isn't read as fully authenticated.
final RegExp _codexLoggedInPattern = RegExp(r'^Logged in using [^()]+$');

@visibleForTesting
AuthStatus parseCodexAuthOutput(int exitCode, String output) {
  // Match on whole-line markers so an accidental substring (e.g. a future
  // "Logged in users: N" counter) cannot match. Exit code is intentionally
  // ignored — codex writes its status to stderr and exits 1 when signed out.
  if (output.length > codexAuthOutputSizeLimit) {
    dLog(
      '[CodexCli] auth status output exceeds ${codexAuthOutputSizeLimit}B (${output.length}B) — treating as unknown',
    );
    return const AuthStatus.unknown();
  }
  final lines = output.split('\n').map((l) => l.trim()).toList();
  if (lines.any((l) => l == 'Not logged in')) {
    return const AuthStatus.unauthenticated(signInCommand: 'codex login');
  }
  if (lines.any(_codexLoggedInPattern.hasMatch)) {
    return const AuthStatus.authenticated();
  }
  dLog('[CodexCli] auth status output unrecognised (${output.length}B) — treating as unknown');
  return const AuthStatus.unknown();
}

@visibleForTesting
Map<String, dynamic> buildCodexTurnStartParams(
  String threadId,
  String prompt, {
  String? modelId,
  ChatEffort? effort,
  ChatPermission? permission,
}) {
  // The picker's OpenAI section is fed by Codex's `model/list` RPC when
  // `openaiTransport == 'cli'`, so any [modelId] reaching here is already
  // valid for this account. Forward it verbatim — when null, Codex picks
  // its account-tier default (e.g. gpt-5.5 on free, varies by plan).
  return {
    'threadId': threadId,
    'input': [
      {'type': 'text', 'text': prompt},
    ],
    'model': ?modelId,
    if (effort != null) 'effort': mapCodexEffort(effort),
    if (permission != null) 'sandboxPolicy': mapCodexSandboxPolicy(permission),
    if (permission != null) 'approvalPolicy': mapCodexApprovalPolicy(permission),
  };
}

/// Parses the JSON result of a `model/list` JSON-RPC response and maps each
/// non-hidden entry to an [AIModel]. Visible for testing so the parsing
/// contract can be exercised without a live `codex app-server`.
@visibleForTesting
List<AIModel> parseCodexModelList(Map<String, dynamic> result) {
  final data = result['data'];
  if (data is! List) return const [];
  final models = <AIModel>[];
  var nonHiddenEntries = 0;
  for (final entry in data) {
    if (entry is! Map) continue;
    if (entry['hidden'] == true) continue;
    nonHiddenEntries++;
    final id = entry['id'];
    final modelId = entry['model'];
    final displayName = entry['displayName'];
    if (id is! String || id.isEmpty) continue;
    if (modelId is! String || modelId.isEmpty) continue;
    models.add(
      AIModel(
        id: id,
        provider: AIProvider.openai,
        name: (displayName is String && displayName.isNotEmpty) ? displayName : id,
        modelId: modelId,
      ),
    );
  }
  if (nonHiddenEntries > 0 && models.isEmpty) {
    throw const ParseException(
      'Codex model/list returned entries but none had a parseable id+model — schema may have changed',
    );
  }
  return models;
}

/// Spawns a short-lived `codex app-server`, performs the JSON-RPC handshake
/// (`initialize` → `initialized`), then queries `model/list` for the models
/// the connected ChatGPT account supports. Hidden entries are filtered out.
///
/// Isolated from [CodexCliDatasourceProcess]'s long-lived turn-streaming
/// process so a model-list refresh can never disturb an in-flight chat.
Future<List<AIModel>> fetchCodexAvailableModels({String binaryPath = 'codex'}) async {
  final resolution = await resolveBinary(binaryPath);
  final String exePath;
  final String? loginShellPath;
  switch (resolution) {
    case BinaryFound(:final path, :final shellPath):
      exePath = path;
      loginShellPath = shellPath;
    case BinaryNotFound():
      throw NetworkException('Codex CLI is not installed or not on PATH');
    case BinaryProbeFailed(:final reason):
      throw NetworkException('Could not probe Codex CLI: $reason');
  }

  final parentEnv = Platform.environment;
  final env = <String, String>{
    if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
    'PATH': loginShellPath ?? parentEnv['PATH'] ?? '/usr/bin:/bin:/usr/sbin:/sbin',
    if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
    if (parentEnv['CODEX_HOME'] != null) 'CODEX_HOME': parentEnv['CODEX_HOME']!,
  };

  Process? proc;
  StreamSubscription<String>? sub;
  try {
    proc = await Process.start(
      exePath,
      ['app-server'],
      runInShell: false,
      includeParentEnvironment: false,
      environment: env,
    );

    final pending = <int, Completer<Map<String, dynamic>>>{};
    sub = proc.stdout.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter()).listen((line) {
      if (line.trim().isEmpty) return;
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        final rawId = json['id'];
        final id = rawId is int ? rawId : (rawId is num ? rawId.toInt() : null);
        if (id != null) {
          final c = pending.remove(id);
          if (c != null && !c.isCompleted) {
            if (json['error'] != null) {
              c.completeError(Exception('codex error: ${json['error']}'));
            } else {
              c.complete((json['result'] as Map<String, dynamic>?) ?? <String, dynamic>{});
            }
          }
        }
      } catch (e) {
        dLog('[CodexCli] model/list frame parse failure: ${e.runtimeType}');
      }
    });

    Future<Map<String, dynamic>> rpc(int id, String method, Map<String, dynamic> params) {
      final c = Completer<Map<String, dynamic>>();
      pending[id] = c;
      proc!.stdin.writeln(jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params}));
      return c.future.timeout(const Duration(seconds: 10));
    }

    void notify(String method, [Map<String, dynamic>? params]) {
      proc!.stdin.writeln(jsonEncode({'jsonrpc': '2.0', 'method': method, 'params': ?params}));
    }

    await rpc(1, 'initialize', {
      'clientInfo': {'name': 'code_bench', 'title': 'Code Bench', 'version': '1.0.0'},
      'capabilities': {'experimentalApi': true},
    });
    notify('initialized');
    final result = await rpc(2, 'model/list', {'includeHidden': false});
    return parseCodexModelList(result);
  } finally {
    await sub?.cancel();
    proc?.kill();
  }
}

@visibleForTesting
Map<String, dynamic> buildCodexThreadStartParams({
  required String workingDirectory,
  required String sessionId,
  String? developerInstructions,
}) {
  return {
    'cwd': workingDirectory,
    if (sessionId.isNotEmpty) 'resumeThreadId': sessionId,
    if (developerInstructions != null && developerInstructions.isNotEmpty)
      'developerInstructions': developerInstructions,
  };
}

@riverpod
AIProviderDatasource codexCliDatasourceProcess(Ref ref) {
  // TODO: read binaryPath from settings once settings model is updated
  return CodexCliDatasourceProcess(binaryPath: 'codex');
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
class CodexCliDatasourceProcess implements AIProviderDatasource {
  CodexCliDatasourceProcess({required this.binaryPath});

  final String binaryPath;

  /// Cap for the in-memory stderr buffer per turn — a chatty crash should
  /// not balloon Flutter-process memory.
  static const int _stderrCap = 64 * 1024;

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
  StreamSubscription<String>? _stderrSubscription;
  final StringBuffer _stderrBuffer = StringBuffer();

  /// Abort after N consecutive JSON parse failures — a healthy stream
  /// produces occasional unknown frames but never a sustained malformed run.
  static const int _consecutiveParseFailureLimit = 5;
  int _consecutiveJsonParseFailures = 0;

  String? _providerThreadId;
  String? _version;

  /// Absolute path to the `codex` binary, resolved via the user's login
  /// shell during [detect]. macOS GUI launches inherit a stripped PATH that
  /// excludes Homebrew / npm-global / nvm / asdf, so a bare `binaryPath`
  /// would only resolve under `flutter run`. See [resolveBinary].
  String? _resolvedPath;

  /// Full PATH string as reported by the login shell when [_resolvedPath]
  /// was resolved. Passed to child processes so shebang interpreters (e.g.
  /// `node` for `#!/usr/bin/env node`) are reachable in release builds.
  String? _shellPath;

  @override
  String get id => 'codex';

  @override
  String get displayName => 'Codex';

  @override
  Future<DetectionResult> detect() async {
    // Resolve through a login shell so `.zprofile` / `.bash_profile` /
    // `.zshrc` PATH augmentations are honoured. The probe distinguishes
    // "not installed" (→ missing) from "probe could not run" (→
    // unhealthy) so the UI can show the right copy.
    final resolution = await resolveBinary(binaryPath);
    final String resolved;
    switch (resolution) {
      case BinaryFound(:final path, :final shellPath):
        resolved = path;
        _resolvedPath = path;
        _shellPath = shellPath;
      case BinaryNotFound():
        return const DetectionResult.missing();
      case BinaryProbeFailed(:final reason):
        return DetectionResult.unhealthy('login-shell probe failed: $reason');
    }

    // Codex doesn't expose `--version` cheaply; the canonical version comes
    // from the `initialize` JSON-RPC response. If we already have it, use it.
    if (_version != null) return DetectionResult.installed(_version!);

    // Probe `--version` defensively. Pass the shell's expanded PATH so that
    // Node-backed binaries (`#!/usr/bin/env node`) can find their runtime
    // even in a release .app with a stripped inherited PATH.
    final probeEnv = _shellPath != null ? {'PATH': _shellPath!} : null;
    try {
      final result = await Process.run(
        resolved,
        ['--version'],
        environment: probeEnv,
        includeParentEnvironment: probeEnv == null,
      ).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) {
        sLog('[CodexCli] --version exited ${result.exitCode}');
        return DetectionResult.unhealthy('--version exited ${result.exitCode}');
      }
      final out = (result.stdout as String).trim();
      return DetectionResult.installed(out.isEmpty ? 'unknown' : out);
    } catch (e) {
      sLog('[CodexCli] --version probe failed: $e');
      return DetectionResult.unhealthy('--version failed: ${e.runtimeType}');
    }
  }

  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
    supportsModelOverride: true,
    supportsSystemPrompt: true,
    supportedModes: {ChatMode.chat, ChatMode.act},
    supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
    supportedPermissions: {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess},
  );

  @override
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
    ProviderTurnSettings? settings,
  }) {
    // A prior turn may have leaked an open controller (cancel + completion
    // race). The previous subscriber is gone by now; close() is async but
    // we don't await it — any unflushed buffered events are intentionally
    // discarded along with the orphaned controller.
    final orphan = _streamController;
    if (orphan != null) unawaited(orphan.close());
    // Single-subscription (not broadcast): `_send` runs synchronously up to
    // its first `await` and emits `ProviderInit` before `sendAndStream`
    // returns. With broadcast, that event would be dropped (no listener
    // attached yet); single-sub buffers until `await for` subscribes.
    _streamController = StreamController<ProviderRuntimeEvent>();
    _send(prompt, sessionId, workingDirectory, settings);
    return _streamController!.stream;
  }

  Future<void> _send(String prompt, String sessionId, String workingDirectory, ProviderTurnSettings? settings) async {
    try {
      _streamController?.add(ProviderInit(provider: id, modelId: settings?.modelId));

      // sessionId guard — Codex uses this value as `resumeThreadId` over
      // JSON-RPC. A non-UUID value could resume a foreign thread or trip
      // unexpected app-server behavior. We only ever generate v4 UUIDs,
      // but a future import/restore path could leak an attacker-shaped
      // value here.
      if (!uuidV4Regex.hasMatch(sessionId)) {
        sLog('[CodexCli] rejected non-UUID sessionId at RPC boundary');
        _streamController?.add(const ProviderStreamFailure(error: 'invalid sessionId shape'));
        return;
      }

      // workingDirectory guard — must be an existing absolute path that is
      // not the filesystem root. Codex roots all tool use at `cwd`, so a
      // stale or attacker-influenced path (e.g. `~`, `/`) would give it
      // read/write/execute access well outside the user's project.
      if (!workingDirectory.startsWith('/') || workingDirectory == '/' || !Directory(workingDirectory).existsSync()) {
        sLog('[CodexCli] rejected workingDirectory: $workingDirectory');
        _streamController?.add(const ProviderStreamFailure(error: 'invalid workingDirectory'));
        return;
      }

      // Spawn or reuse the app-server process
      await _ensureProcess(workingDirectory);

      // Initialize if this is a fresh process
      if (_version == null) {
        await _initialize();
      }

      // Start or resume a Codex thread
      _providerThreadId ??= await _startThread(sessionId, workingDirectory, settings?.systemPrompt);

      // Send the user's turn
      await _sendTurn(prompt, settings);

      // Events stream back via notifications; [_handleNotification] drives
      // the StreamController. We wait here until turn/completed or an error.
    } catch (e, st) {
      dLog('[CodexCli] send failed: ${redactSecrets('$e')}\n$st');
      _streamController?.add(ProviderStreamFailure(error: e));
      // Per-turn cleanup — keep the long-lived app-server process alive so
      // a retry can reuse it. If the process itself died, the stdout
      // onDone / exitCode handlers will _resetProcess().
      _resetTurn();
    }
  }

  Future<void> _ensureProcess(String workingDirectory) async {
    if (_process != null && _workingDirectory == workingDirectory) return;

    // Kill existing process if working directory changed
    if (_process != null) {
      _process!.kill();
      await _process!.exitCode;
      _resetProcess();
    }

    dLog('[CodexCli] spawning codex app-server in $workingDirectory');

    // Minimal env — the app-server inherits this and so do the commands
    // it executes. A developer's parent env routinely contains
    // ANTHROPIC_API_KEY / OPENAI_API_KEY / GITHUB_TOKEN / AWS_*; do not
    // leak those into transitively-spawned commands.
    final parentEnv = Platform.environment;
    final minimalEnv = <String, String>{
      if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
      // Use the login-shell PATH captured during detect so that
      // Node-backed binaries resolve correctly in release builds.
      'PATH': _shellPath ?? parentEnv['PATH'] ?? '/usr/bin:/bin:/usr/sbin:/sbin',
      if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
      if (parentEnv['LANG'] != null) 'LANG': parentEnv['LANG']!,
      if (parentEnv['TMPDIR'] != null) 'TMPDIR': parentEnv['TMPDIR']!,
      if (parentEnv['SHELL'] != null) 'SHELL': parentEnv['SHELL']!,
      // Codex-specific: forward only what its OAuth flow needs.
      if (parentEnv['CODEX_HOME'] != null) 'CODEX_HOME': parentEnv['CODEX_HOME']!,
    };

    // Use the absolute path resolved by [detect]. Resolve on-demand if a
    // caller skipped detection (e.g. settings UI bypassed) so the spawn
    // works in release builds where the inherited PATH doesn't see
    // Homebrew / npm-global. On a stale cache (binary moved/uninstalled
    // since detect), invalidate and retry once with a fresh probe.
    var exePath = await _resolveExePath();
    try {
      _process = await Process.start(
        exePath,
        ['app-server'],
        workingDirectory: workingDirectory,
        runInShell: false,
        includeParentEnvironment: false,
        environment: minimalEnv,
      );
    } on ProcessException catch (e) {
      // Cached path may be stale (brew upgrade, uninstall). Invalidate and
      // retry once. Rebuild minimalEnv so the retry uses the freshly-resolved
      // _shellPath rather than the stale one captured above.
      sLog('[CodexCli] start failed at $exePath: $e — invalidating cache and retrying');
      _resolvedPath = null;
      exePath = await _resolveExePath();
      final retryEnv = <String, String>{
        if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
        'PATH': _shellPath ?? parentEnv['PATH'] ?? '/usr/bin:/bin:/usr/sbin:/sbin',
        if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
        if (parentEnv['LANG'] != null) 'LANG': parentEnv['LANG']!,
        if (parentEnv['TMPDIR'] != null) 'TMPDIR': parentEnv['TMPDIR']!,
        if (parentEnv['SHELL'] != null) 'SHELL': parentEnv['SHELL']!,
        if (parentEnv['CODEX_HOME'] != null) 'CODEX_HOME': parentEnv['CODEX_HOME']!,
      };
      try {
        _process = await Process.start(
          exePath,
          ['app-server'],
          workingDirectory: workingDirectory,
          runInShell: false,
          includeParentEnvironment: false,
          environment: retryEnv,
        );
      } on ProcessException catch (e2) {
        sLog('[CodexCli] retry start also failed at $exePath: $e2');
        throw Exception('Codex CLI is not installed or not executable');
      }
    }
    _workingDirectory = workingDirectory;

    // Wire stdout → JSON-RPC message handler. Use allowMalformed so a
    // multi-byte char split across reads doesn't take the whole stream
    // down with a UTF-8 decode error.
    _stdoutSubscription = _process!.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          _handleLine,
          onError: (Object e) {
            dLog('[CodexCli] stdout error: ${redactSecrets('$e')}');
            _streamController?.add(ProviderStreamFailure(error: 'Codex stdout error: ${e.runtimeType}'));
            _resetProcess();
          },
          onDone: () {
            dLog('[CodexCli] app-server stdout closed');
            _streamController?.add(const ProviderStreamFailure(error: 'Codex process exited'));
            _resetProcess();
          },
        );

    // Buffer stderr for diagnostics; cap so it can't grow without bound.
    _stderrSubscription = _process!.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((line) {
          // dLog goes through redactSecrets so an inadvertent token echo
          // doesn't end up in Console.app during development.
          dLog('[CodexProvider.stderr] ${redactSecrets(line)}');
          if (_stderrBuffer.length >= _stderrCap) return;
          final remaining = _stderrCap - _stderrBuffer.length;
          final out = line.length <= remaining ? line : line.substring(0, remaining);
          _stderrBuffer.writeln(out);
        });

    // If the process exits unexpectedly, surface and clean up.
    unawaited(
      _process!.exitCode
          .then((code) {
            if (code != 0) {
              dLog('[CodexCli] app-server exited with code $code\nstderr=${redactSecrets(_stderrBuffer.toString())}');
              _streamController?.add(
                ProviderStreamFailure(
                  error: 'Codex exited with code $code',
                  details: redactSecrets(_stderrBuffer.toString()),
                ),
              );
            } else if (_providerThreadId != null) {
              // Process exited cleanly mid-turn — surface so the caller
              // doesn't hang waiting for turn/completed.
              dLog('[CodexCli] app-server exited 0 unexpectedly mid-turn');
              _streamController?.add(const ProviderStreamFailure(error: 'Codex process exited unexpectedly'));
            }
            _resetProcess();
          })
          .catchError((Object e) {
            dLog('[CodexCli] exitCode handler threw: ${redactSecrets('$e')}');
            _resetProcess();
          }),
    );
  }

  /// Send a client→server request and await the response.
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

  /// Send a client→server notification (no response expected).
  void _notify(String method, [Map<String, dynamic>? params]) {
    final message = jsonEncode({'jsonrpc': '2.0', 'method': method, 'params': params});
    dLog('[CodexCli] → $method (notification)');
    _writeStdin(message);
  }

  /// Respond to a server→client request (approval, user-input, etc.).
  void _respond(dynamic id, Map<String, dynamic> result) {
    final message = jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result});
    dLog('[CodexCli] → response to server request $id');
    _writeStdin(message);
  }

  /// Centralised stdin write so we can fail fast if the pipe is dead.
  /// `IOSink.writeln` swallows errors as zone-async; surfacing them here
  /// avoids losing approval responses to a silent broken pipe.
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

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(line) as Map<String, dynamic>;
      _consecutiveJsonParseFailures = 0;
    } catch (e) {
      _consecutiveJsonParseFailures++;
      final preview = line.length > 256 ? '${line.substring(0, 256)}…' : line;
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
    final completer = _pendingRequests.remove(_coerceId(id));
    if (completer != null) {
      completer.complete(result);
    } else {
      dLog('[CodexCli] No pending request for id $id');
    }
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

  void _handleErrorResponse(dynamic id, Map<String, dynamic> error) {
    final completer = _pendingRequests.remove(_coerceId(id));
    final message = error['message'] as String? ?? 'Unknown error';
    if (completer != null) {
      completer.completeError(Exception('Codex error: $message'));
    } else {
      dLog('[CodexCli] No pending request for error id $id (server-acknowledged: $message)');
    }
    _streamController?.add(ProviderStreamFailure(error: 'Codex error: $message'));
  }

  /// Handle a request that the Codex server sends TO US (approval, user-input).
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
        // User-input questions — emit as permission request for now
        // TODO: dedicated user-input event type
        _emitPermissionRequest(id, method, params);

      case 'account/chatgptAuthTokens/refresh':
        // Auth token refresh — auto-approved once the JSON-RPC handshake
        // has completed (i.e. `_version` is set, meaning we received the
        // `initialize` response). Earlier than that, a hostile or buggy
        // app-server could loop this request before any client guard runs.
        // The token never crosses the host process; codex holds and
        // refreshes it internally. sLog so the event is grep-able in
        // release builds. Gating on `_version` (not `_providerThreadId`)
        // because legitimate refreshes can happen between `initialized`
        // and `thread/start` if the OAuth token has expired at startup.
        if (_version == null) {
          sLog('[CodexCli] denying account/chatgptAuthTokens/refresh — process not yet initialized (id=$id)');
          _respond(id, {'ok': false});
        } else {
          sLog('[CodexCli] auto-approving account/chatgptAuthTokens/refresh (id=$id)');
          _respond(id, {'ok': true});
        }

      default:
        // Unknown approval-shaped method. sLog (survives release) and
        // surface as a stream failure so the user sees "your codex version
        // sent a method we don't recognise" rather than a silent denial.
        sLog('[CodexCli] unknown server request: $method — denying and aborting turn');
        _respond(id, {'decision': 'denied'});
        _streamController?.add(
          ProviderStreamFailure(error: 'Unsupported codex approval method: $method — please update Code Bench'),
        );
    }
  }

  void _emitPermissionRequest(dynamic id, String method, Map<String, dynamic>? params) {
    // Normalize the JSON-RPC id before stringifying so num `5.0` and int `5`
    // produce the same key — same protocol-drift hazard `_coerceId` handles
    // for `_pendingRequests`.
    final normalized = _coerceId(id);
    final requestId = (normalized ?? id).toString();

    // Store completer so [respondToRequest] can resolve it
    final completer = Completer<Map<String, dynamic>>();
    _pendingApprovals[requestId] = completer;

    _streamController?.add(
      ProviderPermissionRequest(requestId: requestId, toolName: _methodToToolName(method), toolInput: params ?? {}),
    );

    // When the UI resolves the approval, send the response back to Codex.
    // Guard the response on a still-live process — a dead pipe would throw
    // asynchronously and the error would be unhandled.
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

  /// Handle a server→client notification (no response expected).
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
        // Token usage — ignore for now
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
        // Unknown notification — sLog so post-release telemetry catches
        // codex protocol additions we haven't wired up.
        sLog('[CodexCli] ignoring unknown notification: $method');
    }
  }

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
    dLog('[CodexCli] version: $_version');

    // Required acknowledgement after initialize
    _notify('initialized');
  }

  Future<String> _startThread(String sessionId, String workingDirectory, String? developerInstructions) async {
    final result = await _request(
      'thread/start',
      buildCodexThreadStartParams(
        workingDirectory: workingDirectory,
        sessionId: sessionId,
        developerInstructions: developerInstructions,
      ),
    );
    final threadId = result['thread']?['id'] as String?;
    if (threadId == null) {
      dLog('[CodexCli] thread/start response missing thread.id: $result');
      throw Exception('Codex thread/start returned no thread ID');
    }
    dLog('[CodexCli] Thread started: $threadId');
    return threadId;
  }

  Future<void> _sendTurn(String prompt, ProviderTurnSettings? settings) async {
    await _request(
      'turn/start',
      buildCodexTurnStartParams(
        _providerThreadId!,
        prompt,
        modelId: settings?.modelId,
        effort: settings?.effort,
        permission: settings?.permission,
      ),
    );
    dLog('[CodexCli] Turn started');
  }

  /// Called by the chat notifier when the user approves or denies a
  /// permission request. [decision] is one of: "approved", "denied".
  @override
  void respondToPermissionRequest(String requestId, {required bool approved}) {
    final completer = _pendingApprovals.remove(requestId);
    if (completer == null) {
      dLog('[CodexCli] No pending approval for requestId $requestId');
      return;
    }
    completer.complete({'decision': approved ? 'approved' : 'denied'});
  }

  @override
  void cancel() {
    dLog('[CodexCli] Cancelling in-flight turn');
    // Interrupt the current turn if one is running. The app-server stays
    // alive; only the turn ends.
    if (_providerThreadId != null && _process != null) {
      _notify('turn/interrupt', {'threadId': _providerThreadId});
    }
    _resetTurn();
  }

  /// Per-turn cleanup. Closes the active stream controller and clears
  /// pending approvals/requests so the next turn doesn't see stale
  /// completers. Does NOT kill the long-lived `app-server` process.
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
  }

  /// Process-level cleanup — the `app-server` process is gone (exit, crash,
  /// stdout closed, working-directory change). Tear everything down.
  void _resetProcess() {
    _resetTurn();
    _process = null;
    _workingDirectory = null;
    _version = null;
    _providerThreadId = null;
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription?.cancel();
    _stderrSubscription = null;
    _stderrBuffer.clear();
  }

  /// Returns the absolute exe path or throws with a user-facing message.
  /// The caller's `catch` in [_send] surfaces the message via
  /// [ProviderStreamFailure].
  Future<String> _resolveExePath() async {
    final cached = _resolvedPath;
    if (cached != null) return cached;
    final r = await resolveBinary(binaryPath);
    switch (r) {
      case BinaryFound(:final path, :final shellPath):
        _resolvedPath = path;
        _shellPath = shellPath;
        return path;
      case BinaryNotFound():
        throw Exception('Codex CLI is not installed or not on PATH');
      case BinaryProbeFailed(:final reason):
        sLog('[CodexCli] _ensureProcess resolve failed: $reason');
        throw Exception('Could not probe Codex CLI: $reason');
    }
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

  @override
  Future<AuthStatus> verifyAuth() async {
    if (_resolvedPath == null) {
      sLog('[CodexCli] verifyAuth skipped — binary not yet resolved');
      return const AuthStatus.unknown();
    }
    try {
      // Forward only what the CLI needs (HOME/USER/CODEX_HOME for auth state,
      // PATH for child lookups) so user-exported API keys don't leak in.
      final parentEnv = Platform.environment;
      final probeEnv = <String, String>{
        if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
        if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
        if (parentEnv['CODEX_HOME'] != null) 'CODEX_HOME': parentEnv['CODEX_HOME']!,
        'PATH': _shellPath ?? parentEnv['PATH'] ?? '',
      };
      final result = await Process.run(
        _resolvedPath!,
        ['login', 'status'],
        environment: probeEnv,
        includeParentEnvironment: false,
      ).timeout(const Duration(seconds: 5));
      // Codex writes its status line to stderr even on exit 0 — merge both
      // streams so the parser doesn't have to guess which channel was used.
      final combined = '${result.stdout}${result.stderr}';
      return parseCodexAuthOutput(result.exitCode, combined);
    } on TimeoutException {
      sLog('[CodexCli] verifyAuth timed out after 5s');
      return const AuthStatus.unknown();
    } catch (e) {
      sLog('[CodexCli] verifyAuth failed: ${e.runtimeType}');
      return const AuthStatus.unknown();
    }
  }
}
