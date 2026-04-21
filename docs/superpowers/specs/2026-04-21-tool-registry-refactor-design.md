# Tool Registry Refactor — Design Spec

## Goal

Replace the static `CodingTools.all` catalog and the `switch(toolName)` dispatch in `CodingToolsService` with a runtime `ToolRegistry` service backed by polymorphic `Tool` classes. Each tool becomes a self-contained unit that declares its own schema, capability, and dependencies, and runs path-safety checks through a shared `ToolContext` helper. `AgentService` loses its two hardcoded tool-specific strings and asks the registry instead.

This is Phase 1 of a larger roadmap (see [2026-04-21-agentic-executor-roadmap.md](./2026-04-21-agentic-executor-roadmap.md) — not yet written). It exists to make Phases 2–9 cheap: adding a tool (Phase 2: Grep/Glob), adding a provider (Phase 6: Anthropic), and introducing MCP (Phase 7) all become small changes on top of the registry seam established here.

---

## Scope

**In scope:**

- A polymorphic `Tool` interface and four concrete implementations replacing today's private handlers in `CodingToolsService`.
- A `ToolCapability` enum with four values: `readOnly`, `mutatingFiles`, `shell`, `network`. Only the first two are used by built-in tools in this phase; `shell` and `network` exist so Phases 5/9 don't require enum churn.
- A `ToolContext` class carrying request-scoped data (`projectPath`, `sessionId`, `messageId`, `args`, `denylist`) plus a `safePath` helper that centralizes the resolve/assertWithinProject/denylist ritual that every file-touching tool currently repeats.
- A `ToolRegistry` service exposing `byName`, `byCapability`, `visibleTools(permission)`, `requiresPrompt(tool, permission)`, `execute(...)`, `register(Tool)`, `unregister(name)`.
- Retargeting of the `AgentService` call sites at [agent_service.dart:115, :205, :222](../../../lib/services/agent/agent_service.dart) to the registry.
- Updating `AIRepository.streamMessageWithTools` signature from `List<CodingToolDefinition>` to `List<Tool>`; ripple through `AIRepositoryImpl` and `CustomRemoteDatasourceDio`.
- Deletion of `CodingToolsService` and `CodingToolDefinition`.
- Retargeted test suite: per-tool tests, a `ToolContext` test file owning the path-safety invariant, a `ToolRegistry` test file, and updated `AgentService` test fakes.

**Out of scope (tracked as follow-up work):**

- **Adding new tools.** No Grep, Glob, Bash, WebFetch, WebSearch, or any other tool in this phase. The four built-in tools and their behaviors are preserved byte-for-byte.
- **MCP client integration.** `register/unregister` exists as a seam but no MCP protocol code lands here.
- **Reactive registry mutation.** `register/unregister` mutate a plain list; watchers of `toolRegistryProvider` do not rebuild on registration change. This is deliberate — AgentService reads the registry at the start of each turn; no widget watches it currently. Phase 7 may upgrade this to a Notifier shape if MCP requires reactive propagation.
- **Permission-tier changes.** The three-tier `ChatPermission` model (`readOnly`, `askBefore`, `fullAccess`) is unchanged. The mapping from permission to capability lives in `ToolRegistry.visibleTools` and `ToolRegistry.requiresPrompt`, where future policy changes would land.
- **Behavior changes.** No observable behavior difference for the end user. Same tool outputs, same error messages, same permission prompts, same security guards. This is a structural refactor.

---

## Architecture

### Before

```
Widgets / Notifiers
      ↓
AgentService
 • hardcoded CodingTools.readOnly vs .all (:115)
 • hardcoded 'write_file' | 'str_replace' destructive check (:205)
 • calls CodingToolsService.execute(toolName, args, ...)
      ↓
CodingToolsService
 • switch (toolName) { 'read_file': _readFile, 'list_dir': _listDir, ... }
 • 4 private handlers, each repeating: resolve + assertWithinProject + assertNotDenied
 • owns crash-catch + timing log
      ↓
CodingToolsRepository, ApplyService, CodingToolsDenylistRepository
```

