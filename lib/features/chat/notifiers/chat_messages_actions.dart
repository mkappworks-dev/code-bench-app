import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/shared/chat_message.dart';
import '../../../services/session/session_service.dart';
import 'chat_messages_failure.dart';
import 'chat_notifier.dart';

part 'chat_messages_actions.g.dart';

/// Command notifier for delete / retry / load-more — the message-list mutations that need an observable error surface independent of the streaming `AsyncValue` on [ChatMessagesNotifier]. Single global slot so a duplicated snackbar across many bubble instances can't fire.
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
        Error.throwWithStackTrace(_asFailure(e, () => const ChatMessagesFailure.deleteUserFailed()), st);
      }
    });
  }

  /// Deletes the assistant message [messageId] along with trailing
  /// `interrupted` markers, then re-sends the preceding user message so the
  /// model generates a fresh response.
  ///
  /// Falls back to a plain delete when no preceding user message is found.
  Future<void> retryAssistantMessage(String sessionId, String messageId) async {
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
        final precedingUser = msgIdx > 0
            ? messages.take(msgIdx).toList().lastWhere((m) => m.role == MessageRole.user, orElse: () => messages[0])
            : null;
        if (precedingUser != null && precedingUser.role == MessageRole.user) {
          // sendMessage returns the caught error rather than throwing — discarding it would let a transport-not-ready / signed-out replay silently succeed in the UI even though no new assistant message was produced.
          final sendErr = await ref.read(chatMessagesProvider(sessionId).notifier).sendMessage(precedingUser.content);
          if (sendErr != null) {
            dLog('[ChatMessagesActions] retry resend failed: $sendErr');
            throw const ChatMessagesFailure.retryFailed();
          }
        }
      } catch (e, st) {
        dLog('[ChatMessagesActions] retryAssistantMessage failed: ${e.runtimeType}');
        Error.throwWithStackTrace(_asFailure(e, () => const ChatMessagesFailure.retryFailed()), st);
      }
    });
  }

  /// Deletes the assistant message [messageId] along with any trailing
  /// `interrupted` markers.
  Future<void> deleteAssistantMessage(String sessionId, String messageId) async {
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
        dLog('[ChatMessagesActions] deleteAssistantMessage failed: ${e.runtimeType}');
        Error.throwWithStackTrace(_asFailure(e, () => const ChatMessagesFailure.deleteAssistantFailed()), st);
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
