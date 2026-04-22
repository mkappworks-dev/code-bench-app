# Phase 2 — Grep + Glob + Parallel Execution: Design Spec

**Date:** 2026-04-22
**Status:** Approved
**Predecessor:** Phase 1 — Tool Registry Refactor (merged PR #27, `1188b55`)

---

## 1. Scope

This phase adds three capabilities to the agentic executor:

1. **`grep` tool** — search file contents by regex pattern, backed by ripgrep when available and pure-Dart otherwise.
2. **`glob` tool** — expand a glob pattern to matching file paths, pure-Dart always.
3. **Parallel read-only tool dispatch** — read-only tool calls in a single agent round run concurrently (max 4), matching Claude Code's behaviour.

These are the highest capability-per-LOC additions after the Tool Registry refactor. Together they unlock **find-then-edit** workflows: the model can locate symbols, usages, or files before opening or editing them — a capability that `read_file` + `list_dir` alone cannot provide.

**Out of scope for this phase:** Bash tool, WebFetch/WebSearch, MCP integration, subagent delegation, Anthropic provider adapter.

---

## 2. Grep tool design

### 2.1 Backend strategy

`grep` uses **ripgrep (`rg`) when available, pure-Dart otherwise** — the same progressive-enhancement pattern used by many developer tools. This matches Claude Code's approach (which bundles ripgrep internally) while avoiding the complexity of binary bundling in a Flutter desktop app.

| Backend | File | When active |
|---|---|---|
| `GrepDatasourceProcess` | `grep_datasource_process.dart` | `rg` found at startup |
| `GrepDatasourceIo` | `grep_datasource_io.dart` | `rg` not installed |

**Detection:** `RipgrepAvailabilityDatasource` runs `Process.run('rg', ['--version'])` once at app startup via a `@Riverpod(keepAlive: true)` provider. Result is cached for the session; the user can re-trigger detection from Settings.

**Backend selection:** `grepDatasourceProvider` reads `ripgrepAvailabilityProvider` and returns the correct implementation. `GrepTool` is injected with a `GrepDatasource` and is never aware of which backend is active.

### 2.2 Data contracts

```dart
// lib/data/coding_tools/models/grep_match.dart

class GrepMatch {
  final String file;              // project-relative path
  final int lineNumber;
  final String lineContent;
  final List<String> contextBefore;  // up to contextLines lines before match
  final List<String> contextAfter;   // up to contextLines lines after match
}

class GrepResult {
  final List<GrepMatch> matches;
  final int totalFound;    // full count before cap; may exceed matches.length
  final bool wasCapped;    // true when totalFound > maxMatches
}
```

```dart
// lib/data/coding_tools/datasource/grep_datasource.dart

abstract interface class GrepDatasource {
  Future<GrepResult> grep({
    required String pattern,
    required String rootPath,       // absolute, pre-validated by ToolContext
    int contextLines = 2,
    int maxMatches = 100,
    List<String> fileExtensions = const [],    // empty = all files
  });
}
```

### 2.3 GrepDatasourceProcess (ripgrep backend)

Invocation:
```
rg --no-heading --line-number --context <N> --max-count <M+1> <pattern> <rootPath>
```

`M+1` (101 instead of 100) allows truncation detection without a separate count call: if we get 101 results, `wasCapped = true` and we return only the first 100.

`--no-heading` produces the flat `file:line:content` format. Context lines use `file:line-content` (dash instead of colon). Groups are separated by `--`.

File extension filtering uses `--glob '*.dart'` per extension in the list.

Binary files: `rg` skips them automatically.

Error handling:
- Exit code 1 = no matches → return empty `GrepResult`
- Exit code 2 = error → throw `CodingToolsDiskException`
- `rg` not found at grep-call time (ProcessException) → throw `CodingToolsDiskException('ripgrep not available')`; caught by `ToolRegistry` crash-catch (Phase 1) and returned as `CodingToolResult.error`. This is a runtime safety net for the case where `rg` is uninstalled mid-session after startup detection said it was available.

### 2.4 GrepDatasourceIo (pure-Dart fallback)

Algorithm:
1. Walk the project tree via `CodingToolsRepository.listDirectory(rootPath, recursive: true)`
2. Filter by `fileExtensions` if provided
3. For each file: read bytes, skip if null-byte detected (binary), decode as UTF-8
4. Scan lines with `RegExp(pattern)`, collecting `GrepMatch` with surrounding context window
5. Stop collecting after 101 matches (same cap logic as process backend)
6. Return `GrepResult`

Both backends produce structurally identical `GrepResult` output.

### 2.5 GrepTool

```dart
// lib/services/coding_tools/tools/grep_tool.dart

class GrepTool extends Tool {
  GrepTool({required this.datasource});
  final GrepDatasource datasource;

  @override String get name => 'grep';
  @override ToolCapability get capability => ToolCapability.readOnly;

  @override
  String get description =>
      'Search file contents by regex pattern inside the active project. '
      'Returns matching lines with 2 lines of context. Caps at 100 matches.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Regex pattern to search for.',
      },
      'path': {
        'type': 'string',
        'description': 'Project-relative or absolute path to search within.',
      },
      'extensions': {
        'type': 'array',
        'items': {'type': 'string'},
        'description':
            'File extensions to include, e.g. ["dart", "yaml"]. '
            'Omit to search all files.',
      },
    },
    'required': ['pattern', 'path'],
  };
}
```

**`execute` flow:**
1. `ctx.safePath('path', verb: 'Search', noun: 'directory')` — validates and resolves root path
2. Extract `pattern` and optional `extensions` from `ctx.args`
3. Call `datasource.grep(pattern: ..., rootPath: abs, ...)`
4. Format output (see §2.6)
5. Return `CodingToolResult.success(formatted)` or `.error(...)` on exception

**Exception handling:**
- `CodingToolsNotFoundException` → `CodingToolResult.error('Path "..." does not exist.')`
- `CodingToolsDiskException` → `CodingToolResult.error('Cannot search "...": <message>.')`
- `FormatException` (bad regex) → `CodingToolResult.error('Invalid regex pattern: <message>.')`
- `PathErr` from `safePath` → return `p.result` immediately

### 2.6 Output format

Matches Claude Code's flat `file:line: content` shape exactly:

```
lib/services/coding_tools/tool_registry.dart:44:    final denylist = await _loadEffectiveDenylist();
lib/services/coding_tools/tool_registry.dart:45:    final tool = byName[name];
lib/services/coding_tools/tool_registry.dart:46:    if (tool == null) return CodingToolResult.error(...);
--
lib/services/agent/agent_service.dart:111:  final registry = ref.watch(toolRegistryProvider);
lib/services/agent/agent_service.dart:112:  final tools = registry.visibleTools(permission);
lib/services/agent/agent_service.dart:113:  final wire = tools.map((t) => t.toOpenAiToolJson()).toList();

Found 2 matches.
```

When capped:
```
Found 847 matches (showing first 100). Narrow your search with a more specific pattern or path.
```

Context lines use the same `file:line: content` format. Match groups are separated by `--` (matching rg's default separator, which models are trained on).

---

## 3. Glob tool design

`GlobTool` is pure-Dart with no external dependency. It uses `package:glob` (pub.dev) added to `pubspec.yaml`.

```dart
// lib/services/coding_tools/tools/glob_tool.dart

class GlobTool extends Tool {
  GlobTool({required this.repo});
  final CodingToolsRepository repo;

  @override String get name => 'glob';
  @override ToolCapability get capability => ToolCapability.readOnly;

  @override
  String get description =>
      'Expand a glob pattern to matching file paths inside the active project. '
      'Returns one project-relative path per line. Caps at 500 paths.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Glob pattern, e.g. lib/**/*.dart or test/**/\*_test.dart',
      },
    },
    'required': ['pattern'],
  };
}
```

**`execute` flow:**
1. Resolve project root from `ctx.projectPath`
2. Reject the pattern immediately if it contains `..` — `package:glob` resolves relative to the root so `../` would escape the project. Return `CodingToolResult.error('Pattern must not contain "..".')`.
3. Apply `package:glob` `Glob(pattern)` against the project root
4. Cap at 500 paths; append truncation notice if exceeded
5. Return one project-relative path per line

**Output format:**
```
lib/data/coding_tools/datasource/grep_datasource.dart
lib/data/coding_tools/datasource/grep_datasource_io.dart
lib/data/coding_tools/datasource/grep_datasource_process.dart
lib/data/coding_tools/models/grep_match.dart

4 paths matched.
```

When capped: `500 paths shown (pattern matched more). Refine the pattern to narrow results.`

---

## 4. Ripgrep availability — detection and settings UI

### 4.1 Detection

```dart
// lib/data/coding_tools/datasource/ripgrep_availability_datasource.dart
class RipgrepAvailabilityDatasource {
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run('rg', ['--version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}

// lib/services/coding_tools/ripgrep_availability_service.dart
@Riverpod(keepAlive: true)
Future<bool> ripgrepAvailability(Ref ref) =>
    RipgrepAvailabilityDatasource().isAvailable();

// lib/data/coding_tools/datasource/grep_datasource_provider.dart
@riverpod
GrepDatasource grepDatasource(Ref ref) {
  final available = ref.watch(ripgrepAvailabilityProvider).valueOrNull ?? false;
  return available ? GrepDatasourceProcess() : GrepDatasourceIo();
}
```

Detection runs once at startup. `grepDatasourceProvider` is non-keepAlive (rebuilds when `ripgrepAvailabilityProvider` changes).

### 4.2 Settings UI

A `RipgrepAvailabilityBanner` widget is added at the top of `CodingToolsScreen`, above the denylist categories.

**When rg is available:** widget renders nothing (`SizedBox.shrink()`).

**When rg is not available:**

```
┌─────────────────────────────────────────────────────┐
│ ⚡ Grep backend: Pure Dart (fallback)                │
│ Install ripgrep for faster searches.                 │
│ macOS:  brew install ripgrep                         │
│ Linux:  sudo apt install ripgrep                     │
│ Windows: winget install ripgrep                      │
│                              [Check again]           │
└─────────────────────────────────────────────────────┘
```

Only the platform-appropriate install command is shown (detected via `Platform.isMacOS` / `Platform.isLinux` / `Platform.isWindows`).

**"Check again" button:** calls `ref.invalidate(ripgrepAvailabilityProvider)`. The provider re-runs `rg --version`; if it now succeeds, the banner disappears and `grepDatasourceProvider` automatically switches to `GrepDatasourceProcess`.

**AsyncLoading state:** show a `CircularProgressIndicator` in place of the banner content while the check runs.

---

## 5. Parallel read-only dispatch in AgentService

### 5.1 Partition logic

The existing `for (final call in roundCalls)` loop at `agent_service.dart:201` is replaced with a two-phase dispatch.

**Parallelizable** = readOnly capability AND no permission prompt required AND decode did not fail:
```dart
final parallelizable = roundCalls.where((c) {
  final tool = _registry.byName(c.name);
  return tool != null &&
      tool.capability == ToolCapability.readOnly &&
      !_registry.requiresPrompt(tool, permission) &&
      !c.decodeFailed;
}).toList();

final serial = roundCalls
    .where((c) => !parallelizable.contains(c))
    .toList();
```

**Phase 1 — parallel reads (chunks of 4):**
```dart
for (var i = 0; i < parallelizable.length; i += 4) {
  if (_cancelFlag()) break;
  final chunk = parallelizable.skip(i).take(4).toList();
  await Future.wait(chunk.map(_executeCall));
  yield snapshot(streaming: true);
}
```

**Phase 2 — serial (existing logic, unchanged):**
```dart
for (final call in serial) {
  if (_cancelFlag()) break;
  if (call.decodeFailed) continue;
  // ... existing permission prompt + execute logic
}
```

**`_executeCall`** is a new private method extracting `_registry.execute(...)` + `_recordResult(...)` from the existing loop body.

### 5.2 Invariants

| Invariant | How preserved |
|---|---|
| Permission prompts always serial | Prompted tools go into `serial` list |
| Writes always serial | `mutatingFiles` / `shell` capability → `serial` list |
| Cancel between chunks, not mid-flight | `_cancelFlag()` checked before each chunk; Dart cannot interrupt in-flight futures |
| Results recorded by event ID | `_recordResult` uses `events.indexWhere((e) => e.id == call.id)` — safe for concurrent writes to different indices |

---

## 6. Testing strategy

### 6.1 `grep_datasource_io_test.dart`
- Match found with context lines
- No match → empty result
- Result cap (inject 101-match fixture, assert `wasCapped = true`, 100 returned)
- Binary file skipped
- Invalid regex → `FormatException`
- Extension filter

### 6.2 `grep_tool_test.dart`
- Output format — match line + context + separator + summary line
- Capped output message
- `safePath` rejection → `CodingToolResult.error`
- Empty result → `"No matches found."`
- Bad regex → error result

### 6.3 `glob_tool_test.dart`
- Pattern matches files → correct project-relative paths
- No matches → empty result with message
- Cap at 500 paths
- Path traversal pattern (`../`) → rejected by `safePath`

### 6.4 `agent_service_parallel_test.dart`
- Two readOnly + one write in same round → reads run first (parallel), write runs after
- Cancel flag mid-parallel-chunk → remaining chunks skipped
- All writes → no parallel, serial as before
- Mixed read/write → correct partition

---

## 7. File layout

### New files (16)

```
lib/data/coding_tools/
  datasource/
    grep_datasource.dart                   ← GrepDatasource interface
    grep_datasource_process.dart           ← rg backend
    grep_datasource_io.dart                ← pure Dart fallback
    grep_datasource_provider.dart          ← @riverpod GrepDatasource selector
    ripgrep_availability_datasource.dart   ← Process.run('rg', ['--version'])
  models/
    grep_match.dart                        ← GrepMatch + GrepResult

lib/services/coding_tools/
  ripgrep_availability_service.dart        ← @Riverpod(keepAlive:true) Future<bool>
  tools/
    grep_tool.dart
    grep_tool.g.dart                       ← generated
    glob_tool.dart
    glob_tool.g.dart                       ← generated

lib/features/coding_tools/
  widgets/
    ripgrep_availability_banner.dart

test/data/coding_tools/
  grep_datasource_io_test.dart
test/services/coding_tools/tools/
  grep_tool_test.dart
  glob_tool_test.dart
test/services/agent/
  agent_service_parallel_test.dart
```

### Modified files (4)

```
lib/services/coding_tools/tool_registry.dart          ← register GrepTool + GlobTool
lib/services/agent/agent_service.dart                 ← parallel dispatch
lib/features/coding_tools/coding_tools_screen.dart    ← add RipgrepAvailabilityBanner
pubspec.yaml                                          ← add package:glob
```

---

## 8. Migration / commit strategy

Two commits (additive then cutover — same pattern as Phase 1):

| Commit | Contents |
|---|---|
| 1 | Data contracts + datasource impls + ripgrep availability + GrepTool + GlobTool + all tests |
| 2 | Register tools in ToolRegistry + parallel dispatch in AgentService + Settings banner |

Commit 1 is entirely additive (no existing code touched). Commit 2 wires everything together and can be reviewed in isolation.