### After

```
Widgets / Notifiers
      ↓
AgentService
 • registry.visibleTools(permission)      (replaces :115)
 • registry.requiresPrompt(tool, perm)    (replaces :205)
 • registry.execute(name, ...)            (replaces :222)
      ↓
ToolRegistry                              NEW
 • List<Tool> (built-ins + future MCP)
 • byName / byCapability / visibleTools / requiresPrompt
 • execute: loads EffectiveDenylist, builds ToolContext, dispatches, wraps crash-catch
 • register / unregister (non-reactive Phase-1 seam)
      ↓
ReadFileTool, ListDirTool, WriteFileTool, StrReplaceTool   NEW (4 classes)
 • each implements Tool, holds its own deps (repo, apply)
 • execute(ctx) uses ctx.safePath for path validation
      ↓
CodingToolsRepository, ApplyService, CodingToolsDenylistRepository   (unchanged)
```

The `ToolRegistry` sits in the same position and has the same provider lifetime (`keepAlive: true`) as the old `CodingToolsService`. `AgentService`'s dependency graph keeps the same fan-out; only what that service *does* changes.

---

## Design

### 4a — Public interfaces (`lib/data/coding_tools/models/`)

**`tool.dart`** — the interface every tool implements:

```dart
abstract class Tool {
  String get name;
  String get description;
  Map<String, dynamic> get inputSchema;
  ToolCapability get capability;

  Future<CodingToolResult> execute(ToolContext ctx);

  /// Serializes to the OpenAI chat-completions `tools[]` shape.
  /// Replaces `CodingToolDefinition.toOpenAiToolJson()`.
  Map<String, dynamic> toOpenAiToolJson() => {
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': inputSchema,
    },
  };
}
```

**`tool_capability.dart`**:

```dart
enum ToolCapability { readOnly, mutatingFiles, shell, network }
```

**`tool_context.dart`**:

```dart
class ToolContext {
  const ToolContext({
    required this.projectPath,
    required this.sessionId,
    required this.messageId,
    required this.args,
    required this.denylist,
  });

  final String projectPath;
  final String sessionId;
  final String messageId;
  final Map<String, dynamic> args;
  final EffectiveDenylist denylist;

  /// Reads a path-shaped arg, enforces project-boundary + denylist.
  /// Returns PathOk with the vetted absolute path, or PathErr carrying
  /// a pre-built error result (with verb-aware phrasing) to return.
  /// Centralizes the resolve + assertWithinProject + assertNotDenied
  /// ritual every file-touching tool used to repeat.
  ///
  /// [verb] — the tool's action phrasing ("Read"/"Write"/"List"/"Edit").
  /// [noun] — what the tool operates on; "file" for read/write/edit,
  /// "directory" for list. Affects the `(sensitive {noun})` suffix
  /// in denylist-block errors. Defaults to "file".
  PathResult safePath(String argName, {required String verb, String noun = 'file'});

  /// Strips control chars and truncates to [max]. Used when embedding a
  /// raw arg into an error message sent back to the model.
  String sanitizeForError(String raw, {int max = 120});
}
```

**`path_result.dart`**:

```dart
sealed class PathResult {
  const PathResult();
}
final class PathOk extends PathResult {
  const PathOk(this.abs, this.displayRaw);
  final String abs;         // vetted absolute path
  final String displayRaw;  // sanitized raw, for success messages
}
final class PathErr extends PathResult {
  const PathErr(this.result);
  final CodingToolResult result;
}
```

**`effective_denylist.dart`** — lifted from private in `CodingToolsService`:

```dart
typedef EffectiveDenylist = ({
  Set<String> segments,
  Set<String> filenames,
  Set<String> extensions,
  Set<String> prefixes,
});
```

#### Path-safety policy

`ToolContext.safePath` is the single enforcement point for:

- Missing or non-string arg → `PathErr` with `"{toolName} requires a non-empty \"{argName}\""`.
- Path resolution: absolute paths are normalized; relative paths are joined to `projectPath` then normalized.
- `PathEscapeException` (outside project root) → `PathErr` with `"Path \"{displayRaw}\" is outside the project root."`.
- `BlockedPathException` (denylist match) → `PathErr` with `"{Verb}ing \"{displayRaw}\" is blocked for safety (sensitive {noun})."` — `{noun}` comes from the `safePath` call (`"file"` for `read_file`/`write_file`/`str_replace`; `"directory"` for `list_dir`). This matches today's phrasing exactly: see [coding_tools_service.dart:166, :229, :265, :316](../../../lib/services/coding_tools/coding_tools_service.dart). The `sLog` security event is emitted (preserving current behavior at [coding_tools_service.dart:96-109](../../../lib/services/coding_tools/coding_tools_service.dart)).
- `ProjectMissingException` → `PathErr` with `"Project folder is missing."`.

The `verb` parameter lets each tool produce its own phrasing (`"Read"`, `"Write"`, `"List"`, `"Edit"`) without branching logic inside `ToolContext`.

### 4b — `ToolRegistry` service (`lib/services/coding_tools/tool_registry.dart`)

```dart
@Riverpod(keepAlive: true)
ToolRegistry toolRegistry(Ref ref) => ToolRegistry(
  builtIns: [
    ref.watch(readFileToolProvider),
    ref.watch(listDirToolProvider),
    ref.watch(writeFileToolProvider),
    ref.watch(strReplaceToolProvider),
  ],
  denylistRepo: ref.watch(codingToolsDenylistRepositoryProvider),
);

class ToolRegistry {
  ToolRegistry({
    required List<Tool> builtIns,
    required CodingToolsDenylistRepository denylistRepo,
  }) : _tools = [...builtIns], _denylistRepo = denylistRepo;

  final List<Tool> _tools;
  final CodingToolsDenylistRepository _denylistRepo;

  List<Tool> get tools => List.unmodifiable(_tools);

  Tool? byName(String name) => _tools.firstWhereOrNull((t) => t.name == name);

  List<Tool> byCapability(ToolCapability c) =>
      _tools.where((t) => t.capability == c).toList();

  /// Tools the agent is allowed to see under a permission tier. Replaces
  /// the hardcoded CodingTools.readOnly/.all split at agent_service.dart:115.
  List<Tool> visibleTools(ChatPermission p) => p == ChatPermission.readOnly
      ? _tools.where((t) => t.capability == ToolCapability.readOnly).toList()
      : List.unmodifiable(_tools);

  /// Whether a call should raise a PermissionRequest in askBefore mode.
  /// Replaces the 'write_file' | 'str_replace' hardcode at agent_service.dart:205.
  bool requiresPrompt(Tool t, ChatPermission p) =>
      p == ChatPermission.askBefore && t.capability != ToolCapability.readOnly;

  /// Dispatcher. Loads EffectiveDenylist once, builds ToolContext, runs
  /// the tool, wraps crash-catch + timing log (preserves current
  /// CodingToolsService.execute behavior).
  Future<CodingToolResult> execute({
    required String name,
    required String projectPath,
    required String sessionId,
    required String messageId,
    required Map<String, dynamic> args,
  }) async {
    final tool = byName(name);
    if (tool == null) return CodingToolResult.error('Unknown tool "$name"');

    final effective = await _loadEffectiveDenylist();
    final ctx = ToolContext(
      projectPath: projectPath,
      sessionId: sessionId,
      messageId: messageId,
      args: args,
      denylist: effective,
    );

    final started = DateTime.now();
    dLog('[ToolRegistry] $name start');
    try {
      return await tool.execute(ctx);
    } catch (e, st) {
      dLog('[ToolRegistry] $name crashed: ${e.runtimeType} $e\n$st');
      return CodingToolResult.error(
        'Tool "$name" crashed unexpectedly (${e.runtimeType}).',
      );
    } finally {
      final ms = DateTime.now().difference(started).inMilliseconds;
      dLog('[ToolRegistry] $name done in ${ms}ms');
    }
  }

  Future<EffectiveDenylist> _loadEffectiveDenylist() async => (
    segments: await _denylistRepo.effective(DenylistCategory.segment),
    filenames: await _denylistRepo.effective(DenylistCategory.filename),
    extensions: await _denylistRepo.effective(DenylistCategory.extension),
    prefixes: await _denylistRepo.effective(DenylistCategory.prefix),
  );

  /// Adds a tool at runtime. Phase-1 seam for future MCP integration.
  /// Throws StateError if a tool with that name already exists.
  ///
  /// NOTE: mutation is not reactive. Watchers of toolRegistryProvider
  /// do not rebuild on register/unregister. AgentService reads the
  /// registry at the start of each turn so this is safe today. If
  /// Phase 7 needs reactive propagation, convert this class to a
  /// Notifier shape at that time.
  void register(Tool t) {
    if (_tools.any((x) => x.name == t.name)) {
      throw StateError('Tool "${t.name}" already registered');
    }
    _tools.add(t);
  }

  void unregister(String name) {
    _tools.removeWhere((t) => t.name == name);
  }
}
```

