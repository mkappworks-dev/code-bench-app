import '../../shared/chat_message.dart';
import '../models/cli_detection.dart';
import '../models/stream_event.dart';
import 'ai_remote_datasource.dart';

/// Shared base for CLI-backed inference datasources.
///
/// Concrete implementations (Phase 7: Claude Code; Phase 8: Codex; Phase 9:
/// Gemini CLI) spawn a local CLI binary via [Process.start] and stream its
/// output as [StreamEvent]s.
abstract class CliRemoteDatasource implements AIRemoteDatasource {
  /// Binary name as invoked on PATH (e.g. `'claude'`, `'codex'`, `'gemini'`).
  String get binaryName;

  /// One-shot detection probe: is the binary installed and what's its version?
  Future<CliDetection> detectInstalled();

  /// Auth status probe. Only meaningful when [detectInstalled] returned installed.
  Future<CliAuthStatus> checkAuthStatus();

  /// Richer stream used when CLI transport is active. Yields structured
  /// [StreamEvent]s (text, tool_use, tool_result, thinking) parsed from the
  /// CLI's native wire format. The chat layer consumes this and bypasses
  /// Code Bench's agent loop.
  Stream<StreamEvent> streamEvents({
    required List<ChatMessage> history,
    required String prompt,
    required String workingDirectory,
    required String sessionId,
    required bool isFirstTurn,
  });
}
