# Claude Code CLI as Anthropic Inference Transport — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `ClaudeCliRemoteDatasourceProcess` that routes Anthropic inference through the user's local `claude` CLI binary, letting users with a Claude Pro/Max subscription avoid a second paid API key. Phase 7 of the agentic executor roadmap.

**Architecture:** New concrete `AIRemoteDatasource` implementation under an abstract `CliRemoteDatasource` base (reusable by Phases 8 and 9). Transport choice (`"api-key"` vs `"cli"`) is persisted per provider in secure storage and consumed by `AIRepositoryImpl` when constructing the `Map<AIProvider, AIRemoteDatasource>`. When CLI transport is active, `SessionService.sendAndStream()` skips the agent loop and streams Claude Code's `stream-json` events directly into the chat transcript; `tool_use` / `tool_result` events render as informational "receipts" in the existing tool-card UI, tagged with a "via Claude Code" badge. Single Code Bench permission card per delegation; Claude Code runs with `--permission-mode bypassPermissions`.

**Tech Stack:** Dart 3.x, Flutter, Riverpod 2 (riverpod_generator), Freezed, `dart:io` `Process.start`, existing `SecureStorage`, existing `AgentPermissionRequestNotifier`/`PermissionRequestCard`.

**Spec:** [docs/superpowers/specs/2026-04-23-claude-cli-inference-transport-design.md](../specs/2026-04-23-claude-cli-inference-transport-design.md)

**Roadmap:** [docs/superpowers/roadmap/agentic-executor-roadmap.md](../roadmap/agentic-executor-roadmap.md) — Phase 7

---

## Pre-flight

- [ ] **P.1 — Create a worktree**

Per CLAUDE.md, plan execution runs in a worktree. From the repo root:

```bash
git worktree add .worktrees/feat/2026-04-23-claude-cli-inference-transport \
  -b feat/2026-04-23-claude-cli-inference-transport
cd .worktrees/feat/2026-04-23-claude-cli-inference-transport
```

- [ ] **P.2 — Verify baseline**

```bash
flutter analyze && flutter test
```

Expected: clean output, all existing tests pass. If anything is red before you start, stop and investigate.

- [ ] **P.3 — Confirm Claude Code CLI is available for fixture capture (Task 1 needs it)**

```bash
claude --version
```

Expected: prints a version like `2.1.104 (Claude Code)`. If the binary is missing, skip Task 1's capture step and use the fixtures embedded in this plan instead.

---

## File map

**New files (production code)**

| Path | Purpose |
|---|---|
| `lib/data/ai/models/cli_detection.dart` | `CliDetection` freezed union + `CliAuthStatus` enum |
| `lib/data/ai/datasource/cli_remote_datasource.dart` | Abstract base; shared by Phases 7/8/9 |
| `lib/data/ai/datasource/claude_cli_remote_datasource_process.dart` | Concrete Claude implementation |
| `lib/data/ai/datasource/claude_cli_stream_parser.dart` | Pure line-parser (stream-json → `StreamEvent`) |
| `lib/services/cli/cli_detection_service.dart` | Detection + auth probe with TTL cache |
| `lib/features/providers/notifiers/claude_cli_failure.dart` | Typed failure union |
| `lib/features/providers/widgets/anthropic_provider_card.dart` | New composite card with switch |
| `lib/features/providers/widgets/coming_soon_provider_card.dart` | Disabled-switch card for OpenAI/Gemini |
| `lib/features/providers/widgets/claude_cli_status_row.dart` | Small component for the CLI detection panel |

**New files (tests and fixtures)**

| Path | Purpose |
|---|---|
| `test/fixtures/claude_cli/text_only.jsonl` | Fixture: plain text response |
| `test/fixtures/claude_cli/single_tool_use.jsonl` | Fixture: one Read tool + result |
| `test/fixtures/claude_cli/thinking.jsonl` | Fixture: thinking block |
| `test/fixtures/claude_cli/malformed.jsonl` | Fixture: bad lines |
| `test/data/ai/datasource/claude_cli_stream_parser_test.dart` | Parser unit tests |
| `test/services/cli/cli_detection_service_test.dart` | Detection service unit tests |
| `test/features/providers/notifiers/claude_cli_failure_test.dart` | Failure mapping tests |
| `test/features/providers/widgets/anthropic_provider_card_test.dart` | Widget/golden tests |
| `test/integration/claude_cli_smoke_test.dart` | Env-gated integration smoke |

**Modified files**

| Path | Change |
|---|---|
| `lib/data/_core/secure_storage.dart` | Add `readAnthropicTransport` / `writeAnthropicTransport` |
| `lib/services/providers/providers_service.dart` | Expose transport read/write |
| `lib/features/providers/notifiers/providers_notifier.dart` | Extend state with `anthropicTransport` |
| `lib/data/ai/repository/ai_repository_impl.dart` | Conditional datasource construction |
| `lib/data/session/models/tool_event.dart` | Add `source` field (freezed) |
| `lib/services/session/session_service.dart` | Route CLI transport to CLI path |
| `lib/features/chat/widgets/tool_call_row.dart` | "via Claude Code" badge when `source == cliTransport` |
| `lib/features/providers/providers_screen.dart` | Use new cards for Anthropic/OpenAI/Gemini rows |

---

## Task 1: Capture stream-json fixtures

**Files:**
- Create: `test/fixtures/claude_cli/text_only.jsonl`
- Create: `test/fixtures/claude_cli/single_tool_use.jsonl`
- Create: `test/fixtures/claude_cli/thinking.jsonl`
- Create: `test/fixtures/claude_cli/malformed.jsonl`

Captured fixtures drive parser tests. If Claude Code is installed, capture them live; otherwise use the embedded samples below.

- [ ] **Step 1: Create fixture directory**

```bash
mkdir -p test/fixtures/claude_cli
```

- [ ] **Step 2: Capture text-only fixture (preferred — live) OR use embedded sample**

Live capture:

```bash
claude -p --output-format stream-json --verbose --permission-mode bypassPermissions \
  --tools "" "Say 'hello' and nothing else." \
  > test/fixtures/claude_cli/text_only.jsonl 2>&1
```

If Claude Code isn't installed, create the file with this embedded sample:

```
{"type":"system","subtype":"init","session_id":"fixture-text-only","model":"claude-opus-4-6"}
{"type":"assistant","message":{"id":"msg_1","role":"assistant","content":[{"type":"text","text":"hello"}]},"session_id":"fixture-text-only","uuid":"evt-1"}
{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"hello"}},"session_id":"fixture-text-only","uuid":"evt-2"}
{"type":"stream_event","event":{"type":"message_stop"},"session_id":"fixture-text-only","uuid":"evt-3"}
{"type":"result","subtype":"success","is_error":false,"session_id":"fixture-text-only"}
```

- [ ] **Step 3: Capture single-tool-use fixture OR use embedded sample**

Live capture:

```bash
claude -p --output-format stream-json --verbose --permission-mode bypassPermissions \
  --tools "Read" "Read the first 2 lines of /etc/hosts and tell me what you see." \
  > test/fixtures/claude_cli/single_tool_use.jsonl 2>&1
```

Embedded sample:

```
{"type":"system","subtype":"init","session_id":"fixture-tool-use"}
{"type":"stream_event","event":{"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_01","name":"Read","input":{}}},"session_id":"fixture-tool-use","uuid":"evt-1"}
{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\"file_path\":\"/etc/hosts\""}},"session_id":"fixture-tool-use","uuid":"evt-2"}
{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":",\"limit\":2}"}},"session_id":"fixture-tool-use","uuid":"evt-3"}
{"type":"stream_event","event":{"type":"content_block_stop","index":0},"session_id":"fixture-tool-use","uuid":"evt-4"}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"toolu_01","content":"1\t##\n2\t# Host Database","is_error":false}]},"session_id":"fixture-tool-use","uuid":"evt-5"}
{"type":"assistant","message":{"id":"msg_2","role":"assistant","content":[{"type":"text","text":"The first two lines are ##, # Host Database."}]},"session_id":"fixture-tool-use","uuid":"evt-6"}
{"type":"stream_event","event":{"type":"message_stop"},"session_id":"fixture-tool-use","uuid":"evt-7"}
```

- [ ] **Step 4: Create thinking fixture**

```
{"type":"system","subtype":"init","session_id":"fixture-thinking"}
{"type":"stream_event","event":{"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":""}},"session_id":"fixture-thinking","uuid":"evt-1"}
{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"The user wants "}},"session_id":"fixture-thinking","uuid":"evt-2"}
{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"a simple greeting."}},"session_id":"fixture-thinking","uuid":"evt-3"}
{"type":"stream_event","event":{"type":"content_block_stop","index":0},"session_id":"fixture-thinking","uuid":"evt-4"}
{"type":"stream_event","event":{"type":"content_block_start","index":1,"content_block":{"type":"text","text":""}},"session_id":"fixture-thinking","uuid":"evt-5"}
{"type":"stream_event","event":{"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"Hi!"}},"session_id":"fixture-thinking","uuid":"evt-6"}
{"type":"stream_event","event":{"type":"message_stop"},"session_id":"fixture-thinking","uuid":"evt-7"}
```

