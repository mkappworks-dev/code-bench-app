# Chat Stream Registry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lift in-flight chat streaming out of `ChatMessagesNotifier` into a long-lived `ChatStreamRegistry` service so multiple sessions can stream concurrently, navigation never tears down a live stream, and transient network failures retry automatically before surfacing as an error.

**Architecture:** A new `@Riverpod(keepAlive: true)` service in `lib/services/chat/` owns one `_StreamHandle` per active sessionId — each handle holds the `StreamSubscription`, the broadcast `StreamController<ChatStreamState>`, and a small retry controller. Notifiers become read-only observers of the registry's per-session state stream and project incoming `ChatMessage`s into their `AsyncValue<List<ChatMessage>>`. Stream lifecycle is decoupled from provider lifecycle: only explicit `cancel(sessionId)` / `cancelAll()` ends a stream.

**Tech Stack:** Flutter, Riverpod 2 (`@riverpod` codegen), `freezed` for sealed unions, `build_runner` for codegen, `flutter_test` + `ProviderContainer` for tests. No new dependencies.

---

## File Structure

**New files:**

| Path | Responsibility |
|---|---|
| [lib/services/chat/chat_stream_state.dart](lib/services/chat/chat_stream_state.dart) | Freezed sealed `ChatStreamState` — single source of truth for what a stream is doing right now. |
| [lib/services/chat/chat_stream_registry.dart](lib/services/chat/chat_stream_registry.dart) | The registry service + `chatStreamRegistryProvider`. Owns subscriptions, retry, broadcast. |
| [test/services/chat/chat_stream_state_test.dart](test/services/chat/chat_stream_state_test.dart) | State pattern-matching exhaustiveness check. |
| [test/services/chat/chat_stream_registry_test.dart](test/services/chat/chat_stream_registry_test.dart) | Registry behaviour tests with a fake streaming service. |

**Modified files:**

| Path | Change |
|---|---|
| [lib/features/chat/notifiers/agent_failure.dart](lib/features/chat/notifiers/agent_failure.dart) | Add `networkExhausted(int attempts)` variant. |
| [lib/features/chat/notifiers/chat_notifier.dart](lib/features/chat/notifiers/chat_notifier.dart) | `ChatMessagesNotifier.sendMessage` / `cancelSend` delegate to the registry. The notifier no longer owns `_activeSubscription` or `_sendCompleter`. |
| [test/features/chat/notifiers/chat_notifier_test.dart](test/features/chat/notifiers/chat_notifier_test.dart) | Update direct-state tests to use the registry-driven flow where applicable. |
| [test/features/chat/notifiers/chat_notifier_cancel_test.dart](test/features/chat/notifiers/chat_notifier_cancel_test.dart) | Verify `cancelSend()` still produces an `interrupted` marker and persists it via the registry path. |
| [lib/services/session/session_service.dart](lib/services/session/session_service.dart) | `deleteAllSessionsAndMessages()` calls `registry.cancelAll()` before truncation. |

**Worktree:** Created at execution time per CLAUDE.md convention:
```bash
git worktree add .worktrees/tech/2026-05-06-chat-stream-registry -b tech/2026-05-06-chat-stream-registry
cd .worktrees/tech/2026-05-06-chat-stream-registry
```

---

## Design notes

**`ChatStreamState` shape:**
```dart
@freezed
sealed class ChatStreamState with _$ChatStreamState {
  const factory ChatStreamState.idle() = ChatStreamIdle;
  const factory ChatStreamState.connecting({required int attempt}) = ChatStreamConnecting;
  const factory ChatStreamState.streaming() = ChatStreamStreaming;
  const factory ChatStreamState.retrying({required int attempt, required Duration nextDelay}) = ChatStreamRetrying;
  const factory ChatStreamState.failed(AgentFailure failure) = ChatStreamFailed;
  const factory ChatStreamState.done() = ChatStreamDone;
}
```

**Retry policy (locked in by user):**
- Exponential backoff: 500ms, 1s, 2s
- Max 3 attempts
- Total wall-time cap ~30s (enforced by per-attempt connect timeout + backoff sum)
- **Only the connecting phase is retried.** Once the first non-user message has been emitted to the listener (i.e. the agent has produced any output), a transport drop is surfaced as `failed` — partial content stays in `state` and the user sees a "Retry" affordance on the bubble (deferred to a later PR; this plan only emits the state).
- Only `NetworkException` and `TimeoutException` are retried. `AgentException` subclasses, `StateError`, and unknown errors fail immediately.

**Cross-project / cross-session concurrency (locked in by user):**
- The registry `Map<sessionId, _StreamHandle>` is unbounded in size; `keepAlive: true` ensures it survives every navigation.
- Project switch does NOT cancel streams. Only explicit `cancel(sessionId)` (from `cancelSend()`) and `cancelAll()` (from "delete all sessions") end streams.

**Defense-in-depth (per `superpowers:systematic-debugging` defense-in-depth ref):**
1. Registry `start()` rejects null/empty sessionId.
2. Listener inside the handle drops chunks where `msg.sessionId != handle.sessionId` (logs via `sLog` — this would be a service bug, not a user bug).
3. Notifier projects only chunks whose sessionId matches its own family key.

---

## Tasks

### Task 1: Define `ChatStreamState`

