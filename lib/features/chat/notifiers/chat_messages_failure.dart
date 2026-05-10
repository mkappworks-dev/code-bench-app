import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_messages_failure.freezed.dart';

@freezed
sealed class ChatMessagesFailure with _$ChatMessagesFailure {
  const factory ChatMessagesFailure.deleteUserFailed() = ChatMessagesDeleteUserFailed;
  const factory ChatMessagesFailure.deleteAssistantFailed() = ChatMessagesDeleteAssistantFailed;
  const factory ChatMessagesFailure.retryFailed() = ChatMessagesRetryFailed;
  const factory ChatMessagesFailure.loadMoreFailed() = ChatMessagesLoadMoreFailed;
}
