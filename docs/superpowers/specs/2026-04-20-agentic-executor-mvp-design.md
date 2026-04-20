# Agentic Executor — MVP Spec

## Goal

Turn `ChatMode.act` from a UI toggle into a working agentic loop. When `act` mode is selected and the active provider is OpenAI-compatible (Custom / LMStudio / any endpoint that supports OpenAI function-calling), the chat loop sends tool definitions with each request, detects tool calls in the stream, executes them against the active project's filesystem, and feeds results back to the model — continuing until the model stops calling tools or the per-turn iteration cap is reached.

This unblocks the user's original pain point: "I'm using LMStudio and the app can't edit files."

---

## Scope

**In scope:**
- One provider: Custom / OpenAI-compatible endpoint (covers LMStudio, OpenAI itself, Ollama via its OpenAI-compat shim if enabled, and any other server speaking the same schema).
- Four tools: `read_file`, `list_dir`, `write_file`, `str_replace`.
- Turn-taking loop capped at 10 iterations per user turn; soft cap (see §5 "Iteration cap behavior").
- Live streaming of tool events (`running` → `success` / `error` / `cancelled`) into the existing `ChatMessage.toolEvents` list.
- Cancellation: user hits stop → loop cancels at the next tool boundary (current in-flight tool is allowed to finish).
- All three `ChatPermission` modes work: `readOnly`, `askBefore`, `fullAccess`.
- Inline approval UI for `askBefore` on destructive tools, reusing the `AskUserQuestionCard` visual pattern.
- One new system prompt applied only when `ChatMode.act` is the active mode.

**Out of scope (tracked as follow-up specs):**
- Anthropic / Gemini / native-OpenAI tool formats. The MVP uses only the OpenAI-compatible shape via `CustomRemoteDatasourceDio`. Other providers' tool modes (Anthropic `tool_use` blocks, Gemini `functionDeclarations`) get their own spec.
- `run_command` and `glob` tools — whole separate spec. `run_command` in particular needs sandboxing, timeout, cancel-signal handling, and an allow-list design that warrants its own brainstorm.
- Drift persistence of tool events across app restarts. Tool events live in the in-memory `ChatMessage.toolEvents` for the duration of the session; reloading an archived session shows message text but loses event detail.
- Multi-tool parallel execution. MVP runs tool calls sequentially even when the model emits multiple in one round.
- Live streaming of `str_replace` diff previews inside the tool row.
- "Allow always for this session" escalation in the approval card. MVP is single-shot `[Allow] [Deny]`.

---

## Architecture

```
Widget: ChatInputBar, MessageBubble          (no changes except MessageBubble.askQuestion-like card rendering)
Notifier: ChatMessagesNotifier.sendMessage   (no API change — yields same ChatMessage stream, just with tool events)
Service: SessionService.sendAndStream        (modified — branches on ChatMode.act)
Service: AgentService                        (NEW — owns the turn-taking loop)
Service: CodingToolsService                  (NEW — dispatches tool name → handler)
Repository: CodingToolsRepository            (NEW — filesystem I/O interface)
Repository: AIRepository.streamMessageWithTools  (NEW method — returns Stream<StreamEvent>)
Datasource: CustomRemoteDatasourceDio.streamWithTools  (NEW — builds OpenAI tool-call SSE body + parses tool_calls deltas)
Datasource: CodingToolsDatasourceIo          (NEW — raw read/list/write via dart:io)
```

Files added under these paths (following existing naming conventions in CLAUDE.md):

```
lib/
├── data/
│   ├── ai/
│   │   └── models/
│   │       └── stream_event.dart                 NEW (freezed sealed)
│   └── coding_tools/                             NEW domain
│       ├── coding_tools_exceptions.dart
│       ├── datasource/
│       │   └── coding_tools_datasource_io.dart
│       ├── models/
│       │   ├── coding_tool_definition.dart
│       │   ├── coding_tool_call.dart
│       │   └── coding_tool_result.dart
│       └── repository/
│           ├── coding_tools_repository.dart
│           └── coding_tools_repository_impl.dart
├── features/
│   └── chat/
│       ├── notifiers/
│       │   ├── agent_cancel_notifier.dart        NEW
│       │   ├── agent_permission_request_notifier.dart  NEW
│       │   └── agent_failure.dart                NEW (freezed sealed)
│       └── widgets/
│           ├── permission_request_card.dart      NEW
│           └── iteration_cap_banner.dart         NEW
└── services/
    ├── agent/
    │   └── agent_service.dart                    NEW
    └── coding_tools/
        └── coding_tools_service.dart             NEW
```