- [ ] **Step 5: Create malformed fixture**

```
{"type":"assistant","message":"incomplete json
not json at all — just a raw line
{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"ok"}},"session_id":"x","uuid":"y"}
```

- [ ] **Step 6: Commit fixtures**

```bash
git add test/fixtures/claude_cli/
git commit -m "test: add stream-json fixtures for Claude Code CLI parser"
```

---

## Task 2: `CliDetection` and `CliAuthStatus` models

**Files:**
- Create: `lib/data/ai/models/cli_detection.dart`
- Create: `test/data/ai/models/cli_detection_test.dart`

- [ ] **Step 1: Write the failing test**

`test/data/ai/models/cli_detection_test.dart`:

```dart
import 'package:code_bench_app/data/ai/models/cli_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CliDetection', () {
    test('notInstalled variant constructs', () {
      const detection = CliDetection.notInstalled();
      expect(detection, isA<CliNotInstalled>());
    });

    test('installed variant carries version, path, auth, timestamp', () {
      final now = DateTime.utc(2026, 4, 23);
      final detection = CliDetection.installed(
        version: '2.1.104',
        binaryPath: '/opt/homebrew/bin/claude',
        authStatus: CliAuthStatus.authenticated,
        checkedAt: now,
      );
      detection.map(
        notInstalled: (_) => fail('expected installed'),
        installed: (installed) {
          expect(installed.version, '2.1.104');
          expect(installed.binaryPath, '/opt/homebrew/bin/claude');
          expect(installed.authStatus, CliAuthStatus.authenticated);
          expect(installed.checkedAt, now);
        },
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/data/ai/models/cli_detection_test.dart
```

Expected: FAIL — `cli_detection.dart` does not exist.

- [ ] **Step 3: Write the model**

`lib/data/ai/models/cli_detection.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cli_detection.freezed.dart';

enum CliAuthStatus { authenticated, unauthenticated, unknown }

@freezed
sealed class CliDetection with _$CliDetection {
  const factory CliDetection.notInstalled() = CliNotInstalled;

  const factory CliDetection.installed({
    required String version,
    required String binaryPath,
    required CliAuthStatus authStatus,
    required DateTime checkedAt,
  }) = CliInstalled;
}
```

- [ ] **Step 4: Generate freezed files**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/data/ai/models/cli_detection.freezed.dart` created.

- [ ] **Step 5: Run tests to verify pass**

```bash
flutter test test/data/ai/models/cli_detection_test.dart
```

Expected: PASS, 2 tests.

- [ ] **Step 6: Commit**

```bash
dart format lib/data/ai/models/cli_detection.dart test/data/ai/models/cli_detection_test.dart
git add lib/data/ai/models/cli_detection.dart lib/data/ai/models/cli_detection.freezed.dart test/data/ai/models/cli_detection_test.dart
git commit -m "feat(ai): add CliDetection/CliAuthStatus models"
```

---

## Task 3: `ClaudeCliFailure` typed union

**Files:**
- Create: `lib/features/providers/notifiers/claude_cli_failure.dart`
- Create: `test/features/providers/notifiers/claude_cli_failure_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:code_bench_app/features/providers/notifiers/claude_cli_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ClaudeCliFailure variants all constructable', () {
    const variants = [
      ClaudeCliFailure.notInstalled(),
      ClaudeCliFailure.unauthenticated(),
      ClaudeCliFailure.crashed(exitCode: 127, stderr: 'not found'),
      ClaudeCliFailure.timedOut(),
      ClaudeCliFailure.streamParseFailed(line: 'x', error: 'y'),
      ClaudeCliFailure.cancelled(),
    ];
    expect(variants.length, 6);
    expect(variants[2], isA<ClaudeCliCrashed>());
  });

  test('unknown wraps arbitrary errors', () {
    final err = StateError('oops');
    final failure = ClaudeCliFailure.unknown(err);
    expect(failure, isA<ClaudeCliUnknown>());
    (failure as ClaudeCliUnknown).error == err ? null : fail('error not preserved');
  });
}
```

- [ ] **Step 2: Run test, confirm FAIL**

```bash
flutter test test/features/providers/notifiers/claude_cli_failure_test.dart
```

- [ ] **Step 3: Write the union**

`lib/features/providers/notifiers/claude_cli_failure.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'claude_cli_failure.freezed.dart';

@freezed
sealed class ClaudeCliFailure with _$ClaudeCliFailure {
  const factory ClaudeCliFailure.notInstalled() = ClaudeCliNotInstalled;
  const factory ClaudeCliFailure.unauthenticated() = ClaudeCliUnauthenticated;
  const factory ClaudeCliFailure.crashed({required int exitCode, required String stderr}) = ClaudeCliCrashed;
  const factory ClaudeCliFailure.timedOut() = ClaudeCliTimedOut;
  const factory ClaudeCliFailure.streamParseFailed({required String line, required Object error}) = ClaudeCliStreamParseFailed;
  const factory ClaudeCliFailure.cancelled() = ClaudeCliCancelled;
  const factory ClaudeCliFailure.unknown(Object error) = ClaudeCliUnknown;
}
```

- [ ] **Step 4: Generate freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run tests, confirm PASS**

```bash
flutter test test/features/providers/notifiers/claude_cli_failure_test.dart
```

- [ ] **Step 6: Commit**

```bash
dart format lib/features/providers/notifiers/ test/features/providers/notifiers/
git add lib/features/providers/notifiers/claude_cli_failure.dart lib/features/providers/notifiers/claude_cli_failure.freezed.dart test/features/providers/notifiers/claude_cli_failure_test.dart
git commit -m "feat(providers): add ClaudeCliFailure typed union"
```

---

## Task 4: `ClaudeCliStreamParser` — failing tests against fixtures

**Files:**
- Create: `test/data/ai/datasource/claude_cli_stream_parser_test.dart`

- [ ] **Step 1: Write the parser tests**

```dart
import 'dart:io';

