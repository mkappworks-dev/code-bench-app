// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ide_launch_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier mediating every IDE / Finder / terminal launch from
/// the top action bar. Widgets never reach [IdeLaunchService] directly.
///
/// The service already returns a user-facing error message (or `null` on
/// success), so these methods are thin passthroughs — no extra logging
/// is needed at this layer.

@ProviderFor(IdeLaunchActions)
final ideLaunchActionsProvider = IdeLaunchActionsProvider._();

/// Command notifier mediating every IDE / Finder / terminal launch from
/// the top action bar. Widgets never reach [IdeLaunchService] directly.
///
/// The service already returns a user-facing error message (or `null` on
/// success), so these methods are thin passthroughs — no extra logging
/// is needed at this layer.
final class IdeLaunchActionsProvider extends $NotifierProvider<IdeLaunchActions, void> {
  /// Command notifier mediating every IDE / Finder / terminal launch from
  /// the top action bar. Widgets never reach [IdeLaunchService] directly.
  ///
  /// The service already returns a user-facing error message (or `null` on
  /// success), so these methods are thin passthroughs — no extra logging
  /// is needed at this layer.
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$ideLaunchActionsHash() => r'2c780be9fe3a83e7c9b7715639e15330046aa02e';

/// Command notifier mediating every IDE / Finder / terminal launch from
/// the top action bar. Widgets never reach [IdeLaunchService] directly.
///
/// The service already returns a user-facing error message (or `null` on
/// success), so these methods are thin passthroughs — no extra logging
/// is needed at this layer.

abstract class _$IdeLaunchActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
