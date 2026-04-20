import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';

void main() {
  test('setIterationCapReached flips the flag on the matching message', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final capped = ChatMessage(
      id: 'cap',
      sessionId: 's',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime(2026, 4, 20),
      iterationCapReached: true,
    );

    final notifier = container.read(chatMessagesProvider('s').notifier);
    notifier.state = AsyncData([capped]);

    notifier.setIterationCapReached('cap', false);
    expect(container.read(chatMessagesProvider('s')).value!.first.iterationCapReached, isFalse);

    notifier.setIterationCapReached('cap', true);
    expect(container.read(chatMessagesProvider('s')).value!.first.iterationCapReached, isTrue);
  });
}
