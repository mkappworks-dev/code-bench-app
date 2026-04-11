// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secure_storage_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(secureStorageSource)
final secureStorageSourceProvider = SecureStorageSourceProvider._();

final class SecureStorageSourceProvider
    extends $FunctionalProvider<SecureStorageSource, SecureStorageSource, SecureStorageSource>
    with $Provider<SecureStorageSource> {
  SecureStorageSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStorageSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStorageSourceHash();

  @$internal
  @override
  $ProviderElement<SecureStorageSource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  SecureStorageSource create(Ref ref) {
    return secureStorageSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecureStorageSource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<SecureStorageSource>(value));
  }
}

String _$secureStorageSourceHash() => r'b15f22b348732cb7c31fb84aa22fd56c167ef5d9';
