// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_tools_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(codingToolsRepository)
final codingToolsRepositoryProvider = CodingToolsRepositoryProvider._();

final class CodingToolsRepositoryProvider
    extends
        $FunctionalProvider<
          CodingToolsRepository,
          CodingToolsRepository,
          CodingToolsRepository
        >
    with $Provider<CodingToolsRepository> {
  CodingToolsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codingToolsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codingToolsRepositoryHash();

  @$internal
  @override
  $ProviderElement<CodingToolsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CodingToolsRepository create(Ref ref) {
    return codingToolsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CodingToolsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CodingToolsRepository>(value),
    );
  }
}

String _$codingToolsRepositoryHash() =>
    r'c0358c38496a234263503949702769d4e37e4231';
