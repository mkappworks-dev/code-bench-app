# Per-session Codex CLI processes — design

**Date:** 2026-05-07
**Branch:** `fix/2026-05-06-tool-call-provider-model-badges`
**Status:** approved-for-implementation pending user spec review

## Problem

`CodexCliDatasourceProcess` holds Codex's `app-server` lifecycle on four scalar fields — `_process`, `_workingDirectory`, `_providerThreadId`, `_streamController` — and `keepAlive: true` makes it app-singleton. Consequence:

- Two chat sessions in the same project clobber each other's thread state (`_providerThreadId` is overwritten by whichever sent last).
- Switching projects kills the previous app-server and respawns in the new working directory, terminating any in-flight turn.
- `cancel()` takes no arguments and operates on the latest process, so cancelling chat A while chat B is streaming kills chat B's process.

Claude CLI doesn't share Codex's daemon model — each turn spawns its own ephemeral `claude -p` process — but it has the same `cancel()` shape and the same latent kill-the-wrong-process bug because `Process? _process` only tracks the most recent spawn.

## Goal

One Codex `app-server` per chat session, regardless of working directory. Sessions are independent: a crash, cancel, or project switch in one cannot disturb another. Idle sessions auto-evict after 10 minutes of inactivity.

Bundle Claude CLI's `cancel(sessionId)` interface fix in the same change to keep `AIProviderDatasource` consistent across providers.

## Non-goals

- Restarting a dead Codex process automatically — surfaces a `ProviderStreamFailure` and the user re-sends as today.
- A persistent process pool surviving app restarts — every session starts cold on launch.
- Multi-thread multiplexing inside a single Codex `app-server` — we use one process per session, which is simpler than multiplexing thread IDs through one process.
- Claude CLI session pooling — Claude CLI already gets a fresh process per turn; only its `cancel` interface changes.

## Design

### Three classes, one subfolder

```
lib/data/ai/datasource/codex/
  codex_cli_datasource_process.dart   ~150 lines  AIProviderDatasource adapter
  codex_session.dart                   ~400 lines  one-process-one-chat
  codex_session_pool.dart              ~150 lines  lifecycle + binary resolution
```

Top-level helpers — `buildCodexTurnStartParams`, `buildCodexThreadStartParams`, `parseCodexAuthOutput`, `parseCodexModelList`, `fetchCodexAvailableModels` — stay in `codex_cli_datasource_process.dart` as top-level functions. They're pure and don't belong to any of the three classes.

### `CodexSession` — single chat, single process

Owns one `Process`, one `_streamController`, one `_providerThreadId`. Constructor takes `sessionId`, `workingDirectory`, `exePath`, `env` — no Riverpod, no provider lookups, no shell-resolution. Pure plumbing over a single `app-server` instance.

```dart
class CodexSession {
  CodexSession({
    required this.sessionId,
    required this.workingDirectory,
    required this.exePath,
    required this.env,
  });

  final String sessionId;
  final String workingDirectory;
  final String exePath;
  final Map<String, String> env;

  Process? _process;
  String? _version;
  String? _providerThreadId;
  StreamController<ProviderRuntimeEvent>? _streamController;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  final StringBuffer _stderrBuffer = StringBuffer();
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final Map<dynamic, Completer<Map<String, dynamic>>> _pendingApprovals = {};
  int _nextId = 1;
  int _consecutiveJsonParseFailures = 0;
  DateTime _lastActiveAt = DateTime.now();

  DateTime get lastActiveAt => _lastActiveAt;
  bool get isInFlight => _streamController?.isClosed == false;

  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    ProviderTurnSettings? settings,
  });

  void cancel();
  void respondToPermissionRequest(String requestId, {required bool approved});
  Future<void> dispose();
}
```

The body of `sendAndStream`, `_send`, `_ensureProcess`, `_initialize`, `_startThread`, `_sendTurn`, `_handleLine`, `_handleResponse`, `_handleErrorResponse`, `_handleServerRequest`, `_handleNotification`, `_emitPermissionRequest`, `_writeStdin`, `_request`, `_notify`, `_respond`, `_resetTurn`, `_resetProcess`, `_methodToToolName`, `_normalizeItemType` — all migrate verbatim from the existing `CodexCliDatasourceProcess`, with `_workingDirectory` reads dropped (now a constructor field) and the per-session field references unchanged in shape.

