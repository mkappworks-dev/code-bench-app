import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';
import 'package:code_bench_app/data/ai/repository/ai_repository.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_definition.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/data/session/models/session_settings.dart';
import 'package:code_bench_app/data/session/models/tool_event.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/coding_tools_service.dart';
import 'package:code_bench_app/services/agent/agent_service.dart';
import 'package:path/path.dart' as p;

class _FakeAIRepo implements AIRepository {
  _FakeAIRepo(this.scripts);
  final List<List<StreamEvent>> scripts;
  int _round = 0;

  @override
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<CodingToolDefinition> tools,
    required AIModel model,
  }) async* {
    final events = scripts[_round++];
    for (final e in events) {
      yield e;
    }
  }

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) => const Stream.empty();

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async => true;

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) async => [];
}

void main() {
  late Directory projectDir;
  late CodingToolsService toolsSvc;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('agent_svc_');
    File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('hello');
    final repo = CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
    final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
    final applySvc = ApplyService(repo: applyRepo);
    toolsSvc = CodingToolsService(repo: repo, applyService: applySvc);
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('happy path: text → tool_call(read_file) → text → stop', () async {
    final aiRepo = _FakeAIRepo([
      [
        const StreamEvent.textDelta('Reading…'),
        const StreamEvent.toolCallStart(id: 'c1', name: 'read_file'),
        const StreamEvent.toolCallArgsDelta(id: 'c1', argsJsonFragment: '{"path":"a.txt"}'),
        const StreamEvent.toolCallEnd(id: 'c1'),
        const StreamEvent.finish(reason: 'tool_calls'),
      ],
      [const StreamEvent.textDelta('It says hello.'), const StreamEvent.finish(reason: 'stop')],
    ]);

    final svc = AgentService(ai: aiRepo, codingTools: toolsSvc, cancelFlag: () => false);
    final messages = <ChatMessage>[];
    await for (final msg in svc.runAgenticTurn(
      sessionId: 's',
      history: const [],
      userInput: 'read a.txt',
      model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
      permission: ChatPermission.fullAccess,
      projectPath: projectDir.path,
    )) {
      messages.add(msg);
    }

    final finalMsg = messages.last;
    expect(finalMsg.role, MessageRole.assistant);
    expect(finalMsg.isStreaming, isFalse);
    expect(finalMsg.content, contains('It says hello.'));
    expect(finalMsg.toolEvents, hasLength(1));
    expect(finalMsg.toolEvents.first.toolName, 'read_file');
    expect(finalMsg.toolEvents.first.status, ToolStatus.success);
  });

  test('iteration cap: loop aborts after 10 tool_calls rounds with iterationCapReached=true', () async {
    final round = [
      const StreamEvent.toolCallStart(id: 'cX', name: 'read_file'),
      const StreamEvent.toolCallArgsDelta(id: 'cX', argsJsonFragment: '{"path":"a.txt"}'),
      const StreamEvent.toolCallEnd(id: 'cX'),
      const StreamEvent.finish(reason: 'tool_calls'),
    ];
    final aiRepo = _FakeAIRepo(List.generate(10, (_) => round));

    final svc = AgentService(ai: aiRepo, codingTools: toolsSvc, cancelFlag: () => false);
    final messages = <ChatMessage>[];
    await for (final msg in svc.runAgenticTurn(
      sessionId: 's',
      history: const [],
      userInput: 'loop',
      model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
      permission: ChatPermission.fullAccess,
      projectPath: projectDir.path,
    )) {
      messages.add(msg);
    }
    final finalMsg = messages.last;
    expect(finalMsg.iterationCapReached, isTrue);
    expect(finalMsg.isStreaming, isFalse);
  });

  test('cancel flag trips loop at next tool boundary', () async {
    var cancel = false;
    final aiRepo = _FakeAIRepo([
      [
        const StreamEvent.toolCallStart(id: 'c1', name: 'read_file'),
        const StreamEvent.toolCallArgsDelta(id: 'c1', argsJsonFragment: '{"path":"a.txt"}'),
        const StreamEvent.toolCallEnd(id: 'c1'),
        const StreamEvent.finish(reason: 'tool_calls'),
      ],
    ]);

    final svc = AgentService(ai: aiRepo, codingTools: toolsSvc, cancelFlag: () => cancel);
    cancel = true;
    final messages = <ChatMessage>[];
    await for (final msg in svc.runAgenticTurn(
      sessionId: 's',
      history: const [],
      userInput: 'x',
      model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
      permission: ChatPermission.fullAccess,
      projectPath: projectDir.path,
    )) {
      messages.add(msg);
    }
    final finalMsg = messages.last;
    expect(finalMsg.isStreaming, isFalse);
    expect(finalMsg.content, contains('Cancelled by user'));
  });

  test('readOnly mode filters write tools from the tools list', () async {
    List<CodingToolDefinition>? sentTools;
    final aiRepo = _CapturingFakeRepo([
      [const StreamEvent.finish(reason: 'stop')],
    ], onSend: (tools) => sentTools = tools);

    final svc = AgentService(ai: aiRepo, codingTools: toolsSvc, cancelFlag: () => false);
    await svc
        .runAgenticTurn(
          sessionId: 's',
          history: const [],
          userInput: 'x',
          model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
          permission: ChatPermission.readOnly,
          projectPath: projectDir.path,
        )
        .drain();

    expect(sentTools!.map((t) => t.name).toList(), ['read_file', 'list_dir']);
  });
}

class _CapturingFakeRepo extends _FakeAIRepo {
  _CapturingFakeRepo(super.scripts, {required this.onSend});
  final void Function(List<CodingToolDefinition>) onSend;

  @override
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<CodingToolDefinition> tools,
    required AIModel model,
  }) {
    onSend(tools);
    return super.streamMessageWithTools(wireMessages: wireMessages, tools: tools, model: model);
  }
}
