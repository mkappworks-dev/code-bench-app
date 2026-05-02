# Agentic Executor Roadmap

**Last updated:** 2026-05-02
**Owner:** Code Bench — agentic coding assistant

This document is the source of truth for the agentic executor build-out. Read this before brainstorming or planning any new phase. It captures the sequencing rationale, key decisions, and Q&A from design sessions so future sessions do not re-litigate settled questions.

---

## Status Overview

| Phase | Description                                  | Status                                 |
| ----- | -------------------------------------------- | -------------------------------------- |
| 1     | Tool Registry Refactor                       | ✅ Done — PR #27, commit `1188b55`     |
| 2     | Grep + Glob + Parallel execution             | ✅ Done — PR #28, commit `f7acbc8`     |
| 3     | Tool-output truncation                       | ✅ Done — commit `5b257c8`             |
| 4     | Bash tool (permission-gated)                 | ✅ Done — commits `a51871d`, `d435681` |
| 5     | MCP client (stdio + HTTP/SSE)                | ✅ Done — PR #31, commit `7d9fb1a`     |
| 6     | WebFetch                                     | ✅ Done — PR #33, commit `651fff4`     |
| 7     | Anthropic inference via Claude Code SDK      | ✅ Done — branch `feat/2026-04-23-claude-cli-inference-transport` |
| 8     | OpenAI inference via Codex SDK               | ✅ Done — branch `feat/2026-04-23-claude-cli-inference-transport` |
| 9     | Gemini inference via Gemini SDK              | ⬜ Not started — abstraction now landed (Phases 7/8) |
| —     | Subagent delegation                          | 🚫 Deferred / YAGNI                    |
| —     | WebSearch                                    | 🚫 Deferred                            |

---

## Original Sequencing Rationale

From the initial 6-gap roadmap session:

| #   | Phase                          | Gap         | Why here                                                                                           |
| --- | ------------------------------ | ----------- | -------------------------------------------------------------------------------------------------- |
| 1   | Tool registry refactor         | 1A          | Prerequisite for 2, 5, and MCP. Pure win, contained blast radius.                                  |
| 2   | Grep + Glob tools              | 2 (partial) | Highest capability gain per LOC. Registry from Phase 1 makes this a one-file add.                  |
| 3   | Parallel read-only tools       | 3B          | Dramatic perceived speedup. Isolated to the loop; no wire/schema changes.                          |
| 4   | Tool-output truncation         | 4B          | Needed as soon as tool breadth grows — more tools = more bloat per round.                          |
| 5   | Bash tool (permission-gated)   | 2 (partial) | Highest capability, highest risk. Defer so Phases 1–4 give usage telemetry to inform the denylist. |
| 6   | Anthropic provider via adapter | 5B          | Pure new-market work. Deferred — no concrete use case identified.                                  |
| 7   | MCP client                     | 1B          | Biggest protocol surface. Only worth it once registry/adapter abstractions are stable.             |
| 8   | Subagent delegation            | 6           | YAGNI until a concrete workflow demands it.                                                        |
| 9   | WebFetch / WebSearch           | 2 (partial) | Needs network-policy UX which is its own design problem.                                           |

> **Note:** Original Phases 2 and 3 (Grep+Glob and Parallel) were combined into a single implementation plan because they share the same AgentService change surface and are low risk together.

---

## Phase 1 — Tool Registry Refactor ✅

**Done.** See PR #27 (`1188b55`). No further decisions needed.

The `ToolRegistry.register()` seam is the hook for future MCP tool injection.

---

## Phase 2 — Grep + Glob + Parallel Execution ✅

**Spec:** `docs/superpowers/specs/2026-04-22-grep-glob-parallel-design.md`
**Plan:** `docs/superpowers/plans/2026-04-22-grep-glob-parallel.md`

Key decisions already locked in the spec — do not re-litigate:

- ripgrep when available, pure-Dart fallback (progressive enhancement)
- Missing rg → persistent UI warning in Settings, not an error; fall back silently
- 2 context lines, 100-match cap, flat `file:line:content` format (matches Claude Code)
- Max 4 parallel read-only calls per round (matches Claude Code)
- Backend selection lives in `grepToolProvider` (services layer), not in data layer — arch constraint

---

## Phase 3 — Tool-output Truncation ✅

**Spec:** `docs/superpowers/specs/2026-04-22-tool-output-truncation-design.md`
**Plan:** `docs/superpowers/plans/2026-04-22-tool-output-truncation.md`

### Settled decisions

