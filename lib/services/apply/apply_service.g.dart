// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(applyService)
final applyServiceProvider = ApplyServiceProvider._();

final class ApplyServiceProvider extends $FunctionalProvider<ApplyService, ApplyService, ApplyService>
    with $Provider<ApplyService> {
  ApplyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'applyServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$applyServiceHash();

  @$internal
  @override
  $ProviderElement<ApplyService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ApplyService create(Ref ref) {
    return applyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApplyService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ApplyService>(value));
  }
}

String _$applyServiceHash() => r'f16c22401ad81ba54499e2584a04e71f7d29e801';
