# Tool Registry Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static `CodingTools.all` catalog and `switch(toolName)` dispatch in `CodingToolsService` with a polymorphic `Tool` interface, a `ToolContext` that centralizes path-safety, and a `ToolRegistry` service. No behavior change — all 14 existing test assertions must survive.

**Architecture:** Each tool becomes its own Riverpod-provided class holding its own dependencies. The path-resolution + project-boundary + denylist ritual that every handler repeats today collapses onto `ToolContext.safePath`. `ToolRegistry` dispatches by name, loads the effective denylist once per call, and exposes permission-aware helpers (`visibleTools`, `requiresPrompt`). `AgentService` loses its two hardcoded tool-name strings and asks the registry instead.

**Tech Stack:** Dart 3 (sealed classes + records), Flutter, Riverpod 2 with code generation (`@riverpod` / `@Riverpod(keepAlive: true)`), `flutter_test`. No Freezed needed — `PathResult` uses a plain sealed class because it's local and doesn't need serialization.

**Spec:** [docs/superpowers/specs/2026-04-21-tool-registry-refactor-design.md](../specs/2026-04-21-tool-registry-refactor-design.md)

---

## Prerequisites

### Task 0: Create worktree and baseline the build

**Files:**
- Create (worktree): `.worktrees/tech/2026-04-21-tool-registry-refactor`

- [ ] **Step 0.1: Create the worktree**

Per [CLAUDE.md](../../../CLAUDE.md) convention, all implementation work for this plan lives in a git worktree. The type is `tech/` because this is a refactor.

Run (from the repo root):
```bash
git worktree add .worktrees/tech/2026-04-21-tool-registry-refactor -b tech/2026-04-21-tool-registry-refactor
cd .worktrees/tech/2026-04-21-tool-registry-refactor
```

Expected: worktree created, `HEAD` now on new branch.

- [ ] **Step 0.2: Verify spec and plan are checked in**

Run:
```bash
ls docs/superpowers/specs/2026-04-21-tool-registry-refactor-design.md
ls docs/superpowers/plans/2026-04-21-tool-registry-refactor.md
```
Expected: both files listed.

- [ ] **Step 0.3: Baseline — current tests pass on a clean tree**

Run:
```bash
flutter pub get
flutter test
```
Expected: all tests pass. If any fail, **halt** — investigate before starting the refactor. The whole premise of this plan is "no behavior change", which only has meaning against a known-green baseline.

---

## Part 1 — Data-layer contracts

### Task 1: Add the type skeletons (`Tool`, `ToolCapability`, `ToolContext` stub, `PathResult`, `EffectiveDenylist`)

This task creates the compiling-but-unimplemented versions of the new types. `ToolContext.safePath` throws `UnimplementedError` so the next task (writing tests) can observe failing tests.

**Files:**
- Create: `lib/data/coding_tools/models/tool_capability.dart`
- Create: `lib/data/coding_tools/models/effective_denylist.dart`
- Create: `lib/data/coding_tools/models/path_result.dart`
- Create: `lib/data/coding_tools/models/tool_context.dart`
- Create: `lib/data/coding_tools/models/tool.dart`

- [ ] **Step 1.1: Create `tool_capability.dart`**

```dart
// lib/data/coding_tools/models/tool_capability.dart

/// Declarative tag describing the side-effect surface of a [Tool].
/// Drives [ToolRegistry]'s permission-aware filtering.
///
/// - [readOnly]: reads filesystem or in-memory state only. Always allowed.
/// - [mutatingFiles]: creates, overwrites, or edits files in the project.
/// - [shell]: spawns a subprocess. (Reserved for Phase 5 — not used yet.)
/// - [network]: makes HTTP or socket I/O. (Reserved for Phase 9 — not used yet.)
enum ToolCapability { readOnly, mutatingFiles, shell, network }
```

- [ ] **Step 1.2: Create `effective_denylist.dart`**

```dart
// lib/data/coding_tools/models/effective_denylist.dart

/// Snapshot of the user's effective denylist (defaults + userAdded −
/// suppressedDefaults). Loaded once per [ToolRegistry.execute] call
/// and embedded in every [ToolContext] for the duration of that call.
typedef EffectiveDenylist = ({
  Set<String> segments,
  Set<String> filenames,
  Set<String> extensions,
  Set<String> prefixes,
});
```

- [ ] **Step 1.3: Create `path_result.dart`**

```dart
// lib/data/coding_tools/models/path_result.dart

import 'coding_tool_result.dart';

/// Return type for [ToolContext.safePath]. Either carries the vetted
/// absolute path (plus a display-safe form of the raw arg) or a pre-built
/// [CodingToolResult] error the caller should return directly.
sealed class PathResult {
  const PathResult();
}

final class PathOk extends PathResult {
  const PathOk(this.abs, this.displayRaw);

  /// Absolute, normalized path that passed project-boundary and denylist
  /// checks. Safe to hand to the filesystem repository.
  final String abs;

  /// Sanitized raw arg (control chars stripped, length-capped) suitable
  /// for embedding in success or error messages returned to the model.
  final String displayRaw;
}

final class PathErr extends PathResult {
  const PathErr(this.result);

  /// Pre-built [CodingToolResult.error] the caller should return directly.
  final CodingToolResult result;
}
```

- [ ] **Step 1.4: Create `tool_context.dart` (skeleton)**

```dart
// lib/data/coding_tools/models/tool_context.dart

import 'effective_denylist.dart';
import 'path_result.dart';

/// Request-scoped inputs to a [Tool.execute] call. Carries the data that
/// varies per tool invocation plus safety helpers that centralize the
/// resolve + assertWithinProject + denylist ritual every file-touching
/// tool used to repeat.
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
  /// Returns [PathOk] with the vetted absolute path, or [PathErr] carrying
  /// a pre-built error result (with verb-aware phrasing) the caller
  /// should return.
  ///
  /// [verb] — the tool's action phrasing ("Read"/"Write"/"List"/"Edit"),
  /// used in the path-escape and denylist error messages.
  /// [noun] — what the tool operates on: "file" for read/write/edit,
  /// "directory" for list. Controls the `(sensitive {noun})` suffix in
  /// denylist-block errors. Defaults to "file".
  PathResult safePath(String argName, {required String verb, String noun = 'file'}) {
    throw UnimplementedError();
  }

  /// Strips control chars and truncates to [max] characters. Used when
  /// embedding a raw arg into an error message fed back to the model.
  String sanitizeForError(String raw, {int max = 120}) {
    throw UnimplementedError();
  }
}
```

- [ ] **Step 1.5: Create `tool.dart`**

```dart
// lib/data/coding_tools/models/tool.dart

import 'coding_tool_result.dart';
import 'tool_capability.dart';
import 'tool_context.dart';

/// A single tool the agent loop may call. Concrete implementations live
/// in `lib/services/coding_tools/tools/`; each holds its own dependencies
/// via constructor injection and is registered into [ToolRegistry]
/// through a Riverpod provider.
abstract class Tool {
  String get name;
  String get description;
  Map<String, dynamic> get inputSchema;
  ToolCapability get capability;

  Future<CodingToolResult> execute(ToolContext ctx);

  /// Serializes to the OpenAI chat-completions `tools[]` schema, used by
  /// [CustomRemoteDatasourceDio] when building the request body. Replaces
  /// `CodingToolDefinition.toOpenAiToolJson()`.
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

- [ ] **Step 1.6: Verify compilation**

Run:
```bash
flutter analyze lib/data/coding_tools/models/
```
Expected: no errors or warnings.

### Task 2: Implement and test `ToolContext.safePath` + `sanitizeForError`

TDD: tests first (they fail with `UnimplementedError`), then fill in the implementation.

**Files:**
- Modify: `lib/data/coding_tools/models/tool_context.dart`
- Create: `test/data/coding_tools/models/tool_context_test.dart`

- [ ] **Step 2.1: Write the tests**

```dart
// test/data/coding_tools/models/tool_context_test.dart

import 'dart:io';

import 'package:code_bench_app/data/coding_tools/models/effective_denylist.dart';
import 'package:code_bench_app/data/coding_tools/models/path_result.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

EffectiveDenylist _empty() => (
  segments: const <String>{},
  filenames: const <String>{},
  extensions: const <String>{},
  prefixes: const <String>{},
);

ToolContext _ctx({
  required String projectPath,
  Map<String, dynamic> args = const {},
  EffectiveDenylist? denylist,
}) => ToolContext(
  projectPath: projectPath,
  sessionId: 's',
  messageId: 'm',
  args: args,
  denylist: denylist ?? _empty(),
);

