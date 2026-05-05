// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_output_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier that runs a user-defined [ProjectAction] as a subprocess and
/// streams its stdout/stderr lines into [ActionOutputState].
///
/// Lives in `lib/shell/notifiers/` because [ActionOutputPanel] (the widget
/// that displays it) is a shell-level widget. Process lifecycle is owned by
/// [ActionRunnerService] — widgets only call [run] and [clear].

@ProviderFor(ActionOutputNotifier)
final actionOutputProvider = ActionOutputNotifierProvider._();

/// Notifier that runs a user-defined [ProjectAction] as a subprocess and
/// streams its stdout/stderr lines into [ActionOutputState].
///
/// Lives in `lib/shell/notifiers/` because [ActionOutputPanel] (the widget
/// that displays it) is a shell-level widget. Process lifecycle is owned by
/// [ActionRunnerService] — widgets only call [run] and [clear].
final class ActionOutputNotifierProvider extends $NotifierProvider<ActionOutputNotifier, ActionOutputState> {
  /// Notifier that runs a user-defined [ProjectAction] as a subprocess and
  /// streams its stdout/stderr lines into [ActionOutputState].
  ///
  /// Lives in `lib/shell/notifiers/` because [ActionOutputPanel] (the widget
  /// that displays it) is a shell-level widget. Process lifecycle is owned by
  /// [ActionRunnerService] — widgets only call [run] and [clear].
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

String _$actionOutputNotifierHash() => r'6053dac27fd2ca9ffb51fb91dc4cbe1bb9d07c4b';

/// Notifier that runs a user-defined [ProjectAction] as a subprocess and
/// streams its stdout/stderr lines into [ActionOutputState].
///
/// Lives in `lib/shell/notifiers/` because [ActionOutputPanel] (the widget
/// that displays it) is a shell-level widget. Process lifecycle is owned by
/// [ActionRunnerService] — widgets only call [run] and [clear].

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
