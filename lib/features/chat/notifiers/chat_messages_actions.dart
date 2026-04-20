import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/shared/chat_message.dart';
import '../../../services/session/session_service.dart';
import 'chat_messages_failure.dart';
import 'chat_notifier.dart';

part 'chat_messages_actions.g.dart';

/// Command notifier for message-list mutations that can fail and need a
/// stable, observable error surface (typed `AsyncError` carrying a
/// [ChatMessagesFailure]).
///
/// Send/cancel stay on [ChatMessagesNotifier] because they own streaming
/// state. Delete and load-more live here so widgets can `ref.listen` for
/// failures without being entangled with the streaming `AsyncValue`.
///
/// Single global slot (no family): only one session is active at a time, and
/// we want one snackbar per failed operation regardless of how many bubbles
/// are on screen.
@Riverpod(keepAlive: true)
class ChatMessagesActions extends _$ChatMessagesActions {
  @override
  FutureOr<void> build() {}

  ChatMessagesFailure _asFailure(Object e, ChatMessagesFailure Function() specific) => switch (e) {
    ChatMessagesFailure() => e,
    _ => specific(),
  };

  /// Deletes [messageId] from [sessionId] together with any trailing
  /// `interrupted` markers that follow it. The DB delete runs in a single
  /// transaction so a failure leaves no orphaned markers.
  Future<void> deleteMessage(String sessionId, String messageId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final service = await ref.read(sessionServiceProvider.future);
        final messages = ref.read(chatMessagesProvider(sessionId)).value ?? const <ChatMessage>[];
        final msgIdx = messages.indexWhere((m) => m.id == messageId);
        final trailing = msgIdx >= 0
            ? messages.skip(msgIdx + 1).takeWhile((m) => m.role == MessageRole.interrupted).toList()
            : const <ChatMessage>[];
        final ids = [messageId, ...trailing.map((m) => m.id)];
        await service.deleteMessages(sessionId, ids);
        ref.read(chatMessagesProvider(sessionId).notifier).removeFromState(ids);
      } catch (e, st) {
        dLog('[ChatMessagesActions] deleteMessage failed: $e');
        Error.throwWithStackTrace(_asFailure(e, () => const ChatMessagesFailure.deleteFailed()), st);
      }
    });
  }

  /// Loads the page of older messages at [offset] and prepends them to
  /// [sessionId]'s in-memory list.
  Future<void> loadMore(String sessionId, int offset) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final service = await ref.read(sessionServiceProvider.future);
        final older = await service.loadHistory(sessionId, limit: 50, offset: offset);
        ref.read(chatMessagesProvider(sessionId).notifier).prependOlder(older);
      } catch (e, st) {
        dLog('[ChatMessagesActions] loadMore failed: $e');
        Error.throwWithStackTrace(_asFailure(e, () => const ChatMessagesFailure.loadMoreFailed()), st);
      }
    });
  }
}