`_lastActiveAt` is stamped at exactly two points:

1. **Top of `sendAndStream`** — marks "session is being used now".
2. **End of `_resetTurn()`** — marks "this session just finished a turn", so the 10-minute idle clock starts from turn-end, not turn-start. Without this, a long agent turn (15 min mid-stream) would age out the moment it completes; `isInFlight` protects it during streaming, but eviction would fire on the very next `sessionFor` call.

The pool reads `lastActiveAt` during eviction. In-flight sessions are protected separately via `isInFlight`, so per-event stamping is unnecessary.

### `CodexSessionPool` — many sessions, one binary

Holds `Map<String, CodexSession>` keyed by sessionId. Owns binary resolution (`_resolvedPath`, `_shellPath`) because it's install-level state, not per-session. Owns the eviction policy.

```dart
class CodexSessionPool {
  CodexSessionPool({
    required this.binaryPath,
    this.idleTimeout = const Duration(minutes: 10),
  });

  final String binaryPath;
  final Duration idleTimeout;
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
      // Same chat, different cwd — the chat's project moved. Rare, but possible
      // via session import or future rename UX. Tear the old one down before
      // re-creating in the new cwd.
      await existing.dispose();
      _sessions.remove(sessionId);
    }
    final session = CodexSession(
      sessionId: sessionId,
      workingDirectory: workingDirectory,
      exePath: await _resolveExePath(),
      env: _buildMinimalEnv(),
    );
    _sessions[sessionId] = session;
    return session;
  }

  void cancel(String sessionId) => _sessions[sessionId]?.cancel();

  void respondToPermissionRequest(String sessionId, String requestId, {required bool approved}) =>
      _sessions[sessionId]?.respondToPermissionRequest(requestId, approved: approved);

  Future<void> dispose() async { /* tear down all sessions */ }

  void _evictIdle() {
    final now = DateTime.now();
    final stale = _sessions.entries
        .where((e) => !e.value.isInFlight && now.difference(e.value.lastActiveAt) > idleTimeout)
        .toList();
    for (final entry in stale) {
      _sessions.remove(entry.key);
      unawaited(entry.value.dispose());
    }
  }

  Future<String> _resolveExePath() async { /* extracted from existing class verbatim */ }
  Map<String, String> _buildMinimalEnv() { /* extracted from existing class verbatim */ }
}
```

Eviction is **lazy** — runs at the top of every `sessionFor` call. No `Timer.periodic`, so no timer-lifecycle surprises in test or under hot-reload. The cost: a session that's idle but never visited again sticks around until app exit. Acceptable; the `_resetProcess` cleanup at app-close (Riverpod's `onDispose`) catches the rest.

`isInFlight` short-circuits eviction for sessions that are mid-turn — important so a cancel-then-resume cycle (within 10 min) reuses the existing process.

### `CodexCliDatasourceProcess` — slim adapter

Implements `AIProviderDatasource`, holds one `CodexSessionPool`, delegates everything per-session through it. Detection and auth verification stay here (install-level, not session-level), but use the pool's resolved exe path.

```dart
class CodexCliDatasourceProcess implements AIProviderDatasource {
  CodexCliDatasourceProcess({required String binaryPath})
      : _pool = CodexSessionPool(binaryPath: binaryPath);

  final CodexSessionPool _pool;

  @override String get id => 'codex';
  @override String get displayName => 'Codex';
  @override ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(...);
  @override Future<DetectionResult> detect() async { /* unchanged, but routes through _pool's binary cache */ }
  @override Future<AuthStatus> verifyAuth() async { /* unchanged */ }

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

  @override void cancel(String sessionId) => _pool.cancel(sessionId);
  @override void respondToPermissionRequest(String sessionId, String requestId, {required bool approved}) =>
      _pool.respondToPermissionRequest(sessionId, requestId, approved: approved);
}
```

### Interface changes — `AIProviderDatasource`

```diff
- void cancel();
+ void cancel(String sessionId);

- void respondToPermissionRequest(String requestId, {required bool approved});
+ void respondToPermissionRequest(String sessionId, String requestId, {required bool approved});
```

