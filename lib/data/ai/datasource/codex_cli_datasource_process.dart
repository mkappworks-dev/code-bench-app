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
import 'codex_session_pool.dart';
import 'process_launcher.dart';

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

/// Parses a `model/list` JSON-RPC result into [AIModel]s, dropping hidden entries.
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

/// Queries `model/list` from a short-lived `codex app-server`, isolated from the long-lived turn-streaming process so refresh can't disturb in-flight chats.
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
  final ds = CodexCliDatasourceProcess(binaryPath: 'codex');
  ref.onDispose(
    () => unawaited(ds.dispose().catchError((Object e) => sLog('[CodexCli] dispose failed: ${e.runtimeType}'))),
  );
  return ds;
}

/// Codex CLI provider; install-level concerns (detect, verifyAuth) live here, per-chat process plumbing in [CodexSessionPool].
class CodexCliDatasourceProcess implements AIProviderDatasource {
  CodexCliDatasourceProcess({required this.binaryPath, ProcessLauncher? processLauncher})
    : _pool = CodexSessionPool(binaryPath: binaryPath, processLauncher: processLauncher);

  final String binaryPath;
  final CodexSessionPool _pool;

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
  }) async* {
    final session = await _pool.sessionFor(sessionId, workingDirectory);
    yield* session.sendAndStream(prompt: prompt, settings: settings);
  }

  @override
  void cancel(String sessionId) => _pool.cancel(sessionId);

  @override
  void respondToPermissionRequest(String sessionId, String requestId, {required bool approved}) =>
      _pool.respondToPermissionRequest(sessionId, requestId, approved: approved);

  @override
  void respondToUserInputRequest(String sessionId, String requestId, {required String response}) {}

  @override
  Future<void> dispose() => _pool.dispose();

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