import 'package:code_bench_app/data/ai/datasource/claude_cli_stream_parser.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ClaudeCliStreamParser parser;

  setUp(() {
    parser = ClaudeCliStreamParser();
  });

  Stream<String> _fixtureLines(String name) async* {
    final file = File('test/fixtures/claude_cli/$name.jsonl');
    for (final line in await file.readAsLines()) {
      if (line.trim().isNotEmpty) yield line;
    }
  }

  test('text_only fixture yields TextDelta + StreamDone', () async {
    final events = <StreamEvent>[];
    await for (final line in _fixtureLines('text_only')) {
      final ev = parser.parseLine(line);
      if (ev != null) events.add(ev);
    }
    expect(events.whereType<TextDelta>().isNotEmpty, isTrue);
    expect(events.whereType<StreamDone>().length, greaterThanOrEqualTo(1));
  });

  test('single_tool_use fixture yields ToolUseStart + deltas + ToolUseComplete + ToolResult', () async {
    final events = <StreamEvent>[];
    await for (final line in _fixtureLines('single_tool_use')) {
      final ev = parser.parseLine(line);
      if (ev != null) events.add(ev);
    }
    expect(events.whereType<ToolUseStart>().length, 1);
    expect(events.whereType<ToolUseInputDelta>().length, greaterThanOrEqualTo(1));
    expect(events.whereType<ToolUseComplete>().length, 1);
    expect(events.whereType<ToolResult>().length, 1);

    final start = events.whereType<ToolUseStart>().single;
    expect(start.name, 'Read');

    final complete = events.whereType<ToolUseComplete>().single;
    expect(complete.input['file_path'], '/etc/hosts');
    expect(complete.input['limit'], 2);

    final result = events.whereType<ToolResult>().single;
    expect(result.isError, isFalse);
    expect(result.content, contains('Host Database'));
  });

  test('thinking fixture yields ThinkingDelta events', () async {
    final events = <StreamEvent>[];
    await for (final line in _fixtureLines('thinking')) {
      final ev = parser.parseLine(line);
      if (ev != null) events.add(ev);
    }
    final thinking = events.whereType<ThinkingDelta>().toList();
    expect(thinking.isNotEmpty, isTrue);
    final concatenated = thinking.map((t) => t.text).join();
    expect(concatenated, 'The user wants a simple greeting.');
  });

  test('malformed fixture: bad lines emit StreamParseFailure, good lines still parsed', () async {
    final events = <StreamEvent>[];
    await for (final line in _fixtureLines('malformed')) {
      final ev = parser.parseLine(line);
      if (ev != null) events.add(ev);
    }
    expect(events.whereType<StreamParseFailure>().length, greaterThanOrEqualTo(2));
    expect(events.whereType<TextDelta>().length, 1);
  });

  test('rate_limit_event is ignored (returns null)', () {
    const line = '{"type":"rate_limit_event","session_id":"x"}';
    expect(parser.parseLine(line), isNull);
  });

  test('system:init is ignored', () {
    const line = '{"type":"system","subtype":"init","session_id":"x"}';
    expect(parser.parseLine(line), isNull);
  });

  test('hook events are ignored', () {
    const line = '{"type":"system","subtype":"hook_started","hook_name":"SessionStart:startup","session_id":"x"}';
    expect(parser.parseLine(line), isNull);
  });
}
```

- [ ] **Step 2: Verify the test file fails to compile (parser does not exist)**

```bash
flutter test test/data/ai/datasource/claude_cli_stream_parser_test.dart 2>&1 | head -20
```

Expected: compile error on `ClaudeCliStreamParser` / `StreamParseFailure`.

- [ ] **Step 3: Commit the failing test file**

```bash
git add test/data/ai/datasource/claude_cli_stream_parser_test.dart
git commit -m "test(ai): failing tests for ClaudeCliStreamParser"
```

---

## Task 5: `ClaudeCliStreamParser` — implementation

**Files:**
- Create: `lib/data/ai/datasource/claude_cli_stream_parser.dart`
- Modify: `lib/data/ai/models/stream_event.dart` (add missing variants if needed)

First inspect `lib/data/ai/models/stream_event.dart` to confirm which variants already exist. The parser emits: `TextDelta`, `ToolUseStart`, `ToolUseInputDelta`, `ToolUseComplete`, `ToolResult`, `ThinkingDelta`, `StreamDone`, `StreamParseFailure`. Add any missing variants to the freezed union before writing the parser.

- [ ] **Step 1: Read existing StreamEvent union and list missing variants**

```bash
cat lib/data/ai/models/stream_event.dart
```

Note which of the eight variants above are already defined. For any missing, append them to the `@freezed sealed class StreamEvent` union as new factories (typical shape: `const factory StreamEvent.textDelta(String text) = TextDelta;` etc.). Preserve existing variants.

- [ ] **Step 2: If you added variants, run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Write the parser**

`lib/data/ai/datasource/claude_cli_stream_parser.dart`:

```dart
import 'dart:convert';

import '../models/stream_event.dart';

/// Parses Claude Code CLI `--output-format stream-json` lines into Code Bench's
/// [StreamEvent] shape.
///
/// Stateful: accumulates partial tool_use input JSON across multiple
/// `input_json_delta` events and emits a single [ToolUseComplete] when the
/// corresponding `content_block_stop` arrives.
class ClaudeCliStreamParser {
  final Map<int, _PendingToolUse> _pendingToolUses = {};

  /// Parses one line of stream-json output.
  ///
  /// Returns the resulting [StreamEvent], or `null` if the line should be
  /// ignored (rate-limit events, system init, hook events). Malformed JSON
  /// returns [StreamParseFailure] instead of throwing.
  StreamEvent? parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return StreamEvent.streamParseFailure(line: trimmed, error: 'expected object, got ${decoded.runtimeType}');
      }
      json = decoded;
    } catch (e) {
      return StreamEvent.streamParseFailure(line: trimmed, error: e);
    }

    final type = json['type'] as String?;

    switch (type) {
      case 'system':
        // Ignore init and hook_* subtypes.
        return null;
      case 'rate_limit_event':
        // Logged elsewhere; not rendered.
        return null;
      case 'stream_event':
        return _parseStreamEvent(json['event'] as Map<String, dynamic>?, line: trimmed);
      case 'user':
        return _parseUserMessage(json['message'] as Map<String, dynamic>?, line: trimmed);
      case 'assistant':
        // Assistant envelope carries the fully-materialised content block;
        // we only rely on the delta-level `stream_event` frames. Ignore the
        // cumulative envelope to avoid double-emitting.
        return null;
      case 'message':
      case 'result':
        return null;
      default:
        // Unknown type — log via the caller's dLog, do not emit parse failure.
        return null;
    }
  }

  StreamEvent? _parseStreamEvent(Map<String, dynamic>? event, {required String line}) {
    if (event == null) return null;
    final eventType = event['type'] as String?;

    switch (eventType) {
      case 'content_block_start':
        final index = event['index'] as int?;
        final block = event['content_block'] as Map<String, dynamic>?;
        if (index == null || block == null) return null;
        final blockType = block['type'] as String?;
        if (blockType == 'tool_use') {
          final id = block['id'] as String?;
          final name = block['name'] as String?;
          if (id == null || name == null) return null;
          _pendingToolUses[index] = _PendingToolUse(id: id, name: name, inputBuffer: StringBuffer());
          return StreamEvent.toolUseStart(id: id, name: name);
        }
        return null;

      case 'content_block_delta':
        final index = event['index'] as int?;
        final delta = event['delta'] as Map<String, dynamic>?;
        if (index == null || delta == null) return null;
        final deltaType = delta['type'] as String?;

        switch (deltaType) {
          case 'text_delta':
            final text = delta['text'] as String? ?? '';
            return StreamEvent.textDelta(text);
          case 'thinking_delta':
            final text = delta['thinking'] as String? ?? '';
            return StreamEvent.thinkingDelta(text);
          case 'input_json_delta':
            final partial = delta['partial_json'] as String? ?? '';
            final pending = _pendingToolUses[index];
            if (pending == null) return null;
            pending.inputBuffer.write(partial);
            return StreamEvent.toolUseInputDelta(id: pending.id, partialJson: partial);
          default:
            return null;
        }

      case 'content_block_stop':
        final index = event['index'] as int?;
        if (index == null) return null;
        final pending = _pendingToolUses.remove(index);
        if (pending == null) return null;
        Map<String, dynamic> input;
        try {
          final decoded = jsonDecode(pending.inputBuffer.toString());
          input = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        } catch (e) {
          return StreamEvent.streamParseFailure(line: line, error: e);
        }
        return StreamEvent.toolUseComplete(id: pending.id, input: input);

      case 'message_stop':
        return const StreamEvent.streamDone();

      default:
        return null;
    }
  }

  StreamEvent? _parseUserMessage(Map<String, dynamic>? message, {required String line}) {
    if (message == null) return null;
    final content = message['content'];
    if (content is! List) return null;
    for (final item in content) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] == 'tool_result') {
        final id = item['tool_use_id'] as String?;
        final raw = item['content'];
        final String contentStr = raw is String ? raw : jsonEncode(raw);
        final isError = item['is_error'] as bool? ?? false;
        if (id == null) return null;
        return StreamEvent.toolResult(toolUseId: id, content: contentStr, isError: isError);
      }
    }
    return null;
  }
}

class _PendingToolUse {
  _PendingToolUse({required this.id, required this.name, required this.inputBuffer});
  final String id;
  final String name;
  final StringBuffer inputBuffer;
}
```

- [ ] **Step 4: Run the parser tests**

```bash
flutter test test/data/ai/datasource/claude_cli_stream_parser_test.dart
```

Expected: all 7 tests PASS. If a test fails, align the parser to the fixture (or the fixture to the real CLI format) — fixtures are the source of truth.

- [ ] **Step 5: Format and commit**

```bash
dart format lib/data/ai/datasource/claude_cli_stream_parser.dart lib/data/ai/models/stream_event.dart
git add lib/data/ai/datasource/claude_cli_stream_parser.dart lib/data/ai/models/stream_event.dart lib/data/ai/models/stream_event.freezed.dart
git commit -m "feat(ai): implement ClaudeCliStreamParser"
```

---

## Task 6: `CliRemoteDatasource` abstract base

**Files:**
- Create: `lib/data/ai/datasource/cli_remote_datasource.dart`

No test — this is an abstract class that gets exercised through its concrete implementations in later tasks.

- [ ] **Step 1: Write the abstract base**

```dart
import '../models/cli_detection.dart';
import 'ai_remote_datasource.dart';

/// Shared base for CLI-backed inference datasources.
///
/// Concrete implementations (Phase 7: Claude Code; Phase 8: Codex; Phase 9:
/// Gemini CLI) spawn a local CLI binary via [Process.start] and stream its
/// output as [StreamEvent]s.
abstract class CliRemoteDatasource implements AIRemoteDatasource {
  /// Binary name as invoked on PATH (e.g. `'claude'`, `'codex'`, `'gemini'`).
  String get binaryName;

