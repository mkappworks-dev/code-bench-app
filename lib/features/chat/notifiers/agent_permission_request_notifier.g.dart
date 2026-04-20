// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_permission_request_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AgentPermissionRequestNotifier)
final agentPermissionRequestProvider =
    AgentPermissionRequestNotifierProvider._();

final class AgentPermissionRequestNotifierProvider
    extends
        $NotifierProvider<AgentPermissionRequestNotifier, PermissionRequest?> {
  AgentPermissionRequestNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentPermissionRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentPermissionRequestNotifierHash();

  @$internal
  @override
  AgentPermissionRequestNotifier create() => AgentPermissionRequestNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PermissionRequest? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PermissionRequest?>(value),
    );
  }
}

String _$agentPermissionRequestNotifierHash() =>
    r'9206456f396eaad66b3806f259769b1fd972367c';

abstract class _$AgentPermissionRequestNotifier
    extends $Notifier<PermissionRequest?> {
  PermissionRequest? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PermissionRequest?, PermissionRequest?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PermissionRequest?, PermissionRequest?>,
              PermissionRequest?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
