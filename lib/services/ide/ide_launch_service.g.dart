// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ide_launch_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ideLaunchService)
final ideLaunchServiceProvider = IdeLaunchServiceProvider._();

final class IdeLaunchServiceProvider extends $FunctionalProvider<IdeLaunchService, IdeLaunchService, IdeLaunchService>
    with $Provider<IdeLaunchService> {
  IdeLaunchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ideLaunchServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ideLaunchServiceHash();

  @$internal
  @override
  $ProviderElement<IdeLaunchService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  IdeLaunchService create(Ref ref) {
    return ideLaunchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdeLaunchService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<IdeLaunchService>(value));
  }
}

String _$ideLaunchServiceHash() => r'e67da7abe82da79b9282509a6fd317d8f89754ee';
