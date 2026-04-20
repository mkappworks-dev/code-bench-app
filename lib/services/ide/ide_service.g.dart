// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ide_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ideService)
final ideServiceProvider = IdeServiceProvider._();

final class IdeServiceProvider
    extends $FunctionalProvider<IdeService, IdeService, IdeService>
    with $Provider<IdeService> {
  IdeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ideServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ideServiceHash();

  @$internal
  @override
  $ProviderElement<IdeService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IdeService create(Ref ref) {
    return ideService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdeService>(value),
    );
  }
}

String _$ideServiceHash() => r'd06ccedbfab1059550a14496bf548f0f8492bd5d';
