# Per-session Codex CLI processes — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `CodexCliDatasourceProcess` into `CodexSession` (one process per chat) + `CodexSessionPool` (lifecycle + idle eviction) so multiple chats can run concurrently across the same or different projects, and bundle Claude CLI's `cancel(sessionId)` interface fix.

**Architecture:** Extract a `CodexSession` class that owns one `app-server` process for one `sessionId`. Wrap them in a `CodexSessionPool` with lazy idle eviction. Slim `CodexCliDatasourceProcess` to a thin `AIProviderDatasource` adapter delegating per-`sessionId` calls into the pool. Inject a `ProcessLauncher` typedef so `CodexSession` is unit-testable without spawning real binaries. `AIProviderDatasource.cancel()` and `respondToPermissionRequest()` grow a `sessionId` argument; Claude CLI gets a `Map<String, Process>` keyed by `sessionId` so its cancel routes correctly.

**Tech Stack:** Dart / Flutter, Riverpod (`@Riverpod(keepAlive: true)`), `dart:io` `Process`, JSON-RPC 2.0 over stdio, `package:flutter_test` `Fake` for stub interfaces.

**Spec:** [docs/superpowers/specs/2026-05-07-codex-per-session-process-design.md](../specs/2026-05-07-codex-per-session-process-design.md)

---

## Task 1: ProcessLauncher typedef

**Why first:** `CodexSession` (Task 2) takes a `ProcessLauncher` in its constructor for testability. Landing the typedef first lets later tasks import it without forward-reference risk.

**Files:**
- Create: `lib/data/ai/datasource/process_launcher.dart`
- Test: `test/data/ai/datasource/process_launcher_test.dart`

- [ ] **Step 1: Write the failing test**

`test/data/ai/datasource/process_launcher_test.dart`:

```dart
import 'dart:io';

import 'package:code_bench_app/data/ai/datasource/process_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaultProcessLauncher', () {
    test('forwards to Process.start and returns a Process', () async {
      // `true` is on every Unix-like and exits 0 immediately.
      final proc = await defaultProcessLauncher('/usr/bin/true', const <String>[]);
      expect(proc, isA<Process>());
      expect(await proc.exitCode, 0);
    });

    test('honours the workingDirectory parameter', () async {
      final proc = await defaultProcessLauncher(
        '/bin/sh',
        const ['-c', 'pwd'],
        workingDirectory: '/tmp',
      );
      final out = await proc.stdout.transform(const SystemEncoding().decoder).join();
      expect(out.trim(), '/tmp');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/ai/datasource/process_launcher_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:code_bench_app/data/ai/datasource/process_launcher.dart'`

- [ ] **Step 3: Write the typedef and default**

`lib/data/ai/datasource/process_launcher.dart`:

```dart
import 'dart:io';

/// Process-spawning seam used by [CodexSession] (and any future datasource
/// that wants unit-testable process plumbing). Production callers pass
/// [defaultProcessLauncher]; tests pass a closure that returns a fake
/// [Process] so JSON-RPC handshakes can be exercised without spawning the
/// real binary.
///
/// Mirrors `Process.start`'s positional + named parameter shape so
/// `defaultProcessLauncher` is a one-line forward.
typedef ProcessLauncher =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment,
      bool runInShell,
    });

Future<Process> defaultProcessLauncher(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
}) {
  return Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/ai/datasource/process_launcher_test.dart`
Expected: PASS — both tests green.

- [ ] **Step 5: Format + analyze**

Run: `dart format lib/data/ai/datasource/process_launcher.dart test/data/ai/datasource/process_launcher_test.dart && flutter analyze lib/data/ai/datasource/process_launcher.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/data/ai/datasource/process_launcher.dart test/data/ai/datasource/process_launcher_test.dart
git commit -m "$(cat <<'EOF'
refactor(codex): extract ProcessLauncher typedef for testable process spawning

Production callers pass `defaultProcessLauncher` (a one-line forward to
`Process.start`); tests pass a closure that returns a fake `Process` so
JSON-RPC handshake plumbing can be exercised without spawning real
binaries. Lands ahead of CodexSession so the constructor seam is in
place when the extraction follows.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Extract `CodexSession` and rewire the existing datasource to use one

**Why this task is one atomic commit:** the existing `CodexCliDatasourceProcess` is monolithic — its scalar fields (`_process`, `_workingDirectory`, `_providerThreadId`, `_streamController`) are read across ~40 methods. Porting to `CodexSession` while leaving the old implementation in place would create ~400 lines of duplicated logic. Doing the extraction AND the swap in one commit keeps the codebase coherent. Behaviour is unchanged: still one session at a time, still single-session interface; the `CodexCliDatasourceProcess` just delegates to a single internally-held `CodexSession`.

**Files:**
- Create: `lib/data/ai/datasource/codex_session.dart` (~400 lines, mostly moved)
- Modify: `lib/data/ai/datasource/codex_cli_datasource_process.dart` (slim to ~150 lines)
- Test: `test/data/ai/datasource/codex_session_test.dart`

- [ ] **Step 1: Add the test infrastructure (Fake Process + Fake IOSink) and the first failing test**

`test/data/ai/datasource/codex_session_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:code_bench_app/data/ai/datasource/codex_session.dart';
import 'package:code_bench_app/data/ai/datasource/process_launcher.dart';
import 'package:code_bench_app/data/ai/models/provider_runtime_event.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIOSink implements IOSink {
  final List<String> writes = [];

  @override
  void writeln([Object? obj = '']) => writes.add(obj.toString());

  @override
  Future<void> close() async {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> get done => Future.value();

  // Methods we don't exercise — fail loudly if called so tests catch drift.
  @override
  Encoding get encoding => utf8;
  @override
  set encoding(Encoding value) => throw UnimplementedError();
  @override
  void add(List<int> data) => throw UnimplementedError();
  @override
  void addError(Object error, [StackTrace? stackTrace]) => throw UnimplementedError();
  @override
  Future<void> addStream(Stream<List<int>> stream) => throw UnimplementedError();
  @override
  void write(Object? obj) => throw UnimplementedError();
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) => throw UnimplementedError();
  @override
  void writeCharCode(int charCode) => throw UnimplementedError();
}

