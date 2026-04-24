import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';
import '../../../features/providers/notifiers/claude_cli_failure.dart';
import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';
import '../models/cli_detection.dart';
import '../models/stream_event.dart';
import 'cli_remote_datasource.dart';
import 'claude_cli_stream_parser.dart';

/// Accepts RFC-4122 lowercased UUIDs (the format our `Uuid.v4()` produces).
/// Anything else at the argv boundary is rejected defensively so a stray
/// value like `--dangerously-skip-perms` can never slip into flag position.
final _uuidV4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

/// CLI-backed Anthropic transport. Spawns `claude -p --output-format stream-json`
/// and streams structured [StreamEvent]s parsed from the CLI's native wire
/// format. Sessions are resumed via `--resume <session-id>` on follow-up turns.
class ClaudeCliRemoteDatasourceProcess extends CliRemoteDatasource {
  ClaudeCliRemoteDatasourceProcess({Future<CliDetection> Function()? detector}) : _detector = detector;

  final Future<CliDetection> Function()? _detector;
  Process? _currentProcess;

  @override
  AIProvider get provider => AIProvider.anthropic;

  @override
  String get binaryName => 'claude';

  /// Resolves the absolute CLI path via the injected detector (wired in
  /// `ai_repository_impl.dart` to [CliDetectionService]). Falls back to the
  /// bare binary name only when no detector is wired (tests).
  Future<CliDetection> _detect() async {
    final detector = _detector;
    if (detector != null) return detector();
    return const CliDetection.notInstalled();
  }

