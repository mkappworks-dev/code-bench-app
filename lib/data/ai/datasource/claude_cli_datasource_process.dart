import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../shared/ai_model.dart';
import '../../shared/session_settings.dart';
import '../models/stream_event.dart';
import '../util/setting_mappers.dart';
import 'ai_provider_datasource.dart';
import 'binary_resolver_process.dart';
import 'claude_cli_stream_parser.dart';
import 'process_launcher.dart';
import 'provider_input_guards.dart';

part 'claude_cli_datasource_process.g.dart';

@visibleForTesting
const int claudeAuthOutputSizeLimit = 64 * 1024;

@visibleForTesting
AuthStatus parseClaudeAuthOutput(int exitCode, String stdout) {
  // Exit code is intentionally ignored: `claude auth status --json` exits 1
  // when not logged in but still emits a valid `loggedIn:false` JSON body.
  if (stdout.length > claudeAuthOutputSizeLimit) {
    dLog(
      '[ClaudeCli] auth status output exceeds ${claudeAuthOutputSizeLimit}B (${stdout.length}B) — treating as unknown',
    );
    return const AuthStatus.unknown();
  }
  try {
    final decoded = jsonDecode(stdout);
    if (decoded is! Map<String, dynamic>) return const AuthStatus.unknown();
    final loggedIn = decoded['loggedIn'];
    if (loggedIn == true) return const AuthStatus.authenticated();
    if (loggedIn == false) {
      return const AuthStatus.unauthenticated(signInCommand: 'claude auth login');
    }
    return const AuthStatus.unknown();
  } catch (e) {
    dLog('[ClaudeCli] auth status JSON parse failed (${e.runtimeType}, ${stdout.length}B) — treating as unknown');
    return const AuthStatus.unknown();
  }
}

@riverpod
AIProviderDatasource claudeCliDatasourceProcess(Ref ref) {
  // TODO: read binaryPath from settings once settings model is updated
  final ds = ClaudeCliDatasourceProcess(binaryPath: 'claude');
  ref.onDispose(() => unawaited(ds.dispose()));
  return ds;
}

@visibleForTesting
List<String> buildClaudeCliArgs({
  required String sessionId,
  required String prompt,
  required bool isFirstTurn,
  ProviderTurnSettings? settings,
}) {
  // Defensive flag-shape guard at the argv boundary in case a future BYO-modelId path lands a `--`-prefixed string.
  var modelId = settings?.modelId;
  if (modelId != null && modelId.startsWith('-')) {
    sLog('[ClaudeCli] rejected flag-shaped modelId at argv boundary');
    modelId = null;
  }
  final systemPrompt = settings?.systemPrompt;
  final permissionMode = mapClaudePermissionMode(
    mode: settings?.mode ?? ChatMode.chat,
    permission: settings?.permission ?? ChatPermission.fullAccess,
  );

  // `--effort` is not forwarded — older Claude CLI versions reject it and exit 1.
  if (settings?.effort != null) {
    dLog('[ClaudeCli] ignoring effort=${settings!.effort!.name} — Claude CLI does not accept --effort');
  }
  return [
    '-p',
    '--output-format',
    'stream-json',
    '--include-partial-messages',
    '--verbose',
    if (modelId != null) ...['--model', modelId],
    if (systemPrompt != null && systemPrompt.isNotEmpty) ...['--append-system-prompt', systemPrompt],
    '--permission-mode',
    permissionMode,
    if (isFirstTurn) ...['--session-id', sessionId] else ...['--resume', sessionId],
    '--',
    prompt,
  ];
}

/// Abort after N consecutive parse failures — a healthy stream produces
/// occasional unknown frames but never a sustained run of malformed lines.
const int _consecutiveParseFailureLimit = 5;

/// Spawns the locally-installed `claude` CLI binary and streams its
/// `--output-format stream-json` output, normalized to [ProviderRuntimeEvent].
class ClaudeCliDatasourceProcess implements AIProviderDatasource {
  ClaudeCliDatasourceProcess({required this.binaryPath, ProcessLauncher? processLauncher, String? resolvedPath})
    : _processLauncher = processLauncher ?? defaultProcessLauncher,
      _resolvedPath = resolvedPath;

  final String binaryPath;
  final ProcessLauncher _processLauncher;

  final Map<String, Process> _processes = {};
  final Set<String> _knownSessions = {};

  /// Absolute path to the `claude` binary, resolved via the user's login
  /// shell during [detect]. macOS GUI launches inherit a stripped PATH that
  /// excludes Homebrew / npm-global / nvm / asdf, so a bare `binaryPath`
  /// would only resolve under `flutter run`. See [resolveBinary].
  String? _resolvedPath;

