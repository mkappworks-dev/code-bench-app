# Agentic Executor MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `ChatMode.act` into a working agentic loop that calls `read_file` / `list_dir` / `write_file` / `str_replace` against the active project's filesystem over an OpenAI-compatible endpoint, capped at 10 iterations per user turn with inline permission gating and visible cancel/cap states.

**Architecture:** New `AgentService` orchestrates the loop; a new `CodingToolsService` dispatches tool calls to `CodingToolsRepository` (filesystem I/O). Writes delegate to the existing `ApplyService.applyChange` so changes appear in the revert panel. A new `CustomRemoteDatasourceDio.streamMessageWithTools` returns a `Stream<StreamEvent>` (a new freezed sealed class) that the loop consumes. `SessionService.sendAndStream` branches on `ChatMode.act` + `AIProvider.custom`. Permission gating uses an inline `PermissionRequestCard` backed by a `Completer<bool>` in `AgentPermissionRequestNotifier`. Iteration cap uses an additive `iterationCapReached` bool on `ChatMessage` and an inline `IterationCapBanner` with a `[Continue]` button.

**Tech Stack:** Flutter / Dart, Riverpod (`@Riverpod(keepAlive: true)` for services & keepers), Freezed for data classes, `dio` for SSE, `dart:io` for filesystem, `Drift` for persistence (existing JSON-column `ChatMessage` tolerates new fields), `uuid` for id generation.

**Reference:** Implements [docs/superpowers/specs/2026-04-20-agentic-executor-mvp-design.md](../specs/2026-04-20-agentic-executor-mvp-design.md).

---

## Worktree setup (required before starting)

```bash
git worktree add .worktrees/feat/2026-04-20-agentic-executor-mvp -b feat/2026-04-20-agentic-executor-mvp
cd .worktrees/feat/2026-04-20-agentic-executor-mvp
flutter pub get
flutter test
```

Expected: clean test baseline before any changes. All work happens inside this worktree.

---

## Phase overview

| Phase | Deliverable | Commits |
|---|---|---|
| 1 | `StreamEvent` model + SSE parser on `CustomRemoteDatasourceDio.streamMessageWithTools` + `AIRepository.streamMessageWithTools` | 3 |
| 2 | `coding_tools` domain — models, exceptions, datasource, repository, service with 4 tool handlers | 5 |
| 3 | `ChatMessage` field additions, `AgentFailure`, `AgentCancelNotifier`, `AgentService` loop skeleton, `SessionService` branch | 4 |
| 4 | UI polish — `ToolCallRow` cancelled-state styling, `IterationCapBanner` widget, `ChatMessagesNotifier.clearIterationCap` / `continueAgenticTurn` | 4 |
| 5 | Permission gating — `AgentPermissionRequestNotifier`, `PermissionRequestCard` widget, integration with `AgentService` | 4 |
| 6 | Smoke test on local LMStudio + finishing | 1 |

Each phase produces a working build — `flutter analyze` + `flutter test` must pass at the end of every phase before moving to the next.

---

# Phase 1 — Wire format & SSE parser

## Task 1.1: Define `StreamEvent` sealed class

**Files:**
- Create: `lib/data/ai/models/stream_event.dart`
- Test: `test/data/ai/models/stream_event_test.dart`

- [ ] **Step 1: Write a failing test that constructs each variant and pattern-matches on them**

Create `test/data/ai/models/stream_event_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';

void main() {
  test('StreamEvent variants pattern-match exhaustively', () {
    final events = <StreamEvent>[
      const StreamEvent.textDelta('hi'),
      const StreamEvent.toolCallStart(id: 'a', name: 'read_file'),
      const StreamEvent.toolCallArgsDelta(id: 'a', argsJsonFragment: '{"p":'),
      const StreamEvent.toolCallEnd(id: 'a'),
      const StreamEvent.finish(reason: 'stop'),
    ];

    final names = events.map((e) => switch (e) {
      StreamTextDelta() => 'text',
      StreamToolCallStart() => 'start',
      StreamToolCallArgsDelta() => 'args',
      StreamToolCallEnd() => 'end',
      StreamFinish() => 'finish',
    }).toList();

    expect(names, ['text', 'start', 'args', 'end', 'finish']);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/data/ai/models/stream_event_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:code_bench_app/data/ai/models/stream_event.dart'`.

- [ ] **Step 3: Write the freezed sealed class**

Create `lib/data/ai/models/stream_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_event.freezed.dart';

/// Provider-agnostic stream event emitted by [AIRepository.streamMessageWithTools].
///
/// The OpenAI wire format interleaves content deltas and tool-call deltas.
/// This sealed class surfaces those as discrete events so the [AgentService]
/// loop can append tool events as they appear without re-parsing SSE.
@freezed
sealed class StreamEvent with _$StreamEvent {
  const factory StreamEvent.textDelta(String text) = StreamTextDelta;
  const factory StreamEvent.toolCallStart({
    required String id,
    required String name,
  }) = StreamToolCallStart;
  const factory StreamEvent.toolCallArgsDelta({
    required String id,
    required String argsJsonFragment,
  }) = StreamToolCallArgsDelta;
  const factory StreamEvent.toolCallEnd({required String id}) = StreamToolCallEnd;

  /// OpenAI `finish_reason` — typically "stop", "tool_calls", or "length".
  const factory StreamEvent.finish({required String reason}) = StreamFinish;
}
```

- [ ] **Step 4: Run `build_runner` to generate the freezed file**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `stream_event.freezed.dart` is created.

- [ ] **Step 5: Run the test to verify it passes**

```bash
flutter test test/data/ai/models/stream_event_test.dart
```

Expected: PASS.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib/data/ai/models/ test/data/ai/models/
flutter analyze
git add lib/data/ai/models/stream_event.dart lib/data/ai/models/stream_event.freezed.dart test/data/ai/models/stream_event_test.dart
git commit -m "feat(ai): add StreamEvent sealed class for tool-capable streaming"
```

Expected: analyze clean; commit succeeds.

---

## Task 1.2: Define `CodingToolDefinition` (pure data; no behavior yet)

**Files:**
- Create: `lib/data/coding_tools/models/coding_tool_definition.dart`
- Test: `test/data/coding_tools/models/coding_tool_definition_test.dart`

Rationale for placing this before the SSE parser: `streamMessageWithTools` accepts `List<CodingToolDefinition>` and serializes it into the request body. Defining the type first keeps the datasource signature correct on the first write.

- [ ] **Step 1: Write a failing test that asserts the four tool definitions expose expected names and required fields**

Create `test/data/coding_tools/models/coding_tool_definition_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_definition.dart';

void main() {
  group('CodingTools.catalog', () {
    test('exposes the four MVP tools with the expected names', () {
      final names = CodingTools.all.map((t) => t.name).toList();
      expect(names, ['read_file', 'list_dir', 'write_file', 'str_replace']);
    });

    test('read-only subset excludes write_file and str_replace', () {
      final names = CodingTools.readOnly.map((t) => t.name).toList();
      expect(names, ['read_file', 'list_dir']);
    });

    test('toOpenAiToolJson wraps schema in {type: function, function: {...}}', () {
      final json = CodingTools.readFile.toOpenAiToolJson();
      expect(json['type'], 'function');
      expect(json['function']['name'], 'read_file');
      expect((json['function']['parameters'] as Map)['required'], ['path']);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/data/coding_tools/models/coding_tool_definition_test.dart
```

Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the model + catalog**

Create `lib/data/coding_tools/models/coding_tool_definition.dart`:

```dart
/// A single tool that the model may call. Pure data — no runtime behavior.
/// The matching handler lives on [CodingToolsService].
class CodingToolDefinition {
  const CodingToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  /// Serializes to the OpenAI chat-completions `tools[]` shape:
  /// `{"type": "function", "function": {name, description, parameters}}`.
  Map<String, dynamic> toOpenAiToolJson() => {
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': inputSchema,
    },
  };
}

/// Catalog of tools shipped in the MVP. Order matters — it's preserved in
/// the request body and in UI lists.
class CodingTools {
  static const readFile = CodingToolDefinition(
    name: 'read_file',
    description: 'Read the contents of a text file inside the active project.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {
          'type': 'string',
          'description': 'Project-relative or absolute path to a file inside the project.',
        },
      },
      'required': ['path'],
    },
  );

  static const listDir = CodingToolDefinition(
    name: 'list_dir',
    description: 'List entries in a directory inside the active project.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'recursive': {'type': 'boolean', 'default': false},
      },
      'required': ['path'],
    },
  );

  static const writeFile = CodingToolDefinition(
    name: 'write_file',
    description:
        'Create or overwrite a file inside the active project. Prefer str_replace for targeted edits to existing files.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'content': {'type': 'string'},
      },
      'required': ['path', 'content'],
    },
  );

  static const strReplace = CodingToolDefinition(
    name: 'str_replace',
    description:
        'Replace the first exact occurrence of old_str with new_str in a file. The match must be unique — if zero or multiple matches exist, this tool returns an error and the file is unchanged.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'old_str': {'type': 'string'},
        'new_str': {'type': 'string'},
      },
      'required': ['path', 'old_str', 'new_str'],
    },
  );

  static const all = <CodingToolDefinition>[readFile, listDir, writeFile, strReplace];
  static const readOnly = <CodingToolDefinition>[readFile, listDir];
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/data/coding_tools/models/coding_tool_definition_test.dart
```

Expected: PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/data/coding_tools/ test/data/coding_tools/
flutter analyze
git add lib/data/coding_tools/models/coding_tool_definition.dart test/data/coding_tools/models/coding_tool_definition_test.dart
git commit -m "feat(coding_tools): add CodingToolDefinition catalog (read/list/write/str_replace)"
```

Expected: analyze clean; commit succeeds.

---

## Task 1.3: Add `streamMessageWithTools` SSE parser on `CustomRemoteDatasourceDio`

**Files:**
- Modify: `lib/data/ai/datasource/custom_remote_datasource_dio.dart`
- Modify: `lib/data/ai/repository/ai_repository.dart`
- Modify: `lib/data/ai/repository/ai_repository_impl.dart`
- Create: `test/data/ai/datasource/custom_remote_datasource_dio_tools_test.dart`

- [ ] **Step 1: Write a failing test that drives the SSE parser via a scripted input**

Create `test/data/ai/datasource/custom_remote_datasource_dio_tools_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/datasource/custom_remote_datasource_dio.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';

void main() {
  group('parseOpenAiToolSseLine', () {
    test('text delta → StreamTextDelta', () {
      final event = parseOpenAiToolSseLine(
        'data: {"choices":[{"delta":{"content":"hello"}}]}',
        const {},
      );
      expect(event, isA<StreamTextDelta>());
      expect((event as StreamTextDelta).text, 'hello');
    });

    test('tool_call_start assigns id and name', () {
      final idByIndex = <int, String>{};
      final event = parseOpenAiToolSseLine(
        'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_abc","type":"function","function":{"name":"read_file","arguments":""}}]}}]}',
        idByIndex,
      );
      expect(event, isA<StreamToolCallStart>());
      expect((event as StreamToolCallStart).id, 'call_abc');
      expect(event.name, 'read_file');
      expect(idByIndex[0], 'call_abc');
    });

    test('args delta without id reuses id-by-index map', () {
      final idByIndex = {0: 'call_abc'};
      final event = parseOpenAiToolSseLine(
        'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\\"path\\":"}}]}}]}',
        idByIndex,
      );
      expect(event, isA<StreamToolCallArgsDelta>());
      expect((event as StreamToolCallArgsDelta).id, 'call_abc');
      expect(event.argsJsonFragment, '{"path":');
    });

    test('finish_reason stop → StreamFinish("stop")', () {
      final event = parseOpenAiToolSseLine(
        'data: {"choices":[{"finish_reason":"stop"}]}',
        const {},
      );
      expect(event, isA<StreamFinish>());
      expect((event as StreamFinish).reason, 'stop');
    });

    test('finish_reason tool_calls → StreamFinish("tool_calls")', () {
      final event = parseOpenAiToolSseLine(
        'data: {"choices":[{"finish_reason":"tool_calls"}]}',
        const {},
      );
      expect((event as StreamFinish).reason, 'tool_calls');
    });

    test('[DONE] line returns null', () {
      expect(parseOpenAiToolSseLine('data: [DONE]', const {}), isNull);
    });

    test('malformed JSON returns null (no throw)', () {
      expect(parseOpenAiToolSseLine('data: {bad', const {}), isNull);
    });

    test('non-data line returns null', () {
      expect(parseOpenAiToolSseLine(': keep-alive', const {}), isNull);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/data/ai/datasource/custom_remote_datasource_dio_tools_test.dart
```

Expected: FAIL — `parseOpenAiToolSseLine` undefined.

- [ ] **Step 3: Add the SSE line parser as a top-level function (exported from the datasource file)**

Edit `lib/data/ai/datasource/custom_remote_datasource_dio.dart`. Add these imports (preserve existing imports; append the new ones):

```dart
import '../../../data/ai/models/stream_event.dart';
import '../../../data/coding_tools/models/coding_tool_definition.dart';
```

Then append this top-level function at the end of the file (after the class closing brace):

