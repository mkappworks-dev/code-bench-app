# Retry / Cancel — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Cancel button while a send is in-flight, a 60-second no-chunk timeout, and hover actions (Retry, Edit, Delete) on the last user message for recovery after failure.

**Architecture:** `sendMessage` in `ChatMessagesNotifier` is refactored from `await for` to `StreamSubscription` so it can be cancelled. A new `PendingMessageActionNotifier` (family by sessionId) acts as a communication channel between message bubble hover actions and `ChatInputBar`. `deleteMessage` is threaded through all four layers: Drift DAO → datasource → repository → service → notifier.

**Tech Stack:** Flutter/Dart, Riverpod (`riverpod_annotation`), Drift, `flutter_test`, `build_runner`

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Modify | `lib/data/_core/app_database.dart` | Add `SessionDao.deleteMessage(String id)` |
| Modify | `lib/data/session/datasource/session_datasource.dart` | Add `deleteMessage` to interface |
| Modify | `lib/data/session/datasource/session_datasource_drift.dart` | Implement `deleteMessage` |
| Modify | `lib/data/session/repository/session_repository.dart` | Add `deleteMessage` to interface |
| Modify | `lib/data/session/repository/session_repository_impl.dart` | Delegate to datasource |
| Modify | `lib/services/session/session_service.dart` | Add `deleteMessage` |
| Modify | `lib/features/chat/notifiers/chat_notifier.dart` | `cancelSend()`, `deleteMessage()`, `StreamSubscription`, timeout |
| Create | `lib/features/chat/notifiers/pending_message_action_notifier.dart` | Retry/Edit communication channel |
| Create | `lib/features/chat/notifiers/pending_message_action_notifier.g.dart` | Generated — do not edit |
| Modify | `lib/features/chat/widgets/message_bubble.dart` | Hover actions on `_UserBubble` |
| Modify | `lib/features/chat/widgets/chat_input_bar.dart` | Cancel button, listen for pending actions |
| Create | `test/features/chat/notifiers/chat_notifier_cancel_test.dart` | Cancel + timeout unit tests |
| Modify | `test/features/chat/widgets/message_bubble_test.dart` | Hover actions widget tests |
| Modify | `test/features/chat/widgets/chat_input_bar_test.dart` | Cancel button widget test |

---

## Task 1: Add `deleteMessage` through the data stack

**Files:**
- Modify: `lib/data/_core/app_database.dart`
- Modify: `lib/data/session/datasource/session_datasource.dart`
- Modify: `lib/data/session/datasource/session_datasource_drift.dart`
- Modify: `lib/data/session/repository/session_repository.dart`
- Modify: `lib/data/session/repository/session_repository_impl.dart`
- Modify: `lib/services/session/session_service.dart`

- [ ] **Step 1: Add `deleteMessage` to `SessionDao`**

In `lib/data/_core/app_database.dart`, add inside `SessionDao` after `insertMessage`:

```dart
Future<void> deleteMessage(String id) =>
    (delete(chatMessages)..where((t) => t.id.equals(id))).go();
```

- [ ] **Step 2: Add `deleteMessage` to the datasource interface**

In `lib/data/session/datasource/session_datasource.dart`, add after `persistMessage`:

```dart
Future<void> deleteMessage(String sessionId, String messageId);
```

- [ ] **Step 3: Implement in `SessionDatasourceDrift`**

In `lib/data/session/datasource/session_datasource_drift.dart`, add after `persistMessage`:

```dart
@override
Future<void> deleteMessage(String sessionId, String messageId) =>
    _db.sessionDao.deleteMessage(messageId);
```

- [ ] **Step 4: Add to `SessionRepository` interface**

In `lib/data/session/repository/session_repository.dart`, add after `persistMessage`:

```dart
Future<void> deleteMessage(String sessionId, String messageId);
```

- [ ] **Step 5: Implement in `SessionRepositoryImpl`**

In `lib/data/session/repository/session_repository_impl.dart`, add after `persistMessage`:

```dart
@override
Future<void> deleteMessage(String sessionId, String messageId) =>
    _ds.deleteMessage(sessionId, messageId);
```

- [ ] **Step 6: Add to `SessionService`**

In `lib/services/session/session_service.dart`, add after the `deleteSession` delegation:

```dart
Future<void> deleteMessage(String sessionId, String messageId) =>
    _session.deleteMessage(sessionId, messageId);
```

- [ ] **Step 7: Verify**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add lib/data/_core/app_database.dart \
        lib/data/session/datasource/session_datasource.dart \
        lib/data/session/datasource/session_datasource_drift.dart \
        lib/data/session/repository/session_repository.dart \
        lib/data/session/repository/session_repository_impl.dart \
        lib/services/session/session_service.dart
