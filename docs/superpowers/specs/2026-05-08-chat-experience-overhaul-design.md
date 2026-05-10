# Chat Experience Overhaul

**Date:** 2026-05-08
**Branch:** `feat/2026-05-08-chat-experience-overhaul`
**Status:** Approved — ready for implementation planning

## Context

Phases 5–9 of the UI improvement queue carry five chat-screen surfaces that have grown out of sync with each other. Each acceptance-criteria block describes a real gap, but the work is interdependent enough that splitting it into five PRs would force every PR to re-establish the same visual idioms (cards, badges, color semantics) before solving its actual problem. This spec bundles all five into one design.

What's broken or missing today:

- **Thinking & progress states** ([message_bubble.dart](../../../lib/features/chat/widgets/message_bubble.dart)) — the in-flight indicator is a single generic "Thinking…" with no signal during tool execution, file reads, or network calls. Users can't tell whether the agent is working or stalled.
- **Session list status** ([sessions list widgets](../../../lib/features/chat/)) — no per-row indicator. To learn that a session is awaiting input, errored, or actively streaming, the user must click into it.
- **Markdown / diff styling** — code blocks render flat with the GitHub-Dark `codeBlockBg` (#0D1117). Per-message `copy` / `retry` / `delete` actions don't exist.
- **Question card** ([ask_user_question_card.dart](../../../lib/features/chat/widgets/ask_user_question_card.dart)) — exists as a wizard widget but is **unwired** to any provider runtime event. Today, Codex's `item/tool/requestUserInput` RPC is misrouted into the permission-card path ([codex_session.dart:328-329](../../../lib/data/ai/datasource/codex_session.dart#L328-L329)), so the agent's question never gets a typed answer back.
- **Apply-code diff** ([apply_code_dialog.dart](../../../lib/features/chat/widgets/apply_code_dialog.dart)) — currently a snackbar stub: `AppSnackBar.show('Apply code is not yet available in the new layout.')`. The agent can produce code but the user can't apply it.
- **Tool-call attribution** ([tool_call_row.dart:89-94](../../../lib/features/chat/widgets/tool_call_row.dart#L89-L94)) — provider and model badges already render on each tool card, but both use the same `c.accent` token. Brand identity is lost; in multi-provider sessions you can't tell at a glance which provider ran which tool.

## Goal

A chat experience where the user can, at all times:

1. Tell what the agent is doing right now (phase) and what it has done in this turn (tool history).
2. Tell which session is streaming, awaiting input, or errored without clicking in.
3. Read code and diffs comfortably, and act on a message (copy / retry / delete).
4. Answer agent questions in a card distinct from approval prompts, regardless of provider transport.
5. Apply suggested code changes inline, with clear feedback about success or failure.
6. See which provider and model produced each tool call.

No provider transport changes that aren't necessary to fix the current routing bug. No new color tokens beyond the brand-color set required for attribution. No service-import violations from widgets.

## Non-goals

- **`ExitPlanMode` and other Claude-Code-specific interactive tools.** Out of scope; the question-card mechanism is built to extend, but only `AskUserQuestion` is wired in this PR.
- **Wizard-style multi-step questions for agents.** Agent-initiated questions are single-step. The existing wizard usage of `AskUserQuestionCard` is preserved by hiding the stepper when `totalSteps == 1`.
- **Provider-specific code-apply pipelines.** The apply-diff card uses the existing `CodeApplyActions` notifier; no datasource changes.
- **Markdown engine migration.** Whatever package is in use today remains; only the styling tokens change.
- **Onboarding / missing-project / live-git surfaces** (Phases 5, 6, 9 of the UI queue) — these stay in their own queue.

## Design decisions

### 1. Thinking & progress states

**Phase pill at the tail of the live assistant bubble + persistent tool cards interleaved with text.**

Two derived UI elements share a single underlying event source:

- **Phase pill** — ephemeral. Appears at the tail of the live bubble, disappears when the turn completes. Color-encoded by phase class:
  - **Teal** (`accent`) — `thinking` (model generating tokens, no tool active)
  - **Amber** (`warning`) — tool execution (anything in `ToolRegistry` whose handler shells out)
  - **Blue** (`info`) — I/O (anything whose handler reads/writes the filesystem)
  - Multiple pills can stack when phases overlap (e.g., reading files while thinking).
- **Tool-calling card** — persistent. Inserted into the bubble when a tool starts, updated to terminal status when it finishes, stays as part of the conversation record. Uses the existing [tool_call_row.dart](../../../lib/features/chat/widgets/tool_call_row.dart), upgraded per §3 and §6 below. Body collapsed by default with `▾ show output`.

Both feed off `ProviderToolUseStart` / `ProviderToolUseComplete` events that already flow through the chat notifier. No new datasource events needed.

**Phase classifier mapping** (default; implementation may refine):

```dart
PhaseClass classifyTool(String toolName, ToolRegistryEntry? entry) {
  if (entry == null) return PhaseClass.tool; // unknown tool — treat as opaque exec
  if (entry.requiresFilesystem) return PhaseClass.io;
  if (entry.shellsOut) return PhaseClass.tool;
  return PhaseClass.think;
}
```

**Alternatives considered:**

- *Single status row (Claude-CLI style).* Rejected — only one phase visible at a time; loses concurrency signal when the agent reads files while thinking.
- *Minimal pulsing dot, no color encoding.* Rejected — equivalent in expressiveness to today's "Thinking…" with extra animation cost.
- *Tool cards only, no phase pill.* Rejected — when the model is generating text without an active tool, the user sees nothing and assumes the stream stalled.

### 2. Session list status indicators

**Four-state colored dot prefixed to each session row.**

| State | Color token | When |
|---|---|---|
| streaming | `accent` (#4EC9B0), pulsing | provider is producing tokens or running a tool |
| awaiting | `warning` (#CCA700) | permission card or question card pending; user must respond before stream resumes |
| errored | `error` (#F44747) | last turn ended in `ProviderStreamFailure` and was not retried |
| idle | `textMuted` dark / `iconInactive` light | clean finish, default for inactive sessions |

Transitions: idle → streaming on send; streaming → waiting when a permission/question card emits; waiting → streaming on user response; any → error on stream failure.

Source: derived from existing session state — chat notifier's `isStreaming` flag, presence of `pendingPermissionRequest` / `askQuestion`, last terminal `AsyncError`. No new persisted state.

### 3. Markdown, diff styling, message icons

**Adopt the Ayu code theme. Always-visible per-message toolbar.**

- **Code blocks** — Ayu Dark (#0B0E14 / #BFBDB6) and Ayu Light (#FAFAFA / #5C6166). Adds `re_highlight/styles/ayu-dark` + `ayu-light` imports next to the existing atom-one imports in [app_colors.dart:4-5](../../../lib/core/theme/app_colors.dart#L4-L5).
- **Inline `code`** — uses existing `inlineCodeFill` / `inlineCodeStroke` / `inlineCodeText` tokens.
- **Diff cards in messages** — file-header strip with filename + `+N −N` stats (Ayu green/red) + copy/open icons. Body uses Ayu palette with line gutters and add/del row tinting. The same diff card structure is reused inside the apply-diff card (§5).
- **Per-message toolbar** — always-visible row below the bubble with `copy` / `retry` / `delete` buttons. No hover-reveal.
  - **Copy** — copies bubble content (text + code blocks as raw markdown) to clipboard.
  - **Retry** — re-runs the user message that produced this bubble (truncates trailing assistant turns, like the existing edit-and-fork pattern).
  - **Delete** — removes this assistant message (and any subsequent assistant messages in the same turn).
- **Markdown elements** (headings, lists, blockquotes) use existing `ThemeConstants` font sizing and theme-aware text colors.

**Why Ayu over atom-one** (which is already imported): Ayu Dark's near-black bg (#0B0E14) sits *darker* than the app bg (#141414), so code reads as an inset well rather than a lifted card — better fit for chat bubbles already on a dark surface. Trade-off accepted: one new theme dependency import.

### 4. Question card · cross-provider

**Info-blue accent card. Reuse `AskUserQuestionCard` with stepper hidden when single-question.**

Visual: left stripe in `info` (#4FC1FF dark / #1E88E5 light), card bg `info` at 4% / 8%. Distinct from permission card (warning amber) and apply card (success teal) — distinct semantic colors map to distinct user actions:

- amber → "should I be allowed to do this?" (binary)
- teal → "should I commit this code?" (binary)
- **blue → "answer this question" (typed)**
- red → error / failed action

The existing widget at [ask_user_question_card.dart](../../../lib/features/chat/widgets/ask_user_question_card.dart) is refactored:

- Stepper UI hidden when `totalSteps == 1` (the agent-question case).
- "Clear answer" / "Next" / "Submit" button labels swap to "Submit" only when single-step.
- `c.questionCardBg` / `c.selectionBorder` color usage swaps to `c.info`-derived shades. Existing `c.questionCardBg` (#0D2B27 dark teal-green) stays for the wizard usage; the new single-question variant is a new visual mode.

#### 4.1 Producer wiring per provider

| Provider | Transport | Wiring |
|---|---|---|
| Codex | RPC `item/tool/requestUserInput` | New `ProviderUserInputRequest` event variant; branch `_handleServerRequest` in [codex_session.dart:317](../../../lib/data/ai/datasource/codex_session.dart#L317); reply via new `respondToUserInputRequest` API with `{response: string}` |
| Claude CLI | `tool_use` event with `name == 'AskUserQuestion'` | Intercept in [claude_cli_stream_parser.dart](../../../lib/data/ai/datasource/claude_cli_stream_parser.dart); emit `ProviderUserInputRequest`; reply via existing `tool_result` flow |
| Anthropic API | Tool registration | Register `AskUserQuestion` as a default tool in [anthropic_remote_datasource_dio.dart](../../../lib/data/ai/datasource/anthropic_remote_datasource_dio.dart); when model calls it, emit `ProviderUserInputRequest`; reply via `tool_result` |
| OpenAI / Gemini / Ollama / custom | Tool registration | Same pattern via each provider's function-calling shape |

#### 4.2 New runtime event variant

In [provider_runtime_event.dart](../../../lib/data/ai/models/provider_runtime_event.dart):

```dart
/// Agent-initiated question requiring a typed answer (not a yes/no approval).
/// UI shows a question card with prompt, optional choices, and free-text input.
class ProviderUserInputRequest extends ProviderRuntimeEvent {
  const ProviderUserInputRequest({
    required this.requestId,
    required this.prompt,
    this.choices,
    this.defaultValue,
  });
  final String requestId;
  final String prompt;
  final List<String>? choices;
  final String? defaultValue;
}
```

#### 4.3 New repository / datasource API

Parallel to `respondToPermissionRequest`:

```dart
void respondToUserInputRequest(
  String sessionId,
  String requestId, {
  required String response,
});
```

For Codex: writes `{response}` (not `{decision}`) back to the JSON-RPC `requestUserInput` completer. For Claude CLI and API providers: assembles a `tool_result` keyed by the original `tool_use_id`.

#### 4.4 New notifier

`AgentUserInputRequestNotifier` (file: [features/chat/notifiers/agent_user_input_request_notifier.dart](../../../lib/features/chat/notifiers/)) parallels [agent_permission_request_notifier.dart](../../../lib/features/chat/notifiers/agent_permission_request_notifier.dart). Holds the active `ProviderUserInputRequest?` and exposes `request(req) → Future<String>` and `submit(answer)` / `cancel()`.

The chat notifier subscribes to `ProviderUserInputRequest` events on the runtime stream and forwards them through the new notifier; the bubble renders [ask_user_question_card.dart](../../../lib/features/chat/widgets/ask_user_question_card.dart) when `agentUserInputRequestProvider` has a value.

### 5. Apply-code diff · inline-in-bubble

**Replace the snackbar stub with an inline card. Three states: ready · applied · failed.**

- **Ready** — file header (filename · `+N −N` stats · copy / open icons · `Apply` button) + body in Ayu palette showing the diff.
- **Applied** — card opacity reduces; `Apply` button is replaced by a `✓ applied` pill; body collapses to a single-line preview. Card stays in the bubble as conversation record.
- **Failed** — file diverged or context mismatch. Card border switches to `error` red; banner explains the divergence; `Re-diff` button fetches a fresh diff against current file state.

Apply-button placement: file-header right side, alongside copy/open icons. Driven by existing [code_apply_actions.dart](../../../lib/features/chat/notifiers/code_apply_actions.dart) — no new actions needed; the dialog stub at [apply_code_dialog.dart:9-11](../../../lib/features/chat/widgets/apply_code_dialog.dart#L9-L11) is deleted and replaced by the new `ApplyDiffCard` widget rendered inline in `MessageBubble` next to the existing card slots ([message_bubble.dart:270-271](../../../lib/features/chat/widgets/message_bubble.dart#L270-L271)).

The "could not apply" path uses the failure typed union pattern from [CLAUDE.md Rule 3](../../../CLAUDE.md): `CodeApplyActions` already returns a typed `CodeApplyFailure`; the card switches into its failed state when it observes that failure for the current code-block id.

### 6. Tool-call attribution · brand chip + neutral model chip

**Per-card placement. Asymmetric coloring.**

The existing [tool_call_row.dart:87-94](../../../lib/features/chat/widgets/tool_call_row.dart#L87-L94) renders both badges in `c.accent`. Change:

- **Provider chip** — brand-colored, with a 6 px brand-color dot prefix. Uses a new `brandColorFor(providerId)` helper next to [provider_label.dart](../../../lib/features/chat/widgets/provider_label.dart).
- **Model chip** — neutral monospace (`textSecondary` on `chipFill`).

Brand-color tokens added to [app_colors.dart](../../../lib/core/theme/app_colors.dart):

| Token | Value | Used for providerId |
|---|---|---|
| `brandAnthropic` | #D97757 | `claude-cli`, `anthropic` |
| `brandOpenAI` | #10A37F | `codex`, `openai` |
| `brandGemini` | #4285F4 | `gemini` |
| `brandOllama` | #9D9D9D dark / #5C6474 light | `ollama` |
| `brandCustom` | falls back to existing `accent` | `custom`, unknown |

Both light and dark themes get the same tokens (brand colors are brand-stable, not theme-derived). Border + fill use the same color at 12% / 35% alpha respectively.

Identical-brand, different-transport pairs (`claude-cli`/`anthropic`, `codex`/`openai`) intentionally share the same brand color — same vendor, just different transport.

### 7. Cross-cutting · architecture & widget rules

Per [CLAUDE.md](../../../CLAUDE.md):

- **No widget violations.** All new widgets read providers via notifiers (`agentPermissionRequestProvider`, new `agentUserInputRequestProvider`, `chatActionsProvider`, `codeApplyActionsProvider`). No service imports in widget files.
- **Failure unions.** `CodeApplyFailure` already exists. No new failure types needed for surfaces 1, 2, 3, 4 (these don't initiate operations that can fail in user-actionable ways — UI state derived from existing notifiers).
- **Logging.** New notifiers (`AgentUserInputRequestNotifier`) follow the matrix in CLAUDE.md — `dLog` only on caught exceptions being turned into `AsyncError`. No widget-layer logging.
- **Naming.** New files follow conventions: `agent_user_input_request_notifier.dart` in `features/chat/notifiers/`; `apply_diff_card.dart` and `tool_phase_pill.dart` in `features/chat/widgets/`.
- **No `Process.run` / `dart:io` / Dio additions in widgets.** All new I/O is through existing datasources.

## Surface inventory

Files touched (high-level — implementation plan will enumerate):

**New files:**
- `lib/features/chat/notifiers/agent_user_input_request_notifier.dart`
- `lib/features/chat/widgets/apply_diff_card.dart`
- `lib/features/chat/widgets/tool_phase_pill.dart`
- `lib/features/chat/widgets/brand_chip.dart` (or extend existing `_BadgeChip`)
- `lib/features/chat/widgets/session_status_dot.dart`

**Modified files:**
- `lib/data/ai/models/provider_runtime_event.dart` — new `ProviderUserInputRequest` variant
- `lib/data/ai/datasource/codex_session.dart` — branch `_handleServerRequest` for `requestUserInput`; new `respondToUserInputRequest`
- `lib/data/ai/datasource/codex_cli_datasource_process.dart` — expose `respondToUserInputRequest` to repository layer
- `lib/data/ai/datasource/claude_cli_stream_parser.dart` — intercept `tool_use` for `AskUserQuestion`
- `lib/data/ai/datasource/{anthropic,openai,gemini,ollama,custom}_remote_datasource_dio.dart` — register `AskUserQuestion` as a default tool
- `lib/data/ai/repository/*` — surface `respondToUserInputRequest`
- `lib/core/theme/app_colors.dart` — add brand-color tokens
- `lib/features/chat/widgets/tool_call_row.dart` — asymmetric badge coloring
- `lib/features/chat/widgets/message_bubble.dart` — render new cards in slot order; always-visible toolbar
- `lib/features/chat/widgets/ask_user_question_card.dart` — hide stepper when `totalSteps == 1`; info-blue color mode
- `lib/features/chat/widgets/provider_label.dart` — add `brandColorFor`
- session list widgets — add `SessionStatusDot` to row prefix
- `pubspec.yaml` — confirm `re_highlight` ayu-dark and ayu-light themes are accessible (they ship with the package; only import strings change)

**Deleted:**
- `lib/features/chat/widgets/apply_code_dialog.dart` (snackbar stub) — replaced by `ApplyDiffCard`

## Open questions resolved during brainstorming

- **Spec scope** → one bundled PR.
- **Code-block theme** → Ayu Dark + Ayu Light.
- **Question card color** → info-blue; reuse existing widget with stepper hidden.
- **Apply-diff format** → inline-in-bubble.
- **Thinking direction** → phase pill at tail + persistent tool cards.
- **Message-icon visibility** → always-visible row below bubble.
- **Tool-card body** → collapsed by default; `▾ show output` to reveal.
- **Phase classifier** → registry-driven (`requiresFilesystem` → I/O blue; `shellsOut` → tool amber; else → think teal).
- **Apply-button placement** → file-header right side.
- **Badge placement** → per-card head row.
- **Badge color treatment** → brand chip + neutral model chip.

## Risks

- **`AskUserQuestion` tool schema across API providers.** Anthropic's tool-use, OpenAI function-calling, Gemini's function declarations, and Ollama's tool format all differ in input-schema syntax. The implementation plan must declare the same logical schema in each provider's native shape. Test path: a happy-path call per provider in dev.
- **Codex `requestUserInput` payload structure.** Today's `_handleServerRequest` for this method routes it as a permission request; the prompt / choices fields aren't extracted. Implementation plan must inspect a real Codex `params` dump (the existing routing means we've never observed the full payload shape) and confirm field names before declaring the variant final.
- **Claude CLI stream-json `AskUserQuestion` shape.** I haven't observed a real Claude CLI session emitting this tool. The plan must capture a real `stream_event` example before locking the parser branch.
- **Ayu palette + diff add/del contrast.** Ayu's lime-green strings (#AAD94C) sit close to its diff-add tinting (rgba(170,217,76,0.12)). Visual review needed during implementation; if contrast against bg drops below WCAG AA, fall back to a separate diff-marker color.
- **Migration of existing `AskUserQuestion` wizard usages.** The card refactor must not break the current onboarding wizard flows. Plan calls for keeping a `WizardMode` vs. `AgentMode` switch on the widget.
