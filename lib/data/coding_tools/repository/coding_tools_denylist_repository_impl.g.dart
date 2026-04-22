// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_tools_denylist_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(codingToolsDenylistRepository)
final codingToolsDenylistRepositoryProvider = CodingToolsDenylistRepositoryProvider._();

final class CodingToolsDenylistRepositoryProvider
    extends
        $FunctionalProvider<CodingToolsDenylistRepository, CodingToolsDenylistRepository, CodingToolsDenylistRepository>
    with $Provider<CodingToolsDenylistRepository> {
  CodingToolsDenylistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codingToolsDenylistRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codingToolsDenylistRepositoryHash();

  @$internal
  @override
  $ProviderElement<CodingToolsDenylistRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  CodingToolsDenylistRepository create(Ref ref) {
    return codingToolsDenylistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CodingToolsDenylistRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<CodingToolsDenylistRepository>(value));
  }
}

String _$codingToolsDenylistRepositoryHash() => r'30e39cce4a24e7dd6ade97c84d58eb61b7153dee';
