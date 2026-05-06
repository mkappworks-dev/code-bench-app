# Tool-Call Provider/Model Badges Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded `'via Claude Code'` badge on tool-call rows with two accurate badges (transport-explicit provider name + model id), and persist per-message attribution so the badges stay correct after a mid-session model switch.

**Architecture:** Add nullable `providerId`/`modelId` columns to `ChatMessages` (Drift schema v2) and matching fields on `ChatMessage` (freezed). Capture attribution at every assistant-message persistence site in `SessionService`. Render in `ToolCallRow` via labels passed from `MessageBubble`, gated only on whether the values are non-null.

**Tech Stack:** Flutter, Drift (SQLite), Riverpod, freezed, build_runner.

**Spec:** [docs/superpowers/specs/2026-05-06-tool-call-provider-model-badges-design.md](../specs/2026-05-06-tool-call-provider-model-badges-design.md)

**Worktree:** `.worktrees/fix/2026-05-06-tool-call-provider-model-badges` (already created)

---

## File Structure

### New files
- `lib/features/chat/widgets/provider_label.dart` — pure helper `providerLabelFor(String?) -> String?`
- `test/features/chat/widgets/provider_label_test.dart` — coverage for known ids, fallback, null

### Modified files
- `lib/data/_core/app_database.dart` — add columns, bump schema, add `MigrationStrategy`
- `lib/data/shared/chat_message.dart` — add `providerId`, `modelId` fields
- `lib/data/session/datasource/session_datasource_drift.dart` — read/write the new columns
- `lib/data/ai/models/provider_runtime_event.dart` — extend `ProviderInit` with optional `modelId`
- `lib/data/ai/datasource/codex_cli_datasource_process.dart` — emit `modelId` on `ProviderInit`
- `lib/data/ai/datasource/claude_cli_datasource_process.dart` — emit `modelId` on `ProviderInit`
- `lib/services/session/session_service.dart` — `_attribution` helper + plumbing through 6 persistence sites
- `lib/features/chat/widgets/message_bubble.dart` — pass labels to `ToolCallRow`
- `lib/features/chat/widgets/tool_call_row.dart` — accept labels, drop hardcoded badge
- `test/features/chat/widgets/tool_call_row_test.dart` — update to assert new contract

### Generated files (committed alongside their source)
- `lib/data/_core/app_database.g.dart`
- `lib/data/shared/chat_message.freezed.dart`
- `lib/data/shared/chat_message.g.dart`

---

## Task 1: Drift schema — add `providerId` and `modelId` columns

**Files:**
- Modify: `lib/data/_core/app_database.dart` (table at line 30, schemaVersion at line 207)

- [ ] **Step 1: Add nullable columns to `ChatMessages`**

In `lib/data/_core/app_database.dart`, add to the `ChatMessages` class (after the `timestamp` column):

```dart
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(ChatSessions, #sessionId)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get codeBlocksJson => text().withDefault(const Constant('[]'))();
  TextColumn get toolEventsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get providerId => text().nullable()();
  TextColumn get modelId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 2: Bump schema version and add migration strategy**

Replace lines 202–208 with:

```dart
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(chatMessages, chatMessages.providerId);
        await m.addColumn(chatMessages, chatMessages.modelId);
      }
    },
  );
}
```

- [ ] **Step 3: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: `app_database.g.dart` regenerates with new column accessors. No errors.

- [ ] **Step 4: Format + analyze**

Run: `dart format lib/data/_core/app_database.dart lib/data/_core/app_database.g.dart && flutter analyze lib/data/_core/`

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/data/_core/app_database.dart lib/data/_core/app_database.g.dart
git commit -m "feat(db): add providerId/modelId columns to chat_messages (schema v2)"
```

---

## Task 2: Add `providerId`/`modelId` to `ChatMessage` model

**Files:**
- Modify: `lib/data/shared/chat_message.dart`

- [ ] **Step 1: Add fields to the freezed class**

Replace the `ChatMessage` factory in `lib/data/shared/chat_message.dart` with:

```dart
@freezed
abstract class ChatMessage with _$ChatMessage {
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
    String? providerId,
    String? modelId,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}
```

- [ ] **Step 2: Regenerate freezed/json code**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: `chat_message.freezed.dart` and `chat_message.g.dart` regenerate. No errors.

