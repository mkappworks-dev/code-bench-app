import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../models/stream_event.dart';
import 'ai_provider_datasource.dart';
import 'claude_sdk_stream_parser.dart';

part 'claude_sdk_datasource_process.g.dart';

@riverpod
AIProviderDatasource claudeSdkDatasourceProcess(Ref ref) {
  return ClaudeSdkDatasourceProcess();
}

/// Accepts RFC-4122 lowercased UUIDs (the format our `Uuid.v4()` produces).
/// Anything else at the argv boundary is rejected defensively so a stray
/// value like `--dangerously-skip-perms` can never slip into flag position.
final _uuidV4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

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
class ClaudeSdkDatasourceProcess implements AIProviderDatasource {
  ClaudeSdkDatasourceProcess({this.binaryPath = 'claude'});

  final String binaryPath;

  Process? _process;
  final Set<String> _knownSessions = {};

  @override
  String get id => 'claude-sdk';

  @override
  String get displayName => 'Claude Code SDK';

  @override
  Future<DetectionResult> detect() async {
    // Step 1: PATH lookup.
    final ProcessResult whichResult;
    try {
      whichResult = await Process.run('which', [binaryPath]).timeout(const Duration(seconds: 2));
    } catch (e) {
      sLog('[ClaudeSdk] which probe failed: $e');
      return DetectionResult.unhealthy('Detection failed: ${e.runtimeType}');
    }
    if (whichResult.exitCode != 0) {
      return const DetectionResult.missing();
    }

    // Step 2: --version probe. A stale or broken binary still resolves on
    // PATH but fails here. Surfacing this as `unhealthy` (rather than
    // `missing`) lets the UI tell users to reinstall vs install.
    final ProcessResult versionResult;
    try {
      versionResult = await Process.run(binaryPath, ['--version']).timeout(const Duration(seconds: 5));
    } catch (e) {
      sLog('[ClaudeSdk] --version probe failed: $e');
      return DetectionResult.unhealthy('--version failed: ${e.runtimeType}');
    }
    if (versionResult.exitCode != 0) {
      sLog('[ClaudeSdk] --version exited ${versionResult.exitCode}');
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
      if (!_uuidV4.hasMatch(sessionId)) {
        sLog('[ClaudeSdk] rejected non-UUID sessionId at argv boundary');
        controller.add(const ProviderStreamFailure(error: 'invalid sessionId shape'));
        return;
      }

      // workingDirectory guard — must be an existing absolute path that is
      // not the filesystem root. The CLI runs with bypassPermissions so a
      // stale or attacker-influenced path (e.g. `~`, `/`) would give it
      // full home-directory tool access.
      final wdDir = Directory(workingDirectory);
      if (!workingDirectory.startsWith('/') || workingDirectory == '/' || !wdDir.existsSync()) {
        sLog('[ClaudeSdk] rejected workingDirectory: $workingDirectory');
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
      final parentEnv = Platform.environment;
      final minimalEnv = <String, String>{
        if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
        if (parentEnv['PATH'] != null) 'PATH': parentEnv['PATH']!,
        if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
        if (parentEnv['LANG'] != null) 'LANG': parentEnv['LANG']!,
        if (parentEnv['TMPDIR'] != null) 'TMPDIR': parentEnv['TMPDIR']!,
        if (parentEnv['SHELL'] != null) 'SHELL': parentEnv['SHELL']!,
      };

      try {
        spawned = await Process.start(
          binaryPath,
          args,
          workingDirectory: workingDirectory,
          runInShell: false,
          includeParentEnvironment: false,
          environment: minimalEnv,
        );
      } on ProcessException catch (e) {
        dLog('[ClaudeSdk] start failed: ${redactSecrets('$e')}');
        controller.add(const ProviderStreamFailure(error: 'Claude Code CLI is not installed or not on PATH'));
        return;
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

      final parser = ClaudeSdkStreamParser();
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
              '[ClaudeSdk] parse failure ($consecutiveParseFailures/$_consecutiveParseFailureLimit): ${event.error} — line="${redactSecrets(preview)}"',
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
          dLog('[ClaudeSdk] process exited $exitCode\nstderr=${redactSecrets(stderrBuffer.toString())}');
          controller.add(
            ProviderStreamFailure(error: 'claude exited $exitCode', details: redactSecrets(stderrBuffer.toString())),
          );
        } else if (!sawDone) {
          dLog('[ClaudeSdk] stdout closed without message_stop (exit=0)');
          controller.add(const ProviderStreamFailure(error: 'stream closed without message_stop'));
        } else {
          // Mark this session as known so subsequent turns use --resume.
          _knownSessions.add(sessionId);
        }
      } finally {
        await stderrSub.cancel();
      }
    } catch (e, st) {
      dLog('[ClaudeSdk] send failed: ${redactSecrets('$e')}\n$st');
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
}
