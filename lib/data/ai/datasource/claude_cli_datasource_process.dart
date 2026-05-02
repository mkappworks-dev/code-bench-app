import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../models/stream_event.dart';
import 'ai_provider_datasource.dart';
import 'binary_resolver_process.dart';
import 'claude_cli_stream_parser.dart';
import 'provider_input_guards.dart';

part 'claude_cli_datasource_process.g.dart';

@riverpod
AIProviderDatasource claudeCliDatasourceProcess(Ref ref) {
  // TODO: read binaryPath from settings once settings model is updated
  return ClaudeCliDatasourceProcess(binaryPath: 'claude');
}

/// Abort after N consecutive parse failures — a healthy stream produces
/// occasional unknown frames but never a sustained run of malformed lines.
const int _consecutiveParseFailureLimit = 5;

/// Spawns the locally-installed `claude` CLI binary and streams its
/// `--output-format stream-json` output, normalized to [ProviderRuntimeEvent].
///
/// First turn for a session uses `--session-id <id>`; subsequent turns reuse
/// the session via `--resume <id>`. The CLI itself runs under
/// `--permission-mode bypassPermissions` so Code Bench's permission rules do
/// not gate its tool use — the user is warned via the chat permission card
/// before delegation begins.
class ClaudeCliDatasourceProcess implements AIProviderDatasource {
  ClaudeCliDatasourceProcess({required this.binaryPath});

  final String binaryPath;

  Process? _process;
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
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
  }) {
    final controller = StreamController<ProviderRuntimeEvent>.broadcast();
    _stream(controller, prompt: prompt, sessionId: sessionId, workingDirectory: workingDirectory);
    return controller.stream;
  }

  Future<void> _stream(
    StreamController<ProviderRuntimeEvent> controller, {
    required String prompt,
    required String sessionId,
    required String workingDirectory,
  }) async {
    Process? spawned;
    try {
      controller.add(ProviderInit(provider: id));

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
      final args = <String>[
        '-p',
        '--output-format',
        'stream-json',
        '--include-partial-messages',
        '--permission-mode',
        'bypassPermissions',
        '--verbose',
        if (isFirstTurn) ...['--session-id', sessionId] else ...['--resume', sessionId],
        // `--` ends Claude Code's option parsing; the prompt after it is
        // always treated positionally, so a `-`-prefixed prompt cannot
        // become a flag.
        '--',
        prompt,
      ];

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
        spawned = await Process.start(
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
          spawned = await Process.start(
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

      _process = spawned;

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
            final preview = line.length > 256 ? '${line.substring(0, 256)}…' : line;
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
        } else {
          // Mark this session as known so subsequent turns use --resume.
          _knownSessions.add(sessionId);
        }
      } finally {
        await stderrSub.cancel();
      }
    } catch (e, st) {
      dLog('[ClaudeCli] send failed: ${redactSecrets('$e')}\n$st');
      controller.add(ProviderStreamFailure(error: e));
    } finally {
      // Only clear _process if it still points to ours — a later sendAndStream
      // call may have already overwritten it.
      if (identical(_process, spawned)) _process = null;
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
  void cancel() {
    _process?.kill(ProcessSignal.sigterm);
    // The controller closes via the `finally` in [_stream] when the process
    // exits — no need to close it here, and doing so would race with a
    // freshly-spawned turn.
  }

  @override
  void respondToPermissionRequest(String requestId, {required bool approved}) {
    // Claude Code CLI runs with --permission-mode bypassPermissions, so it
    // never sends permission requests back to the host.
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