  /// Full PATH string as reported by the login shell when [_resolvedPath]
  /// was resolved. Passed to child processes so shebang interpreters (e.g.
  /// `node` for `#!/usr/bin/env node`) are reachable in release builds.
  String? _shellPath;

  @override
  String get id => 'claude-cli';

  @override
  String get displayName => 'Claude Code CLI';

  @override
  Future<DetectionResult> detect() async {
    // Step 1: resolve through a login shell so `.zprofile` / `.bash_profile`
    // / `.zshrc` PATH augmentations are honoured. A bare `which` would
    // inherit the stripped GUI PATH and miss Homebrew / npm-global / nvm.
    // The probe distinguishes "not installed" (→ missing) from "probe
    // could not run" (→ unhealthy) so the UI can show the right copy.
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

    // Step 2: --version probe. Pass the shell's expanded PATH so that
    // Node-backed binaries (`#!/usr/bin/env node`) can find their runtime
    // even in a release .app with a stripped inherited PATH.
    final probeEnv = _shellPath != null ? {'PATH': _shellPath!} : null;
    final ProcessResult versionResult;
    try {
      versionResult = await Process.run(
        resolved,
        ['--version'],
        environment: probeEnv,
        includeParentEnvironment: probeEnv == null,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      sLog('[ClaudeCli] --version probe failed: $e');
      return DetectionResult.unhealthy('--version failed: ${e.runtimeType}');
    }
    if (versionResult.exitCode != 0) {
      sLog('[ClaudeCli] --version exited ${versionResult.exitCode}');
      return DetectionResult.unhealthy('--version exited ${versionResult.exitCode}');
    }
    final version = (versionResult.stdout as String).trim();
    return DetectionResult.installed(version.isEmpty ? 'unknown' : version);
  }

  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
    supportsModelOverride: true,
    supportsSystemPrompt: true,
    supportedModes: {ChatMode.chat, ChatMode.plan, ChatMode.act},
    // Empty: hides the effort chip since `--effort` is not forwarded (see buildClaudeCliArgs).
    supportedEfforts: <ChatEffort>{},
    supportedPermissions: {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess},
  );

