import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';
import 'package:code_bench_app/data/ai/repository/ai_repository.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_definition.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tools_denylist_state.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/session/models/session_settings.dart';
import 'package:code_bench_app/data/session/repository/session_repository.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/services/agent/agent_service.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/coding_tools_service.dart';
import 'package:code_bench_app/services/session/session_service.dart';

class _FakeDenylistRepository implements CodingToolsDenylistRepository {
  @override
  Future<CodingToolsDenylistState> load() async => CodingToolsDenylistState.empty();

  @override
  Future<CodingToolsDenylistState> save(CodingToolsDenylistState state) async => state;

  @override
  Future<Set<String>> effective(DenylistCategory category) async => {};

  @override
  Future<void> restoreAllDefaults() async {}
}

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

class _ScriptedAI implements AIRepository {
  _ScriptedAI(this.rounds);
  final List<List<StreamEvent>> rounds;
  int _r = 0;

  @override
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<CodingToolDefinition> tools,
    required AIModel model,
  }) async* {
    for (final e in rounds[_r++]) {
      yield e;
    }
  }

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    yield 'plain-text-path';
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async => true;

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) async => [];
}

AgentService _buildAgent({required AIRepository ai}) {
  final tools = CodingToolsService(
    repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()),
    applyService: ApplyService(repo: ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()))),
    denylist: _FakeDenylistRepository(),
  );
  return AgentService(ai: ai, codingTools: tools, cancelFlag: () => false);
}

void main() {
  test('sendAndStream yields user then streamed assistant then final', () async {
    final fakeAI = _FakeAIRepo();
    final svc = SessionService(
      session: _FakeSessionRepo(),
      ai: fakeAI,
      agent: _buildAgent(ai: fakeAI),
    );
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

  test('sendAndStream routes to AgentService for ChatMode.act + AIProvider.custom', () async {
    final projectDir = await Directory.systemTemp.createTemp('ss_act_');
    addTearDown(() async {
      if (projectDir.existsSync()) await projectDir.delete(recursive: true);
    });

    final ai = _ScriptedAI([
      [const StreamEvent.textDelta('done'), const StreamEvent.finish(reason: 'stop')],
    ]);
    final agent = _buildAgent(ai: ai);
    final svc = SessionService(session: _FakeSessionRepo(), ai: ai, agent: agent);

    final messages = <ChatMessage>[];
    await for (final msg in svc.sendAndStream(
      sessionId: 's1',
      userInput: 'do the thing',
      model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
      mode: ChatMode.act,
      permission: ChatPermission.fullAccess,
      projectPath: projectDir.path,
    )) {
      messages.add(msg);
    }

    final assistant = messages.where((m) => m.role == MessageRole.assistant).last;
    expect(assistant.content, 'done');
    expect(assistant.isStreaming, isFalse);
  });
}