  /// One-shot detection probe: is the binary installed and what's its version?
  Future<CliDetection> detectInstalled();

  /// Auth status probe. Only meaningful when [detectInstalled] returned installed.
  Future<CliAuthStatus> checkAuthStatus();
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/data/ai/datasource/cli_remote_datasource.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
dart format lib/data/ai/datasource/cli_remote_datasource.dart
git add lib/data/ai/datasource/cli_remote_datasource.dart
git commit -m "feat(ai): add CliRemoteDatasource abstract base"
```

---

## Task 7: `CliDetectionService` — failing tests

**Files:**
- Create: `test/services/cli/cli_detection_service_test.dart`

This service wraps `Process.run('<binary>', ['--version'])` and `<binary> auth status`. Tests use the same "real process" pattern as [bash_datasource_process_test.dart](../../../test/data/bash/datasource/bash_datasource_process_test.dart), exercising only the parsing/caching — we test with `echo`/`false`/`true` as stand-in binaries instead of mocking. (A pure unit mock would drift from reality.)

- [ ] **Step 1: Write tests**

```dart
import 'package:code_bench_app/data/ai/models/cli_detection.dart';
import 'package:code_bench_app/services/cli/cli_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('binary not on PATH → notInstalled', () async {
    final service = container.read(cliDetectionServiceProvider.notifier);
    final detection = await service.probe('definitely-not-a-real-binary-abc');
    expect(detection, isA<CliNotInstalled>());
  });

  test('binary exists but parser can extract version from stdout', () async {
    // `echo` is on every POSIX system and prints its args verbatim.
    // The service parses the FIRST line matching /\\d+\\.\\d+/ as the version.
    final service = container.read(cliDetectionServiceProvider.notifier);
    // Use the `--help` branch with a binary we know — `sh` prints a usage line
    // with no version. Expect parser to degrade gracefully to version='unknown'.
    // Skip unless /bin/echo present; assume POSIX.
    final detection = await service.probe('/bin/echo');
    expect(detection, isA<CliInstalled>());
  });

  test('TTL cache: second probe within TTL returns cached value', () async {
    final service = container.read(cliDetectionServiceProvider.notifier);
    final first = await service.probe('/bin/echo', ttl: const Duration(minutes: 5));
    final second = await service.probe('/bin/echo', ttl: const Duration(minutes: 5));
    // Same instance is returned for cache hits.
    expect(identical(first, second), isTrue);
  });

  test('invalidate forces re-probe', () async {
    final service = container.read(cliDetectionServiceProvider.notifier);
    final first = await service.probe('/bin/echo');
    service.invalidate('/bin/echo');
    final second = await service.probe('/bin/echo');
    expect(identical(first, second), isFalse);
  });
}
```

- [ ] **Step 2: Run, expect FAIL (service doesn't exist)**

```bash
flutter test test/services/cli/cli_detection_service_test.dart
```

- [ ] **Step 3: Commit failing tests**

```bash
git add test/services/cli/cli_detection_service_test.dart
git commit -m "test(cli): failing tests for CliDetectionService"
```

---

## Task 8: `CliDetectionService` — implementation

**Files:**
- Create: `lib/services/cli/cli_detection_service.dart`

- [ ] **Step 1: Write the service**

```dart
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/models/cli_detection.dart';

part 'cli_detection_service.g.dart';

/// Detects local CLI binaries and caches results per-binary with a TTL.
///
/// Usage:
/// ```
/// final detection = await ref.read(cliDetectionServiceProvider.notifier).probe('claude');
/// ```
@Riverpod(keepAlive: true)
class CliDetectionService extends _$CliDetectionService {
  final Map<String, _CachedDetection> _cache = {};

  @override
  Map<String, CliDetection> build() => const {};

  /// Probes the binary, returning [CliDetection]. Cached for [ttl].
  Future<CliDetection> probe(String binary, {Duration ttl = const Duration(minutes: 2)}) async {
    final cached = _cache[binary];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.cachedAt) < ttl) {
      return cached.detection;
    }

    final detection = await _runProbe(binary);
    _cache[binary] = _CachedDetection(detection: detection, cachedAt: now);
    state = {...state, binary: detection};
    return detection;
  }

  /// Forces the next [probe] call to re-run instead of using the cache.
  void invalidate(String binary) {
    _cache.remove(binary);
    final next = {...state}..remove(binary);
    state = next;
  }

  Future<CliDetection> _runProbe(String binary) async {
    try {
      final versionResult = await Process.run(binary, ['--version'])
          .timeout(const Duration(seconds: 5));
      if (versionResult.exitCode != 0) {
        return const CliDetection.notInstalled();
      }
      final version = _extractVersion(versionResult.stdout.toString());
      final authStatus = await _probeAuth(binary);
      final path = await _which(binary) ?? binary;
      return CliDetection.installed(
        version: version,
        binaryPath: path,
        authStatus: authStatus,
        checkedAt: DateTime.now(),
      );
    } on ProcessException catch (e) {
      dLog('[CliDetectionService] $binary not found: ${e.message}');
      return const CliDetection.notInstalled();
    } catch (e, st) {
      dLog('[CliDetectionService] $binary probe failed: $e\n$st');
      return const CliDetection.notInstalled();
    }
  }

  Future<CliAuthStatus> _probeAuth(String binary) async {
    // Claude CLI: `claude auth status` exits 0 if authenticated, non-zero otherwise.
    // Other CLIs (Phases 8/9) will override this — for now, only handle `claude`.
    if (binary.endsWith('claude')) {
      try {
        final result = await Process.run(binary, ['auth', 'status'])
            .timeout(const Duration(seconds: 5));
        if (result.exitCode == 0) return CliAuthStatus.authenticated;
        final stdout = result.stdout.toString().toLowerCase();
        if (stdout.contains('not logged in') || stdout.contains('unauthenticated')) {
          return CliAuthStatus.unauthenticated;
        }
        return CliAuthStatus.unauthenticated;
      } catch (_) {
        return CliAuthStatus.unknown;
      }
    }
    return CliAuthStatus.unknown;
  }

  String _extractVersion(String output) {
    final match = RegExp(r'(\d+\.\d+(?:\.\d+)?)').firstMatch(output);
    return match?.group(1) ?? 'unknown';
  }

  Future<String?> _which(String binary) async {
    try {
      final result = await Process.run('which', [binary]).timeout(const Duration(seconds: 2));
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }
}

class _CachedDetection {
  _CachedDetection({required this.detection, required this.cachedAt});
  final CliDetection detection;
  final DateTime cachedAt;
}
```

- [ ] **Step 2: Generate riverpod code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Run service tests**

```bash
flutter test test/services/cli/cli_detection_service_test.dart
```

Expected: all 4 tests PASS.

- [ ] **Step 4: Commit**

```bash
dart format lib/services/cli/cli_detection_service.dart
git add lib/services/cli/cli_detection_service.dart lib/services/cli/cli_detection_service.g.dart
git commit -m "feat(services): CliDetectionService with TTL cache"
```

---

## Task 9: `ClaudeCliRemoteDatasourceProcess` — spawn and stream

**Files:**
- Create: `lib/data/ai/datasource/claude_cli_remote_datasource_process.dart`

Implements `AIRemoteDatasource.streamMessage()` by spawning `claude -p` and piping stdout through `ClaudeCliStreamParser`. Does NOT yet integrate with the permission system — that's Task 15. Here we only build the stream end to end.

Note: `streamMessage` on `AIRemoteDatasource` returns `Stream<String>` (raw text tokens). But for CLI transport, we also need to surface the full `StreamEvent` stream so Code Bench's chat layer can render tool cards. We'll add a second method `streamEvents(...)` on `CliRemoteDatasource` (update the abstract base in this task) and call it from `SessionService` in Task 12.

- [ ] **Step 1: Extend `CliRemoteDatasource` base with `streamEvents` method**

Modify `lib/data/ai/datasource/cli_remote_datasource.dart` — add before the closing brace:

```dart
  /// Richer stream used when CLI transport is active. Yields structured
  /// [StreamEvent]s (text, tool_use, tool_result, thinking) parsed from the
  /// CLI's native wire format. The chat layer consumes this and bypasses
  /// Code Bench's agent loop.
  Stream<StreamEvent> streamEvents({
    required List<ChatMessage> history,
    required String prompt,
    required String workingDirectory,
    required String sessionId,
    required bool isFirstTurn,
  });
```

Add needed imports at top:
```dart
import '../../shared/chat_message.dart';
import '../models/stream_event.dart';
```

- [ ] **Step 2: Write the concrete datasource**

`lib/data/ai/datasource/claude_cli_remote_datasource_process.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';
import '../../../features/providers/notifiers/claude_cli_failure.dart';
import '../../coding_tools/models/tool.dart';
import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';
import '../models/cli_detection.dart';
import '../models/stream_event.dart';
import 'cli_remote_datasource.dart';
import 'claude_cli_stream_parser.dart';

