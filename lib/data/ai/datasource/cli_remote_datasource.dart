import '../models/cli_detection.dart';
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
}