Modified files:

```
lib/services/session/session_service.dart         (branch on ChatMode.act)
lib/data/ai/datasource/custom_remote_datasource_dio.dart  (add streamWithTools)
lib/data/ai/repository/ai_repository_impl.dart    (add streamMessageWithTools)
lib/features/chat/notifiers/chat_messages_notifier.dart   (add clearIterationCap + continueAgenticTurn methods)
lib/features/chat/widgets/message_bubble.dart     (render permission_request_card + iteration_cap_banner when present)
lib/features/chat/widgets/tool_call_row.dart      (visual polish for ToolStatus.cancelled)
```

`ToolEvent`'s existing `ToolStatus.cancelled` enum value is already wired end-to-end — the loop sets it when cancellation or the iteration cap fires. Only the `ToolCallRow` render needs polish; the data model and cancellation plumbing are unchanged.

---

## Data model: `StreamEvent`

A new freezed sealed class in `lib/data/ai/models/stream_event.dart`:

```dart
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
  const factory StreamEvent.finish({required String reason}) = StreamFinish;
}
```

`reason` is the OpenAI `finish_reason` — typically `"stop"`, `"tool_calls"`, or `"length"`.

---

## The loop (`AgentService.runAgenticTurn`)

```dart
Stream<ChatMessage> runAgenticTurn({
  required String sessionId,
  required List<ChatMessage> history,
  required String userInput,
  required AIModel model,
  required ChatPermission permission,
  required String projectPath,
}) async* { ... }
```

Pseudocode:

```
assistantId = uuid
textBuffer  = ""
events      = []           // List<ToolEvent>
iteration   = 0
cancelled   = false

loop:
  iteration++
  requestMessages = translateHistory(history, [assistantTurnSoFar(textBuffer, events)])
  tools = permission == readOnly
            ? [read_file, list_dir]
            : [read_file, list_dir, write_file, str_replace]

  pendingCalls = []   // accumulated during this round's stream

  async for event in aiRepo.streamMessageWithTools(messages: requestMessages, tools: tools, model: model):
    match event:
      textDelta(t):
        textBuffer += t
        yield msg(textBuffer, events, isStreaming: true)

      toolCallStart(id, name):
        pendingCalls.append({id, name, argsBuffer: ""})
        events.append(ToolEvent(id: id, toolName: name, status: running, input: {}))
        yield msg(textBuffer, events, isStreaming: true)

      toolCallArgsDelta(id, fragment):
        pendingCalls[id].argsBuffer += fragment
        // no yield — silent accumulation

      toolCallEnd(id):
        call = pendingCalls[id]
        call.args = jsonDecode(call.argsBuffer) catch → {}
        events[id].input = call.args
        yield msg(textBuffer, events, isStreaming: true)

      finish(reason):
        break

  if reason == "stop":
    yield msg(textBuffer, events, isStreaming: false)
    return

  if reason != "tool_calls":  // "length" or unknown
    emit AgentFailure.streamAbortedUnexpectedly(reason)
    return

  if ref.read(agentCancelProvider):
    events[pending] → cancelled
    textBuffer += "\n\n_Cancelled by user._"
    yield final msg, isStreaming: false
    return

  if iteration == 10:
    events[pending] → cancelled
    yield final msg, isStreaming: false, iterationCapReached: true
    return

  for call in pendingCalls:
    if permission == readOnly and call.name in {write_file, str_replace}:
      // can't happen — tools weren't sent — but defensive
      events[call.id] → error("read-only mode")
      continue

    if permission == askBefore and call.name in {write_file, str_replace}:
      approved = await waitForApproval(call, projectPath)
      if !approved:
        events[call.id] → cancelled with error "Denied by user"
        history.append(toolResult(call.id, "User denied this change."))
        yield msg(textBuffer, events, isStreaming: true)
        continue

    result = await codingToolsService.execute(call.name, call.args, projectPath, sessionId, assistantId)
    events[call.id] → success(result.output) or error(result.error)
    history.append(toolResult(call.id, result.output ?? result.error))
    yield msg(textBuffer, events, isStreaming: true)
```

Key points:

- Tool events are appended as the stream emits `tool_call_start`, so the user sees the row appear with `status: running` before the app even starts executing the tool.
- The `input` map on `ToolEvent` is populated only after `toolCallEnd` (the full args JSON arrived). This means the row renders "running, no args" momentarily — acceptable for MVP; a later polish spec can stream partial args.
- Each tool execution is a single `await` — the loop doesn't parallelize even if the model emitted multiple calls in one round.
- On cancel, the loop returns `isStreaming: false` and relies on the UI's existing cancel-button wiring (same `activeMessageIdProvider` that already shows "working for Xs").

---

## Iteration cap behavior

When `iteration == 10` at a `tool_calls` finish boundary:

1. Any `ToolEvent` still in `running` state flips to `cancelled`.
2. The final `ChatMessage` is yielded with `isStreaming: false` and a new nullable field `iterationCapReached: true` (see §"ChatMessage addition" below).
3. The assistant bubble renders an inline amber-tinted banner — `IterationCapBanner` — below its tool rows. No prose is appended to `textBuffer`; the banner is the entire UX for the cap state.

### `IterationCapBanner` widget

New widget in `lib/features/chat/widgets/iteration_cap_banner.dart`. Layout (left → right):

| Region | Contents |
|---|---|
| Icon | `⏸` in `c.warning` |
| Message | **"Paused at 10-step limit."** Subline: "Run 10 more steps, or send a new message to redirect." |
| Action | `[Continue]` button — amber-tinted fill, `c.warning` text |

**Three states:**

1. **Active (pending):** amber border (`c.warning` at 40% alpha), amber tint background, `[Continue]` button clickable. Hover lightens the button. This is the default when a message carries `iterationCapReached: true` and no later user message exists for this session.
2. **Consumed (user clicked `Continue`):** the banner is immediately removed from render. The click handler (`continueAgenticTurn` — see below) writes `iterationCapReached: false` back onto the capped message via `ChatMessagesNotifier.clearIterationCap(messageId)` *before* re-entering the loop. The widget then sees the flag cleared and renders nothing; users see the new streaming bubble appear below, not a stale banner.
3. **Dismissed (user sent a new message instead):** banner stays in place on the old bubble but drains to neutral grey — `c.textMuted` color, `rgba(255,255,255,0.02)` background, hairline border. Subline changes to "Continued via new message." Button remains visible but inert (neutral grey outline, no hover, `onPressed: null`). Rationale: keeping the button present in disabled form preserves visual parity so the cap event is still recognizable when scrolling back through history, but its disabled styling makes it unmistakable that the offer expired.

**Dismissal detection:** the banner's active/dismissed state is a pure function of "is this the most recent message in the session, AND is there no user message after it?" Computed in `_AssistantBubble` via `ref.watch(lastMessageIdProvider) == message.id && message.iterationCapReached`. No separate "dismissed" flag is persisted — dismissal is always derivable from message ordering. (Also avoids a tangled write path: sending a new user message is already the existing code path; it doesn't need to reach back and mutate a prior message's flag.)

**Click handler:** tapping `[Continue]` calls `chatActionsProvider.notifier.continueAgenticTurn(messageId)`, which:

1. Calls `clearIterationCap(messageId)` — a new single-field mutation on `ChatMessagesNotifier` that flips the capped message's `iterationCapReached` back to `false` and persists via Drift. This collapses the banner before re-entry so the user doesn't briefly see two banners.
2. Re-enters `AgentService.runAgenticTurn` with the same history (including the capped assistant message and its tool events). No new user message is appended.
3. The iteration counter resets to 0 — the next 10 iterations are "fresh."
4. The model naturally resumes because the wire-translation layer unpacks the capped assistant message into its `tool_calls` + `tool_result` pairs; the model sees "here's where I stopped" and continues.

### ChatMessage addition

In addition to `pendingPermissionRequest` (see §"Permission gating"), one more nullable field:

```dart
@Default(false) bool iterationCapReached,
```

Additive, defaults false — no migration impact. Persisted to Drift along with the rest of the message.

---

## Permission gating

Behavior per `ChatPermission` value:

| Permission | `read_file`, `list_dir` | `write_file`, `str_replace` |
|---|---|---|
| `readOnly` | Sent to model; executed normally | **Not sent to model** (filtered out of the tool list). If the model manages to call one anyway, handler rejects with `"Read-only mode active"` |
| `askBefore` | Sent; executed normally | Sent; execution pauses on a per-call approval card (see below) |
| `fullAccess` | Sent; executed normally | Sent; executed normally |

### Approval card (`askBefore` only)