/// CLI-backed Anthropic transport. Spawns `claude -p --output-format stream-json`.
class ClaudeCliRemoteDatasourceProcess extends CliRemoteDatasource {
  ClaudeCliRemoteDatasourceProcess({Future<CliDetection> Function()? detector})
      : _detector = detector;

  final Future<CliDetection> Function()? _detector;
  Process? _currentProcess;

  @override
  AIProvider get provider => AIProvider.anthropic;

  @override
  String get binaryName => 'claude';

  @override
  Future<CliDetection> detectInstalled() async {
    if (_detector != null) return _detector!();
    // Fallback direct probe — services layer normally calls CliDetectionService.
    try {
      final result = await Process.run(binaryName, ['--version']).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) return const CliDetection.notInstalled();
      return CliDetection.installed(
        version: result.stdout.toString().trim(),
        binaryPath: binaryName,
        authStatus: CliAuthStatus.unknown,
        checkedAt: DateTime.now(),
      );
    } catch (_) {
      return const CliDetection.notInstalled();
    }
  }

  @override
  Future<CliAuthStatus> checkAuthStatus() async {
    try {
      final result = await Process.run(binaryName, ['auth', 'status']).timeout(const Duration(seconds: 5));
      return result.exitCode == 0 ? CliAuthStatus.authenticated : CliAuthStatus.unauthenticated;
    } catch (_) {
      return CliAuthStatus.unknown;
    }
  }

  @override
  Stream<StreamEvent> streamEvents({
    required List<ChatMessage> history,
    required String prompt,
    required String workingDirectory,
    required String sessionId,
    required bool isFirstTurn,
  }) async* {
    final parser = ClaudeCliStreamParser();
    final args = <String>[
      '-p',
      '--output-format', 'stream-json',
      '--include-partial-messages',
      '--permission-mode', 'bypassPermissions',
      '--verbose',
      if (isFirstTurn) ...['--session-id', sessionId] else ...['--resume', sessionId],
      prompt,
    ];

    final Process process;
    try {
      process = await Process.start(
        binaryName,
        args,
        workingDirectory: workingDirectory,
        runInShell: false,
      );
    } on ProcessException catch (e) {
      dLog('[ClaudeCli] start failed: $e');
      yield StreamEvent.streamError(const ClaudeCliFailure.notInstalled());
      return;
    } catch (e) {
      yield StreamEvent.streamError(ClaudeCliFailure.unknown(e));
      return;
    }

    _currentProcess = process;
    final stderrBuffer = StringBuffer();
    process.stderr.transform(utf8.decoder).listen(stderrBuffer.write);

    try {
      await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
        final event = parser.parseLine(line);
        if (event != null) yield event;
      }

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        yield StreamEvent.streamError(
          ClaudeCliFailure.crashed(exitCode: exitCode, stderr: stderrBuffer.toString()),
        );
      } else {
        yield const StreamEvent.streamDone();
      }
    } finally {
      _currentProcess = null;
    }
  }

  /// Cancels any in-flight process (called by SessionService on user stop).
  Future<void> cancel() async {
    final p = _currentProcess;
    if (p == null) return;
    p.kill(ProcessSignal.sigterm);
    final exited = await p.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () async {
        p.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    dLog('[ClaudeCli] cancelled with exit=$exited');
  }

  // ── AIRemoteDatasource legacy methods ─────────────────────────────────
  //
  // `streamMessage` on the base interface returns raw text tokens. For CLI
  // transport, the chat layer calls `streamEvents` directly. We implement
  // `streamMessage` as a thin adapter that projects text-only content, used
  // only in code paths that haven't been wired for events yet.

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    // SessionService routes CLI transport to streamEvents. This adapter exists
    // so AIRepositoryImpl can still satisfy the AIRemoteDatasource contract.
    yield* streamEvents(
      history: history,
      prompt: prompt,
      workingDirectory: Directory.current.path,
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      isFirstTurn: true,
    )
        .where((e) => e is TextDelta)
        .cast<TextDelta>()
        .map((e) => e.text);
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    final detection = await detectInstalled();
    if (detection is! CliInstalled) return false;
    return detection.authStatus == CliAuthStatus.authenticated;
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    // CLI transport doesn't expose model enumeration; return the default Claude models.
    return AIModels.defaults.where((m) => m.provider == AIProvider.anthropic).toList();
  }
}
```

- [ ] **Step 3: Add `StreamEvent.streamError` if missing**

Check `lib/data/ai/models/stream_event.dart` for a variant that wraps a typed failure. If not present, add:

```dart
const factory StreamEvent.streamError(Object failure) = StreamError;
```

Then `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Verify compiles**

```bash
flutter analyze lib/data/ai/datasource/claude_cli_remote_datasource_process.dart
```

Expected: no issues.

- [ ] **Step 5: Commit**

```bash
dart format lib/data/ai/datasource/
git add lib/data/ai/datasource/claude_cli_remote_datasource_process.dart lib/data/ai/datasource/cli_remote_datasource.dart lib/data/ai/models/stream_event.dart lib/data/ai/models/stream_event.freezed.dart
git commit -m "feat(ai): implement ClaudeCliRemoteDatasourceProcess"
```

---

## Task 10: Integration smoke test (env-gated)

**Files:**
- Create: `test/integration/claude_cli_smoke_test.dart`

- [ ] **Step 1: Write the smoke test**

```dart
@TestOn('mac-os || linux')
@Tags(['integration'])
import 'dart:io';

import 'package:code_bench_app/data/ai/datasource/claude_cli_remote_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/stream_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cliAvailable = Platform.environment['CLAUDE_CLI_AVAILABLE'] == '1';

  test('real claude CLI emits at least one TextDelta', () async {
    final ds = ClaudeCliRemoteDatasourceProcess();
    final events = <StreamEvent>[];
    await for (final event in ds.streamEvents(
      history: const [],
      prompt: 'Say "hi" and nothing else.',
      workingDirectory: Directory.systemTemp.path,
      sessionId: 'smoke-${DateTime.now().millisecondsSinceEpoch}',
      isFirstTurn: true,
    )) {
      events.add(event);
      if (events.length > 500) break; // safety cap
    }
    expect(events.whereType<TextDelta>().isNotEmpty, isTrue);
  }, skip: cliAvailable ? null : 'Set CLAUDE_CLI_AVAILABLE=1 to run');
}
```

- [ ] **Step 2: Run locally if available**

```bash
CLAUDE_CLI_AVAILABLE=1 flutter test test/integration/claude_cli_smoke_test.dart --tags=integration
```

Expected (if `claude` installed and authenticated): PASS. Otherwise: skipped.

- [ ] **Step 3: Commit**

```bash
git add test/integration/claude_cli_smoke_test.dart
git commit -m "test(integration): env-gated Claude CLI smoke test"
```

---

## Task 11: `SecureStorage` transport persistence

**Files:**
- Modify: `lib/data/_core/secure_storage.dart`
- Modify: `lib/services/providers/providers_service.dart`

- [ ] **Step 1: Add to `SecureStorage`**

Add alongside `writeApiKey` / `readApiKey`:

```dart
  static const _kAnthropicTransport = 'anthropic_transport';

  Future<void> writeAnthropicTransport(String value) async {
    await _storage.write(key: _kAnthropicTransport, value: value);
  }

  Future<String?> readAnthropicTransport() async {
    return _storage.read(key: _kAnthropicTransport);
  }

  Future<void> deleteAnthropicTransport() async {
    await _storage.delete(key: _kAnthropicTransport);
  }
```

- [ ] **Step 2: Expose through `ProvidersService`**

Add the same three methods to `providers_service.dart`, delegating to `SecureStorage`:

```dart
  Future<void> writeAnthropicTransport(String value) => _storage.writeAnthropicTransport(value);
  Future<String?> readAnthropicTransport() => _storage.readAnthropicTransport();
```

- [ ] **Step 3: Verify compiles**

```bash
flutter analyze lib/data/_core/secure_storage.dart lib/services/providers/providers_service.dart
```

- [ ] **Step 4: Commit**

```bash
dart format lib/data/_core/secure_storage.dart lib/services/providers/providers_service.dart
git add lib/data/_core/secure_storage.dart lib/services/providers/providers_service.dart
git commit -m "feat(providers): persist anthropicTransport in secure storage"
```

---

## Task 12: `ApiKeysNotifierState` — add `anthropicTransport`

**Files:**
- Modify: `lib/features/providers/notifiers/providers_notifier.dart`

- [ ] **Step 1: Extend state and loader**