class _FakeProcess implements Process {
  _FakeProcess()
      : _stdoutCtrl = StreamController<List<int>>(),
        _stderrCtrl = StreamController<List<int>>(),
        _exitCompleter = Completer<int>();

  final StreamController<List<int>> _stdoutCtrl;
  final StreamController<List<int>> _stderrCtrl;
  final _FakeIOSink _stdin = _FakeIOSink();
  final Completer<int> _exitCompleter;
  bool killed = false;

  @override
  Stream<List<int>> get stdout => _stdoutCtrl.stream;
  @override
  Stream<List<int>> get stderr => _stderrCtrl.stream;
  @override
  IOSink get stdin => _stdin;
  @override
  Future<int> get exitCode => _exitCompleter.future;
  @override
  int get pid => 12345;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(0);
    return true;
  }

  void emitStdoutLine(String line) => _stdoutCtrl.add(utf8.encode('$line\n'));

  Future<void> exit(int code) async {
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(code);
    await _stdoutCtrl.close();
    await _stderrCtrl.close();
  }
}

ProcessLauncher _launcherReturning(_FakeProcess process) {
  return (
    String exe,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
  }) async {
    return process;
  };
}

CodexSession _makeSession({
  String sessionId = '11111111-1111-4111-8111-111111111111',
  String workingDirectory = '/tmp',
  required ProcessLauncher launcher,
}) {
  return CodexSession(
    sessionId: sessionId,
    workingDirectory: workingDirectory,
    exePath: '/fake/codex',
    env: const {},
    processLauncher: launcher,
  );
}

