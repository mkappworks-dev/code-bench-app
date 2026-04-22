# Bash Tool (Permission-Gated) — Design Spec

**Date:** 2026-04-22
**Phase:** 4 (Agentic Executor Roadmap)
**Status:** Approved — ready for implementation planning

---

## Goal

Give the AI agent the ability to execute shell commands inside the active project, with mandatory user approval before every execution. Every call is gated, every result is bounded by the Phase 3 50 KB cap.

---

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Shell mode | `/bin/sh -c <command>` (`runInShell: false` on `Process.start`) | We are the shell layer. Dart's `runInShell` adds a redundant wrapper. The CLAUDE.md ban targets services constructing commands from external user data — not this case. |
| Working directory | Locked to `ctx.projectPath` | Same pattern as all other tools. No `cwd` parameter. Model uses `cd subdir && …` inline if needed. |
| `cwd` argument | None | YAGNI — the model can prefix `cd` inline. Adds permission card complexity for zero gain. |
| Denylist on command | Not applied | Permission gate is the real guard. Substring scan would produce false positives on legitimate commands (e.g. `echo "check .env vars"`). |
| Output format | `Exit N\n\n<stdout+stderr merged>` | Mirrors a terminal. Model reads exit code from first line; interleaved streams give full context for self-correction. |
| Timeout | 120 seconds, fixed | Covers `flutter build`, `flutter test`, long dev commands. Non-configurable — no identified workflow needs more. |
| Timeout output | `Timed out after 120 s\n\n<partial output>` | Partial output may still contain useful context. |
| Architecture | Datasource-direct (no repository layer) | One backend, no fallback. Repository interface would be an empty abstraction. |
| `ToolCapability` | `shell` | Already declared in enum. Automatically non-parallelizable and triggers permission prompt in `askBefore` mode. |
| Permission card | Bash-specific: always-visible code block, no collapse toggle | User must read the command before approving. Code block (monospace, `codeBlockBg`) makes it visually distinct from prose. |
| CLAUDE.md update | Required | Narrow `runInShell: true` restriction; document `bash_datasource_process.dart` as approved exception alongside `ApplyRepository.assertWithinProject`. |

---

## Architecture

### Files

| Action | File | Purpose |
|---|---|---|
| Create | `lib/data/bash/datasource/bash_datasource_process.dart` | `Process.start`, stdout+stderr merge, 120 s timeout, exit code |
| Create | `lib/services/coding_tools/tools/bash_tool.dart` | `Tool` impl — schema, arg validation, datasource call, result format |
| Modify | `lib/features/chat/widgets/permission_request_card.dart` | Bash branch: always-visible command code block |
| Modify | `lib/services/agent/agent_service.dart` | `_summaryFor` — bash case returns truncated command string |
| Modify | `lib/services/coding_tools/tool_registry.dart` | Register `bashToolProvider` in `builtIns` |
| Modify | `CLAUDE.md` | Document `bash_datasource_process.dart` as `runInShell` exception |

No new models, no schema migrations, no generated code.

---

## BashDatasource

**File:** `lib/data/bash/datasource/bash_datasource_process.dart`

```dart
typedef BashResult = ({int exitCode, String output, bool timedOut});

class BashDatasource {
  BashDatasource({this.timeout = const Duration(seconds: 120)});
  final Duration timeout;

  Future<BashResult> run({
    required String command,
    required String workingDirectory,
  }) async {
    final process = await Process.start(
      '/bin/sh', ['-c', command],
      workingDirectory: workingDirectory,
      runInShell: false,
    );

    final outputBuf = StringBuffer();
    final stdoutSub = process.stdout.transform(utf8.decoder).listen(outputBuf.write);
    final stderrSub = process.stderr.transform(utf8.decoder).listen(outputBuf.write);

    final exitCode = await process.exitCode.timeout(
      timeout,
      onTimeout: () {
        process.kill();
        return -1;
      },
    );
    await Future.wait([stdoutSub.asFuture(), stderrSub.asFuture()]);

    return (exitCode: exitCode, output: outputBuf.toString(), timedOut: exitCode == -1);
  }
}
```

`stdout` and `stderr` are listened concurrently and written to a single `StringBuffer` — interleaved in arrival order, matching terminal behaviour. `BashResult` is an inline named record; no model file needed.

---

## BashTool

**File:** `lib/services/coding_tools/tools/bash_tool.dart`