Add `anthropicTransport` field to `ApiKeysNotifierState` and its `copyWith`. In `build()`, read from service (default to `'api-key'` if null). Add a `setAnthropicTransport` method to the notifier that writes through to the service and updates state:

```dart
class ApiKeysNotifierState {
  const ApiKeysNotifierState({
    required this.openai,
    required this.anthropic,
    required this.gemini,
    required this.ollamaUrl,
    required this.customEndpoint,
    required this.customApiKey,
    required this.anthropicTransport,
  });

  // ... existing fields ...
  final String anthropicTransport; // 'api-key' | 'cli'

  ApiKeysNotifierState copyWith({
    // ... existing params ...
    String? anthropicTransport,
  }) => ApiKeysNotifierState(
    // ... existing assignments ...
    anthropicTransport: anthropicTransport ?? this.anthropicTransport,
  );
}
```

In `build()`:
```dart
anthropicTransport: await svc.readAnthropicTransport() ?? 'api-key',
```

In the notifier class, add:
```dart
Future<void> setAnthropicTransport(String value) async {
  assert(value == 'api-key' || value == 'cli', 'invalid transport: $value');
  final svc = ref.read(providersServiceProvider);
  await svc.writeAnthropicTransport(value);
  final current = await future;
  state = AsyncData(current.copyWith(anthropicTransport: value));
  ref.invalidate(aiRepositoryProvider);
}
```

Add import: `import '../../../data/ai/repository/ai_repository_impl.dart';`

- [ ] **Step 2: Verify analyze**

```bash
flutter analyze lib/features/providers/notifiers/providers_notifier.dart
```

- [ ] **Step 3: Regenerate Riverpod code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Commit**

```bash
dart format lib/features/providers/notifiers/providers_notifier.dart
git add lib/features/providers/notifiers/providers_notifier.dart lib/features/providers/notifiers/providers_notifier.g.dart
git commit -m "feat(providers): expose anthropicTransport in ApiKeysNotifierState"
```

---

## Task 13: `AIRepositoryImpl` — conditional datasource

**Files:**
- Modify: `lib/data/ai/repository/ai_repository_impl.dart`

- [ ] **Step 1: Read transport setting and swap datasource**

Replace the existing `AnthropicRemoteDatasourceDio(...)` construction with a conditional:

```dart
@Riverpod(keepAlive: true)
Future<AIRepository> aiRepository(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  final transport = await storage.readAnthropicTransport() ?? 'api-key';
  final anthropicDs = transport == 'cli'
      ? ClaudeCliRemoteDatasourceProcess()
      : AnthropicRemoteDatasourceDio(await storage.readApiKey('anthropic') ?? '');
  return AIRepositoryImpl(
    sources: {
      AIProvider.anthropic: anthropicDs,
      AIProvider.openai: OpenAIRemoteDatasourceDio(await storage.readApiKey('openai') ?? ''),
      AIProvider.gemini: GeminiRemoteDatasourceDio(await storage.readApiKey('gemini') ?? ''),
      AIProvider.ollama: OllamaRemoteDatasourceDio(await storage.readOllamaUrl() ?? 'http://localhost:11434'),
      AIProvider.custom: CustomRemoteDatasourceDio(
        endpoint: await storage.readCustomEndpoint() ?? '',
        apiKey: await storage.readCustomApiKey() ?? '',
      ),
    },
  );
}
```

Add import: `import '../datasource/claude_cli_remote_datasource_process.dart';`

- [ ] **Step 2: Verify analyze**

```bash
flutter analyze lib/data/ai/repository/ai_repository_impl.dart
```

- [ ] **Step 3: Commit**

```bash
dart format lib/data/ai/repository/ai_repository_impl.dart
git add lib/data/ai/repository/ai_repository_impl.dart
git commit -m "feat(ai): conditional Anthropic datasource by transport"
```

---

## Task 14: `ToolEvent.source` field

**Files:**
- Modify: `lib/data/session/models/tool_event.dart`

Adds a `ToolEventSource` enum to distinguish agent-loop-driven tool events from CLI-transport "receipt" events. Default to `agentLoop` for backward compatibility.

- [ ] **Step 1: Extend the model**

Add at top of file:

```dart
enum ToolEventSource { agentLoop, cliTransport }
```

Add field inside the freezed factory (with default):

```dart
@Default(ToolEventSource.agentLoop) ToolEventSource source,
```

- [ ] **Step 2: Regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Run existing tests to ensure no regression**

```bash
flutter test
```

Expected: all existing tests pass — the default keeps old call sites valid.

- [ ] **Step 4: Commit**

```bash
dart format lib/data/session/models/tool_event.dart
git add lib/data/session/models/tool_event.dart lib/data/session/models/tool_event.freezed.dart lib/data/session/models/tool_event.g.dart
git commit -m "feat(session): add ToolEventSource (agentLoop|cliTransport)"
```

---

## Task 15: `SessionService` — CLI routing

**Files:**
- Modify: `lib/services/session/session_service.dart`

This is the main integration seam. When the active Anthropic transport is CLI, `sendAndStream()` dispatches to `ClaudeCliRemoteDatasourceProcess.streamEvents()` directly, bypassing `AgentService.runAgenticTurn()`. Each received `StreamEvent` is converted into a `ChatMessage` update (text accumulates, tool events append to `toolEvents` with `source: ToolEventSource.cliTransport`).

- [ ] **Step 1: Inspect existing `sendAndStream` (read lines around 115–147)**

```bash
sed -n '100,160p' lib/services/session/session_service.dart
```

Locate the existing branch between `ChatMode.act` (→ agent) and plain chat (→ streamMessage). We add a third: if model is Anthropic AND transport is CLI, route to CLI event stream.

- [ ] **Step 2: Add the CLI routing branch**

Pseudo-diff (adapt to the actual existing method signature):

```dart
Stream<ChatMessage> sendAndStream({required String sessionId, required String prompt, ...}) async* {
  final transport = (await ref.read(apiKeysProvider.future)).anthropicTransport;
  final model = _resolveModel(...);

  if (model.provider == AIProvider.anthropic && transport == 'cli') {
    // Request permission first.
    final permitted = await ref.read(agentPermissionRequestProvider.notifier).request(
      toolEventId: sessionId,
      toolName: 'claude-cli',
      summary: 'Delegate to Claude Code CLI',
      input: {
        'prompt': prompt.substring(0, prompt.length < 200 ? prompt.length : 200),
        'workingDirectory': projectPath,
        'sessionId': sessionId,
        'warning': 'Claude Code will autonomously read, edit, and run shell commands in this directory using its built-in tools. Code Bench\'s permission rules do not apply to its actions.',
      },
    );
    if (!permitted) {
      yield* _emitCancelledChatMessage(sessionId);
      return;
    }

    final anthropicDs = (await ref.read(aiRepositoryProvider.future) as AIRepositoryImpl)
        .rawDatasource(AIProvider.anthropic) as ClaudeCliRemoteDatasourceProcess;

    final isFirstTurn = await _isFirstTurn(sessionId);
    yield* _streamCliEvents(
      anthropicDs,
      sessionId: sessionId,
      prompt: prompt,
      isFirstTurn: isFirstTurn,
    );
    return;
  }

  // ... existing branches for agent loop / plain chat ...
}

Stream<ChatMessage> _streamCliEvents(
  ClaudeCliRemoteDatasourceProcess ds, {
  required String sessionId,
  required String prompt,
  required bool isFirstTurn,
}) async* {
  final msg = ChatMessage.assistant(id: _uuid.v4(), sessionId: sessionId, content: '');
  var current = msg;
  final toolEvents = <ToolEvent>[];

  await for (final event in ds.streamEvents(
    history: await _loadHistory(sessionId),
    prompt: prompt,
    workingDirectory: _projectPath,
    sessionId: sessionId,
    isFirstTurn: isFirstTurn,
  )) {
    current = _applyCliEvent(current, event, toolEvents);
    yield current;
    await _persist(current); // write-through to Drift
  }
}

ChatMessage _applyCliEvent(ChatMessage msg, StreamEvent event, List<ToolEvent> toolEvents) {
  return event.map(
    textDelta: (e) => msg.copyWith(content: msg.content + e.text),
    thinkingDelta: (e) => msg.copyWith(thinking: (msg.thinking ?? '') + e.text),
    toolUseStart: (e) {
      toolEvents.add(ToolEvent.running(
        id: e.id,
        name: e.name,
        input: const {},
        source: ToolEventSource.cliTransport,
      ));
      return msg.copyWith(toolEvents: List.unmodifiable(toolEvents));
    },
    toolUseComplete: (e) {
      final idx = toolEvents.indexWhere((t) => t.id == e.id);
      if (idx >= 0) toolEvents[idx] = toolEvents[idx].copyWith(input: e.input);
      return msg.copyWith(toolEvents: List.unmodifiable(toolEvents));
    },
    toolResult: (e) {
      final idx = toolEvents.indexWhere((t) => t.id == e.toolUseId);
      if (idx >= 0) {
        toolEvents[idx] = toolEvents[idx].copyWith(
          output: e.content,
          status: e.isError ? ToolEventStatus.error : ToolEventStatus.success,
        );
      }
      return msg.copyWith(toolEvents: List.unmodifiable(toolEvents));
    },
    streamDone: (_) => msg.copyWith(done: true),
    streamError: (e) => msg.copyWith(done: true, error: e.failure.toString()),
    // other variants (toolUseInputDelta): no-op — we accumulate in the parser
    orElse: () => msg,
  );
}
```

