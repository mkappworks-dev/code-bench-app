import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/shared/chat_message.dart';
import '../../data/session/models/tool_event.dart';
import '../../features/chat/notifiers/chat_notifier.dart';

part 'working_pill_notifier.g.dart';

/// Returns `true` when the message with [messageId] in [sessionId] has at
/// least one [ToolStatus.running] tool event.
///
/// Because this is a functional provider returning a [bool], Riverpod will
/// only notify [WorkingPill] when the running status actually flips — not
/// on every message content update — so the widget's elapsed-second timer
/// is not disturbed by unrelated message changes.
@riverpod
bool workingPillRunning(Ref ref, String sessionId, String messageId) {
  final messages = ref.watch(chatMessagesProvider(sessionId)).asData?.value ?? const <ChatMessage>[];
  final msg = messages.firstWhereOrNull((m) => m.id == messageId);
  return msg?.toolEvents.any((e) => e.status == ToolStatus.running) ?? false;
}