A new widget `PermissionRequestCard` rendered inline when the loop is paused waiting for approval. Wiring mirrors `AskUserQuestionCard`; visual is warning-tinted (amber border + `c.warning` icon) so users reading the stream can spot a pending approval without having to parse it.

**Layout (top → bottom), collapsed (default):**
1. Title row: `⚠ Allow <tool_name>?` (tool name in an amber-tinted inline code badge).
2. Summary line, monospace, muted: `"<path> · <one-liner>"` where the one-liner is:
   - `str_replace`: `"1 match"`
   - `write_file` creating: `"New file · <N> bytes"`
   - `write_file` overwriting: `"Overwrite · <oldBytes> → <newBytes>"`
3. Disclosure row: a small `Show diff ▾` text button (muted, 10px, `c.textMuted`) aligned left — shown **only when a preview can be built** (see §"Preview availability" below). Tapping toggles to `Hide diff ▴` and expands the preview block inline. State is local to the card (`StatefulWidget`, `_expanded: bool`), resets when the card is rebuilt for the next request.
4. Button row, right-aligned: `[Deny]` (neutral outline) · `[Allow]` (primary, success-tinted).

**Layout expanded (after tapping `Show diff ▾`):** same as above with the preview block inserted between the disclosure row and the button row.

**Preview block contents:**
- `str_replace`: two-sided inline diff — `- <old_str>` in error red, `+ <new_str>` in success green. Truncated to the first 3 lines of each side with a `"…"` marker if longer. Uses monospace font, small (10–11px), in the existing inline-code-block-style container.
- `write_file` (new file): first 5 lines of `content` with a `"…"` marker if longer. Header: `Preview (new file)`.
- `write_file` (overwrite existing file): first 5 lines of `new content` with a `"…"` marker. Header: `Preview (will overwrite)`. **Does not** read the existing file just to diff — keeps the approval path I/O-free.

**Preview availability:** the disclosure row is rendered only when `PermissionRequest.input` contains enough data to build a non-empty preview (`str_replace` with non-empty `old_str`/`new_str`, or `write_file` with non-empty `content`). When unavailable (e.g., empty content), the card collapses cleanly to title + summary + buttons with no disclosure affordance.

**State:** lives in a new `AgentPermissionRequestNotifier` — an `AsyncNotifier<PermissionRequest?>` that the loop awaits on via a `Completer<bool>`. The `_expanded` flag is local `StatefulWidget` state inside `PermissionRequestCard` — not tracked by the notifier.

**Input bar behavior:** the input bar stays fully interactive while a permission card is pending — the user can type a new message, which cancels the agent turn as a whole (same cancel wiring as the stop button). The card does not block chat input.

Interaction:

1. Loop emits a `ChatMessage` with `pendingPermissionRequest` (new nullable field — see §"ChatMessage addition" below) populated.
2. `_AssistantBubble` renders `PermissionRequestCard` below the tool row whose approval is pending.
3. User taps `Allow` or `Deny` → card calls `agentPermissionRequestProvider.notifier.resolve(approved)`.
4. `AgentService` unblocks the `Completer<bool>` it was awaiting → loop continues.

### ChatMessage addition

One new nullable field on `ChatMessage`:

```dart
PermissionRequest? pendingPermissionRequest,
```

Where `PermissionRequest` is a freezed class in `lib/data/session/models/`:

```dart
@freezed
abstract class PermissionRequest with _$PermissionRequest {
  const factory PermissionRequest({
    required String toolEventId,   // points at a ToolEvent in this message
    required String toolName,
    required String summary,       // human-readable, for the card
    required Map<String, dynamic> input,
  }) = _PermissionRequest;
}
```

This is additive — no migration needed because (a) Drift JSON columns tolerate new nullable fields and (b) existing messages serialize with `pendingPermissionRequest: null`.

---

## Tool definitions (`CodingTools.catalog`)

Static const list in `lib/data/coding_tools/models/coding_tool_definition.dart`:

```dart
const CodingToolDefinition readFile = CodingToolDefinition(
  name: 'read_file',
  description: 'Read the contents of a text file inside the active project.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'path': {'type': 'string', 'description': 'Project-relative or absolute path to a file inside the project.'}
    },
    'required': ['path'],
  },
);

const CodingToolDefinition listDir = CodingToolDefinition(
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

const CodingToolDefinition writeFile = CodingToolDefinition(
  name: 'write_file',
  description: 'Create or overwrite a file inside the active project. Prefer str_replace for targeted edits to existing files.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'content': {'type': 'string'},
    },
    'required': ['path', 'content'],
  },
);

const CodingToolDefinition strReplace = CodingToolDefinition(
  name: 'str_replace',
  description: 'Replace the first exact occurrence of old_str with new_str in a file. The match must be unique — if zero or multiple matches exist, this tool returns an error and the file is unchanged.',
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
```