git commit -m "feat(session): add deleteMessage through data stack"
```

---

## Task 2: Refactor `sendMessage` to `StreamSubscription` + cancel + timeout

**Files:**
- Modify: `lib/features/chat/notifiers/chat_notifier.dart`
- Create: `test/features/chat/notifiers/chat_notifier_cancel_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/chat/notifiers/chat_notifier_cancel_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/services/session/session_service.dart';

// ── Fake SessionService ───────────────────────────────────────────────────────

class _FakeSessionService extends Fake implements SessionService {
  final StreamController<ChatMessage> controller = StreamController();
  bool sendCalled = false;
  bool deleteMessageCalled = false;
  String? deletedMessageId;

  @override
  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
  }) {
    sendCalled = true;
    return controller.stream;
  }

  @override
  Future<void> deleteMessage(String sessionId, String messageId) async {
    deleteMessageCalled = true;
    deletedMessageId = messageId;
  }

  @override
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) async => [];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(_FakeSessionService svc) {
  return ProviderContainer(
    overrides: [
      sessionServiceProvider.overrideWith((ref) async => svc),
      activeSessionIdProvider.overrideWith((ref) => 'session-1'),
      selectedModelProvider.overrideWith((ref) => AIModels.claude35Sonnet),
    ],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ChatMessagesNotifier.cancelSend', () {
    test('restores state to pre-send messages when cancelled', () async {
      final svc = _FakeSessionService();
      final container = _makeContainer(svc);
      addTearDown(container.dispose);

      // Prime the notifier with an initial empty state.
      await container.read(chatMessagesProvider('session-1').future);

      // Start a send — stream never emits.
      unawaited(
        container.read(chatMessagesProvider('session-1').notifier).sendMessage('hello'),
      );
      await Future.microtask(() {}); // let sendMessage start

      // Cancel.
      container.read(chatMessagesProvider('session-1').notifier).cancelSend();
      await Future.microtask(() {});

      // State is AsyncData (not AsyncError, not AsyncLoading).
      final state = container.read(chatMessagesProvider('session-1'));
      expect(state, isA<AsyncData<List<ChatMessage>>>());
    });
  });

  group('ChatMessagesNotifier.deleteMessage', () {
    test('removes message from in-memory state and calls service', () async {
      final svc = _FakeSessionService();
      final container = _makeContainer(svc);
      addTearDown(container.dispose);

      // Seed with a known message.
      final msg = ChatMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        role: MessageRole.user,
        content: 'hello',
        timestamp: DateTime(2026),
      );
      // Set state directly.
      container
          .read(chatMessagesProvider('session-1').notifier)
          .state = AsyncData([msg]);

      await container
          .read(chatMessagesProvider('session-1').notifier)
          .deleteMessage('msg-1');

      expect(container.read(chatMessagesProvider('session-1')).value, isEmpty);
      expect(svc.deleteMessageCalled, isTrue);
      expect(svc.deletedMessageId, 'msg-1');
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/features/chat/notifiers/chat_notifier_cancel_test.dart
```

Expected: compilation error — `cancelSend` and `deleteMessage` do not exist yet.

- [ ] **Step 3: Refactor `sendMessage` and add `cancelSend` and `deleteMessage`**

In `lib/features/chat/notifiers/chat_notifier.dart`, update `ChatMessagesNotifier`:

Add at the top of the class:

```dart
StreamSubscription<ChatMessage>? _activeSubscription;
List<ChatMessage> _preSendMessages = [];
```

Replace the `sendMessage` method:

```dart
Future<Object?> sendMessage(String input, {String? systemPrompt}) async {
  final sessionId = ref.read(activeSessionIdProvider);
  if (sessionId == null) throw StateError('No active session — cannot send message.');

  final model = ref.read(selectedModelProvider);
  final service = await ref.read(sessionServiceProvider.future);

  _preSendMessages = state.value ?? [];
  state = AsyncData(List.from(_preSendMessages));

  final activeMessageIdNotifier = ref.read(activeMessageIdProvider.notifier);
  String? streamingAssistantId;
  final completer = Completer<Object?>();

  _activeSubscription = service
      .sendAndStream(
        sessionId: sessionId,
        userInput: input,
        model: model,
        systemPrompt: systemPrompt,
      )
      .timeout(
        const Duration(seconds: 60),
        onTimeout: (sink) => sink.addError(
          NetworkException('No response — the model may still be loading.'),
          StackTrace.current,
        ),
      )
      .listen(
    (msg) {
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
    onError: (Object e, StackTrace st) {
      dLog('[sendMessage] stream error: $e\n$st');
      state = AsyncError(e, st);
      state = AsyncData(_preSendMessages);
      if (!completer.isCompleted) completer.complete(e);
    },
    onDone: () {
      if (!completer.isCompleted) completer.complete(null);
    },
    cancelOnError: true,
  );

  final result = await completer.future;
  _activeSubscription = null;
  if (streamingAssistantId != null) activeMessageIdNotifier.set(null);
  return result;
}

void cancelSend() {
  _activeSubscription?.cancel();
  _activeSubscription = null;
  state = AsyncData(List.from(_preSendMessages));
}
```

Add the `deleteMessage` method:

```dart
Future<void> deleteMessage(String messageId) async {
  final sessionId = ref.read(activeSessionIdProvider);
  if (sessionId == null) return;
  try {
    final service = await ref.read(sessionServiceProvider.future);
    await service.deleteMessage(sessionId, messageId);
    final current = state.value ?? [];
    state = AsyncData(current.where((m) => m.id != messageId).toList());
  } catch (e, st) {
    dLog('[ChatMessagesNotifier] deleteMessage failed: $e');
    state = AsyncError(e, st);
    state = AsyncData(state.value ?? []);
  }
}
```

Add the missing import at the top of `chat_notifier.dart`:

```dart
import 'dart:async';
import '../../../core/errors/app_exception.dart';
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/chat/notifiers/chat_notifier_cancel_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/notifiers/chat_notifier.dart \
        test/features/chat/notifiers/chat_notifier_cancel_test.dart
git commit -m "feat(chat): add cancelSend, deleteMessage, and 60s timeout to ChatMessagesNotifier"
```

---

## Task 3: Create `PendingMessageActionNotifier`

**Files:**
- Create: `lib/features/chat/notifiers/pending_message_action_notifier.dart`
- Create: `lib/features/chat/notifiers/pending_message_action_notifier.g.dart` (generated)

- [ ] **Step 1: Create the notifier**

```dart
// lib/features/chat/notifiers/pending_message_action_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_message_action_notifier.g.dart';

sealed class MessageAction {
  const MessageAction(this.content);
  final String content;
}

final class RetryAction extends MessageAction {
  const RetryAction(super.content);
}

final class EditAction extends MessageAction {
  const EditAction(super.content);
}

@Riverpod(keepAlive: true)
class PendingMessageActionNotifier extends _$PendingMessageActionNotifier {
  @override
  MessageAction? build(String sessionId) => null;

  void retry(String content) => state = RetryAction(content);
  void edit(String content) => state = EditAction(content);
  void clear() => state = null;
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/features/chat/notifiers/pending_message_action_notifier.g.dart` created.

- [ ] **Step 3: Verify**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/notifiers/pending_message_action_notifier.dart \
        lib/features/chat/notifiers/pending_message_action_notifier.g.dart
git commit -m "feat(chat): add PendingMessageActionNotifier for retry/edit communication"
```

---

## Task 4: Add hover actions to `_UserBubble`

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`

- [ ] **Step 1: Update `MessageBubble` to accept `isLast` and `sessionId`**

In `lib/features/chat/widgets/message_bubble.dart`, update the `MessageBubble` class:

```dart
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.sessionId,
    this.isLast = false,
  });

  final ChatMessage message;
  final String sessionId;
  final bool isLast;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _isUser
          ? _UserBubble(message: message, sessionId: sessionId, isLast: isLast)
          : _AssistantBubble(message: message),
    );
  }
}
```

- [ ] **Step 2: Convert `_UserBubble` to `ConsumerStatefulWidget` with hover detection**

Replace the `_UserBubble` class entirely:

```dart
class _UserBubble extends ConsumerStatefulWidget {
  const _UserBubble({
    required this.message,
    required this.sessionId,
    required this.isLast,
  });