### 4c — Tool implementations (`lib/services/coding_tools/tools/`)

Each tool is its own file with its own Riverpod provider. All four preserve their current error messages, size caps, and permission semantics byte-for-byte — only the path-safety ritual collapses onto `ctx.safePath`.

Canonical example — `read_file_tool.dart`:

```dart
@riverpod
ReadFileTool readFileTool(Ref ref) => ReadFileTool(
  repo: ref.watch(codingToolsRepositoryProvider),
);

class ReadFileTool implements Tool {
  ReadFileTool({required this.repo});
  final CodingToolsRepository repo;

  static const int _kMaxReadBytes = 2 * 1024 * 1024;

  @override final name = 'read_file';
  @override final capability = ToolCapability.readOnly;
  @override final description =
      'Read the contents of a text file inside the active project.';
  @override final inputSchema = const {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Project-relative or absolute path to a file inside the project.',
      },
    },
    'required': ['path'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final p = ctx.safePath('path', verb: 'Read'); // noun defaults to "file"
    if (p is PathErr) return p.result;
    final PathOk(:abs, :displayRaw) = p;

    try {
      final size = await repo.fileSizeBytes(abs);
      if (size > _kMaxReadBytes) {
        return CodingToolResult.error(
          'File too large ($size bytes; max $_kMaxReadBytes bytes). '
          'Consider str_replace for targeted edits.',
        );
      }
      return CodingToolResult.success(await repo.readTextFile(abs));
    } on PathNotFoundException {
      return CodingToolResult.error('File "$displayRaw" does not exist.');
    } on FormatException {
      return CodingToolResult.error('File "$displayRaw" is not text-encoded.');
    } on FileSystemException catch (e) {
      dLog('[ReadFileTool] FileSystemException: ${e.osError?.message ?? e.message}');
      return CodingToolResult.error(
        'Cannot read "$displayRaw": ${e.osError?.message ?? 'I/O error'}.',
      );
    }
  }
}
```

The other three follow the same shape:

- `list_dir_tool.dart` — holds `CodingToolsRepository`; calls `ctx.safePath('path', verb: 'List', noun: 'directory')`; iterates entries, filters via `ctx.denylist` using a private helper `_isDeniedRel` (ported from [coding_tools_service.dart:118-129](../../../lib/services/coding_tools/coding_tools_service.dart)); caps at 500 entries and depth 3.
- `write_file_tool.dart` — holds `ApplyService`; calls `ctx.safePath('path', verb: 'Write')`, then `ApplyService.applyChange`.
- `str_replace_tool.dart` — holds `CodingToolsRepository` and `ApplyService`; calls `ctx.safePath('path', verb: 'Edit')`; reads file, counts occurrences, enforces "exactly one match" rule, then `ApplyService.applyChange`.

Size caps, error verbiage, and security guards are preserved exactly.

---

## File layout

### New files (10)

```
lib/data/coding_tools/models/
  tool.dart
  tool_capability.dart
  tool_context.dart
  path_result.dart
  effective_denylist.dart

lib/services/coding_tools/
  tool_registry.dart
  tools/
    read_file_tool.dart
    list_dir_tool.dart
    write_file_tool.dart
    str_replace_tool.dart
```

