import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/ai_provider/ai_provider_service.dart';

export '../../../services/ai_provider/ai_provider_service.dart'
    show ProviderEntry, ProviderAvailable, ProviderUnavailable, ProviderUnavailableReason;

part 'ai_provider_status_notifier.g.dart';

/// Async snapshot of all registered AI providers with their availability
/// status. The `recheck` method is the widget-facing entry point — widgets
/// must never call `ref.refresh(aiProviderStatusProvider)` directly (that
/// violates the architecture rule that widgets only reach notifiers, not
/// providers).
@riverpod
class AiProviderStatusNotifier extends _$AiProviderStatusNotifier {
  @override
  Future<List<ProviderEntry>> build() {
    return ref.watch(aIProviderServiceProvider.notifier).listWithStatus();
  }

  /// Re-probes every registered provider's availability. Widgets call this
  /// from the "Recheck" button on each provider card. Errors land in
  /// `state.error`; widgets read `state.hasError` after `await`.
  Future<void> recheck() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(aIProviderServiceProvider.notifier).listWithStatus());
  }
}
