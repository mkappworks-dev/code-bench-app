// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_user_input_request_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-session notifier holding any in-flight agent question for that session.
/// Family-keyed by sessionId — concurrent sessions cannot trample each other,
/// and tab-switching while a question is open no longer routes the answer to
/// the wrong session.

@ProviderFor(AgentUserInputRequestNotifier)
final agentUserInputRequestProvider = AgentUserInputRequestNotifierFamily._();

/// Per-session notifier holding any in-flight agent question for that session.
/// Family-keyed by sessionId — concurrent sessions cannot trample each other,
/// and tab-switching while a question is open no longer routes the answer to
/// the wrong session.
final class AgentUserInputRequestNotifierProvider
    extends $NotifierProvider<AgentUserInputRequestNotifier, ProviderUserInputRequest?> {
  /// Per-session notifier holding any in-flight agent question for that session.
  /// Family-keyed by sessionId — concurrent sessions cannot trample each other,
  /// and tab-switching while a question is open no longer routes the answer to
  /// the wrong session.
  AgentUserInputRequestNotifierProvider._({
    required AgentUserInputRequestNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'agentUserInputRequestProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$agentUserInputRequestNotifierHash();

  @override
  String toString() {
    return r'agentUserInputRequestProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AgentUserInputRequestNotifier create() => AgentUserInputRequestNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderUserInputRequest? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProviderUserInputRequest?>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is AgentUserInputRequestNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$agentUserInputRequestNotifierHash() => r'd9031dc53f394aad70f66dde0be9d1c8a1522a67';

/// Per-session notifier holding any in-flight agent question for that session.
/// Family-keyed by sessionId — concurrent sessions cannot trample each other,
/// and tab-switching while a question is open no longer routes the answer to
/// the wrong session.

final class AgentUserInputRequestNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AgentUserInputRequestNotifier,
          ProviderUserInputRequest?,
          ProviderUserInputRequest?,
          ProviderUserInputRequest?,
          String
        > {
  AgentUserInputRequestNotifierFamily._()
    : super(
        retry: null,
        name: r'agentUserInputRequestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Per-session notifier holding any in-flight agent question for that session.
  /// Family-keyed by sessionId — concurrent sessions cannot trample each other,
  /// and tab-switching while a question is open no longer routes the answer to
  /// the wrong session.

  AgentUserInputRequestNotifierProvider call(String sessionId) =>
      AgentUserInputRequestNotifierProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'agentUserInputRequestProvider';
}

/// Per-session notifier holding any in-flight agent question for that session.
/// Family-keyed by sessionId — concurrent sessions cannot trample each other,
/// and tab-switching while a question is open no longer routes the answer to
/// the wrong session.

abstract class _$AgentUserInputRequestNotifier extends $Notifier<ProviderUserInputRequest?> {
  late final _$args = ref.$arg as String;
  String get sessionId => _$args;

  ProviderUserInputRequest? build(String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProviderUserInputRequest?, ProviderUserInputRequest?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProviderUserInputRequest?, ProviderUserInputRequest?>,
              ProviderUserInputRequest?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
