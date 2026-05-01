// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Service that manages all available AI providers and their status.
///
/// State is a map of provider ID → [AIProviderDatasource] instance. Use [getProvider]
/// to get a specific provider, or [listWithStatus] for the full status list.

@ProviderFor(AIProviderService)
final aIProviderServiceProvider = AIProviderServiceProvider._();

/// Service that manages all available AI providers and their status.
///
/// State is a map of provider ID → [AIProviderDatasource] instance. Use [getProvider]
/// to get a specific provider, or [listWithStatus] for the full status list.
final class AIProviderServiceProvider extends $NotifierProvider<AIProviderService, Map<String, AIProviderDatasource>> {
  /// Service that manages all available AI providers and their status.
  ///
  /// State is a map of provider ID → [AIProviderDatasource] instance. Use [getProvider]
  /// to get a specific provider, or [listWithStatus] for the full status list.
  AIProviderServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aIProviderServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aIProviderServiceHash();

  @$internal
  @override
  AIProviderService create() => AIProviderService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, AIProviderDatasource> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, AIProviderDatasource>>(value),
    );
  }
}

String _$aIProviderServiceHash() => r'72dab6241b23ebd4aa32f4e1c5d0f070a4d1b5a1';

/// Service that manages all available AI providers and their status.
///
/// State is a map of provider ID → [AIProviderDatasource] instance. Use [getProvider]
/// to get a specific provider, or [listWithStatus] for the full status list.

abstract class _$AIProviderService extends $Notifier<Map<String, AIProviderDatasource>> {
  Map<String, AIProviderDatasource> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, AIProviderDatasource>, Map<String, AIProviderDatasource>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, AIProviderDatasource>, Map<String, AIProviderDatasource>>,
              Map<String, AIProviderDatasource>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
