# Claude Code CLI as Anthropic Inference Transport — Design

**Date:** 2026-04-23
**Phase:** 7 — see [roadmap](../roadmap/agentic-executor-roadmap.md)
**Status:** Design approved, implementation plan pending
**Owner:** Code Bench — agentic coding assistant

---

## 1. Goal

Let users with a Claude Pro/Max subscription route Anthropic inference through their local `claude` binary instead of a paid Anthropic API key, reusing their subscription and avoiding a second bill.

Concretely: add a new `ClaudeCliRemoteDatasourceProcess` that satisfies the existing [AIRemoteDatasource](../../../lib/data/ai/datasource/ai_remote_datasource.dart) interface by spawning `claude -p --output-format stream-json` via `Process.start`. Users opt in per provider in the Providers screen. The chat, session, and tool-use layers above the datasource do not change — Claude Code's stream-json events parse into Code Bench's existing `StreamEvent` shape.

## 2. Context & framing

Claude Code CLI is an **agent**, not a pure inference endpoint. When invoked via `claude -p "<prompt>"`, Claude Code runs its own tool loop (Read, Edit, Bash, Grep, MCP) using ~20 KB of its own baked-in system prompt. It cannot be reduced to a chat-completion shim.

That means a CLI-routed session is driven by Claude Code's agent, not Code Bench's. Code Bench's Phase 1–6 tool stack (grep, bash, web_fetch, Code Bench's MCP) is bypassed on the CLI path — Code Bench becomes the UI, persistence, and project-management shell around the CLI's session. The user's subscription reuse goal is fully met; the trade-off is that Code Bench's custom tools aren't available on this path.

This is the only architecturally viable option. The brainstorm ruled out three alternatives:

- **Pure-inference transport via `--tools ""`**: suppresses all tool use, producing a non-agentic chat experience. Rejected — breaks the whole product on the CLI path.
- **External-tools-via-MCP**: expose Code Bench's tool registry as an MCP server to `claude --mcp-config`. Rejected — Claude Code is still orchestrator; tools are just remote-mounted. Complexity without a corresponding gain.
- **Bidirectional `--input-format stream-json` permission relay**: undocumented, unproven. Rejected — fights the CLI's architecture.

## 3. Scope

### In scope (v1)

- `ClaudeCliRemoteDatasourceProcess` concrete datasource for `AIProvider.anthropic`.
- Abstract base `CliRemoteDatasource` that Phases 8 (Codex) and 9 (Gemini) will extend.
- `CliDetectionService` with TTL-cached detection + auth probe.
- Settings persistence for `anthropicTransport: "api-key" | "cli"`.
- Providers-screen two-option card for the Anthropic row; detection shown always (even when inactive).
- Stream-json parser mapping Claude Code events to Code Bench's `StreamEvent` union.
- Single per-delegation permission card reusing existing infrastructure.
- Cancellation via `SIGTERM` → `SIGKILL`, mirroring the Bash datasource.
- Typed `ClaudeCliFailure` union with six concrete variants.

### Out of scope

- **MCP bridging.** MCP servers configured in Code Bench (Phase 5) do not apply when CLI transport is active. Claude Code has its own MCP config. Cross-mounting is deferred.
- **System prompt injection.** No `--append-system-prompt` in v1. Claude Code's built-in prompt applies; Code Bench does not override it.
- **Concrete Codex or Gemini adapters.** Phases 8 and 9. The Providers screen shows them as disabled "Coming soon" options in v1.
- **Hook event rendering.** `--include-hook-events` is not enabled. SessionStart/Stop/PreToolUse events would clutter the transcript.
- **Silent fallback to API key** on CLI errors. Users who opt into CLI transport did so deliberately; silently billing them for API use would violate the cost-reuse goal.
- **Rate-limit event surfacing.** `rate_limit_event` is logged but not rendered. Can be added later if users ask.

## 4. User-facing behavior

### 4.1 Providers screen (Anthropic row)

Each provider card uses a **symmetric three-part layout** so the CLI and API-key transports are peers, not baseline-plus-override:

```
┌─ Anthropic ───────────────── ● Active: <Transport> ──┐
│                                                       │
│  [Active transport's full panel]                      │
│                                                       │
│ ──────────────────────────────────────────────────────│
│  Route through Claude Code CLI                  ○─●   │
│  [Inactive transport's one-line summary]              │
└───────────────────────────────────────────────────────┘
```

The active transport's full panel and the inactive transport's summary swap places when the switch flips. OFF and ON are mirror images; there is no structural "primary" transport in the layout.

**Switch states (Anthropic row):**

| State | Active panel shown | Inactive summary alongside switch |
|---|---|---|
| OFF | Full API-key input with `[Test]` and `● saved` badge | `Route through Claude Code CLI` + `● detected · v2.1.104 · authenticated` + "Use your Claude subscription instead of the API key." |
| ON  | CLI status card — version, auth status, binary path, "Inference routed through `/opt/homebrew/bin/claude`" | `Route through Claude Code CLI` + `API key: sk-ant-••••abcd · saved · inactive · Edit` |

**Header indicator.** `● Active: API Key` or `● Active: Claude Code CLI` is always shown in the card header — glanceable status without reading the switch. A secondary hint at the right of the header describes the other transport's state: `Claude Code CLI detected`, `API key saved as fallback`, or `Codex CLI coming in Phase 8` (OpenAI row) / `Gemini CLI coming in Phase 9` (Gemini row).

