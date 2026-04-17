# Per-Session Settings Persistence — Design Spec

## Goal

Persist model, system prompt, mode (chat/plan/act), effort (low/medium/high/max), and permission (read-only/ask-before/full-access) per chat session. When the user switches sessions, all five settings restore to what they were when that session was last active.

## Background

All five settings live today as widget-local `setState` fields in `ChatInputBar` (`_mode`, `_effort`, `_permission`) or as global in-memory Riverpod notifiers (`SelectedModelNotifier`, `SessionSystemPromptNotifier`). None are persisted to the database. Switching sessions resets mode/effort/permission to their defaults and keeps whatever model was last selected globally — not what was set for that specific session.

---

## Section 1 — Data Layer

### 1.1 Shared enums

New file: `lib/data/session/models/session_settings.dart`

```dart
enum ChatMode { chat, plan, act }
enum ChatEffort { low, medium, high, max }
enum ChatPermission { readOnly, askBefore, fullAccess }
```

Serialized as the enum's `.name` string (`'chat'`, `'plan'`, `'act'`, etc.) in the database. `ChatInputBar` imports these and removes its private `_Mode`, `_Effort`, `_Permission` enums.

### 1.2 Database schema — migration 5 → 6

`lib/data/_core/app_database.dart`

Add to the `ChatSessions` Drift table:

```dart
TextColumn get systemPrompt => text().nullable()();
TextColumn get mode       => text().nullable()();   // ChatMode.name
TextColumn get effort     => text().nullable()();   // ChatEffort.name
TextColumn get permission => text().nullable()();   // ChatPermission.name
```

Bump `schemaVersion` to 6 and add migration:

```dart
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 6) {
      await m.addColumn(chatSessions, chatSessions.systemPrompt);
      await m.addColumn(chatSessions, chatSessions.mode);
      await m.addColumn(chatSessions, chatSessions.effort);
      await m.addColumn(chatSessions, chatSessions.permission);
    }
  },
);
```

All four columns are nullable — existing sessions keep `null` and the notifier falls back to defaults (see Section 2).

### 1.3 `AIModels.fromId()`

New static helper in `lib/data/shared/ai_model.dart`:

```dart
static AIModel? fromId(String modelId) =>
    defaults.firstWhereOrNull((m) => m.modelId == modelId);
```

### 1.4 Datasource — `session_datasource_drift.dart`

New methods:

```dart
Future<ChatSession?> getSession(String sessionId);
Future<void> updateSessionModel(String sessionId, String modelId);
Future<void> updateSessionSystemPrompt(String sessionId, String prompt);
Future<void> updateSessionMode(String sessionId, String mode);
Future<void> updateSessionEffort(String sessionId, String effort);
Future<void> updateSessionPermission(String sessionId, String permission);
```

Each update is a single `UPDATE chat_sessions SET <col> = ? WHERE session_id = ?`.

### 1.5 Repository + Service

Same six methods plumbed through `SessionRepository` (interface) → `SessionRepositoryImpl` → `SessionService`.

---

## Section 2 — Notifier Layer

### 2.1 Three new Riverpod notifiers

Added to `lib/features/chat/notifiers/chat_notifier.dart` alongside the existing `SelectedModelNotifier` and `SessionSystemPromptNotifier`:

```dart
@Riverpod(keepAlive: true)
class SessionModeNotifier extends _$SessionModeNotifier {
  @override ChatMode build() => ChatMode.chat;
  void set(ChatMode v) => state = v;
}

@Riverpod(keepAlive: true)
class SessionEffortNotifier extends _$SessionEffortNotifier {
  @override ChatEffort build() => ChatEffort.high;
  void set(ChatEffort v) => state = v;
}

@Riverpod(keepAlive: true)
class SessionPermissionNotifier extends _$SessionPermissionNotifier {
  @override ChatPermission build() => ChatPermission.fullAccess;
  void set(ChatPermission v) => state = v;
}
```

### 2.2 `SessionSettingsActions`

New file: `lib/features/chat/notifiers/session_settings_actions.dart`

