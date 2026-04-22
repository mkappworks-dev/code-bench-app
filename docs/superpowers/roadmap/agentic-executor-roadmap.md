# Agentic Executor Roadmap

**Last updated:** 2026-04-22
**Owner:** Code Bench — agentic coding assistant

This document is the source of truth for the agentic executor build-out. Read this before brainstorming or planning any new phase. It captures the sequencing rationale, key decisions, and Q&A from design sessions so future sessions do not re-litigate settled questions.

---

## Status Overview

| Phase | Description | Status |
|---|---|---|
| 1 | Tool Registry Refactor | ✅ Done — PR #27, commit `1188b55` |
| 2 | Grep + Glob + Parallel execution | 🗂 Planned — `docs/superpowers/plans/2026-04-22-grep-glob-parallel.md` |
| 3 | Tool-output truncation | ⬜ Not started |
| 4 | Bash tool (permission-gated) | ⬜ Not started |
| 5 | MCP client (stdio + HTTP/SSE) | ⬜ Not started |
| 6 | WebFetch | ⬜ Not started |
| — | Anthropic provider adapter | 🚫 Deferred / YAGNI |
| — | Subagent delegation | 🚫 Deferred / YAGNI |
| — | WebSearch | 🚫 Deferred |

---

## Original Sequencing Rationale

From the initial 6-gap roadmap session:

| # | Phase | Gap | Why here |
|---|---|---|---|
| 1 | Tool registry refactor | 1A | Prerequisite for 2, 5, and MCP. Pure win, contained blast radius. |
| 2 | Grep + Glob tools | 2 (partial) | Highest capability gain per LOC. Registry from Phase 1 makes this a one-file add. |
| 3 | Parallel read-only tools | 3B | Dramatic perceived speedup. Isolated to the loop; no wire/schema changes. |
| 4 | Tool-output truncation | 4B | Needed as soon as tool breadth grows — more tools = more bloat per round. |
| 5 | Bash tool (permission-gated) | 2 (partial) | Highest capability, highest risk. Defer so Phases 1–4 give usage telemetry to inform the denylist. |
| 6 | Anthropic provider via adapter | 5B | Pure new-market work. Deferred — no concrete use case identified. |
| 7 | MCP client | 1B | Biggest protocol surface. Only worth it once registry/adapter abstractions are stable. |
| 8 | Subagent delegation | 6 | YAGNI until a concrete workflow demands it. |
| 9 | WebFetch / WebSearch | 2 (partial) | Needs network-policy UX which is its own design problem. |

> **Note:** Original Phases 2 and 3 (Grep+Glob and Parallel) were combined into a single implementation plan because they share the same AgentService change surface and are low risk together.

---

## Phase 1 — Tool Registry Refactor ✅

**Done.** See PR #27 (`1188b55`). No further decisions needed.

The `ToolRegistry.register()` seam is the hook for future MCP tool injection.

---

## Phase 2 — Grep + Glob + Parallel Execution 🗂

**Spec:** `docs/superpowers/specs/2026-04-22-grep-glob-parallel-design.md`
**Plan:** `docs/superpowers/plans/2026-04-22-grep-glob-parallel.md`

Key decisions already locked in the spec — do not re-litigate:
- ripgrep when available, pure-Dart fallback (progressive enhancement)
- Missing rg → persistent UI warning in Settings, not an error; fall back silently
- 2 context lines, 100-match cap, flat `file:line:content` format (matches Claude Code)
- Max 4 parallel read-only calls per round (matches Claude Code)
- Backend selection lives in `grepToolProvider` (services layer), not in data layer — arch constraint

---

## Phase 3 — Tool-output Truncation

**Status:** Not started. No spec or plan yet.

### Settled decisions

**Where the cap lives:** Central enforcement in `AgentService`, not per-tool. Applied to every tool result before it is added to the wire message. Tools still do their own semantic caps (grep's 100-match limit, list_dir's entry cap) — the agent-level cap is a safety net that covers all current and future tools including Bash, MCP, and WebFetch.

**Cap size:** 50 KB per tool result. Rationale: Claude Code uses 200 KB but Code Bench hits the Anthropic API directly — context window bloat affects cost and quality. `read_file` allows 2 MB files; without this cap one large read could consume ~500 K tokens. 50 KB ≈ ~12 K tokens, substantial but not window-dominating.

**Truncation notice:** Append `\n[Output truncated at 50 KB. Use a more specific path or pattern.]` when cut.

### Open questions
None — ready to spec and plan when Phase 2 is merged.

---

## Phase 4 — Bash Tool (permission-gated)

**Status:** Not started. No spec or plan yet.

### Settled decisions

**Shell mode:** `runInShell: true`. A no-shell Bash tool (no pipes, no redirects) is too crippled to be useful — `grep foo | wc -l` would not work. Claude Code runs a real shell. The CLAUDE.md restriction on `runInShell: true` was written for services that construct commands programmatically from user data (branch names, commit messages) where shell injection is the risk. The Bash tool is different: the AI generates the command and the user explicitly approves it before execution.

**CLAUDE.md update required:** Narrow the `runInShell: true` restriction. The existing ban applies to services constructing commands from external/user data. `bash_datasource_process.dart` is a documented exception — it executes an AI-generated, user-approved shell command. Document this the same way `ApplyRepository.assertWithinProject` is documented as a `dart:io` exception.

**Permission gate:** Every Bash call requires explicit user approval. No auto-approve path, ever.

**Working directory:** Locked to project root — same pattern as all other tools.

**Denylist:** Existing coding tools denylist applies to the command string.

**Timing:** Implement after Phase 3. The original rationale (telemetry to inform the denylist) still applies — having grep/glob/truncation in production first gives real usage data before the highest-risk tool ships.

### Open questions
None — ready to spec and plan when Phase 3 is merged.

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

## Deferred / YAGNI

### Anthropic provider adapter

No concrete use case identified. The user does not see a need for Anthropic as a custom-endpoint provider option. Revisit if a specific workflow demands native Anthropic API features (extended thinking, prompt caching).

### Subagent delegation

YAGNI. Code Bench is interactive and session-based. The parallel read-only dispatch (Phase 2) covers the practical performance win. Subagent delegation adds significant complexity (multiple concurrent agent sessions, result aggregation, cancellation propagation, UI representation) with no identified workflow that demands it. Revisit when a concrete use case appears.

### WebSearch

Requires an external search API key (Brave/Bing/Google), adds per-query cost, and the AI can usually construct a docs URL directly. Add when users explicitly need "search the web for this error" without providing a URL.
