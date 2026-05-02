import '../models/detection_result.dart';
import '../models/provider_runtime_event.dart';

export '../models/detection_result.dart';
export '../models/provider_runtime_event.dart';

/// Contract for pluggable AI provider datasources (Claude CLI, Codex, etc.).
///
/// Each implementation speaks its own wire protocol and normalizes output to
/// [ProviderRuntimeEvent]s. Callers never need to know which provider is active.
///
/// Implementations live alongside this file with the appropriate suffix:
///   - HTTP-based: `*_datasource_dio.dart`   (e.g. `claude_cli_datasource_dio.dart`)
///   - Process-based: `*_datasource_process.dart` (e.g. `codex_datasource_process.dart`)
abstract interface class AIProviderDatasource {
  /// Unique identifier (e.g. "claude-cli", "codex").
  String get id;

  /// Display name for UI dropdowns (e.g. "Claude (API Key)", "Codex").
  String get displayName;

  /// Probe the provider for availability. Distinguishes `installed`,
  /// `unhealthy` (broken install / hung version probe), and `missing`
  /// (not on PATH) so the UI can render the right recovery affordance.
  Future<DetectionResult> detect();

  /// Send a message and stream normalized [ProviderRuntimeEvent]s.
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
  });

  /// Cancel any in-flight request.
  void cancel();

  /// Respond to a pending server-initiated permission request.
  /// No-op for providers that don't support interactive approval (e.g. HTTP/SSE).
  void respondToPermissionRequest(String requestId, {required bool approved});
}
