import 'package:freezed_annotation/freezed_annotation.dart';

import 'transport_readiness.dart';

part 'agent_failure.freezed.dart';

@freezed
sealed class AgentFailure with _$AgentFailure {
  const factory AgentFailure.iterationCapReached() = AgentIterationCapReached;
  const factory AgentFailure.providerDoesNotSupportTools() = AgentProviderDoesNotSupportTools;
  const factory AgentFailure.streamAbortedUnexpectedly(String reason) = AgentStreamAbortedUnexpectedly;
  const factory AgentFailure.toolDispatchFailed(String toolName, String message) = AgentToolDispatchFailed;
  const factory AgentFailure.networkExhausted(int attempts) = AgentNetworkExhausted;
  const factory AgentFailure.transportNotReady(TransportReadiness readiness) = AgentTransportNotReady;
  const factory AgentFailure.unknown(Object error) = AgentUnknownError;
}