**Smart switch default (per provider, driven by what's configured):**

| API key saved? | CLI detected + authed? | Switch default | Rationale |
|---|---|---|---|
| Yes | No  | OFF | Only option that works. |
| No  | Yes | ON  | Only option that works. |
| Yes | Yes (first time) | OFF | Preserve existing behavior — no surprise auto-switch for existing users. |
| Yes | Yes (returning) | last choice | Sticky — whatever was persisted in the prior session. |
| No  | No  | OFF (disabled) | Neither transport configured; user must add an API key or install the CLI. |

**Detection.** Runs on Providers screen open and on the `↻ Re-check` link in the CLI panel. Cached for 2 minutes via `CliDetectionService`.

**Detection states and switch enablement:**

- `detected + authenticated` → switch enabled.
- `detected + unauthenticated` → switch disabled. Inactive summary shows "Run `claude auth login` in a terminal" with a copy-to-clipboard button.
- `not installed` → switch disabled. Inactive summary shows an install-instructions doc link.

**OpenAI and Gemini rows (v1).** Same three-part layout, switch permanently disabled. Secondary header hint reads "Codex CLI coming in Phase 8" / "Gemini CLI coming in Phase 9". This keeps the Providers screen visually consistent across all three provider rows and prepares the widget surface for Phases 8 and 9 to drop in their adapters.

**Persistence.** Flipping the switch writes to secure storage immediately. An active chat session keeps its current transport until the next message — no mid-stream switch.

**Design constraint acknowledged.** The switch model supports exactly 2 transports per provider. If a future phase ever introduces a 3rd transport for a provider (unlikely on the current roadmap), the card migrates from switch to radios or tabs.

### 4.2 Chat flow on CLI transport

1. User types a message and hits send.
2. Code Bench shows its standard permission card:
   > **Delegate to Claude Code CLI?**
   > Claude Code will autonomously read, edit, and run shell commands in `<project path>` using its built-in tools. Code Bench's permission rules do not apply to its actions.
3. On approval, Code Bench spawns `claude -p --permission-mode bypassPermissions --output-format stream-json --include-partial-messages --session-id <uuid>` (plus `--resume <uuid>` on subsequent turns), `workingDirectory: projectPath`.
4. Events stream into the chat transcript as they arrive:
   - Text content → normal assistant message text, token-by-token.
   - Tool use + tool result → tool cards rendered **as receipts** (already-executed, informational). Each card tagged "via Claude Code" to distinguish from Code Bench-agent tool cards.
   - Thinking blocks → existing thinking UI.
5. User can stop mid-stream via the chat composer's stop button.

### 4.3 Error states on send

- CLI not installed → snackbar: "Claude Code CLI not installed. Install it or switch back to API Key in Providers." Action button: "Open Providers."
- CLI unauthenticated → snackbar: "Claude Code CLI not authenticated. Run `claude auth login` or switch to API Key."
- CLI crashed (non-zero exit) → snackbar: "Claude Code exited unexpectedly (exit code N). Check the logs."
- CLI timed out → snackbar: "Claude Code did not respond in time."
- Stream parse failure → snackbar: "Unexpected output from Claude Code. Please report this."
- Cancelled → no snackbar; chat shows a "cancelled" state inline.

## 5. Architecture

### 5.1 Integration point

The existing [ai_repository_impl.dart](../../../lib/data/ai/repository/ai_repository_impl.dart) holds `Map<AIProvider, AIRemoteDatasource>`. Only the construction of the `anthropic` entry changes:

```dart
AIProvider.anthropic: settings.anthropicTransport == 'cli'
    ? ClaudeCliRemoteDatasourceProcess(detectionService)
    : AnthropicRemoteDatasourceDio(await storage.readApiKey('anthropic') ?? ''),
```

The `aiRepository` `@Riverpod(keepAlive: true)` provider reads the transport setting from secure storage alongside API keys. When the user flips the transport switch, the provider is invalidated so the swap takes effect on the next message.

### 5.2 New types

```dart
// lib/data/ai/datasource/cli_remote_datasource.dart
abstract class CliRemoteDatasource implements AIRemoteDatasource {
  String get binaryName;
  Future<CliDetection> detectInstalled();
  Future<CliAuthStatus> checkAuthStatus();
  // streamMessage(...), testConnection(...), fetchAvailableModels(...) inherited
}

// lib/data/ai/datasource/claude_cli_remote_datasource_process.dart
class ClaudeCliRemoteDatasourceProcess extends CliRemoteDatasource {
  @override String get binaryName => 'claude';
  @override AIProvider get provider => AIProvider.anthropic;
  // ...
}

// lib/services/cli/cli_detection_service.dart
@Riverpod(keepAlive: true)
class CliDetectionService extends _$CliDetectionService {
  @override Map<String, CliDetection> build() => {};
  Future<CliDetection> probe(String binary, {Duration ttl = const Duration(minutes: 2)});
  void invalidate(String binary);
}

// lib/data/ai/models/cli_detection.dart
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

enum CliAuthStatus { authenticated, unauthenticated, unknown }
```

### 5.3 File placements

| File | Purpose |
|---|---|
| `lib/data/ai/datasource/cli_remote_datasource.dart` | Abstract base shared with Phases 8/9 |
| `lib/data/ai/datasource/claude_cli_remote_datasource_process.dart` | Concrete Claude implementation |
| `lib/data/ai/datasource/claude_cli_stream_parser.dart` | Private line-parser utility (can be inlined if small) |
| `lib/data/ai/models/cli_detection.dart` | `CliDetection`, `CliAuthStatus` |
| `lib/services/cli/cli_detection_service.dart` | Detection + TTL cache |
| `lib/features/providers/widgets/claude_cli_card.dart` | Detection UI for the Anthropic row |
| `lib/features/providers/widgets/anthropic_provider_card.dart` | Composite card (API key + CLI option + transport radio) |
| `lib/features/providers/notifiers/claude_cli_failure.dart` | Typed failure union |
| `test/data/ai/datasource/claude_cli_stream_parser_test.dart` | Parser unit tests against fixtures |
| `test/fixtures/claude_cli/*.jsonl` | Captured stream-json fixtures |
| `test/services/cli/cli_detection_service_test.dart` | Detection unit tests |

Follows CLAUDE.md architecture constraints: `Process.start` / `dart:io` confined to `lib/data/**/datasource/` and `lib/services/`; `*_process.dart` suffix for process-spawning files.

## 6. Settings persistence

One new secure-storage key: `anthropic_transport`, values `"api-key" | "cli"`, default `"api-key"`.

Extend the existing `apiKeysProvider` state with an `anthropicTransport: String` field alongside the existing `anthropic` (API key) field. Load and save through the same secure-storage pathway. Existing users see no change — their `anthropic_transport` key is absent and falls back to `"api-key"`.

No persistence for OpenAI/Gemini transport in v1 (those rows are display-only for the CLI option).

## 7. Stream parser

### 7.1 Invocation shape

```
claude -p <prompt>
  --output-format stream-json
  --include-partial-messages
  --permission-mode bypassPermissions
  --session-id <uuid>        # first turn
  --resume <uuid>            # subsequent turns
  (workingDirectory: projectPath via Process.start)
```

### 7.2 Event mapping

Claude Code emits line-delimited JSON. Each line is parsed and mapped to a `StreamEvent` variant (existing union in [lib/data/ai/models/stream_event.dart](../../../lib/data/ai/models/stream_event.dart)):

| Claude Code event line | → `StreamEvent` |
|---|---|
| `{type:"assistant", ..., content_block_delta: {type:"text_delta", text}}` | `TextDelta(text)` |
| `{type:"assistant", ..., content_block_start: {type:"tool_use", id, name}}` | `ToolUseStart(id, name)` |
| `{type:"assistant", ..., content_block_delta: {type:"input_json_delta", partial_json}}` | `ToolUseInputDelta(id, partialJson)` |
| `{type:"assistant", ..., content_block_stop: {index}}` on a tool_use block | `ToolUseComplete(id, fullInput)` |
| `{type:"user", ..., content: [{type:"tool_result", tool_use_id, content, is_error}]}` | `ToolResult(toolUseId, content, isError)` |
| `{type:"assistant", ..., content_block.type:"thinking"}` + thinking_delta | `ThinkingDelta(text)` |
| `{type:"assistant", ..., message_stop}` | `StreamDone()` |
| `{type:"rate_limit_event", ...}` | logged via `dLog`, not rendered |
| `{type:"system", subtype:"init"}` | ignored |
| `{type:"system", subtype:"hook_*"}` | ignored |
| Unrecognized line | logged via `dLog`, parser does not throw |
| Malformed JSON | `ClaudeCliFailure.streamParseFailed` emitted on the error stream |

Tool input reconstruction: `ToolUseStart` + successive `ToolUseInputDelta`s accumulate a partial JSON string; `ToolUseComplete` parses the accumulated string into a `Map<String, dynamic>`. If parsing fails, emit `streamParseFailed` — don't swallow silently.

## 8. Permission gate

Reuse [agent_permission_request_notifier.dart](../../../lib/features/chat/notifiers/agent_permission_request_notifier.dart) and [permission_request_card.dart](../../../lib/features/chat/widgets/permission_request_card.dart). Before each CLI invocation, `streamMessage()` issues a `PermissionRequest`:

```dart
PermissionRequest(
  toolEventId: <turn id>,
  toolName: 'claude-cli',
  summary: 'Delegate to Claude Code CLI',
  input: {
    'prompt': userMessage.substring(0, min(200, userMessage.length)),  // preview only
    'workingDirectory': projectPath,
    'sessionId': sessionUuid,
    'warning': 'Claude Code will autonomously read, edit, and run shell commands in this directory using its built-in tools. Code Bench\'s permission rules do not apply to its actions.',
  },
)
```

Approval → spawn with `--permission-mode bypassPermissions`. Deny → stream emits `ClaudeCliFailure.cancelled` and terminates cleanly without spawning. No process is ever started without user approval.

Tool cards rendered from `tool_use` / `tool_result` events are **informational only** — no approve/deny buttons. A small "via Claude Code" tag visually distinguishes them from Code Bench-agent tool cards.

## 9. Cancellation

User hits the stop button in the chat composer → `Process.kill(ProcessSignal.sigterm)`. Wait up to 5 seconds for clean exit. If not exited, `Process.kill(ProcessSignal.sigkill)`. Mirrors [bash_datasource_process.dart](../../../lib/data/bash/datasource/bash_datasource_process.dart) exactly.

Partial tool cards remain rendered (context for the user on what was in flight when they stopped). The stream emits `ClaudeCliFailure.cancelled` and closes.

## 10. Error handling

Typed union in `lib/features/providers/notifiers/claude_cli_failure.dart`:

```dart
@freezed
sealed class ClaudeCliFailure with _$ClaudeCliFailure {
  const factory ClaudeCliFailure.notInstalled() = ClaudeCliNotInstalled;
  const factory ClaudeCliFailure.unauthenticated() = ClaudeCliUnauthenticated;
  const factory ClaudeCliFailure.crashed(int exitCode, String stderr) = ClaudeCliCrashed;
  const factory ClaudeCliFailure.timedOut() = ClaudeCliTimedOut;
  const factory ClaudeCliFailure.streamParseFailed(String line, Object error) = ClaudeCliStreamParseFailed;
  const factory ClaudeCliFailure.cancelled() = ClaudeCliCancelled;
  const factory ClaudeCliFailure.unknown(Object error) = ClaudeCliUnknown;
}
```

Widget layer uses an exhaustive `switch` per CLAUDE.md Rule 3. No silent fallback to API key on any failure variant.

`sLog` is used for security-relevant events (detection failures that look like tampering, unexpected process exit codes). `dLog` for debug breadcrumbs. Raw stderr is logged at the datasource layer once; the widget layer logs nothing additional.

## 11. Testing strategy

### 11.1 Unit tests

- **`ClaudeCliStreamParser`** against golden fixtures captured from real `claude -p` runs. Fixtures in `test/fixtures/claude_cli/`:
  - `text_only.jsonl` — simple text response, no tools.
  - `single_tool_use.jsonl` — one Read tool call with result.
  - `multi_tool_use.jsonl` — sequential tool calls.
  - `thinking.jsonl` — response with thinking block.
  - `malformed.jsonl` — intentionally bad lines to verify error handling.
  - Cover every row in the §7.2 event mapping table, plus parse-failure surface.
- **`CliDetectionService`** with a `FakeProcessRunner` injected via constructor:
  - `--version` outputs `2.1.104 (Claude Code)` → `CliInstalled` with version parsed.
  - `--version` fails with `ENOENT` → `CliNotInstalled`.
  - `claude auth status` output variants → each `CliAuthStatus` mapped correctly.
  - TTL cache: second call within TTL returns cached value; `invalidate()` forces re-probe.

### 11.2 Integration test (manual / optional CI)

- **`test/integration/claude_cli_smoke_test.dart`** (skipped unless `CLAUDE_CLI_AVAILABLE=1`): spawns real `claude -p --tools "" "Say hi"` with a short timeout; asserts at least one `TextDelta` arrives. Intended for local smoke, not CI gate.

### 11.3 Manual QA checklist

Belongs in the implementation plan. Covers: detect / not-detect / auth / unauth flows in the Providers screen; full-turn chat with tool use; stop-button mid-stream; stream parse error injection (via a test fixture-replay route); switching transport between turns in the same session; declining the permission card.

## 12. Open questions

None — all resolved in the 2026-04-23 brainstorm.

### Resolved during brainstorm

- **Agent replacement vs. inference-transport framing** → inference transport (at the `AIRemoteDatasource` layer), with the honest acknowledgment that Claude Code is itself an agent.
- **Option B (Code Bench loop drives CLI)** → infeasible. `--tools ""` kills agent behavior; tool schemas can't be passed via CLI flags; MCP relay is structurally Option A.
- **Permission model** → A.1 (single card per delegation, `bypassPermissions` under the hood, tool cards as receipts).
- **v1 scope** → Claude only. Codex and Gemini deferred to Phases 8 and 9. `CliRemoteDatasource` abstract base built now so those phases are plumbing.
- **Transport persistence** → global per provider (one setting, applies everywhere).
- **Selector style (switch vs tabs vs radio)** → switch, with symmetric three-part card layout (active panel + toggle + inactive summary), active-transport indicator in the card header, and smart-default routing driven by what's configured. Resolves "API key as baseline" asymmetry.
- **Behavior on missing / unauthenticated CLI at send time** → typed failure + snackbar, no silent fallback.
- **Detection visibility** → always shown, even on API-key transport, so the subscription-reuse path is discoverable.
- **Hook events** → dropped from the stream.
- **Partial messages** → enabled (`--include-partial-messages`) for token-by-token parity with the API-key path.
- **Cancellation** → `SIGTERM` → 5 s grace → `SIGKILL`, mirroring Bash.

## 13. Related

- [Roadmap — Phase 7](../roadmap/agentic-executor-roadmap.md)
- [Phase 4 Bash tool spec](./2026-04-22-bash-tool-design.md) — process-spawn and cancellation pattern
- [Phase 5 MCP client spec](./2026-04-22-mcp-client-design.md) — service lifecycle and registry patterns
- [Phase 6 WebFetch plan](../plans/2026-04-22-web-fetch.md) — latest permission-card pattern
