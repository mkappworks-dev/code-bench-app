// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_cancel_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cooperative cancel flag read by [AgentService] at each tool boundary.
/// Separate from the plain-text stream cancel so both can be flipped by a
/// single stop-button press without coupling their wiring.

@ProviderFor(AgentCancelNotifier)
final agentCancelProvider = AgentCancelNotifierProvider._();

/// Cooperative cancel flag read by [AgentService] at each tool boundary.
/// Separate from the plain-text stream cancel so both can be flipped by a
/// single stop-button press without coupling their wiring.
final class AgentCancelNotifierProvider extends $NotifierProvider<AgentCancelNotifier, bool> {
  /// Cooperative cancel flag read by [AgentService] at each tool boundary.
  /// Separate from the plain-text stream cancel so both can be flipped by a
  /// single stop-button press without coupling their wiring.
  AgentCancelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentCancelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentCancelNotifierHash();

  @$internal
  @override
  AgentCancelNotifier create() => AgentCancelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$agentCancelNotifierHash() => r'c43ce94e836454f64ec244ec3e23302b76465627';

/// Cooperative cancel flag read by [AgentService] at each tool boundary.
/// Separate from the plain-text stream cancel so both can be flipped by a
/// single stop-button press without coupling their wiring.

abstract class _$AgentCancelNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