```dart
@riverpod
BashTool bashTool(Ref ref) => BashTool(datasource: BashDatasource());

class BashTool extends Tool {
  BashTool({required this.datasource});
  final BashDatasource datasource;

  @override String get name => 'bash';
  @override ToolCapability get capability => ToolCapability.shell;

  @override
  String get description =>
      'Execute a shell command in the project root. '
      'stdout and stderr are returned together with the exit code.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'command': {
        'type': 'string',
        'description':
            'The shell command to run. Executed via /bin/sh -c. '
            'Working directory is the project root.',
      },
    },
    'required': ['command'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final command = ctx.args['command'];
    if (command is! String || command.trim().isEmpty) {
      return CodingToolResult.error('bash requires a non-empty "command" argument.');
    }
    try {
      final result = await datasource.run(
        command: command,
        workingDirectory: ctx.projectPath,
      );
      final header = result.timedOut
          ? 'Timed out after 120 s\n\n'
          : 'Exit ${result.exitCode}\n\n';
      return CodingToolResult.success('$header${result.output}');
    } on ProcessException catch (e) {
      dLog('[BashTool] ProcessException: $e');
      return CodingToolResult.error('bash failed to start: ${e.message}');
    }
  }
}
```

---

## Permission Card Extension

**File:** `lib/features/chat/widgets/permission_request_card.dart`

Add to `_buildPreviewLines()`:
```dart
if (req.toolName == 'bash') {
  final command = req.input['command'];
  if (command is! String || command.isEmpty) return null;
  return [command];
}
```

Add to `build()` alongside the existing `write_file`/`str_replace` toggle block:
```dart
// existing toggle — skip for bash
if (previewLines != null && req.toolName != 'bash') ...[
  // ... existing Show diff ▾ collapsible block unchanged
],

// bash: always-visible code block
if (req.toolName == 'bash' && previewLines != null) ...[
  const SizedBox(height: 6),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: c.codeBlockBg,
      border: Border.all(color: c.subtleBorder),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      previewLines.first,
      style: TextStyle(color: c.textPrimary, fontSize: 11, fontFamily: 'monospace'),
    ),
  ),
],
```

---

## AgentService — `_summaryFor`

**File:** `lib/services/agent/agent_service.dart`

Add alongside the existing `write_file` and `str_replace` cases:
```dart
if (call.name == 'bash') {
  final cmd = call.args['command'] ?? '';
  return cmd is String && cmd.length > 80
      ? '${cmd.substring(0, 80)}…'
      : cmd.toString();
}
```

---

## ToolRegistry Registration

**File:** `lib/services/coding_tools/tool_registry.dart`

```dart
builtIns: [
  ref.watch(readFileToolProvider),
  ref.watch(listDirToolProvider),
  ref.watch(writeFileToolProvider),
  ref.watch(strReplaceToolProvider),
  ref.watch(grepToolProvider),
  ref.watch(globToolProvider),
  ref.watch(bashToolProvider), // Phase 4
],
```

---

## CLAUDE.md Update

In the macOS notes section, after the `ApplyRepository.assertWithinProject` exception, add:

> `bash_datasource_process.dart` is a second documented exception. It spawns `/bin/sh -c <command>` where the command is AI-generated and user-approved before execution — the injection risk the ban targets does not apply here. The CLAUDE.md restriction on `runInShell: true` continues to apply to all other services.

---

## Testing

### `test/data/bash/datasource/bash_datasource_process_test.dart`

Four integration cases hitting a real shell (no mocking):

| Case | Command | Expected |
|---|---|---|
| stdout captured | `echo hello` | output contains `hello`, exitCode 0 |
| stderr captured | `echo err >&2` | output contains `err`, exitCode 0 |
| non-zero exit | `exit 42` | exitCode 42, timedOut false |
| timeout kill | `sleep 200` (1 s cap override) | timedOut true |

Timeout test passes `timeout: Duration(seconds: 1)` to the `BashDatasource` constructor — no subclass needed.

### `test/services/coding_tools/tools/bash_tool_test.dart`

Three pure unit cases using a fake datasource (inline class, no Mockito):

| Case | Input | Expected |
|---|---|---|
| Missing `command` | `{}` | `CodingToolResult.error(...)` |
| Empty `command` | `{'command': ''}` | `CodingToolResult.error(...)` |
| Success | fake `(exitCode: 0, output: 'ok', timedOut: false)` | `CodingToolResult.success('Exit 0\n\nok')` |

---

## What This Does NOT Change

- `ToolCapability` enum (already has `shell`)
- `ToolEvent` model and Drift schema
- `AgentService` parallel execution logic (`shell` capability is automatically non-parallelizable)
- `CodingToolResult` model
- Any existing tool implementations
- Permission gate flow (bash uses the existing `requiresPrompt` path)
