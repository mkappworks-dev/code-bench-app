// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider_status_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Async snapshot of all registered AI providers with their availability
/// status. The `recheck` method is the widget-facing entry point — widgets
/// must never call `ref.refresh(aiProviderStatusProvider)` directly (that
/// violates the architecture rule that widgets only reach notifiers, not
/// providers).

@ProviderFor(AiProviderStatusNotifier)
final aiProviderStatusProvider = AiProviderStatusNotifierProvider._();

/// Async snapshot of all registered AI providers with their availability
/// status. The `recheck` method is the widget-facing entry point — widgets
/// must never call `ref.refresh(aiProviderStatusProvider)` directly (that
/// violates the architecture rule that widgets only reach notifiers, not
/// providers).
final class AiProviderStatusNotifierProvider
    extends
        $AsyncNotifierProvider<AiProviderStatusNotifier, List<ProviderEntry>> {
  /// Async snapshot of all registered AI providers with their availability
  /// status. The `recheck` method is the widget-facing entry point — widgets
  /// must never call `ref.refresh(aiProviderStatusProvider)` directly (that
  /// violates the architecture rule that widgets only reach notifiers, not
  /// providers).
  AiProviderStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiProviderStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiProviderStatusNotifierHash();

  @$internal
  @override
  AiProviderStatusNotifier create() => AiProviderStatusNotifier();
}

String _$aiProviderStatusNotifierHash() =>
    r'91b5b5d50ac082b7b3d30776dfc40cb8613152b0';

/// Async snapshot of all registered AI providers with their availability
/// status. The `recheck` method is the widget-facing entry point — widgets
/// must never call `ref.refresh(aiProviderStatusProvider)` directly (that
/// violates the architecture rule that widgets only reach notifiers, not
/// providers).

abstract class _$AiProviderStatusNotifier
    extends $AsyncNotifier<List<ProviderEntry>> {
  FutureOr<List<ProviderEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ProviderEntry>>, List<ProviderEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ProviderEntry>>, List<ProviderEntry>>,
              AsyncValue<List<ProviderEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