---

## Tool handlers

All handlers live on `CodingToolsService` and route filesystem I/O through `CodingToolsRepository` (which wraps `dart:io`). Every path is first validated via the existing `ApplyRepository.assertWithinProject` static guard — unchanged, already security-audited.

### `read_file`

1. Resolve `path` relative to `projectPath`.
2. `assertWithinProject(resolvedPath, projectPath)`.
3. Reject files larger than 2MB (return `CodingToolResult.error("File too large (2.1MB max 2MB). Consider str_replace for targeted edits.")`).
4. Read as UTF-8; on decode failure return `error("File is not text-encoded.")`.
5. Return `CodingToolResult.success(content)`.

### `list_dir`

1. Resolve, assert within project.
2. Reject non-existent or non-directory paths.
3. If `recursive == false`: list immediate children, format as `"- <name> (<type>)"` lines.
4. If `recursive == true`: walk with a depth cap of 3 and an entry cap of 500. If cap hit, truncate and append `"(truncated, 500+ entries)"`.
5. Return formatted text as `success`.

### `write_file`

1. Resolve, assert within project (done by `ApplyService.applyChange`).
2. Delegate to `ApplyService.applyChange(filePath, projectPath, newContent, sessionId, messageId)`. This:
   - Inherits the 5MB size cap.
   - Records an `AppliedChange` so the write appears in the existing changes panel with revert support.
   - Snapshots the original content for revert.
3. On success return `success("Wrote <N> bytes to <path>.")`.
4. On `ApplyTooLargeException` / `PathEscapeException` / `ProjectMissingException` return `error(...)` with a scrubbed message.

### `str_replace`

1. Resolve, assert within project.
2. Read the file via the repository.
3. Count occurrences of `old_str`:
   - 0 matches → `error("old_str not found in <path>. The match must be exact, including whitespace.")`
   - \>1 matches → `error("old_str matches <N> times in <path>. Include more surrounding context to make it unique.")`
   - 1 match → proceed.
4. Compute new content via single-replace.
5. Delegate to `ApplyService.applyChange` (same as write_file — inherits size cap and revert).
6. On success return `success("Replaced 1 match in <path>.")`.

---

## Provider wire format

### Extending `CustomRemoteDatasourceDio`

A new method alongside the existing `streamMessage`:

```dart
Stream<StreamEvent> streamMessageWithTools({
  required List<OpenAiMessage> messages,   // includes tool-role messages
  required List<CodingToolDefinition> tools,
  required AIModel model,
  String? systemPrompt,
}) async* { ... }
```

Request body (OpenAI chat-completions shape):

```json
{
  "model": "<model.modelId>",
  "stream": true,
  "messages": [ ...history..., { "role": "user", "content": "..." } ],
  "tools": [
    { "type": "function", "function": { "name": "read_file", "description": "...", "parameters": { ... } } },
    { "type": "function", "function": { "name": "list_dir",  ... } },
    { "type": "function", "function": { "name": "write_file", ... } },
    { "type": "function", "function": { "name": "str_replace", ... } }
  ],
  "tool_choice": "auto"
}
```

SSE parser maps each `data:` event to a `StreamEvent`:

| SSE shape | Emitted event |
|---|---|
| `{"choices":[{"delta":{"content":"hi"}}]}` | `textDelta("hi")` |
| `{"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_abc","type":"function","function":{"name":"read_file","arguments":""}}]}}]}` | `toolCallStart(id: "call_abc", name: "read_file")` |
| `{"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\"path\":"}}]}}]}` | `toolCallArgsDelta(id, "{\"path\":")` |
| `{"choices":[{"finish_reason":"tool_calls"}]}` | Emit `toolCallEnd` for each in-flight id, then `finish("tool_calls")` |
| `{"choices":[{"finish_reason":"stop"}]}` | `finish("stop")` |
| `[DONE]` | Close the stream |

Tool-call identity tracking uses the `index` field as primary key (since `id` only appears on the first delta of each call). A small in-method `Map<int, String>` carries the `index → id` mapping across deltas.

