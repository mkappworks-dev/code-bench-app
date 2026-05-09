// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_cancel_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cooperative per-session cancel flags read by [AgentService] / [ChatStreamRegistryService] at each tool boundary; tracking by sessionId stops one chat's stop-button from cancelling concurrent chats' streams.

@ProviderFor(AgentCancelNotifier)
final agentCancelProvider = AgentCancelNotifierProvider._();

/// Cooperative per-session cancel flags read by [AgentService] / [ChatStreamRegistryService] at each tool boundary; tracking by sessionId stops one chat's stop-button from cancelling concurrent chats' streams.
final class AgentCancelNotifierProvider extends $NotifierProvider<AgentCancelNotifier, Set<String>> {
  /// Cooperative per-session cancel flags read by [AgentService] / [ChatStreamRegistryService] at each tool boundary; tracking by sessionId stops one chat's stop-button from cancelling concurrent chats' streams.
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
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Set<String>>(value));
  }
}

String _$agentCancelNotifierHash() => r'42e0ff1dc8ca568f64b32b64a07767f086a11752';

/// Cooperative per-session cancel flags read by [AgentService] / [ChatStreamRegistryService] at each tool boundary; tracking by sessionId stops one chat's stop-button from cancelling concurrent chats' streams.

abstract class _$AgentCancelNotifier extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<Set<String>, Set<String>>, Set<String>, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
