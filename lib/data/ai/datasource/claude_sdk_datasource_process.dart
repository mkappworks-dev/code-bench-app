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
  StreamController<ProviderRuntimeEvent>? _controller;
  final Set<String> _knownSessions = {};

  @override
  String get id => 'claude-sdk';

  @override
  String get displayName => 'Claude Code SDK';

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
    try {
      final result = await Process.run(binaryPath, ['--version']).timeout(const Duration(seconds: 5));
      if (result.exitCode == 0) return (result.stdout as String).trim();
    } catch (_) {}
    return null;
  }

  @override
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
  }) {
    _controller = StreamController<ProviderRuntimeEvent>.broadcast();
    _stream(prompt: prompt, sessionId: sessionId, workingDirectory: workingDirectory);
    return _controller!.stream;
  }

  Future<void> _stream({required String prompt, required String sessionId, required String workingDirectory}) async {
    try {
      _controller?.add(ProviderInit(provider: id));

      // sessionId guard — we only ever generate v4 UUIDs, but a future
      // import/restore path could leak an attacker-shaped value into argv.
      if (!_uuidV4.hasMatch(sessionId)) {
        sLog('[ClaudeSdk] rejected non-UUID sessionId at argv boundary');
        _controller?.add(const ProviderStreamFailure(error: 'invalid sessionId shape'));
        await _controller?.close();
        return;
      }

      // workingDirectory guard — must be an existing absolute path. The CLI
      // runs with bypassPermissions so a stale or attacker-influenced path
      // (e.g. `~`, `/`) would give it full home-directory tool access.
      final wdDir = Directory(workingDirectory);
      if (!workingDirectory.startsWith('/') || !wdDir.existsSync()) {
        sLog('[ClaudeSdk] rejected workingDirectory: $workingDirectory');
        _controller?.add(const ProviderStreamFailure(error: 'invalid workingDirectory'));
        await _controller?.close();
        return;
      }

      // Flag-shaped prompts slip past argv into the CLI's own option parser.
      // `--` ends Claude Code's option parsing; the prompt after it is
      // always treated positionally.
      if (prompt.startsWith('-')) {
        sLog('[ClaudeSdk] prompt begins with "-"; neutralising with -- separator');
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

      final Process process;
      try {
        process = await Process.start(
          binaryPath,
          args,
          workingDirectory: workingDirectory,
          runInShell: false,
          includeParentEnvironment: false,
          environment: minimalEnv,
        );
      } on ProcessException catch (e) {
        dLog('[ClaudeSdk] start failed: $e');
        _controller?.add(const ProviderStreamFailure(error: 'Claude Code CLI is not installed or not on PATH'));
        await _controller?.close();
        return;
      }

      _process = process;

      // Cap stderr so a chatty crash can't balloon memory.
      const stderrCap = 64 * 1024;
      final stderrBuffer = StringBuffer();
      final stderrSub = process.stderr.transform(utf8.decoder).listen((chunk) {
        if (stderrBuffer.length >= stderrCap) return;
        final remaining = stderrCap - stderrBuffer.length;
        stderrBuffer.write(chunk.length <= remaining ? chunk : chunk.substring(0, remaining));
      });

      final parser = ClaudeSdkStreamParser();
      var sawDone = false;

      try {
        await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
          final event = parser.parseLine(line);
          if (event == null) continue;
          final mapped = _toProviderEvent(event);
          if (mapped == null) continue;
          if (mapped is ProviderStreamDone) sawDone = true;
          _controller?.add(mapped);
        }

        final exitCode = await process.exitCode;
        if (exitCode != 0) {
          dLog('[ClaudeSdk] process exited $exitCode\nstderr=${stderrBuffer.toString()}');
          _controller?.add(ProviderStreamFailure(error: 'claude exited $exitCode', details: stderrBuffer.toString()));
        } else if (!sawDone) {
          dLog('[ClaudeSdk] stdout closed without message_stop (exit=0)');
          _controller?.add(const ProviderStreamFailure(error: 'stream closed without message_stop'));
        } else {
          // Mark this session as known so subsequent turns use --resume.
          _knownSessions.add(sessionId);
        }
      } finally {
        await stderrSub.cancel();
        _process = null;
      }
    } catch (e, st) {
      dLog('[ClaudeSdk] send failed: $e\n$st');
      _controller?.add(ProviderStreamFailure(error: e));
    } finally {
      await _controller?.close();
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
    final p = _process;
    if (p != null) p.kill(ProcessSignal.sigterm);
    _controller?.close();
  }

  @override
  void respondToPermissionRequest(String requestId, {required bool approved}) {
    // Claude Code CLI runs with --permission-mode bypassPermissions, so it
    // never sends permission requests back to the host.
  }
}