Two callsites in `lib/services/session/session_service.dart`:

```dart
// _streamProvider, line ~305
if (cancelFlag()) {
  ds.cancel(sessionId);   // was: ds.cancel()
  ...
}

// _streamProvider, line ~349
ds.respondToPermissionRequest(sessionId, requestId, approved: approved);   // was: (requestId, approved:)
```

Both have `sessionId` in scope already — mechanical change.

### Claude CLI changes

`ClaudeCliDatasourceProcess` keeps its per-turn-process-spawn model, but to satisfy the new `cancel(sessionId)` and `respondToPermissionRequest(sessionId, …)` interfaces:

```diff
- Process? _process;
+ final Map<String, Process> _processes = {};
```

In `_stream`:
- After `Process.start`: `_processes[sessionId] = spawned;`
- In the cleanup `finally` (after exit): `if (identical(_processes[sessionId], spawned)) _processes.remove(sessionId);`

In `cancel(sessionId)`:
```dart
_processes[sessionId]?.kill(ProcessSignal.sigterm);
```

`respondToPermissionRequest(sessionId, ...)` — Claude CLI ignores it (no interactive approval over its stream-json protocol), so the `sessionId` arg is unused. Doc comment notes it.

This fixes the latent "cancel kills the latest, not the right one" bug as a side effect of making the interface consistent.

## Eviction policy

| Property | Value | Why |
|---|---|---|
| Strategy | Idle-timeout, lazy sweep | No `Timer.periodic` to manage; cost is one map walk per `sendAndStream` |
| Default duration | 10 minutes | Long enough that switching tabs / running a build doesn't tear down the daemon; short enough that abandoned chats reclaim ~50-100 MB RSS |
| Configurable | `CodexSessionPool` constructor `idleTimeout` parameter | Lets tests use `Duration.zero` or `Duration(milliseconds: 1)` without sleep |
| In-flight protection | `isInFlight` check | A session mid-turn is never evicted, even if `lastActiveAt` is old (e.g. user away during a long agent run) |
| App-exit cleanup | `_pool.dispose()` from a Riverpod `onDispose` on `codexCliDatasourceProcess` | Tears down all live processes on container disposal |

## Concurrency edge cases

| Scenario | Behaviour |
|---|---|
| Send to chat A, then chat B, in same project | Two `app-server` processes, two `_providerThreadId`s, fully independent streams |
| Send to chat A in project P, then move chat A to project Q | `sessionFor(A, Q)` sees existing session with wd=P, disposes it, creates fresh one with wd=Q |
| Cancel chat A while chat B is streaming | `_pool.cancel('A')` → only A's `turn/interrupt` fires; B unaffected |
| Codex process crashes for chat A | A's `_streamController` emits `ProviderStreamFailure`; B's process and stream untouched |
| User idle for 11 minutes, then sends to chat A | `_evictIdle` runs at top of `sessionFor`, A's stale session disposed; new session spawned, same `sessionId` so Codex's own `resumeThreadId` rehydrates context |
| Two concurrent sends to the *same* chat A | Second `sendAndStream` closes the first's `_streamController` (existing semantics, preserved) — turn-level serialization within a session still applies |

## Testing strategy

Three new test files; existing tests stay green.

### `test/data/ai/datasource/codex/codex_session_pool_test.dart`

Fakes a `CodexSession` factory so the pool can be tested without spawning real processes. Covers:

- `sessionFor` returns the same instance for the same `sessionId` + `workingDirectory`.
- `sessionFor` disposes and recreates when `workingDirectory` changes for the same `sessionId`.
- `_evictIdle` removes sessions older than `idleTimeout`.
- `_evictIdle` skips sessions mid-turn (`isInFlight == true`).
- `cancel` and `respondToPermissionRequest` route to the right session.
- `dispose` tears down all sessions.

### `test/data/ai/datasource/codex/codex_session_test.dart`

Stubs `Process.start` via a process factory injected through the constructor (small new abstraction — see "Risks" below). Covers:

- `_pendingRequests` ID counter is per-instance, not global.
- `dispose` kills the process and cancels stdout/stderr subscriptions.
- `cancel()` sends `turn/interrupt` only when there's an in-flight thread.