**Where the cap lives:** Central enforcement in `AgentService`, not per-tool. Applied to every tool result before it is added to the wire message. Tools still do their own semantic caps (grep's 100-match limit, list_dir's entry cap) — the agent-level cap is a safety net that covers all current and future tools including Bash, MCP, and WebFetch.

**Cap size:** 50 KB per tool result. Rationale: Claude Code uses 200 KB but Code Bench hits the Anthropic API directly — context window bloat affects cost and quality. `read_file` allows 2 MB files; without this cap one large read could consume ~500 K tokens. 50 KB ≈ ~12 K tokens, substantial but not window-dominating.

**Enforcement point:** Wire time (`_buildWireMessages`) — full output stays in DB and UI; only the API payload is capped.

**Scope:** Both `te.output` and `te.error` — both fields go into the same `content` wire field. Phase 4 (Bash) will route large stderr through `te.error`.

**Truncation notice:** `\n[Output truncated at 50 KB. Use grep to search for specific content or read a narrower file range.]`

### Open questions

None.

---

## Phase 4 — Bash Tool (permission-gated) ✅

**Spec:** `docs/superpowers/specs/2026-04-22-bash-tool-design.md`
**Plan:** `docs/superpowers/plans/2026-04-22-bash-tool.md`

**Done.** Implementation commits: `cf2e889` (BashDatasource), `14ed4b8` (BashTool), `4ee01e9` (permission card), `2ff9be9` (wiring).

Key decisions locked in:

- Spawns `/bin/sh -c <command>` via `Process.start` with `runInShell: false` — pipes and redirects work via the shell
- Every bash call requires explicit user approval — no auto-approve path
- Working directory locked to project root (`ctx.projectPath`)
- CLAUDE.md updated to document `bash_datasource_process.dart` as an approved exception to the `runInShell: true` ban

---

## Phase 5 — MCP Client (stdio + HTTP/SSE) ✅

**Done.** See PR #31 (`7d9fb1a`).
**Spec:** `docs/superpowers/specs/2026-04-22-mcp-client-design.md`
**Plan:** `docs/superpowers/plans/2026-04-22-mcp-client.md`

### Settled decisions

**Protocol scope:** Local stdio servers (JSON-RPC over stdin/stdout) + HTTP/SSE servers. Matches Claude Code's two transport modes; covers most published MCP servers.

**Out of scope:** Auth flows, resource subscriptions, sampling, WebSearch.

**Integration point:** `ToolRegistry.register()` — added in Phase 1 for this exact purpose. MCP tools register at runtime and are indistinguishable from built-ins from the model's perspective.

**Lifecycle:** Session-scoped on-demand (Approach A). `McpService.startSession()` runs at the top of each `runAgenticTurn`; teardown runs in `finally`. No app-startup startup; no cross-session caching complexity.

**Configuration UX:** New "MCP Servers" tab in Settings. Form ↔ JSON dual editor in an add/edit dialog. Env vars stored in SQLite (not secure storage) for v1.

**Permission gating:** Always prompt (`ToolCapability.shell`) — MCP is third-party code.

**Tool naming:** `server-name/tool-name` (slash separator) in the registry. UI converts to `server › tool_name` for display.

**Error handling:** Server startup failures are non-fatal — `McpService` logs via `sLog`/`dLog`, marks the server `error` in `McpServerStatusNotifier`, and the session continues without that server's tools.

**Timeouts:** 30 s initialization, 120 s per tool call.

### Open questions

None — all design questions resolved in the 2026-04-22 design session.

---

## Phase 6 — WebFetch ✅

**Done.** See PR #33 (`651fff4`).
**Plan:** `docs/superpowers/plans/2026-04-22-web-fetch.md`

Key decisions locked in:

- HTTP fetch only — strip HTML to markdown, return content. No WebSearch.
- Permission gate per fetch request (same pattern as Bash tool).
- SSRF guard blocks localhost, 127.0.0.1, 10.x, 172.16-31.x, 192.168.x. Hardened with `dart:io InternetAddress` IPv6 coverage in `fba0f46`.
- No external API key — pure HTTP.
- Primary use case: "fetch the docs for this package," "read this GitHub issue," "check this API reference."
- Authenticated requests deferred as YAGNI.

---

## Phase 7 — Anthropic inference via Claude Code SDK ✅