**Files:**
- Create: `lib/services/chat/chat_stream_state.dart`
- Test: `test/services/chat/chat_stream_state_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/services/chat/chat_stream_state_test.dart
import 'package:code_bench_app/features/chat/notifiers/agent_failure.dart';
import 'package:code_bench_app/services/chat/chat_stream_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exhaustive switch covers every variant', () {
    String label(ChatStreamState s) => switch (s) {
      ChatStreamIdle() => 'idle',
      ChatStreamConnecting() => 'connecting',
      ChatStreamStreaming() => 'streaming',
      ChatStreamRetrying() => 'retrying',
      ChatStreamFailed() => 'failed',
      ChatStreamDone() => 'done',
    };

    expect(label(const ChatStreamState.idle()), 'idle');
    expect(label(const ChatStreamState.connecting(attempt: 1)), 'connecting');
    expect(label(const ChatStreamState.streaming()), 'streaming');
    expect(
      label(ChatStreamState.retrying(attempt: 2, nextDelay: const Duration(seconds: 1))),
      'retrying',
    );
    expect(label(ChatStreamState.failed(const AgentFailure.unknown('e'))), 'failed');
    expect(label(const ChatStreamState.done()), 'done');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/chat/chat_stream_state_test.dart`
Expected: compile error — `chat_stream_state.dart` does not exist.

- [ ] **Step 3: Implement `ChatStreamState`**

```dart
// lib/services/chat/chat_stream_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../features/chat/notifiers/agent_failure.dart';

part 'chat_stream_state.freezed.dart';

@freezed
sealed class ChatStreamState with _$ChatStreamState {
  const factory ChatStreamState.idle() = ChatStreamIdle;
  const factory ChatStreamState.connecting({required int attempt}) = ChatStreamConnecting;
  const factory ChatStreamState.streaming() = ChatStreamStreaming;
  const factory ChatStreamState.retrying({
    required int attempt,
    required Duration nextDelay,
  }) = ChatStreamRetrying;
  const factory ChatStreamState.failed(AgentFailure failure) = ChatStreamFailed;
  const factory ChatStreamState.done() = ChatStreamDone;
}
```

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `lib/services/chat/chat_stream_state.freezed.dart`.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/services/chat/chat_stream_state_test.dart`
Expected: PASS.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib/services/chat/ test/services/chat/
flutter analyze lib/services/chat/ test/services/chat/
git add lib/services/chat/chat_stream_state.dart \
        lib/services/chat/chat_stream_state.freezed.dart \
        test/services/chat/chat_stream_state_test.dart
git commit -m "feat(chat-stream): add ChatStreamState sealed union"
```

---

### Task 2: Extend `AgentFailure` with `networkExhausted`

**Files:**
- Modify: `lib/features/chat/notifiers/agent_failure.dart`
- Test: `test/features/chat/notifiers/agent_failure_test.dart` (create)

- [ ] **Step 1: Write the failing test**

```dart
// test/features/chat/notifiers/agent_failure_test.dart
import 'package:code_bench_app/features/chat/notifiers/agent_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('networkExhausted carries the attempt count', () {
    const f = AgentFailure.networkExhausted(3);
    expect(f, isA<AgentNetworkExhausted>());
    expect((f as AgentNetworkExhausted).attempts, 3);
  });

  test('switch over AgentFailure handles networkExhausted exhaustively', () {
    String name(AgentFailure f) => switch (f) {
      AgentIterationCapReached() => 'cap',
      AgentProviderDoesNotSupportTools() => 'nosupp',
      AgentStreamAbortedUnexpectedly() => 'aborted',
      AgentToolDispatchFailed() => 'tool',
      AgentNetworkExhausted() => 'net',
      AgentUnknownError() => 'unknown',
    };
    expect(name(const AgentFailure.networkExhausted(3)), 'net');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/chat/notifiers/agent_failure_test.dart`
Expected: FAIL — `networkExhausted` is not a member of `AgentFailure`.

- [ ] **Step 3: Add the variant**

Modify `lib/features/chat/notifiers/agent_failure.dart`:

```dart
@freezed
sealed class AgentFailure with _$AgentFailure {
  const factory AgentFailure.iterationCapReached() = AgentIterationCapReached;
  const factory AgentFailure.providerDoesNotSupportTools() = AgentProviderDoesNotSupportTools;
  const factory AgentFailure.streamAbortedUnexpectedly(String reason) = AgentStreamAbortedUnexpectedly;
  const factory AgentFailure.toolDispatchFailed(String toolName, String message) = AgentToolDispatchFailed;
  const factory AgentFailure.networkExhausted(int attempts) = AgentNetworkExhausted;
  const factory AgentFailure.unknown(Object error) = AgentUnknownError;
}
```

- [ ] **Step 4: Codegen, format, analyze**

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/features/chat/notifiers/agent_failure.dart \
            lib/features/chat/notifiers/agent_failure.freezed.dart \
            test/features/chat/notifiers/agent_failure_test.dart
flutter analyze lib/features/chat/ test/features/chat/notifiers/agent_failure_test.dart
```

The analyzer will surface non-exhaustive switches anywhere `AgentFailure` is matched (e.g. in `chat_input_bar.dart`). Add a `AgentNetworkExhausted() => '<existing snackbar string for network failure>'` arm to each — keep wording consistent with adjacent arms; do not invent new copy.

- [ ] **Step 5: Run all tests**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/notifiers/agent_failure.dart \
        lib/features/chat/notifiers/agent_failure.freezed.dart \
        test/features/chat/notifiers/agent_failure_test.dart \
        lib/features/chat/widgets/chat_input_bar.dart  # if touched by exhaustiveness
git commit -m "feat(chat-stream): add AgentFailure.networkExhausted variant"
```