Adjust to the actual `ChatMessage` / `ToolEvent` shape. Key invariants:
- Each `StreamEvent` produces a new `ChatMessage` snapshot (immutable).
- Tool events originating from CLI carry `source: ToolEventSource.cliTransport`.
- Permission denial emits a "cancelled" `ChatMessage` and returns early, without spawning.

- [ ] **Step 3: Verify analyze**

```bash
flutter analyze lib/services/session/session_service.dart
```

Expected: no new issues. If `AIRepositoryImpl` needs a public accessor for its sources map, add `AIRemoteDatasource rawDatasource(AIProvider p) => _sources[p]!;` to the repo impl.

- [ ] **Step 4: Run existing session service tests**

```bash
flutter test test/services/session/
```

Expected: all previous tests still pass (the new branch only activates when transport is `'cli'`, which no existing test configures).

- [ ] **Step 5: Commit**

```bash
dart format lib/services/session/session_service.dart lib/data/ai/repository/ai_repository_impl.dart
git add lib/services/session/session_service.dart lib/data/ai/repository/ai_repository_impl.dart
git commit -m "feat(session): route Anthropic CLI transport to CLI event stream"
```

---

## Task 16: "via Claude Code" badge in tool card

**Files:**
- Modify: `lib/features/chat/widgets/tool_call_row.dart`

- [ ] **Step 1: Import `ToolEventSource` and render badge**

Near the tool name label, add:

```dart
if (event.source == ToolEventSource.cliTransport) ...[
  const SizedBox(width: 8),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: colors.accent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: colors.accent.withOpacity(0.3), width: 0.5),
    ),
    child: Text(
      'via Claude Code',
      style: TextStyle(fontSize: 10, color: colors.accent, letterSpacing: 0.3),
    ),
  ),
],
```

Add import for `ToolEventSource` from `lib/data/session/models/tool_event.dart`.

- [ ] **Step 2: Verify analyze + existing widget tests**

```bash
flutter analyze lib/features/chat/widgets/tool_call_row.dart
flutter test test/features/chat/
```

Expected: all pass; the badge branch is only taken for CLI events, so agent-loop tests are unaffected.

- [ ] **Step 3: Commit**

```bash
dart format lib/features/chat/widgets/tool_call_row.dart
git add lib/features/chat/widgets/tool_call_row.dart
git commit -m "feat(chat): 'via Claude Code' badge on CLI-sourced tool cards"
```

---

## Task 17: `ClaudeCliStatusRow` widget

**Files:**
- Create: `lib/features/providers/widgets/claude_cli_status_row.dart`

Small stateless component: one row showing CLI detection + auth status. Used by both the active-panel state and the switch's inactive summary.

- [ ] **Step 1: Write the widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/ai/models/cli_detection.dart';
import '../../../services/cli/cli_detection_service.dart';

class ClaudeCliStatusRow extends ConsumerStatefulWidget {
  const ClaudeCliStatusRow({super.key});

  @override
  ConsumerState<ClaudeCliStatusRow> createState() => _ClaudeCliStatusRowState();
}

class _ClaudeCliStatusRowState extends ConsumerState<ClaudeCliStatusRow> {
  CliDetection? _detection;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe({bool forceRefresh = false}) async {
    if (forceRefresh) {
      ref.read(cliDetectionServiceProvider.notifier).invalidate('claude');
    }
    final d = await ref.read(cliDetectionServiceProvider.notifier).probe('claude');
    if (!mounted) return;
    setState(() {
      _detection = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_loading) return const SizedBox(height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)));
    final d = _detection;
    if (d is CliNotInstalled) {
      return _row(
        context,
        color: c.textMuted,
        statusLabel: 'not installed',
        detail: 'Install Claude Code to route Anthropic through your subscription.',
      );
    }
    if (d is CliInstalled) {
      switch (d.authStatus) {
        case CliAuthStatus.authenticated:
          return _row(
            context,
            color: c.success,
            statusLabel: 'detected · v${d.version} · authenticated',
            detail: 'Not active — flip the switch above to route through your subscription.',
            showRecheck: true,
          );
        case CliAuthStatus.unauthenticated:
          return _row(
            context,
            color: c.warning,
            statusLabel: 'detected · v${d.version} · not authenticated',
            detail: 'Run this in a terminal to sign in:',
            cta: _copyCta(context, 'claude auth login'),
          );
        case CliAuthStatus.unknown:
          return _row(
            context,
            color: c.textMuted,
            statusLabel: 'detected · v${d.version} · auth unknown',
            detail: '',
            showRecheck: true,
          );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _row(BuildContext context, {required Color color, required String statusLabel, required String detail, bool showRecheck = false, Widget? cta}) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Claude Code CLI', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('● $statusLabel', style: TextStyle(color: color, fontSize: 11)),
            if (showRecheck) ...[
              const SizedBox(width: 10),
              InkWell(onTap: () => _probe(forceRefresh: true), child: Text('↻ Re-check', style: TextStyle(color: c.accent, fontSize: 11))),
            ],
          ],
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(detail, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        ],
        if (cta != null) ...[
          const SizedBox(height: 6),
          cta,
        ],
      ],
    );
  }

  Widget _copyCta(BuildContext context, String command) {
    final c = AppColors.of(context);
    return Row(children: [
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: c.codeBlockBg, borderRadius: BorderRadius.circular(3), border: Border.all(color: c.borderColor)),
        child: Text(command, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: c.syntaxString)),
      )),
      const SizedBox(width: 6),
      ElevatedButton(
        onPressed: () => Clipboard.setData(ClipboardData(text: command)),
        child: const Text('Copy'),
      ),
    ]);
  }
}
```

- [ ] **Step 2: Verify analyze**

```bash
flutter analyze lib/features/providers/widgets/claude_cli_status_row.dart
```

- [ ] **Step 3: Commit**

```bash
dart format lib/features/providers/widgets/claude_cli_status_row.dart
git add lib/features/providers/widgets/claude_cli_status_row.dart
git commit -m "feat(providers): ClaudeCliStatusRow widget"
```

---

## Task 18: `AnthropicProviderCard` widget — switch with symmetric layout

**Files:**
- Create: `lib/features/providers/widgets/anthropic_provider_card.dart`

Composite card per spec §4.1: header with "Active: X" badge, active transport's panel, then toggle row with inactive transport's summary.

- [ ] **Step 1: Write the card**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../notifiers/providers_notifier.dart';
import 'api_key_card.dart';
import 'claude_cli_status_row.dart';

class AnthropicProviderCard extends ConsumerWidget {
  const AnthropicProviderCard({
    super.key,
    required this.apiKeyController,
    required this.initialApiKey,
  });

  final TextEditingController apiKeyController;
  final String initialApiKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final state = ref.watch(apiKeysProvider);
    return state.when(
      loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Failed to load: $e', style: TextStyle(color: c.error)),
      data: (s) {
        final isCli = s.anthropicTransport == 'cli';
        return Container(
          decoration: BoxDecoration(
            color: c.panelBackground,
            border: Border.all(color: isCli ? c.accent : c.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, isCli),
              _activePanel(context, s, isCli),
              _toggleRow(context, ref, s, isCli),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, bool isCli) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.dividerColor))),
      child: Row(
        children: [
          Text('Anthropic', style: TextStyle(color: c.headingText, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('● Active: ${isCli ? "Claude Code CLI" : "API Key"}',
              style: TextStyle(color: c.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _activePanel(BuildContext context, ApiKeysNotifierState s, bool isCli) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isCli
          ? const ClaudeCliStatusRow()
          : ApiKeyCard.inline(
              controller: apiKeyController,
              initialValue: initialApiKey,
              providerLabel: 'API Key',
            ),
    );
  }

  Widget _toggleRow(BuildContext context, WidgetRef ref, ApiKeysNotifierState s, bool isCli) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.deepBackground,
        border: Border(top: BorderSide(color: c.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route through Claude Code CLI',
                    style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                isCli
                    ? _inactiveApiKeySummary(context, s)
                    : const ClaudeCliStatusRow(),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Switch(
            value: isCli,
            onChanged: (v) => ref
                .read(apiKeysProvider.notifier)
                .setAnthropicTransport(v ? 'cli' : 'api-key'),
          ),
        ],
      ),
    );
  }

  Widget _inactiveApiKeySummary(BuildContext context, ApiKeysNotifierState s) {
    final c = AppColors.of(context);
    final masked = s.anthropic.isEmpty
        ? 'Not set'
        : '${s.anthropic.substring(0, s.anthropic.length.clamp(0, 10))}…';
    return Row(children: [
      Text('API key: ', style: TextStyle(color: c.textSecondary, fontSize: 11)),
      Text(masked, style: TextStyle(fontFamily: 'monospace', color: c.textMuted, fontSize: 11)),
      Text(' · saved · inactive', style: TextStyle(color: c.textMuted, fontSize: 11)),
    ]);
  }
}
```