void main() {
  late Directory projectDir;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('tool_ctx_');
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  group('safePath — arg validation', () {
    test('missing arg returns PathErr with "requires a non-empty" message', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {});
      final r = ctx.safePath('path', verb: 'Read');
      expect(r, isA<PathErr>());
      final err = (r as PathErr).result;
      expect(err, isA<CodingToolResultError>());
      expect((err as CodingToolResultError).message, contains('requires a non-empty "path"'));
    });

    test('non-string arg returns PathErr', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': 42});
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });

    test('empty-string arg returns PathErr', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': ''});
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });
  });

  group('safePath — happy path', () {
    test('returns PathOk with absolute path and sanitized displayRaw', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': 'a.txt'});
      final r = ctx.safePath('path', verb: 'Read');
      expect(r, isA<PathOk>());
      final ok = r as PathOk;
      expect(ok.abs, p.normalize(p.join(projectDir.path, 'a.txt')));
      expect(ok.displayRaw, 'a.txt');
    });

    test('accepts absolute path inside the project', () {
      final inside = p.join(projectDir.path, 'sub', 'x.txt');
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': inside});
      expect(ctx.safePath('path', verb: 'Read'), isA<PathOk>());
    });
  });

  group('safePath — project-boundary', () {
    test('rejects relative path that escapes the project', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': '../../etc/passwd'});
      final r = ctx.safePath('path', verb: 'Read');
      expect(r, isA<PathErr>());
      final msg = ((r as PathErr).result as CodingToolResultError).message;
      expect(msg, contains('outside the project root'));
      expect(msg, contains('"../../etc/passwd"'));
    });

    test('rejects absolute path outside the project', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': '/etc/passwd'});
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });
  });

  group('safePath — denylist', () {
    test('rejects filename match with "sensitive file" suffix by default', () {
      final d = (
        segments: const <String>{},
        filenames: const <String>{'credentials'},
        extensions: const <String>{},
        prefixes: const <String>{},
      );
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': 'credentials'}, denylist: d);
      final r = ctx.safePath('path', verb: 'Read');
      expect(r, isA<PathErr>());
      final msg = ((r as PathErr).result as CodingToolResultError).message;
      expect(msg, contains('Reading "credentials" is blocked for safety (sensitive file).'));
    });

    test('rejects segment match and uses custom noun', () {
      final d = (
        segments: const <String>{'.git'},
        filenames: const <String>{},
        extensions: const <String>{},
        prefixes: const <String>{},
      );
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': '.git/config'}, denylist: d);
      final r = ctx.safePath('path', verb: 'List', noun: 'directory');
      expect(r, isA<PathErr>());
      final msg = ((r as PathErr).result as CodingToolResultError).message;
      expect(msg, contains('Listing ".git/config" is blocked for safety (sensitive directory).'));
    });

    test('rejects extension match', () {
      final d = (
        segments: const <String>{},
        filenames: const <String>{},
        extensions: const <String>{'.pem'},
        prefixes: const <String>{},
      );
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': 'keys/server.pem'}, denylist: d);
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });

    test('rejects filename-prefix match', () {
      final d = (
        segments: const <String>{},
        filenames: const <String>{},
        extensions: const <String>{},
        prefixes: const <String>{'.env.'},
      );
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': '.env.production'}, denylist: d);
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });
  });

  group('sanitizeForError', () {
    test('strips control characters', () {
      final ctx = _ctx(projectPath: projectDir.path);
      expect(ctx.sanitizeForError('a\nb\tc\x07d'), 'a b c d');
    });

    test('truncates to max with ellipsis', () {
      final ctx = _ctx(projectPath: projectDir.path);
      final long = 'x' * 200;
      final result = ctx.sanitizeForError(long, max: 10);
      expect(result, 'xxxxxxxxxx…');
    });

    test('passes short strings through unchanged', () {
      final ctx = _ctx(projectPath: projectDir.path);
      expect(ctx.sanitizeForError('normal text'), 'normal text');
    });
  });
}
```

- [ ] **Step 2.2: Run tests to confirm they fail with UnimplementedError**

Run:
```bash
flutter test test/data/coding_tools/models/tool_context_test.dart
```
Expected: all 14 tests fail (`UnimplementedError` thrown from stubs).

- [ ] **Step 2.3: Implement `ToolContext.safePath` and `sanitizeForError`**

Replace the entire content of `lib/data/coding_tools/models/tool_context.dart` with:

```dart
// lib/data/coding_tools/models/tool_context.dart

import 'package:path/path.dart' as p;

import '../../../core/utils/debug_logger.dart';
import '../../../services/apply/apply_exceptions.dart';
import '../../../services/apply/apply_service.dart';
import 'coding_tool_result.dart';
import 'effective_denylist.dart';
import 'path_result.dart';

/// Request-scoped inputs to a [Tool.execute] call. Carries per-call data
/// plus safety helpers that centralize the resolve + assertWithinProject
/// + denylist ritual every file-touching tool used to repeat.
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
  /// Returns [PathOk] with the vetted absolute path, or [PathErr] carrying
  /// a pre-built error result (with verb-aware phrasing) the caller
  /// should return.
  ///
  /// [verb] — the tool's action phrasing ("Read"/"Write"/"List"/"Edit"),
  /// used in the path-escape and denylist error messages.
  /// [noun] — what the tool operates on: "file" for read/write/edit,
  /// "directory" for list. Controls the `(sensitive {noun})` suffix in
  /// denylist-block errors. Defaults to "file".
  PathResult safePath(String argName, {required String verb, String noun = 'file'}) {
    final raw = args[argName];
    if (raw is! String || raw.isEmpty) {
      return PathErr(
        CodingToolResult.error('${_toolNameFromVerb(verb)} requires a non-empty "$argName"'),
      );
    }
    final displayRaw = sanitizeForError(raw);
    final abs = p.isAbsolute(raw) ? p.normalize(raw) : p.normalize(p.join(projectPath, raw));

    try {
      ApplyService.assertWithinProject(abs, projectPath);
    } on PathEscapeException {
      return PathErr(
        CodingToolResult.error('Path "$displayRaw" is outside the project root.'),
      );
    }

    final block = _checkDenied(abs);
    if (block != null) {
      sLog('[ToolContext] denied ${block.kind}: "${p.relative(abs, from: projectPath)}" ($block)');
      return PathErr(
        CodingToolResult.error('${verb}ing "$displayRaw" is blocked for safety (sensitive $noun).'),
      );
    }

    return PathOk(abs, displayRaw);
  }

  /// Strips control chars and truncates to [max] characters. Used when
  /// embedding a raw arg into an error message fed back to the model.
  String sanitizeForError(String raw, {int max = 120}) {
    final stripped = raw.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ');
    return stripped.length > max ? '${stripped.substring(0, max)}…' : stripped;
  }

  _DenyMatch? _checkDenied(String abs) {
    final rel = p.relative(abs, from: projectPath);
    for (final segRaw in p.split(rel)) {
      final seg = segRaw.toLowerCase();
      if (seg.isEmpty || seg == '.' || seg == '..') continue;
      if (denylist.segments.contains(seg)) return _DenyMatch('segment', seg);
      if (denylist.filenames.contains(seg)) return _DenyMatch('filename', seg);
      if (denylist.prefixes.any(seg.startsWith)) return _DenyMatch('prefix', seg);
      final ext = p.extension(seg).toLowerCase();
      if (ext.isNotEmpty && denylist.extensions.contains(ext)) return _DenyMatch('extension', ext);
    }
    return null;
  }

  String _toolNameFromVerb(String verb) => switch (verb) {
    'Read' => 'read_file',
    'Write' => 'write_file',
    'List' => 'list_dir',
    'Edit' => 'str_replace',
    _ => verb.toLowerCase(),
  };
}

class _DenyMatch {
  const _DenyMatch(this.kind, this.value);
  final String kind; // 'segment' | 'filename' | 'prefix' | 'extension'
  final String value;

  @override
  String toString() => '$kind=$value';
}
```

- [ ] **Step 2.4: Re-run tests to confirm they pass**

Run:
```bash
flutter test test/data/coding_tools/models/tool_context_test.dart
```
Expected: all 14 tests pass.

- [ ] **Step 2.5: Run analyzer on changed files**

Run:
```bash
flutter analyze lib/data/coding_tools/models/ test/data/coding_tools/models/
```
Expected: no errors or warnings.

### Task 3: Add the shared test helper

**Files:**
- Create: `test/services/coding_tools/_helpers/tool_test_helpers.dart`

- [ ] **Step 3.1: Create the helpers file**

```dart
// test/services/coding_tools/_helpers/tool_test_helpers.dart

import 'package:code_bench_app/data/coding_tools/models/effective_denylist.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';

