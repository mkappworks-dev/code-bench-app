// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_user_input_request_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AgentUserInputRequestNotifier)
final agentUserInputRequestProvider = AgentUserInputRequestNotifierProvider._();

final class AgentUserInputRequestNotifierProvider
    extends
        $NotifierProvider<
          AgentUserInputRequestNotifier,
          ProviderUserInputRequest?
        > {
  AgentUserInputRequestNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentUserInputRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentUserInputRequestNotifierHash();

  @$internal
  @override
  AgentUserInputRequestNotifier create() => AgentUserInputRequestNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderUserInputRequest? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProviderUserInputRequest?>(value),
    );
  }
}

String _$agentUserInputRequestNotifierHash() =>
    r'afb01b081c32f77bc848de5ddff0ec7859549258';

abstract class _$AgentUserInputRequestNotifier
    extends $Notifier<ProviderUserInputRequest?> {
  ProviderUserInputRequest? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<ProviderUserInputRequest?, ProviderUserInputRequest?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProviderUserInputRequest?, ProviderUserInputRequest?>,
              ProviderUserInputRequest?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
