import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/repository/ai_repository.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/services/ai/ai_service.dart';

class _FakeAIRepo extends Fake implements AIRepository {
  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    yield 'chunk1 ';
    yield 'chunk2';
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async => true;

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) async => [];
}

void main() {
  late AIService svc;

  setUp(() => svc = AIService(repo: _FakeAIRepo(), uuidGen: () => 'test-id'));

  test('sendMessage buffers stream into a single ChatMessage', () async {
    final model = AIModel(id: 'claude-3', modelId: 'claude-3', provider: AIProvider.anthropic, name: 'Claude');
    final msg = await svc.sendMessage(history: [], prompt: 'hello', model: model);
    expect(msg.content, 'chunk1 chunk2');
    expect(msg.role, MessageRole.assistant);
    expect(msg.id, 'test-id');
  });

  test('testConnection delegates to repository', () async {
    final model = AIModel(id: 'claude-3', modelId: 'claude-3', provider: AIProvider.anthropic, name: 'Claude');
    expect(await svc.testConnection(model, 'key'), isTrue);
  });

  test('streamMessage delegates to repository', () async {
    final model = AIModel(id: 'claude-3', modelId: 'claude-3', provider: AIProvider.anthropic, name: 'Claude');
    final chunks = await svc.streamMessage(history: [], prompt: 'hi', model: model).toList();
    expect(chunks, ['chunk1 ', 'chunk2']);
  });
}