### History translation (stored → OpenAI wire)

`AgentService` owns a private helper:

```dart
List<Map<String, dynamic>> _buildWireMessages(List<ChatMessage> history, String? agentSystemPrompt) { ... }
```

Rules:

- Prepend `{"role": "system", "content": agentSystemPrompt}` if provided.
- For each `ChatMessage`:
  - `user` → `{"role": "user", "content": content}`
  - `assistant` with `toolEvents` empty → `{"role": "assistant", "content": content}`
  - `assistant` with `toolEvents` non-empty →
    - one `{"role": "assistant", "content": content or null, "tool_calls": [ ... ]}` with one entry per `ToolEvent`
    - followed by N `{"role": "tool", "tool_call_id": event.id, "content": event.output ?? event.error ?? ""}`
  - `system` → `{"role": "system", "content": content}`

`ToolEvent`s with `status: cancelled` or `error` are still translated so the model sees the full history including denials and failures.

---

## System prompt (`act` mode only)

Lives as a private const in `agent_service.dart`:

```dart
const String _kActSystemPrompt = '''
You are a coding assistant embedded in a local IDE. You have four tools: read_file, list_dir, write_file, str_replace.

Rules:
- Read before you edit. Always call read_file on a file before write_file or str_replace against it, unless you're creating a brand-new file.
- Prefer str_replace over write_file for targeted edits. Only use write_file for new files or full rewrites.
- After making changes, briefly describe what you changed and why in 1–3 sentences.
- If a task is ambiguous or destructive (removing large sections, deleting files, sweeping refactors), ask the user before acting.
- All paths you provide must be inside the active project. Absolute paths outside the project will be rejected.
''';
```

The prompt is passed to `_buildWireMessages` whenever `ChatMode.act` is the current mode. In `chat` and `plan` modes the prompt is not included and no tools are sent — those modes keep the existing pure-text behavior.

---

## Cancellation

New notifier in `lib/features/chat/notifiers/agent_cancel_notifier.dart`:

```dart
@Riverpod(keepAlive: true)
class AgentCancelNotifier extends _$AgentCancelNotifier {
  @override
  bool build() => false;

  void request() => state = true;
  void clear() => state = false;
}
```

The loop checks `ref.read(agentCancelProvider)` at each tool boundary. When true, it:

1. Marks all in-flight `ToolEvent`s as `cancelled`.
2. Appends `"\n\n_Cancelled by user._"` to the text buffer.
3. Yields a final `ChatMessage` with `isStreaming: false`.
4. Calls `AgentCancelNotifier.clear()` so the next turn starts with a clean flag.

The existing stop button in the chat input bar (already wired to a cancel action for plain-text streams) gains a `ref.read(agentCancelProvider.notifier).request()` call so one button cancels both modes.