  @override
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
    ProviderTurnSettings? settings,
  }) {
    // Single-subscription buffers `ProviderInit` until `await for` subscribes; broadcast would drop it.
    final controller = StreamController<ProviderRuntimeEvent>();
    _stream(controller, prompt: prompt, sessionId: sessionId, workingDirectory: workingDirectory, settings: settings);
    return controller.stream;
  }

  Future<void> _stream(
    StreamController<ProviderRuntimeEvent> controller, {
    required String prompt,
    required String sessionId,
    required String workingDirectory,
    ProviderTurnSettings? settings,
  }) async {
    Process? spawned;
    try {
      controller.add(ProviderInit(provider: id, modelId: settings?.modelId));

      // sessionId guard — we only ever generate v4 UUIDs, but a future
      // import/restore path could leak an attacker-shaped value into argv.
      if (!uuidV4Regex.hasMatch(sessionId)) {
        sLog('[ClaudeCli] rejected non-UUID sessionId at argv boundary');
        controller.add(const ProviderStreamFailure(error: 'invalid sessionId shape'));
        return;
      }

      // workingDirectory guard — must be an existing absolute path that is
      // not the filesystem root. The CLI runs with bypassPermissions so a
      // stale or attacker-influenced path (e.g. `~`, `/`) would give it
      // full home-directory tool access.
      final wdDir = Directory(workingDirectory);
      if (!workingDirectory.startsWith('/') || workingDirectory == '/' || !wdDir.existsSync()) {
        sLog('[ClaudeCli] rejected workingDirectory: $workingDirectory');
        controller.add(const ProviderStreamFailure(error: 'invalid workingDirectory'));
        return;
      }

      final isFirstTurn = !_knownSessions.contains(sessionId);
      // `--` ends Claude Code's option parsing; the prompt after it is always
      // treated positionally, so a `-`-prefixed prompt cannot become a flag.
      final args = buildClaudeCliArgs(
        sessionId: sessionId,
        prompt: prompt,
        isFirstTurn: isFirstTurn,
        settings: settings,
      );

      // Minimal env — inheriting parent's full env would leak
      // ANTHROPIC_API_KEY / GITHUB_TOKEN / AWS_* into the CLI's child
      // processes (which run under bypassPermissions).
      // Use the login-shell PATH (captured during detect) rather than the
      // GUI app's stripped PATH so Node-backed binaries resolve correctly.
      final parentEnv = Platform.environment;
      final minimalEnv = <String, String>{
        if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
        'PATH': _shellPath ?? parentEnv['PATH'] ?? '/usr/bin:/bin:/usr/sbin:/sbin',
        if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
        if (parentEnv['LANG'] != null) 'LANG': parentEnv['LANG']!,
        if (parentEnv['TMPDIR'] != null) 'TMPDIR': parentEnv['TMPDIR']!,
        if (parentEnv['SHELL'] != null) 'SHELL': parentEnv['SHELL']!,
      };

      // Use the absolute path resolved by [detect]. If the user reaches
      // [sendAndStream] without a successful detection (e.g. settings UI
      // bypassed), resolve on-demand so the spawn works in release builds
      // where the inherited PATH doesn't see Homebrew / npm-global.
      var exePath = await _resolveExePath(controller);
      if (exePath == null) return;

      try {
        spawned = await _processLauncher(
          exePath,
          args,
          workingDirectory: workingDirectory,
          runInShell: false,
          includeParentEnvironment: false,
          environment: minimalEnv,
        );
      } on ProcessException catch (e) {
        // Cached path may be stale (brew upgrade, uninstall, version bump
        // moved the binary). Invalidate and retry once with a fresh probe.
        // Rebuild minimalEnv so the retry uses the freshly-resolved
        // _shellPath rather than the stale one captured above.
        sLog('[ClaudeCli] start failed at $exePath: $e — invalidating cache and retrying');
        _resolvedPath = null;
        exePath = await _resolveExePath(controller);
        if (exePath == null) return;
        final retryEnv = <String, String>{
          if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
          'PATH': _shellPath ?? parentEnv['PATH'] ?? '/usr/bin:/bin:/usr/sbin:/sbin',
          if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
          if (parentEnv['LANG'] != null) 'LANG': parentEnv['LANG']!,
          if (parentEnv['TMPDIR'] != null) 'TMPDIR': parentEnv['TMPDIR']!,
          if (parentEnv['SHELL'] != null) 'SHELL': parentEnv['SHELL']!,
        };
        try {
          spawned = await _processLauncher(
            exePath,
            args,
            workingDirectory: workingDirectory,
            runInShell: false,
            includeParentEnvironment: false,
            environment: retryEnv,
          );
        } on ProcessException catch (e2) {
          dLog('[ClaudeCli] retry start failed: ${redactSecrets('$e2')}');
          controller.add(const ProviderStreamFailure(error: 'Claude Code CLI is not installed or not on PATH'));
          return;
        }
      }

      _processes[sessionId] = spawned;

      // EOF stdin up-front: newer CLI versions block reading stdin in `-p` mode and exit 1 after a 3s warning.
      unawaited(spawned.stdin.close());

      // Cap stderr so a chatty crash can't balloon memory.
      const stderrCap = 64 * 1024;
      final stderrBuffer = StringBuffer();
      final stderrSub = spawned.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((chunk) {
        if (stderrBuffer.length >= stderrCap) return;
        final remaining = stderrCap - stderrBuffer.length;
        stderrBuffer.write(chunk.length <= remaining ? chunk : chunk.substring(0, remaining));
      });

      final parser = ClaudeCliStreamParser();
      var sawDone = false;
      var sessionCommitted = false;
      var consecutiveParseFailures = 0;
      var aborted = false;

      try {
        await for (final line
            in spawned.stdout.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())) {
          final event = parser.parseLine(line);
          if (event == null) {
            consecutiveParseFailures = 0;
            continue;
          }
          final mapped = _toProviderEvent(event);
          if (event is StreamParseFailure) {
            consecutiveParseFailures++;
            // Cap preview at 64 chars — redactSecrets only strips known token shapes; a 256-char window can leak prompt text or file contents the model just read.
            final preview = line.length > 64 ? '${line.substring(0, 64)}…' : line;
            dLog(
              '[ClaudeCli] parse failure ($consecutiveParseFailures/$_consecutiveParseFailureLimit): ${event.error} — line="${redactSecrets(preview)}"',
            );
            if (consecutiveParseFailures >= _consecutiveParseFailureLimit) {
              controller.add(
                ProviderStreamFailure(error: 'Claude CLI output unparseable', details: 'last error: ${event.error}'),
              );
              aborted = true;
              spawned.kill(ProcessSignal.sigterm);
              break;
            }
            continue;
          }
          consecutiveParseFailures = 0;
          // Mark the session known on first real CLI event — the CLI commits its session-store at that point. Marking on `Process.start` was too eager: a spawn that hung at auth never wrote the session, so a later `--resume` would fail.
          if (!sessionCommitted) {
            _knownSessions.add(sessionId);
            sessionCommitted = true;
          }
          if (mapped == null) continue;
          if (mapped is ProviderStreamDone) sawDone = true;
          controller.add(mapped);
        }

        final exitCode = await spawned.exitCode;
        if (aborted) {
          // Already emitted ProviderStreamFailure; nothing more to do.
        } else if (exitCode != 0) {
          dLog('[ClaudeCli] process exited $exitCode\nstderr=${redactSecrets(stderrBuffer.toString())}');
          controller.add(
            ProviderStreamFailure(error: 'claude exited $exitCode', details: redactSecrets(stderrBuffer.toString())),
          );
        } else if (!sawDone) {
          dLog('[ClaudeCli] stdout closed without message_stop (exit=0)');
          controller.add(const ProviderStreamFailure(error: 'stream closed without message_stop'));
        }
      } finally {
        await stderrSub.cancel();
      }
    } catch (e, st) {
      dLog('[ClaudeCli] send failed: ${redactSecrets('$e')}\n$st');
      controller.add(ProviderStreamFailure(error: e));
    } finally {
      if (identical(_processes[sessionId], spawned)) {
        _processes.remove(sessionId);
      }
      await controller.close();
    }
  }

  /// Maps a parser-emitted [StreamEvent] into the canonical
  /// [ProviderRuntimeEvent]. Returns null for events that have no equivalent
  /// (e.g. tool results — they roll into ToolUseComplete on the receiving side).
  ProviderRuntimeEvent? _toProviderEvent(StreamEvent event) {
    return switch (event) {
      TextDelta(:final text) => ProviderTextDelta(text: text),
      ThinkingDelta(:final text) => ProviderThinkingDelta(thinking: text),
      ToolUseStart(:final id, :final name) => ProviderToolUseStart(toolId: id, toolName: name),
      ToolUseInputDelta(:final id, :final partialJson) => ProviderToolInputDelta(toolId: id, partialJson: partialJson),
      ToolUseComplete(:final id, :final input) => ProviderToolUseComplete(toolId: id, input: input),
      ToolResult() => null,
      StreamDone() => const ProviderStreamDone(),
      StreamError(:final failure) => ProviderStreamFailure(error: failure),
      // StreamParseFailure handled by the caller (counted, dLog'd, aborts after threshold).
      StreamParseFailure() => null,
      // OpenAI-format variants — never emitted by the Claude CLI parser.
      StreamTextDelta() ||
      StreamToolCallStart() ||
      StreamToolCallArgsDelta() ||
      StreamToolCallEnd() ||
      StreamFinish() => null,
    };
  }

  @override
  void cancel(String sessionId) {
    _processes[sessionId]?.kill(ProcessSignal.sigterm);
  }

  @override
  Future<void> dispose() async {
    for (final p in _processes.values.toList()) {
      p.kill(ProcessSignal.sigterm);
    }
    _processes.clear();
  }

  @override
  void respondToPermissionRequest(String sessionId, String requestId, {required bool approved}) {
    // Claude Code CLI handles its own permission UI inline and never forwards prompts to the host.
  }

  @override
  Future<AuthStatus> verifyAuth() async {
    if (_resolvedPath == null) {
      sLog('[ClaudeCli] verifyAuth skipped — binary not yet resolved');
      return const AuthStatus.unknown();
    }
    try {
      // Forward only what the CLI needs (HOME/USER for auth config, PATH for
      // child lookups) so user-exported API keys don't leak into the probe.
      final parentEnv = Platform.environment;
      final probeEnv = <String, String>{
        if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
        if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
        'PATH': _shellPath ?? parentEnv['PATH'] ?? '',
      };
      final result = await Process.run(
        _resolvedPath!,
        ['auth', 'status', '--json'],
        environment: probeEnv,
        includeParentEnvironment: false,
      ).timeout(const Duration(seconds: 5));
      return parseClaudeAuthOutput(result.exitCode, result.stdout as String);
    } on TimeoutException {
      sLog('[ClaudeCli] verifyAuth timed out after 5s');
      return const AuthStatus.unknown();
    } catch (e) {
      sLog('[ClaudeCli] verifyAuth failed: ${e.runtimeType}');
      return const AuthStatus.unknown();
    }
  }

  /// Returns the absolute exe path or null. On null, has already added a
  /// [ProviderStreamFailure] to [controller] and logged the reason.
  Future<String?> _resolveExePath(StreamController<ProviderRuntimeEvent> controller) async {
    final cached = _resolvedPath;
    if (cached != null) return cached;
    final r = await resolveBinary(binaryPath);
    switch (r) {
      case BinaryFound(:final path, :final shellPath):
        _resolvedPath = path;
        _shellPath = shellPath;
        return path;
      case BinaryNotFound():
        controller.add(const ProviderStreamFailure(error: 'Claude Code CLI is not installed or not on PATH'));
        return null;
      case BinaryProbeFailed(:final reason):
        sLog('[ClaudeCli] sendAndStream resolve failed: $reason');
        controller.add(const ProviderStreamFailure(error: 'Could not probe Claude Code CLI — please retry'));
        return null;
    }
  }
}
