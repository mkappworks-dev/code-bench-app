import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/chat/models/agent_failure.dart';

part 'chat_stream_state.freezed.dart';

@freezed
sealed class ChatStreamState with _$ChatStreamState {
  const factory ChatStreamState.idle() = ChatStreamIdle;
  const factory ChatStreamState.connecting({required int attempt}) = ChatStreamConnecting;
  const factory ChatStreamState.streaming() = ChatStreamStreaming;
  const factory ChatStreamState.retrying({required int attempt, required Duration nextDelay}) = ChatStreamRetrying;
  const factory ChatStreamState.failed(AgentFailure failure) = ChatStreamFailed;
  const factory ChatStreamState.done() = ChatStreamDone;
}