Important: the currently-executing tool is **not** aborted — the `await` on `codingToolsService.execute` runs to completion. This is intentional: aborting a `write_file` mid-write risks a truncated file on disk. The trade-off is one extra tool duration before the loop stops (< 1s for our tools; `run_command`'s future spec will need a real abort signal).

### Cancelled-row visual treatment

`ToolCallRow`'s existing `ToolStatus.cancelled` branch renders the row identically to every other status — only the right-side icon changes. In a mixed stream this reads as "all these ran" at a glance. Polish the row so cancelled events are visibly distinct:

| Element | Active/success state | Cancelled state |
|---|---|---|
| Row background | `c.inputSurface` | `c.inputSurface` at ~50% alpha (dropped to `rgba(255,255,255,0.015)` against the chat background) |
| Row border | `c.borderColor` | `c.borderColor` at ~50% alpha |
| Tool-name text | `c.textPrimary` | `c.textMuted` |
| Leading tool icon | `c.textSecondary` | `c.dimFg` |
| Primary arg (filename) | `c.textSecondary`, normal weight | `c.dimFg` with a **strikethrough** (`decoration: TextDecoration.lineThrough`, `decorationColor: c.dimFg`, `decorationThickness: 1`) |
| Right status icon | `Icons.check_circle` in `c.success` / `Icons.error` in `c.error` | `Icons.cancel_outlined` in `c.dimFg` (unchanged) |

Rationale:
- The strikethrough lands on the arg (filename) because that's the piece users scan when reconstructing "what was this row going to do?" Putting the cancellation signal there makes it unambiguous without adding chrome.
- Strikethrough survives high-contrast accessibility modes (structural, not purely chromatic) — unlike a pure opacity dim.
- Keeping the tool name readable (muted but not struck through) means users can still distinguish `read_file` from `str_replace` when scrolling back through old transcripts.
- No new theme tokens needed: `c.textMuted` and `c.dimFg` already exist in [app_colors.dart](../../../lib/core/theme/app_colors.dart). Alpha modulation on existing tokens stays inside the `ThemeConstants` convention (no new hex literals).

Expanded view (when the user taps to expand a cancelled row) stays as-is — the INPUT / OUTPUT labels and content render normally. The `output` field is always `null` for cancelled rows, so the OUTPUT block naturally doesn't render.

---

## Error handling

### Typed failure union

```dart
// lib/features/chat/notifiers/agent_failure.dart
@freezed
sealed class AgentFailure with _$AgentFailure {
  const factory AgentFailure.iterationCapReached() = AgentIterationCapReached;
  const factory AgentFailure.providerDoesNotSupportTools() = AgentProviderDoesNotSupportTools;
  const factory AgentFailure.streamAbortedUnexpectedly(String reason) = AgentStreamAbortedUnexpectedly;
  const factory AgentFailure.toolDispatchFailed(String toolName, String message) = AgentToolDispatchFailed;
  const factory AgentFailure.unknown(Object error) = AgentUnknownError;
}
```

`ChatMessagesNotifier` already emits `AsyncError` for stream failures — that pattern extends here. The widget-layer listener in `chat_input_bar.dart` gains a `switch` on `AgentFailure` cases:

- `iterationCapReached` is **not** an error (the banner communicates it — no snackbar).
- `providerDoesNotSupportTools` surfaces the snackbar `"The selected provider doesn't support tool use. Switch to a compatible model or leave Act mode."` and reverts to text mode for that turn.
- `streamAbortedUnexpectedly` → generic "Stream ended unexpectedly — try again."
- `toolDispatchFailed` → never reaches widget-layer; tool errors are reported to the model as tool_results, not surfaced as chat errors.
- `unknown` → generic "Something went wrong."

### Per-tool errors

Tool handlers catch expected exceptions (`PathNotFoundException`, `PathEscapeException`, `FileSystemException`, `ApplyTooLargeException`, `FormatException` for bad JSON args) and convert to `CodingToolResult.error(scrubbedMessage)`. Unexpected exceptions rethrow and are caught by the loop, which converts them into `ToolEvent.error("Tool dispatch failed: <type>")` and also feeds a generic error as a `tool_result` so the model can recover.

All tool executions `dLog` start/end with timing; security rejections `sLog` (they go through the existing `ApplyService` / `assertWithinProject` guards, which already `sLog`).

---

## Testing

### Unit tests

1. **`CodingToolsService` — each tool, happy path + boundary conditions**
   - `read_file` on a normal file, missing file, 2MB+ file, binary file, path outside project.
   - `list_dir` on a flat dir, recursive (depth-capped), non-existent, symlink-escape.
   - `write_file` create new, overwrite existing, 5MB+ content, path outside project. Verify an `AppliedChange` is recorded.
   - `str_replace` with 0/1/2+ matches, path outside project.

2. **`AgentService.runAgenticTurn` — scripted stream fake for `AIRepository`**
   - Happy path: two rounds (text → tool_call → text → stop). Assert: yielded messages reach the expected final shape; tool events fire start→running→success.
   - Cap hit: repository yields `finish_reason: "tool_calls"` for 10 rounds. Assert: final message has `iterationCapReached: true` and `isStreaming: false`, no 11th round.
   - Continue from cap: calling `continueAgenticTurn(messageId)` re-enters the loop with the capped message as part of history. Assert: iteration counter starts at 1 (not 10), history to the provider includes the capped message's `tool_calls` + `tool_result` pairs.
   - Cancel mid-turn: cancel flag set after round 3. Assert: loop exits at tool boundary, pending events flip to `cancelled`.
   - `askBefore` + deny: permission request yields; denial feeds back as tool_result `"User denied this change."` Assert: loop continues; next round sees the denial in history.
   - `readOnly`: write_file filtered out of tool list. Assert: request body contains only read_file and list_dir.

3. **Wire-format translator**
   - Assistant `ChatMessage` with two `ToolEvent`s unpacks into `[assistant with tool_calls, tool for event1, tool for event2]` in order.
   - Empty tool events → plain assistant message.

4. **`CustomRemoteDatasourceDio.streamMessageWithTools`**
   - Fake SSE fixtures covering each event type above; assert `StreamEvent` output sequence matches.

### Widget tests

5. **`PermissionRequestCard`** — renders collapsed by default (title + summary + disclosure row + buttons, no preview visible); tapping `Show diff ▾` reveals the preview block and flips label to `Hide diff ▴`; disclosure row hidden when no preview is available (empty `str_replace.new_str` / empty `write_file.content`); `[Allow]` calls `resolve(true)`; `[Deny]` calls `resolve(false)`.
6. **`IterationCapBanner`** — active state renders with amber border, `[Continue]` button is enabled and calls `continueAgenticTurn(messageId)`; dismissed state (simulated by appending a user message after the capped one) renders with neutral grey styling and an inert button with `onPressed: null`.
7. **`ToolCallRow` cancelled styling** — pump a row with `ToolStatus.cancelled`, assert the `Text` widget rendering the primary arg has `TextDecoration.lineThrough` in its style and the tool-name text uses `c.textMuted`. Pump the same row with `ToolStatus.success`, assert no `lineThrough` and `c.textPrimary` — proves the diff is scoped to the cancelled branch.
8. **`_AssistantBubble`** — pumps a message with `pendingPermissionRequest` set, asserts the card renders; clears the field, asserts the card disappears. Pumps a message with `iterationCapReached: true` that is the most recent message, asserts banner is active; adds a trailing user message, asserts banner transitions to dismissed styling; calls `clearIterationCap` on the message, asserts banner disappears entirely.

### Integration (manual, smoke)

Once implemented, manually verify against a local LMStudio endpoint loaded with a tool-capable model (e.g. Qwen 2.5 Coder, Llama 3.1 Instruct):

- "Read my package.json and tell me what Dart SDK version is pinned." → expects `read_file` call → assistant answer.
- "Add a debugPrint at the top of lib/main.dart's main()." → expects `read_file` → `str_replace` → success banner.
- "Create a new file lib/foo.dart with a hello world function." → expects `write_file` → `AppliedChange` appears in changes panel.
- "List the lib directory." → expects `list_dir` → formatted tree in response.

---

## Non-functional requirements

- **Architecture rule compliance:** all I/O lives in the new `CodingToolsDatasourceIo` (filename ends in `_io.dart` per naming convention). `AgentService` composes `AIService`, `CodingToolsService`, `ApplyService`. No widget reaches into any service — `ChatMessagesNotifier` remains the only notifier widgets talk to.
- **Logging:** tool starts/ends `dLog`ed with timing in `CodingToolsService`; security rejects already `sLog`ed by the reused `ApplyService.assertWithinProject`. Never log file contents or model output bodies.
- **Naming:** `AgentService`, `CodingToolsService` (both end in `Service`). `AgentCancelNotifier`, `AgentPermissionRequestNotifier` (end in `Notifier`, own value state). `AgentFailure` (strips `Service` suffix). Files under `lib/features/chat/notifiers/` per CLAUDE.md.
- **Performance:** the loop yields on every tool-event transition — streaming feels live. The 500-entry cap on `list_dir` and 2MB cap on `read_file` bound the per-tool payload size. `str_replace` reads the whole file into memory once — acceptable up to the 5MB cap.
- **Security:** no new attack surface beyond what `ApplyService` already audits. Tool inputs are JSON-schema-validated by the provider (OpenAI enforces schema) and re-validated by the Dart handlers. `list_dir` caps prevent a rogue model from requesting a full-system walk.

---

## Rollout

- **Backout:** revert the six modified files + delete the new domain folders. No schema migrations (the new `pendingPermissionRequest` and `iterationCapReached` fields are additive with safe defaults; Drift JSON columns tolerate missing fields). No breaking changes to `ChatMessage` or `ToolEvent`.
- **Feature gate:** the loop only activates when `ChatMode.act` is selected AND the active model's provider is `AIProvider.custom`. For all other combinations, `SessionService.sendAndStream` takes the existing text-only path.
- **Follow-up specs (known, ordered):**
  1. `run_command` + `glob` tools (separate brainstorm needed).
  2. Anthropic tool-use support (wire format differs enough to warrant its own spec).
  3. Drift persistence of `ToolEvent`s across app restarts.
  4. "Allow always this session" escalation on the permission card.
  5. Parallel tool execution when the model emits multiple calls in one round.