If the process-factory injection is too invasive for the time budget, this file gets a light "construction smoke test" only and the integration concerns are covered manually.

### Existing tests

- `codex_cli_turn_start_params_test.dart` — unchanged. Tests pure functions.
- `codex_model_list_parser_test.dart` — unchanged. `fetchCodexAvailableModels` still spawns its own ephemeral process, untouched by the pool.
- `chat_notifier_test.dart` — unchanged.
- All session_service tests — `cancel(sessionId)` and `respondToPermissionRequest(sessionId, …)` signature changes are mechanical; if any test mocks these methods we update the mock.

## Manual smoke test

1. Open Project A, start chat 1, send `Hello`. Wait for response.
2. Open Project B, start chat 2, send `Hello`. Both stream concurrently — no "switching project" pause.
3. While chat 2 is mid-stream, click cancel on chat 1. Chat 2 keeps streaming.
4. Idle 11 minutes. Send to chat 1 again — Codex re-spawns, `--resume`-style context retained via Codex's own thread store.
5. `[CodexCli] spawning codex app-server in <wd>` log fires per session, not globally.

## Risks

1. **`Process.start` injection for tests**. To unit-test `CodexSession` without spawning real binaries we need a `ProcessFactory` typedef threaded through the constructor. The cleanest version is `typedef ProcessLauncher = Future<Process> Function(String exe, List<String> args, {String? workingDirectory, …})`. This is a new abstraction in this layer — adds slight mechanical cost to every `Process.start` callsite. **Decision:** add it; the testability win pays for the indirection.

2. **`sendAndStream` is async generator now (`async*`) instead of returning a stream synchronously**. The existing implementation returns the stream synchronously; pulling it through `_pool.sessionFor` (which is async) forces the adapter's `sendAndStream` to be `async*`. The yield-from-stream wiring is one line (`yield* session.sendAndStream(...)`), but consumers may notice a one-microtask delay before subscription. The single subscriber (session_service's `await for`) doesn't care — it would have yielded anyway.

3. **`detect()` and the pool's binary resolution**. `detect` currently caches `_resolvedPath` on the datasource; with the pool owning that cache, `detect()` either calls `_pool.someResolveMethod()` or duplicates the resolution. Cleanest: expose a small `Future<DetectionResult> detect()` helper on the pool (it's already where the binary lives), have the datasource's `detect()` delegate. Keeps the cache in one place.

4. **`_pendingApprovals` was keyed by `dynamic` (the JSON-RPC id)**. In the pool model that key needs to also disambiguate across sessions if the session-router ever emits cross-session — but it doesn't, because each session owns its stdout listener. So the key can stay as-is.

5. **`AIProviderDatasource.cancel(String)` is a breaking interface change**. There are exactly two implementers (Codex CLI, Claude CLI) and one consumer (session_service). All in our codebase. No third-party adapters. Safe to break.

## Out of scope (call out for follow-up)

- Per-session metrics (process RSS, JSON-RPC latency, parse failure rate) — easy to add once `CodexSession` exists, not needed for correctness.
- Auto-restart on Codex process crash — currently surfaces as `ProviderStreamFailure` and the user re-sends; restart logic could live on `CodexSession.dispose` listeners later.
- Persistent process pool across app restarts — Codex's own session store handles user-visible continuity via `--resume`/`resumeThreadId`; our pool is correctly process-only, not session-state.
- A pool-level cap on simultaneous processes — relies on idle eviction. Add a `maxConcurrent` cap if real-world usage shows users routinely keep 20+ chats hot within 10 minutes.

## Branching and commits

Land on the existing branch `fix/2026-05-06-tool-call-provider-model-badges`. Plan to split into commits:

1. `refactor(codex): extract CodexSession from CodexCliDatasourceProcess` — pure move, no behaviour change. One process, one chat, but still routed through the legacy adapter scalar fields. Tests for `CodexSession` only.
2. `feat(codex): introduce CodexSessionPool with idle eviction` — the multi-session win. AIProviderDatasource interface gains `sessionId` arg on `cancel` and `respondToPermissionRequest`. Pool tests.
3. `fix(claude-cli): track per-session processes for correct cancel routing` — Claude CLI's `Map<String, Process>` change.
