import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/data/session/repository/session_repository.dart';
import 'package:code_bench_app/data/ai/repository/ai_repository.dart';
import 'package:code_bench_app/services/session/session_service.dart';

class _FakeSessionRepo extends Fake implements SessionRepository {
  final messages = <ChatMessage>[];

  @override
  Future<void> persistMessage(String sessionId, ChatMessage message) async => messages.add(message);

  @override
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) async => messages;

  @override
  Future<void> updateSessionTitle(String sessionId, String title) async {}
}

class _FakeAIRepo extends Fake implements AIRepository {
  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    yield 'hello ';
    yield 'world';
  }
}

void main() {
  test('sendAndStream yields user then streamed assistant then final', () async {
    final svc = SessionService(session: _FakeSessionRepo(), ai: _FakeAIRepo());
    final model = AIModel(id: 'claude-3', modelId: 'claude-3', provider: AIProvider.anthropic, name: 'Claude');
    final events = await svc.sendAndStream(sessionId: 'sid', userInput: 'hi', model: model).toList();

    // First event: user message
    expect(events.first.role, MessageRole.user);
    expect(events.first.content, 'hi');

    // Middle events: streaming assistant
    final streaming = events.where((e) => e.isStreaming == true).toList();
    expect(streaming, isNotEmpty);

    // Last event: final persisted assistant message
    final last = events.last;
    expect(last.role, MessageRole.assistant);
    expect(last.isStreaming, isNot(true));
    expect(last.content, 'hello world');
  });
}