/// Empty denylist snapshot for tests that don't exercise the denylist.
EffectiveDenylist emptyDenylist() => (
  segments: const <String>{},
  filenames: const <String>{},
  extensions: const <String>{},
  prefixes: const <String>{},
);

/// Builds a [ToolContext] with sane test defaults. Override any field as
/// needed. The default [denylist] is [emptyDenylist].
ToolContext fakeCtx({
  required String projectPath,
  String sessionId = 's',
  String messageId = 'm',
  Map<String, dynamic> args = const {},
  EffectiveDenylist? denylist,
}) => ToolContext(
  projectPath: projectPath,
  sessionId: sessionId,
  messageId: messageId,
  args: args,
  denylist: denylist ?? emptyDenylist(),
);
```

- [ ] **Step 3.2: Run analyzer**

Run:
```bash
flutter analyze test/services/coding_tools/_helpers/
```
Expected: no errors or warnings.

### Task 4: Commit 1 — data-layer contracts

- [ ] **Step 4.1: Format**

Run:
```bash
dart format lib/data/coding_tools/models/ test/data/coding_tools/models/ test/services/coding_tools/_helpers/
```

- [ ] **Step 4.2: Stage and commit**

Run:
```bash
git add \
  lib/data/coding_tools/models/tool.dart \
  lib/data/coding_tools/models/tool_capability.dart \
  lib/data/coding_tools/models/tool_context.dart \
  lib/data/coding_tools/models/path_result.dart \
  lib/data/coding_tools/models/effective_denylist.dart \
  test/data/coding_tools/models/tool_context_test.dart \
  test/services/coding_tools/_helpers/tool_test_helpers.dart

git commit -m "$(cat <<'EOF'
feat(coding-tools): add Tool / ToolContext contracts with path-safety helpers

Phase 1 of tool registry refactor (additive, no behavior change). Adds:
- Tool: abstract interface with name/description/schema/capability/execute
  and toOpenAiToolJson, replacing the upcoming deletion of
  CodingToolDefinition.
- ToolCapability: enum {readOnly, mutatingFiles, shell, network}.
- ToolContext: request-scoped context with safePath (centralizes the
  resolve + assertWithinProject + denylist ritual) and sanitizeForError.
- PathResult sealed class: PathOk(abs, displayRaw) | PathErr(result).
- EffectiveDenylist typedef lifted from CodingToolsService private type.

Tests cover ToolContext invariants (missing/non-string args, path
escape, denylist matches across all four categories, sanitization).

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4.3: Verify clean status**

Run: `git status`
Expected: `nothing to commit, working tree clean` (relative to the changes in this task).

---

## Part 2 — Tools and Registry

Each tool follows the same TDD shape: (a) write a skeleton class that compiles but throws `UnimplementedError` from `execute`, (b) write the test file with the migrated assertions, (c) run tests to confirm they fail, (d) fill in the implementation, (e) run tests to confirm they pass.

### Task 5: `ReadFileTool`

**Files:**
- Create: `lib/services/coding_tools/tools/read_file_tool.dart`
- Create: `test/services/coding_tools/tools/read_file_tool_test.dart`

- [ ] **Step 5.1: Create skeleton**

```dart
// lib/services/coding_tools/tools/read_file_tool.dart

import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../../data/coding_tools/repository/coding_tools_repository_impl.dart';

part 'read_file_tool.g.dart';

@riverpod
ReadFileTool readFileTool(Ref ref) => ReadFileTool(
  repo: ref.watch(codingToolsRepositoryProvider),
);

class ReadFileTool implements Tool {
  ReadFileTool({required this.repo});
  final CodingToolsRepository repo;

  static const int _kMaxReadBytes = 2 * 1024 * 1024; // 2 MB

  @override
  String get name => 'read_file';
  @override
  ToolCapability get capability => ToolCapability.readOnly;
  @override
  String get description => 'Read the contents of a text file inside the active project.';
  @override
  Map<String, dynamic> get inputSchema => const {
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
    throw UnimplementedError();
  }
}
```

- [ ] **Step 5.2: Generate the Riverpod part file**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: `read_file_tool.g.dart` created; build succeeds.

- [ ] **Step 5.3: Write the tests**

```dart
// test/services/coding_tools/tools/read_file_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/services/coding_tools/tools/read_file_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

void main() {
  late Directory projectDir;
  late ReadFileTool tool;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('read_tool_');
    tool = ReadFileTool(
      repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()),
    );
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('returns success with content', () async {
    File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('hello');
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'a.txt'}));
    expect(r, isA<CodingToolResultSuccess>());
    expect((r as CodingToolResultSuccess).output, 'hello');
  });

  test('rejects files larger than 2MB', () async {
    final big = File(p.join(projectDir.path, 'big.bin'));
    big.writeAsBytesSync(List.filled(2 * 1024 * 1024 + 1, 0x41));
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'big.bin'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('File too large'));
  });

  test('rejects non-text files with a clear error', () async {
    File(p.join(projectDir.path, 'bad.bin')).writeAsBytesSync([0xC3, 0x28]);
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'bad.bin'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('not text-encoded'));
  });

  test('returns error for non-existent file', () async {
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': 'missing.txt'}));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('does not exist'));
  });

  test('surfaces ctx.safePath errors (path escape sanity)', () async {
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': '../../../etc/passwd'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });
}
```

- [ ] **Step 5.4: Run tests to confirm they fail**

Run:
```bash
flutter test test/services/coding_tools/tools/read_file_tool_test.dart
```
Expected: 5 tests fail (`UnimplementedError`).

- [ ] **Step 5.5: Implement `execute`**

Replace the `execute` body in `lib/services/coding_tools/tools/read_file_tool.dart`:

```dart
@override
Future<CodingToolResult> execute(ToolContext ctx) async {
  final p = ctx.safePath('path', verb: 'Read');
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
```

- [ ] **Step 5.6: Run tests to confirm they pass**

Run:
```bash
flutter test test/services/coding_tools/tools/read_file_tool_test.dart
```
Expected: all 5 tests pass.

### Task 6: `ListDirTool`

**Files:**
- Create: `lib/services/coding_tools/tools/list_dir_tool.dart`
- Create: `test/services/coding_tools/tools/list_dir_tool_test.dart`

- [ ] **Step 6.1: Create skeleton**

```dart
// lib/services/coding_tools/tools/list_dir_tool.dart

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/effective_denylist.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../../data/coding_tools/repository/coding_tools_repository_impl.dart';
import '../../../services/apply/apply_exceptions.dart';
import '../../../services/apply/apply_service.dart';

part 'list_dir_tool.g.dart';

@riverpod
ListDirTool listDirTool(Ref ref) => ListDirTool(
  repo: ref.watch(codingToolsRepositoryProvider),
);

class ListDirTool implements Tool {
  ListDirTool({required this.repo});
  final CodingToolsRepository repo;

  static const int _kMaxListEntries = 500;
  static const int _kMaxListDepth = 3;

  @override
  String get name => 'list_dir';
  @override
  ToolCapability get capability => ToolCapability.readOnly;
  @override
  String get description => 'List entries in a directory inside the active project.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'recursive': {'type': 'boolean', 'default': false},
    },
    'required': ['path'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    throw UnimplementedError();
  }
}
```

- [ ] **Step 6.2: Generate part file**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6.3: Write the tests**

```dart
// test/services/coding_tools/tools/list_dir_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/services/coding_tools/tools/list_dir_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

void main() {
  late Directory projectDir;
  late ListDirTool tool;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('list_tool_');
    tool = ListDirTool(
      repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()),
    );
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('non-recursive lists immediate children', () async {
    File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('x');
    Directory(p.join(projectDir.path, 'sub')).createSync();
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': '.', 'recursive': false}),
    );
    expect(r, isA<CodingToolResultSuccess>());
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('a.txt'));
    expect(out, contains('sub'));
  });

  test('missing path returns error', () async {
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': 'does_not_exist'}),
    );
    expect(r, isA<CodingToolResultError>());
  });

  test('surfaces ctx.safePath errors (path escape sanity)', () async {
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'path': '../../..'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });
}
```

- [ ] **Step 6.4: Run tests to confirm they fail**

Run: `flutter test test/services/coding_tools/tools/list_dir_tool_test.dart`
Expected: 3 tests fail.

- [ ] **Step 6.5: Implement `execute`**

Replace the `execute` body. Note the two special cases: (a) the project root is allowed (`assertWithinProject` rejects the root itself, so we check explicitly); (b) listing filters entries matching the denylist without revealing them.