```dart
@Riverpod(keepAlive: true)
class SessionSettingsActions extends _$SessionSettingsActions {
  @override
  FutureOr<void> build() {
    ref.listen(activeSessionIdProvider, (_, sessionId) {
      if (sessionId != null) _loadForSession(sessionId);
    });
  }

  Future<void> _loadForSession(String sessionId) async {
    final session = await ref.read(sessionServiceProvider).getSession(sessionId);
    if (session == null) return;

    final model = session.modelId != null
        ? AIModels.fromId(session.modelId!) ?? ref.read(selectedModelProvider)
        : ref.read(selectedModelProvider);
    ref.read(selectedModelProvider.notifier).select(model);
    ref.read(sessionSystemPromptProvider.notifier)
        .setPrompt(sessionId, session.systemPrompt ?? '');
    ref.read(sessionModeProvider.notifier)
        .set(ChatMode.values.byNameOrNull(session.mode) ?? ChatMode.chat);
    ref.read(sessionEffortProvider.notifier)
        .set(ChatEffort.values.byNameOrNull(session.effort) ?? ChatEffort.high);
    ref.read(sessionPermissionProvider.notifier)
        .set(ChatPermission.values.byNameOrNull(session.permission) ?? ChatPermission.fullAccess);
  }

  Future<void> updateModel(String sessionId, AIModel model) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        ref.read(selectedModelProvider.notifier).select(model);
        await ref.read(sessionServiceProvider).updateSessionModel(sessionId, model.modelId);
      } catch (e, st) { Error.throwWithStackTrace(_asFailure(e), st); }
    });
  }

  Future<void> updateSystemPrompt(String sessionId, String prompt) async { ... }
  Future<void> updateMode(String sessionId, ChatMode mode) async { ... }
  Future<void> updateEffort(String sessionId, ChatEffort effort) async { ... }
  Future<void> updatePermission(String sessionId, ChatPermission permission) async { ... }

  SessionSettingsFailure _asFailure(Object e) =>
      SessionSettingsFailure.unknown(e);
}
```

Each `update*` writes to the reactive notifier first (instant UI response), then persists to DB. A failure reverts the `AsyncValue` to `AsyncError`; the widget listens and shows a snackbar.

### 2.3 `SessionSettingsFailure`

New file: `lib/features/chat/notifiers/session_settings_failure.dart`

```dart
@freezed
sealed class SessionSettingsFailure with _$SessionSettingsFailure {
  const factory SessionSettingsFailure.unknown(Object error) = SessionSettingsUnknownFailure;
}
```

### 2.4 Bootstrap

`SessionSettingsActions` must be eagerly initialized so it reacts to the first session load. Add `ref.read(sessionSettingsActionsProvider)` in the app bootstrap (or in `ChatScreen.build`).

---

## Section 3 — Widget Changes

### 3.1 `ChatInputBar`

**Remove:** private enums `_Mode`, `_Effort`, `_Permission` and their local fields `_mode`, `_effort`, `_permission`.

**Replace local state reads with `ref.watch`:**

```dart
final mode       = ref.watch(sessionModeProvider);
final effort     = ref.watch(sessionEffortProvider);
final permission = ref.watch(sessionPermissionProvider);
```

**Replace `setState` on change with `SessionSettingsActions`:**

```dart
// was: setState(() => _mode = value)
ref.read(sessionSettingsActionsProvider.notifier).updateMode(widget.sessionId, value);

// was: setState(() => _effort = value)
ref.read(sessionSettingsActionsProvider.notifier).updateEffort(widget.sessionId, value);

// was: setState(() => _permission = value)
ref.read(sessionSettingsActionsProvider.notifier).updatePermission(widget.sessionId, value);

// was: ref.read(selectedModelProvider.notifier).select(value)
ref.read(sessionSettingsActionsProvider.notifier).updateModel(widget.sessionId, value);
```

**Remove from `didUpdateWidget`:** The comment "Effort/mode/permission stay untouched" is no longer valid — the load happens via `SessionSettingsActions` reacting to `activeSessionIdProvider`.

**Add `ref.listen` for error display:**

```dart
ref.listen(sessionSettingsActionsProvider, (_, next) {
  if (next is! AsyncError) return;
  if (next.error is! SessionSettingsFailure) return;
  showErrorSnackBar(context, 'Could not save session settings.');
});
```

---

## Data Flow

```
User taps session in sidebar
  → ActiveSessionIdNotifier.set(sessionId)
  → SessionSettingsActions._loadForSession(sessionId)
  → reads ChatSession from DB
  → pushes model/systemPrompt/mode/effort/permission to their notifiers
  → ChatInputBar rebuilds showing the session's saved settings

User changes model/mode/effort/permission in ChatInputBar
  → SessionSettingsActions.update*(sessionId, value)
  → notifier updated instantly (no flicker)
  → DB persisted async
```

---

## Out of Scope

- Temperature, max tokens, top-p — hardcoded at the datasource layer by design; not surfaced in the UI.
- Per-session custom model definition — custom models are a future feature; for now `AIModels.fromId()` returns null for unknown ids and falls back to the global selection.