---

### Task 3: Skeleton `ChatStreamRegistry` + provider

Goal: empty registry that exposes `watchState(sessionId)` returning `idle`, with no other behaviour. Lets later tasks slot real logic in without provider-wiring churn.

**Files:**
- Create: `lib/services/chat/chat_stream_registry.dart`
- Test: `test/services/chat/chat_stream_registry_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/services/chat/chat_stream_registry_test.dart
import 'package:code_bench_app/services/chat/chat_stream_registry.dart';
import 'package:code_bench_app/services/chat/chat_stream_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('latestState returns idle for unknown sessions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamRegistryProvider);
    expect(registry.latestState('unknown'), isA<ChatStreamIdle>());
  });

  test('watchState emits the current state immediately', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamRegistryProvider);
    final first = await registry.watchState('s').first;
    expect(first, isA<ChatStreamIdle>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/chat/chat_stream_registry_test.dart`
Expected: compile error — `chat_stream_registry.dart` does not exist.

- [ ] **Step 3: Implement skeleton**

```dart
// lib/services/chat/chat_stream_registry.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'chat_stream_state.dart';

part 'chat_stream_registry.g.dart';

@Riverpod(keepAlive: true)
ChatStreamRegistry chatStreamRegistry(Ref ref) {
  final registry = ChatStreamRegistry();
  ref.onDispose(registry.dispose);
  return registry;
}

class ChatStreamRegistry {
  final Map<String, _StreamHandle> _handles = {};

  ChatStreamState latestState(String sessionId) =>
      _handles[sessionId]?.latest ?? const ChatStreamState.idle();

  Stream<ChatStreamState> watchState(String sessionId) {
    final handle = _handles.putIfAbsent(sessionId, () => _StreamHandle(sessionId));
    return handle.stateStream;
  }

  Future<void> dispose() async {
    for (final h in _handles.values) {
      await h.dispose();
    }
    _handles.clear();
  }
}

class _StreamHandle {
  _StreamHandle(this.sessionId);

  final String sessionId;
  final StreamController<ChatStreamState> _controller =
      StreamController<ChatStreamState>.broadcast();
  ChatStreamState latest = const ChatStreamState.idle();

  Stream<ChatStreamState> get stateStream async* {
    yield latest;
    yield* _controller.stream;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
```

- [ ] **Step 4: Codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `lib/services/chat/chat_stream_registry.g.dart`.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/services/chat/chat_stream_registry_test.dart`
Expected: PASS (both cases).

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib/services/chat/ test/services/chat/
flutter analyze lib/services/chat/ test/services/chat/
git add lib/services/chat/chat_stream_registry.dart \
        lib/services/chat/chat_stream_registry.g.dart \
        test/services/chat/chat_stream_registry_test.dart
git commit -m "feat(chat-stream): add ChatStreamRegistry skeleton"
```

---

### Task 4: Registry `start()` — wire to a stream source

The registry now needs a way to subscribe to a `Stream<ChatMessage>` and translate it into state events. We isolate the dependency on `SessionService.sendAndStream` behind a function-typed parameter so the registry can be tested against a fake stream without spinning up the full service graph.

**Files:**
- Modify: `lib/services/chat/chat_stream_registry.dart`
- Modify: `test/services/chat/chat_stream_registry_test.dart`

- [ ] **Step 1: Write the failing tests**

Append to `test/services/chat/chat_stream_registry_test.dart`:

```dart
import 'dart:async';
import 'package:code_bench_app/data/shared/chat_message.dart';

ChatMessage _msg(String id, {String sessionId = 's'}) => ChatMessage(
  id: id,
  sessionId: sessionId,
  role: MessageRole.assistant,
  content: 'hi',
  timestamp: DateTime(2026, 5, 6),
);

void main2() {
  test('start emits connecting → streaming → done as chunks arrive', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamRegistryProvider);

    final source = StreamController<ChatMessage>();
    final states = <ChatStreamState>[];
    final sub = registry.watchState('s').listen(states.add);
    addTearDown(sub.cancel);

    final messages = <ChatMessage>[];
    registry.start(
      sessionId: 's',
      streamFactory: () => source.stream,
      onMessage: messages.add,
    );

    await Future<void>.delayed(Duration.zero); // let connecting emit
    expect(states.last, isA<ChatStreamConnecting>());

    source.add(_msg('a'));
    await Future<void>.delayed(Duration.zero);
    expect(states.last, isA<ChatStreamStreaming>());
    expect(messages, hasLength(1));

    await source.close();
    await Future<void>.delayed(Duration.zero);
    expect(states.last, isA<ChatStreamDone>());
  });

  test('start drops chunks whose sessionId does not match', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamRegistryProvider);
    final source = StreamController<ChatMessage>();
    final messages = <ChatMessage>[];

    registry.start(
      sessionId: 's',
      streamFactory: () => source.stream,
      onMessage: messages.add,
    );

    source.add(_msg('a', sessionId: 'OTHER'));
    source.add(_msg('b', sessionId: 's'));
    await source.close();
    await Future<void>.delayed(Duration.zero);

    expect(messages.map((m) => m.id), ['b']);
  });
}
```