  final ChatMessage message;
  final String sessionId;
  final bool isLast;

  @override
  ConsumerState<_UserBubble> createState() => _UserBubbleState();
}

class _UserBubbleState extends ConsumerState<_UserBubble> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: c.userBubbleFill,
                  border: Border.all(color: c.userBubbleStroke),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(color: c.userBubbleHighlight, blurRadius: 0, offset: const Offset(0, 1)),
                  ],
                ),
                child: SelectableText(
                  widget.message.content,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: ThemeConstants.uiFontSize,
                    height: 1.5,
                  ),
                ),
              ),
              if (widget.isLast && _hovered) _ActionRow(message: widget.message, sessionId: widget.sessionId, c: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.message, required this.sessionId, required this.c});

  final ChatMessage message;
  final String sessionId;
  final AppColors c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: -28,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: c.panelBackground,
          border: Border.all(color: c.subtleBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              label: '↺ Retry',
              color: c.textSecondary,
              onTap: () => ref
                  .read(pendingMessageActionProvider(sessionId).notifier)
                  .retry(message.content),
            ),
            _ActionButton(
              label: '✎ Edit',
              color: c.textSecondary,
              onTap: () => ref
                  .read(pendingMessageActionProvider(sessionId).notifier)
                  .edit(message.content),
            ),
            _ActionButton(
              label: '✕ Delete',
              color: c.warning, // use whatever danger/error color token AppColors exposes
              onTap: () => ref
                  .read(chatMessagesProvider(sessionId).notifier)
                  .deleteMessage(message.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: ThemeConstants.uiFontSizeSmall,
          ),
        ),
      ),
    );
  }
}
```

Add import at top of `message_bubble.dart`:

```dart
import '../notifiers/pending_message_action_notifier.dart';
```

- [ ] **Step 3: Fix all call sites of `MessageBubble` to pass `sessionId` and `isLast`**

Search for all uses of `MessageBubble(`:

```bash
grep -rn "MessageBubble(" lib/ --include="*.dart"
```

For each call site, add the required `sessionId` parameter. The parent list widget has the session ID (it's usually passed in via the widget constructor). For the `isLast` parameter, pass `true` only for the last message in the list:

```dart
// Example: building the list of bubbles
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) => MessageBubble(
    message: messages[index],
    sessionId: sessionId,
    isLast: index == messages.length - 1,
  ),
)
```

Adapt to whatever the actual list-building code looks like at each call site.

- [ ] **Step 4: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 5: Run tests**

```bash
flutter test
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/widgets/message_bubble.dart
git commit -m "feat(chat): add hover retry/edit/delete actions to last user message bubble"
```

---

## Task 5: Add Cancel button and pending action listener to `ChatInputBar`

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar.dart`

