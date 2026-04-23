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

  @override
  Future<CliDetection> detectInstalled() async {
    final detector = _detector;
    if (detector != null) return detector();
    try {
      final result = await Process.run(binaryName, ['--version']).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) return const CliDetection.notInstalled();
      return CliDetection.installed(
        version: result.stdout.toString().trim(),
        binaryPath: binaryName,
        authStatus: CliAuthStatus.unknown,
        checkedAt: DateTime.now(),
      );
    } catch (_) {
      return const CliDetection.notInstalled();
    }
  }

  @override
  Future<CliAuthStatus> checkAuthStatus() async {
    try {
      final result = await Process.run(binaryName, ['auth', 'status']).timeout(const Duration(seconds: 5));
      return result.exitCode == 0 ? CliAuthStatus.authenticated : CliAuthStatus.unauthenticated;
    } catch (_) {
      return CliAuthStatus.unknown;
    }
  }

  @override
  Stream<StreamEvent> streamEvents({
    required List<ChatMessage> history,
    required String prompt,
    required String workingDirectory,
    required String sessionId,
    required bool isFirstTurn,
  }) async* {
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
      prompt,
    ];

    final Process process;
    try {
      process = await Process.start(binaryName, args, workingDirectory: workingDirectory, runInShell: false);
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
    final stderrBuffer = StringBuffer();
    final stderrSub = process.stderr.transform(utf8.decoder).listen(stderrBuffer.write);

    try {
      await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
        final event = parser.parseLine(line);
        if (event != null) yield event;
      }

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        yield StreamEvent.cliStreamError(ClaudeCliFailure.crashed(exitCode: exitCode, stderr: stderrBuffer.toString()));
      } else {
        yield const StreamEvent.cliStreamDone();
      }
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

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    // SessionService routes CLI transport to streamEvents. This adapter exists
    // so AIRepositoryImpl can still satisfy the AIRemoteDatasource contract.
    yield* streamEvents(
      history: history,
      prompt: prompt,
      workingDirectory: Directory.current.path,
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      isFirstTurn: true,
    ).where((e) => e is TextDelta).cast<TextDelta>().map((e) => e.text);
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    final detection = await detectInstalled();
    if (detection is! CliInstalled) return false;
    return detection.authStatus == CliAuthStatus.authenticated;
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    return AIModels.defaults.where((m) => m.provider == AIProvider.anthropic).toList();
  }
}
