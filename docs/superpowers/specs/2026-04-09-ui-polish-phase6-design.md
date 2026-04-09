# Code Bench — UI Polish Phase 6: Agent Question UI

## Overview

Phase 6 adds the UI surface for agentic question/answer flows. When the AI agent calls `AskUserQuestion` mid-task, a structured card renders in the chat. A collapsible WORK LOG section inside the same message bubble shows live tool-call progress with a running timer.

This is Phase 6 of the UI improvement queue. It builds on the agentic tool-use infrastructure from Phase 5.

---

## Decisions Made

### 1. AskUserQuestion Card

Rendered as a structured card appended to the assistant message bubble when the agent calls `AskUserQuestion`.

#### Card structure

**Header:**
- Progress dots — completed steps solid blue (`#4A7CFF`), current step blue at 50% opacity, upcoming grey
- `N / M` step counter in small-caps
- Section label right-aligned (e.g., `Architecture`) — optional, from agent payload

**Body:**
- Question title — `titleSmall`, full text
- **Numbered option rows** — each row: numbered badge + full-text label. Selected row highlights with blue tint + blue numbered badge. Tapping selects.
- **Free-text input** — always visible below options, placeholder: `"Or describe your own approach…"`. Hidden when agent sets `allowFreeText: false`.

**Footer:**
- `← Back` — disabled on step 1; navigates to previous card and restores prior selection
- `Next →` — shown on multi-step questions, disabled until a selection is made; hidden on single-step
- `Submit` — primary button, right-aligned, shown on final step (or only step)

#### Multi-step behaviour

The agent sends questions one at a time. Each `AskUserQuestion` call carries `stepIndex` and `totalSteps`. `AskQuestionNotifier` stores previous answers keyed by `(sessionId, stepIndex)`. Back navigates to the prior card and restores the selection.

On Submit: the answer payload is sent back to the agent as a user message (structured JSON internally, rendered as plain text in the bubble).

#### Data model

```dart
@freezed
class AskUserQuestion with _$AskUserQuestion {
  const factory AskUserQuestion({
    required String question,
    required List<String> options,
    @Default(true) bool allowFreeText,
    required int stepIndex,
    required int totalSteps,
    String? sectionLabel,
  }) = _AskUserQuestion;
}
```

---

### 2. WORK LOG (In-message Collapsible)

A collapsible section at the bottom of the active assistant message bubble, showing live tool-call progress while the agent runs.

#### Collapsed state (default while running)

Toggle row:
- Spinner icon + `WORK LOG` label (small-caps) + live `⏱ Xs` timer + `▾` chevron
- Tapping expands

#### Expanded state

Each tool call appends a log entry in real time:
- Status icon: ⚡ running / ✓ done / ✗ failed
- Tool name (monospace)
- Primary argument (e.g., file path), truncated
- Duration once completed (e.g., `0.3s`)

Timer counts up while agent is running, freezes on completion.

#### After agent finishes

- Spinner in toggle row replaced with ✓
- Timer freezes showing total elapsed time
- Section collapses by default — stays expandable at any time in history

#### Status bar pill

`"Working for Xs"` pill in the status bar while agent is running (ticker-driven). Tapping scrolls the chat to the active message. No separate panel — the message bubble is the source of truth.

#### State

**`WorkLogNotifier`** — `keepAlive` Riverpod notifier keyed by `messageId`, holding `List<WorkLogEntry>`. Entries are populated by the same tool-call pipeline that feeds `ToolEvent` on the message (Phase 5). Collapsed/expanded state per message also held here.

```dart
@freezed
class WorkLogEntry with _$WorkLogEntry {
  const factory WorkLogEntry({
    required String toolName,
    String? argument,
    required WorkLogStatus status,
    int? durationMs,
    required DateTime startedAt,
  }) = _WorkLogEntry;
}

enum WorkLogStatus { running, done, failed }
```

---

## Files Touched

| File | Change |
|---|---|
| `lib/data/models/ask_user_question.dart` | New `@freezed` model |
| `lib/data/models/work_log_entry.dart` | New `@freezed` model + `WorkLogStatus` enum |
| `lib/features/chat/widgets/message_bubble.dart` | Render `AskUserQuestionCard` and `WorkLogSection` when present on message |
| `lib/features/chat/widgets/ask_user_question_card.dart` | New — numbered rows, step counter, progress dots, free-text input, Back/Next/Submit footer |
| `lib/features/chat/widgets/work_log_section.dart` | New — collapsible toggle row + live log entry list with timer |
| `lib/features/chat/notifiers/ask_question_notifier.dart` | New — stores per-session answers keyed by `(sessionId, stepIndex)`; handles Back navigation |
| `lib/features/chat/notifiers/work_log_notifier.dart` | New — `keepAlive`, keyed by `messageId`, appended to by tool-call pipeline |
| `lib/shell/widgets/status_bar.dart` | Add `"Working for Xs"` ticker-driven pill; tap scrolls to active message |

---

## Out of Scope for This Phase

- Cancelling a running agent mid-task — future
- Multi-select answers (more than one option at a time) — future
- Branching question trees (option A leads to a different follow-up than option B) — future
