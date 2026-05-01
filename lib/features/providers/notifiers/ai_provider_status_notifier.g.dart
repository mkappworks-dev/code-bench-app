// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider_status_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Async snapshot of all registered AI providers with their availability status.
/// Rebuilt whenever [aIProviderServiceProvider] state changes.
///
/// Used by provider cards (e.g. Anthropic) to enable/disable the SDK transport
/// option based on whether the local binary is installed.

@ProviderFor(aiProviderStatus)
final aiProviderStatusProvider = AiProviderStatusProvider._();

/// Async snapshot of all registered AI providers with their availability status.
/// Rebuilt whenever [aIProviderServiceProvider] state changes.
///
/// Used by provider cards (e.g. Anthropic) to enable/disable the SDK transport
/// option based on whether the local binary is installed.

final class AiProviderStatusProvider
    extends $FunctionalProvider<AsyncValue<List<ProviderEntry>>, List<ProviderEntry>, FutureOr<List<ProviderEntry>>>
    with $FutureModifier<List<ProviderEntry>>, $FutureProvider<List<ProviderEntry>> {
  /// Async snapshot of all registered AI providers with their availability status.
  /// Rebuilt whenever [aIProviderServiceProvider] state changes.
  ///
  /// Used by provider cards (e.g. Anthropic) to enable/disable the SDK transport
  /// option based on whether the local binary is installed.
  AiProviderStatusProvider._()
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
  String debugGetCreateSourceHash() => _$aiProviderStatusHash();

  @$internal
  @override
  $FutureProviderElement<List<ProviderEntry>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProviderEntry>> create(Ref ref) {
    return aiProviderStatus(ref);
  }
}

String _$aiProviderStatusHash() => r'3d0ee7fa8eb847ade6a0627b0d3c051c0f489948';