### Changed files (4)

```
lib/services/agent/agent_service.dart               (3 call-site edits + constructor dep)
lib/data/ai/repository/ai_repository.dart           (tools parameter type)
lib/data/ai/repository/ai_repository_impl.dart      (tools parameter type)
lib/data/ai/datasource/custom_remote_datasource_dio.dart   (tools parameter type)
```

### Deleted files (2)

```
lib/services/coding_tools/coding_tools_service.dart
lib/data/coding_tools/models/coding_tool_definition.dart
```

### Unchanged (all other files under `lib/data/coding_tools/**`, `lib/services/coding_tools/**`, and `test/**` except the retargeted suites listed in §Testing)

---

## Migration path

Single PR, four commits, green build at every commit boundary.

| # | Commit | Scope | Why green |
|---|--------|-------|-----------|
| 1 | `feat(coding-tools): add Tool / ToolContext / ToolCapability contracts` | New data-layer types (`tool.dart`, `tool_capability.dart`, `tool_context.dart`, `path_result.dart`, `effective_denylist.dart`). | Purely additive — no existing code references these yet. |
| 2 | `feat(coding-tools): add ToolRegistry service and four Tool implementations` | `ToolRegistry`, `ReadFileTool`, `ListDirTool`, `WriteFileTool`, `StrReplaceTool` and their Riverpod providers. | Purely additive — registry exists in parallel with `CodingToolsService`; nothing calls it yet. |
| 3 | `refactor(agent): route AgentService through ToolRegistry` | Swap `AIRepository.streamMessageWithTools` signature to `List<Tool>`; update `AgentService` constructor to take `ToolRegistry`; replace the three call sites at `:115`, `:205`, `:222`; update `AgentService` test fakes. | AIRepository signature change is a pure type substitution (same method surface). The only AgentService consumer of `CodingToolsService` swaps atomically; no interim dual-wiring. |
| 4 | `refactor(coding-tools): remove CodingToolsService and CodingToolDefinition` | Delete `lib/services/coding_tools/coding_tools_service.dart`, `lib/data/coding_tools/models/coding_tool_definition.dart`, and their tests. Migrate old test assertions into their new homes (see §Testing). | Commit 3 removed all references; deletion is mechanical. |

### Exact AgentService edits

1. Constructor dep: `CodingToolsService codingTools` → `ToolRegistry registry`. Provider line at [agent_service.dart:45](../../../lib/services/agent/agent_service.dart): `ref.read(codingToolsServiceProvider)` → `ref.read(toolRegistryProvider)`.
2. Line 115: `final tools = permission == ChatPermission.readOnly ? CodingTools.readOnly : CodingTools.all;` → `final tools = _registry.visibleTools(permission);`.
3. Line 205: `final isDestructive = call.name == 'write_file' || call.name == 'str_replace';` → `final tool = _registry.byName(call.name);` followed by `if (tool != null && _registry.requiresPrompt(tool, permission)) { ... }`.
4. Line 222-228: `_tools.execute(toolName: call.name, ...)` → `_registry.execute(name: call.name, ...)` — same trailing arguments.

### AIRepository signature change

`streamMessageWithTools({required List<CodingToolDefinition> tools, ...})` → `streamMessageWithTools({required List<Tool> tools, ...})`. Ripples through `AIRepositoryImpl` (same line shape) and `CustomRemoteDatasourceDio` (same line shape). The datasource body calls `tools.map((t) => t.toOpenAiToolJson())` — that method moved from `CodingToolDefinition` to `Tool`, so the call is unchanged.

---

## Testing strategy

### New test files

```
test/data/coding_tools/models/
  tool_context_test.dart

test/services/coding_tools/
  tool_registry_test.dart
  tools/
    read_file_tool_test.dart
    list_dir_tool_test.dart
    write_file_tool_test.dart
    str_replace_tool_test.dart

test/services/coding_tools/_helpers/
  tool_test_helpers.dart    (shared fakeCtx + emptyDenylist utilities)
```