Note: the `ApiKeyCard.inline` call assumes an existing `inline` constructor — if missing, add one to `api_key_card.dart` (short helper that renders just the input row without the provider header).

- [ ] **Step 2: Verify analyze**

```bash
flutter analyze lib/features/providers/widgets/anthropic_provider_card.dart
```

- [ ] **Step 3: Commit**

```bash
dart format lib/features/providers/widgets/anthropic_provider_card.dart
git add lib/features/providers/widgets/anthropic_provider_card.dart
git commit -m "feat(providers): AnthropicProviderCard with transport switch"
```

---

## Task 19: `ComingSoonProviderCard` widget

**Files:**
- Create: `lib/features/providers/widgets/coming_soon_provider_card.dart`

Disabled-switch variant for OpenAI (Codex — Phase 8) and Gemini (Gemini CLI — Phase 9).

- [ ] **Step 1: Write the widget**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'api_key_card.dart';

class ComingSoonProviderCard extends StatelessWidget {
  const ComingSoonProviderCard({
    super.key,
    required this.providerName,
    required this.cliName,
    required this.comingInPhase,
    required this.apiKeyController,
    required this.initialApiKey,
  });

  final String providerName;
  final String cliName;
  final String comingInPhase; // e.g. "Phase 8"
  final TextEditingController apiKeyController;
  final String initialApiKey;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.panelBackground,
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Text(providerName, style: TextStyle(color: c.headingText, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('● Active: API Key', style: TextStyle(color: c.textSecondary, fontSize: 11)),
              const SizedBox(width: 10),
              Text('· $cliName coming in $comingInPhase', style: TextStyle(color: c.textMuted, fontSize: 11)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ApiKeyCard.inline(
              controller: apiKeyController,
              initialValue: initialApiKey,
              providerLabel: 'API Key',
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyze**

```bash
flutter analyze lib/features/providers/widgets/coming_soon_provider_card.dart
```

- [ ] **Step 3: Commit**

```bash
dart format lib/features/providers/widgets/coming_soon_provider_card.dart
git add lib/features/providers/widgets/coming_soon_provider_card.dart
git commit -m "feat(providers): ComingSoonProviderCard for OpenAI/Gemini CLI placeholders"
```

---

## Task 20: Wire new cards into `ProvidersScreen`

**Files:**
- Modify: `lib/features/providers/providers_screen.dart`

- [ ] **Step 1: Replace the three ApiKeyCard instances**

Change:

```dart
ApiKeyCard(provider: AIProvider.openai, controller: ..., initialValue: _initialOpenAi),
ApiKeyCard(provider: AIProvider.anthropic, controller: ..., initialValue: _initialAnthropic),
ApiKeyCard(provider: AIProvider.gemini, controller: ..., initialValue: _initialGemini),
```

to:

```dart
ComingSoonProviderCard(
  providerName: 'OpenAI',
  cliName: 'Codex CLI',
  comingInPhase: 'Phase 8',
  apiKeyController: _controllers[AIProvider.openai]!,
  initialApiKey: _initialOpenAi,
),
const SizedBox(height: 6),
AnthropicProviderCard(
  apiKeyController: _controllers[AIProvider.anthropic]!,
  initialApiKey: _initialAnthropic,
),
const SizedBox(height: 6),
ComingSoonProviderCard(
  providerName: 'Gemini',
  cliName: 'Gemini CLI',
  comingInPhase: 'Phase 9',
  apiKeyController: _controllers[AIProvider.gemini]!,
  initialApiKey: _initialGemini,
),
```

Update imports.

- [ ] **Step 2: Verify analyze**

```bash
flutter analyze lib/features/providers/providers_screen.dart
```

- [ ] **Step 3: Launch app and visually verify**

```bash
flutter run -d macos
```

Navigate to Settings → Providers. Expected: three cards with the new layout. Anthropic card shows the switch; OpenAI and Gemini show "Coming soon" hints.

- [ ] **Step 4: Commit**

```bash
dart format lib/features/providers/providers_screen.dart
git add lib/features/providers/providers_screen.dart
git commit -m "feat(providers): wire new provider cards into Providers screen"
```

---

## Task 21: End-to-end manual QA

**Files:** none (manual)

Run through the spec's §11.3 QA checklist. Each item is a real user action.

- [ ] **QA.1 — CLI not installed**
  - Temporarily rename or `PATH`-hide `claude`.
  - Open Providers → Anthropic card.
  - Expected: switch is disabled; status row shows "not installed".

- [ ] **QA.2 — CLI installed, unauthenticated**
  - `claude auth logout` (if safe — user confirms first).
  - Open Providers.
  - Expected: switch disabled; status shows "not authenticated"; copy-to-clipboard button for `claude auth login`.

- [ ] **QA.3 — CLI authenticated, switch OFF**
  - `claude auth status` confirms authenticated.
  - Switch is enabled and OFF. API key input editable.
  - Expected: card header reads "Active: API Key".

- [ ] **QA.4 — Flip switch ON, send a message**
  - Flip the switch ON in Providers.
  - Start a new chat; send "Say hi".
  - Expected: Code Bench shows a permission card "Delegate to Claude Code CLI?".
  - Approve → transcript streams a text reply "via Claude Code" visible as a small tag if tool use happens.
  - Cancel → chat shows cancelled state, no CLI spawn.

- [ ] **QA.5 — Tool-using delegation**
  - Send "Read the first 3 lines of /etc/hosts and summarize."
  - Expected: one permission card; approve → tool card(s) with "via Claude Code" badge appear as receipts; final text summary arrives.

- [ ] **QA.6 — Stop button mid-stream**
  - Send a slow prompt (e.g., "count to 50 slowly").
  - Hit stop.
  - Expected: stream ends cleanly, no zombie processes (`ps aux | grep claude`).

- [ ] **QA.7 — Switch back to API key mid-session**
  - With an active chat using CLI, open Providers and flip switch OFF.
  - Send another message.
  - Expected: next message goes through API key path; UI doesn't break.

- [ ] **QA.8 — Final verification**

```bash
flutter analyze
dart format --set-exit-if-changed lib/ test/
flutter test
```

Expected: clean analyze, no format changes, all tests pass.

- [ ] **QA.9 — Create PR**

```bash
git push -u origin feat/2026-04-23-claude-cli-inference-transport
gh pr create --title "feat: Claude Code CLI as Anthropic inference transport (Phase 7)" --body-file docs/superpowers/plans/2026-04-23-claude-cli-inference-transport.md
```

---

## Self-review notes

- **Spec coverage (§3 in scope):** All seven in-scope items mapped to tasks. ClaudeCliRemoteDatasourceProcess → Task 9; CliRemoteDatasource abstract → Task 6; CliDetectionService → Task 7–8; Settings persistence → Task 11–12; Providers switch card → Task 18–20; Stream parser → Task 4–5; Permission gate → Task 15; Cancellation → Task 9 (cancel method) + Task 21 QA; Typed failure → Task 3; Error snackbars → deferred into Task 15's surface (if issues surface during QA, add a Task 22 for dedicated snackbar handlers).
- **No silent fallback:** Task 15's CLI branch emits a cancelled or error ChatMessage on denial/failure — it does not quietly fall back to the API key datasource.
- **Detection always shown:** `ClaudeCliStatusRow` (Task 17) is rendered inside both the active panel (when CLI is active) and the toggle row's inactive summary (when API key is active).
- **Types consistent:** `ToolEventSource.cliTransport` used in Tasks 14, 15, 16 uniformly. `CliDetection` and `CliAuthStatus` used in Tasks 2, 8, 17. `ClaudeCliFailure` used in Tasks 3, 9, 15.
- **Out-of-scope items confirmed absent:** No `--append-system-prompt`, no `--mcp-config`, no `--include-hook-events`, no silent API-key fallback, no Codex/Gemini concrete adapters.
