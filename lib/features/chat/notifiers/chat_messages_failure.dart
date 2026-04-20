import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_messages_failure.freezed.dart';

@freezed
sealed class ChatMessagesFailure with _$ChatMessagesFailure {
  /// Failed to delete one or more messages from the database.
  const factory ChatMessagesFailure.deleteFailed() = ChatMessagesDeleteFailed;

  /// Failed to fetch the next page of older messages.
  const factory ChatMessagesFailure.loadMoreFailed() = ChatMessagesLoadMoreFailed;

  const factory ChatMessagesFailure.unknown(Object error) = ChatMessagesUnknownError;
}
