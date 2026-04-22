# Agentic Executor Roadmap

**Last updated:** 2026-04-22
**Owner:** Code Bench — agentic coding assistant

This document is the source of truth for the agentic executor build-out. Read this before brainstorming or planning any new phase. It captures the sequencing rationale, key decisions, and Q&A from design sessions so future sessions do not re-litigate settled questions.

---

## Status Overview

| Phase | Description                         | Status                             |
| ----- | ----------------------------------- | ---------------------------------- |
| 1     | Tool Registry Refactor              | ✅ Done — PR #27, commit `1188b55` |
| 2     | Grep + Glob + Parallel execution    | ✅ Done — PR #28, commit `f7acbc8` |
| 3     | Tool-output truncation              | ✅ Done — commit `5b257c8`         |
| 4     | Bash tool (permission-gated)        | ✅ Done — commits `a51871d`, `d435681` |
| 5     | MCP client (stdio + HTTP/SSE)       | ⬜ Not started                     |
| 6     | WebFetch                            | ⬜ Not started                     |
| 7     | CLI Provider Detection & Delegation | ⬜ Not started                     |
| —     | Anthropic provider adapter          | 🚫 Deferred / YAGNI                |
| —     | Subagent delegation                 | 🚫 Deferred / YAGNI                |
| —     | WebSearch                           | 🚫 Deferred                        |

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

**Done.** See commits `a51871d` (plan), `d435681` (implementation). No further decisions needed.

Key decisions already locked in the spec and implemented:

- `runInShell: true` to support pipes and redirects — security risk does not apply to AI-generated, user-approved commands
- Every Bash call requires explicit user approval — no auto-approve path
- Working directory locked to project root
- Existing coding tools denylist applies to the command string
- CLAUDE.md updated to document `bash_datasource_process.dart` as a `runInShell: true` exception (like `ApplyRepository.assertWithinProject`)

---

## Phase 5 — MCP Client (stdio + HTTP/SSE)

**Status:** Not started. No spec or plan yet.

### Settled decisions

**Protocol scope:** Local stdio servers (JSON-RPC over stdin/stdout) + HTTP/SSE servers. This matches the two transport modes Claude Code supports and covers most published MCP servers.

**Out of scope for this phase:** Auth flows, resource subscriptions, sampling. These are the full-spec extras that add significant surface area for marginal gain.

**Integration point:** `ToolRegistry.register()` — the seam was intentionally added in Phase 1 for this. MCP tools register at runtime exactly like built-in tools from the model's perspective.

**Timing:** After Phase 4 (Bash). The registry and adapter abstractions need to be proven stable before adding the biggest protocol surface.

### Open questions

- Configuration UX: how does the user configure MCP server connections? (stdio command, HTTP URL, env vars) — needs brainstorming session.
- Lifecycle: who starts/stops stdio server processes? (app startup vs on-demand)

---

## Phase 6 — WebFetch

**Status:** Not started. No spec or plan yet.

### Settled decisions

**Scope:** HTTP fetch only — strip HTML to markdown, return content. No WebSearch (separate decision, deferred — see below).

**Permission gate:** Same pattern as Bash tool — user approves each fetch request. No auto-approve.

**URL blocklist:** Block localhost, 127.0.0.1, 10.x, 172.16-31.x, 192.168.x (private ranges) to prevent SSRF. This is the "network-policy UX" the original roadmap flagged — it is simpler than it sounded.

**No external API key required.** Pure HTTP — zero dependency on Brave/Bing/Google.

**Primary use case:** "Fetch the docs for this package," "read this GitHub issue," "check this API reference." The AI receives a URL and fetches it.

### Open questions

- Content size cap (probably same 50 KB as tool-output truncation, or a separate web-specific cap)
- Whether to support authenticated requests (e.g., private GitHub repos) — likely YAGNI

---

## Phase 7 — CLI Provider Detection & Delegation

**Status:** Not started. No spec or plan yet.

### What this is

A multi-provider CLI detection and task delegation system. Code Bench learns which AI CLI tools are installed on the host machine (e.g. `claude`, `codex`, custom CLIs), validates their authentication status, and can delegate tasks to them — streaming their responses back to the UI in real time.

Layered provider architecture:

```
UI Layer (provider status, streamed results)
        ↓
Orchestration (Riverpod — task routing, state transitions)
        ↓
Provider Registry / Adapters (ClaudeAdapter, CodexAdapter, …)
        ↓
CLI / Process layer (Process.start, stdout streaming)
```

### Core capabilities