```dart
@override
Future<CodingToolResult> execute(ToolContext ctx) async {
  final raw = ctx.args['path'];
  if (raw is! String || raw.isEmpty) {
    return CodingToolResult.error('list_dir requires a non-empty "path"');
  }
  final displayRaw = ctx.sanitizeForError(raw);
  final recursive = ctx.args['recursive'] == true;
  final abs = p.isAbsolute(raw)
      ? p.normalize(raw)
      : p.normalize(p.join(ctx.projectPath, raw));

  try {
    final normalAbs = p.normalize(p.absolute(abs));
    final normalRoot = p.normalize(p.absolute(ctx.projectPath));
    if (normalAbs != normalRoot) {
      // Non-root: run full safePath check (boundary + denylist).
      final pr = ctx.safePath('path', verb: 'List', noun: 'directory');
      if (pr is PathErr) return pr.result;
    } else if (!await repo.directoryExists(normalRoot)) {
      throw ProjectMissingException(ctx.projectPath);
    }
    if (!await repo.directoryExists(abs)) {
      return CodingToolResult.error('"$displayRaw" is not a directory or does not exist.');
    }

    final entries = await repo.listDirectory(abs, recursive: recursive);
    final buffer = StringBuffer();
    var count = 0;
    for (final entry in entries) {
      final rel = p.relative(entry.path, from: abs);
      final depth = rel.split(p.separator).length;
      if (recursive && depth > _kMaxListDepth) continue;
      if (_isDeniedRel(p.relative(entry.path, from: ctx.projectPath), ctx.denylist)) continue;
      final String typeStr;
      try {
        typeStr = entry.statSync().type.toString().split('.').last;
      } on FileSystemException catch (e) {
        dLog('[ListDirTool] stat failed for "${entry.path}": ${e.osError?.message ?? e.message}');
        continue;
      }
      buffer.writeln('- $rel ($typeStr)');
      count++;
      if (count >= _kMaxListEntries) {
        buffer.writeln('(truncated, $_kMaxListEntries+ entries)');
        break;
      }
    }
    return CodingToolResult.success(buffer.toString().trimRight());
  } on ProjectMissingException {
    return CodingToolResult.error('Project folder is missing.');
  } on FileSystemException catch (e) {
    dLog('[ListDirTool] FileSystemException: ${e.osError?.message ?? e.message}');
    return CodingToolResult.error(
      'Cannot list "$displayRaw": ${e.osError?.message ?? 'I/O error'}.',
    );
  }
}

bool _isDeniedRel(String relPath, EffectiveDenylist denylist) {
  for (final segRaw in p.split(relPath)) {
    final seg = segRaw.toLowerCase();
    if (seg.isEmpty || seg == '.' || seg == '..') continue;
    if (denylist.segments.contains(seg)) return true;
    if (denylist.filenames.contains(seg)) return true;
    if (denylist.prefixes.any(seg.startsWith)) return true;
    final ext = p.extension(seg).toLowerCase();
    if (ext.isNotEmpty && denylist.extensions.contains(ext)) return true;
  }
  return false;
}
```

- [ ] **Step 6.6: Run tests to confirm they pass**

Run: `flutter test test/services/coding_tools/tools/list_dir_tool_test.dart`
Expected: all 3 tests pass.

### Task 7: `WriteFileTool`

**Files:**
- Create: `lib/services/coding_tools/tools/write_file_tool.dart`
- Create: `test/services/coding_tools/tools/write_file_tool_test.dart`

- [ ] **Step 7.1: Create skeleton**

```dart
// lib/services/coding_tools/tools/write_file_tool.dart

import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../services/apply/apply_exceptions.dart';
import '../../../services/apply/apply_service.dart';

part 'write_file_tool.g.dart';

@riverpod
WriteFileTool writeFileTool(Ref ref) => WriteFileTool(
  applyService: ref.watch(applyServiceProvider),
);

class WriteFileTool implements Tool {
  WriteFileTool({required this.applyService});
  final ApplyService applyService;

  @override
  String get name => 'write_file';
  @override
  ToolCapability get capability => ToolCapability.mutatingFiles;
  @override
  String get description =>
      'Create or overwrite a file inside the active project. Prefer str_replace for targeted edits to existing files.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'content': {'type': 'string'},
    },
    'required': ['path', 'content'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    throw UnimplementedError();
  }
}
```

- [ ] **Step 7.2: Generate part file**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 7.3: Write the tests**

```dart
// test/services/coding_tools/tools/write_file_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/tools/write_file_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

void main() {
  late Directory projectDir;
  late WriteFileTool tool;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('write_tool_');
    final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
    tool = WriteFileTool(applyService: ApplyService(repo: applyRepo));
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('creates new file and returns byte count', () async {
    final r = await tool.execute(fakeCtx(
      projectPath: projectDir.path,
      args: {'path': 'new.txt', 'content': 'hello world'},
    ));
    expect(r, isA<CodingToolResultSuccess>());
    expect(File(p.join(projectDir.path, 'new.txt')).readAsStringSync(), 'hello world');
  });

  test('overwrites existing file', () async {
    File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('old');
    final r = await tool.execute(fakeCtx(
      projectPath: projectDir.path,
      args: {'path': 'x.txt', 'content': 'new'},
    ));
    expect(r, isA<CodingToolResultSuccess>());
    expect(File(p.join(projectDir.path, 'x.txt')).readAsStringSync(), 'new');
  });

  test('surfaces ctx.safePath errors (path escape sanity)', () async {
    final r = await tool.execute(fakeCtx(
      projectPath: projectDir.path,
      args: {'path': '../etc/passwd', 'content': 'x'},
    ));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });

  test('requires string content', () async {
    final r = await tool.execute(fakeCtx(
      projectPath: projectDir.path,
      args: {'path': 'x.txt', 'content': 42},
    ));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('"content"'));
  });
}
```

- [ ] **Step 7.4: Run tests to confirm they fail**

Run: `flutter test test/services/coding_tools/tools/write_file_tool_test.dart`
Expected: 4 tests fail.

- [ ] **Step 7.5: Implement `execute`**

```dart
@override
Future<CodingToolResult> execute(ToolContext ctx) async {
  final content = ctx.args['content'];
  if (content is! String) {
    return CodingToolResult.error('write_file requires a string "content"');
  }
  final p = ctx.safePath('path', verb: 'Write');
  if (p is PathErr) return p.result;
  final PathOk(:abs, :displayRaw) = p;

  try {
    await applyService.applyChange(
      filePath: abs,
      projectPath: ctx.projectPath,
      newContent: content,
      sessionId: ctx.sessionId,
      messageId: ctx.messageId,
    );
    final bytes = utf8.encode(content).length;
    return CodingToolResult.success('Wrote $bytes bytes to $displayRaw.');
  } on ProjectMissingException {
    return CodingToolResult.error('Project folder is missing.');
  } on ApplyTooLargeException catch (e) {
    return CodingToolResult.error('File too large (${e.bytes} bytes).');
  } on FileSystemException catch (e) {
    dLog('[WriteFileTool] FileSystemException: ${e.osError?.message ?? e.message}');
    return CodingToolResult.error(
      'Cannot write "$displayRaw": ${e.osError?.message ?? 'I/O error'}.',
    );
  }
}
```

- [ ] **Step 7.6: Run tests to confirm they pass**

Run: `flutter test test/services/coding_tools/tools/write_file_tool_test.dart`
Expected: all 4 tests pass.

### Task 8: `StrReplaceTool`

**Files:**
- Create: `lib/services/coding_tools/tools/str_replace_tool.dart`
- Create: `test/services/coding_tools/tools/str_replace_tool_test.dart`

- [ ] **Step 8.1: Create skeleton**

```dart
// lib/services/coding_tools/tools/str_replace_tool.dart

import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../../data/coding_tools/repository/coding_tools_repository_impl.dart';
import '../../../services/apply/apply_exceptions.dart';
import '../../../services/apply/apply_service.dart';

part 'str_replace_tool.g.dart';

@riverpod
StrReplaceTool strReplaceTool(Ref ref) => StrReplaceTool(
  repo: ref.watch(codingToolsRepositoryProvider),
  applyService: ref.watch(applyServiceProvider),
);

class StrReplaceTool implements Tool {
  StrReplaceTool({required this.repo, required this.applyService});
  final CodingToolsRepository repo;
  final ApplyService applyService;

  @override
  String get name => 'str_replace';
  @override
  ToolCapability get capability => ToolCapability.mutatingFiles;
  @override
  String get description =>
      'Replace the first exact occurrence of old_str with new_str in a file. '
      'The match must be unique — if zero or multiple matches exist, this tool '
      'returns an error and the file is unchanged.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'old_str': {'type': 'string'},
      'new_str': {'type': 'string'},
    },
    'required': ['path', 'old_str', 'new_str'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    throw UnimplementedError();
  }
}

int _countOccurrences(String haystack, String needle) {
  if (needle.isEmpty) return 0;
  var count = 0;
  var idx = 0;
  while ((idx = haystack.indexOf(needle, idx)) != -1) {
    count++;
    idx += needle.length;
  }
  return count;
}
```

