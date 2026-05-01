import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/datasource/ai_provider_datasource.dart';
import '../../data/ai/datasource/claude_sdk_datasource_process.dart';
import '../../data/ai/datasource/codex_sdk_datasource_process.dart';

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
      'claude-sdk': ref.watch(claudeSdkDatasourceProcessProvider),
      'codex': ref.watch(codexSdkDatasourceProcessProvider),
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

  /// Detailed availability status for a single provider.
  Future<ProviderStatus> getStatus(String id) async {
    final provider = state[id];
    if (provider == null) {
      return const ProviderStatus.unavailable(reason: 'Provider not registered');
    }
    try {
      final available = await provider.isAvailable();
      if (!available) {
        return const ProviderStatus.unavailable(reason: 'Not installed or configured');
      }
      final version = await provider.getVersion();
      return ProviderStatus.available(version: version ?? 'unknown', checkedAt: DateTime.now());
    } catch (e) {
      return ProviderStatus.unavailable(reason: 'Error: $e');
    }
  }

  /// Status for all registered providers — consumed by per-provider cards
  /// (e.g. [AnthropicProviderCard]) to enable/disable the SDK transport
  /// option based on whether the local binary is installed.
  Future<List<ProviderEntry>> listWithStatus() async {
    final entries = <ProviderEntry>[];
    for (final MapEntry(:key, :value) in state.entries) {
      final status = await getStatus(key);
      entries.add(ProviderEntry(id: key, displayName: value.displayName, status: status));
    }
    return entries;
  }
}

/// Availability status of a single AI provider.
sealed class ProviderStatus {
  const ProviderStatus();

  const factory ProviderStatus.unavailable({required String reason}) = ProviderUnavailable;

  const factory ProviderStatus.available({required String version, required DateTime checkedAt}) = ProviderAvailable;
}

class ProviderUnavailable extends ProviderStatus {
  const ProviderUnavailable({required this.reason});
  final String reason;
}

class ProviderAvailable extends ProviderStatus {
  const ProviderAvailable({required this.version, required this.checkedAt});
  final String version;
  final DateTime checkedAt;
}

/// Entry in the provider list — surfaced by [listWithStatus] to provider
/// cards so they can render the right state for their SDK transport option.
class ProviderEntry {
  const ProviderEntry({required this.id, required this.displayName, required this.status});

  final String id;
  final String displayName;
  final ProviderStatus status;

  bool get isAvailable => status is ProviderAvailable;
}