  @override
  Stream<StreamEvent> streamEvents({
    required List<ChatMessage> history,
    required String prompt,
    required String workingDirectory,
    required String sessionId,
    required bool isFirstTurn,
  }) async* {
    // Defensive sessionId check: we only ever generate v4 UUIDs today, but
    // a future import/restore path could leak an attacker-shaped value into
    // argv. Reject anything that isn't a canonical UUID before spawn.
    if (!_uuidV4.hasMatch(sessionId)) {
      sLog('[ClaudeCli] rejected non-UUID sessionId at argv boundary');
      yield StreamEvent.cliStreamError(ClaudeCliFailure.unknown('invalid sessionId shape'));
      return;
    }

    // workingDirectory guard: must be an existing absolute directory inside
    // the user's filesystem. Since bypassPermissions is active, a stale or
    // attacker-influenced path (e.g. `~`, `/`) would give the CLI full
    // home-directory tool access.
    final wdDir = Directory(workingDirectory);
    if (!workingDirectory.startsWith('/') || !wdDir.existsSync()) {
      sLog('[ClaudeCli] rejected workingDirectory: $workingDirectory');
      yield StreamEvent.cliStreamError(ClaudeCliFailure.unknown('invalid workingDirectory'));
      return;
    }

    // Prefer the absolute path from detection so a hostile PATH prefix
    // (e.g. `~/.malicious/bin:$PATH`) cannot substitute a look-alike
    // binary. Falls back to binaryName only if detection didn't produce
    // a path (shouldn't happen in production — the switch that routes
    // here requires a successful probe).
    String exePath = binaryName;
    final detection = await _detect();
    if (detection is CliInstalled) exePath = detection.binaryPath;

    // Flag-shaped prompts slip past argv into the CLI's own option parser
    // (e.g. `--mcp-config /tmp/attacker.json`). `--` ends Claude Code's
    // option parsing; the prompt after it is always treated positionally.
    if (prompt.startsWith('-')) {
      sLog('[ClaudeCli] prompt begins with "-"; neutralising with -- separator');
    }

    final parser = ClaudeCliStreamParser();
    final args = <String>[
      '-p',
      '--output-format',
      'stream-json',
      '--include-partial-messages',
      '--permission-mode',
      'bypassPermissions',
      '--verbose',
      if (isFirstTurn) ...['--session-id', sessionId] else ...['--resume', sessionId],
      '--',
      prompt,
    ];

    // Minimal environment: HOME + PATH + standard XDG locations are enough
    // for Claude Code to locate its own config. Inheriting the parent's
    // full env would leak ANTHROPIC_API_KEY / GITHUB_TOKEN / AWS_* into
    // the CLI's child processes (which run under bypassPermissions).
    final parentEnv = Platform.environment;
    final minimalEnv = <String, String>{
      if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
      if (parentEnv['PATH'] != null) 'PATH': parentEnv['PATH']!,
      if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
      if (parentEnv['LANG'] != null) 'LANG': parentEnv['LANG']!,
      if (parentEnv['TMPDIR'] != null) 'TMPDIR': parentEnv['TMPDIR']!,
      if (parentEnv['SHELL'] != null) 'SHELL': parentEnv['SHELL']!,
    };

    final Process process;
    try {
      process = await Process.start(
        exePath,
        args,
        workingDirectory: workingDirectory,
        runInShell: false,
        includeParentEnvironment: false,
        environment: minimalEnv,
      );
    } on ProcessException catch (e) {
      dLog('[ClaudeCli] start failed: $e');
      yield StreamEvent.cliStreamError(const ClaudeCliFailure.notInstalled());
      return;
    } catch (e) {
      dLog('[ClaudeCli] start failed (unexpected): $e');
      yield StreamEvent.cliStreamError(ClaudeCliFailure.unknown(e));
      return;
    }

    _currentProcess = process;
    // Cap stderr capture so a chatty crash can't balloon memory.
    const stderrCap = 64 * 1024;
    final stderrBuffer = StringBuffer();
    final stderrSub = process.stderr.transform(utf8.decoder).listen((chunk) {
      if (stderrBuffer.length >= stderrCap) return;
      final remaining = stderrCap - stderrBuffer.length;
      stderrBuffer.write(chunk.length <= remaining ? chunk : chunk.substring(0, remaining));
    });

    var sawMessageStop = false;
    try {
      await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
        final event = parser.parseLine(line);
        if (event == null) continue;
        if (event is StreamDone) sawMessageStop = true;
        yield event;
      }

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        // Log raw stderr at the I/O boundary so operators can diagnose,
        // but never let it leak up — the failure union carries exitCode
        // and SessionService maps to a user-safe string.
        dLog('[ClaudeCli] process exited $exitCode\nstderr=${stderrBuffer.toString()}');
        yield StreamEvent.cliStreamError(ClaudeCliFailure.crashed(exitCode: exitCode, stderr: stderrBuffer.toString()));
      } else if (!sawMessageStop) {
        // Clean exit without a terminal frame — treat as truncation so
        // the consumer surfaces an error instead of a partial reply.
        dLog('[ClaudeCli] stdout closed without message_stop (exit=0)');
        yield StreamEvent.cliStreamError(
          ClaudeCliFailure.unknown('stream closed without message_stop (exit=$exitCode)'),
        );
      }
      // Terminal StreamDone is emitted by the parser on `message_stop`;
      // no need to re-emit here on clean exit.
    } finally {
      await stderrSub.cancel();
      _currentProcess = null;
    }
  }

  /// Cancels any in-flight process (called by SessionService on user stop).
  Future<void> cancel() async {
    final p = _currentProcess;
    if (p == null) return;
    p.kill(ProcessSignal.sigterm);
    final exited = await p.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () async {
        p.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    dLog('[ClaudeCli] cancelled with exit=$exited');
  }

  // ── AIRemoteDatasource methods ────────────────────────────────────────
  //
  // Note: CLI transport does not implement [TextStreamingDatasource]. Raw
  // text token streaming is not a capability this datasource can provide —
  // it delivers structured events through [streamEvents] instead, consumed
  // by SessionService's CLI branch. AIRepositoryImpl.streamMessage guards
  // with a type check before invocation.

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    final detection = await _detect();
    return detection is CliInstalled;
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    return AIModels.defaults.where((m) => m.provider == AIProvider.anthropic).toList();
  }
}
