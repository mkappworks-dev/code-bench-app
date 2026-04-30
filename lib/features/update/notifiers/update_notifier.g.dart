// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateLastChecked)
final updateLastCheckedProvider = UpdateLastCheckedProvider._();

final class UpdateLastCheckedProvider extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
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
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return updateLastChecked(ref);
  }
}

String _$updateLastCheckedHash() => r'b3b84b6d5ba97bcc8980d7be6bf95d75569e2acb';

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

String _$updateNotifierHash() => r'95f7f945bfa7c99063645980aae18cc1fde10f03';

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