```dart
/// Parses a single SSE line from OpenAI chat-completions (tools enabled).
///
/// [idByIndex] carries tool-call `index → id` mapping across deltas. The
/// first delta for each tool call carries `id`; subsequent args deltas carry
/// only `index`. Callers own this map for the lifetime of one stream.
///
/// Returns `null` for lines that don't produce events (keep-alives, `[DONE]`,
/// malformed JSON, tool-call deltas with no meaningful content).
StreamEvent? parseOpenAiToolSseLine(String line, Map<int, String> idByIndex) {
  final trimmed = line.trim();
  if (!trimmed.startsWith('data: ')) return null;
  final data = trimmed.substring(6);
  if (data == '[DONE]') return null;

  Map<String, dynamic> json;
  try {
    json = jsonDecode(data) as Map<String, dynamic>;
  } on FormatException {
    return null;
  }

  final choices = json['choices'];
  if (choices is! List || choices.isEmpty) return null;
  final choice = choices[0];
  if (choice is! Map) return null;

  final finishReason = choice['finish_reason'];
  if (finishReason is String) {
    return StreamEvent.finish(reason: finishReason);
  }

  final delta = choice['delta'];
  if (delta is! Map) return null;

  final content = delta['content'];
  if (content is String && content.isNotEmpty) {
    return StreamEvent.textDelta(content);
  }

  final toolCalls = delta['tool_calls'];
  if (toolCalls is List && toolCalls.isNotEmpty) {
    final tc = toolCalls[0];
    if (tc is! Map) return null;
    final index = tc['index'];
    if (index is! int) return null;

    final id = tc['id'];
    final fnBlock = tc['function'];
    if (id is String && id.isNotEmpty) {
      idByIndex[index] = id;
      final name = (fnBlock is Map) ? fnBlock['name'] : null;
      if (name is String && name.isNotEmpty) {
        return StreamEvent.toolCallStart(id: id, name: name);
      }
    }

    if (fnBlock is Map) {
      final args = fnBlock['arguments'];
      if (args is String && args.isNotEmpty) {
        final resolvedId = idByIndex[index];
        if (resolvedId != null) {
          return StreamEvent.toolCallArgsDelta(id: resolvedId, argsJsonFragment: args);
        }
      }
    }
  }

  return null;
}
```

- [ ] **Step 4: Run the parser tests to verify they pass**

```bash
flutter test test/data/ai/datasource/custom_remote_datasource_dio_tools_test.dart
```

Expected: PASS — all eight tests green.

- [ ] **Step 5: Add `streamMessageWithTools` method on the datasource**

Inside the `CustomRemoteDatasourceDio` class in `lib/data/ai/datasource/custom_remote_datasource_dio.dart`, append a new method after the existing `streamMessage`:

```dart
/// OpenAI function-calling stream. Emits [StreamEvent]s as SSE chunks arrive.
///
/// [messages] must already be in OpenAI wire shape (list of maps with `role`,
/// `content`, optionally `tool_calls` / `tool_call_id`). The [AgentService]
/// history translator is responsible for that layout — this datasource does
/// not re-translate.
Stream<StreamEvent> streamMessageWithTools({
  required List<Map<String, dynamic>> messages,
  required List<CodingToolDefinition> tools,
  required AIModel model,
}) async* {
  final body = {
    'model': model.modelId,
    'stream': true,
    'messages': messages,
    'tools': tools.map((t) => t.toOpenAiToolJson()).toList(),
    'tool_choice': 'auto',
  };

  try {
    final response = await _dio.post(
      '/chat/completions',
      data: body,
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data as ResponseBody;
    final buffer = StringBuffer();
    final idByIndex = <int, String>{};
    final inFlightIds = <String>{};

    await for (final chunk in stream.stream) {
      buffer.write(utf8.decode(chunk));
      final raw = buffer.toString();
      buffer.clear();

      for (final line in raw.split('\n')) {
        if (line.trim().isEmpty) continue;
        final event = parseOpenAiToolSseLine(line, idByIndex);
        if (event == null) continue;

        switch (event) {
          case StreamToolCallStart(:final id):
            inFlightIds.add(id);
            yield event;
          case StreamToolCallArgsDelta():
            yield event;
          case StreamFinish(reason: 'tool_calls'):
            for (final id in inFlightIds) {
              yield StreamEvent.toolCallEnd(id: id);
            }
            inFlightIds.clear();
            yield event;
            return;
          case StreamFinish():
            yield event;
            return;
          case StreamTextDelta():
            yield event;
          case StreamToolCallEnd():
            // Parser never emits this directly; end is synthesized above.
            yield event;
        }
      }
    }
  } on DioException catch (e) {
    throw NetworkException('Custom endpoint tool stream failed', statusCode: e.response?.statusCode, originalError: e);
  }
}
```

- [ ] **Step 6: Extend `AIRepository` interface and impl**

Edit `lib/data/ai/repository/ai_repository.dart` — add the new abstract method just after `streamMessage`:

```dart
import '../models/stream_event.dart';
import '../../coding_tools/models/coding_tool_definition.dart';
```

Then inside the `AIRepository` abstract interface add:

```dart
/// Function-calling stream. MVP only supports [AIProvider.custom]. For all
/// other providers this throws [UnsupportedError] (caller gates on provider).
Stream<StreamEvent> streamMessageWithTools({
  required List<Map<String, dynamic>> wireMessages,
  required List<CodingToolDefinition> tools,
  required AIModel model,
});
```

Edit `lib/data/ai/repository/ai_repository_impl.dart` — add the matching imports:

```dart
import '../models/stream_event.dart';
import '../../coding_tools/models/coding_tool_definition.dart';
```

And inside `AIRepositoryImpl` class, add:

```dart
@override
Stream<StreamEvent> streamMessageWithTools({
  required List<Map<String, dynamic>> wireMessages,
  required List<CodingToolDefinition> tools,
  required AIModel model,
}) {
  final src = _source(model.provider);
  if (src is! CustomRemoteDatasourceDio) {
    throw UnsupportedError('streamMessageWithTools is only supported on AIProvider.custom in the MVP');
  }
  return src.streamMessageWithTools(messages: wireMessages, tools: tools, model: model);
}
```

- [ ] **Step 7: Run analyze + full test suite**

```bash
flutter analyze
flutter test
```

Expected: analyze clean; all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/data/ai/datasource/custom_remote_datasource_dio.dart lib/data/ai/repository/ai_repository.dart lib/data/ai/repository/ai_repository_impl.dart test/data/ai/datasource/custom_remote_datasource_dio_tools_test.dart
git commit -m "feat(ai): add streamMessageWithTools SSE parser for OpenAI-compatible endpoints"
```

---

# Phase 2 — `coding_tools` domain

## Task 2.1: Exceptions + tool result model

**Files:**
- Create: `lib/data/coding_tools/coding_tools_exceptions.dart`
- Create: `lib/data/coding_tools/models/coding_tool_result.dart`
- Test: `test/data/coding_tools/models/coding_tool_result_test.dart`

- [ ] **Step 1: Write a failing test for `CodingToolResult`**

Create `test/data/coding_tools/models/coding_tool_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';

