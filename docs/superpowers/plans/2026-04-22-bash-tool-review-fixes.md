# Bash Tool — Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all nine issues identified in the post-implementation security, code-quality, and silent-failure review of the Phase 4 bash tool.

**Architecture:** Fixes are grouped bottom-up: datasource layer first (interface split, error handling, output cap), then tool/registry policy (permission gate, summary type guard), then UI trust layer (command sanitization, denylist caveat). Each group produces a standalone commit.

**Tech Stack:** Dart 3, Flutter, Riverpod generator, `dart:io` Process API.

---

## Issue index

| ID | Severity | Short description |
|----|----------|-------------------|
| CODE-2 | Low | `BashDatasource` class name should be `BashDatasourceProcess` (interface/impl split) |
| SF-1 | High | `IOException`/`OSError` from `Process.start` not caught — surfaces as opaque error |
| SF-2 | High | No output cap on `outputBuf` — unbounded memory growth possible |
| SF-3 | Medium | `catch (_)` swallows UTF-8 errors and drain `TimeoutException` |
| SF-4 | Low | `process.kill()` uses SIGTERM (can be ignored); orphan children undocumented |
| SEC-1 | Critical | `fullAccess` mode bypasses permission gate for bash |
| CODE-1 | Medium | Non-String `command` in `_summaryFor` silently falls back with no logging |
| SEC-2 | Critical | Denylist is never consulted for bash commands — bypass not surfaced to user |
| SEC-3 | Medium | ANSI/bidi chars in permission card command display — approval spoofing risk |

---

## File map

| File | Change |
|------|--------|
| `lib/data/bash/datasource/bash_datasource_process.dart` | CODE-2, SF-1, SF-2, SF-3, SF-4 |
| `lib/services/coding_tools/tools/bash_tool.dart` | CODE-2 (provider), SF-1 (IOException catch) |
| `test/data/bash/datasource/bash_datasource_process_test.dart` | CODE-2 rename, SF-2 cap test |
| `test/services/coding_tools/tools/bash_tool_test.dart` | CODE-2 rename |
| `lib/services/coding_tools/tool_registry.dart` | SEC-1 |
| `test/services/coding_tools/tool_registry_test.dart` | SEC-1 new tests |
| `lib/services/agent/agent_service.dart` | CODE-1 |
| `lib/features/chat/widgets/permission_request_card.dart` | SEC-2, SEC-3 |

---

## Task 1: CODE-2 — Split BashDatasource into abstract interface + concrete impl

**Files:**
- Modify: `lib/data/bash/datasource/bash_datasource_process.dart`
- Modify: `lib/services/coding_tools/tools/bash_tool.dart`
- Modify: `test/data/bash/datasource/bash_datasource_process_test.dart`
- Modify: `test/services/coding_tools/tools/bash_tool_test.dart`

- [ ] **Step 1: Update datasource file**

Replace the entire contents of `lib/data/bash/datasource/bash_datasource_process.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';

typedef BashResult = ({int exitCode, String output, bool timedOut});

abstract class BashDatasource {
  Future<BashResult> run({required String command, required String workingDirectory});
}

class BashDatasourceProcess implements BashDatasource {
  BashDatasourceProcess({this.timeout = const Duration(seconds: 120)});
  final Duration timeout;

  @override
  Future<BashResult> run({required String command, required String workingDirectory}) async {
    late final Process process;
    try {
      process = await Process.start('/bin/sh', ['-c', command], workingDirectory: workingDirectory);
    } on ProcessException catch (e) {
      dLog('[BashDatasource] Process.start failed (ProcessException): $e');
      rethrow;
    }

    final outputBuf = StringBuffer();
    final stdoutFuture = process.stdout.transform(utf8.decoder).forEach(outputBuf.write);
    final stderrFuture = process.stderr.transform(utf8.decoder).forEach(outputBuf.write);

    late int exitCode;
    late bool timedOut;
    try {
      exitCode = await process.exitCode.timeout(timeout);
      timedOut = false;
    } on TimeoutException {
      process.kill();
      exitCode = -1;
      timedOut = true;
    }

    try {
      await Future.wait([stdoutFuture, stderrFuture]).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Streams may already be closed after process.kill(); drain errors are benign.
    }

    return (exitCode: exitCode, output: outputBuf.toString(), timedOut: timedOut);
  }
}
```

- [ ] **Step 2: Update provider in bash_tool.dart to instantiate BashDatasourceProcess**

In `lib/services/coding_tools/tools/bash_tool.dart`, change line 15:

```dart
// Before:
@riverpod
BashTool bashTool(Ref ref) => BashTool(datasource: BashDatasource());

// After:
@riverpod
BashTool bashTool(Ref ref) => BashTool(datasource: BashDatasourceProcess());
```

The `BashTool` field `final BashDatasource datasource;` and its constructor parameter already reference `BashDatasource` — now the abstract interface — so no further change is needed there.

- [ ] **Step 3: Update datasource test to use BashDatasourceProcess**

In `test/data/bash/datasource/bash_datasource_process_test.dart`, replace `BashDatasource()` with `BashDatasourceProcess()` (4 occurrences):

```dart
// Before:
final ds = BashDatasource();
final ds = BashDatasource(timeout: const Duration(seconds: 1));

// After:
final ds = BashDatasourceProcess();
final ds = BashDatasourceProcess(timeout: const Duration(seconds: 1));
```

- [ ] **Step 4: Verify tool test still compiles**

`_FakeDatasource extends BashDatasource` in the tool test already extends the interface name — no change needed. Run:

```bash
flutter test test/services/coding_tools/tools/bash_tool_test.dart test/data/bash/datasource/bash_datasource_process_test.dart
```

Expected: all 8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/bash/datasource/bash_datasource_process.dart \
        lib/services/coding_tools/tools/bash_tool.dart \
        test/data/bash/datasource/bash_datasource_process_test.dart
git commit -m "refactor(bash): split BashDatasource into abstract interface + BashDatasourceProcess impl"
```

---

## Task 2: SF-1/SF-2/SF-3/SF-4 — Datasource hardening

**Files:**
- Modify: `lib/data/bash/datasource/bash_datasource_process.dart`
- Modify: `test/data/bash/datasource/bash_datasource_process_test.dart`
- Modify: `lib/services/coding_tools/tools/bash_tool.dart`
- Modify: `test/services/coding_tools/tools/bash_tool_test.dart`

- [ ] **Step 1: Write failing tests for new behaviors**

Add to `test/data/bash/datasource/bash_datasource_process_test.dart`:

```dart
test('caps output at 50 KB and appends sentinel', () async {
  final ds = BashDatasourceProcess();
  // Generate ~100 KB of output (each iteration ~1 KB)
  final result = await ds.run(
    command: r"python3 -c \"print('x' * 1000)\" for i in {1..120}; do python3 -c \"print('x' * 1000)\"; done",
    workingDirectory: '/tmp',
  );
  expect(result.output.length, lessThan(55 * 1024));
  expect(result.output, contains('[Output capped'));
});
```

Actually, let's use a simpler command that reliably generates >50 KB:

```dart
test('caps output at 50 KB and appends sentinel', () async {
  final ds = BashDatasourceProcess();
  // ~1 KB per iteration × 60 iterations = ~60 KB
  final result = await ds.run(
    command: 'for i in \$(seq 1 60); do printf "%1000s\\n"; done',
    workingDirectory: '/tmp',
  );
  expect(result.timedOut, isFalse);
  expect(result.output, contains('[Output capped'));
});
```

Run to confirm it fails:

```bash
flutter test test/data/bash/datasource/bash_datasource_process_test.dart
```

Expected: last test fails.

- [ ] **Step 2: Rewrite BashDatasourceProcess.run with all four hardening changes**

Replace the full contents of `lib/data/bash/datasource/bash_datasource_process.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';

typedef BashResult = ({int exitCode, String output, bool timedOut});

const int _kOutputCapBytes = 50 * 1024;

abstract class BashDatasource {
  Future<BashResult> run({required String command, required String workingDirectory});
}

class BashDatasourceProcess implements BashDatasource {
  BashDatasourceProcess({this.timeout = const Duration(seconds: 120)});
  final Duration timeout;