- [ ] **Step 1: Add import**

At the top of `lib/features/chat/widgets/chat_input_bar.dart`, add:

```dart
import '../notifiers/pending_message_action_notifier.dart';
```

- [ ] **Step 2: Add `ref.listen` for `PendingMessageActionNotifier` in `build()`**

Inside `build()`, add after the existing `ref.listen` calls:

```dart
ref.listen(pendingMessageActionProvider(widget.sessionId), (_, action) {
  if (action == null) return;
  ref.read(pendingMessageActionProvider(widget.sessionId).notifier).clear();
  _controller.text = action.content;
  _controller.selection = TextSelection.collapsed(offset: action.content.length);
  if (action is RetryAction) {
    _send();
  } else {
    _focusNode.requestFocus();
  }
});
```

- [ ] **Step 3: Replace the send button with a Cancel/Send toggle**

Find the send button widget in `build()`. It currently looks like:

```dart
onTap: _isSending ? null : _send,
```

Replace the entire send button area so that when `_isSending` is true, a Cancel button appears instead. Find the `GestureDetector` or `InkWell` that wraps the send icon/arrow and replace it:

```dart
if (_isSending)
  GestureDetector(
    onTap: () {
      ref.read(chatMessagesProvider(widget.sessionId).notifier).cancelSend();
      setState(() => _isSending = false);
    },
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: c.glassFill,
        border: Border.all(color: c.glassBorder),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(
        '✕',
        style: TextStyle(color: c.warning, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
      ),
    ),
  )
else
  // existing send button widget unchanged
```

- [ ] **Step 4: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/widgets/chat_input_bar.dart
git commit -m "feat(chat): add Cancel button and pending retry/edit action listener to ChatInputBar"
```

---

## Task 6: Final checks

- [ ] **Step 1: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 3: Format**

```bash
dart format lib/ test/
```

- [ ] **Step 4: Launch and smoke-test**

```bash
flutter run -d macos
```

Verify:
1. Send a message — while waiting, the send arrow swaps to `✕ Cancel`
2. Tap Cancel — stream stops, state restored, input re-enabled
3. Send a message to an offline/slow endpoint — after 60s no response, error snackbar appears
4. Hover the last user message — action row appears with Retry / Edit / Delete
5. Tap **Retry** — message text populates and is auto-sent
6. Tap **Edit** — message text populates the input bar, cursor at end, user modifies and sends
7. Tap **Delete** — message disappears from the chat history
8. Hover a non-last message — no action row appears

- [ ] **Step 5: Commit formatting if changed**

```bash
git add -p
git commit -m "style: dart format after retry/cancel"
```