- [ ] **Step 8.2: Generate part file**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 8.3: Write the tests**

```dart
// test/services/coding_tools/tools/str_replace_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/tools/str_replace_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

void main() {
  late Directory projectDir;
  late StrReplaceTool tool;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('repl_tool_');
    final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
    tool = StrReplaceTool(
      repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()),
      applyService: ApplyService(repo: applyRepo),
    );
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('replaces a unique occurrence', () async {
    File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('hello world');
    final r = await tool.execute(fakeCtx(
      projectPath: projectDir.path,
      args: {'path': 'x.txt', 'old_str': 'world', 'new_str': 'dart'},
    ));
    expect(r, isA<CodingToolResultSuccess>());
    expect(File(p.join(projectDir.path, 'x.txt')).readAsStringSync(), 'hello dart');
  });

  test('returns error when old_str not found', () async {
    File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('hello');
    final r = await tool.execute(fakeCtx(
      projectPath: projectDir.path,
      args: {'path': 'x.txt', 'old_str': 'missing', 'new_str': 'x'},
    ));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('not found'));
  });

  test('returns error when old_str matches multiple times', () async {
    File(p.join(projectDir.path, 'x.txt')).writeAsStringSync('ab ab ab');
    final r = await tool.execute(fakeCtx(
      projectPath: projectDir.path,
      args: {'path': 'x.txt', 'old_str': 'ab', 'new_str': 'cd'},
    ));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('matches 3 times'));
  });

  test('surfaces ctx.safePath errors (path escape sanity)', () async {
    final r = await tool.execute(fakeCtx(
      projectPath: projectDir.path,
      args: {'path': '../x', 'old_str': 'a', 'new_str': 'b'},
    ));
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });
}
```

- [ ] **Step 8.4: Run tests to confirm they fail**

Run: `flutter test test/services/coding_tools/tools/str_replace_tool_test.dart`
Expected: 4 tests fail.

- [ ] **Step 8.5: Implement `execute`**

```dart
@override
Future<CodingToolResult> execute(ToolContext ctx) async {
  final oldStr = ctx.args['old_str'];
  final newStr = ctx.args['new_str'];
  if (oldStr is! String || oldStr.isEmpty) {
    return CodingToolResult.error('str_replace requires "old_str"');
  }
  if (newStr is! String) {
    return CodingToolResult.error('str_replace requires "new_str"');
  }
  final pr = ctx.safePath('path', verb: 'Edit');
  if (pr is PathErr) return pr.result;
  final PathOk(:abs, :displayRaw) = pr;

  try {
    final original = await repo.readTextFile(abs);
    final matchCount = _countOccurrences(original, oldStr);
    if (matchCount == 0) {
      return CodingToolResult.error(
        'old_str not found in $displayRaw. The match must be exact, including whitespace.',
      );
    }
    if (matchCount > 1) {
      return CodingToolResult.error(
        'old_str matches $matchCount times in $displayRaw. Include more surrounding context to make it unique.',
      );
    }
    final updated = original.replaceFirst(oldStr, newStr);
    await applyService.applyChange(
      filePath: abs,
      projectPath: ctx.projectPath,
      newContent: updated,
      sessionId: ctx.sessionId,
      messageId: ctx.messageId,
    );
    return CodingToolResult.success('Replaced 1 match in $displayRaw.');
  } on PathNotFoundException {
    return CodingToolResult.error('File "$displayRaw" does not exist.');
  } on FormatException {
    return CodingToolResult.error('File "$displayRaw" is not text-encoded.');
  } on ProjectMissingException {
    return CodingToolResult.error('Project folder is missing.');
  } on ApplyTooLargeException catch (e) {
    return CodingToolResult.error('File too large (${e.bytes} bytes).');
  } on FileSystemException catch (e) {
    dLog('[StrReplaceTool] FileSystemException: ${e.osError?.message ?? e.message}');
    return CodingToolResult.error(
      'Cannot edit "$displayRaw": ${e.osError?.message ?? 'I/O error'}.',
    );
  }
}
```

- [ ] **Step 8.6: Run tests to confirm they pass**

Run: `flutter test test/services/coding_tools/tools/str_replace_tool_test.dart`
Expected: all 4 tests pass.

### Task 9: `ToolRegistry`

**Files:**
- Create: `lib/services/coding_tools/tool_registry.dart`
- Create: `test/services/coding_tools/tool_registry_test.dart`

- [ ] **Step 9.1: Create skeleton**

```dart
// lib/services/coding_tools/tool_registry.dart

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/coding_tools/models/coding_tool_result.dart';
import '../../data/coding_tools/models/denylist_category.dart';
import '../../data/coding_tools/models/effective_denylist.dart';
import '../../data/coding_tools/models/tool.dart';
import '../../data/coding_tools/models/tool_capability.dart';
import '../../data/coding_tools/models/tool_context.dart';
import '../../data/coding_tools/repository/coding_tools_denylist_repository.dart';
import '../../data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';
import '../../data/session/models/session_settings.dart';
import 'tools/list_dir_tool.dart';
import 'tools/read_file_tool.dart';
import 'tools/str_replace_tool.dart';
import 'tools/write_file_tool.dart';

part 'tool_registry.g.dart';

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

/// Central registry of all tools the agent loop may call. Holds built-in
/// tools and — via [register] — runtime-added tools (the seam MCP will
/// plug into in Phase 7).
///
/// Replaces the static `CodingTools.all` catalog and the `switch(toolName)`
/// dispatch in the deleted `CodingToolsService`.
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

  /// Tools the agent is allowed to see under [p]. In readOnly mode the
  /// model receives only tools tagged [ToolCapability.readOnly]; in all
  /// other modes it receives every registered tool.
  List<Tool> visibleTools(ChatPermission p) => p == ChatPermission.readOnly
      ? _tools.where((t) => t.capability == ToolCapability.readOnly).toList()
      : List.unmodifiable(_tools);

  /// Whether invoking [t] should raise a PermissionRequest in [p].
  bool requiresPrompt(Tool t, ChatPermission p) =>
      p == ChatPermission.askBefore && t.capability != ToolCapability.readOnly;

  /// Dispatcher. Loads the effective denylist, builds a [ToolContext],
  /// delegates to the tool, wraps crash-catch + timing log.
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

  /// Adds a tool at runtime. Phase-1 seam for Phase 7 MCP integration.
  /// Throws [StateError] if a tool with that name already exists.
  ///
  /// NOTE: mutation is not reactive. Watchers of toolRegistryProvider do
  /// not rebuild on register/unregister. AgentService reads the registry
  /// at the start of each turn so this is safe today. If Phase 7 needs
  /// reactive propagation, convert this class to a Notifier shape then.
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

- [ ] **Step 9.2: Generate part file**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 9.3: Write the tests**

```dart
// test/services/coding_tools/tool_registry_test.dart

import 'dart:io';

import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tools_denylist_state.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
import 'package:code_bench_app/data/coding_tools/models/tool.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/data/session/models/session_settings.dart';
import 'package:code_bench_app/data/_core/preferences/coding_tools_preferences.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/tool_registry.dart';
import 'package:code_bench_app/services/coding_tools/tools/list_dir_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/read_file_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/str_replace_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/write_file_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyDenylistRepo implements CodingToolsDenylistRepository {
  @override
  Future<CodingToolsDenylistState> load() async => CodingToolsDenylistState.empty();
  @override
  Future<CodingToolsDenylistState> save(CodingToolsDenylistState state) async => state;
  @override
  Future<Set<String>> effective(DenylistCategory category) async => {};
  @override
  Future<void> restoreAllDefaults() async {}
}

class _AlwaysCrashesTool implements Tool {
  @override String get name => 'crasher';
  @override ToolCapability get capability => ToolCapability.readOnly;
  @override String get description => 'always crashes for test purposes';
  @override Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override Map<String, dynamic> toOpenAiToolJson() => const {};
  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    throw StateError('boom');
  }
}

ToolRegistry _newRegistry({
  required Directory projectDir,
  CodingToolsDenylistRepository? denylistRepo,
}) {
  final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
  final applySvc = ApplyService(repo: applyRepo);
  final codingRepo = CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
  return ToolRegistry(
    builtIns: [
      ReadFileTool(repo: codingRepo),
      ListDirTool(repo: codingRepo),
      WriteFileTool(applyService: applySvc),
      StrReplaceTool(repo: codingRepo, applyService: applySvc),
    ],
    denylistRepo: denylistRepo ?? _EmptyDenylistRepo(),
  );
}

