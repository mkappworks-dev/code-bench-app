import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';
import 'package:code_bench_app/data/ai/repository/ai_repository.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tools_denylist_state.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
import 'package:code_bench_app/data/coding_tools/models/tool.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/data/session/models/session_settings.dart';
import 'package:code_bench_app/data/session/models/tool_event.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/tool_registry.dart';
import 'package:code_bench_app/services/coding_tools/tools/list_dir_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/read_file_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/str_replace_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/write_file_tool.dart';
import 'package:code_bench_app/services/agent/agent_service.dart';
import 'package:path/path.dart' as p;

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

class _FakeAIRepo implements AIRepository {
  _FakeAIRepo(this.scripts);
  final List<List<StreamEvent>> scripts;
  int _round = 0;

  @override
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<Tool> tools,
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
  late ToolRegistry registry;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('agent_svc_');
    File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('hello');
    final repo = CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
    final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
    final applySvc = ApplyService(repo: applyRepo);
    registry = ToolRegistry(
      builtIns: [
        ReadFileTool(repo: repo),
        ListDirTool(repo: repo),
        WriteFileTool(applyService: applySvc),
        StrReplaceTool(repo: repo, applyService: applySvc),
      ],
      denylistRepo: _FakeDenylistRepository(),
    );
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

    final svc = AgentService(ai: aiRepo, registry: registry);
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

    final svc = AgentService(ai: aiRepo, registry: registry);
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

    final svc = AgentService(ai: aiRepo, registry: registry);
    cancel = true;
    final messages = <ChatMessage>[];
    await for (final msg in svc.runAgenticTurn(
      sessionId: 's',
      history: const [],
      userInput: 'x',
      model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
      permission: ChatPermission.fullAccess,
      projectPath: projectDir.path,
      cancelFlag: () => cancel,
    )) {
      messages.add(msg);
    }
    final finalMsg = messages.last;
    expect(finalMsg.isStreaming, isFalse);
    expect(finalMsg.content, contains('Cancelled by user'));
  });

  test('historical replay: prior agentic turn emits tool result exactly once', () async {
    const prevCallId = 'prev_c1';
    List<Map<String, dynamic>>? capturedWire;
    final aiRepo = _WireCapturingFakeRepo([
      [const StreamEvent.finish(reason: 'stop')],
    ], onWire: (w) => capturedWire = w);

    // Persisted assistant messages carry their terminal-status toolEvents.
    // The wire builder synthesises `role: 'tool'` entries from them — there
    // is no separate system+tool_result message in DB.
    final priorHistory = [
      ChatMessage(
        id: 'u_prev',
        sessionId: 's',
        role: MessageRole.user,
        content: 'read the file',
        timestamp: DateTime(2026),
      ),
      ChatMessage(
        id: 'a_prev',
        sessionId: 's',
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime(2026),
        toolEvents: [
          const ToolEvent(
            id: prevCallId,
            type: 'tool_use',
            toolName: 'read_file',
            input: {'path': 'a.txt'},
            status: ToolStatus.success,
            output: 'hello',
          ),
        ],
      ),
      ChatMessage(
        id: 'a_final',
        sessionId: 's',
        role: MessageRole.assistant,
        content: 'Done.',
        timestamp: DateTime(2026),
      ),
    ];

    final svc = AgentService(ai: aiRepo, registry: registry);
    await svc
        .runAgenticTurn(
          sessionId: 's',
          history: priorHistory,
          userInput: 'next question',
          model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
          permission: ChatPermission.fullAccess,
          projectPath: projectDir.path,
        )
        .drain();

    final wire = capturedWire!;
    final toolEntries = wire.where((m) => m['role'] == 'tool').toList();
    expect(toolEntries, hasLength(1), reason: 'tool result must appear exactly once, not duplicated');
    expect(toolEntries.first['tool_call_id'], prevCallId);
  });

  test('readOnly mode filters write tools from the tools list', () async {
    List<Tool>? sentTools;
    final aiRepo = _CapturingFakeRepo([
      [const StreamEvent.finish(reason: 'stop')],
    ], onSend: (tools) => sentTools = tools);

    final svc = AgentService(ai: aiRepo, registry: registry);
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

  test('askBefore + deny: tool result reports user denial and next round sees it', () async {
    final aiRepo = _FakeAIRepo([
      [
        const StreamEvent.toolCallStart(id: 'c1', name: 'write_file'),
        const StreamEvent.toolCallArgsDelta(id: 'c1', argsJsonFragment: '{"path":"new.txt","content":"hi"}'),
        const StreamEvent.toolCallEnd(id: 'c1'),
        const StreamEvent.finish(reason: 'tool_calls'),
      ],
      [const StreamEvent.textDelta('Understood — aborted.'), const StreamEvent.finish(reason: 'stop')],
    ]);

    Future<bool> deny(_) async => false;
    final svc = AgentService(ai: aiRepo, registry: registry);
    final messages = <ChatMessage>[];
    await for (final msg in svc.runAgenticTurn(
      sessionId: 's',
      history: const [],
      userInput: 'write new.txt',
      model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
      permission: ChatPermission.askBefore,
      projectPath: projectDir.path,
      requestPermission: deny,
    )) {
      messages.add(msg);
    }

    final finalMsg = messages.last;
    expect(finalMsg.toolEvents.first.status, ToolStatus.cancelled);
    expect(finalMsg.toolEvents.first.error, contains('Denied'));
  });

  test('wire: oversized tool output is capped and contains truncation notice', () async {
    List<Map<String, dynamic>>? capturedWire;
    final aiRepo = _WireCapturingFakeRepo([
      [const StreamEvent.finish(reason: 'stop')],
    ], onWire: (w) => capturedWire = w);

    final oversizedOutput = 'x' * (AgentService.kToolOutputCapBytes + 1);
    final priorHistory = [
      ChatMessage(id: 'u1', sessionId: 's', role: MessageRole.user, content: 'do it', timestamp: DateTime(2026)),
      ChatMessage(
        id: 'a1',
        sessionId: 's',
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime(2026),
        toolEvents: [
          ToolEvent(
            id: 'te1',
            type: 'tool_use',
            toolName: 'read_file',
            input: const {'path': 'a.txt'},
            status: ToolStatus.success,
            output: oversizedOutput,
          ),
        ],
      ),
    ];

    final svc = AgentService(ai: aiRepo, registry: registry);
    await svc
        .runAgenticTurn(
          sessionId: 's',
          history: priorHistory,
          userInput: 'continue',
          model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
          permission: ChatPermission.fullAccess,
          projectPath: projectDir.path,
        )
        .drain();

    final wire = capturedWire!;
    final toolEntries = wire.where((m) => m['role'] == 'tool').toList();
    expect(toolEntries, hasLength(1));
    expect(toolEntries.first['content'] as String, contains('[Output truncated at 50 KB.'));
  });
}

class _WireCapturingFakeRepo extends _FakeAIRepo {
  _WireCapturingFakeRepo(super.scripts, {required this.onWire});
  final void Function(List<Map<String, dynamic>>) onWire;

  @override
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<Tool> tools,
    required AIModel model,
  }) {
    onWire(wireMessages);
    return super.streamMessageWithTools(wireMessages: wireMessages, tools: tools, model: model);
  }
}

class _CapturingFakeRepo extends _FakeAIRepo {
  _CapturingFakeRepo(super.scripts, {required this.onSend});
  final void Function(List<Tool>) onSend;

  @override
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<Tool> tools,
    required AIModel model,
  }) {
    onSend(tools);
    return super.streamMessageWithTools(wireMessages: wireMessages, tools: tools, model: model);
  }
}
