import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/datasource/ai_provider_datasource.dart';
import '../../data/ai/datasource/claude_cli_datasource_process.dart';
import '../../data/ai/datasource/codex_cli_datasource_process.dart';

part 'ai_provider_service.g.dart';

/// Service that manages all available AI providers and their status.
///
/// State is a map of provider ID → [AIProviderDatasource] instance. Use [getProvider]
/// to get a specific provider, or [listWithStatus] for the full status list.
@Riverpod(keepAlive: true)
class AIProviderService extends _$AIProviderService {
  @override
  Map<String, AIProviderDatasource> build() {
    dLog('[AIProviderService] Initializing providers');
    return {
      'claude-cli': ref.watch(claudeCliDatasourceProcessProvider),
      'codex': ref.watch(codexCliDatasourceProcessProvider),
    };
  }

  /// Get a registered provider by ID, or null if not found.
  AIProviderDatasource? getProvider(String id) {
    final p = state[id];
    if (p == null) dLog('[AIProviderService] Provider $id not found');
    return p;
  }

  /// List all registered provider IDs.
  List<String> listProviderIds() => state.keys.toList();

  bool respondToUserInputRequest(String providerId, String sessionId, String requestId, {required String response}) {
    final ds = state[providerId];
    if (ds == null) {
      sLog('[AIProviderService] respondToUserInputRequest: unknown providerId $providerId');
      return false;
    }
    return ds.respondToUserInputRequest(sessionId, requestId, response: response);
  }

  /// Detailed availability status for a single provider.
  ///
  /// Distinguishes three underlying detection states from the datasource
  /// (`installed` / `unhealthy` / `missing`) and surfaces them via
  /// [ProviderStatus]. The UI uses [ProviderUnavailable.reasonKind] to
  /// pick the right copy ("install" vs "reinstall" vs "broken").
  Future<ProviderStatus> getStatus(String id) async {
    final provider = state[id];
    if (provider == null) {
      return const ProviderStatus.unavailable(
        reason: 'Provider not registered',
        reasonKind: ProviderUnavailableReason.notRegistered,
      );
    }
    final DetectionResult result;
    try {
      result = await provider.detect();
    } catch (e) {
      dLog('[AIProviderService] detect($id) threw: $e');
      return ProviderStatus.unavailable(
        reason: 'Detection failed: ${e.runtimeType}',
        reasonKind: ProviderUnavailableReason.detectionFailed,
      );
    }
    return switch (result) {
      DetectionInstalled(:final version) => ProviderStatus.available(version: version, checkedAt: DateTime.now()),
      DetectionUnhealthy(:final reason) => ProviderStatus.unavailable(
        reason: reason,
        reasonKind: ProviderUnavailableReason.unhealthy,
      ),
      DetectionMissing() => const ProviderStatus.unavailable(
        reason: 'Not installed or configured',
        reasonKind: ProviderUnavailableReason.missing,
      ),
    };
  }

  /// Returns [AuthStatus.unknown] for unregistered providers and probe
  /// exceptions — send is never blocked on a probe we couldn't run.
  Future<AuthStatus> getAuthStatus(String id) async {
    final provider = state[id];
    if (provider == null) {
      dLog('[AIProviderService] getAuthStatus: provider $id not registered');
      return const AuthStatus.unknown();
    }
    try {
      return await provider.verifyAuth();
    } catch (e) {
      dLog('[AIProviderService] verifyAuth($id) threw: $e');
      return const AuthStatus.unknown();
    }
  }

  /// Status for all registered providers — consumed by per-provider cards
  /// (e.g. [AnthropicProviderCard]) to enable/disable the CLI transport
  /// option based on whether the local binary is installed.
  Future<List<ProviderEntry>> listWithStatus() async {
    final futures = state.entries.map((entry) async {
      final id = entry.key;
      final ds = entry.value;
      final status = await getStatus(id);
      // Auth is meaningless on a missing binary — skip the probe.
      final authStatus = status is ProviderAvailable ? await getAuthStatus(id) : const AuthStatus.unknown();
      return ProviderEntry(id: id, displayName: ds.displayName, status: status, authStatus: authStatus);
    });
    return Future.wait(futures);
  }
}

/// Why a provider is unavailable. Drives UI copy: "install" vs "reinstall"
/// vs "Code Bench needs an update" vs "couldn't probe — retry".
enum ProviderUnavailableReason { missing, unhealthy, detectionFailed, notRegistered }

/// Availability status of a single AI provider.
sealed class ProviderStatus {
  const ProviderStatus();

  const factory ProviderStatus.unavailable({required String reason, required ProviderUnavailableReason reasonKind}) =
      ProviderUnavailable;

  const factory ProviderStatus.available({required String version, required DateTime checkedAt}) = ProviderAvailable;
}

class ProviderUnavailable extends ProviderStatus {
  const ProviderUnavailable({required this.reason, required this.reasonKind});
  final String reason;
  final ProviderUnavailableReason reasonKind;
}

class ProviderAvailable extends ProviderStatus {
  const ProviderAvailable({required this.version, required this.checkedAt});
  final String version;
  final DateTime checkedAt;
}

/// Entry in the provider list — surfaced by [listWithStatus] to provider
/// cards so they can render the right state for their CLI transport option.
class ProviderEntry {
  const ProviderEntry({required this.id, required this.displayName, required this.status, required this.authStatus});

  final String id;
  final String displayName;
  final ProviderStatus status;
  final AuthStatus authStatus;

  bool get isAvailable => status is ProviderAvailable;
}
