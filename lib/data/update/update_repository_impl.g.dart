// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateRepository)
final updateRepositoryProvider = UpdateRepositoryProvider._();

final class UpdateRepositoryProvider extends $FunctionalProvider<UpdateRepository, UpdateRepository, UpdateRepository>
    with $Provider<UpdateRepository> {
  UpdateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateRepositoryHash();

  @$internal
  @override
  $ProviderElement<UpdateRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  UpdateRepository create(Ref ref) {
    return updateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<UpdateRepository>(value));
  }
}

String _$updateRepositoryHash() => r'e725cf919e55c430b7cd6f70f3c56debed778d31';