void main() {
  late Directory projectDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    projectDir = await Directory.systemTemp.createTemp('tool_reg_');
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  group('byName / byCapability', () {
    test('byName returns the registered tool', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.byName('read_file')?.name, 'read_file');
      expect(r.byName('nonexistent'), isNull);
    });

    test('byCapability filters correctly', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(
        r.byCapability(ToolCapability.readOnly).map((t) => t.name).toSet(),
        {'read_file', 'list_dir'},
      );
      expect(
        r.byCapability(ToolCapability.mutatingFiles).map((t) => t.name).toSet(),
        {'write_file', 'str_replace'},
      );
      expect(r.byCapability(ToolCapability.shell), isEmpty);
      expect(r.byCapability(ToolCapability.network), isEmpty);
    });
  });

  group('visibleTools', () {
    test('readOnly returns only readOnly-capability tools', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(
        r.visibleTools(ChatPermission.readOnly).map((t) => t.name).toList(),
        ['read_file', 'list_dir'],
      );
    });

    test('askBefore returns all tools', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.visibleTools(ChatPermission.askBefore).length, 4);
    });

    test('fullAccess returns all tools', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.visibleTools(ChatPermission.fullAccess).length, 4);
    });
  });

  group('requiresPrompt', () {
    test('askBefore + readOnly = false', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.requiresPrompt(r.byName('read_file')!, ChatPermission.askBefore), isFalse);
    });

    test('askBefore + mutatingFiles = true', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.requiresPrompt(r.byName('write_file')!, ChatPermission.askBefore), isTrue);
      expect(r.requiresPrompt(r.byName('str_replace')!, ChatPermission.askBefore), isTrue);
    });

    test('fullAccess never prompts', () {
      final r = _newRegistry(projectDir: projectDir);
      for (final t in r.tools) {
        expect(r.requiresPrompt(t, ChatPermission.fullAccess), isFalse);
      }
    });

    test('readOnly permission never prompts', () {
      final r = _newRegistry(projectDir: projectDir);
      for (final t in r.tools) {
        expect(r.requiresPrompt(t, ChatPermission.readOnly), isFalse);
      }
    });
  });

  group('register / unregister', () {
    test('register adds tool at the end', () {
      final r = _newRegistry(projectDir: projectDir);
      final before = r.tools.length;
      r.register(_AlwaysCrashesTool());
      expect(r.tools.length, before + 1);
      expect(r.tools.last.name, 'crasher');
    });

    test('register throws on name collision', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(
        () => r.register(ReadFileTool(repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()))),
        throwsStateError,
      );
    });

    test('unregister removes the tool', () {
      final r = _newRegistry(projectDir: projectDir);
      r.register(_AlwaysCrashesTool());
      r.unregister('crasher');
      expect(r.byName('crasher'), isNull);
    });
  });

  group('execute', () {
    test('dispatches to the named tool', () async {
      File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('hi');
      final r = _newRegistry(projectDir: projectDir);
      final result = await r.execute(
        name: 'read_file',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: {'path': 'a.txt'},
      );
      expect(result, isA<CodingToolResultSuccess>());
      expect((result as CodingToolResultSuccess).output, 'hi');
    });

    test('returns "Unknown tool" for unknown names', () async {
      final r = _newRegistry(projectDir: projectDir);
      final result = await r.execute(
        name: 'nope',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: const {},
      );
      expect(result, isA<CodingToolResultError>());
      expect((result as CodingToolResultError).message, contains('Unknown tool "nope"'));
    });

    test('catches tool crashes and returns error result', () async {
      final r = _newRegistry(projectDir: projectDir);
      r.register(_AlwaysCrashesTool());
      final result = await r.execute(
        name: 'crasher',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: const {},
      );
      expect(result, isA<CodingToolResultError>());
      expect((result as CodingToolResultError).message, contains('crashed unexpectedly'));
    });
  });

  group('configurable denylist', () {
    test('user-added filename refused on read_file', () async {
      final prefs = CodingToolsPreferences();
      final denylistRepo = CodingToolsDenylistRepositoryImpl(prefs: prefs);
      await denylistRepo.save(
        (await denylistRepo.load()).copyWith(
          userAdded: {
            DenylistCategory.filename: {'custom_secret'},
            for (final c in DenylistCategory.values)
              if (c != DenylistCategory.filename) c: <String>{},
          },
        ),
      );
      final r = _newRegistry(projectDir: projectDir, denylistRepo: denylistRepo);
      File(p.join(projectDir.path, 'custom_secret')).writeAsStringSync('sensitive');
      final result = await r.execute(
        name: 'read_file',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: {'path': 'custom_secret'},
      );
      expect(result, isA<CodingToolResultError>());
      expect((result as CodingToolResultError).message, contains('blocked for safety'));
    });

    test('suppressed baseline filename allowed on read_file', () async {
      final prefs = CodingToolsPreferences();
      final denylistRepo = CodingToolsDenylistRepositoryImpl(prefs: prefs);
      await denylistRepo.save(
        (await denylistRepo.load()).copyWith(
          suppressedDefaults: {
            DenylistCategory.filename: {'credentials'},
            for (final c in DenylistCategory.values)
              if (c != DenylistCategory.filename) c: <String>{},
          },
        ),
      );
      final r = _newRegistry(projectDir: projectDir, denylistRepo: denylistRepo);
      File(p.join(projectDir.path, 'credentials')).writeAsStringSync('not-actually-secret');
      final result = await r.execute(
        name: 'read_file',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: {'path': 'credentials'},
      );
      expect(result, isA<CodingToolResultSuccess>());
    });
  });
}
```

- [ ] **Step 9.4: Run tests to confirm they fail**

The registry skeleton is already implemented (not throwing UnimplementedError) because we wrote the full class body in Step 9.1 — the tests should run against the real impl. If there are any compilation or behavior issues, fix them now.

Run: `flutter test test/services/coding_tools/tool_registry_test.dart`
Expected: all tests pass. If any fail, fix the implementation in `tool_registry.dart` until they do.

### Task 10: Verify full test suite green before committing

- [ ] **Step 10.1: Run full test suite**

Run:
```bash
flutter test
```
Expected: all tests pass. The old `coding_tools_service_test.dart` is still present and still passes against the still-present `CodingToolsService` (deleted later in Task 17).

- [ ] **Step 10.2: Analyzer**

Run:
```bash
flutter analyze
```
Expected: no errors or warnings.

- [ ] **Step 10.3: Format**

Run:
```bash
dart format lib/ test/
```

### Task 11: Commit 2 — tools + registry

- [ ] **Step 11.1: Stage and commit**

Run:
```bash
git add \
  lib/services/coding_tools/tool_registry.dart \
  lib/services/coding_tools/tool_registry.g.dart \
  lib/services/coding_tools/tools/ \
  test/services/coding_tools/tool_registry_test.dart \
  test/services/coding_tools/tools/

git commit -m "$(cat <<'EOF'
feat(coding-tools): add ToolRegistry service and four Tool implementations

Additive commit 2/4 for tool registry refactor. Adds:
- ReadFileTool, ListDirTool, WriteFileTool, StrReplaceTool (each a
  first-class Tool with its own Riverpod provider and deps).
- ToolRegistry service: byName / byCapability / visibleTools /
  requiresPrompt / execute / register / unregister. Loads effective
  denylist once per execute call; wraps crash-catch + timing log
  (preserves old CodingToolsService.execute behavior).

The old CodingToolsService and CodingToolDefinition are still in place
and still exercised by agent_service and the old service_test — both
will be deleted in commits 3 and 4.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Part 3 — Wire AgentService through the registry

### Task 12: Migrate `AIRepository.streamMessageWithTools` signature

**Files:**
- Modify: `lib/data/ai/repository/ai_repository.dart:17-21`
- Modify: `lib/data/ai/repository/ai_repository_impl.dart:58-62`
- Modify: `lib/data/ai/datasource/custom_remote_datasource_dio.dart:149-153`

- [ ] **Step 12.1: Update the interface declaration**

In `lib/data/ai/repository/ai_repository.dart`:

Replace:
```dart
import '../../coding_tools/models/coding_tool_definition.dart';
```
with:
```dart
import '../../coding_tools/models/tool.dart';
```

Replace (lines 17-21):
```dart
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<CodingToolDefinition> tools,
    required AIModel model,
  });
```
with:
```dart
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<Tool> tools,
    required AIModel model,
  });
```

- [ ] **Step 12.2: Update the impl**

In `lib/data/ai/repository/ai_repository_impl.dart`:

