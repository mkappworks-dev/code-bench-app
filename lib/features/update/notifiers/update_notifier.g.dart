// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateLastChecked)
final updateLastCheckedProvider = UpdateLastCheckedProvider._();

final class UpdateLastCheckedProvider
    extends $FunctionalProvider<AsyncValue<UpdateLastChecked?>, UpdateLastChecked?, FutureOr<UpdateLastChecked?>>
    with $FutureModifier<UpdateLastChecked?>, $FutureProvider<UpdateLastChecked?> {
  UpdateLastCheckedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateLastCheckedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateLastCheckedHash();

  @$internal
  @override
  $FutureProviderElement<UpdateLastChecked?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UpdateLastChecked?> create(Ref ref) {
    return updateLastChecked(ref);
  }
}

String _$updateLastCheckedHash() => r'd0d3cc407a5ce8af8f19bba6c26927794008b8df';

@ProviderFor(packageVersion)
final packageVersionProvider = PackageVersionProvider._();

final class PackageVersionProvider extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  PackageVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return packageVersion(ref);
  }
}

String _$packageVersionHash() => r'4d98f96bd5204c1669f8be48831091660117f005';

@ProviderFor(UpdateNotifier)
final updateProvider = UpdateNotifierProvider._();

final class UpdateNotifierProvider extends $NotifierProvider<UpdateNotifier, UpdateState> {
  UpdateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateNotifierHash();

  @$internal
  @override
  UpdateNotifier create() => UpdateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<UpdateState>(value));
  }
}

String _$updateNotifierHash() => r'1a8bf6ad967315def7e12fd646851a6cd805b84d';

abstract class _$UpdateNotifier extends $Notifier<UpdateState> {
  UpdateState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UpdateState, UpdateState>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<UpdateState, UpdateState>, UpdateState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
