import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_message_action_notifier.g.dart';

sealed class MessageAction {
  const MessageAction(this.content);
  final String content;
}

final class RetryAction extends MessageAction {
  const RetryAction(super.content);
}

final class EditAction extends MessageAction {
  const EditAction(super.content);
}

@Riverpod(keepAlive: true)
class PendingMessageActionNotifier extends _$PendingMessageActionNotifier {
  @override
  MessageAction? build(String sessionId) => null;

  void retry(String content) => state = RetryAction(content);
  void edit(String content) => state = EditAction(content);
  void clear() => state = null;
}
