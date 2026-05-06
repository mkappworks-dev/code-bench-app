// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ide_launch_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier mediating every IDE / Finder / terminal launch from
/// the top action bar. Widgets never reach [IdeService] directly.
///
/// Errors are emitted as [AsyncError] carrying an [IdeLaunchFailure] so
/// widgets can use [ref.listen] to surface inline error messages.

@ProviderFor(IdeLaunchActions)
final ideLaunchActionsProvider = IdeLaunchActionsProvider._();

/// Command notifier mediating every IDE / Finder / terminal launch from
/// the top action bar. Widgets never reach [IdeService] directly.
///
/// Errors are emitted as [AsyncError] carrying an [IdeLaunchFailure] so
/// widgets can use [ref.listen] to surface inline error messages.
final class IdeLaunchActionsProvider extends $AsyncNotifierProvider<IdeLaunchActions, void> {
  /// Command notifier mediating every IDE / Finder / terminal launch from
  /// the top action bar. Widgets never reach [IdeService] directly.
  ///
  /// Errors are emitted as [AsyncError] carrying an [IdeLaunchFailure] so
  /// widgets can use [ref.listen] to surface inline error messages.
  IdeLaunchActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ideLaunchActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ideLaunchActionsHash();

  @$internal
  @override
  IdeLaunchActions create() => IdeLaunchActions();
}

String _$ideLaunchActionsHash() => r'94c72ea9439c51ab55ebd9654995b20ff5af595d';

/// Command notifier mediating every IDE / Finder / terminal launch from
/// the top action bar. Widgets never reach [IdeService] directly.
///
/// Errors are emitted as [AsyncError] carrying an [IdeLaunchFailure] so
/// widgets can use [ref.listen] to surface inline error messages.

abstract class _$IdeLaunchActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>, AsyncValue<void>, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
