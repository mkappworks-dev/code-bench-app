// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(providersService)
final providersServiceProvider = ProvidersServiceProvider._();

final class ProvidersServiceProvider extends $FunctionalProvider<ProvidersService, ProvidersService, ProvidersService>
    with $Provider<ProvidersService> {
  ProvidersServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providersServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providersServiceHash();

  @$internal
  @override
  $ProviderElement<ProvidersService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProvidersService create(Ref ref) {
    return providersService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProvidersService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProvidersService>(value));
  }
}

String _$providersServiceHash() => r'79291fcd47b4616b173f2061f659ac3c844cc6a6';