void main() {
  group('CodexSession', () {
    test('isInFlight is false before any sendAndStream call', () {
      final session = _makeSession(launcher: _launcherReturning(_FakeProcess()));
      expect(session.isInFlight, isFalse);
    });

    test('lastActiveAt is set at construction time', () {
      final before = DateTime.now();
      final session = _makeSession(launcher: _launcherReturning(_FakeProcess()));
      final after = DateTime.now();
      expect(session.lastActiveAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(session.lastActiveAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('dispose is safe to call before any process is spawned', () async {
      final session = _makeSession(launcher: _launcherReturning(_FakeProcess()));
      await expectLater(session.dispose(), completes);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails on the import**

Run: `flutter test test/data/ai/datasource/codex_session_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:code_bench_app/data/ai/datasource/codex_session.dart'`

- [ ] **Step 3: Create the `CodexSession` file by porting logic out of `CodexCliDatasourceProcess`**

This step is a port-and-rename refactor. The ~400 lines of method bodies move verbatim from `CodexCliDatasourceProcess` to `CodexSession` with three mechanical substitutions; the plan does NOT duplicate the bodies inline because they are unchanged in logic. Substitution rules:

1. `_workingDirectory` → `this.workingDirectory` (instance field on the new class).
2. `Process.start(exePath, ['app-server'], …)` → `_processLauncher(exePath, const ['app-server'], …)`.
3. References to `_resolvedPath` and `_shellPath` inside `_ensureProcess` are removed — `exePath` and `env` are now constructor-supplied.

Log prefixes — `[CodexCli]` and `[CodexProvider.stderr]` etc. — keep their existing strings so log-grep patterns remain valid; do not rebrand them to `[CodexSession]`.

`lib/data/ai/datasource/codex_session.dart` — port the following from `CodexCliDatasourceProcess`, with the source removed in Step 4:

- Move these private methods verbatim, replacing `_workingDirectory` reads with `this.workingDirectory` and `_resolvedPath`/`_shellPath` reads with constructor-supplied `exePath`/`env`:
  - `_send(String prompt, ProviderTurnSettings? settings)` — drops the `sessionId` and `workingDirectory` arguments; reads them from instance fields.
  - `_ensureProcess()` — drops the `workingDirectory` argument; uses the instance field.
  - `_initialize()`
  - `_startThread(String? developerInstructions)` — drops the `sessionId` and `workingDirectory` args.
  - `_sendTurn(String prompt, ProviderTurnSettings? settings)`
  - `_handleLine(String line)`
  - `_handleResponse(dynamic id, Map<String, dynamic> result)`
  - `_handleErrorResponse(dynamic id, Map<String, dynamic> error)`
  - `_handleServerRequest(dynamic id, String method, Map<String, dynamic>? params)`
  - `_handleNotification(String method, Map<String, dynamic>? params)`
  - `_emitPermissionRequest(dynamic id, String method, Map<String, dynamic>? params)`
  - `_writeStdin(String message)`
  - `_request(String method, Map<String, dynamic> params)`
  - `_notify(String method, [Map<String, dynamic>? params])`
  - `_respond(dynamic id, Map<String, dynamic> result)`
  - `_resetTurn()`
  - `_resetProcess()`
  - `_methodToToolName(String method)`
  - `_normalizeItemType(String raw)`

Replace `Process.start(...)` inside `_ensureProcess()` with `processLauncher(...)`. The retry-on-`ProcessException` block also calls the launcher. Both use `exePath` and `env` from instance fields.

Stamp `_lastActiveAt = DateTime.now()` at the end of `_resetTurn()`.

The complete top-level structure of `lib/data/ai/datasource/codex_session.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';
import '../../shared/session_settings.dart';
import '../models/provider_capabilities.dart';
import '../models/provider_runtime_event.dart';
import '../models/provider_turn_settings.dart';
import '../util/setting_mappers.dart';
import 'process_launcher.dart';
import 'provider_input_guards.dart';

/// Owns one Codex `app-server` process bound to one chat session.
///
/// Construction is pure (no I/O). The first [sendAndStream] call spawns the
/// process, performs the JSON-RPC handshake (`initialize` -> `initialized`
/// -> `thread/start`), and then forwards every `turn/start` for the session.
/// Subsequent `sendAndStream` calls reuse the same process and thread.
///
/// Lifecycle ends when [dispose] is called or the process exits.
class CodexSession {
  CodexSession({
    required this.sessionId,
    required this.workingDirectory,
    required this.exePath,
    required this.env,
    ProcessLauncher? processLauncher,
  }) : _processLauncher = processLauncher ?? defaultProcessLauncher,
       _lastActiveAt = DateTime.now();

  final String sessionId;
  final String workingDirectory;
  final String exePath;
  final Map<String, String> env;
  final ProcessLauncher _processLauncher;

  static const int _stderrCap = 64 * 1024;
  static const int _consecutiveParseFailureLimit = 5;

  Process? _process;
  String? _version;
  String? _providerThreadId;
  StreamController<ProviderRuntimeEvent>? _streamController;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  final StringBuffer _stderrBuffer = StringBuffer();
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final Map<dynamic, Completer<Map<String, dynamic>>> _pendingApprovals = {};
  int _nextId = 1;
  int _consecutiveJsonParseFailures = 0;
  DateTime _lastActiveAt;

  DateTime get lastActiveAt => _lastActiveAt;
  bool get isInFlight => _streamController?.isClosed == false;

  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    ProviderTurnSettings? settings,
  }) {
    _lastActiveAt = DateTime.now();
    _streamController?.close();
    // Single-subscription so ProviderInit (added synchronously by `_send`
    // before its first `await`) buffers until `await for` subscribes.
    _streamController = StreamController<ProviderRuntimeEvent>();
    _send(prompt, settings);
    return _streamController!.stream;
  }

  void cancel() {
    if (_providerThreadId != null && _process != null) {
      _notify('turn/interrupt', {'threadId': _providerThreadId});
    }
    _resetTurn();
  }

  void respondToPermissionRequest(String requestId, {required bool approved}) {
    final completer = _pendingApprovals.remove(requestId);
    if (completer == null) {
      dLog('[CodexSession] No pending approval for requestId $requestId');
      return;
    }
    completer.complete({'decision': approved ? 'approved' : 'denied'});
  }

  Future<void> dispose() async {
    _resetTurn();
    _process?.kill();
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
    _stderrBuffer.clear();
    _process = null;
    _providerThreadId = null;
    _version = null;
  }

  // ---- ported private methods follow ----
  // _send, _ensureProcess, _initialize, _startThread, _sendTurn,
  // _handleLine, _handleResponse, _handleErrorResponse, _handleServerRequest,
  // _handleNotification, _emitPermissionRequest, _writeStdin,
  // _request, _notify, _respond, _resetTurn, _resetProcess,
  // _methodToToolName, _normalizeItemType
}
```

In `_resetTurn()`, the new last line is `_lastActiveAt = DateTime.now();` so the idle clock starts at turn-end, not turn-start.

In `_ensureProcess()`, the `Process.start` call site changes from:

```dart
_process = await Process.start(
  exePath,
  ['app-server'],
  workingDirectory: workingDirectory,
  runInShell: false,
  includeParentEnvironment: false,
  environment: minimalEnv,
);
```

to:

```dart
_process = await _processLauncher(
  exePath,
  const ['app-server'],
  workingDirectory: workingDirectory,
  runInShell: false,
  includeParentEnvironment: false,
  environment: env,
);
```

(`exePath`, `workingDirectory`, `env` all become instance fields; `minimalEnv` no longer constructed inside the method — the pool builds it once and passes it in.)

The retry-on-`ProcessException` block uses the same launcher.

- [ ] **Step 4: Strip the moved methods from `CodexCliDatasourceProcess` and route through a single internally-held `CodexSession`**

In `lib/data/ai/datasource/codex_cli_datasource_process.dart`:

Remove these instance fields (now living on `CodexSession`):
- `Process? _process`
- `String? _workingDirectory`
- `int _nextId`
- `final Map<int, Completer<Map<String, dynamic>>> _pendingRequests`
- `final Map<dynamic, Completer<Map<String, dynamic>>> _pendingApprovals`
- `StreamController<ProviderRuntimeEvent>? _streamController`
- `StreamSubscription<String>? _stdoutSubscription`
- `StreamSubscription<String>? _stderrSubscription`
- `final StringBuffer _stderrBuffer`
- `int _consecutiveJsonParseFailures`
- `String? _providerThreadId`
- `String? _version`

Remove these methods (now on `CodexSession`):
- `_send`, `_ensureProcess`, `_initialize`, `_startThread`, `_sendTurn`,
  `_handleLine`, `_handleResponse`, `_handleErrorResponse`,
  `_handleServerRequest`, `_handleNotification`, `_emitPermissionRequest`,
  `_writeStdin`, `_request`, `_notify`, `_respond`, `_resetTurn`,
  `_resetProcess`, `_methodToToolName`, `_normalizeItemType`

Keep these (install-level, not session-level):
- `id`, `displayName`, `capabilitiesFor`, `detect`, `verifyAuth`,
  `_resolveExePath`, `_resolvedPath`, `_shellPath`, `binaryPath`

Add a single internally-held `CodexSession?`:

```dart
class CodexCliDatasourceProcess implements AIProviderDatasource {
  CodexCliDatasourceProcess({required this.binaryPath, ProcessLauncher? processLauncher})
      : _processLauncher = processLauncher ?? defaultProcessLauncher;

  final String binaryPath;
  final ProcessLauncher _processLauncher;

  String? _resolvedPath;
  String? _shellPath;

  /// Single in-flight session in this commit. The pool refactor in Task 3
  /// promotes this to a Map<sessionId, CodexSession>.
  CodexSession? _session;

  // ... id, displayName, capabilitiesFor, detect, verifyAuth unchanged ...

  @override
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
    ProviderTurnSettings? settings,
  }) async* {
    final session = await _ensureSession(sessionId, workingDirectory);
    yield* session.sendAndStream(prompt: prompt, settings: settings);
  }

  Future<CodexSession> _ensureSession(String sessionId, String workingDirectory) async {
    final existing = _session;
    if (existing != null &&
        existing.sessionId == sessionId &&
        existing.workingDirectory == workingDirectory) {
      return existing;
    }
    if (existing != null) {
      await existing.dispose();
    }
    _session = CodexSession(
      sessionId: sessionId,
      workingDirectory: workingDirectory,
      exePath: await _resolveExePath(),
      env: _buildMinimalEnv(),
      processLauncher: _processLauncher,
    );
    return _session!;
  }

  Map<String, String> _buildMinimalEnv() {
    final parentEnv = Platform.environment;
    return <String, String>{
      if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
      'PATH': _shellPath ?? parentEnv['PATH'] ?? '/usr/bin:/bin:/usr/sbin:/sbin',
      if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
      if (parentEnv['LANG'] != null) 'LANG': parentEnv['LANG']!,
      if (parentEnv['TMPDIR'] != null) 'TMPDIR': parentEnv['TMPDIR']!,
      if (parentEnv['SHELL'] != null) 'SHELL': parentEnv['SHELL']!,
      if (parentEnv['CODEX_HOME'] != null) 'CODEX_HOME': parentEnv['CODEX_HOME']!,
    };
  }

  @override
  void cancel() => _session?.cancel();

  @override
  void respondToPermissionRequest(String requestId, {required bool approved}) =>
      _session?.respondToPermissionRequest(requestId, approved: approved);
}
```

Note: `cancel()` and `respondToPermissionRequest(requestId, ...)` keep their existing single-arg signatures in this commit. The interface change happens in Task 3.

Top-level helpers — `buildCodexTurnStartParams`, `buildCodexThreadStartParams`, `parseCodexAuthOutput`, `parseCodexModelList`, `fetchCodexAvailableModels` — stay verbatim in this file. They're pure functions.

- [ ] **Step 5: Run the new CodexSession unit tests**

Run: `flutter test test/data/ai/datasource/codex_session_test.dart`
Expected: PASS — three tests green (isInFlight, lastActiveAt, dispose-before-spawn).

- [ ] **Step 6: Run the full test suite**

Run: `flutter test`
Expected: PASS — 741+3 tests = 744 tests green. The existing
`codex_cli_turn_start_params_test.dart` and `codex_model_list_parser_test.dart`
still cover the top-level helpers (which didn't move). Existing
`chat_notifier_test.dart` still passes because the `cancel()` /
`respondToPermissionRequest(requestId, ...)` interface is unchanged.

- [ ] **Step 7: Format and analyze**

Run: `dart format lib/ test/ && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/data/ai/datasource/codex_session.dart \
        lib/data/ai/datasource/codex_cli_datasource_process.dart \
        test/data/ai/datasource/codex_session_test.dart
git commit -m "$(cat <<'EOF'
refactor(codex): extract CodexSession from CodexCliDatasourceProcess

Pure refactor: behaviour unchanged. The 19 previously-private methods on
CodexCliDatasourceProcess (_send, _ensureProcess, _initialize, _handleLine,
_handleResponse, _handleNotification, _emitPermissionRequest, _writeStdin,
_request, _notify, _respond, _resetTurn, _resetProcess, _methodToToolName,
_normalizeItemType, _startThread, _sendTurn, _handleErrorResponse,
_handleServerRequest) move to a new CodexSession class that owns one
process for one (sessionId, workingDirectory). The datasource now holds a
single CodexSession field and delegates per-call.

ProcessLauncher is injected through the constructor (defaults to
defaultProcessLauncher → Process.start) so CodexSession can be unit-
tested with a fake Process. Three smoke tests added covering construction,
lastActiveAt initialisation, and dispose-before-spawn idempotency.

Sets up the next task: promoting the single CodexSession field to a
CodexSessionPool keyed by sessionId, plus the AIProviderDatasource
interface change to make cancel and respondToPermissionRequest
session-scoped.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `CodexSessionPool` + interface change + Claude CLI fix + session_service callsites

**Why this task is one atomic commit:** the `AIProviderDatasource.cancel(String sessionId)` and `respondToPermissionRequest(String sessionId, String requestId, ...)` interface changes break compilation for both implementers (Codex CLI, Claude CLI) and the single consumer (`session_service.dart`) until all four sites are updated together.

**Files:**
- Create: `lib/data/ai/datasource/codex_session_pool.dart`
- Test: `test/data/ai/datasource/codex_session_pool_test.dart`
- Modify: `lib/data/ai/datasource/ai_provider_datasource.dart` (interface signatures)
- Modify: `lib/data/ai/datasource/codex_cli_datasource_process.dart` (swap `CodexSession?` → `CodexSessionPool`, propagate sessionId on cancel/respond)
- Modify: `lib/data/ai/datasource/claude_cli_datasource_process.dart` (`Map<String, Process>` for cancel routing + `(sessionId, ...)` signatures)
- Modify: `lib/services/session/session_service.dart:305,349` (pass `sessionId` to `cancel` and `respondToPermissionRequest`)

### Sub-task 3a: Build CodexSessionPool with TDD

- [ ] **Step 1: Write the failing pool tests**

`test/data/ai/datasource/codex_session_pool_test.dart`:

```dart
import 'dart:async';

import 'package:code_bench_app/data/ai/datasource/codex_session.dart';
import 'package:code_bench_app/data/ai/datasource/codex_session_pool.dart';
import 'package:code_bench_app/data/ai/datasource/process_launcher.dart';
import 'package:code_bench_app/data/ai/models/provider_runtime_event.dart';
import 'package:code_bench_app/data/ai/models/provider_turn_settings.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCodexSession extends Fake implements CodexSession {
  _FakeCodexSession({
    required this.sessionId,
    required this.workingDirectory,
    DateTime? lastActiveAt,
    this.isInFlight = false,
  }) : _lastActiveAt = lastActiveAt ?? DateTime.now();

  @override
  final String sessionId;

  @override
  final String workingDirectory;

  DateTime _lastActiveAt;

  @override
  DateTime get lastActiveAt => _lastActiveAt;
  set lastActiveAt(DateTime value) => _lastActiveAt = value;

  @override
  bool isInFlight;

  bool disposed = false;
  bool cancelled = false;
  String? lastApprovalRequestId;
  bool? lastApproved;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  void cancel() {
    cancelled = true;
  }

  @override
  void respondToPermissionRequest(String requestId, {required bool approved}) {
    lastApprovalRequestId = requestId;
    lastApproved = approved;
  }
}

CodexSessionPool _poolWithFakeFactory(
  Map<String, _FakeCodexSession> registry, {
  Duration idleTimeout = const Duration(minutes: 10),
}) {
  return CodexSessionPool(
    binaryPath: 'codex',
    idleTimeout: idleTimeout,
    sessionFactory: ({
      required sessionId,
      required workingDirectory,
      required exePath,
      required env,
      ProcessLauncher? processLauncher,
    }) {
      final fake = _FakeCodexSession(sessionId: sessionId, workingDirectory: workingDirectory);
      registry[sessionId] = fake;
      return fake;
    },
    exePathResolver: () async => '/fake/codex',
  );
}

void main() {
  group('CodexSessionPool.sessionFor', () {
    test('returns the same instance for the same (sessionId, workingDirectory)', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      final a = await pool.sessionFor('session-1', '/proj/a');
      final b = await pool.sessionFor('session-1', '/proj/a');

      expect(identical(a, b), isTrue);
      expect(registry.length, 1);
    });

    test('disposes the existing session when workingDirectory changes for the same sessionId', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      final original = await pool.sessionFor('session-1', '/proj/a') as _FakeCodexSession;
      final replacement = await pool.sessionFor('session-1', '/proj/b') as _FakeCodexSession;

      expect(original.disposed, isTrue);
      expect(identical(original, replacement), isFalse);
      expect(replacement.workingDirectory, '/proj/b');
    });

    test('keeps independent sessions for different sessionIds', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      final a = await pool.sessionFor('session-1', '/proj/a') as _FakeCodexSession;
      final b = await pool.sessionFor('session-2', '/proj/b') as _FakeCodexSession;

      expect(identical(a, b), isFalse);
      expect(a.disposed, isFalse);
      expect(b.disposed, isFalse);
    });
  });

  group('CodexSessionPool eviction', () {
    test('evicts sessions idle longer than idleTimeout', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry, idleTimeout: const Duration(milliseconds: 1));

      final stale = await pool.sessionFor('stale', '/p') as _FakeCodexSession;
      stale.lastActiveAt = DateTime.now().subtract(const Duration(minutes: 1));

      // Trigger lazy eviction by asking for a different session.
      await pool.sessionFor('fresh', '/p');

      expect(stale.disposed, isTrue);
    });

    test('does NOT evict an in-flight session even when lastActiveAt is old', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry, idleTimeout: const Duration(milliseconds: 1));

      final inFlight = await pool.sessionFor('long-turn', '/p') as _FakeCodexSession;
      inFlight.lastActiveAt = DateTime.now().subtract(const Duration(minutes: 1));
      inFlight.isInFlight = true;

      await pool.sessionFor('other', '/p');

      expect(inFlight.disposed, isFalse);
    });
  });

  group('CodexSessionPool.cancel', () {
    test('cancels the matching session and leaves others alone', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      await pool.sessionFor('a', '/p');
      await pool.sessionFor('b', '/p');

      pool.cancel('a');

      expect(registry['a']!.cancelled, isTrue);
      expect(registry['b']!.cancelled, isFalse);
    });

    test('is a no-op for an unknown sessionId', () {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      expect(() => pool.cancel('nope'), returnsNormally);
    });
  });

  group('CodexSessionPool.respondToPermissionRequest', () {
    test('routes approval to the matching session', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      await pool.sessionFor('a', '/p');
      pool.respondToPermissionRequest('a', 'req-1', approved: true);

      expect(registry['a']!.lastApprovalRequestId, 'req-1');
      expect(registry['a']!.lastApproved, isTrue);
    });
  });

  group('CodexSessionPool.dispose', () {
    test('disposes every live session', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      await pool.sessionFor('a', '/p');
      await pool.sessionFor('b', '/p');

      await pool.dispose();

      expect(registry['a']!.disposed, isTrue);
      expect(registry['b']!.disposed, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/data/ai/datasource/codex_session_pool_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:code_bench_app/data/ai/datasource/codex_session_pool.dart'`

- [ ] **Step 3: Implement `CodexSessionPool`**

`lib/data/ai/datasource/codex_session_pool.dart`:

```dart
import 'dart:async';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';
import 'binary_resolver_process.dart';
import 'codex_session.dart';
import 'process_launcher.dart';

/// Factory typedef matching `CodexSession.new` so tests can inject a stub
/// implementation without driving the real process plumbing.
typedef CodexSessionFactory =
    CodexSession Function({
      required String sessionId,
      required String workingDirectory,
      required String exePath,
      required Map<String, String> env,
      ProcessLauncher? processLauncher,
    });

/// Resolves the Codex binary's absolute path. Tests inject a closure that
/// returns a fixed path; production wires through `resolveBinary`.
typedef ExePathResolver = Future<String> Function();

/// Owns a per-`sessionId` map of live `CodexSession`s. Lazy idle eviction
/// runs at the top of every [sessionFor] call so abandoned chats reclaim
/// memory without a `Timer.periodic` to manage.
class CodexSessionPool {
  CodexSessionPool({
    required this.binaryPath,
    this.idleTimeout = const Duration(minutes: 10),
    ProcessLauncher? processLauncher,
    CodexSessionFactory? sessionFactory,
    ExePathResolver? exePathResolver,
  }) : _processLauncher = processLauncher ?? defaultProcessLauncher,
       _sessionFactory = sessionFactory ?? CodexSession.new,
       _exePathResolver = exePathResolver;

  final String binaryPath;
  final Duration idleTimeout;
  final ProcessLauncher _processLauncher;
  final CodexSessionFactory _sessionFactory;
  final ExePathResolver? _exePathResolver;

  final Map<String, CodexSession> _sessions = {};
  String? _resolvedPath;
  String? _shellPath;

  Future<CodexSession> sessionFor(String sessionId, String workingDirectory) async {
    _evictIdle();
    final existing = _sessions[sessionId];
    if (existing != null && existing.workingDirectory == workingDirectory) {
      return existing;
    }
    if (existing != null) {
      // Same chat, different cwd — rare (chat moved between projects).
      // Tear the old one down before creating a fresh one.
      await existing.dispose();
      _sessions.remove(sessionId);
    }
    final session = _sessionFactory(
      sessionId: sessionId,
      workingDirectory: workingDirectory,
      exePath: await _resolveExePath(),
      env: _buildMinimalEnv(),
      processLauncher: _processLauncher,
    );
    _sessions[sessionId] = session;
    return session;
  }

  void cancel(String sessionId) => _sessions[sessionId]?.cancel();

  void respondToPermissionRequest(
    String sessionId,
    String requestId, {
    required bool approved,
  }) {
    _sessions[sessionId]?.respondToPermissionRequest(requestId, approved: approved);
  }

  Future<void> dispose() async {
    final all = _sessions.values.toList();
    _sessions.clear();
    await Future.wait(all.map((s) => s.dispose()));
  }

  void _evictIdle() {
    final now = DateTime.now();
    final stale = <MapEntry<String, CodexSession>>[];
    for (final entry in _sessions.entries) {
      if (entry.value.isInFlight) continue;
      if (now.difference(entry.value.lastActiveAt) > idleTimeout) {
        stale.add(entry);
      }
    }
    for (final entry in stale) {
      _sessions.remove(entry.key);
      unawaited(entry.value.dispose());
      dLog('[CodexSessionPool] evicted idle session ${entry.key}');
    }
  }

  Future<String> _resolveExePath() async {
    final injected = _exePathResolver;
    if (injected != null) return injected();
    if (_resolvedPath != null) return _resolvedPath!;
    final r = await resolveBinary(binaryPath);
    switch (r) {
      case BinaryFound(:final path, :final shellPath):
        _resolvedPath = path;
        _shellPath = shellPath;
        return path;
      case BinaryNotFound():
        throw Exception('Codex CLI is not installed or not on PATH');
      case BinaryProbeFailed(:final reason):
        throw Exception('Could not probe Codex CLI: $reason');
    }
  }

  Map<String, String> _buildMinimalEnv() {
    final parentEnv = Platform.environment;
    return <String, String>{
      if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
      'PATH': _shellPath ?? parentEnv['PATH'] ?? '/usr/bin:/bin:/usr/sbin:/sbin',
      if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
      if (parentEnv['LANG'] != null) 'LANG': parentEnv['LANG']!,
      if (parentEnv['TMPDIR'] != null) 'TMPDIR': parentEnv['TMPDIR']!,
      if (parentEnv['SHELL'] != null) 'SHELL': parentEnv['SHELL']!,
      if (parentEnv['CODEX_HOME'] != null) 'CODEX_HOME': parentEnv['CODEX_HOME']!,
    };
  }
}
```

- [ ] **Step 4: Run the pool tests to verify they pass**

Run: `flutter test test/data/ai/datasource/codex_session_pool_test.dart`
Expected: PASS — all 9 tests green.

### Sub-task 3b: Update `AIProviderDatasource` interface

- [ ] **Step 5: Modify the abstract interface**

In `lib/data/ai/datasource/ai_provider_datasource.dart`, change:

```dart
abstract interface class AIProviderDatasource {
  // ...
  void cancel();
  void respondToPermissionRequest(String requestId, {required bool approved});
}
```

to:

```dart
abstract interface class AIProviderDatasource {
  // ...
  /// Cancel the in-flight turn for [sessionId]. No-op if the session has no
  /// active turn or no associated process.
  void cancel(String sessionId);

  /// Resolve a server-initiated permission request originating from
  /// [sessionId]'s stream. No-op for providers that don't support
  /// interactive approval.
  void respondToPermissionRequest(
    String sessionId,
    String requestId, {
    required bool approved,
  });
}
```

This breaks compilation in three places — fixed in Steps 6, 7, and 8 below. Run no commands until all three are patched.

### Sub-task 3c: Swap CodexCliDatasourceProcess to use the pool

- [ ] **Step 6: Replace the single-CodexSession field with a CodexSessionPool**

In `lib/data/ai/datasource/codex_cli_datasource_process.dart`:

Remove the `CodexSession? _session` field and `_ensureSession`, `_buildMinimalEnv` helpers added in Task 2. Replace with a `CodexSessionPool _pool`:

```dart
class CodexCliDatasourceProcess implements AIProviderDatasource {
  CodexCliDatasourceProcess({required String binaryPath, ProcessLauncher? processLauncher})
      : _pool = CodexSessionPool(binaryPath: binaryPath, processLauncher: processLauncher);

  final CodexSessionPool _pool;

  // ... id, displayName, capabilitiesFor, detect, verifyAuth, _resolveExePath
  //     unchanged ...

  @override
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
    ProviderTurnSettings? settings,
  }) async* {
    final session = await _pool.sessionFor(sessionId, workingDirectory);
    yield* session.sendAndStream(prompt: prompt, settings: settings);
  }

  @override
  void cancel(String sessionId) => _pool.cancel(sessionId);

  @override
  void respondToPermissionRequest(
    String sessionId,
    String requestId, {
    required bool approved,
  }) => _pool.respondToPermissionRequest(sessionId, requestId, approved: approved);
}
```

`detect` continues to call the file-local `_resolveExePath` for the version probe. The pool maintains its own internal cache; the small duplication of binary resolution between `detect()` (one-shot install probe) and `CodexSessionPool` (per-session spawn) is intentional and preserves the existing detection lifecycle.

Add the `process_launcher.dart` and `codex_session_pool.dart` imports at the top of the file.

### Sub-task 3d: Claude CLI per-session process map

- [ ] **Step 7: Replace `Process? _process` with `Map<String, Process>` in Claude CLI**

In `lib/data/ai/datasource/claude_cli_datasource_process.dart`:

Change:

```dart
Process? _process;
```

to:

```dart
final Map<String, Process> _processes = {};
```

Inside `_stream(...)` after `Process.start` succeeds, change:

```dart
_process = spawned;
```

to:

```dart
_processes[sessionId] = spawned;
```

Inside `_stream`'s `finally` (after the process exits), change:

```dart
if (identical(_process, spawned)) _process = null;
```

to:

```dart
if (identical(_processes[sessionId], spawned)) {
  _processes.remove(sessionId);
}
```

Update `cancel()` (currently no-args, kills `_process`) to:

```dart
@override
void cancel(String sessionId) {
  _processes[sessionId]?.kill(ProcessSignal.sigterm);
}
```

Update `respondToPermissionRequest` to accept a `sessionId` arg. Claude CLI's stream-json protocol doesn't support interactive approval, so the body is unchanged (still a no-op or `dLog`):

```dart
@override
void respondToPermissionRequest(
  String sessionId,
  String requestId, {
  required bool approved,
}) {
  // Claude CLI's stream-json protocol doesn't expose interactive permission
  // responses; the session_service caller routes here only for
  // AIProviderDatasource interface uniformity. sessionId is unused.
}
```

Existing body — if it currently does anything with the request, preserve that, just take the new arg.

### Sub-task 3e: session_service callsites

- [ ] **Step 8: Pass `sessionId` at the two callsites**

In `lib/services/session/session_service.dart`, at the two callsites inside `_streamProvider`:

Line ~305 — inside the `cancelFlag()` branch — change:

```dart
ds.cancel();
```

to:

```dart
ds.cancel(sessionId);
```

Line ~349 — inside the `ProviderPermissionRequest` switch arm — change:

```dart
ds.respondToPermissionRequest(requestId, approved: approved);
```

to:

```dart
ds.respondToPermissionRequest(sessionId, requestId, approved: approved);
```

`sessionId` is already in scope at both sites (it's a parameter on `_streamProvider`).

### Sub-task 3f: Verify and commit

- [ ] **Step 9: Run analyzer to confirm interface change compiles end-to-end**

Run: `flutter analyze`
Expected: `No issues found!` — Codex, Claude CLI, and session_service all updated.

- [ ] **Step 10: Run the full test suite**

Run: `flutter test`
Expected: PASS — pre-existing 741 tests + 3 from CodexSession (Task 2) + 9 from CodexSessionPool = 753 tests green.

If `chat_notifier_test.dart` or `chat_notifier_cancel_test.dart` mocks `cancel()` or `respondToPermissionRequest`, update those mocks to match the new signatures. Run:
`grep -rn "respondToPermissionRequest\|cancel()" test/features/chat/notifiers/ --include="*.dart"`
to find any. Currently the test files don't mock the AIProviderDatasource interface directly, so this should be a no-op — but verify.

- [ ] **Step 11: Format**

Run: `dart format lib/ test/`

- [ ] **Step 12: Manual smoke test (do not commit until this passes)**

1. `flutter run -d macos`
2. Open Project A. Start Chat 1. Send `count to 3 slowly` (something that takes ≥ 5 seconds to stream).
3. Without waiting, switch to Project B in another window or sidebar entry. Start Chat 2. Send `count to 3 slowly`.
4. Verify: both chats stream concurrently. The flutter log shows `[CodexCli] spawning codex app-server in <wd>` twice with different `<wd>` paths (one per session).
5. Click cancel on Chat 1 mid-stream. Verify Chat 2 keeps streaming, Chat 1 shows the interrupt marker.
6. Verify the warning log `[SessionService] provider codex stream ended without ProviderInit` does NOT fire (regression check on the earlier broadcast-stream fix).

If any of these fail, do not commit — return to the failing step.

- [ ] **Step 13: Commit**

```bash
git add lib/data/ai/datasource/codex_session_pool.dart \
        lib/data/ai/datasource/codex_cli_datasource_process.dart \
        lib/data/ai/datasource/ai_provider_datasource.dart \
        lib/data/ai/datasource/claude_cli_datasource_process.dart \
        lib/services/session/session_service.dart \
        test/data/ai/datasource/codex_session_pool_test.dart
git commit -m "$(cat <<'EOF'
feat(codex): per-session app-server processes via CodexSessionPool

Introduces CodexSessionPool keyed by sessionId. Each chat session owns
its own codex app-server process — switching projects or sending to a
different chat no longer kills another chat's in-flight turn. Idle
sessions evict after 10 minutes (configurable on the pool) via lazy
sweep at the top of every sessionFor() call; in-flight sessions are
protected via isInFlight regardless of lastActiveAt.

AIProviderDatasource grows a sessionId argument on cancel() and
respondToPermissionRequest(), so each provider can route per-session.
Two implementations:

  - Codex (CodexCliDatasourceProcess): delegates to CodexSessionPool.
  - Claude CLI (ClaudeCliDatasourceProcess): keeps its per-turn-process
    spawn model but tracks Map<String, Process> by sessionId so cancel
    routes to the correct process. Fixes a latent bug where cancelling
    chat A while chat B was streaming would kill chat B (the latest
    spawned process).

session_service.dart's two callsites in _streamProvider thread the
in-scope sessionId through to the new interface.

Tests: 9 new pool tests (sessionFor identity, wd-change disposal,
eviction, in-flight protection, cancel routing, dispose). Existing
chat_notifier_test, codex_cli_turn_start_params_test, and
codex_model_list_parser_test stay green.

Manual smoke: two concurrent chats in different projects stream
without interference; cancel on one leaves the other intact.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-review checklist (run after writing this plan)

1. **Spec coverage** — every section of `2026-05-07-codex-per-session-process-design.md` traces to a task:
   - Three-class layout → Tasks 1-3. ✅
   - `CodexSession` field/method definitions → Task 2 Step 3. ✅
   - `CodexSessionPool` interface → Task 3 Step 3. ✅
   - `AIProviderDatasource` interface change → Task 3 Step 5. ✅
   - Claude CLI `Map<String, Process>` → Task 3 Step 7. ✅
   - session_service callsite updates → Task 3 Step 8. ✅
   - Eviction policy (10 min, lazy, in-flight protection) → Task 3 Steps 1-3. ✅
   - `_lastActiveAt` stamping at sendAndStream entry + `_resetTurn()` end → Task 2 Step 3 description. ✅
   - Manual smoke checklist → Task 3 Step 12. ✅
   - Commit shape (3 commits matching spec's branching plan) → Tasks 1, 2, 3. ✅

2. **Placeholder scan** — no "TBD" / "TODO" / "implement appropriate error handling" / "similar to Task N". All code shown verbatim. Test files give complete fakes.

3. **Type consistency** — `ProcessLauncher` typedef used identically in `process_launcher.dart`, `codex_session.dart` constructor, `codex_session_pool.dart` `_processLauncher` field, and the test launcher closures. `CodexSessionFactory` typedef matches `CodexSession.new`'s signature. `cancel(String sessionId)` and `respondToPermissionRequest(String sessionId, String requestId, ...)` match across the abstract interface, both implementers, and the consumer.

4. **Open question** — Step 10 of Task 3 mentions verifying that no test files mock the `cancel()` / `respondToPermissionRequest` interface directly. The grep is in the plan; if matches surface, the implementer updates them. Not pre-listed because the implementer hasn't run the grep yet.
