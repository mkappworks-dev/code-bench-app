// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides an [AgentService] wired to the cancel flag and permission-request
/// notifier from the chat feature layer.

@ProviderFor(agentService)
final agentServiceProvider = AgentServiceProvider._();

/// Provides an [AgentService] wired to the cancel flag and permission-request
/// notifier from the chat feature layer.

final class AgentServiceProvider
    extends $FunctionalProvider<AsyncValue<AgentService>, AgentService, FutureOr<AgentService>>
    with $FutureModifier<AgentService>, $FutureProvider<AgentService> {
  /// Provides an [AgentService] wired to the cancel flag and permission-request
  /// notifier from the chat feature layer.
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

String _$agentServiceHash() => r'756ce404747bcf7f9293c8b7fd02f3994d370f39';
