// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_output_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActionOutputNotifier)
final actionOutputProvider = ActionOutputNotifierProvider._();

final class ActionOutputNotifierProvider extends $NotifierProvider<ActionOutputNotifier, ActionOutputState> {
  ActionOutputNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'actionOutputProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$actionOutputNotifierHash();

  @$internal
  @override
  ActionOutputNotifier create() => ActionOutputNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActionOutputState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ActionOutputState>(value));
  }
}

String _$actionOutputNotifierHash() => r'c6e3530ea0ce274624c34620e6f45d662eb5c6cc';

abstract class _$ActionOutputNotifier extends $Notifier<ActionOutputState> {
  ActionOutputState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ActionOutputState, ActionOutputState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActionOutputState, ActionOutputState>,
              ActionOutputState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
