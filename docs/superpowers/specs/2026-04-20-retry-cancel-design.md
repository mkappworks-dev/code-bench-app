# Retry / Cancel — Spec

## Goal

Give users recovery options when a message gets no response: a Cancel button while the stream is in-flight, and hover actions (Retry, Edit, Delete) on the last user message after a failure or timeout.

---

## Scope

**In scope:**
- Cancel button in the input bar while a send is in-flight
- 60-second no-chunk timeout that auto-cancels the stream
- Hover actions on the last user message: Retry (re-sends immediately), Edit (populates input bar), Delete (removes from history)
- `deleteMessage` threaded through datasource → repository → service → notifier

**Out of scope:**
- Retry/edit for non-last messages
- Retry after session reload (persisted error state)
- Abort mid-stream once chunks have already started arriving (cancel only fires during the waiting period or on timeout)

---

## Architecture

### Cancel

`ChatMessagesNotifier.sendMessage` currently uses `await for` with no cancellation path. Replace with a `StreamSubscription` stored as `_activeSubscription`. A new `cancelSend()` method cancels the subscription and restores `AsyncData` with the pre-send message list.

`ChatInputBar` already tracks `_isSending` locally. When Cancel is tapped it calls `cancelSend()` and sets `_isSending = false`.

### 60-Second Timeout

Applied to the stream returned by `SessionService.sendAndStream` at the `ChatMessagesNotifier` level using `.timeout(const Duration(seconds: 60))`. A `TimeoutException` is caught and re-thrown as a `NetworkException('No response — the model may still be loading')` so the existing error path handles it.

### Hover Actions — Communication Channel

`_UserBubble` needs to communicate Retry/Edit intent to `ChatInputBar`, which are sibling widgets. Introduce a `PendingMessageActionNotifier` (`keepAlive: true`, session-keyed via `family`) that holds `MessageAction?`. `ChatInputBar` uses `ref.listen` to react to it.

```
MessageAction = retry(String content) | edit(String content)
```

`ref.listen(pendingMessageActionProvider(sessionId), (_, action) {
  if (action == null) return;
  _controller.text = action.content;
  ref.read(pendingMessageActionProvider(sessionId).notifier).clear();
  if (action is RetryAction) _send();   // auto-submits for retry
  // edit falls through — user modifies and submits manually
})
```

### Delete

`deleteMessage(sessionId, messageId)` is added at every layer:

```
SessionDao.deleteMessage(messageId)                  ← Drift
SessionDatasource.deleteMessage(sessionId, messageId)
SessionRepository.deleteMessage(sessionId, messageId)
SessionRepositoryImpl → delegates to datasource
SessionService.deleteMessage(sessionId, messageId)
ChatMessagesNotifier.deleteMessage(messageId)        ← calls service, removes from in-memory state
```

Widget taps `ref.read(chatMessagesProvider(sessionId).notifier).deleteMessage(messageId)`.

---

## UI Changes

### `ChatInputBar` — Send button area

While `_isSending`: render a Cancel button (amber text, `✕ Cancel` label) instead of the arrow send button. The cancel button calls `ref.read(chatMessagesProvider(sessionId).notifier).cancelSend()` then `setState(() => _isSending = false)`.

No change to the input field or chip row.

### `MessageBubble._UserBubble`

Convert to `ConsumerStatefulWidget`. Accept an `isLast` flag from the parent list. When `isLast` and hovering (`MouseRegion.onEnter/onExit`), show an action row floating above the bubble:

```
[ ↺ Retry ]  [ ✎ Edit ]  [ ✕ Delete ]
```

- **Retry** — sets `PendingMessageActionNotifier(sessionId)` to `MessageAction.retry(content)`
- **Edit** — sets it to `MessageAction.edit(content)`
- **Delete** — calls `chatMessagesProvider(sessionId).notifier.deleteMessage(messageId)`. Shows a confirmation only if the session has more than 2 messages (safeguard); otherwise deletes immediately.

The action row is only visible while `isLast && isHovered && !isSending`.

---

## Error Handling

- `cancelSend()` called on an already-completed stream: no-op (subscription is null after completion).
- `TimeoutException` in `sendMessage`: caught, wrapped as `NetworkException`, surfaces via existing snackbar path in `ChatInputBar`.
- `deleteMessage` failure: surfaces as snackbar via `ref.listen` on `chatMessagesProvider` `AsyncError`, same as existing send errors.

---

## Testing

- Unit — `ChatMessagesNotifier.cancelSend()`: verify state is restored to pre-send `AsyncData`
- Unit — `ChatMessagesNotifier` timeout: mock a stream that emits nothing for 61s; verify `NetworkException` is returned
- Unit — `ChatMessagesNotifier.deleteMessage()`: mock service; verify message removed from state
- Widget — `_UserBubble`: hover shows action row only when `isLast: true`; action row hidden when `isLast: false`
- Widget — `ChatInputBar`: Cancel button visible while `_isSending`; tapping calls `cancelSend()`
