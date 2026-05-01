import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/ai_provider/ai_provider_service.dart';

export '../../../services/ai_provider/ai_provider_service.dart'
    show ProviderEntry, ProviderAvailable, ProviderUnavailable;

part 'ai_provider_status_notifier.g.dart';

/// Async snapshot of all registered AI providers with their availability status.
/// Rebuilt whenever [aIProviderServiceProvider] state changes.
///
/// Used by provider cards (e.g. Anthropic) to enable/disable the SDK transport
/// option based on whether the local binary is installed.
@riverpod
Future<List<ProviderEntry>> aiProviderStatus(Ref ref) {
  return ref.watch(aIProviderServiceProvider.notifier).listWithStatus();
}
