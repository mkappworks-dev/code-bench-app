import '../models/provider_runtime_event.dart';

export '../models/provider_runtime_event.dart';

/// Contract for pluggable AI provider datasources (Claude SDK, Codex, etc.).
///
/// Each implementation speaks its own wire protocol and normalizes output to
/// [ProviderRuntimeEvent]s. Callers never need to know which provider is active.
///
/// Implementations live alongside this file with the appropriate suffix:
///   - HTTP-based: `*_datasource_dio.dart`   (e.g. `claude_sdk_datasource_dio.dart`)
///   - Process-based: `*_datasource_process.dart` (e.g. `codex_datasource_process.dart`)
abstract interface class AIProviderDatasource {
  /// Unique identifier (e.g. "claude-sdk", "codex").
  String get id;

  /// Display name for UI dropdowns (e.g. "Claude (API Key)", "Codex").
  String get displayName;

  /// Whether this provider is installed and configured.
  /// For SDK providers: API key is present.
  /// For binary providers: binary is on PATH.
  Future<bool> isAvailable();

  /// Human-readable version string, or null if not yet known.
  Future<String?> getVersion();

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
