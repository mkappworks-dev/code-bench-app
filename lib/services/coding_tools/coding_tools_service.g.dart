// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_tools_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(codingToolsService)
final codingToolsServiceProvider = CodingToolsServiceProvider._();

final class CodingToolsServiceProvider
    extends
        $FunctionalProvider<
          CodingToolsService,
          CodingToolsService,
          CodingToolsService
        >
    with $Provider<CodingToolsService> {
  CodingToolsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codingToolsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codingToolsServiceHash();

  @$internal
  @override
  $ProviderElement<CodingToolsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CodingToolsService create(Ref ref) {
    return codingToolsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CodingToolsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CodingToolsService>(value),
    );
  }
}

String _$codingToolsServiceHash() =>
    r'241e27c749a10eeaa99f56fd434fdce297433ef2';
