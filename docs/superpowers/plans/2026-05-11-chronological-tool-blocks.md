# Chronological tool blocks · plan

**Branch:** `feat/2026-05-11-chronological-tool-blocks`
**Source spec:** `.superpowers/brainstorm/38278-1778252612/content/final-summary.html` — "Tool cards persistent · interleaved with text"
**Why now:** Both Claude.ai and ChatGPT interleave tool calls chronologically with text. Current Code Bench groups all tool calls at the top of the assistant bubble, then renders all text below. The conclusion appears under the workings, which reads backwards.

---

## Today's data model — the constraint

```dart
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String sessionId,
    required MessageRole role,
    required String content,                  // single concatenated string
    @Default([]) List<ToolEvent> toolEvents,  // flat list, no positional info
    required DateTime timestamp,
    @Default(false) bool isStreaming,
    // ...
  });
}
```

`content` is one string. `toolEvents` is a flat list with no positional info indicating *where in the text stream* each event fired. Order between text and tools is lost at the model boundary.

## Target data model

Replace `content` + `toolEvents` with `List<MessageBlock> blocks`, where each block is a sealed-class variant. Keep `content` as a derived getter (concatenation of text blocks) for callers that just want the prose — chiefly persistence, copy-as-markdown, search.

```dart
@freezed
sealed class MessageBlock with _$MessageBlock {
  const factory MessageBlock.text(String text) = TextBlock;
  const factory MessageBlock.tool(ToolEvent event) = ToolBlock;
}

extension ChatMessageBlocks on ChatMessage {
  String get content => blocks.whereType<TextBlock>().map((b) => b.text).join();
  List<ToolEvent> get toolEvents => blocks.whereType<ToolBlock>().map((b) => b.event).toList();
}
```

**Streaming append rule:**
- Text delta arrives → if the *last* block is a `TextBlock`, mutate its `text` (append). Otherwise add a new `TextBlock`.
- Tool event arrives (running) → close the current text block (no further appends to it). Add a new `ToolBlock`.
- Tool event status update → find the `ToolBlock` whose `event.id` matches and replace it in-place (preserving position).

This rule guarantees blocks stay ordered by emission time without needing per-block timestamps.

## Phasing — three commits, each independently revertable

### Phase 1 · data model + getters (compat shims)
- Add `MessageBlock` sealed class, `freezed` generation
- Add `blocks` field to `ChatMessage`, default `[]`
- Keep `content` and `toolEvents` as **stored fields** for one release — the getter approach starts in phase 3
- Add `chatMessage.toBlocks()` migration helper: `[TextBlock(content), ...toolEvents.map(ToolBlock.new)]` (preserves today's grouped rendering order until phase 2 swaps the renderer)
- Drift schema: add `blocks_json` TEXT column; backfill via `toBlocks()` on read until phase 3
- Tests: model serialization round-trip, drift up/down migration

**Risk:** low — additive only, nothing reads `blocks` yet.

### Phase 2 · streaming pipeline writes blocks
- `ChatNotifier.appendStreamingText(...)` → mutate-last-or-append logic
- `ChatNotifier.appendToolEvent(...)` → always append a new block, close current text run
- `ChatNotifier.updateToolEvent(...)` → in-place replace by id
- Every provider datasource that emits text+tool events must call these new methods in chronological order. Audit checklist:
  - `lib/data/ai/datasource/anthropic_*` — Claude API direct
  - `lib/data/ai/datasource/openai_*` — OpenAI direct
  - `lib/data/ai/datasource/gemini_*` — Gemini
  - `lib/data/ai/datasource/ollama_*` — Ollama
  - `lib/data/session/datasource/claude_cli_*` — Claude Code CLI transport
  - `lib/data/session/datasource/codex_*` — Codex
- Verify each emits text-then-tool-then-text in the order received from the upstream stream

**Risk:** medium — bug here corrupts message order. Mitigate with a single integration test per provider (mock stream → assert block order).

### Phase 3 · renderer swap + remove compat shims
- `_AssistantBubble.build` iterates `message.blocks` instead of rendering `_MessageContent` + grouped `ToolCallRow`s
- Each `TextBlock` → reuse the existing `MarkdownBody` with `MarkdownStyleSheet` from phase D
- Each `ToolBlock` → reuse `ToolCallRow`
- Drop the `content` / `toolEvents` *stored* fields (the getters in `ChatMessageBlocks` keep call sites working)
- Drift schema: drop the old `content` and `tool_events_json` columns; backfill `blocks_json` for any pre-phase-1 rows that slipped through
- Tests: golden render tests for a turn with text→tool→text→tool→text, and for a tool-first turn

**Risk:** medium — visible UI change. Hold behind a feature flag (`enableChronologicalBlocks`) for one release if the team wants a kill switch.

---

## Files touched (estimate)

| Path | Phase | Notes |
|---|---|---|
| `lib/data/shared/chat_message.dart` | 1 | Add `MessageBlock` sealed class, `blocks` field |
| `lib/data/shared/chat_message.freezed.dart` | 1 | regen |
| `lib/data/shared/chat_message.g.dart` | 1 | regen |
| `lib/data/session/datasource/chat_session_drift.dart` | 1, 3 | drift schema migration |
| `lib/features/chat/notifiers/chat_notifier.dart` | 2 | append/update methods |
| `lib/data/ai/datasource/anthropic_*.dart` | 2 | emit in chronological order |
| `lib/data/ai/datasource/openai_*.dart` | 2 | emit in chronological order |
| `lib/data/ai/datasource/gemini_*.dart` | 2 | emit in chronological order |
| `lib/data/ai/datasource/ollama_*.dart` | 2 | emit in chronological order |
| `lib/data/session/datasource/claude_cli_*.dart` | 2 | emit in chronological order |
| `lib/data/session/datasource/codex_*.dart` | 2 | emit in chronological order |
| `lib/features/chat/widgets/message_bubble.dart` | 3 | swap renderer to iterate blocks |
| `test/data/shared/chat_message_test.dart` | 1 | round-trip, getters |
| `test/data/session/datasource/chat_session_drift_test.dart` | 1, 3 | migration |
| `test/features/chat/notifiers/chat_notifier_test.dart` | 2 | block append rules |
| `test/features/chat/widgets/message_bubble_test.dart` | 3 | golden render |

Estimated effort: **1.5–2 days** spread across the three commits (about half a day per phase, plus ~2 hr for the per-provider datasource audit).

## Open questions for review

1. **Edge case: tool event before any text** — does an agent that opens with a tool call (no prelude text) render correctly? Suggest: `_AssistantBubble` renders an empty leading gap so the bubble doesn't collapse vertically.
2. **Edge case: rapid text→tool→text within 100ms** — the "close current text block" rule must fire even if the next text chunk arrives one event-loop tick later. Verify the streaming chunker doesn't coalesce across a tool event.
3. **Persistence migration of in-flight messages** — what happens if a user is mid-turn when the upgrade lands? Suggest: discard the in-flight turn on first load with the new schema (it's already failed from the streaming side).
4. **Feature flag or hard cutover?** — phase 3 is visible; a one-release kill switch via `enableChronologicalBlocks` GrowthBook flag is cheap insurance. Recommend ON.

## Out of scope

- Per-block timestamps. The emission-order invariant is sufficient.
- Block-level edit / delete (today's `delete_message` operates at message granularity; keep it that way).
- Tool result rendering inside a block (today's `ToolCallRow` already shows status + output preview — no change).
- Word-level intra-line diffs in diff content (separate concern, see `code_block_widget.dart`).
