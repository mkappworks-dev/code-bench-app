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

  /// Cancel any in-flight request.
  void cancel();

  /// Respond to a pending server-initiated permission request.
  /// No-op for providers that don't support interactive approval (e.g. HTTP/SSE).
  void respondToPermissionRequest(String requestId, {required bool approved});

  /// Returns `AuthStatus.unknown` (not a thrown exception) on probe failure
  /// — send is never blocked on a probe we couldn't run.
  Future<AuthStatus> verifyAuth();
}