### Coverage assignment

**`tool_context_test.dart`** — single source of truth for path-safety invariants:

- `safePath` rejects missing arg, non-string arg, empty string.
- `safePath` rejects path-escape — `PathErr` with "outside project" message.
- `safePath` rejects denylist matches for each category: segment, filename, extension, prefix.
- `safePath` returns `PathOk` with vetted abs + sanitized displayRaw on the happy path.
- `safePath` uses `verb` to shape error text ("Read"/"Write"/"List"/"Edit").
- `sanitizeForError` strips control chars and truncates to `max`.

**`tool_registry_test.dart`**:

- `byName` hit + miss.
- `byCapability` filters correctly for each of the four enum values.
- `visibleTools(readOnly)` returns only `readOnly` tools; `visibleTools(askBefore)` and `visibleTools(fullAccess)` return all.
- `requiresPrompt` truth table: 4 capabilities × 3 permissions = 12 assertions.
- `register` adds at end; `register` throws `StateError` on name collision; `unregister` removes.
- `execute` dispatches to the named tool; `execute` returns `"Unknown tool"` error for unknown name.
- `execute` catches tool crashes and returns error result (with `dLog` emitted).
- `execute` loads effective denylist once per call and threads it into the built ToolContext.
- Migrated from the old `configurable denylist` group: user-added filename refused; suppressed baseline filename allowed.

**Per-tool test files** — each covers only that tool's own logic:

- Happy path.
- Tool-specific edge cases (preserved from the old `coding_tools_service_test.dart`):
  - `read_file`: 2MB size cap, non-text-encoded rejection, non-existent file.
  - `list_dir`: non-recursive listing of children, missing path.
  - `write_file`: creation of new file with byte count, overwrite of existing.
  - `str_replace`: unique-occurrence replacement, `old_str` not found, multiple matches rejected.
- One sanity test per tool: "tool surfaces `ctx.safePath` errors" — calling with an escape path returns an error result. Confirms the tool actually uses `ctx.safePath`.
- Mutating tools: assert `ApplyService.applyChange` called with correct args via a fake.

### Migration of existing assertions

All 14 assertions in `test/services/coding_tools/coding_tools_service_test.dart` survive. No coverage lost.

| Existing test | Moves to |
|---|---|
| `read_file > returns success with content` | `read_file_tool_test.dart` |
| `read_file > rejects path escape` | `tool_context_test.dart` + sanity case in `read_file_tool_test.dart` |
| `read_file > rejects files larger than 2MB` | `read_file_tool_test.dart` |
| `read_file > rejects non-text files` | `read_file_tool_test.dart` |
| `read_file > non-existent file` | `read_file_tool_test.dart` |
| `list_dir > non-recursive lists children` | `list_dir_tool_test.dart` |
| `list_dir > missing path returns error` | `list_dir_tool_test.dart` |
| `write_file > creates new file` | `write_file_tool_test.dart` |
| `write_file > overwrites existing` | `write_file_tool_test.dart` |
| `str_replace > replaces unique occurrence` | `str_replace_tool_test.dart` |
| `str_replace > old_str not found` | `str_replace_tool_test.dart` |
| `str_replace > matches multiple times` | `str_replace_tool_test.dart` |
| `configurable denylist > user-added filename refused` | `tool_registry_test.dart` |
| `configurable denylist > suppressed baseline allowed` | `tool_registry_test.dart` |

### AgentService test updates

- The fake that currently stands in for `CodingToolsService` swaps to one standing in for `ToolRegistry`. Same public surface: accepts a name + args, returns `CodingToolResult`.
- Existing "in readOnly mode, only read/list tools are sent to the model" test now asserts `registry.visibleTools(ChatPermission.readOnly)` returned the right subset.
- Existing "askBefore prompts only for destructive" test now asserts `registry.requiresPrompt(...)` drives the prompt.

### Deletions

- `test/services/coding_tools/coding_tools_service_test.dart` (258 lines) — all assertions migrated.

---

## Design decisions

### Why polymorphic tools instead of a data-driven registry (schema + handler function)?