  @override
  Future<BashResult> run({required String command, required String workingDirectory}) async {
    late final Process process;
    try {
      process = await Process.start('/bin/sh', ['-c', command], workingDirectory: workingDirectory);
    } on ProcessException catch (e) {
      // SF-1: also catches ProcessException specifically for message access
      dLog('[BashDatasource] Process.start failed (ProcessException): $e');
      rethrow;
    } on IOException catch (e) {
      // SF-1: OSError / missing workingDirectory falls here
      dLog('[BashDatasource] Process.start failed (IOException): $e');
      rethrow;
    }

    final outputBuf = StringBuffer();
    var totalBytes = 0;
    var outputCapped = false;

    // SF-2: cap collected output to avoid unbounded memory growth
    void write(String chunk) {
      if (outputCapped) return;
      final chunkBytes = utf8.encode(chunk).length;
      if (totalBytes + chunkBytes > _kOutputCapBytes) {
        outputBuf.write('\n[Output capped at ${_kOutputCapBytes ~/ 1024} KB]');
        outputCapped = true;
        return;
      }
      outputBuf.write(chunk);
      totalBytes += chunkBytes;
    }

    final stdoutFuture = process.stdout.transform(utf8.decoder).forEach(write);
    final stderrFuture = process.stderr.transform(utf8.decoder).forEach(write);

    late int exitCode;
    late bool timedOut;
    try {
      exitCode = await process.exitCode.timeout(timeout);
      timedOut = false;
    } on TimeoutException {
      // SF-4: SIGKILL cannot be caught or ignored by the shell process.
      // Known limitation: child processes in a separate process group may persist as orphans.
      process.kill(ProcessSignal.sigkill);
      dLog('[BashDatasource] command timed out; shell killed. Child processes in separate groups may persist.');
      exitCode = -1;
      timedOut = true;
    }

    // SF-3: distinguish benign drain close from UTF-8/timeout errors
    try {
      await Future.wait([stdoutFuture, stderrFuture]).timeout(const Duration(seconds: 5));
    } on TimeoutException {
      dLog('[BashDatasource] stdout/stderr drain timed out — output may be incomplete');
      outputBuf.write('\n[Warning: output stream drain timed out; output may be incomplete]');
    } catch (e) {
      dLog('[BashDatasource] stream drain error: ${e.runtimeType} $e');
      outputBuf.write('\n[Warning: output stream error (${e.runtimeType}); output may be incomplete]');
    }

    return (exitCode: exitCode, output: outputBuf.toString(), timedOut: timedOut);
  }
}
```

- [ ] **Step 3: Catch IOException in BashTool.execute**

In `lib/services/coding_tools/tools/bash_tool.dart`, extend the catch block (lines 56-59):

```dart
// Before:
    } on ProcessException catch (e) {
      dLog('[BashTool] ProcessException: $e');
      return CodingToolResult.error('bash failed to start: ${e.message}');
    }

// After:
    } on ProcessException catch (e) {
      dLog('[BashTool] ProcessException: $e');
      return CodingToolResult.error('bash failed to start: ${e.message}');
    } on IOException catch (e) {
      dLog('[BashTool] IOException: $e');
      return CodingToolResult.error('bash failed to start: $e');
    }
