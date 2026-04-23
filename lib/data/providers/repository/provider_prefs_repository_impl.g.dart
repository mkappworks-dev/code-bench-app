// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_prefs_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(providerPrefsRepository)
final providerPrefsRepositoryProvider = ProviderPrefsRepositoryProvider._();

final class ProviderPrefsRepositoryProvider
    extends $FunctionalProvider<ProviderPrefsRepository, ProviderPrefsRepository, ProviderPrefsRepository>
    with $Provider<ProviderPrefsRepository> {
  ProviderPrefsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providerPrefsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providerPrefsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProviderPrefsRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProviderPrefsRepository create(Ref ref) {
    return providerPrefsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderPrefsRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProviderPrefsRepository>(value));
  }
}

String _$providerPrefsRepositoryHash() => r'344a9ea46be4c3583013e74df7e5b74ebabae8f0';