1. **CLI Detection Service** — runs `<cli> --version` to detect installation; parses version; checks auth status via `<cli> auth status` (or equivalent). Results are cached with a TTL to avoid re-running on every build.
2. **Provider Registry** — aggregates status from all adapters; exposes `AsyncValue<List<CliProvider>>` via Riverpod; supports force-refresh per provider.
3. **Adapter pattern** — each CLI implements a common `CliAdapter` interface (`startSession`, `streamTaskResponse`, `sendInput`, `stopSession`, `supports`). New CLIs can be added without touching existing adapters.
4. **Task Delegation Repository** — routes a `TaskRequest` to the correct adapter by provider name; manages session lifecycle; exposes response `Stream<TaskResponse>` to the Riverpod layer.
5. **Streaming UI** — `StreamProvider` accumulates `TaskResponse` chunks line-by-line; `ProviderSelectorWidget` shows detection status; `TaskResponseDisplayWidget` updates in real time without UI freezes.

### Key data models

```dart
class CliProvider { name, binaryPath, isInstalled, version, authStatus, checkedAt, message }
enum CliAuthStatus { authenticated, unauthenticated, unknown }
class TaskRequest { taskDescription, workspaceContext, metadata }
class TaskResponse { content, status, createdAt }
enum TaskStatus { running, completed, failed, interrupted }
```

### Architecture constraints (from CLAUDE.md)

- `Process.start` / `dart:io` is only allowed inside `lib/data/**/datasource/` and `lib/services/`. Detection and CLI-spawning code lives in `*_process.dart` datasource files.
- Adapter classes are services (suffix `Service` or named `*Adapter` — document the deviation if `Adapter` suffix is used).
- Riverpod providers for detection results follow the `FutureProvider` / `AsyncValue` exhaustive-switch pattern.
- No `try/catch` in widgets — errors surface via typed `*Failure` freezed unions and `ref.listen`.

### Settled decisions

**Distinct from "Anthropic provider adapter" (Deferred):** That deferred item was about exposing the Anthropic HTTP API as a selectable provider. This phase is about CLI-level providers — processes on the user's machine. No API key routing, no HTTP client changes.

**Distinct from "Subagent delegation" (Deferred):** Subagent delegation meant spawning parallel Code Bench agent sessions. This phase is sequential task routing to a single external CLI per request — far simpler.

**Session tracking:** Each delegated task gets a UUID session ID. Active sessions are tracked in a `StateProvider<TaskSession?>`. The UI drives loading/error state from `ref.watch(fooActionsProvider).isLoading` per CLAUDE.md Rule 2.

**Auth check strategy:** Run `<cli> auth status` (Claude) or `<cli> login status` (Codex) after installation is confirmed. Parse stdout for known unauthenticated strings. Auth status is `unknown` on any error — not a hard failure.

**Process exit code handling:** A non-zero exit emits `TaskStatus.failed`; the UI shows a typed failure, not a raw exception.

### Open questions

- **Which CLIs to ship in v1?** Likely `claude` and `codex` as the two highest-value targets — confirm with user before speccing.
- **Provider selector UX:** Does this live in the Settings screen (provider configuration), in the session start flow (per-task selection), or both?
- **Default provider fallback:** If the preferred provider is unavailable, does the app auto-fall-back to another installed CLI or block with an error?
- **Working directory propagation:** Each delegated task should receive the active project path as context — confirm the exact flags each CLI accepts.
- **Streaming parse format:** Claude CLI and Codex CLI may emit JSON events rather than plain text. Parser strategy needs to be per-adapter.

### Timing

After Phase 6 (WebFetch). MCP (Phase 5) and WebFetch (Phase 6) prove the tool registry and permission-gate patterns at scale. CLI adapters can reuse those patterns cleanly once they are stable in production.

---

### Anthropic provider adapter

No concrete use case identified. The user does not see a need for Anthropic as a custom-endpoint provider option. Revisit if a specific workflow demands native Anthropic API features (extended thinking, prompt caching).

### Subagent delegation

YAGNI. Code Bench is interactive and session-based. The parallel read-only dispatch (Phase 2) covers the practical performance win. Subagent delegation adds significant complexity (multiple concurrent agent sessions, result aggregation, cancellation propagation, UI representation) with no identified workflow that demands it. Revisit when a concrete use case appears.

### WebSearch

Requires an external search API key (Brave/Bing/Google), adds per-query cost, and the AI can usually construct a docs URL directly. Add when users explicitly need "search the web for this error" without providing a URL.
