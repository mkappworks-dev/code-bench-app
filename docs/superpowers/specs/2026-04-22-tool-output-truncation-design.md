# Tool-Output Truncation — Design Spec

**Date:** 2026-04-22
**Phase:** 3 (Agentic Executor Roadmap)
**Status:** Approved — ready for implementation planning

---

## Goal

Prevent any single tool result from consuming an unbounded slice of the context window. A 50 KB per-result cap is applied centrally at wire-message assembly time, covering all current and future tools.

---

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Enforcement point | Wire time (`_buildWireMessages`) | Full output stays in DB and UI; only the API payload is capped |
| Cap size | 50 KB (`50 * 1024` code units) | Claude Code uses 200 KB; Code Bench hits the API directly — context bloat affects cost and quality. 50 KB ≈ 12 K tokens, substantial but not window-dominating |
| Length measurement | `String.length` (UTF-16 code units) | Slightly overestimates byte count for ASCII; acceptable for a safety-net cap, avoids `utf8.encode` allocation on every result |
| Scope | Both `te.output` and `te.error` | Both fields go into the same `content` wire field. Phase 4 (Bash) will route large stderr through `te.error` — capping only `te.output` would leave that path open |
| Per-tool caps | Unchanged | `grep` (100 matches), `glob` (500 paths), `read_file` (2 MB) serve different concerns (memory/IO). The agent-level cap is a safety net on top, not a replacement |
| `read_file` max | Unchanged at 2 MB | Model gets a 50 KB slice with a truncation notice; can recover by requesting a specific line range or using grep |
| Storage | Full output stored in Drift | `ToolEvent.output` / `ToolEvent.error` are never touched — lossy writes to the DB are avoided |
| UI display | Full output shown | Tool-output cards read from `ToolEvent.output` directly, not from the wire payload |

---

## Architecture

One file changes: `lib/services/agent/agent_service.dart`.

### New constant

```dart
static const int _kToolOutputCap = 50 * 1024; // 50 KB
```

### New private method

```dart
String _capContent(String s) {
  if (s.length <= _kToolOutputCap) return s;
  return '${s.substring(0, _kToolOutputCap)}'
      '\n[Output truncated at 50 KB. '
      'Use grep to search for specific content or read a narrower file range.]';
}
```

### Call site — `_buildWireMessages`

Both loops (history-replay and in-flight) replace:

```dart
content: te.output ?? te.error ?? ''
```

with:

```dart
content: _capContent(te.output ?? te.error ?? '')
```

No other files change. No schema migrations. No generated code.

---

## Truncation Notice

```
[Output truncated at 50 KB. Use grep to search for specific content or read a narrower file range.]
```

Appended on a new line so it is visually distinct from a mid-line cut. Wording updated from the original roadmap draft to reference grep and line-range reads — both are now available tools the model can act on.

---

## Testing

One new test file: `test/services/agent/agent_service_cap_test.dart` (or added to an existing `agent_service_test.dart` if one exists).

Four test cases — all pure, no mocking required:

| Case | Input | Expected |
|---|---|---|
| Under cap | String of length < 50 KB | Returned unchanged |
| Exactly at cap | String of length == 50 KB | Returned unchanged |
| Over cap (output) | String of length > 50 KB | Truncated to 50 KB + notice appended |
| Over cap (error) | Error string of length > 50 KB | Same truncation — covers `te.error` path |

---

## What This Does NOT Change

- `ToolEvent` model and Drift schema
- `CodingToolResult` model
- Per-tool semantic caps (grep, glob, read_file)
- Wire message format / role structure
- UI tool-output card rendering
- Any other service or datasource
