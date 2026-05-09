// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_capabilities_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(providerCapabilitiesService)
final providerCapabilitiesServiceProvider = ProviderCapabilitiesServiceProvider._();

final class ProviderCapabilitiesServiceProvider
    extends $FunctionalProvider<ProviderCapabilitiesService, ProviderCapabilitiesService, ProviderCapabilitiesService>
    with $Provider<ProviderCapabilitiesService> {
  ProviderCapabilitiesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providerCapabilitiesServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providerCapabilitiesServiceHash();

  @$internal
  @override
  $ProviderElement<ProviderCapabilitiesService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProviderCapabilitiesService create(Ref ref) {
    return providerCapabilitiesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderCapabilitiesService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProviderCapabilitiesService>(value));
  }
}

String _$providerCapabilitiesServiceHash() => r'2812b406611739d23011f8d2f2af870f798a4925';
