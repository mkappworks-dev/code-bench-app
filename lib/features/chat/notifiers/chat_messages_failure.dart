import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_messages_failure.freezed.dart';

@freezed
sealed class ChatMessagesFailure with _$ChatMessagesFailure {
  const factory ChatMessagesFailure.deleteFailed() = ChatMessagesDeleteFailed;
  const factory ChatMessagesFailure.retryFailed() = ChatMessagesRetryFailed;
  const factory ChatMessagesFailure.loadMoreFailed() = ChatMessagesLoadMoreFailed;
  const factory ChatMessagesFailure.unknown(Object error) = ChatMessagesUnknownError;
}