Considered. A schema-plus-handler model (tool = `(Map schema, Function(ctx) handler)`) is lighter per tool but loses dep-injection cleanness — handlers can't hold their own deps without closures, and adding `BashTool` with a `ProcessRunner` dep becomes awkward. The polymorphic approach matches the rest of the codebase's service style (`GitService`, `ApplyService`, each a class with its own deps).

### Why one `ToolCapability` enum value per tool, instead of a flag set?

Evaluated. Flag sets (`{readsFiles, writesFiles, runsProcesses, accessesNetwork}`) would be more expressive for MCP tools that span multiple risk categories. But for Phase 1's four tools, all fit cleanly into one bucket, and the permission UI doesn't yet use capability info for anything beyond the readOnly/mutating split. The enum can be swapped for flags at Phase 7 if MCP requires it; the cost is a one-line enum swap plus updated `visibleTools`/`requiresPrompt` predicates.

### Why non-reactive `register/unregister`?

No current caller watches the registry reactively. AgentService reads it once per turn. Making `register/unregister` reactive would require converting the class to a `Notifier` and updating every `ref.read(toolRegistryProvider)` to `ref.read(toolRegistryProvider.notifier)`. That's cheap to do later if Phase 7 needs it; doing it now adds complexity for zero current benefit. Flagged explicitly in the class doc comment so it's not mistaken for an oversight.

### Why `PathResult` sealed class instead of throwing?

Throwing would force every tool to wrap `safePath` in try/catch for three exception types (`PathEscapeException`, `BlockedPathException`, `ProjectMissingException`). The sealed return keeps the early-exit to a single `if (p is PathErr) return p.result` line. It also mirrors the existing `CodingToolResult` sealed pattern, so the style stays consistent.

### Why load the denylist in `ToolRegistry.execute` instead of per-tool?

Currently every tool handler calls `_loadEffectiveDenylist()` individually. Pushing the load up to the registry means one load per `execute` call (identical cost to today — no regression), and `safePath` becomes synchronous inside the tool — cleaner to read and test. The `EffectiveDenylist` becomes a public typedef so tests can construct snapshots.

---

## Risks

- **Accidental behavior drift.** Each of the four tools needs its current error messages, size caps, and edge cases preserved exactly. The test migration table in §Testing is the checklist; every existing assertion has a named destination.
- **AIRepository signature ripple.** Three files change on the type name swap. If any caller missed, build breaks loudly — not a silent risk.
- **Denylist snapshot staleness.** The denylist loads at the start of `ToolRegistry.execute`; if the user edits the denylist mid-tool-call, the in-flight call uses the snapshot taken when dispatch started. This matches today's behavior (each handler's `_loadEffectiveDenylist` is async and may also miss mid-call edits) — no regression, worth noting for future observability work.
- **Non-reactive registry mutation.** Documented as deliberate. If someone in Phase 2+ adds a widget that watches the tools list expecting reactive updates, they'll need to either use `ref.read` (fine) or promote the registry to a Notifier shape (cheap conversion).

---

## Follow-up work unlocked by this phase

- **Phase 2 — Grep + Glob tools:** add two new files under `lib/services/coding_tools/tools/`, register them in `toolRegistry()`. No other code change.
- **Phase 3 — Parallel tool execution:** small change to `AgentService` around the sequential `for (final call in roundCalls)` loop at [agent_service.dart:201-231](../../../lib/services/agent/agent_service.dart). Registry is unaffected.
- **Phase 5 — Bash tool:** adds a tool with `capability: ToolCapability.shell`. `visibleTools` and `requiresPrompt` already handle `shell` correctly via the existing policy (`!= readOnly` gets prompted in askBefore).
- **Phase 6 — Anthropic provider:** `Tool.toOpenAiToolJson` becomes one of several serializers; the registry is provider-agnostic. Adding an `AnthropicWireAdapter` is isolated to the AI layer.
- **Phase 7 — MCP:** external tools arrive via `registry.register(McpTool(...))`. At that point, evaluate whether to promote the registry to a `Notifier` for reactive propagation.
