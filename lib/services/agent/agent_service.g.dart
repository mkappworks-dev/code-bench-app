// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides an [AgentService] with a no-op cancel flag.
///
/// The cancel flag is intentionally left as `() => false` here because the
/// service layer must not import from `lib/features/`. Callers that need
/// cooperative cancellation (e.g. [ChatMessagesActions]) should supply their
/// own cancel closure by constructing an [AgentService] directly — or by
/// reading [agentCancelProvider] themselves and passing it as a closure to
/// [AgentService.runAgenticTurn] via a wrapper.

@ProviderFor(agentService)
final agentServiceProvider = AgentServiceProvider._();

/// Provides an [AgentService] with a no-op cancel flag.
///
/// The cancel flag is intentionally left as `() => false` here because the
/// service layer must not import from `lib/features/`. Callers that need
/// cooperative cancellation (e.g. [ChatMessagesActions]) should supply their
/// own cancel closure by constructing an [AgentService] directly — or by
/// reading [agentCancelProvider] themselves and passing it as a closure to
/// [AgentService.runAgenticTurn] via a wrapper.

final class AgentServiceProvider
    extends $FunctionalProvider<AsyncValue<AgentService>, AgentService, FutureOr<AgentService>>
    with $FutureModifier<AgentService>, $FutureProvider<AgentService> {
  /// Provides an [AgentService] with a no-op cancel flag.
  ///
  /// The cancel flag is intentionally left as `() => false` here because the
  /// service layer must not import from `lib/features/`. Callers that need
  /// cooperative cancellation (e.g. [ChatMessagesActions]) should supply their
  /// own cancel closure by constructing an [AgentService] directly — or by
  /// reading [agentCancelProvider] themselves and passing it as a closure to
  /// [AgentService.runAgenticTurn] via a wrapper.
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

String _$agentServiceHash() => r'1a74d26ba9b66f9f1f86874e0b73eeab9bd40d2e';