**Done.** Shipped on branch `feat/2026-04-23-claude-cli-inference-transport`. The transport switch (API Key | Claude SDK) is exposed on the Anthropic provider card; selecting "Claude SDK" routes inference through the locally-installed `claude` binary via `ClaudeSdkDatasourceProcess`. Tool events from the CLI's own agent loop render as receipts; a single permission card gates the whole delegation.

### What this is

A new `AIRemoteDatasource` backed by the local `claude` CLI instead of the Anthropic HTTP API. Users with a Claude Pro/Max subscription route Anthropic inference through their installed Claude Code binary — reusing their subscription instead of paying for a second API key.

Because Claude Code CLI is itself an agent (not a pure inference endpoint), a session routed through the CLI is driven by Claude Code's own agent loop, tools, and MCP. Code Bench's Phase 1–6 tool registry is bypassed on that path. Code Bench becomes the UI, transcript persistence, and project-management shell around the CLI's session — same UI chrome, different agent under the hood.

### Settled decisions (from 2026-04-23 brainstorming)

**Framing — inference transport replacement, not session-level agent routing.** Integration point is [ai_repository_impl.dart:22-32](lib/data/ai/repository/ai_repository_impl.dart#L22-L32) — the `Map<AIProvider, AIRemoteDatasource>` map. A new concrete `ClaudeCliRemoteDatasourceProcess` is swapped in when the user selects "Claude Code CLI" transport for the Anthropic provider in the Providers screen. The chat, session, and tool-use layers above the repository don't change.

**CLI-as-agent accepted (Option A.1).** `claude -p` cannot be reduced to a pure inference endpoint. `--tools ""` disables all tools but also kills agentic behavior; `--mcp-config` can expose Code Bench's tools to the CLI but that's Claude Code orchestrating a remote toolset, not Code Bench driving. The cleaner path — and the one that matches the user's actual goal (reuse subscription) — is to let Claude Code drive the loop and render its transcript in Code Bench's UI.

**Permission model (A.1) — single gate per delegation.** One Code Bench permission card per user turn on the CLI transport. The card summary: *"Delegate to Claude Code? This will autonomously read, edit, and run shell commands in `<project path>`."* On approval, spawn with `--permission-mode bypassPermissions`. Claude Code's built-in per-tool permission prompts are OFF; Code Bench's existing permission infrastructure (`AgentPermissionRequestNotifier`, `PermissionRequestCard`) is the single gate. This matches the Bash / WebFetch pattern (one card, one action).

**Tool cards render as receipts, not approvals.** `tool_use` and `tool_result` events stream via `--output-format stream-json` and render in Code Bench's existing tool-card UI. These are informational — already executed by Claude Code — and the user does NOT approve individual tool calls mid-stream. This is structurally different from Code Bench's built-in agent where each tool_use is gated; here, the gate is at delegation time.

**Stream format — verified.** Claude Code CLI emits Anthropic API–format stream-json, wrapped in `type: "assistant"` / `type: "user"` envelopes with session metadata. Parser maps to Code Bench's existing `StreamEvent` model ([lib/data/ai/models/stream_event.dart](lib/data/ai/models/stream_event.dart)). Event types observed in a live run: `tool_use`, `tool_result`, `thinking`, `text`, `content_block_delta`, `input_json_delta`, `message_start/stop`, `rate_limit_event`, `hook_started/response`, `system:init`.

**Session resume.** Pass `--session-id <uuid>` on first turn (Code Bench generates and persists per chat session), then `--resume <uuid>` on subsequent turns. Maps Code Bench session ↔ Claude Code session 1:1. If Claude Code forgets the session (rare), surface a typed failure and start fresh.

**Working directory.** `Process.start(..., workingDirectory: ctx.projectPath)`. Same pattern as [bash_datasource_process.dart](lib/data/bash/datasource/bash_datasource_process.dart).

**Authentication.** `claude auth status` reports authenticated / unauthenticated / unknown. Unauthenticated state shows a "Run `claude auth login` in a terminal" CTA in the Providers screen — the app does not spawn an interactive login itself.

**Providers screen UX.** The Anthropic row in [providers_screen.dart](lib/features/providers/providers_screen.dart) gains a transport picker (segmented control: "API Key" | "Claude Code CLI"). Only one active per provider at a time. Detection + auth status shown under the CLI option. OpenAI and Gemini rows show their CLI options as disabled "Coming soon" (Phases 8 / 9).

**Scope exclusions.**
- MCP servers configured in Code Bench (Phase 5) do NOT apply when CLI transport is active — Claude Code has its own MCP config. v1 documents this in the Providers screen; cross-mounting Code Bench's MCP into the CLI via `--mcp-config` is out of scope.
- System prompt: Code Bench does not inject a system prompt on the CLI transport. Claude Code's built-in prompt (~20K tokens per the `cache_creation_input_tokens` field on a probe) applies. `--append-system-prompt` is not used in v1.
- No concrete Codex or Gemini adapters — those are Phases 8 and 9.

### Architecture sketch

```
AIRepositoryImpl._sources[AIProvider.anthropic]
   = user setting "anthropic.transport" == "api-key"
       ? AnthropicRemoteDatasourceDio(apiKey)
       : ClaudeCliRemoteDatasourceProcess(detectionService)

abstract class CliRemoteDatasource implements AIRemoteDatasource {
   Future<CliDetection> detectInstalled();
   Future<CliAuthStatus> checkAuthStatus();
   // streamMessage(...) from AIRemoteDatasource
}

class ClaudeCliRemoteDatasourceProcess extends CliRemoteDatasource { ... }
// Phase 8: CodexCliRemoteDatasourceProcess
// Phase 9: GeminiCliRemoteDatasourceProcess

class CliDetectionService (lib/services/cli/)
   - cached per binary with TTL
   - runs <cli> --version and <cli> auth status
   - exposes AsyncValue<Map<CliId, CliDetection>> via @riverpod
```

### Open questions (pre-spec)

- `--include-hook-events`: render in UI, or drop? Decision: **drop in v1** — hook events (SessionStart/Stop/PreToolUse) would clutter the transcript.
- `--include-partial-messages`: enable? Decision: **yes** — matches token-by-token streaming on the API-key path.
- Cancellation mid-stream: `SIGTERM` → timeout → `SIGKILL`, mirroring [bash_datasource_process.dart](lib/data/bash/datasource/bash_datasource_process.dart).
- Typed failure surface: `CliNotInstalled`, `CliUnauthenticated`, `CliCrashed`, `CliTimedOut`, `StreamParseFailure` — exhaustive switch per CLAUDE.md Rule 3.

### Timing

Blocks Phases 8 and 9. The `CliRemoteDatasource` abstract base, `CliDetectionService`, permission-card plumbing, and stream-parser framing are all shared infrastructure established here.

---

## Phase 8 — OpenAI inference via Codex SDK ✅

**Done.** Shipped on branch `feat/2026-04-23-claude-cli-inference-transport` alongside Phase 7. The OpenAI provider card gains the same transport switch (API Key | Codex SDK); selecting "Codex SDK" routes inference through `codex app-server` over JSON-RPC 2.0 via `CodexSdkDatasourceProcess`.

### What shipped (vs. original Phase 8 plan)

The original Phase 8 plan assumed Codex would mirror Claude Code's `--output-format stream-json` model (a plain CLI emitting newline-delimited JSON). The pre-spec spike found Codex actually exposes a long-lived `app-server` subcommand speaking JSON-RPC 2.0 over stdin/stdout, with a richer protocol: `initialize` → `account/read` → `thread/start` → `turn/start` → streaming notifications + server-to-client approval requests.

Implementation in this PR:

- **`CodexSdkDatasourceProcess`** — long-lived process per working directory, full JSON-RPC 2.0 client (request/response correlation, server request handling, approval forwarding).
- **Auto-approved auth refresh** — `account/chatgptAuthTokens/refresh` is auto-acked; the token never crosses our process boundary, codex holds and refreshes it internally.
- **Permission-card mapping** — `item/commandExecution/requestApproval`, `item/fileRead/requestApproval`, `item/fileChange/requestApproval`, `applyPatchApproval`, `execCommandApproval` all route to Code Bench's existing permission card.
- **Detection** — `which codex` + version probe with TTL cache, sharing `CliDetectionService` with Claude.
- **Security guards** — workingDirectory and sessionId validated at the RPC boundary via `provider_input_guards.dart`; minimal env (no parent ANTHROPIC/OPENAI/GITHUB tokens leak through to subprocesses).

### Known gaps

Tracked under [Cross-cutting follow-ups](#cross-cutting-follow-ups) — `item/tool/requestUserInput` mapping needs a dedicated user-input event type (Codex-specific), and `binaryPath` should become settings-driven (spans Phases 7/8/9).

### Naming note

The PR uses "Codex SDK" rather than "Codex CLI" in user-facing copy because `codex app-server` is a long-lived RPC server, not a one-shot CLI invocation. The user-facing transport label `'sdk'` reflects this. The original phase title (CLI) is preserved here for continuity but the overview table reads "Codex SDK".

---

## Phase 9 — Gemini inference via Gemini SDK

**Status:** Not started. Abstraction landed in Phases 7/8 — no longer blocked, just unscheduled.

Third concrete provider transport, targeting the `gemini` CLI (Google). Should follow the `AIProviderDatasource` shape established in Phases 7/8 and the `provider_input_guards.dart` validation contract. Permission-card mapping lifts from Codex's approval-request handler.

### Scope

- `GeminiSdkDatasourceProcess` (or equivalent) concrete implementation.
- Gemini event → `ProviderRuntimeEvent` parser.
- Gemini-specific detection and auth probe (extending `CliDetectionService`).
- Providers screen: enable the "Gemini SDK" transport option on the Gemini row (currently a `ComingSoonProviderCard` placeholder).

### Pre-spec spike required

Install Gemini CLI, capture: invocation shape (one-shot vs. long-lived), stream output format, working-directory mechanism, auth status command, session-resume model. Phase 8's experience suggests the shape may not match Claude — keep an open mind about whether Gemini fits the same JSON-RPC `app-server` model, the streaming-CLI model, or a third one.

### Timing

After someone identifies a concrete user pulling for Gemini integration. The abstraction is ready; demand is the gating factor.

---

## Cross-cutting follow-ups

These are gaps that span multiple shipped phases. They are not new capabilities — they polish existing ones. Tracked here (not as new phases) so the roadmap's phase numbers stay reserved for genuinely new executor capability.

Each item names: which phases it spans, and the concrete trigger to act. The trigger matters — without it, follow-ups drift into perpetual "later".

### Settings-driven `binaryPath` for provider transports

**Spans:** Phases 7 (Claude SDK), 8 (Codex SDK), and any future Phase 9 (Gemini SDK).

**Today:** Both `ClaudeSdkDatasourceProcess` and `CodexSdkDatasourceProcess` hardcode the binary name (`'claude'` / `'codex'`) inside their provider functions, with a TODO marker. Whatever binary wins the user's `$PATH` race wins. This works for the 90% case (official installer puts the binary on PATH) but breaks for power users with multiple installs side-by-side, non-PATH installs, or version pinning.

**Work involved:**
- New per-provider field on the settings model (Drift migration).
- Settings UI surface — "Custom binary path" row under each provider's transport card, with validation feedback.
- Security guard at the `Process.start` boundary — must be either a bare name (resolved via `which`) or an absolute path that exists, must not contain shell metacharacters. User-supplied paths cannot be trusted.

**Trigger:** First user report of a non-PATH install or dual-install ambiguity. OR when the settings model is touched for an unrelated reason (e.g., a new settings field for some other feature) — adding a sibling field then is cheap.

### Dedicated user-input event type for Codex

**Spans:** Phase 8 (Codex). Phase 7 (Claude) does not need this — Claude Code's stream-json doesn't expose a user-input request as a distinct RPC; questions surface as plain assistant messages handled by the CLI's own loop. Phase 9 (Gemini) status is unknown until the spike.

**Today:** [`codex_sdk_datasource_process.dart:373-376`](lib/data/ai/datasource/codex_sdk_datasource_process.dart#L373-L376) routes `item/tool/requestUserInput` to `_emitPermissionRequest`, which renders an approve/deny card. That mapping is wrong — the user can't actually answer the question. Approve sends `{decision: 'approved'}` back to Codex, which can't parse it as the answer it asked for; the tool either proceeds with no input or errors.

**Work involved:**
- New `ProviderUserInputRequest` variant on `ProviderRuntimeEvent` (prompt, choices, defaultValue).
- Question-card widget in chat — distinct from the permission card.
- Update `_handleServerRequest` in the Codex datasource to emit the new variant.

**Trigger:** When the question-UI work in the UI improvement queue (Phase 6 of that queue) lands. Backend half is ~15 lines; frontend half is the actual cost. Pair them in a single PR so the variant doesn't ship dead.

---

### Subagent delegation

YAGNI. Code Bench is interactive and session-based. The parallel read-only dispatch (Phase 2) covers the practical performance win. Subagent delegation adds significant complexity (multiple concurrent agent sessions, result aggregation, cancellation propagation, UI representation) with no identified workflow that demands it. Revisit when a concrete use case appears.

### WebSearch

Requires an external search API key (Brave/Bing/Google), adds per-query cost, and the AI can usually construct a docs URL directly. Add when users explicitly need "search the web for this error" without providing a URL.
