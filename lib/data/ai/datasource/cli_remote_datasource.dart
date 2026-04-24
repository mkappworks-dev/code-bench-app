import '../../shared/chat_message.dart';
import '../models/stream_event.dart';
import 'ai_remote_datasource.dart';

/// Shared base for CLI-backed inference datasources.
///
/// Concrete implementations (Phase 7: Claude Code; Phase 8: Codex; Phase 9:
/// Gemini CLI) spawn a local CLI binary via [Process.start] and stream its
/// output as [StreamEvent]s.
///
/// Detection (`claude --version`, auth probe) does NOT live on this interface —
/// it belongs to `CliDetectionService`, which owns TTL caching and is shared
/// across the UI card and the datasource's own `testConnection`.
abstract class CliRemoteDatasource implements AIRemoteDatasource {
  /// Binary name as invoked on PATH (e.g. `'claude'`, `'codex'`, `'gemini'`).
  String get binaryName;

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