- [ ] **Step 3: Format + analyze**

Run: `dart format lib/data/shared/chat_message.dart lib/data/shared/chat_message.freezed.dart lib/data/shared/chat_message.g.dart && flutter analyze lib/data/shared/`

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/data/shared/chat_message.dart lib/data/shared/chat_message.freezed.dart lib/data/shared/chat_message.g.dart
git commit -m "feat(model): add providerId/modelId to ChatMessage"
```

---

## Task 3: Drift datasource — read/write the new columns

**Files:**
- Modify: `lib/data/session/datasource/session_datasource_drift.dart` (around lines 124–141 for `persistMessage`, 168+ for `_messageFromRow`)

- [ ] **Step 1: Update `persistMessage` to write the new columns**

In `lib/data/session/datasource/session_datasource_drift.dart`, replace the `ChatMessagesCompanion(...)` block in `persistMessage` (lines 125–139):

```dart
Future<void> persistMessage(String sessionId, msg.ChatMessage message) async {
  await _db.sessionDao.insertMessage(
    ChatMessagesCompanion(
      id: Value(message.id),
      sessionId: Value(sessionId),
      role: Value(message.role.value),
      content: Value(message.content),
      codeBlocksJson: Value(
        jsonEncode(
          message.codeBlocks.map((b) => {'code': b.code, 'language': b.language, 'filename': b.filename}).toList(),
        ),
      ),
      toolEventsJson: Value(jsonEncode(message.toolEvents.map((e) => e.toJson()).toList())),
      timestamp: Value(message.timestamp),
      providerId: Value(message.providerId),
      modelId: Value(message.modelId),
    ),
  );
  await _db.sessionDao.updateSession(sessionId, ChatSessionsCompanion(updatedAt: Value(DateTime.now())));
}
```

- [ ] **Step 2: Update `_messageFromRow` to read the new columns**

Locate `_messageFromRow` (line 168). It uses `copyWith` or constructor-based reconstruction; add `providerId: row.providerId` and `modelId: row.modelId` to the `ChatMessage(...)` call. If the existing reconstruction logic is unclear, run:

```bash
sed -n '165,200p' lib/data/session/datasource/session_datasource_drift.dart
```

Then add the two fields wherever the `ChatMessage(` constructor is invoked inside `_messageFromRow`.

- [ ] **Step 3: Format + analyze**

Run: `dart format lib/data/session/datasource/session_datasource_drift.dart && flutter analyze lib/data/session/`

Expected: `No issues found!`

- [ ] **Step 4: Run existing session datasource tests if any**

Run: `flutter test test/data/session/ 2>&1 | tail -20`

Expected: All existing tests still pass (round-trip stays correct because new fields are nullable).

- [ ] **Step 5: Commit**

```bash
git add lib/data/session/datasource/session_datasource_drift.dart
git commit -m "feat(session-datasource): persist providerId/modelId on chat messages"
```

---

## Task 4: `providerLabelFor` helper + tests (TDD)

**Files:**
- Create: `lib/features/chat/widgets/provider_label.dart`
- Create: `test/features/chat/widgets/provider_label_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/chat/widgets/provider_label_test.dart`:

```dart
import 'package:code_bench_app/features/chat/widgets/provider_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('providerLabelFor', () {
    test('null id returns null', () {
      expect(providerLabelFor(null), isNull);
    });

    test('empty string returns null', () {
      expect(providerLabelFor(''), isNull);
    });

    test('"claude-cli" returns "Claude Code CLI"', () {
      expect(providerLabelFor('claude-cli'), 'Claude Code CLI');
    });

    test('"codex" returns "Codex CLI"', () {
      expect(providerLabelFor('codex'), 'Codex CLI');
    });

    test('"anthropic" returns "Anthropic API"', () {
      expect(providerLabelFor('anthropic'), 'Anthropic API');
    });

    test('"openai" returns "OpenAI API"', () {
      expect(providerLabelFor('openai'), 'OpenAI API');
    });

    test('"gemini" returns "Gemini API"', () {
      expect(providerLabelFor('gemini'), 'Gemini API');
    });

    test('"ollama" returns "Ollama"', () {
      expect(providerLabelFor('ollama'), 'Ollama');
    });

    test('"custom" returns "Custom"', () {
      expect(providerLabelFor('custom'), 'Custom');
    });

    test('unknown id returns the raw id (last-resort fallback)', () {
      expect(providerLabelFor('something-new'), 'something-new');
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/features/chat/widgets/provider_label_test.dart`

Expected: FAIL with import error / `providerLabelFor` not defined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/chat/widgets/provider_label.dart`:

```dart
String? providerLabelFor(String? providerId) {
  if (providerId == null || providerId.isEmpty) return null;
  return switch (providerId) {
    'claude-cli' => 'Claude Code CLI',
    'codex' => 'Codex CLI',
    'anthropic' => 'Anthropic API',
    'openai' => 'OpenAI API',
    'gemini' => 'Gemini API',
    'ollama' => 'Ollama',
    'custom' => 'Custom',
    _ => providerId,
  };
}
```

- [ ] **Step 4: Run test, verify it passes**

Run: `flutter test test/features/chat/widgets/provider_label_test.dart`

Expected: All 10 tests pass.

- [ ] **Step 5: Format + analyze**

Run: `dart format lib/features/chat/widgets/provider_label.dart test/features/chat/widgets/provider_label_test.dart && flutter analyze lib/features/chat/widgets/provider_label.dart test/features/chat/widgets/provider_label_test.dart`

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/widgets/provider_label.dart test/features/chat/widgets/provider_label_test.dart
git commit -m "feat(chat): add providerLabelFor helper with explicit transport labels"
```

---

## Task 5: Extend `ProviderInit` event with optional `modelId`

**Files:**
- Modify: `lib/data/ai/models/provider_runtime_event.dart` (lines 9–12)

- [ ] **Step 1: Add the optional `modelId` field**

Replace the `ProviderInit` class in `lib/data/ai/models/provider_runtime_event.dart`:

```dart
class ProviderInit extends ProviderRuntimeEvent {
  const ProviderInit({required this.provider, this.modelId});
  final String provider;
  final String? modelId;
}
```

- [ ] **Step 2: Format + analyze**

Run: `dart format lib/data/ai/models/provider_runtime_event.dart && flutter analyze lib/data/ai/`

Expected: `No issues found!` (existing call sites still compile because `modelId` is optional).

- [ ] **Step 3: Commit**

```bash
git add lib/data/ai/models/provider_runtime_event.dart
git commit -m "feat(provider-event): allow ProviderInit to carry modelId"
```

---

## Task 6: Codex CLI — emit `modelId` on `ProviderInit`

**Files:**
- Modify: `lib/data/ai/datasource/codex_cli_datasource_process.dart` (around line 145 for the `ProviderInit` emit; around lines 609–625 for `_initialize`)

- [ ] **Step 1: Inspect what Codex returns from `initialize`**

Run: `grep -n "userAgent\|_version\|initialize" lib/data/ai/datasource/codex_cli_datasource_process.dart | head -10`

Confirm that `_initialize()` already extracts `_version` from the `userAgent` field. We'll piggyback on that — the model isn't explicitly returned by `initialize`, so we use `_version` (the codex CLI version, e.g. `'0.128.0'`) as a stand-in for `modelId`. **NOTE:** Codex doesn't expose the model server-side until `turn/start` returns; for v1 we accept that the model badge may show codex CLI version rather than the OpenAI model id. If we want the actual model id, capture `result.model` from `turn/start` response (if present) — out of scope for this task.

- [ ] **Step 2: Pass `_version` to `ProviderInit`**

Locate the line that emits `ProviderInit` (around line 145) — change from:

```dart
_streamController?.add(ProviderInit(provider: id));
```

To:

```dart
_streamController?.add(ProviderInit(provider: id, modelId: _version));
```

The emit happens AFTER `_initialize()` runs, so `_version` is populated by then.

- [ ] **Step 3: Format + analyze**

Run: `dart format lib/data/ai/datasource/codex_cli_datasource_process.dart && flutter analyze lib/data/ai/datasource/codex_cli_datasource_process.dart`

Expected: `No issues found!`

- [ ] **Step 4: Re-run codex CLI tests**

Run: `flutter test test/data/ai/datasource/codex_cli_auth_test.dart test/data/ai/datasource/codex_cli_turn_start_params_test.dart 2>&1 | tail -10`

Expected: All tests pass (we didn't touch tested logic).

- [ ] **Step 5: Commit**

```bash
git add lib/data/ai/datasource/codex_cli_datasource_process.dart
git commit -m "feat(codex-cli): include CLI version as modelId on ProviderInit"
```

---

## Task 7: Claude CLI — emit `modelId` on `ProviderInit`

**Files:**
- Modify: `lib/data/ai/datasource/claude_cli_datasource_process.dart` (around line 122 for the `ProviderInit` emit)

- [ ] **Step 1: Inspect what Claude CLI returns at session init**

Run: `grep -n "model\|ProviderInit\|sessionInit\|metadata" lib/data/ai/datasource/claude_cli_datasource_process.dart | head -20`

Determine whether the Claude Code CLI's first JSON line includes a `model` field. If it does, capture it before emitting `ProviderInit`. If it doesn't (or only emits `version`), pass null (the badge will gracefully hide).

- [ ] **Step 2: Capture and emit the model**

Locate the line at ~122 (`controller.add(ProviderInit(provider: id));`).

If Claude CLI's session-init JSON has `model`: parse it from the same JSON frame that's already being processed near line 122 and pass it through:

```dart
controller.add(ProviderInit(provider: id, modelId: parsedModel));
```

If Claude CLI does NOT expose model at init: leave the emit as-is (or pass `modelId: null` explicitly for clarity). Document in a single-line WHY comment per [CLAUDE.md](../../../CLAUDE.md):

```dart
// Claude CLI does not surface a model id at session init; modelId stays null.
controller.add(ProviderInit(provider: id));
```

- [ ] **Step 3: Format + analyze**

Run: `dart format lib/data/ai/datasource/claude_cli_datasource_process.dart && flutter analyze lib/data/ai/datasource/claude_cli_datasource_process.dart`

Expected: `No issues found!`

- [ ] **Step 4: Re-run Claude CLI tests**

Run: `flutter test test/data/ai/datasource/claude_cli_auth_test.dart test/data/ai/datasource/claude_cli_stream_parser_test.dart 2>&1 | tail -10`

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/ai/datasource/claude_cli_datasource_process.dart
git commit -m "feat(claude-cli): pass modelId through ProviderInit when available"
```

---

## Task 8: `SessionService` — `_attribution` helper + plumb 6 sites

**Files:**
- Modify: `lib/services/session/session_service.dart` (sites at lines 123, 186, 225, 311, 326, 332; new helper added near top of class)

- [ ] **Step 1: Add the `_attribution` helper**

Inside the `SessionService` class in `lib/services/session/session_service.dart`, add a private helper. Find a suitable spot near other helpers (above `streamUserTurn` is fine):

```dart
({String? providerId, String? modelId}) _attribution({
  AIModel? model,
  String? cliProviderId,
  String? cliModelId,
}) {
  if (cliProviderId != null) return (providerId: cliProviderId, modelId: cliModelId);
  if (model != null) return (providerId: model.provider.name, modelId: model.modelId);
  return (providerId: null, modelId: null);
}
```

- [ ] **Step 2: User-message persistence — leave NULL**

At line 115–123 in `session_service.dart`, the user message is constructed via:

```dart
final userMsg = ChatMessage(
  id: _uuid.v4(),
  sessionId: sessionId,
  role: MessageRole.user,
  content: userInput,
  timestamp: DateTime.now(),
);
```

No change — both new fields default to `null`, which is correct for user messages.

- [ ] **Step 3: Plain-text final (line 218–224) — capture from `model`**

Replace the `finalMsg` construction in the plain-text path:

```dart
final attribution = _attribution(model: model);
final finalMsg = ChatMessage(
  id: assistantId,
  sessionId: sessionId,
  role: MessageRole.assistant,
  content: buffer.toString(),
  timestamp: DateTime.now(),
  providerId: attribution.providerId,
  modelId: attribution.modelId,
);
await _session.persistMessage(sessionId, finalMsg);
yield finalMsg;
```

The streaming snapshot at line 208–215 also needs the fields so `MessageBubble` can render badges during streaming. Add the same two fields to that yield as well.

- [ ] **Step 4: Agent loop final (line 186) — capture from `model`**

The agent loop yields `ChatMessage` objects from `_agent.runAgenticTurn(...)`. We need those messages to carry attribution. Two options:

**(a)** Modify `_agent.runAgenticTurn` to populate the fields itself (cleanest). Find the file (likely `lib/services/agent/...`) and pass `model.provider.name` + `model.modelId` into every assistant `ChatMessage` it constructs.

**(b)** Wrap in `SessionService`: copy the message with attribution before persisting:

```dart
await for (final msg in _agent.runAgenticTurn(...)) {
  final stamped = msg.role == MessageRole.assistant
      ? msg.copyWith(providerId: model.provider.name, modelId: model.modelId)
      : msg;
  if (!stamped.isStreaming) {
    await _session.persistMessage(sessionId, stamped);
  }
  yield stamped;
}
```

Use **(b)** unless `runAgenticTurn` has very few `ChatMessage(...)` construction sites (in which case (a) is preferred). Run `grep -n "ChatMessage(" lib/services/agent/` to decide.

- [ ] **Step 5: Provider stream — `_streamProvider` (lines 234–334)**

In `_streamProvider`, capture provider/model from the first `ProviderInit` event. Track them in two locals:

```dart
String? streamProviderId = ds.id;
String? streamModelId;
```

Update the `ProviderInit` case (around line 269):

```dart
case ProviderInit(:final provider, :final modelId):
  streamProviderId = provider;
  streamModelId = modelId;
  dLog('[SessionService] provider $provider started (model=$modelId)');
```

Update `snapshot()` (line 246–254) to include the fields:

```dart
ChatMessage snapshot({bool streaming = true}) => ChatMessage(
  id: assistantId,
  sessionId: sessionId,
  role: MessageRole.assistant,
  content: contentBuffer.toString(),
  timestamp: DateTime.now(),
  isStreaming: streaming,
  toolEvents: List.unmodifiable(toolEvents),
  providerId: streamProviderId,
  modelId: streamModelId,
);
```

The mid-stream-failure (line 311) and final (line 332) sites use `snapshot(...)`, so they pick up the attribution automatically.

For the interrupted message (lines 317–326), build it with attribution explicitly:

```dart
final interruptedMsg = ChatMessage(
  id: assistantId,
  sessionId: sessionId,
  role: MessageRole.interrupted,
  content: contentBuffer.isEmpty ? '[interrupted]' : '${contentBuffer.toString()}\n[interrupted]',
  timestamp: DateTime.now(),
  toolEvents: List.unmodifiable(toolEvents),
  providerId: streamProviderId,
  modelId: streamModelId,
);
```

- [ ] **Step 6: Format + analyze**

Run: `dart format lib/services/session/session_service.dart && flutter analyze lib/services/session/session_service.dart`

Expected: `No issues found!`

If this triggers analyzer errors in `_agent.runAgenticTurn` (option a from Step 4), fix those files too — list them, format/analyze each.

- [ ] **Step 7: Run existing service-layer tests**

Run: `flutter test test/services/session/ 2>&1 | tail -15`

Expected: All existing tests pass. (None should fail because we only ADD attribution to existing flows.)

- [ ] **Step 8: Commit**

```bash
git add lib/services/session/session_service.dart
# also any agent files modified in Step 4
git commit -m "feat(session-service): stamp providerId/modelId on assistant messages"
```

---

## Task 9: `ToolCallRow` — drop hardcoded badge, accept labels (TDD)

**Files:**
- Modify: `lib/features/chat/widgets/tool_call_row.dart`
- Modify: `test/features/chat/widgets/tool_call_row_test.dart`

- [ ] **Step 1: Read the existing widget test to understand current shape**

Run: `cat test/features/chat/widgets/tool_call_row_test.dart`

Note the `pumpWidget` boilerplate so the new tests match style.

- [ ] **Step 2: Add new failing tests**

Append to `test/features/chat/widgets/tool_call_row_test.dart` (inside the existing `group` or a new one):

```dart
group('ToolCallRow provider/model badges', () {
  ToolEvent makeEvent() => const ToolEvent(
    id: 'evt1',
    type: 'provider_tool',
    toolName: 'read_file',
    status: ToolStatus.success,
    source: ToolEventSource.cliTransport,
  );

  testWidgets('renders both badges when both labels are non-null', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ToolCallRow(
          event: makeEvent(),
          providerLabel: 'Codex CLI',
          modelLabel: 'gpt-5',
        ),
      ),
    ));
    expect(find.text('Codex CLI'), findsOneWidget);
    expect(find.text('gpt-5'), findsOneWidget);
  });

  testWidgets('renders only provider badge when modelLabel is null', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ToolCallRow(
          event: makeEvent(),
          providerLabel: 'Claude Code CLI',
          modelLabel: null,
        ),
      ),
    ));
    expect(find.text('Claude Code CLI'), findsOneWidget);
    expect(find.text('gpt-5'), findsNothing);
  });

  testWidgets('renders no badges when both labels are null', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ToolCallRow(
          event: makeEvent(),
          providerLabel: null,
          modelLabel: null,
        ),
      ),
    ));
    expect(find.text('Codex CLI'), findsNothing);
    expect(find.text('gpt-5'), findsNothing);
    expect(find.text('via Claude Code'), findsNothing);
  });

  testWidgets('hardcoded "via Claude Code" string is gone (regression guard)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ToolCallRow(event: makeEvent()),
      ),
    ));
    expect(find.text('via Claude Code'), findsNothing);
  });
});
```

If the existing test file already imports `ToolEvent`/`ToolStatus`/`ToolEventSource`, reuse those imports. Otherwise add:

```dart
import 'package:code_bench_app/data/session/models/tool_event.dart';
import 'package:code_bench_app/features/chat/widgets/tool_call_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
```

- [ ] **Step 3: Run tests, verify they fail**

Run: `flutter test test/features/chat/widgets/tool_call_row_test.dart 2>&1 | tail -15`

Expected: New tests fail (widget doesn't accept `providerLabel`/`modelLabel` yet).

- [ ] **Step 4: Update `ToolCallRow` widget**

In `lib/features/chat/widgets/tool_call_row.dart`:

(a) Update the constructor (lines 10–12):

```dart
class ToolCallRow extends StatefulWidget {
  const ToolCallRow({
    super.key,
    required this.event,
    this.providerLabel,
    this.modelLabel,
  });
  final ToolEvent event;
  final String? providerLabel;
  final String? modelLabel;
  ...
}
```

(b) Replace lines 85–96 (the existing CLI-transport gate + hardcoded badge) with:

```dart
if (widget.providerLabel != null) ...[
  const SizedBox(width: 8),
  _BadgeChip(label: widget.providerLabel!, color: c.accent),
],
if (widget.modelLabel != null) ...[
  const SizedBox(width: 4),
  _BadgeChip(label: widget.modelLabel!, color: c.accent),
],
```

(c) Add a `_BadgeChip` widget at the bottom of the file (above `_ExpandableOutput` is fine):

```dart
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, letterSpacing: 0.3)),
    );
  }
}
```

- [ ] **Step 5: Run tests, verify they pass**

Run: `flutter test test/features/chat/widgets/tool_call_row_test.dart 2>&1 | tail -15`

Expected: All tests (existing + new 4) pass.

- [ ] **Step 6: Format + analyze**

Run: `dart format lib/features/chat/widgets/tool_call_row.dart test/features/chat/widgets/tool_call_row_test.dart && flutter analyze lib/features/chat/widgets/ test/features/chat/widgets/`

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/features/chat/widgets/tool_call_row.dart test/features/chat/widgets/tool_call_row_test.dart
git commit -m "feat(chat): two-badge tool-call row driven by providerLabel/modelLabel"
```

---

## Task 10: `MessageBubble` — pass labels to `ToolCallRow`

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart` (around line 240 where `ToolCallRow` is constructed)

- [ ] **Step 1: Inspect the current call site**

Run: `sed -n '230,250p' lib/features/chat/widgets/message_bubble.dart`

Identify what `event` and `widget.message` are in scope at that point.

- [ ] **Step 2: Pass labels via `providerLabelFor`**

Replace the `ToolCallRow(event: event)` line with:

```dart
ToolCallRow(
  event: event,
  providerLabel: providerLabelFor(widget.message.providerId),
  modelLabel: widget.message.modelId,
),
```

Add the import at the top of the file:

```dart
import 'provider_label.dart';
```

- [ ] **Step 3: Format + analyze**

Run: `dart format lib/features/chat/widgets/message_bubble.dart && flutter analyze lib/features/chat/widgets/message_bubble.dart`

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/widgets/message_bubble.dart
git commit -m "feat(chat): wire providerId/modelId from message into ToolCallRow"
```

---

## Task 11: Final verification

- [ ] **Step 1: Full format pass**

Run: `dart format lib/ test/`

Expected: `Formatted N files (0 changed)` — anything formatted at this point is a missed step earlier; commit them with a `chore: dart format` commit if any.

- [ ] **Step 2: Full analyzer pass**

Run: `flutter analyze 2>&1 | tail -5`

Expected: `No issues found!`

- [ ] **Step 3: Full test suite**

Run: `flutter test 2>&1 | tail -10`

Expected: All tests pass (existing + new tests from Task 4 and Task 9).

- [ ] **Step 4: Confirm no `'via Claude Code'` literal remains**

Run: `grep -rn "via Claude Code" lib/ test/ 2>/dev/null`

Expected: No matches.

- [ ] **Step 5: Run the macOS app and smoke-test**

Run: `flutter run -d macos`

Manual verification:
- Open a Codex CLI session, send a turn that triggers a tool call. Tool-call row shows `[Codex CLI]` `[<codex-version-or-model>]` badges.
- Open a Claude Code CLI session, send a turn that triggers a tool call. Row shows `[Claude Code CLI]` plus model badge if Claude CLI surfaces one (else just provider).
- Open a custom Anthropic-API session (act mode), trigger a tool call. Row shows `[Anthropic API]` + the model id.
- Switch model mid-session, send a new turn. New tool-call rows show the new model. Old rows keep the old model.

(Per `feedback_smoke_test_launch` memory: don't `open` the .app — let the user launch it.)

- [ ] **Step 6: Commit any final formatting**

If `git status` shows any untracked or modified files (e.g. unformatted regen artifacts):

```bash
git add -A  # or specific files
git commit -m "chore: dart format"
```

- [ ] **Step 7: Push branch and open PR**

```bash
git push -u origin fix/2026-05-06-tool-call-provider-model-badges
gh pr create --title "fix(chat): two-badge tool-call attribution (provider + model)" --body "$(cat <<'EOF'
## Summary
- Replaces hardcoded `via Claude Code` badge with two accent badges: explicit transport name + model id
- Adds nullable `providerId`/`modelId` columns to `ChatMessages` (Drift schema v2) and matching fields on `ChatMessage`
- Stamps attribution at every assistant-message persistence site so mid-session model switches stay accurate per turn
- Drops the `cliTransport` gate — visibility is now driven by whether attribution is known at write-time

## Test plan
- [ ] `dart format lib/ test/` — clean
- [ ] `flutter analyze` — clean
- [ ] `flutter test` — all green
- [ ] Codex CLI turn shows `[Codex CLI]` + model badges
- [ ] Claude Code CLI turn shows `[Claude Code CLI]` + (model if surfaced) badges
- [ ] Custom-API (Anthropic act mode) turn shows `[Anthropic API]` + model badges
- [ ] Mid-session model switch attributes new turns to new model; old turns retain old model

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-review notes

**Spec coverage:** Each spec section maps to at least one task — schema (Task 1), model (Task 2), datasource read/write (Task 3), helper (Task 4), event extension (Task 5), CLI emission (Tasks 6–7), service plumbing (Task 8), widget (Task 9), bubble pass-through (Task 10), verification (Task 11). All 6 acceptance criteria covered in Task 11 Step 5.

**Placeholder scan:** Step 4 of Task 8 has a small judgement call ("decide between (a) or (b) based on grep result") — this is a real fork in the work, not a placeholder; the deciding command is given.

**Type consistency:** Field names `providerId` / `modelId` are consistent across schema, model, datasource, service, widget. Helper is `providerLabelFor` (single point); badge widget is `_BadgeChip`. `_attribution` returns a record with named fields matching the model.

**Risks acknowledged in spec:**
- CLI may not surface a model id → handled in Tasks 6–7 (graceful null).
- Pre-release migration acceptance → schema bump done with proper `MigrationStrategy` even though we accept potential dev-DB wipes.