Replace the `CodingToolDefinition` import with `Tool`, and update the parameter type on lines 58-62 identically (`List<CodingToolDefinition>` → `List<Tool>`). The method body is unchanged — it forwards to the datasource.

- [ ] **Step 12.3: Update the datasource**

In `lib/data/ai/datasource/custom_remote_datasource_dio.dart`:

Replace the `CodingToolDefinition` import with `Tool`, and update the parameter type on lines 149-153. The body at `:158` (`tools.map((t) => t.toOpenAiToolJson())`) is unchanged — polymorphic dispatch on the `Tool` interface.

- [ ] **Step 12.4: Confirm compilation**

Run: `flutter analyze lib/data/ai/`
Expected: no errors. (AgentService will break next — that's Task 13.)

### Task 13: Route `AgentService` through `ToolRegistry`

**Files:**
- Modify: `lib/services/agent/agent_service.dart` (provider dep, constructor, lines 115, 205, 222-228)

- [ ] **Step 13.1: Update the Riverpod provider body**

In `lib/services/agent/agent_service.dart`, replace the imports that reference `coding_tool_definition.dart` and `coding_tools_service.dart` with:
```dart
import '../../data/coding_tools/models/tool.dart';
import '../coding_tools/tool_registry.dart';
```
(Also remove the `export 'agent_exceptions.dart';` if it references CodingToolsService types — it doesn't, but verify.)

Replace the provider body at lines 42-52:
```dart
@Riverpod(keepAlive: true)
Future<AgentService> agentService(Ref ref) async {
  final ai = await ref.watch(aiRepositoryProvider.future);
  final registry = ref.read(toolRegistryProvider);
  return AgentService(
    ai: ai,
    registry: registry,
    cancelFlag: () => ref.read(agentCancelProvider),
    requestPermission: (req) => ref.read(agentPermissionRequestProvider.notifier).request(req),
  );
}
```

- [ ] **Step 13.2: Update the constructor**

Replace the constructor block at lines 58-68:
```dart
AgentService({
  required AIRepository ai,
  required ToolRegistry registry,
  required bool Function() cancelFlag,
  Future<bool> Function(PermissionRequest req)? requestPermission,
  String Function()? idGen,
}) : _ai = ai,
     _registry = registry,
     _cancelFlag = cancelFlag,
     _requestPermission = requestPermission ?? ((_) async => true),
     _idGen = idGen ?? (() => const Uuid().v4());

final AIRepository _ai;
final ToolRegistry _registry;
final bool Function() _cancelFlag;
final Future<bool> Function(PermissionRequest req) _requestPermission;
final String Function() _idGen;
```

(Drops the `_tools` field entirely; adds `_registry`.)

- [ ] **Step 13.3: Replace the tool-selection line (was :115)**

Replace:
```dart
final tools = permission == ChatPermission.readOnly ? CodingTools.readOnly : CodingTools.all;
```
with:
```dart
final tools = _registry.visibleTools(permission);
```

- [ ] **Step 13.4: Replace the destructive-check block (was :205-220)**

Replace:
```dart
final isDestructive = call.name == 'write_file' || call.name == 'str_replace';
if (permission == ChatPermission.askBefore && isDestructive) {
  final summary = _summaryFor(call);
  final req = PermissionRequest(...);
  ...
}
```
with:
```dart
final tool = _registry.byName(call.name);
if (tool != null && _registry.requiresPrompt(tool, permission)) {
  final summary = _summaryFor(call);
  final req = PermissionRequest(
    toolEventId: call.id,
    toolName: call.name,
    summary: summary,
    input: call.args,
  );
  yield snapshot(streaming: true).copyWith(pendingPermissionRequest: req);
  final approved = await _requestPermission(req);
  yield snapshot(streaming: true); // clear pendingPermissionRequest
  if (!approved) {
    final idx = events.indexWhere((e) => e.id == call.id);
    if (idx >= 0) {
      events[idx] = events[idx].copyWith(status: ToolStatus.cancelled, error: 'Denied by user');
    }
    yield snapshot(streaming: true);
    continue;
  }
}
```

- [ ] **Step 13.5: Replace the dispatch call (was :222-228)**

Replace:
```dart
final result = await _tools.execute(
  toolName: call.name,
  args: call.args,
  projectPath: projectPath,
  sessionId: sessionId,
  messageId: assistantId,
);
```
with:
```dart
final result = await _registry.execute(
  name: call.name,
  args: call.args,
  projectPath: projectPath,
  sessionId: sessionId,
  messageId: assistantId,
);
```

- [ ] **Step 13.6: Regenerate the Riverpod part file**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 13.7: Compile-check**

Run: `flutter analyze lib/services/agent/`
Expected: no errors. If any, fix imports/typos.

### Task 14: Update `agent_service_test.dart` fakes

**Files:**
- Modify: `test/services/agent/agent_service_test.dart`

- [ ] **Step 14.1: Swap CodingToolsService setup for a ToolRegistry**

Replace the imports of `coding_tool_definition.dart` and `coding_tools_service.dart` with:
```dart
import 'package:code_bench_app/data/coding_tools/models/tool.dart';
import 'package:code_bench_app/services/coding_tools/tool_registry.dart';
import 'package:code_bench_app/services/coding_tools/tools/list_dir_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/read_file_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/str_replace_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/write_file_tool.dart';
```

Replace the `late CodingToolsService toolsSvc;` declaration with:
```dart
late ToolRegistry registry;
```

Replace the `setUp` block that builds `toolsSvc` with:
```dart
setUp(() async {
  projectDir = await Directory.systemTemp.createTemp('agent_svc_');
  File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('hello');
  final repo = CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
  final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
  final applySvc = ApplyService(repo: applyRepo);
  registry = ToolRegistry(
    builtIns: [
      ReadFileTool(repo: repo),
      ListDirTool(repo: repo),
      WriteFileTool(applyService: applySvc),
      StrReplaceTool(repo: repo, applyService: applySvc),
    ],
    denylistRepo: _FakeDenylistRepository(),
  );
});
```

- [ ] **Step 14.2: Update every `AgentService(...)` construction**

Find each `AgentService(ai: ..., codingTools: toolsSvc, ...)` in the test file. Replace `codingTools: toolsSvc` with `registry: registry`. Do this for all four existing test bodies.

- [ ] **Step 14.3: Update the `_FakeAIRepo`, `_WireCapturingFakeRepo`, `_CapturingFakeRepo` signatures**

Each class overrides `streamMessageWithTools`. Change the `tools` parameter type from `List<CodingToolDefinition>` to `List<Tool>` in all three fakes (lines 45, 296, 311 in the original file). The `_CapturingFakeRepo.onSend` callback becomes `void Function(List<Tool>)`.

- [ ] **Step 14.4: Update the `readOnly mode filters write tools` assertion**

The test at `:239` reads `sentTools!.map((t) => t.name).toList()`. That assertion still works — the `name` getter is on `Tool`. No change needed to the assertion itself. Just verify the test still compiles and passes.

- [ ] **Step 14.5: Run the agent service tests**

Run:
```bash
flutter test test/services/agent/agent_service_test.dart
```
Expected: all 5 tests pass. If the `readOnly mode` test fails because `sentTools` is empty, verify that `registry.visibleTools(ChatPermission.readOnly)` is being called in `AgentService` (Step 13.3) and that `tools.map(...).toList()` is passed to the AI repo.

### Task 15: Full regression

- [ ] **Step 15.1: Full test suite**

Run: `flutter test`
Expected: all tests pass. The old `coding_tools_service_test.dart` still passes against the still-present `CodingToolsService`.

- [ ] **Step 15.2: Analyzer**

Run: `flutter analyze`
Expected: no errors or warnings.

- [ ] **Step 15.3: Format**

Run: `dart format lib/ test/`

### Task 16: Commit 3 — AgentService migration

- [ ] **Step 16.1: Stage and commit**

Run:
```bash
git add \
  lib/data/ai/repository/ai_repository.dart \
  lib/data/ai/repository/ai_repository_impl.dart \
  lib/data/ai/datasource/custom_remote_datasource_dio.dart \
  lib/services/agent/agent_service.dart \
  lib/services/agent/agent_service.g.dart \
  test/services/agent/agent_service_test.dart

git commit -m "$(cat <<'EOF'
refactor(agent): route AgentService through ToolRegistry

Commit 3/4 for tool registry refactor. Changes:
- AIRepository.streamMessageWithTools: tools parameter typed as
  List<Tool> instead of List<CodingToolDefinition>. Ripples to impl +
  datasource; tools.map(t => t.toOpenAiToolJson()) works polymorphically
  on the new interface.
- AgentService: receives ToolRegistry (not CodingToolsService). Three
  call sites migrate:
  * tool selection: registry.visibleTools(permission) replaces
    hardcoded CodingTools.readOnly/.all split.
  * destructive check: registry.requiresPrompt(tool, permission)
    replaces hardcoded 'write_file' | 'str_replace' string check.
  * dispatch: registry.execute(name: ...) replaces
    codingTools.execute(toolName: ...).
- AgentService tests: fakes swap CodingToolDefinition for Tool; setUp
  builds a real ToolRegistry instead of CodingToolsService.

CodingToolsService and CodingToolDefinition are still on disk but no
longer referenced by production code. Removal follows in commit 4.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Part 4 — Remove the old service

### Task 17: Delete `CodingToolsService`, `CodingToolDefinition`, and the legacy test

**Files:**
- Delete: `lib/services/coding_tools/coding_tools_service.dart`
- Delete: `lib/services/coding_tools/coding_tools_service.g.dart`
- Delete: `lib/data/coding_tools/models/coding_tool_definition.dart`
- Delete: `test/services/coding_tools/coding_tools_service_test.dart`

- [ ] **Step 17.1: Remove the files**

Run:
```bash
git rm \
  lib/services/coding_tools/coding_tools_service.dart \
  lib/services/coding_tools/coding_tools_service.g.dart \
  lib/data/coding_tools/models/coding_tool_definition.dart \
  test/services/coding_tools/coding_tools_service_test.dart
```

- [ ] **Step 17.2: Verify no dangling imports**

Run:
```bash
flutter analyze
```
Expected: no errors. If any file still references `CodingToolsService` or `CodingToolDefinition`, the import will fail — grep for the missing symbol and update or remove it.

Sanity grep (should return no matches — Task 13 migrated them all):
```bash
grep -rn "CodingToolsService" lib/ test/
grep -rn "CodingToolDefinition" lib/ test/
grep -rn "CodingTools\." lib/ test/
```

- [ ] **Step 17.3: Run the full suite**

Run: `flutter test`
Expected: all tests pass. Count: 14 of the assertions from the deleted `coding_tools_service_test.dart` now live in the six new test files created in Tasks 2, 5-9.

### Task 18: Final verification

- [ ] **Step 18.1: Analyzer**

Run: `flutter analyze`
Expected: no errors or warnings.

- [ ] **Step 18.2: Full test suite**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 18.3: Format**

Run: `dart format lib/ test/`

- [ ] **Step 18.4: Verify the MVP works end-to-end**

Run the macOS app and exercise each of the four tools through a chat session:
```bash
flutter run -d macos
```
Checklist (perform each in the running app):
- [ ] Agent can `read_file` an existing file.
- [ ] Agent can `list_dir` a folder.
- [ ] Agent can `write_file` (triggers the permission prompt in `askBefore` mode).
- [ ] Agent can `str_replace` (triggers the permission prompt in `askBefore` mode).
- [ ] In `readOnly` mode, the agent is offered only `read_file` and `list_dir`.
- [ ] Denylisted paths (e.g. `.env`) are refused with the same user-facing message as before.

### Task 19: Commit 4 — deletions

- [ ] **Step 19.1: Stage and commit**

Run:
```bash
git add -u lib/ test/
git status  # sanity check — only deletions listed

git commit -m "$(cat <<'EOF'
refactor(coding-tools): remove CodingToolsService and CodingToolDefinition

Commit 4/4 for tool registry refactor. Deletes:
- lib/services/coding_tools/coding_tools_service.dart (+ .g.dart)
- lib/data/coding_tools/models/coding_tool_definition.dart
- test/services/coding_tools/coding_tools_service_test.dart

All behavior migrated:
- switch(toolName) dispatch -> ToolRegistry.execute
- per-handler path ritual -> ToolContext.safePath
- crash-catch + timing log -> ToolRegistry.execute wrapper
- CodingToolDefinition.toOpenAiToolJson -> Tool.toOpenAiToolJson
- 14 test assertions -> redistributed across 6 new test files

Refactor complete. No user-visible behavior change.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 19.2: Sanity-check the final tree**

Run:
```bash
git log --oneline -5
```
Expected: four new commits on top of the pre-refactor base — "feat(coding-tools): add Tool / ToolContext contracts...", "feat(coding-tools): add ToolRegistry service...", "refactor(agent): route AgentService...", "refactor(coding-tools): remove CodingToolsService...".

---

## Wrap-up

### Task 20: PR-readiness check

- [ ] **Step 20.1: Ensure branch is pushed**

Run:
```bash
git push -u origin tech/2026-04-21-tool-registry-refactor
```

- [ ] **Step 20.2: Open PR (ask the user for approval before running)**

Only after the user asks to open the PR. When asked, use the PR template in [CLAUDE.md](../../../CLAUDE.md):

Run (from the worktree):
```bash
gh pr create --title "refactor(coding-tools): extract ToolRegistry + polymorphic Tool interface" --body "$(cat <<'EOF'
## Summary

Phase 1 of the agentic-executor roadmap. Replaces the static
`CodingTools` catalog and `switch(toolName)` dispatch in
`CodingToolsService` with a polymorphic `Tool` interface, a `ToolContext`
that centralizes path-safety, and a `ToolRegistry` service. No
user-visible behavior change.

See the design spec: `docs/superpowers/specs/2026-04-21-tool-registry-refactor-design.md`.

## Changes

- Added `Tool` interface, `ToolCapability` enum, `ToolContext`, `PathResult`, `EffectiveDenylist` under `lib/data/coding_tools/models/`.
- Extracted four `Tool` classes: `ReadFileTool`, `ListDirTool`, `WriteFileTool`, `StrReplaceTool`.
- Added `ToolRegistry` service with `byName` / `byCapability` / `visibleTools` / `requiresPrompt` / `execute` / `register` / `unregister`.
- Migrated `AgentService` to route through the registry; `AIRepository.streamMessageWithTools` now takes `List<Tool>`.
- Deleted `CodingToolsService` and `CodingToolDefinition`.
- Redistributed 14 test assertions from the deleted service test file into 6 new per-tool and registry test files.

## Type of change

- [ ] Bug fix
- [ ] New feature
- [x] Refactor / internal improvement
- [ ] Documentation

## Checklist

- [x] `flutter analyze` passes with no issues
- [x] `dart format lib/` applied
- [x] `flutter test` passes
- [x] `build_runner` re-run; generated files committed alongside their source files
- [x] PR is focused on a single concern

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Appendix — Expected final file tree

```
lib/data/coding_tools/models/
  tool.dart                                (NEW)
  tool_capability.dart                     (NEW)
  tool_context.dart                        (NEW)
  path_result.dart                         (NEW)
  effective_denylist.dart                  (NEW)
  coding_tool_result.dart                  (unchanged)
  coding_tool_call.dart                    (unchanged)
  coding_tools_denylist_state.dart         (unchanged)
  denylist_category.dart                   (unchanged)
  denylist_defaults.dart                   (unchanged)
  # coding_tool_definition.dart (DELETED)

lib/services/coding_tools/
  tool_registry.dart                       (NEW)
  tool_registry.g.dart                     (NEW — generated)
  coding_tools_denylist_service.dart       (unchanged)
  coding_tools_denylist_service.g.dart     (unchanged)
  tools/
    read_file_tool.dart                    (NEW)
    read_file_tool.g.dart                  (NEW — generated)
    list_dir_tool.dart                     (NEW)
    list_dir_tool.g.dart                   (NEW — generated)
    write_file_tool.dart                   (NEW)
    write_file_tool.g.dart                 (NEW — generated)
    str_replace_tool.dart                  (NEW)
    str_replace_tool.g.dart                (NEW — generated)
  # coding_tools_service.dart (DELETED)
  # coding_tools_service.g.dart (DELETED)

lib/services/agent/
  agent_service.dart                       (CHANGED — constructor, 3 call sites)
  agent_service.g.dart                     (regenerated)

lib/data/ai/repository/
  ai_repository.dart                       (CHANGED — tools parameter type)
  ai_repository_impl.dart                  (CHANGED — tools parameter type)

lib/data/ai/datasource/
  custom_remote_datasource_dio.dart        (CHANGED — tools parameter type)

test/data/coding_tools/models/
  tool_context_test.dart                   (NEW)

test/services/coding_tools/
  tool_registry_test.dart                  (NEW)
  _helpers/
    tool_test_helpers.dart                 (NEW)
  tools/
    read_file_tool_test.dart               (NEW)
    list_dir_tool_test.dart                (NEW)
    write_file_tool_test.dart              (NEW)
    str_replace_tool_test.dart             (NEW)
  # coding_tools_service_test.dart (DELETED)

test/services/agent/
  agent_service_test.dart                  (CHANGED — fakes swapped to Tool / ToolRegistry)
```
