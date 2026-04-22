// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(applyRepository)
final applyRepositoryProvider = ApplyRepositoryProvider._();

final class ApplyRepositoryProvider
    extends
        $FunctionalProvider<ApplyRepository, ApplyRepository, ApplyRepository>
    with $Provider<ApplyRepository> {
  ApplyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'applyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$applyRepositoryHash();

  @$internal
  @override
  $ProviderElement<ApplyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApplyRepository create(Ref ref) {
    return applyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApplyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApplyRepository>(value),
    );
  }
}

String _$applyRepositoryHash() => r'af2b2b5607ae2408e6c0d50cae4ffe17e75d535f';