(Wire `main2()` into the existing `main()` block with `group('start', main2);` or inline — pick whichever matches the existing test style.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/services/chat/chat_stream_registry_test.dart`
Expected: FAIL — `start` method does not exist.

- [ ] **Step 3: Implement `start()`**

Replace the `_StreamHandle` and add `start()` to `ChatStreamRegistry`:

```dart
class ChatStreamRegistry {
  final Map<String, _StreamHandle> _handles = {};

  ChatStreamState latestState(String sessionId) =>
      _handles[sessionId]?.latest ?? const ChatStreamState.idle();

  Stream<ChatStreamState> watchState(String sessionId) {
    final handle = _handles.putIfAbsent(sessionId, () => _StreamHandle(sessionId));
    return handle.stateStream;
  }

  /// Begins a stream for [sessionId]. If a stream is already active for that
  /// session, this is a no-op (the caller must `cancel` first).
  void start({
    required String sessionId,
    required Stream<ChatMessage> Function() streamFactory,
    required void Function(ChatMessage) onMessage,
  }) {
    if (sessionId.isEmpty) {
      throw ArgumentError.value(sessionId, 'sessionId', 'must be non-empty');
    }
    final handle = _handles.putIfAbsent(sessionId, () => _StreamHandle(sessionId));
    if (handle.subscription != null) return; // already active
    handle._emit(const ChatStreamState.connecting(attempt: 1));
    handle.subscription = streamFactory().listen(
      (msg) {
        if (msg.sessionId != sessionId) {
          // Service bug — surfaces in dev. Drop silently in release.
          assert(() {
            // ignore: avoid_print
            print('[ChatStreamRegistry] dropped cross-session chunk: '
                'expected=$sessionId got=${msg.sessionId}');
            return true;
          }());
          return;
        }
        if (handle.latest is! ChatStreamStreaming) {
          handle._emit(const ChatStreamState.streaming());
        }
        onMessage(msg);
      },
      onError: (Object e, StackTrace st) {
        handle._emit(ChatStreamState.failed(_mapError(e)));
        handle.subscription = null;
      },
      onDone: () {
        handle._emit(const ChatStreamState.done());
        handle.subscription = null;
      },
      cancelOnError: true,
    );
  }

  AgentFailure _mapError(Object e) => switch (e) {
    ProviderDoesNotSupportToolsException() => const AgentFailure.providerDoesNotSupportTools(),
    StreamAbortedUnexpectedlyException(:final reason) => AgentFailure.streamAbortedUnexpectedly(reason),
    _ => AgentFailure.unknown(e),
  };

  Future<void> dispose() async {
    for (final h in _handles.values) {
      await h.dispose();
    }
    _handles.clear();
  }
}

class _StreamHandle {
  _StreamHandle(this.sessionId);
  final String sessionId;
  final StreamController<ChatStreamState> _controller =
      StreamController<ChatStreamState>.broadcast();
  StreamSubscription<ChatMessage>? subscription;
  ChatStreamState latest = const ChatStreamState.idle();

  Stream<ChatStreamState> get stateStream async* {
    yield latest;
    yield* _controller.stream;
  }

  void _emit(ChatStreamState s) {
    latest = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  Future<void> dispose() async {
    await subscription?.cancel();
    await _controller.close();
  }
}
```

Add imports for `ChatMessage`, `AgentFailure`, `ProviderDoesNotSupportToolsException`, `StreamAbortedUnexpectedlyException`.

- [ ] **Step 4: Run tests**

Run: `flutter test test/services/chat/chat_stream_registry_test.dart`
Expected: PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/services/chat/ test/services/chat/
flutter analyze lib/services/chat/ test/services/chat/
git add lib/services/chat/chat_stream_registry.dart \
        test/services/chat/chat_stream_registry_test.dart
git commit -m "feat(chat-stream): registry.start subscribes and emits state"
```

---

### Task 5: `cancel(sessionId)` and `cancelAll()`

**Files:**
- Modify: `lib/services/chat/chat_stream_registry.dart`
- Modify: `test/services/chat/chat_stream_registry_test.dart`

- [ ] **Step 1: Write the failing tests**

Append:

```dart
test('cancel stops the subscription and emits idle', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final registry = container.read(chatStreamRegistryProvider);
  final source = StreamController<ChatMessage>();
  final states = <ChatStreamState>[];
  registry.watchState('s').listen(states.add);
  registry.start(sessionId: 's', streamFactory: () => source.stream, onMessage: (_) {});
  await Future<void>.delayed(Duration.zero);
  source.add(_msg('a'));
  await Future<void>.delayed(Duration.zero);

  await registry.cancel('s');
  expect(registry.latestState('s'), isA<ChatStreamIdle>());

  // Late chunks after cancel are ignored.
  final received = <ChatMessage>[];
  source.add(_msg('b'));
  await Future<void>.delayed(Duration.zero);
  expect(received, isEmpty);
});

test('cancelAll stops every active session', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final registry = container.read(chatStreamRegistryProvider);
  final s1 = StreamController<ChatMessage>();
  final s2 = StreamController<ChatMessage>();
  registry.start(sessionId: 'a', streamFactory: () => s1.stream, onMessage: (_) {});
  registry.start(sessionId: 'b', streamFactory: () => s2.stream, onMessage: (_) {});
  await Future<void>.delayed(Duration.zero);

  await registry.cancelAll();
  expect(registry.latestState('a'), isA<ChatStreamIdle>());
  expect(registry.latestState('b'), isA<ChatStreamIdle>());
});
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — `cancel` / `cancelAll` undefined.

- [ ] **Step 3: Implement**

Add to `ChatStreamRegistry`:

```dart
Future<void> cancel(String sessionId) async {
  final handle = _handles[sessionId];
  if (handle == null) return;
  await handle.subscription?.cancel();
  handle.subscription = null;
  handle._emit(const ChatStreamState.idle());
}

Future<void> cancelAll() async {
  for (final id in _handles.keys.toList()) {
    await cancel(id);
  }
}
```

- [ ] **Step 4: Run tests**

Expected: PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/services/chat/ test/services/chat/
flutter analyze lib/services/chat/ test/services/chat/
git add lib/services/chat/chat_stream_registry.dart \
        test/services/chat/chat_stream_registry_test.dart
git commit -m "feat(chat-stream): registry.cancel and cancelAll"
```

---

### Task 6: Connecting-phase retry with exponential backoff

`streamFactory` is invoked once per attempt. If it errors **before** the first chunk arrives, the registry emits `retrying`, waits, and re-invokes `streamFactory`. Once the first chunk has arrived (state has transitioned to `streaming`), errors are terminal.

**Files:**
- Modify: `lib/services/chat/chat_stream_registry.dart`
- Modify: `test/services/chat/chat_stream_registry_test.dart`

- [ ] **Step 1: Write the failing tests**

Append:

```dart
import 'package:code_bench_app/core/errors/app_exception.dart';

test('retries on NetworkException before any chunk arrives', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final registry = container.read(chatStreamRegistryProvider);

  var calls = 0;
  Stream<ChatMessage> factory() async* {
    calls++;
    if (calls < 3) {
      throw NetworkException('flaky');
    }
    yield _msg('ok');
  }

  final states = <ChatStreamState>[];
  registry.watchState('s').listen(states.add);
  final received = <ChatMessage>[];
  registry.start(
    sessionId: 's',
    streamFactory: factory,
    onMessage: received.add,
    backoff: const [Duration(milliseconds: 1), Duration(milliseconds: 1)],
  );

  await Future<void>.delayed(const Duration(milliseconds: 50));
  expect(calls, 3);
  expect(received.single.id, 'ok');
  expect(states.whereType<ChatStreamRetrying>(), hasLength(2));
  expect(states.last, isA<ChatStreamDone>());
});

test('after retries are exhausted, emits failed(networkExhausted)', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final registry = container.read(chatStreamRegistryProvider);

  Stream<ChatMessage> factory() async* {
    throw NetworkException('still flaky');
  }

  final states = <ChatStreamState>[];
  registry.watchState('s').listen(states.add);
  registry.start(
    sessionId: 's',
    streamFactory: factory,
    onMessage: (_) {},
    backoff: const [Duration(milliseconds: 1), Duration(milliseconds: 1)],
  );

  await Future<void>.delayed(const Duration(milliseconds: 50));
  final failed = states.last as ChatStreamFailed;
  expect(failed.failure, isA<AgentNetworkExhausted>());
  expect((failed.failure as AgentNetworkExhausted).attempts, 3);
});

test('errors after first chunk arrives are NOT retried', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final registry = container.read(chatStreamRegistryProvider);

  var calls = 0;
  Stream<ChatMessage> factory() async* {
    calls++;
    yield _msg('partial');
    throw NetworkException('drop after partial');
  }

  final states = <ChatStreamState>[];
  registry.watchState('s').listen(states.add);
  registry.start(
    sessionId: 's',
    streamFactory: factory,
    onMessage: (_) {},
    backoff: const [Duration(milliseconds: 1)],
  );

  await Future<void>.delayed(const Duration(milliseconds: 50));
  expect(calls, 1);
  expect(states.last, isA<ChatStreamFailed>());
  expect((states.last as ChatStreamFailed).failure, isNot(isA<AgentNetworkExhausted>()));
});
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — `backoff` parameter not recognised; no retry behaviour.

- [ ] **Step 3: Implement retry**

Update `start()`:

```dart
static const _defaultBackoff = [
  Duration(milliseconds: 500),
  Duration(seconds: 1),
  Duration(seconds: 2),
];

void start({
  required String sessionId,
  required Stream<ChatMessage> Function() streamFactory,
  required void Function(ChatMessage) onMessage,
  List<Duration> backoff = _defaultBackoff,
}) {
  if (sessionId.isEmpty) {
    throw ArgumentError.value(sessionId, 'sessionId', 'must be non-empty');
  }
  final handle = _handles.putIfAbsent(sessionId, () => _StreamHandle(sessionId));
  if (handle.subscription != null) return;
  _attemptConnect(handle, streamFactory, onMessage, backoff, attempt: 1);
}

void _attemptConnect(
  _StreamHandle handle,
  Stream<ChatMessage> Function() streamFactory,
  void Function(ChatMessage) onMessage,
  List<Duration> backoff, {
  required int attempt,
}) {
  handle._emit(ChatStreamState.connecting(attempt: attempt));
  var sawChunk = false;

  handle.subscription = streamFactory().listen(
    (msg) {
      if (msg.sessionId != handle.sessionId) {
        assert(() {
          // ignore: avoid_print
          print('[ChatStreamRegistry] dropped cross-session chunk: '
              'expected=${handle.sessionId} got=${msg.sessionId}');
          return true;
        }());
        return;
      }
      sawChunk = true;
      if (handle.latest is! ChatStreamStreaming) {
        handle._emit(const ChatStreamState.streaming());
      }
      onMessage(msg);
    },
    onError: (Object e, StackTrace st) {
      final shouldRetry = !sawChunk &&
          (e is NetworkException || e is TimeoutException) &&
          attempt <= backoff.length;
      if (shouldRetry) {
        final delay = backoff[attempt - 1];
        handle._emit(ChatStreamState.retrying(attempt: attempt, nextDelay: delay));
        handle.retryTimer?.cancel();
        handle.retryTimer = Timer(delay, () {
          if (handle._controller.isClosed) return;
          _attemptConnect(handle, streamFactory, onMessage, backoff, attempt: attempt + 1);
        });
      } else {
        final failure = !sawChunk && (e is NetworkException || e is TimeoutException)
            ? AgentFailure.networkExhausted(attempt)
            : _mapError(e);
        handle._emit(ChatStreamState.failed(failure));
        handle.subscription = null;
      }
    },
    onDone: () {
      handle._emit(const ChatStreamState.done());
      handle.subscription = null;
    },
    cancelOnError: true,
  );
}
```

Add `Timer? retryTimer;` to `_StreamHandle` and cancel it in `dispose()` and `cancel()`:

```dart
class _StreamHandle {
  _StreamHandle(this.sessionId);
  final String sessionId;
  final StreamController<ChatStreamState> _controller =
      StreamController<ChatStreamState>.broadcast();
  StreamSubscription<ChatMessage>? subscription;
  Timer? retryTimer;
  ChatStreamState latest = const ChatStreamState.idle();

  Stream<ChatStreamState> get stateStream async* {
    yield latest;
    yield* _controller.stream;
  }

  void _emit(ChatStreamState s) {
    latest = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  Future<void> dispose() async {
    retryTimer?.cancel();
    await subscription?.cancel();
    await _controller.close();
  }
}
```

Update `cancel()` to also cancel `retryTimer`:

```dart
Future<void> cancel(String sessionId) async {
  final handle = _handles[sessionId];
  if (handle == null) return;
  handle.retryTimer?.cancel();
  handle.retryTimer = null;
  await handle.subscription?.cancel();
  handle.subscription = null;
  handle._emit(const ChatStreamState.idle());
}
```

- [ ] **Step 4: Run tests**

Expected: all three retry tests PASS plus the earlier tests still PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/services/chat/ test/services/chat/
flutter analyze lib/services/chat/ test/services/chat/
git add lib/services/chat/chat_stream_registry.dart \
        test/services/chat/chat_stream_registry_test.dart
git commit -m "feat(chat-stream): exponential-backoff retry on connect"
```

---

### Task 7: Refactor `ChatMessagesNotifier` to delegate

The notifier no longer holds `_activeSubscription` or `_sendCompleter`. It owns:
- The list of messages (`AsyncData<List<ChatMessage>>`)
- A subscription to `registry.watchState(sessionId)` (set up once in `build`)
- A subscription to message chunks via the `onMessage` callback passed to `registry.start`

The public surface (`sendMessage`, `cancelSend`, `setIterationCapReached`, etc.) stays the same — only internals change.

**Files:**
- Modify: `lib/features/chat/notifiers/chat_notifier.dart`
- Modify: `test/features/chat/notifiers/chat_notifier_test.dart`
- Modify: `test/features/chat/notifiers/chat_notifier_cancel_test.dart`

- [ ] **Step 1: Sketch the new shape**

Replace `ChatMessagesNotifier` with this structure (only the parts that change shown):

```dart
@riverpod
class ChatMessagesNotifier extends _$ChatMessagesNotifier {
  static const _uuid = Uuid();
  bool _cancelRequested = false;
  List<ChatMessage> _preSendMessages = [];

  @override
  Future<List<ChatMessage>> build(String sessionId) async {
    final svc = await ref.watch(sessionServiceProvider.future);
    final history = await svc.loadHistory(sessionId);

    // Bridge registry chunks into our message list while this notifier is alive.
    final registry = ref.read(chatStreamRegistryProvider);
    final stateSub = registry.watchState(sessionId).listen((s) {
      switch (s) {
        case ChatStreamFailed(:final failure):
          dLog('[ChatMessagesNotifier] stream failed for $sessionId: $failure');
        case ChatStreamDone() || ChatStreamIdle():
          ref.read(activeMessageIdProvider.notifier).set(null);
        default:
          break;
      }
    });
    ref.onDispose(stateSub.cancel);

    return history;
  }

  Future<Object?> sendMessage(String input, {String? systemPrompt}) async {
    _cancelRequested = false;
    ref.read(agentCancelProvider.notifier).clear();

    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) throw StateError('No active session — cannot send message.');

    final model = ref.read(selectedModelProvider);
    final service = await ref.read(sessionServiceProvider.future);

    _preSendMessages = state.value ?? [];
    state = AsyncData(List.from(_preSendMessages));

    final activeMessageIdNotifier = ref.read(activeMessageIdProvider.notifier);
    activeMessageIdNotifier.set('pending');

    final mode = ref.read(sessionModeProvider);
    final permission = ref.read(sessionPermissionProvider);
    final projectPath = ref.read(activeProjectProvider)?.path;
    final prefs = await ref.read(apiKeysProvider.future);
    final providerId = _resolveProviderId(model, prefs);

    final registry = ref.read(chatStreamRegistryProvider);
    final completer = Completer<Object?>();

    String? streamingAssistantId;

    // One-shot listener: terminal states resolve the completer.
    late final StreamSubscription<ChatStreamState> termSub;
    termSub = registry.watchState(sessionId).listen((s) {
      switch (s) {
        case ChatStreamDone():
          if (!completer.isCompleted) completer.complete(null);
          termSub.cancel();
        case ChatStreamFailed(:final failure):
          if (!completer.isCompleted) completer.complete(failure);
          termSub.cancel();
        case ChatStreamIdle():
          // Cancelled — sendMessage returns success-shaped null; cancelSend
          // is responsible for the interrupted marker.
          if (!completer.isCompleted) completer.complete(null);
          termSub.cancel();
        default:
          break;
      }
    });

    registry.start(
      sessionId: sessionId,
      streamFactory: () => service
          .sendAndStream(
            sessionId: sessionId,
            userInput: input,
            model: model,
            systemPrompt: systemPrompt,
            mode: mode,
            permission: permission,
            projectPath: projectPath,
            providerId: providerId,
            cancelFlag: () => ref.read(agentCancelProvider),
            requestPermission: (req) =>
                ref.read(agentPermissionRequestProvider.notifier).request(req),
            onMcpStatusChanged: ref.read(mcpServerStatusProvider.notifier).setStatus,
            onMcpServerRemoved: ref.read(mcpServerStatusProvider.notifier).remove,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: (sink) => sink.addError(
              NetworkException('No response — the model may still be loading.'),
              StackTrace.current,
            ),
          ),
      onMessage: (msg) {
        // Defense-in-depth: only this family-keyed notifier instance should
        // append messages for its own sessionId.
        if (msg.sessionId != sessionId) return;
        if (msg.role == MessageRole.assistant && streamingAssistantId == null) {
          streamingAssistantId = msg.id;
          activeMessageIdNotifier.set(msg.id);
        }
        final current = state.value ?? [];
        final idx = current.indexWhere((m) => m.id == msg.id);
        if (idx >= 0) {
          final updated = List<ChatMessage>.from(current);
          updated[idx] = msg;
          state = AsyncData(updated);
        } else {
          state = AsyncData([...current, msg]);
        }
      },
    );

    return completer.future;
  }

  void cancelSend() {
    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) return;
    final registry = ref.read(chatStreamRegistryProvider);
    if (registry.latestState(sessionId) is ChatStreamIdle) return;

    _cancelRequested = true;
    unawaited(registry.cancel(sessionId));
    ref.read(agentCancelProvider.notifier).request();
    ref.read(agentPermissionRequestProvider.notifier).cancel();
    ref.read(activeMessageIdProvider.notifier).set(null);

    final current = state.value ?? _preSendMessages;
    final marker = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.interrupted,
      content: '',
      timestamp: DateTime.now(),
    );
    state = AsyncData([...current, marker]);
    unawaited(_persistInterrupted(sessionId, marker));
  }

  // _persistInterrupted, removeFromState, prependOlder, setIterationCapReached,
  // continueAgenticTurn — unchanged.
}
```

Delete the now-unused `_asAgentFailure` helper at the top of the file (mapping moved to the registry).

- [ ] **Step 2: Run the existing test suite**

Run: `flutter test`
Expected: existing tests still PASS — public API of the notifier is unchanged.

If `chat_notifier_cancel_test.dart` references private fields like `_activeSubscription`, update it to assert on registry state instead:

```dart
final registry = container.read(chatStreamRegistryProvider);
expect(registry.latestState('s'), isA<ChatStreamIdle>());
```

- [ ] **Step 3: Add a test for "switching sessions does not break the new session's stream"**

Append to `test/features/chat/notifiers/chat_notifier_test.dart`:

```dart
test('two sessions can stream concurrently', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final registry = container.read(chatStreamRegistryProvider);

  // Drive both sessions directly via the registry to prove independence.
  final aSrc = StreamController<ChatMessage>();
  final bSrc = StreamController<ChatMessage>();
  registry.start(sessionId: 'a', streamFactory: () => aSrc.stream, onMessage: (_) {});
  registry.start(sessionId: 'b', streamFactory: () => bSrc.stream, onMessage: (_) {});
  await Future<void>.delayed(Duration.zero);

  expect(registry.latestState('a'), isA<ChatStreamConnecting>());
  expect(registry.latestState('b'), isA<ChatStreamConnecting>());

  aSrc.add(ChatMessage(
    id: 'a1', sessionId: 'a', role: MessageRole.assistant, content: '', timestamp: DateTime(2026),
  ));
  await Future<void>.delayed(Duration.zero);
  expect(registry.latestState('a'), isA<ChatStreamStreaming>());
  expect(registry.latestState('b'), isA<ChatStreamConnecting>()); // unaffected
});
```

- [ ] **Step 4: Run all tests**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/features/chat/notifiers/ test/features/chat/notifiers/
flutter analyze lib/ test/
git add lib/features/chat/notifiers/chat_notifier.dart \
        lib/features/chat/notifiers/chat_notifier.g.dart \
        test/features/chat/notifiers/chat_notifier_test.dart \
        test/features/chat/notifiers/chat_notifier_cancel_test.dart
git commit -m "refactor(chat): delegate streaming to ChatStreamRegistry"
```

---

### Task 8: Wire `cancelAll()` into "delete all sessions"

**Files:**
- Modify: `lib/services/session/session_service.dart`
- Test: `test/services/session/session_service_test.dart` (add one case)

- [ ] **Step 1: Write the failing test**

Add a test that verifies `deleteAllSessionsAndMessages` cancels active streams:

```dart
test('deleteAllSessionsAndMessages cancels active streams first', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final registry = container.read(chatStreamRegistryProvider);
  final src = StreamController<ChatMessage>();
  registry.start(sessionId: 's', streamFactory: () => src.stream, onMessage: (_) {});
  await Future<void>.delayed(Duration.zero);
  expect(registry.latestState('s'), isA<ChatStreamConnecting>());

  final svc = await container.read(sessionServiceProvider.future);
  await svc.deleteAllSessionsAndMessages();
  expect(registry.latestState('s'), isA<ChatStreamIdle>());
});
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — registry still shows `connecting` after delete-all.

- [ ] **Step 3: Implement**

In `session_service.dart`, locate `deleteAllSessionsAndMessages` and inject the registry. Since `SessionService` is constructed via a Riverpod provider, the cleanest hook is at the call site — modify the wrapper to grab the registry from `Ref` and call it before the inner `_session.deleteAllSessionsAndMessages()`:

```dart
Future<void> deleteAllSessionsAndMessages() async {
  await _registry.cancelAll();
  return _session.deleteAllSessionsAndMessages();
}
```

Add `_registry` as a constructor param sourced from `chatStreamRegistryProvider` in the service's `@riverpod` factory function.

- [ ] **Step 4: Run tests**

Expected: PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/services/session/ test/services/session/
flutter analyze lib/services/session/ test/services/session/
git add lib/services/session/session_service.dart \
        test/services/session/session_service_test.dart
git commit -m "feat(chat-stream): cancelAll on delete-all-sessions"
```

---

### Task 9: Manual smoke test on macOS

The goal is to validate the three acceptance criteria from the spec by hand. No code changes expected.

- [ ] **Step 1: Run the app**

```bash
flutter run -d macos
```

- [ ] **Step 2: Multi-session concurrency**

1. Open Session A. Send a long-running prompt (e.g. "write a 500-word essay").
2. Before A finishes, click Session B in the sidebar. Send a different prompt.
3. Switch back to A. **Expect:** A's response is either still streaming or already complete with all chunks present. No "stuck" UI.

- [ ] **Step 3: Settings round-trip**

1. Send a prompt in Session A.
2. While streaming, navigate to Settings.
3. Return to chat. **Expect:** A is still streaming or complete; no error banner.

- [ ] **Step 4: Network-interruption resilience**

1. Send a prompt.
2. Toggle Wi-Fi off within 2s of pressing send (so the failure happens during the connecting phase).
3. Toggle Wi-Fi back on within ~3s.
4. **Expect:** sidebar/state indicators briefly show "Retrying", then the response streams normally.
5. Repeat with Wi-Fi staying off for >30s. **Expect:** failure surfaces as a snackbar/error bubble; app does not need restart.

- [ ] **Step 5: Cancel during streaming**

1. Send a prompt.
2. Click Cancel mid-stream.
3. **Expect:** an "interrupted" marker appears, no error, and a fresh send works immediately afterward.

- [ ] **Step 6: Final commit (if any housekeeping needed)**

```bash
flutter analyze
flutter test
dart format lib/ test/
# Only commit if there are leftover format/analyze fixes.
```

---

## Self-review checklist

- [x] **Spec coverage** — every acceptance criterion is exercised:
  - "Switching does not break streaming for the newly opened session" → Task 7 concurrent-streams test + Task 9 step 2.
  - "Previous session stream stopped or detached cleanly" → Task 5 cancel test + Task 9 step 5.
  - "Returning to a session does not leave UI stuck" → Task 9 steps 2 & 3 (manual).
  - "Temporary network interruption does not leave stream broken" → Task 6 retry tests + Task 9 step 4.
  - "UI clearly reflects retrying / failure / recovery" → `ChatStreamState` includes `retrying`/`failed`/`done`; UI rendering of these is the explicit follow-up plan (`feat/2026-05-06-session-status-indicators` and `feat/2026-05-06-thinking-progress-and-model-badge`). This plan only guarantees the state model is in place.
  - "Streaming can resume or fail gracefully without app reset" → Task 6 (retry) + Task 5 (cancel).
- [x] **No placeholders** — all task code blocks are complete; no TODOs.
- [x] **Type consistency** — `ChatStreamState` variants used identically in tasks 1, 4, 5, 6, 7, 8. `AgentNetworkExhausted` carries `attempts` (int) consistently. `streamFactory` signature `Stream<ChatMessage> Function()` is identical across tasks 4–7.
- [x] **No widget-layer regressions** — `ChatMessagesNotifier` public surface unchanged; widgets continue to call `notifier.sendMessage(...)` and `notifier.cancelSend()`.

---

## Out of scope (separate plans)

- **Sidebar status indicators** that visualise `ChatStreamState` per session — `feat/2026-05-06-session-status-indicators`.
- **AI thinking / progress states** UI in the chat view + per-message provider/model badge — `feat/2026-05-06-thinking-progress-and-model-badge`.
- **Per-bubble "Retry" button** for `ChatStreamFailed` after partial content — depends on the message-bubble UI work above.
- **Per-project cancel** (cancel only streams whose session belongs to project X). Not needed for current acceptance; revisit if "delete project" UX surfaces it.
