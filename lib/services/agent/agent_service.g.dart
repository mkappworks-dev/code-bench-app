// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(agentService)
final agentServiceProvider = AgentServiceProvider._();

final class AgentServiceProvider
    extends $FunctionalProvider<AsyncValue<AgentService>, AgentService, FutureOr<AgentService>>
    with $FutureModifier<AgentService>, $FutureProvider<AgentService> {
  AgentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentServiceHash();

  @$internal
  @override
  $FutureProviderElement<AgentService> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<AgentService> create(Ref ref) {
    return agentService(ref);
  }
}

String _$agentServiceHash() => r'6cc804aa1107f91465673efce8b7e0c041ec429f';
