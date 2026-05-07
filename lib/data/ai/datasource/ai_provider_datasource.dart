import '../../shared/ai_model.dart';
import '../models/auth_status.dart';
import '../models/detection_result.dart';
import '../models/provider_capabilities.dart';
import '../models/provider_runtime_event.dart';
import '../models/provider_turn_settings.dart';

export '../models/auth_status.dart';
export '../models/detection_result.dart';
export '../models/provider_capabilities.dart';
export '../models/provider_runtime_event.dart';
export '../models/provider_turn_settings.dart';

/// Contract for pluggable AI provider datasources — each normalizes its wire protocol to [ProviderRuntimeEvent]s.
abstract interface class AIProviderDatasource {
  /// Unique identifier (e.g. "claude-cli", "codex").
  String get id;

  /// Display name for UI dropdowns (e.g. "Claude (API Key)", "Codex").
  String get displayName;

  /// Probe the provider for availability. Distinguishes `installed`,
  /// `unhealthy` (broken install / hung version probe), and `missing`
  /// (not on PATH) so the UI can render the right recovery affordance.
  Future<DetectionResult> detect();

  /// Capability surface for the picked [model]; HTTP providers may shrink the surface based on model id.
  ProviderCapabilities capabilitiesFor(AIModel model);

  /// Send a message and stream normalized [ProviderRuntimeEvent]s.
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
    ProviderTurnSettings? settings,
  });

  /// Cancel the in-flight turn for [sessionId]. No-op if the session has no
  /// active turn or no associated process.
  void cancel(String sessionId);

  /// Resolve a server-initiated permission request originating from
  /// [sessionId]'s stream. No-op for providers that don't support
  /// interactive approval.
  void respondToPermissionRequest(String sessionId, String requestId, {required bool approved});

  /// Returns `AuthStatus.unknown` (not a thrown exception) on probe failure
  /// — send is never blocked on a probe we couldn't run.
  Future<AuthStatus> verifyAuth();

  /// Tear down child processes and resources. Called from the Riverpod
  /// `ref.onDispose` of the datasource provider so a provider rebuild does
  /// not orphan long-lived per-session processes.
  Future<void> dispose();
}