void main() {
  test('success result carries output and no error', () {
    const r = CodingToolResult.success('hello');
    expect(r.isSuccess, isTrue);
    expect(r.output, 'hello');
    expect(r.error, isNull);
  });

  test('error result carries message and no output', () {
    const r = CodingToolResult.error('bad thing');
    expect(r.isSuccess, isFalse);
    expect(r.error, 'bad thing');
    expect(r.output, isNull);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/data/coding_tools/models/coding_tool_result_test.dart
```

Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the exceptions file**

Create `lib/data/coding_tools/coding_tools_exceptions.dart`:

```dart
/// Raised when `read_file` is asked for a file larger than [maxBytes].
class CodingToolFileTooLargeException implements Exception {
  const CodingToolFileTooLargeException(this.actualBytes, this.maxBytes);
  final int actualBytes;
  final int maxBytes;

  @override
  String toString() => 'CodingToolFileTooLargeException($actualBytes > $maxBytes)';
}

/// Raised when `read_file` cannot decode a file as UTF-8.
class CodingToolNotTextEncodedException implements Exception {
  const CodingToolNotTextEncodedException(this.path);
  final String path;

  @override
  String toString() => 'CodingToolNotTextEncodedException($path)';
}

/// Raised when `str_replace`'s `old_str` does not occur exactly once.
class CodingToolAmbiguousMatchException implements Exception {
  const CodingToolAmbiguousMatchException(this.matchCount);
  final int matchCount;

  @override
  String toString() => 'CodingToolAmbiguousMatchException($matchCount)';
}
```

- [ ] **Step 4: Write the result model**

Create `lib/data/coding_tools/models/coding_tool_result.dart`:

```dart
/// Normalized result of executing one tool call. Converted to a `tool_result`
/// message in the OpenAI wire history by [AgentService] before the next round.
class CodingToolResult {
  const CodingToolResult._({this.output, this.error}) : assert((output == null) != (error == null));

  const factory CodingToolResult.success(String output) = _CodingToolResultSuccess;
  const factory CodingToolResult.error(String message) = _CodingToolResultError;

  final String? output;
  final String? error;

  bool get isSuccess => output != null;
}

class _CodingToolResultSuccess extends CodingToolResult {
  const _CodingToolResultSuccess(String output) : super._(output: output);
}

class _CodingToolResultError extends CodingToolResult {
  const _CodingToolResultError(String message) : super._(error: message);
}
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
flutter test test/data/coding_tools/models/coding_tool_result_test.dart
```

Expected: PASS.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib/data/coding_tools/ test/data/coding_tools/
flutter analyze
git add lib/data/coding_tools/coding_tools_exceptions.dart lib/data/coding_tools/models/coding_tool_result.dart test/data/coding_tools/models/coding_tool_result_test.dart
git commit -m "feat(coding_tools): add exceptions and CodingToolResult model"
```

---

## Task 2.2: `CodingToolCall` model

**Files:**
- Create: `lib/data/coding_tools/models/coding_tool_call.dart`
- Test: `test/data/coding_tools/models/coding_tool_call_test.dart`

- [ ] **Step 1: Write a failing test**

Create `test/data/coding_tools/models/coding_tool_call_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_call.dart';

void main() {
  test('CodingToolCall holds id, name, and parsed args', () {
    const call = CodingToolCall(
      id: 'call_abc',
      name: 'read_file',
      args: {'path': 'lib/main.dart'},
    );
    expect(call.id, 'call_abc');
    expect(call.name, 'read_file');
    expect(call.args['path'], 'lib/main.dart');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/data/coding_tools/models/coding_tool_call_test.dart
```

Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the model**

Create `lib/data/coding_tools/models/coding_tool_call.dart`:

```dart
/// A single tool invocation emitted by the model. Constructed by
/// [AgentService] after assembling [StreamEvent]s into a complete call.
class CodingToolCall {
  const CodingToolCall({required this.id, required this.name, required this.args});

  final String id;
  final String name;
  final Map<String, dynamic> args;
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/data/coding_tools/models/coding_tool_call_test.dart
dart format lib/data/coding_tools/models/coding_tool_call.dart test/data/coding_tools/models/coding_tool_call_test.dart
flutter analyze
git add lib/data/coding_tools/models/coding_tool_call.dart test/data/coding_tools/models/coding_tool_call_test.dart
git commit -m "feat(coding_tools): add CodingToolCall model"
```

---

## Task 2.3: `CodingToolsDatasourceIo` (raw filesystem I/O)

**Files:**
- Create: `lib/data/coding_tools/datasource/coding_tools_datasource_io.dart`
- Test: `test/data/coding_tools/datasource/coding_tools_datasource_io_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/data/coding_tools/datasource/coding_tools_datasource_io_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late CodingToolsDatasourceIo ds;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ct_ds_');
    ds = CodingToolsDatasourceIo();
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  test('readFileBytes returns the file bytes', () async {
    final f = File(p.join(tmp.path, 'a.txt'))..writeAsStringSync('hello');
    final bytes = await ds.readFileBytes(f.path);
    expect(bytes.length, 5);
  });

  test('fileSizeBytes returns size without reading contents', () async {
    final f = File(p.join(tmp.path, 'a.txt'))..writeAsStringSync('hello');
    expect(await ds.fileSizeBytes(f.path), 5);
  });

  test('listDirectoryEntries returns children for non-recursive', () async {
    File(p.join(tmp.path, 'a.txt')).writeAsStringSync('x');
    Directory(p.join(tmp.path, 'sub')).createSync();
    final entries = await ds.listDirectoryEntries(tmp.path, recursive: false);
    final names = entries.map((e) => p.basename(e.path)).toSet();
    expect(names, {'a.txt', 'sub'});
  });

  test('listDirectoryEntries recursive walks subdirs (depth-capped inside service, not here)', () async {
    Directory(p.join(tmp.path, 'sub')).createSync();
    File(p.join(tmp.path, 'sub', 'b.txt')).writeAsStringSync('y');
    final entries = await ds.listDirectoryEntries(tmp.path, recursive: true);
    final names = entries.map((e) => p.basename(e.path)).toSet();
    expect(names.contains('sub'), isTrue);
    expect(names.contains('b.txt'), isTrue);
  });

  test('fileSizeBytes on missing path throws PathNotFoundException', () async {
    expect(
      () => ds.fileSizeBytes(p.join(tmp.path, 'missing.txt')),
      throwsA(isA<PathNotFoundException>()),
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/data/coding_tools/datasource/coding_tools_datasource_io_test.dart
```

Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the datasource**

Create `lib/data/coding_tools/datasource/coding_tools_datasource_io.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

/// Raw filesystem I/O for the coding tools. No path guards — callers
/// (`CodingToolsRepository` + `ApplyService.assertWithinProject`) own that.
class CodingToolsDatasourceIo {
  Future<Uint8List> readFileBytes(String path) => File(path).readAsBytes();
  Future<int> fileSizeBytes(String path) => File(path).length();
  Future<bool> fileExists(String path) => File(path).exists();
  Future<bool> directoryExists(String path) => Directory(path).exists();

  /// Lists directory entries. When [recursive] is true, walks all subdirs
  /// without depth limit — the caller (service) is responsible for capping.
  Future<List<FileSystemEntity>> listDirectoryEntries(String path, {required bool recursive}) {
    return Directory(path).list(recursive: recursive, followLinks: false).toList();
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/data/coding_tools/datasource/coding_tools_datasource_io_test.dart
```

Expected: PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/data/coding_tools/datasource/ test/data/coding_tools/datasource/
flutter analyze
git add lib/data/coding_tools/datasource/coding_tools_datasource_io.dart test/data/coding_tools/datasource/coding_tools_datasource_io_test.dart
git commit -m "feat(coding_tools): add CodingToolsDatasourceIo for raw filesystem I/O"
```

---

## Task 2.4: `CodingToolsRepository` interface + impl

**Files:**
- Create: `lib/data/coding_tools/repository/coding_tools_repository.dart`
- Create: `lib/data/coding_tools/repository/coding_tools_repository_impl.dart`
- Test: `test/data/coding_tools/repository/coding_tools_repository_impl_test.dart`

- [ ] **Step 1: Write a failing test for the impl**

Create `test/data/coding_tools/repository/coding_tools_repository_impl_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late CodingToolsRepositoryImpl repo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ct_repo_');
    repo = CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  test('readTextFile returns decoded UTF-8 content', () async {
    File(p.join(tmp.path, 'a.txt')).writeAsStringSync('héllo');
    expect(await repo.readTextFile(p.join(tmp.path, 'a.txt')), 'héllo');
  });

  test('readTextFile throws on invalid UTF-8 bytes', () async {
    File(p.join(tmp.path, 'bad.bin')).writeAsBytesSync([0xC3, 0x28]);
    expect(() => repo.readTextFile(p.join(tmp.path, 'bad.bin')), throwsA(isA<FormatException>()));
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/data/coding_tools/repository/coding_tools_repository_impl_test.dart
```

Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the repository interface**

Create `lib/data/coding_tools/repository/coding_tools_repository.dart`:

```dart
import 'dart:io';

/// Domain API for coding-tool filesystem reads/listings. Writes go through
/// [ApplyService.applyChange] instead (see `write_file` / `str_replace`
/// handlers in CodingToolsService).
abstract interface class CodingToolsRepository {
  Future<String> readTextFile(String path);
  Future<int> fileSizeBytes(String path);
  Future<bool> fileExists(String path);
  Future<bool> directoryExists(String path);
  Future<List<FileSystemEntity>> listDirectory(String path, {required bool recursive});
}
```

- [ ] **Step 4: Write the repository impl**

Create `lib/data/coding_tools/repository/coding_tools_repository_impl.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/coding_tools_datasource_io.dart';
import 'coding_tools_repository.dart';

part 'coding_tools_repository_impl.g.dart';

@Riverpod(keepAlive: true)
CodingToolsRepository codingToolsRepository(Ref ref) =>
    CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());

class CodingToolsRepositoryImpl implements CodingToolsRepository {
  CodingToolsRepositoryImpl({required CodingToolsDatasourceIo datasource}) : _ds = datasource;

  final CodingToolsDatasourceIo _ds;

  @override
  Future<String> readTextFile(String path) async {
    final bytes = await _ds.readFileBytes(path);
    return utf8.decode(bytes);
  }

  @override
  Future<int> fileSizeBytes(String path) => _ds.fileSizeBytes(path);

  @override
  Future<bool> fileExists(String path) => _ds.fileExists(path);

  @override
  Future<bool> directoryExists(String path) => _ds.directoryExists(path);

  @override
  Future<List<FileSystemEntity>> listDirectory(String path, {required bool recursive}) =>
      _ds.listDirectoryEntries(path, recursive: recursive);
}
```

- [ ] **Step 5: Generate + run tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/coding_tools/repository/coding_tools_repository_impl_test.dart
```

Expected: PASS.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib/data/coding_tools/repository/ test/data/coding_tools/repository/
flutter analyze
git add lib/data/coding_tools/repository/
git add test/data/coding_tools/repository/
git commit -m "feat(coding_tools): add CodingToolsRepository + Impl with UTF-8 decode"
```

---

## Task 2.5: `CodingToolsService` — four tool handlers

**Files:**
- Create: `lib/services/coding_tools/coding_tools_service.dart`
- Test: `test/services/coding_tools/coding_tools_service_test.dart`

- [ ] **Step 1: Write failing tests covering each tool + boundary conditions**

Create `test/services/coding_tools/coding_tools_service_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/coding_tools_service.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/apply/datasource/apply_datasource_io.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory projectDir;
  late CodingToolsService svc;
  late ProviderContainer container;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('ct_svc_');
    container = ProviderContainer();
    final CodingToolsRepository repo =
        CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
    final applyRepo = ApplyRepositoryImpl(datasource: ApplyDatasourceIo());
    final applySvc = ApplyService(repo: applyRepo);
    svc = CodingToolsService(repo: repo, applyService: applySvc);
  });

  tearDown(() async {
    container.dispose();
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  group('read_file', () {
    test('returns success with content', () async {
      File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('hello');
      final r = await svc.execute(
        toolName: 'read_file',
        args: {'path': 'a.txt'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isTrue);
      expect(r.output, 'hello');
    });

    test('rejects path escape', () async {
      final r = await svc.execute(
        toolName: 'read_file',
        args: {'path': '../../../etc/passwd'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isFalse);
      expect(r.error, contains('outside'));
    });

    test('rejects files larger than 2MB', () async {
      final big = File(p.join(projectDir.path, 'big.bin'));
      big.writeAsBytesSync(List.filled(2 * 1024 * 1024 + 1, 0x41));
      final r = await svc.execute(
        toolName: 'read_file',
        args: {'path': 'big.bin'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isFalse);
      expect(r.error, contains('File too large'));
    });

    test('rejects non-text files with a clear error', () async {
      File(p.join(projectDir.path, 'bad.bin')).writeAsBytesSync([0xC3, 0x28]);
      final r = await svc.execute(
        toolName: 'read_file',
        args: {'path': 'bad.bin'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isFalse);
      expect(r.error, contains('not text-encoded'));
    });
  });

  group('list_dir', () {
    test('non-recursive lists immediate children', () async {
      File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('x');
      Directory(p.join(projectDir.path, 'sub')).createSync();
      final r = await svc.execute(
        toolName: 'list_dir',
        args: {'path': '.', 'recursive': false},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isTrue);
      expect(r.output, contains('a.txt'));
      expect(r.output, contains('sub'));
    });

    test('missing path returns error', () async {
      final r = await svc.execute(
        toolName: 'list_dir',
        args: {'path': 'does_not_exist'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isFalse);
    });
  });

  group('write_file', () {
    test('creates new file and returns byte count', () async {
      final r = await svc.execute(
        toolName: 'write_file',
        args: {'path': 'new.txt', 'content': 'hello world'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isTrue);
      expect(File(p.join(projectDir.path, 'new.txt')).readAsStringSync(), 'hello world');
    });

    test('overwrites existing file', () async {
      File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('old');
      final r = await svc.execute(
        toolName: 'write_file',
        args: {'path': 'x.txt', 'content': 'new'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isTrue);
      expect(File(p.join(projectDir.path, 'x.txt')).readAsStringSync(), 'new');
    });
  });

  group('str_replace', () {
    test('replaces a unique occurrence', () async {
      File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('hello world');
      final r = await svc.execute(
        toolName: 'str_replace',
        args: {'path': 'x.txt', 'old_str': 'world', 'new_str': 'dart'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isTrue);
      expect(File(p.join(projectDir.path, 'x.txt')).readAsStringSync(), 'hello dart');
    });

    test('returns error when old_str not found', () async {
      File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('hello');
      final r = await svc.execute(
        toolName: 'str_replace',
        args: {'path': 'x.txt', 'old_str': 'missing', 'new_str': 'x'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isFalse);
      expect(r.error, contains('not found'));
    });

    test('returns error when old_str matches multiple times', () async {
      File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('ab ab ab');
      final r = await svc.execute(
        toolName: 'str_replace',
        args: {'path': 'x.txt', 'old_str': 'ab', 'new_str': 'cd'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r.isSuccess, isFalse);
      expect(r.error, contains('matches 3 times'));
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/services/coding_tools/coding_tools_service_test.dart
```

Expected: FAIL — `coding_tools_service.dart` URI doesn't exist.

- [ ] **Step 3: Write the service**

Create `lib/services/coding_tools/coding_tools_service.dart`:

```dart
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/apply/repository/apply_repository.dart';
import '../../data/coding_tools/coding_tools_exceptions.dart';
import '../../data/coding_tools/models/coding_tool_result.dart';
import '../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../data/coding_tools/repository/coding_tools_repository_impl.dart';
import '../apply/apply_service.dart';

part 'coding_tools_service.g.dart';

@Riverpod(keepAlive: true)
CodingToolsService codingToolsService(Ref ref) => CodingToolsService(
  repo: ref.watch(codingToolsRepositoryProvider),
  applyService: ref.watch(applyServiceProvider),
);

/// Executes a single tool call. Each handler is path-guarded, size-capped,
/// and scrubs error messages before returning them to the loop.
class CodingToolsService {
  CodingToolsService({required CodingToolsRepository repo, required ApplyService applyService})
      : _repo = repo,
        _apply = applyService;

  final CodingToolsRepository _repo;
  final ApplyService _apply;

  static const int _kMaxReadBytes = 2 * 1024 * 1024; // 2 MB
  static const int _kMaxListEntries = 500;
  static const int _kMaxListDepth = 3;

  Future<CodingToolResult> execute({
    required String toolName,
    required Map<String, dynamic> args,
    required String projectPath,
    required String sessionId,
    required String messageId,
  }) async {
    final started = DateTime.now();
    dLog('[CodingToolsService] $toolName start');
    try {
      return switch (toolName) {
        'read_file' => await _readFile(args, projectPath),
        'list_dir' => await _listDir(args, projectPath),
        'write_file' => await _writeFile(args, projectPath, sessionId, messageId),
        'str_replace' => await _strReplace(args, projectPath, sessionId, messageId),
        _ => CodingToolResult.error('Unknown tool "$toolName"'),
      };
    } finally {
      dLog('[CodingToolsService] $toolName done in ${DateTime.now().difference(started).inMilliseconds}ms');
    }
  }

  String _resolve(String raw, String projectPath) =>
      p.isAbsolute(raw) ? p.normalize(raw) : p.normalize(p.join(projectPath, raw));

  Future<CodingToolResult> _readFile(Map<String, dynamic> args, String projectPath) async {
    final raw = args['path'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('read_file requires a non-empty "path"');
    final abs = _resolve(raw, projectPath);

    try {
      ApplyService.assertWithinProject(abs, projectPath);
      final size = await _repo.fileSizeBytes(abs);
      if (size > _kMaxReadBytes) {
        return CodingToolResult.error(
          'File too large (${size} bytes; max ${_kMaxReadBytes} bytes). Consider str_replace for targeted edits.',
        );
      }
      final content = await _repo.readTextFile(abs);
      return CodingToolResult.success(content);
    } on PathEscapeException {
      return CodingToolResult.error('Path "$raw" is outside the project root.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on PathNotFoundException {
      return CodingToolResult.error('File "$raw" does not exist.');
    } on FormatException {
      return CodingToolResult.error('File "$raw" is not text-encoded.');
    }
  }

  Future<CodingToolResult> _listDir(Map<String, dynamic> args, String projectPath) async {
    final raw = args['path'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('list_dir requires a non-empty "path"');
    final recursive = args['recursive'] == true;
    final abs = _resolve(raw, projectPath);

    try {
      ApplyService.assertWithinProject(abs, projectPath);
      if (!await _repo.directoryExists(abs)) {
        return CodingToolResult.error('"$raw" is not a directory or does not exist.');
      }
      final entries = await _repo.listDirectory(abs, recursive: recursive);
      final buffer = StringBuffer();
      var count = 0;
      for (final entry in entries) {
        final rel = p.relative(entry.path, from: abs);
        final depth = rel.split(p.separator).length;
        if (recursive && depth > _kMaxListDepth) continue;
        buffer.writeln('- $rel (${entry.statSync().type.name})');
        count++;
        if (count >= _kMaxListEntries) {
          buffer.writeln('(truncated, ${_kMaxListEntries}+ entries)');
          break;
        }
      }
      return CodingToolResult.success(buffer.toString().trimRight());
    } on PathEscapeException {
      return CodingToolResult.error('Path "$raw" is outside the project root.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    }
  }

  Future<CodingToolResult> _writeFile(
    Map<String, dynamic> args,
    String projectPath,
    String sessionId,
    String messageId,
  ) async {
    final raw = args['path'];
    final content = args['content'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('write_file requires a non-empty "path"');
    if (content is! String) return CodingToolResult.error('write_file requires a string "content"');
    final abs = _resolve(raw, projectPath);

    try {
      await _apply.applyChange(
        filePath: abs,
        projectPath: projectPath,
        newContent: content,
        sessionId: sessionId,
        messageId: messageId,
      );
      final bytes = utf8.encode(content).length;
      return CodingToolResult.success('Wrote $bytes bytes to $raw.');
    } on PathEscapeException {
      return CodingToolResult.error('Path "$raw" is outside the project root.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on ApplyTooLargeException catch (e) {
      return CodingToolResult.error('File too large (${e.bytes} bytes).');
    }
  }

  Future<CodingToolResult> _strReplace(
    Map<String, dynamic> args,
    String projectPath,
    String sessionId,
    String messageId,
  ) async {
    final raw = args['path'];
    final oldStr = args['old_str'];
    final newStr = args['new_str'];
    if (raw is! String || raw.isEmpty) return CodingToolResult.error('str_replace requires a non-empty "path"');
    if (oldStr is! String || oldStr.isEmpty) return CodingToolResult.error('str_replace requires "old_str"');
    if (newStr is! String) return CodingToolResult.error('str_replace requires "new_str"');
    final abs = _resolve(raw, projectPath);

    try {
      ApplyService.assertWithinProject(abs, projectPath);
      final original = await _repo.readTextFile(abs);
      final matchCount = _countOccurrences(original, oldStr);
      if (matchCount == 0) {
        return CodingToolResult.error(
          'old_str not found in $raw. The match must be exact, including whitespace.',
        );
      }
      if (matchCount > 1) {
        return CodingToolResult.error(
          'old_str matches $matchCount times in $raw. Include more surrounding context to make it unique.',
        );
      }
      final updated = original.replaceFirst(oldStr, newStr);
      await _apply.applyChange(
        filePath: abs,
        projectPath: projectPath,
        newContent: updated,
        sessionId: sessionId,
        messageId: messageId,
      );
      return CodingToolResult.success('Replaced 1 match in $raw.');
    } on PathEscapeException {
      return CodingToolResult.error('Path "$raw" is outside the project root.');
    } on ProjectMissingException {
      return CodingToolResult.error('Project folder is missing.');
    } on PathNotFoundException {
      return CodingToolResult.error('File "$raw" does not exist.');
    } on FormatException {
      return CodingToolResult.error('File "$raw" is not text-encoded.');
    } on ApplyTooLargeException catch (e) {
      return CodingToolResult.error('File too large (${e.bytes} bytes).');
    }
  }

  static int _countOccurrences(String haystack, String needle) {
    if (needle.isEmpty) return 0;
    var count = 0;
    var idx = 0;
    while ((idx = haystack.indexOf(needle, idx)) != -1) {
      count++;
      idx += needle.length;
    }
    return count;
  }
}
```

- [ ] **Step 4: Generate + run tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/coding_tools/coding_tools_service_test.dart
```

Expected: PASS — all tool tests green.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/services/coding_tools/ test/services/coding_tools/
flutter analyze
git add lib/services/coding_tools/ test/services/coding_tools/
git commit -m "feat(coding_tools): add CodingToolsService with read/list/write/str_replace handlers"
```

---

# Phase 3 — Agent loop skeleton

## Task 3.1: Extend `ChatMessage` with `iterationCapReached` + `pendingPermissionRequest`

**Files:**
- Create: `lib/data/session/models/permission_request.dart`
- Modify: `lib/data/shared/chat_message.dart`
- Test: `test/data/shared/chat_message_test.dart` (create or extend if exists)

- [ ] **Step 1: Write a failing test asserting the new fields default correctly and round-trip through JSON**

Create or extend `test/data/shared/chat_message_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/data/session/models/permission_request.dart';

void main() {
  test('ChatMessage defaults iterationCapReached to false and pendingPermissionRequest to null', () {
    final msg = ChatMessage(
      id: 'm',
      sessionId: 's',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime(2026, 4, 20),
    );
    expect(msg.iterationCapReached, isFalse);
    expect(msg.pendingPermissionRequest, isNull);
  });

  test('ChatMessage round-trips new fields through JSON', () {
    final msg = ChatMessage(
      id: 'm',
      sessionId: 's',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime(2026, 4, 20),
      iterationCapReached: true,
      pendingPermissionRequest: const PermissionRequest(
        toolEventId: 'te1',
        toolName: 'write_file',
        summary: 'lib/foo.dart · New file · 20 bytes',
        input: {'path': 'lib/foo.dart', 'content': '// hi'},
      ),
    );
    final round = ChatMessage.fromJson(msg.toJson());
    expect(round.iterationCapReached, isTrue);
    expect(round.pendingPermissionRequest?.toolName, 'write_file');
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/data/shared/chat_message_test.dart
```

Expected: FAIL — `PermissionRequest` URI doesn't exist.

- [ ] **Step 3: Create `PermissionRequest` model**

Create `lib/data/session/models/permission_request.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_request.freezed.dart';
part 'permission_request.g.dart';

/// A pending approval request emitted by the agent loop in [ChatPermission.askBefore]
/// mode. Rendered by [PermissionRequestCard]; resolved through
/// [AgentPermissionRequestNotifier].
@freezed
abstract class PermissionRequest with _$PermissionRequest {
  const factory PermissionRequest({
    required String toolEventId,
    required String toolName,
    required String summary,
    required Map<String, dynamic> input,
  }) = _PermissionRequest;

  factory PermissionRequest.fromJson(Map<String, dynamic> json) => _$PermissionRequestFromJson(json);
}
```

- [ ] **Step 4: Extend `ChatMessage`**

Edit `lib/data/shared/chat_message.dart`. At the top, after the existing imports, add:

```dart
import '../session/models/permission_request.dart';
```

In the `ChatMessage` freezed class, add two new fields — insert between `askQuestion` and the closing `);`:

```dart
@Default(false) bool iterationCapReached,
PermissionRequest? pendingPermissionRequest,
```

The full updated `ChatMessage` constructor becomes:

```dart
const factory ChatMessage({
  required String id,
  required String sessionId,
  required MessageRole role,
  required String content,
  @Default([]) List<CodeBlock> codeBlocks,
  @Default([]) List<ToolEvent> toolEvents,
  required DateTime timestamp,
  @Default(false) bool isStreaming,
  AskUserQuestion? askQuestion,
  @Default(false) bool iterationCapReached,
  PermissionRequest? pendingPermissionRequest,
}) = _ChatMessage;
```

- [ ] **Step 5: Run build_runner + tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/shared/chat_message_test.dart
```

Expected: PASS.

- [ ] **Step 6: Full test suite check — make sure no callers broke**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib/data/session/models/ lib/data/shared/ test/data/shared/
flutter analyze
git add lib/data/session/models/permission_request.dart lib/data/session/models/permission_request.freezed.dart lib/data/session/models/permission_request.g.dart lib/data/shared/chat_message.dart lib/data/shared/chat_message.freezed.dart lib/data/shared/chat_message.g.dart test/data/shared/chat_message_test.dart
git commit -m "feat(chat): add iterationCapReached + pendingPermissionRequest to ChatMessage"
```

---

## Task 3.2: `AgentFailure` sealed class + `AgentCancelNotifier`

**Files:**
- Create: `lib/features/chat/notifiers/agent_failure.dart`
- Create: `lib/features/chat/notifiers/agent_cancel_notifier.dart`
- Test: `test/features/chat/notifiers/agent_cancel_notifier_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/chat/notifiers/agent_cancel_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/features/chat/notifiers/agent_cancel_notifier.dart';

void main() {
  test('AgentCancelNotifier starts false and toggles via request/clear', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(agentCancelProvider), isFalse);
    container.read(agentCancelProvider.notifier).request();
    expect(container.read(agentCancelProvider), isTrue);
    container.read(agentCancelProvider.notifier).clear();
    expect(container.read(agentCancelProvider), isFalse);
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/features/chat/notifiers/agent_cancel_notifier_test.dart
```

Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write `AgentFailure`**

Create `lib/features/chat/notifiers/agent_failure.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_failure.freezed.dart';

/// Typed failures emitted by [AgentService]. Mapped to snackbars in
/// `chat_input_bar.dart` (or swallowed when the UI already communicates the
/// state — e.g. `iterationCapReached`).
@freezed
sealed class AgentFailure with _$AgentFailure {
  const factory AgentFailure.iterationCapReached() = AgentIterationCapReached;
  const factory AgentFailure.providerDoesNotSupportTools() = AgentProviderDoesNotSupportTools;
  const factory AgentFailure.streamAbortedUnexpectedly(String reason) = AgentStreamAbortedUnexpectedly;
  const factory AgentFailure.toolDispatchFailed(String toolName, String message) = AgentToolDispatchFailed;
  const factory AgentFailure.unknown(Object error) = AgentUnknownError;
}
```

- [ ] **Step 4: Write `AgentCancelNotifier`**

Create `lib/features/chat/notifiers/agent_cancel_notifier.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_cancel_notifier.g.dart';

/// Cooperative cancel flag read by [AgentService] at each tool boundary.
/// Separate from the plain-text stream cancel so both can be flipped by a
/// single stop-button press without coupling their wiring.
@Riverpod(keepAlive: true)
class AgentCancelNotifier extends _$AgentCancelNotifier {
  @override
  bool build() => false;

  void request() => state = true;
  void clear() => state = false;
}
```

- [ ] **Step 5: Generate + run tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/chat/notifiers/agent_cancel_notifier_test.dart
```

Expected: PASS.

- [ ] **Step 6: Wire `AgentCancelNotifier` into `ChatMessagesNotifier`**

> **Context (main already has this):** `cancelSend()` in `ChatMessagesNotifier` cancels the SSE stream via `_activeSubscription?.cancel()`. Without also flipping `agentCancelProvider`, the agent loop's cooperative cancel flag stays `false` and the loop continues after the stream is torn down.

Edit `lib/features/chat/notifiers/chat_notifier.dart`:

1. Add import at the top of the file:

```dart
import 'agent_cancel_notifier.dart';
```

2. At the top of `sendMessage`, after `_cancelRequested = false`, add:

```dart
ref.read(agentCancelProvider.notifier).clear();
```

3. In `cancelSend()`, after `_activeSubscription?.cancel()` / `_activeSubscription = null`, add:

```dart
ref.read(agentCancelProvider.notifier).request();
```

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib/features/chat/notifiers/ test/features/chat/notifiers/
flutter analyze
git add lib/features/chat/notifiers/agent_failure.dart lib/features/chat/notifiers/agent_failure.freezed.dart lib/features/chat/notifiers/agent_cancel_notifier.dart lib/features/chat/notifiers/agent_cancel_notifier.g.dart lib/features/chat/notifiers/chat_notifier.dart test/features/chat/notifiers/agent_cancel_notifier_test.dart
git commit -m "feat(chat): add AgentFailure sealed class and AgentCancelNotifier"
```

---

## Task 3.3: `AgentService.runAgenticTurn` skeleton (no permission gating yet)

**Files:**
- Create: `lib/services/agent/agent_service.dart`
- Test: `test/services/agent/agent_service_test.dart`

This task wires the loop end-to-end minus approval gating. `askBefore` behaves like `fullAccess` until Phase 5 adds the pause-for-approval wiring.

- [ ] **Step 1: Write a failing test that runs a scripted happy-path turn (two rounds) with a fake AIRepository**

Create `test/services/agent/agent_service_test.dart`:

```dart
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
import 'package:code_bench_app/data/apply/datasource/apply_datasource_io.dart';
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
  Stream<String> streamMessage({required List<ChatMessage> history, required String prompt, required AIModel model, String? systemPrompt}) =>
      const Stream.empty();

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
    final applySvc = ApplyService(repo: ApplyRepositoryImpl(datasource: ApplyDatasourceIo()));
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
      [
        const StreamEvent.textDelta('It says hello.'),
        const StreamEvent.finish(reason: 'stop'),
      ],
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
    await svc.runAgenticTurn(
      sessionId: 's',
      history: const [],
      userInput: 'x',
      model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
      permission: ChatPermission.readOnly,
      projectPath: projectDir.path,
    ).drain();

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
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/services/agent/agent_service_test.dart
```

Expected: FAIL — `agent_service.dart` URI doesn't exist.

- [ ] **Step 3: Write the service**

Create `lib/services/agent/agent_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/models/stream_event.dart';
import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/coding_tools/models/coding_tool_definition.dart';
import '../../data/shared/ai_model.dart';
import '../../data/shared/chat_message.dart';
import '../../data/session/models/session_settings.dart';
import '../../data/session/models/tool_event.dart';
import '../../features/chat/notifiers/agent_cancel_notifier.dart';
import '../coding_tools/coding_tools_service.dart';

part 'agent_service.g.dart';

const String _kActSystemPrompt = '''
You are a coding assistant embedded in a local IDE. You have four tools: read_file, list_dir, write_file, str_replace.

Rules:
- Read before you edit. Always call read_file on a file before write_file or str_replace against it, unless you're creating a brand-new file.
- Prefer str_replace over write_file for targeted edits. Only use write_file for new files or full rewrites.
- After making changes, briefly describe what you changed and why in 1-3 sentences.
- If a task is ambiguous or destructive (removing large sections, deleting files, sweeping refactors), ask the user before acting.
- All paths you provide must be inside the active project. Absolute paths outside the project will be rejected.
''';

const int _kMaxIterations = 10;

@Riverpod(keepAlive: true)
Future<AgentService> agentService(Ref ref) async {
  final ai = await ref.watch(aiRepositoryProvider.future);
  final codingTools = ref.watch(codingToolsServiceProvider);
  return AgentService(
    ai: ai,
    codingTools: codingTools,
    cancelFlag: () => ref.read(agentCancelProvider),
  );
}

/// Orchestrates one user turn: streams from the model, executes tool calls,
/// loops until the model returns `finish_reason: stop`, hits the iteration
/// cap, or the user cancels.
class AgentService {
  AgentService({
    required AIRepository ai,
    required CodingToolsService codingTools,
    required bool Function() cancelFlag,
    String Function()? idGen,
  })  : _ai = ai,
        _tools = codingTools,
        _cancelFlag = cancelFlag,
        _idGen = idGen ?? (() => const Uuid().v4());

  final AIRepository _ai;
  final CodingToolsService _tools;
  final bool Function() _cancelFlag;
  final String Function() _idGen;

  Stream<ChatMessage> runAgenticTurn({
    required String sessionId,
    required List<ChatMessage> history,
    required String userInput,
    required AIModel model,
    required ChatPermission permission,
    required String projectPath,
  }) async* {
    final assistantId = _idGen();
    final textBuffer = StringBuffer();
    final events = <ToolEvent>[];
    final pending = <String, _PendingCall>{};
    var iteration = 0;

    final workingHistory = <ChatMessage>[
      ...history,
      ChatMessage(
        id: _idGen(),
        sessionId: sessionId,
        role: MessageRole.user,
        content: userInput,
        timestamp: DateTime.now(),
      ),
    ];

    ChatMessage snapshot({required bool streaming, bool capReached = false}) => ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: textBuffer.toString(),
      timestamp: DateTime.now(),
      isStreaming: streaming,
      toolEvents: List.unmodifiable(events),
      iterationCapReached: capReached,
    );

    while (true) {
      iteration++;
      final tools = permission == ChatPermission.readOnly ? CodingTools.readOnly : CodingTools.all;
      final wire = _buildWireMessages(workingHistory, _kActSystemPrompt, assistantId, textBuffer.toString(), events);
      final roundCalls = <_PendingCall>[];
      String? finishReason;

      await for (final event in _ai.streamMessageWithTools(wireMessages: wire, tools: tools, model: model)) {
        switch (event) {
          case StreamTextDelta(:final text):
            textBuffer.write(text);
            yield snapshot(streaming: true);
          case StreamToolCallStart(:final id, :final name):
            final call = _PendingCall(id: id, name: name);
            pending[id] = call;
            roundCalls.add(call);
            events.add(ToolEvent(id: id, type: 'tool_use', toolName: name));
            yield snapshot(streaming: true);
          case StreamToolCallArgsDelta(:final id, :final argsJsonFragment):
            pending[id]?.argsBuffer.write(argsJsonFragment);
          case StreamToolCallEnd(:final id):
            final call = pending[id];
            if (call != null) {
              call.args = _decodeArgs(call.argsBuffer.toString());
              final idx = events.indexWhere((e) => e.id == id);
              if (idx >= 0) {
                events[idx] = events[idx].copyWith(input: call.args);
              }
              yield snapshot(streaming: true);
            }
          case StreamFinish(:final reason):
            finishReason = reason;
        }
      }

      if (finishReason == 'stop') {
        yield snapshot(streaming: false);
        return;
      }

      if (finishReason != 'tool_calls') {
        dLog('[AgentService] unexpected finishReason=$finishReason');
        textBuffer.write('\n\n_Stream ended unexpectedly._');
        yield snapshot(streaming: false);
        return;
      }

      if (_cancelFlag()) {
        _flipRunningToCancelled(events);
        textBuffer.write('\n\n_Cancelled by user._');
        yield snapshot(streaming: false);
        return;
      }

      if (iteration >= _kMaxIterations) {
        _flipRunningToCancelled(events);
        yield snapshot(streaming: false, capReached: true);
        return;
      }

      for (final call in roundCalls) {
        if (_cancelFlag()) break;
        final result = await _tools.execute(
          toolName: call.name,
          args: call.args,
          projectPath: projectPath,
          sessionId: sessionId,
          messageId: assistantId,
        );
        _recordResult(events, call.id, result);
        workingHistory.add(_toolResultMessage(sessionId, call.id, result));
        yield snapshot(streaming: true);
      }
    }
  }

  Map<String, dynamic> _decodeArgs(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  void _flipRunningToCancelled(List<ToolEvent> events) {
    for (var i = 0; i < events.length; i++) {
      if (events[i].status == ToolStatus.running) {
        events[i] = events[i].copyWith(status: ToolStatus.cancelled);
      }
    }
  }

  void _recordResult(List<ToolEvent> events, String id, dynamic result) {
    final idx = events.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    // result is CodingToolResult — dynamic-typed to keep this method small.
    final isSuccess = (result.isSuccess as bool);
    events[idx] = events[idx].copyWith(
      status: isSuccess ? ToolStatus.success : ToolStatus.error,
      output: result.output as String?,
      error: result.error as String?,
    );
  }

  ChatMessage _toolResultMessage(String sessionId, String toolCallId, dynamic result) {
    // Encoded as a system-role carrier in the local history; the wire translator
    // unpacks it to an OpenAI `tool` role.
    return ChatMessage(
      id: _idGen(),
      sessionId: sessionId,
      role: MessageRole.system,
      content: (result.output ?? result.error ?? '') as String,
      timestamp: DateTime.now(),
      toolEvents: [
        ToolEvent(
          id: toolCallId,
          type: 'tool_result',
          toolName: '__tool_result__',
          status: result.isSuccess == true ? ToolStatus.success : ToolStatus.error,
          output: result.output as String?,
          error: result.error as String?,
        ),
      ],
    );
  }

  /// Translates in-memory history → OpenAI chat-completions wire format.
  List<Map<String, dynamic>> _buildWireMessages(
    List<ChatMessage> history,
    String systemPrompt,
    String currentAssistantId,
    String currentTextBuffer,
    List<ToolEvent> currentEvents,
  ) {
    final wire = <Map<String, dynamic>>[];
    wire.add({'role': 'system', 'content': systemPrompt});
    for (final msg in history) {
      if (msg.role == MessageRole.system && msg.toolEvents.isNotEmpty && msg.toolEvents.first.type == 'tool_result') {
        final te = msg.toolEvents.first;
        wire.add({
          'role': 'tool',
          'tool_call_id': te.id,
          'content': te.output ?? te.error ?? '',
        });
      } else if (msg.role == MessageRole.assistant && msg.toolEvents.isNotEmpty) {
        wire.add({
          'role': 'assistant',
          'content': msg.content.isEmpty ? null : msg.content,
          'tool_calls': [
            for (final te in msg.toolEvents)
              {
                'id': te.id,
                'type': 'function',
                'function': {'name': te.toolName, 'arguments': jsonEncode(te.input)},
              },
          ],
        });
        for (final te in msg.toolEvents) {
          wire.add({
            'role': 'tool',
            'tool_call_id': te.id,
            'content': te.output ?? te.error ?? '',
          });
        }
      } else {
        wire.add({'role': msg.role.value, 'content': msg.content});
      }
    }
    // The assistant's in-progress turn (if it has called tools already this turn).
    if (currentEvents.isNotEmpty) {
      wire.add({
        'role': 'assistant',
        'content': currentTextBuffer.isEmpty ? null : currentTextBuffer,
        'tool_calls': [
          for (final te in currentEvents)
            {
              'id': te.id,
              'type': 'function',
              'function': {'name': te.toolName, 'arguments': jsonEncode(te.input)},
            },
        ],
      });
      for (final te in currentEvents) {
        if (te.status == ToolStatus.success || te.status == ToolStatus.error) {
          wire.add({
            'role': 'tool',
            'tool_call_id': te.id,
            'content': te.output ?? te.error ?? '',
          });
        }
      }
    }
    return wire;
  }
}

class _PendingCall {
  _PendingCall({required this.id, required this.name});
  final String id;
  final String name;
  final StringBuffer argsBuffer = StringBuffer();
  Map<String, dynamic> args = const {};
}
```

- [ ] **Step 4: Generate + run tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/agent/agent_service_test.dart
```

Expected: PASS — all four test cases green.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/services/agent/ test/services/agent/
flutter analyze
git add lib/services/agent/ test/services/agent/
git commit -m "feat(agent): add AgentService loop with cancel, cap, and readOnly gating"
```

---

## Task 3.4: Branch `SessionService.sendAndStream` on `ChatMode.act` + provider

**Files:**
- Modify: `lib/services/session/session_service.dart`
- Test: extend `test/services/session/session_service_test.dart` (or create if not present)

- [ ] **Step 1: Inspect existing tests to mirror patterns**

```bash
flutter test test/services/session/ --list 2>/dev/null || ls test/services/session/
```

If `session_service_test.dart` does not exist, create it minimally. Otherwise append.

- [ ] **Step 2: Write a failing test asserting `sendAndStream` delegates to `AgentService` when mode=act + provider=custom**

Create or append to `test/services/session/session_service_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';
import 'package:code_bench_app/data/ai/repository/ai_repository.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_definition.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/data/apply/datasource/apply_datasource_io.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/session/repository/session_repository.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/data/session/models/chat_session.dart';
import 'package:code_bench_app/data/session/models/session_settings.dart';
import 'package:code_bench_app/services/agent/agent_service.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/coding_tools_service.dart';
import 'package:code_bench_app/services/session/session_service.dart';

class _FakeSessionRepo implements SessionRepository {
  final List<ChatMessage> persisted = [];

  @override
  Future<void> persistMessage(String sessionId, ChatMessage msg) async {
    persisted.add(msg);
  }

  @override
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) async =>
      List.of(persisted);

  // Remaining methods unused in this test.
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
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
    for (final e in rounds[_r++]) { yield e; }
  }

  @override
  Stream<String> streamMessage({required List<ChatMessage> history, required String prompt, required AIModel model, String? systemPrompt}) async* {
    yield 'plain-text-path';
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async => true;

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) async => [];
}

void main() {
  test('sendAndStream routes to AgentService for ChatMode.act + AIProvider.custom', () async {
    final projectDir = await Directory.systemTemp.createTemp('ss_test_');
    addTearDown(() async { if (projectDir.existsSync()) await projectDir.delete(recursive: true); });

    final ai = _ScriptedAI([
      [const StreamEvent.textDelta('done'), const StreamEvent.finish(reason: 'stop')],
    ]);
    final tools = CodingToolsService(
      repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()),
      applyService: ApplyService(repo: ApplyRepositoryImpl(datasource: ApplyDatasourceIo())),
    );
    final agent = AgentService(ai: ai, codingTools: tools, cancelFlag: () => false);
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
```

- [ ] **Step 3: Run to verify failure**

```bash
flutter test test/services/session/session_service_test.dart
```

Expected: FAIL — `SessionService` constructor doesn't accept `agent`, and `sendAndStream` doesn't accept `mode` / `permission` / `projectPath`.

- [ ] **Step 4: Extend `SessionService`**

Edit `lib/services/session/session_service.dart`.

Replace the existing `sessionService` provider and `SessionService` class with:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/shared/ai_model.dart';
import '../../data/shared/chat_message.dart';
import '../../data/session/models/chat_session.dart';
import '../../data/session/models/session_settings.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';
import '../agent/agent_service.dart';

part 'session_service.g.dart';

@Riverpod(keepAlive: true)
Future<SessionService> sessionService(Ref ref) async {
  final session = ref.watch(sessionRepositoryProvider);
  final ai = await ref.watch(aiRepositoryProvider.future);
  final agent = await ref.watch(agentServiceProvider.future);
  return SessionService(session: session, ai: ai, agent: agent);
}

class SessionService {
  SessionService({required SessionRepository session, required AIRepository ai, required AgentService agent})
      : _session = session,
        _ai = ai,
        _agent = agent;

  final SessionRepository _session;
  final AIRepository _ai;
  final AgentService _agent;
  static const _uuid = Uuid();

  // ── CRUD delegation (unchanged — keep existing methods below) ──────────────
```

Keep all the existing CRUD delegate methods (`watchAllSessions`, `createSession`, etc.) — they do not change. Only the constructor and `sendAndStream` signature change.

Replace `sendAndStream` with this branching version:

```dart
  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
    ChatMode mode = ChatMode.chat,
    ChatPermission permission = ChatPermission.fullAccess,
    String? projectPath,
  }) async* {
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: userInput,
      timestamp: DateTime.now(),
    );
    await _session.persistMessage(sessionId, userMsg);
    yield userMsg;

    final history = await _session.loadHistory(sessionId, limit: 20);
    // Preserve the existing interrupted-marker filter so MessageRole.interrupted
    // rows never leak into the model's context window.
    final historyExcludingCurrent = history
        .where((m) => m.id != userMsg.id && m.role != MessageRole.interrupted)
        .toList();

    if (mode == ChatMode.act && model.provider == AIProvider.custom && projectPath != null) {
      await for (final msg in _agent.runAgenticTurn(
        sessionId: sessionId,
        history: historyExcludingCurrent,
        userInput: userInput,
        model: model,
        permission: permission,
        projectPath: projectPath,
      )) {
        if (!msg.isStreaming) {
          await _session.persistMessage(sessionId, msg);
        }
        yield msg;
      }
      if (history.isEmpty) {
        final shortTitle = userInput.length > 50 ? '${userInput.substring(0, 47)}...' : userInput;
        await _session.updateSessionTitle(sessionId, shortTitle);
      }
      return;
    }

    // Plain text path — unchanged from the pre-agent implementation.
    final assistantId = _uuid.v4();
    final buffer = StringBuffer();

    await for (final chunk in _ai.streamMessage(
      history: historyExcludingCurrent,
      prompt: userInput,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      buffer.write(chunk);
      yield ChatMessage(
        id: assistantId,
        sessionId: sessionId,
        role: MessageRole.assistant,
        content: buffer.toString(),
        timestamp: DateTime.now(),
        isStreaming: true,
      );
    }

    final finalMsg = ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: buffer.toString(),
      timestamp: DateTime.now(),
    );
    await _session.persistMessage(sessionId, finalMsg);
    yield finalMsg;

    if (history.isEmpty) {
      final shortTitle = userInput.length > 50 ? '${userInput.substring(0, 47)}...' : userInput;
      await _session.updateSessionTitle(sessionId, shortTitle);
    }
  }
```

- [ ] **Step 5: Update `ChatMessagesNotifier.sendMessage` to pass new args**

Edit `lib/features/chat/notifiers/chat_notifier.dart` — update the `sendMessage` call site to pass mode/permission/projectPath from the session-level providers:

Add these imports (if not already present):

```dart
import '../../project_sidebar/notifiers/project_sidebar_notifier.dart';
```

Inside `sendMessage`, read mode/permission/projectPath just before the `_activeSubscription = service.sendAndStream(...)` call, and extend the named args on that existing call. **Do NOT replace the `StreamSubscription.listen` pattern with `await for`** — doing so would break `cancelSend()`, which cancels via `_activeSubscription?.cancel()`.

```dart
// Read the three new args from their providers immediately before the call.
final mode = ref.read(sessionModeProvider);
final permission = ref.read(sessionPermissionProvider);
final projectPath = ref.read(activeProjectProvider)?.path;

// Existing subscription pattern — keep as-is; just add the new named args.
_activeSubscription = service
    .sendAndStream(
      sessionId: sessionId,
      userInput: input,
      model: model,
      systemPrompt: systemPrompt,
      mode: mode,
      permission: permission,
      projectPath: projectPath,
    )
    .timeout(...)  // keep existing timeout wrapper
    .listen(...)   // keep existing listen block unchanged
```

- [ ] **Step 6: Generate + run tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib/services/session/ lib/features/chat/notifiers/ test/services/session/
flutter analyze
git add lib/services/session/session_service.dart lib/services/session/session_service.g.dart lib/features/chat/notifiers/chat_notifier.dart test/services/session/session_service_test.dart
git commit -m "feat(session): branch sendAndStream on ChatMode.act + AIProvider.custom"
```

---

# Phase 4 — UI polish (cancelled rows + iteration cap banner)

## Task 4.1: `ToolCallRow` — cancelled-state visual polish

**Files:**
- Modify: `lib/features/chat/widgets/tool_call_row.dart`
- Test: `test/features/chat/widgets/tool_call_row_test.dart` (extend if exists; otherwise create)

- [ ] **Step 1: Write failing tests that assert cancelled vs success styling differences**

Create or extend `test/features/chat/widgets/tool_call_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/session/models/tool_event.dart';
import 'package:code_bench_app/features/chat/widgets/tool_call_row.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData.dark().copyWith(extensions: [AppColors.dark]),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('cancelled row renders the arg text with strikethrough decoration', (tester) async {
    const event = ToolEvent(
      id: 'e1',
      type: 'tool_use',
      toolName: 'read_file',
      status: ToolStatus.cancelled,
      input: {'path': 'lib/main.dart'},
    );
    await tester.pumpWidget(_wrap(const ToolCallRow(event: event)));
    await tester.pumpAndSettle();

    final argFinder = find.text('lib/main.dart');
    expect(argFinder, findsOneWidget);
    final argText = tester.widget<Text>(argFinder);
    expect(argText.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('success row does NOT apply strikethrough to the arg text', (tester) async {
    const event = ToolEvent(
      id: 'e1',
      type: 'tool_use',
      toolName: 'read_file',
      status: ToolStatus.success,
      input: {'path': 'lib/main.dart'},
      output: 'hello',
    );
    await tester.pumpWidget(_wrap(const ToolCallRow(event: event)));
    await tester.pumpAndSettle();

    final argText = tester.widget<Text>(find.text('lib/main.dart'));
    expect(argText.style?.decoration, anyOf(isNull, isNot(TextDecoration.lineThrough)));
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/features/chat/widgets/tool_call_row_test.dart
```

Expected: FAIL — cancelled arg's decoration is `null`, not `TextDecoration.lineThrough`.

- [ ] **Step 3: Apply cancelled-state styling in `ToolCallRow`**

Edit `lib/features/chat/widgets/tool_call_row.dart`. In `_ToolCallRowState.build`, replace the collapsed-row `Container` / `Row` with one that branches on `status == ToolStatus.cancelled`. Specifically:

Replace the `Container(...)` at the current lines 53-112 with:

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: status == ToolStatus.cancelled ? c.inputSurface.withValues(alpha: 0.5) : c.inputSurface,
    borderRadius: BorderRadius.circular(_expanded ? 0 : 6),
    border: Border.all(
      color: status == ToolStatus.cancelled ? c.borderColor.withValues(alpha: 0.5) : c.borderColor,
    ),
  ),
  child: Row(
    children: [
      Icon(
        _iconForTool(widget.event.toolName),
        size: 13,
        color: status == ToolStatus.cancelled ? c.dimFg : c.textSecondary,
      ),
      const SizedBox(width: 6),
      Text(
        widget.event.toolName,
        style: TextStyle(
          color: status == ToolStatus.cancelled ? c.textMuted : c.textPrimary,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
      if (arg.isNotEmpty) ...[
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            arg,
            style: TextStyle(
              color: status == ToolStatus.cancelled ? c.dimFg : c.textSecondary,
              fontSize: 10,
              decoration: status == ToolStatus.cancelled ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: status == ToolStatus.cancelled ? c.dimFg : null,
              decorationThickness: 1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ] else
        const Spacer(),
      const SizedBox(width: 8),
      switch (status) {
        ToolStatus.running => SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: c.blueAccent),
        ),
        ToolStatus.success => Icon(Icons.check_circle, size: 11, color: c.success),
        ToolStatus.error => Tooltip(
          message: widget.event.error ?? '${widget.event.toolName} — failed',
          child: Icon(Icons.error, size: 11, color: c.error),
        ),
        ToolStatus.cancelled => Tooltip(
          message: '${widget.event.toolName} — cancelled',
          child: Icon(Icons.cancel_outlined, size: 11, color: c.dimFg),
        ),
      },
      if (widget.event.durationMs != null) ...[
        const SizedBox(width: 6),
        Text('${widget.event.durationMs}ms', style: TextStyle(color: c.textSecondary, fontSize: 9)),
      ],
      if (widget.event.tokensIn != null) ...[
        const SizedBox(width: 6),
        Text(
          '↑${widget.event.tokensIn} ↓${widget.event.tokensOut ?? 0}',
          style: TextStyle(color: c.textSecondary, fontSize: 9),
        ),
      ],
      const SizedBox(width: 6),
      Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 12, color: c.textSecondary),
    ],
  ),
),
```

Note: the surrounding `GestureDetector` remains unchanged — only the `Container` body differs.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
flutter test test/features/chat/widgets/tool_call_row_test.dart
```

Expected: PASS — both tests green.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/features/chat/widgets/tool_call_row.dart test/features/chat/widgets/tool_call_row_test.dart
flutter analyze
git add lib/features/chat/widgets/tool_call_row.dart test/features/chat/widgets/tool_call_row_test.dart
git commit -m "feat(chat): strikethrough + muted styling for cancelled ToolCallRow"
```

---

## Task 4.2: `ChatMessagesNotifier.clearIterationCap` + `continueAgenticTurn`

> **Context (main already has this):** PR #23 created `ChatMessagesActions` for non-streaming state mutations (`deleteMessage`, `loadMore`). `clearIterationCap` and `continueAgenticTurn` stay on `ChatMessagesNotifier` — not `ChatMessagesActions` — because `continueAgenticTurn` calls `sendMessage()` which owns streaming state on the notifier. `clearIterationCap` follows the same helper pattern as `removeFromState`/`prependOlder`. If `continueAgenticTurn` needs a new failure variant, add it to the existing `ChatMessagesFailure` sealed class in `chat_messages_failure.dart` rather than creating a new file.

**Files:**
- Modify: `lib/features/chat/notifiers/chat_notifier.dart`
- Test: `test/features/chat/notifiers/chat_notifier_test.dart` (create if missing; otherwise extend)

- [ ] **Step 1: Write a failing test**

Create or extend `test/features/chat/notifiers/chat_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';

void main() {
  test('clearIterationCap flips iterationCapReached on the matching message', () {
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

    // Seed state directly for the unit test.
    final notifier = container.read(chatMessagesProvider('s').notifier);
    notifier.state = AsyncData([capped]);

    notifier.clearIterationCap('cap');

    final afterMessage = container.read(chatMessagesProvider('s')).value!.first;
    expect(afterMessage.iterationCapReached, isFalse);
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/features/chat/notifiers/chat_notifier_test.dart
```

Expected: FAIL — `clearIterationCap` undefined on `ChatMessagesNotifier`.

- [ ] **Step 3: Add `clearIterationCap` + `continueAgenticTurn` methods**

Edit `lib/features/chat/notifiers/chat_notifier.dart`. Inside `ChatMessagesNotifier`, after `loadMore`, add:

```dart
/// Flips `iterationCapReached` back to `false` on the matching assistant
/// message. Called from the `[Continue]` button on `IterationCapBanner`
/// before re-entering the loop so users don't see two banners.
void clearIterationCap(String messageId) {
  final current = state.value ?? [];
  final idx = current.indexWhere((m) => m.id == messageId);
  if (idx < 0) return;
  final updated = List<ChatMessage>.from(current);
  updated[idx] = updated[idx].copyWith(iterationCapReached: false);
  state = AsyncData(updated);
}

/// Re-enters the agent loop from a capped assistant message. The model sees
/// the capped message's `tool_calls` + `tool_result` pairs in history and
/// continues naturally. No new user message is appended; the iteration
/// counter resets to zero.
Future<Object?> continueAgenticTurn(String messageId) async {
  final sessionId = ref.read(activeSessionIdProvider);
  if (sessionId == null) {
    throw StateError('No active session — cannot continue agentic turn.');
  }
  clearIterationCap(messageId);
  // Piggy-back on sendMessage with an empty user input + a continuation marker.
  // The AgentService sees an empty userInput and does not append a user message.
  return sendMessage('', systemPrompt: null);
}
```

Also update `AgentService.runAgenticTurn` and `SessionService.sendAndStream` to skip the user-message injection when `userInput.isEmpty`:

Edit `lib/services/agent/agent_service.dart` — change the `workingHistory` initializer to:

```dart
final workingHistory = <ChatMessage>[
  ...history,
  if (userInput.isNotEmpty)
    ChatMessage(
      id: _idGen(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: userInput,
      timestamp: DateTime.now(),
    ),
];
```

Edit `lib/services/session/session_service.dart` — wrap the user-message persistence in an `if`:

```dart
if (userInput.isNotEmpty) {
  final userMsg = ChatMessage(
    id: _uuid.v4(),
    sessionId: sessionId,
    role: MessageRole.user,
    content: userInput,
    timestamp: DateTime.now(),
  );
  await _session.persistMessage(sessionId, userMsg);
  yield userMsg;
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/chat/notifiers/chat_notifier_test.dart
flutter test test/services/agent/
```

Expected: PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/features/chat/notifiers/chat_notifier.dart lib/services/agent/ lib/services/session/ test/features/chat/notifiers/
flutter analyze
git add lib/features/chat/notifiers/chat_notifier.dart lib/features/chat/notifiers/chat_notifier.g.dart lib/services/agent/agent_service.dart lib/services/session/session_service.dart test/features/chat/notifiers/chat_notifier_test.dart
git commit -m "feat(chat): add clearIterationCap + continueAgenticTurn for cap-recovery UX"
```

---

## Task 4.3: `IterationCapBanner` widget + last-message provider

**Files:**
- Create: `lib/features/chat/widgets/iteration_cap_banner.dart`
- Test: `test/features/chat/widgets/iteration_cap_banner_test.dart`

- [ ] **Step 1: Write failing widget tests**

Create `test/features/chat/widgets/iteration_cap_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/features/chat/widgets/iteration_cap_banner.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: ThemeData.dark().copyWith(extensions: [AppColors.dark]),
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('active state shows an enabled Continue button', (tester) async {
    await tester.pumpWidget(_wrap(const IterationCapBanner(
      messageId: 'cap',
      sessionId: 's',
      isActive: true,
    )));
    await tester.pumpAndSettle();

    final btn = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Continue'));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('dismissed state shows a disabled Continue button', (tester) async {
    await tester.pumpWidget(_wrap(const IterationCapBanner(
      messageId: 'cap',
      sessionId: 's',
      isActive: false,
    )));
    await tester.pumpAndSettle();

    final btn = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Continue'));
    expect(btn.onPressed, isNull);
    expect(find.text('Continued via new message.'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/features/chat/widgets/iteration_cap_banner_test.dart
```

Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the widget**

Create `lib/features/chat/widgets/iteration_cap_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../notifiers/chat_notifier.dart';

/// Inline banner shown below a capped assistant bubble. [isActive] controls
/// whether the `[Continue]` button is enabled. The dismissal rule lives in
/// the caller (`_AssistantBubble`): active when the capped message is the
/// most recent in the session, otherwise dismissed.
class IterationCapBanner extends ConsumerWidget {
  const IterationCapBanner({
    super.key,
    required this.messageId,
    required this.sessionId,
    required this.isActive,
  });

  final String messageId;
  final String sessionId;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final borderColor = isActive ? c.warning.withValues(alpha: 0.4) : c.borderColor;
    final bgColor = isActive ? c.warning.withValues(alpha: 0.07) : c.inputSurface.withValues(alpha: 0.02);
    final iconColor = isActive ? c.warning : c.textMuted;
    final titleColor = isActive ? c.warning : c.textMuted;
    final subColor = isActive ? c.textSecondary : c.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pause_circle_outline, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paused at 10-step limit.',
                  style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive
                      ? 'Run 10 more steps, or send a new message to redirect.'
                      : 'Continued via new message.',
                  style: TextStyle(color: subColor, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isActive
                ? () => ref.read(chatMessagesProvider(sessionId).notifier).continueAgenticTurn(messageId)
                : null,
            style: TextButton.styleFrom(
              foregroundColor: isActive ? c.warning : c.textMuted,
              backgroundColor: isActive ? c.warning.withValues(alpha: 0.12) : Colors.transparent,
              side: BorderSide(color: isActive ? c.warning.withValues(alpha: 0.4) : c.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Wire the banner into `_AssistantBubble`**

Edit `lib/features/chat/widgets/message_bubble.dart`. Add import:

```dart
import 'iteration_cap_banner.dart';
```

Inside `_AssistantBubble.build` (or the new `_AssistantBubbleState.build` if Phase 4 of the text-selection plan already merged), insert this block inside the `Column` children, directly after the existing `toolEvents` block and before `askQuestion`:

```dart
if (message.iterationCapReached) ...[
  Builder(
    builder: (context) {
      // Banner is active iff this is the most recent message in the session.
      final allMessages = ref.watch(chatMessagesProvider(message.sessionId)).value ?? const [];
      final isActive = allMessages.isNotEmpty && allMessages.last.id == message.id;
      return IterationCapBanner(
        messageId: message.id,
        sessionId: message.sessionId,
        isActive: isActive,
      );
    },
  ),
],
```

- [ ] **Step 5: Run widget tests**

```bash
flutter test test/features/chat/widgets/iteration_cap_banner_test.dart test/features/chat/widgets/message_bubble_test.dart
```

Expected: PASS.

- [ ] **Step 6: Full suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib/features/chat/widgets/ test/features/chat/widgets/
flutter analyze
git add lib/features/chat/widgets/iteration_cap_banner.dart lib/features/chat/widgets/message_bubble.dart test/features/chat/widgets/iteration_cap_banner_test.dart
git commit -m "feat(chat): add IterationCapBanner and wire it into assistant bubble"
```

---

## Task 4.4: Wire stop-button to `AgentCancelNotifier`

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar.dart` (find the existing stop button handler; grep `stop` / `cancel` / `isStreaming`)

- [ ] **Step 1: Locate the existing stop/cancel handler**

```bash
```

Then via the Grep tool search for the stop/cancel-button handler in `lib/features/chat/widgets/chat_input_bar.dart` and read the surrounding code.

- [ ] **Step 2: Add `ref.read(agentCancelProvider.notifier).request()` to the stop handler**

Inside the stop-button `onPressed` handler in `chat_input_bar.dart`, add (keeping the existing cancel wiring intact):

```dart
ref.read(agentCancelProvider.notifier).request();
```

Add import at the top:

```dart
import '../notifiers/agent_cancel_notifier.dart';
```

- [ ] **Step 3: Also clear the flag at the start of each new `sendMessage`**

Edit `lib/features/chat/notifiers/chat_notifier.dart` — inside `ChatMessagesNotifier.sendMessage`, add one line at the very top of the `try` block:

```dart
ref.read(agentCancelProvider.notifier).clear();
```

Add import:

```dart
import 'agent_cancel_notifier.dart';
```

- [ ] **Step 4: Run tests + analyze**

```bash
flutter test
flutter analyze
```

Expected: pass.

- [ ] **Step 5: Commit**

```bash
dart format lib/features/chat/
git add lib/features/chat/widgets/chat_input_bar.dart lib/features/chat/notifiers/chat_notifier.dart
git commit -m "feat(chat): wire stop button to AgentCancelNotifier"
```

---

# Phase 5 — Permission gating

## Task 5.1: `AgentPermissionRequestNotifier`

**Files:**
- Create: `lib/features/chat/notifiers/agent_permission_request_notifier.dart`
- Test: `test/features/chat/notifiers/agent_permission_request_notifier_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/chat/notifiers/agent_permission_request_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/session/models/permission_request.dart';
import 'package:code_bench_app/features/chat/notifiers/agent_permission_request_notifier.dart';

void main() {
  test('request() yields a future that resolves to the user choice', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(agentPermissionRequestProvider.notifier);

    const req = PermissionRequest(
      toolEventId: 'te',
      toolName: 'write_file',
      summary: 'lib/foo.dart · New file · 20 bytes',
      input: {'path': 'lib/foo.dart', 'content': '// hi'},
    );

    final future = notifier.request(req);
    expect(container.read(agentPermissionRequestProvider)?.toolName, 'write_file');

    notifier.resolve(true);
    expect(await future, isTrue);
    expect(container.read(agentPermissionRequestProvider), isNull);
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/features/chat/notifiers/agent_permission_request_notifier_test.dart
```

Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the notifier**

Create `lib/features/chat/notifiers/agent_permission_request_notifier.dart`:

```dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/session/models/permission_request.dart';

part 'agent_permission_request_notifier.g.dart';

/// Holds at most one pending [PermissionRequest]. The agent loop awaits a
/// `Completer<bool>` that fires when the user taps `[Allow]` or `[Deny]`.
/// Single-slot is sufficient because the MVP executes tool calls sequentially.
@Riverpod(keepAlive: true)
class AgentPermissionRequestNotifier extends _$AgentPermissionRequestNotifier {
  Completer<bool>? _completer;

  @override
  PermissionRequest? build() => null;

  /// Posts a request and returns a future that resolves when the user decides.
  Future<bool> request(PermissionRequest req) {
    _completer?.complete(false); // defensive: cancel any stale prior request
    _completer = Completer<bool>();
    state = req;
    return _completer!.future;
  }

  void resolve(bool approved) {
    _completer?.complete(approved);
    _completer = null;
    state = null;
  }
}
```

- [ ] **Step 4: Generate + run tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/chat/notifiers/agent_permission_request_notifier_test.dart
```

Expected: PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/features/chat/notifiers/agent_permission_request_notifier.dart test/features/chat/notifiers/agent_permission_request_notifier_test.dart
flutter analyze
git add lib/features/chat/notifiers/agent_permission_request_notifier.dart lib/features/chat/notifiers/agent_permission_request_notifier.g.dart test/features/chat/notifiers/agent_permission_request_notifier_test.dart
git commit -m "feat(chat): add AgentPermissionRequestNotifier for askBefore gating"
```

---

## Task 5.2: `PermissionRequestCard` widget with `Show diff ▾` disclosure

**Files:**
- Create: `lib/features/chat/widgets/permission_request_card.dart`
- Test: `test/features/chat/widgets/permission_request_card_test.dart`

- [ ] **Step 1: Write failing widget tests**

Create `test/features/chat/widgets/permission_request_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/session/models/permission_request.dart';
import 'package:code_bench_app/features/chat/notifiers/agent_permission_request_notifier.dart';
import 'package:code_bench_app/features/chat/widgets/permission_request_card.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: ThemeData.dark().copyWith(extensions: [AppColors.dark]),
    home: Scaffold(body: child),
  ),
);

void main() {
  const writeReq = PermissionRequest(
    toolEventId: 'te',
    toolName: 'write_file',
    summary: 'lib/foo.dart · New file · 20 bytes',
    input: {'path': 'lib/foo.dart', 'content': '// line1\n// line2\n// line3\n'},
  );

  const emptyContentReq = PermissionRequest(
    toolEventId: 'te',
    toolName: 'write_file',
    summary: 'lib/foo.dart · New file · 0 bytes',
    input: {'path': 'lib/foo.dart', 'content': ''},
  );

  testWidgets('collapsed by default — no preview visible, Show diff label present', (tester) async {
    await tester.pumpWidget(_wrap(const PermissionRequestCard(request: writeReq)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Show diff'), findsOneWidget);
    expect(find.text('// line1'), findsNothing);
  });

  testWidgets('tapping Show diff reveals preview and flips to Hide diff', (tester) async {
    await tester.pumpWidget(_wrap(const PermissionRequestCard(request: writeReq)));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Show diff'));
    await tester.pumpAndSettle();

    expect(find.text('// line1'), findsOneWidget);
    expect(find.textContaining('Hide diff'), findsOneWidget);
  });

  testWidgets('disclosure hidden when preview cannot be built', (tester) async {
    await tester.pumpWidget(_wrap(const PermissionRequestCard(request: emptyContentReq)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Show diff'), findsNothing);
  });

  testWidgets('Allow calls resolve(true)', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              theme: ThemeData.dark().copyWith(extensions: [AppColors.dark]),
              home: const Scaffold(body: PermissionRequestCard(request: writeReq)),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final future = container.read(agentPermissionRequestProvider.notifier).request(writeReq);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Allow'));
    await tester.pumpAndSettle();

    expect(await future, isTrue);
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/features/chat/widgets/permission_request_card_test.dart
```

Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the widget**

Create `lib/features/chat/widgets/permission_request_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/session/models/permission_request.dart';
import '../notifiers/agent_permission_request_notifier.dart';

/// Inline approval card rendered when [ChatPermission.askBefore] gates a
/// destructive tool call. Resolves through [AgentPermissionRequestNotifier].
class PermissionRequestCard extends ConsumerStatefulWidget {
  const PermissionRequestCard({super.key, required this.request});
  final PermissionRequest request;

  @override
  ConsumerState<PermissionRequestCard> createState() => _PermissionRequestCardState();
}

class _PermissionRequestCardState extends ConsumerState<PermissionRequestCard> {
  bool _expanded = false;

  String? _buildPreview() {
    final req = widget.request;
    if (req.toolName == 'write_file') {
      final content = req.input['content'];
      if (content is! String || content.isEmpty) return null;
      final lines = content.split('\n').take(5).toList();
      final truncated = content.split('\n').length > 5;
      return '${lines.join('\n')}${truncated ? '\n…' : ''}';
    }
    if (req.toolName == 'str_replace') {
      final oldStr = req.input['old_str'];
      final newStr = req.input['new_str'];
      if (oldStr is! String || oldStr.isEmpty) return null;
      if (newStr is! String) return null;
      final oldTrunc = oldStr.split('\n').take(3).join('\n');
      final newTrunc = newStr.split('\n').take(3).join('\n');
      return '- $oldTrunc\n+ $newTrunc';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final preview = _buildPreview();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.05),
        border: Border.all(color: c.warning.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: c.warning),
              const SizedBox(width: 6),
              Text('Allow ', style: TextStyle(color: c.textPrimary, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: c.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  widget.request.toolName,
                  style: TextStyle(color: c.warning, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              Text('?', style: TextStyle(color: c.textPrimary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(widget.request.summary, style: TextStyle(color: c.textSecondary, fontSize: 11, fontFamily: 'monospace')),
          if (preview != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Hide diff ▴' : 'Show diff ▾',
                style: TextStyle(color: c.textMuted, fontSize: 10),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.codeBlockBg,
                  border: Border.all(color: c.subtleBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(preview, style: TextStyle(color: c.textPrimary, fontSize: 11, fontFamily: 'monospace')),
              ),
            ],
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => ref.read(agentPermissionRequestProvider.notifier).resolve(false),
                style: TextButton.styleFrom(
                  foregroundColor: c.textSecondary,
                  side: BorderSide(color: c.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('Deny'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => ref.read(agentPermissionRequestProvider.notifier).resolve(true),
                style: TextButton.styleFrom(
                  foregroundColor: c.success,
                  backgroundColor: c.success.withValues(alpha: 0.15),
                  side: BorderSide(color: c.success.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                child: const Text('Allow'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Render the card in `_AssistantBubble`**

Edit `lib/features/chat/widgets/message_bubble.dart`. Add import:

```dart
import 'permission_request_card.dart';
```

Add this block inside the assistant bubble `Column`, directly after the `toolEvents` block and before `iterationCapReached`:

```dart
if (message.pendingPermissionRequest != null) ...[
  PermissionRequestCard(request: message.pendingPermissionRequest!),
],
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/features/chat/widgets/permission_request_card_test.dart
flutter test test/features/chat/widgets/message_bubble_test.dart
```

Expected: PASS.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib/features/chat/widgets/ test/features/chat/widgets/
flutter analyze
git add lib/features/chat/widgets/permission_request_card.dart lib/features/chat/widgets/message_bubble.dart test/features/chat/widgets/permission_request_card_test.dart
git commit -m "feat(chat): add PermissionRequestCard with Show diff disclosure"
```

---

## Task 5.3: Gate write tools in `AgentService` via `AgentPermissionRequestNotifier`

**Files:**
- Modify: `lib/services/agent/agent_service.dart`
- Test: extend `test/services/agent/agent_service_test.dart`

- [ ] **Step 1: Write a failing test for the `askBefore` → deny path**

Append to `test/services/agent/agent_service_test.dart`:

```dart
test('askBefore + deny: tool result reports user denial and next round sees it', () async {
  File(p.join(projectDir.path, 'new.txt')).deleteSync(recursive: false); // ensure not present
  final aiRepo = _FakeAIRepo([
    [
      const StreamEvent.toolCallStart(id: 'c1', name: 'write_file'),
      const StreamEvent.toolCallArgsDelta(id: 'c1', argsJsonFragment: '{"path":"new.txt","content":"hi"}'),
      const StreamEvent.toolCallEnd(id: 'c1'),
      const StreamEvent.finish(reason: 'tool_calls'),
    ],
    [
      const StreamEvent.textDelta('Understood — aborted.'),
      const StreamEvent.finish(reason: 'stop'),
    ],
  ]);

  Future<bool> deny(_) async => false;
  final svc = AgentService(
    ai: aiRepo,
    codingTools: toolsSvc,
    cancelFlag: () => false,
    requestPermission: deny,
  );
  final messages = <ChatMessage>[];
  await for (final msg in svc.runAgenticTurn(
    sessionId: 's',
    history: const [],
    userInput: 'write new.txt',
    model: const AIModel(id: 'm', provider: AIProvider.custom, name: 'm', modelId: 'm'),
    permission: ChatPermission.askBefore,
    projectPath: projectDir.path,
  )) {
    messages.add(msg);
  }

  final finalMsg = messages.last;
  expect(finalMsg.toolEvents.first.status, ToolStatus.cancelled);
  expect(finalMsg.toolEvents.first.error, contains('Denied'));
  expect(File(p.join(projectDir.path, 'new.txt')).existsSync(), isFalse);
});
```

Remove the `File(...).deleteSync` if `new.txt` does not exist; it's a defensive clear.

- [ ] **Step 2: Run to verify failure**

```bash
flutter test test/services/agent/agent_service_test.dart
```

Expected: FAIL — `AgentService` constructor doesn't accept `requestPermission`.

- [ ] **Step 3: Extend `AgentService` with permission gating**

Edit `lib/services/agent/agent_service.dart`.

Update imports:

```dart
import '../../data/session/models/permission_request.dart';
import '../../features/chat/notifiers/agent_permission_request_notifier.dart';
```

Update the constructor to accept a `requestPermission` callback:

```dart
AgentService({
  required AIRepository ai,
  required CodingToolsService codingTools,
  required bool Function() cancelFlag,
  Future<bool> Function(PermissionRequest req)? requestPermission,
  String Function()? idGen,
})  : _ai = ai,
      _tools = codingTools,
      _cancelFlag = cancelFlag,
      _requestPermission = requestPermission ?? ((_) async => true),
      _idGen = idGen ?? (() => const Uuid().v4());

final Future<bool> Function(PermissionRequest req) _requestPermission;
```

Update the `agentServiceProvider` function to inject the notifier-backed callback:

```dart
@Riverpod(keepAlive: true)
Future<AgentService> agentService(Ref ref) async {
  final ai = await ref.watch(aiRepositoryProvider.future);
  final codingTools = ref.watch(codingToolsServiceProvider);
  return AgentService(
    ai: ai,
    codingTools: codingTools,
    cancelFlag: () => ref.read(agentCancelProvider),
    requestPermission: (req) => ref.read(agentPermissionRequestProvider.notifier).request(req),
  );
}
```

Inside the loop's tool-dispatch block (replace the existing `for (final call in roundCalls)` block), gate writes:

```dart
for (final call in roundCalls) {
  if (_cancelFlag()) break;

  final isDestructive = call.name == 'write_file' || call.name == 'str_replace';
  if (permission == ChatPermission.askBefore && isDestructive) {
    final summary = _summaryFor(call);
    final req = PermissionRequest(
      toolEventId: call.id,
      toolName: call.name,
      summary: summary,
      input: call.args,
    );
    yield snapshot(streaming: true).copyWith(pendingPermissionRequest: req);
    final approved = await _requestPermission(req);
    yield snapshot(streaming: true); // clear pendingPermissionRequest
    if (!approved) {
      final idx = events.indexWhere((e) => e.id == call.id);
      if (idx >= 0) {
        events[idx] = events[idx].copyWith(
          status: ToolStatus.cancelled,
          error: 'Denied by user',
        );
      }
      workingHistory.add(_toolResultMessage(sessionId, call.id, const _DeniedResult()));
      yield snapshot(streaming: true);
      continue;
    }
  }

  final result = await _tools.execute(
    toolName: call.name,
    args: call.args,
    projectPath: projectPath,
    sessionId: sessionId,
    messageId: assistantId,
  );
  _recordResult(events, call.id, result);
  workingHistory.add(_toolResultMessage(sessionId, call.id, result));
  yield snapshot(streaming: true);
}
```

Add helpers at the end of the class:

```dart
String _summaryFor(_PendingCall call) {
  if (call.name == 'write_file') {
    final path = call.args['path'] ?? '';
    final content = call.args['content'];
    final bytes = content is String ? utf8.encode(content).length : 0;
    return '$path · New file · $bytes bytes';
  }
  if (call.name == 'str_replace') {
    final path = call.args['path'] ?? '';
    return '$path · 1 match';
  }
  return call.args['path']?.toString() ?? '';
}
```

And a tiny `_DeniedResult` class in the file:

```dart
class _DeniedResult {
  const _DeniedResult();
  bool get isSuccess => false;
  String? get output => null;
  String get error => 'User denied this change.';
}
```

- [ ] **Step 4: Run tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/agent/agent_service_test.dart
```

Expected: PASS (all five test cases including deny path).

- [ ] **Step 5: Full suite + analyze**

```bash
flutter test
flutter analyze
```

Expected: pass; analyze clean.

- [ ] **Step 6: Commit**

```bash
dart format lib/services/agent/ test/services/agent/
git add lib/services/agent/agent_service.dart lib/services/agent/agent_service.g.dart test/services/agent/agent_service_test.dart
git commit -m "feat(agent): gate write_file/str_replace behind askBefore permission"
```

---

## Task 5.4: Surface `AgentFailure.providerDoesNotSupportTools` in `chat_input_bar.dart`

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar.dart` (existing listener; add case)

- [ ] **Step 1: Locate the existing `ref.listen(chatMessagesProvider(...), ...)` in `chat_input_bar.dart`**

Use the Grep tool on `chat_input_bar.dart` for `ref.listen` to find the existing AsyncError handler.

- [ ] **Step 2: Add a switch branch for `AgentFailure`**

Inside the existing `ref.listen` body, when `next is AsyncError`, extract `next.error` and switch on it if it's an `AgentFailure`:

```dart
final err = next.error;
if (err is AgentFailure) {
  switch (err) {
    case AgentIterationCapReached():
      break; // banner communicates this
    case AgentProviderDoesNotSupportTools():
      showErrorSnackBar(
        context,
        "The selected provider doesn't support tool use. Switch to a compatible model or leave Act mode.",
      );
      break;
    case AgentStreamAbortedUnexpectedly():
      showErrorSnackBar(context, 'Stream ended unexpectedly — try again.');
      break;
    case AgentToolDispatchFailed():
      break; // surfaced to the model as a tool_result
    case AgentUnknownError():
      showErrorSnackBar(context, 'Something went wrong.');
      break;
  }
  return;
}
```

Add import:

```dart
import '../notifiers/agent_failure.dart';
```

Note: `SessionService` must emit `AgentFailure.providerDoesNotSupportTools()` when `ChatMode.act` is active but the provider is not `custom`. Add this check in `SessionService.sendAndStream` — at the top of the act-branch, before entering `runAgenticTurn`:

```dart
if (model.provider != AIProvider.custom) {
  throw const AgentProviderDoesNotSupportTools();
}
```

Import `AgentFailure` into `session_service.dart`:

```dart
import '../../features/chat/notifiers/agent_failure.dart';
```

- [ ] **Step 3: Run tests + analyze + commit**

```bash
flutter test
flutter analyze
dart format lib/features/chat/widgets/chat_input_bar.dart lib/services/session/session_service.dart
git add lib/features/chat/widgets/chat_input_bar.dart lib/services/session/session_service.dart
git commit -m "feat(chat): surface AgentFailure.providerDoesNotSupportTools as snackbar"
```

---

# Phase 6 — Manual smoke test + finish

## Task 6.1: Smoke test on local LMStudio

- [ ] **Step 1: Verify build runs clean**

```bash
flutter run -d macos
```

Expected: app launches, existing flows work.

- [ ] **Step 2: Configure a tool-capable local endpoint**

Inside the running app:
1. Open Settings → Providers → Custom.
2. Set the endpoint to your LMStudio / OpenAI-compatible URL (e.g. `http://localhost:1234/v1`).
3. Load a tool-capable model in LMStudio (Qwen 2.5 Coder, Llama 3.1 Instruct, etc.).
4. Select that model in the app's model picker.

- [ ] **Step 3: Manually verify the five scenarios from the spec**

1. **Read:** Prompt `"Read my pubspec.yaml and tell me what Dart SDK version is pinned."` — expect one `read_file` tool row → assistant answer with the version.
2. **Str-replace:** Prompt `"Add a debugPrint('starting') at the top of lib/main.dart's main()."` — expect `read_file` → `str_replace` → assistant summary; the AppliedChange appears in the Changes panel.
3. **Write-file new:** Prompt `"Create a new file lib/foo.dart with a hello world function."` — expect `write_file` row with success; file appears on disk; AppliedChange appears in Changes panel.
4. **List-dir:** Prompt `"List the lib directory."` — expect `list_dir` row with success; formatted tree in response.
5. **Cancel:** Start a multi-step task, click stop during round 2. Verify: stream ends cleanly; in-flight tool row shows strikethrough filename + cancelled icon; assistant message ends with `_Cancelled by user._`.

- [ ] **Step 4: Permission-gating verification**

1. In the session settings, switch permission to `askBefore`.
2. Prompt `"Create a new file lib/bar.dart with a hello function."` — expect an amber `PermissionRequestCard` to appear asking `Allow write_file?`.
3. Tap `Show diff ▾` — expect the preview to expand showing the first lines of `content`.
4. Tap `Deny` — card disappears; tool row shows strikethrough + cancelled; assistant proceeds without creating the file.
5. Re-prompt with the same request, tap `Allow` — file is created.

- [ ] **Step 5: Cap verification**

Force a capped loop by picking a task that naturally loops (e.g. `"read every .dart file in lib/ one at a time and summarize each"`). After 10 tool rounds, expect:
1. The `IterationCapBanner` renders with amber border and enabled `[Continue]` button.
2. Tapping `[Continue]` clears the banner and the agent resumes.
3. Forcing the cap again then typing a new user message instead demonstrates the `dismissed` styling: neutral grey, button inert.

If any scenario fails, debug inline. Do not proceed to finishing until all five work on at least one tool-capable local model.

- [ ] **Step 6: Run the full test suite one last time**

```bash
flutter test
flutter analyze
```

Expected: all green.

- [ ] **Step 7: Commit any smoke-induced fixes**

If the smoke found bugs that required code changes, commit each fix as its own commit with a `fix(...)` message before proceeding.

---

## Completion

After Phase 6 passes and all tests are green, invoke the `superpowers:finishing-a-development-branch` skill to present merge / PR / keep / discard options.

---

## Testing matrix (from spec §Testing — confirms coverage)

| Spec test | Plan task |
|---|---|
| 1. `CodingToolsService` — each tool | Task 2.5 |
| 2. `AgentService.runAgenticTurn` — scripted stream fake | Task 3.3 (happy, cap, cancel, readOnly) + Task 5.3 (askBefore + deny) |
| 3. Wire-format translator | Task 3.3 (covered via the scripted tests — the translator is exercised by each round) |
| 4. `CustomRemoteDatasourceDio.streamMessageWithTools` SSE parser | Task 1.3 |
| 5. `PermissionRequestCard` | Task 5.2 |
| 6. `IterationCapBanner` | Task 4.3 |
| 7. `ToolCallRow` cancelled styling | Task 4.1 |
| 8. `_AssistantBubble` wiring | Covered inline in Task 4.3 / Task 5.2 assertion that the card + banner render when fields are set |

---

## Rollout notes (spec §Rollout, restated)

- **Backout:** revert the six modified files (`session_service.dart`, `custom_remote_datasource_dio.dart`, `ai_repository*.dart`, `chat_notifier.dart`, `message_bubble.dart`, `tool_call_row.dart`, `chat_input_bar.dart`) + delete `lib/data/coding_tools/`, `lib/services/agent/`, `lib/services/coding_tools/`, `lib/features/chat/notifiers/agent_*.dart`, and the two new widgets. No schema migrations — `iterationCapReached` defaults false; `pendingPermissionRequest` defaults null; Drift JSON columns tolerate missing fields.
- **Feature gate:** the agent loop only activates when `ChatMode.act` is selected AND the active model's provider is `AIProvider.custom`. All other combinations use the existing text-only `sendAndStream` path.
