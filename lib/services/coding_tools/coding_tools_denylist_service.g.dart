// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_tools_denylist_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(codingToolsDenylistService)
final codingToolsDenylistServiceProvider = CodingToolsDenylistServiceProvider._();

final class CodingToolsDenylistServiceProvider
    extends $FunctionalProvider<CodingToolsDenylistService, CodingToolsDenylistService, CodingToolsDenylistService>
    with $Provider<CodingToolsDenylistService> {
  CodingToolsDenylistServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codingToolsDenylistServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codingToolsDenylistServiceHash();

  @$internal
  @override
  $ProviderElement<CodingToolsDenylistService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  CodingToolsDenylistService create(Ref ref) {
    return codingToolsDenylistService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CodingToolsDenylistService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<CodingToolsDenylistService>(value));
  }
}

String _$codingToolsDenylistServiceHash() => r'55e05d55ba0765378989c46cf3f6b678dcbe156a';