```

- [ ] **Step 4: Add IOException test to bash_tool_test.dart**

Add after the existing `'returns success with Timed out header on timeout'` test:

```dart
test('returns error when datasource throws IOException', () async {
  final tool = BashTool(datasource: _ThrowingDatasource());
  final result = await tool.execute(fakeCtx(projectPath: '/tmp', args: {'command': 'echo hi'}));
  expect(result, isA<CodingToolResultError>());
});
```

And add the throwing fake above `main()`:

```dart
class _ThrowingDatasource extends BashDatasource {
  @override
  Future<BashResult> run({required String command, required String workingDirectory}) async {
    throw const FileSystemException('no such directory', '/nonexistent');
  }
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/data/bash/datasource/bash_datasource_process_test.dart test/services/coding_tools/tools/bash_tool_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/data/bash/datasource/bash_datasource_process.dart \
        lib/services/coding_tools/tools/bash_tool.dart \
        test/data/bash/datasource/bash_datasource_process_test.dart \
        test/services/coding_tools/tools/bash_tool_test.dart
git commit -m "fix(bash): datasource hardening — IOException, output cap, drain split, SIGKILL"
```

---

## Task 3: SEC-1 — Always gate shell-capability tools

**Files:**
- Modify: `lib/services/coding_tools/tool_registry.dart`
- Modify: `test/services/coding_tools/tool_registry_test.dart`

- [ ] **Step 1: Write failing test first**

Add a `_FakeShellTool` class above `main()` in `test/services/coding_tools/tool_registry_test.dart`:

```dart
class _FakeShellTool implements Tool {
  @override
  String get name => 'fake_shell';
  @override
  ToolCapability get capability => ToolCapability.shell;
  @override
  String get description => 'test shell tool';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  Map<String, dynamic> toOpenAiToolJson() => const {};
  @override
  Future<CodingToolResult> execute(ToolContext ctx) async => CodingToolResult.success('');
}
```

Add a new group at the end of `main()` in the `requiresPrompt` group:

```dart
test('shell tool always requires prompt under every ChatPermission', () {
  final r = _newRegistry(projectDir: projectDir);
  r.register(_FakeShellTool());
  final t = r.byName('fake_shell')!;
  for (final p in ChatPermission.values) {
    expect(r.requiresPrompt(t, p), isTrue, reason: 'expected prompt for $p');
  }
});
```

Run to confirm it fails:

```bash
flutter test test/services/coding_tools/tool_registry_test.dart
```

Expected: new test fails.

- [ ] **Step 2: Fix requiresPrompt in tool_registry.dart**

In `lib/services/coding_tools/tool_registry.dart`, replace lines 68-69:

```dart
// Before:
  bool requiresPrompt(Tool t, ChatPermission p) =>
      p == ChatPermission.askBefore && t.capability != ToolCapability.readOnly;

// After:
  bool requiresPrompt(Tool t, ChatPermission p) {
    if (t.capability == ToolCapability.shell) return true;
    return p == ChatPermission.askBefore && t.capability != ToolCapability.readOnly;
  }
```

- [ ] **Step 3: Run tests**

```bash
flutter test test/services/coding_tools/tool_registry_test.dart
```

Expected: all tests pass (the existing `'fullAccess never prompts'` test only iterates over `_newRegistry`'s tools which have no shell tools, so it is unaffected).

- [ ] **Step 4: Commit**

```bash
git add lib/services/coding_tools/tool_registry.dart \
        test/services/coding_tools/tool_registry_test.dart
git commit -m "fix(bash/sec): shell-capability tools always require user prompt regardless of permission mode"
```

---

## Task 4: CODE-1 — Fix _summaryFor type guard

**Files:**
- Modify: `lib/services/agent/agent_service.dart`

- [ ] **Step 1: Fix the bash branch in _summaryFor (lines 308-311)**

```dart
// Before:
    if (call.name == 'bash') {
      final cmd = call.args['command'] ?? '';
      return cmd is String && cmd.length > 80 ? '${cmd.substring(0, 80)}…' : cmd.toString();
    }

// After:
    if (call.name == 'bash') {
      final raw = call.args['command'];
      if (raw is! String) {
        dLog('[AgentService] bash command arg is ${raw.runtimeType}, expected String');
        return '<invalid bash command>';
      }
      return raw.length > 80 ? '${raw.substring(0, 80)}…' : raw;
    }
```

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/services/agent/agent_service.dart
git commit -m "fix(bash): type-safe _summaryFor — log and return sentinel for non-String command arg"
```

---

## Task 5: SEC-2/SEC-3 — Permission card: sanitize command + denylist caveat

**Files:**
- Modify: `lib/features/chat/widgets/permission_request_card.dart`

- [ ] **Step 1: Add the _sanitizeCommand helper and apply it in _buildPreviewLines**

In `_PermissionRequestCardState`, add the private static helper method before `_buildPreviewLines`:

```dart
static String _sanitizeCommand(String command) {
  // Strip ANSI escape sequences (e.g. \x1b[31m)
  var s = command.replaceAll(RegExp(r'\x1b\[[0-9;]*[A-Za-z]'), '');
  // Strip Unicode bidi override / directional marks that can reverse displayed text
  s = s.replaceAll(RegExp(r'[‪-‮⁦-⁩‏؜]'), '');
  // Strip other non-printable control characters except \n and \t
  s = s.replaceAll(RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]'), '');
  return s;
}
```

In `_buildPreviewLines`, update the bash branch to sanitize:

```dart
// Before:
    if (req.toolName == 'bash') {
      final command = req.input['command'];
      if (command is! String || command.isEmpty) return null;
      return [command];
    }

// After:
    if (req.toolName == 'bash') {
      final command = req.input['command'];
      if (command is! String || command.isEmpty) return null;
      return [_sanitizeCommand(command)];
    }
```

- [ ] **Step 2: Add denylist caveat note below the bash code block**

In the `build` method, find the bash command block section (lines 119-135 in the existing file) and add the caveat:

```dart
          // bash: always-visible command code block
          if (widget.request.toolName == 'bash' && previewLines != null) ...[
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
            const SizedBox(height: 4),
            Text(
              'Denylist rules do not restrict bash commands.',
              style: TextStyle(color: c.textMuted, fontSize: 10),
            ),
          ],
```

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/widgets/permission_request_card.dart
git commit -m "fix(bash/sec): sanitize ANSI/bidi chars in command preview; add denylist bypass notice"
```

---

## Task 6: Format, analyze, full test run

- [ ] **Step 1: Format**

```bash
dart format lib/ test/
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 3: Full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Final commit if format made changes**

```bash
git add -u
git commit -m "style: dart format after review fixes"
```
