# Phase 1b — Settings Redesign + Archive Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Archive feature (DB migration + DAO methods + conversation tile menu), redesign Settings screen to a two-pane layout (General / Providers / Archive), and introduce `GeneralPreferences` for auto-commit, terminal app, and delete-confirmation settings.

**Architecture:** Two independent subsystems — (1) DB + service layer changes (isArchived migration, archive/unarchive methods), and (2) pure UI changes (settings two-pane, archive screen widget). The DB changes are required first because the UI reads from the new DAO methods.

**Tech Stack:** Flutter, Drift (SQLite ORM), Riverpod (`riverpod_annotation`), `shared_preferences`, `lucide_icons_flutter` (added in Phase 1a).

---

## As Implemented — Deviations from Plan

The following changes were made during implementation that differ from or extend the original plan.

### `ChatSession` domain model — `isArchived` field added (code-review fix)

The plan only added `isArchived` as a DB column. A post-implementation code review identified that the `ChatSession` Freezed model and `_sessionFromRow` mapper did not expose the field to the domain layer.

- `lib/data/models/chat_session.dart` — added `@Default(false) bool isArchived`
- `lib/services/session/session_service.dart` `_sessionFromRow` — maps `row.isArchived`
- `build_runner` regenerated `chat_session.freezed.dart` and `chat_session.g.dart`

### Settings screen — implementation choices differed from spec

| Spec said | What was built | Reason |
|---|---|---|
| `_SettingsHeaderBar` with Back button (chevron-left icon + `← Back` label) | Header bar removed entirely; Back is a `_NavItem` at the bottom of the left nav | Cleaner two-pane layout; no redundant chrome |
| Material `DropdownButton` / `Switch` widgets | `_AppDropdown<T>` — generic `showInstantMenu`-based chip, matching the existing `_ControlChip` pattern in `chat_input_bar_v2.dart` | Consistent with the zero-animation, app-native dropdown pattern established in Phase 1a |
| Restore defaults in header bar | Moved to the bottom of `_SettingsLeftNav`, above the Back nav item | Header bar was removed |
| Ollama Base URL row in General section | Removed (duplicate of Providers section) | User request during implementation |
| Archive menu order: Rename → divider → Archive → Delete | Rename → Archive → divider → Delete | Archive is a recoverable action; placed with Rename above the destructive-action divider |

### macOS traffic-light clearance — inside left nav

The plan omitted macOS traffic-light handling for the settings screen. The `TitleBarStyle.hidden` window (set in Phase 1a) means the traffic lights overlay the top of any full-screen route.

Implementation:
- The `_SettingsLeftNav` Column gets `if (PlatformUtils.isMacOS) const SizedBox(height: 28)` at the very top so the nav background fills y=0 while the "Settings" title clears the traffic lights.
- The content area uses `padding: EdgeInsets.only(top: PlatformUtils.isMacOS ? 48 : 20)` (28 clearance + 20 alignment) to keep the section label aligned with the "Settings" title.
- The `Scaffold.body` is a bare `Row(...)` — no outer `Column` wrapper — so the left nav background fills the full height including the traffic-light zone.

### Router changes (not in plan)

| Change | Reason |
|---|---|
| `/settings` moved outside `ShellRoute` | Settings is a full-screen route; inside the shell it shared the sidebar chrome |
| `ShellRoute` changed from `builder:` to `pageBuilder:` with `NoTransitionPage` | `builder:` wraps children in a `MaterialPage`, which uses a platform slide animation; `pageBuilder` with `NoTransitionPage` makes all shell navigation instant |

### Async archive/unarchive — `unawaited()` wrappers (code-review fix)

`onArchive` in `project_sidebar.dart` and `onUnarchive` in `settings_screen.dart` both discard the returned `Future<void>`. Post-review: wrapped with `unawaited()` from `dart:async` to signal intent explicitly. `dart:async` import added to both files.

### Terminal app text field — persistence listener (code-review fix)

The `_terminalAppController` had no save path. Post-review: `addListener(() => widget.generalPrefs.setTerminalApp(...))` added in `_GeneralSectionState.initState` so changes are persisted immediately on every keystroke.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/data/datasources/local/app_database.dart` | Modify | Add `isArchived` to `ChatSessions`, bump schemaVersion 2→3, update `watchAllSessions`/`watchSessionsByProject`, add `watchArchivedSessions`, `archiveSession`, `unarchiveSession` |
| `lib/data/datasources/local/general_preferences.dart` | Create | `GeneralPreferences` — SharedPreferences wrapper for `auto_commit_enabled`, `terminal_app`, `delete_confirmation_enabled` |
| `lib/services/session/session_service.dart` | Modify | Add `archiveSession(String)` and `unarchiveSession(String)` + `watchArchivedSessions()` |
| `lib/features/chat/chat_notifier.dart` | Modify | Add `archivedSessionsProvider` stream |
| `lib/features/project_sidebar/widgets/conversation_tile.dart` | Modify | Add `onArchive` callback + **Archive** item to existing right-click menu (Phase 1a already added the menu with Rename / Delete) |
| `lib/features/project_sidebar/widgets/project_tile.dart` | Modify | Add `onArchive: ValueChanged<String>` parameter, pass to each `ConversationTile` |
| `lib/features/project_sidebar/project_sidebar.dart` | Modify | Wire `onArchive` to `sessionService.archiveSession` |
| `lib/features/settings/archive_screen.dart` | Create | Archived sessions grouped by project; Unarchive button; empty state |
| `lib/features/settings/settings_screen.dart` | Modify | Full two-pane redesign — 200px left nav, content area, General/Providers/Archive sections |
| `test/data/datasources/local/general_preferences_test.dart` | Create | Unit tests for `GeneralPreferences` |
| `test/features/project_sidebar/conversation_tile_archive_test.dart` | Create | Widget test: right-click shows Archive item |
| `test/features/settings/archive_screen_test.dart` | Create | Widget test: empty state + session cards |

---

### Task 1: DB migration — `isArchived` on `ChatSessions`

**Files:**
- Modify: `lib/data/datasources/local/app_database.dart`

- [ ] **Step 1: Add `isArchived` column to the `ChatSessions` table**

  In `app_database.dart`, add one line to `ChatSessions` after the `isPinned` column:

  ```dart
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  ```

  Full updated `ChatSessions` class:

  ```dart
  @DataClassName('ChatSessionRow')
  class ChatSessions extends Table {
    TextColumn get sessionId => text()();
    TextColumn get title => text()();
    TextColumn get modelId => text()();
    TextColumn get providerId => text()();
    TextColumn get projectId => text().nullable()();
    DateTimeColumn get createdAt => dateTime()();
    DateTimeColumn get updatedAt => dateTime()();
    BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
    BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

    @override
    Set<Column> get primaryKey => {sessionId};
  }
  ```

- [ ] **Step 2: Bump `schemaVersion` to 3 and add migration step**

  Replace the `schemaVersion` getter and `migration` getter in `AppDatabase`:

  ```dart
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(chatSessions, chatSessions.projectId);
            await migrator.deleteTable('workspace_projects');
            await migrator.createTable(workspaceProjects);
          }
          if (from < 3) {
            await migrator.addColumn(chatSessions, chatSessions.isArchived);
          }
        },
      );
  ```

- [ ] **Step 3: Update `watchAllSessions()` to exclude archived sessions**

  In `SessionDao`, replace `watchAllSessions()`:

  ```dart
  Stream<List<ChatSessionRow>> watchAllSessions() => (select(chatSessions)
        ..where((t) => t.isArchived.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();
  ```

- [ ] **Step 4: Update `watchSessionsByProject()` to exclude archived sessions**

  In `SessionDao`, replace `watchSessionsByProject()`:

  ```dart
  Stream<List<ChatSessionRow>> watchSessionsByProject(String projectId) =>
      (select(chatSessions)
            ..where(
              (t) => t.projectId.equals(projectId) & t.isArchived.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();
  ```

- [ ] **Step 5: Add `watchArchivedSessions()`, `archiveSession()`, `unarchiveSession()` to `SessionDao`**

  Add these three methods to `SessionDao`:

  ```dart
  Stream<List<ChatSessionRow>> watchArchivedSessions() =>
      (select(chatSessions)
            ..where((t) => t.isArchived.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<void> archiveSession(String id) =>
      (update(chatSessions)..where((t) => t.sessionId.equals(id)))
          .write(const ChatSessionsCompanion(isArchived: Value(true)));

  Future<void> unarchiveSession(String id) =>
      (update(chatSessions)..where((t) => t.sessionId.equals(id)))
          .write(const ChatSessionsCompanion(isArchived: Value(false)));
  ```

- [ ] **Step 6: Run `build_runner` to regenerate Drift code**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Expected: exits 0, regenerates `app_database.g.dart`. The `ChatSessionRow` class now has an `isArchived` field.

- [ ] **Step 7: Verify the app still compiles**

  ```bash
  flutter analyze
  ```
  Expected: no errors (the generated code picks up the new column automatically).

- [ ] **Step 8: Commit**

  ```bash
  git add lib/data/datasources/local/app_database.dart lib/data/datasources/local/app_database.g.dart
  git commit -m "feat: add isArchived to ChatSessions, bump schema to v3"
  ```

---

### Task 2: `GeneralPreferences` — SharedPreferences wrapper

**Files:**
- Create: `lib/data/datasources/local/general_preferences.dart`
- Create: `test/data/datasources/local/general_preferences_test.dart`

- [ ] **Step 1: Write the failing tests**

  Create `test/data/datasources/local/general_preferences_test.dart`:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:code_bench_app/data/datasources/local/general_preferences.dart';

  void main() {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() => SharedPreferences.setMockInitialValues({}));

    group('GeneralPreferences.autoCommit', () {
      test('returns false by default', () async {
        expect(await GeneralPreferences().getAutoCommit(), false);
      });

      test('returns true after setAutoCommit(true)', () async {
        final prefs = GeneralPreferences();
        await prefs.setAutoCommit(true);
        expect(await prefs.getAutoCommit(), true);
      });
    });

    group('GeneralPreferences.terminalApp', () {
      test('returns "Terminal" by default', () async {
        expect(await GeneralPreferences().getTerminalApp(), 'Terminal');
      });

      test('returns set value', () async {
        final prefs = GeneralPreferences();
        await prefs.setTerminalApp('iTerm');
        expect(await prefs.getTerminalApp(), 'iTerm');
      });
    });

    group('GeneralPreferences.deleteConfirmation', () {
      test('returns true by default', () async {
        expect(await GeneralPreferences().getDeleteConfirmation(), true);
      });

      test('returns false after setDeleteConfirmation(false)', () async {
        final prefs = GeneralPreferences();
        await prefs.setDeleteConfirmation(false);
        expect(await prefs.getDeleteConfirmation(), false);
      });
    });
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  ```bash
  flutter test test/data/datasources/local/general_preferences_test.dart
  ```
  Expected: FAIL — `general_preferences.dart` not found.

- [ ] **Step 3: Implement `GeneralPreferences`**

  Create `lib/data/datasources/local/general_preferences.dart`:

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  part 'general_preferences.g.dart';

  @Riverpod(keepAlive: true)
  GeneralPreferences generalPreferences(Ref ref) => GeneralPreferences();

  class GeneralPreferences {
    static const _autoCommit = 'auto_commit_enabled';
    static const _terminalApp = 'terminal_app';
    static const _deleteConfirm = 'delete_confirmation_enabled';

    Future<bool> getAutoCommit() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoCommit) ?? false;
    }

    Future<void> setAutoCommit(bool value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoCommit, value);
    }

    Future<String> getTerminalApp() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_terminalApp) ?? 'Terminal';
    }

    Future<void> setTerminalApp(String value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_terminalApp, value);
    }

    Future<bool> getDeleteConfirmation() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_deleteConfirm) ?? true;
    }

    Future<void> setDeleteConfirmation(bool value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_deleteConfirm, value);
    }
  }
  ```

- [ ] **Step 4: Run `build_runner` for the new Riverpod provider**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Expected: generates `general_preferences.g.dart`.

- [ ] **Step 5: Run tests to verify they pass**

  ```bash
  flutter test test/data/datasources/local/general_preferences_test.dart
  ```
  Expected: all 6 tests PASS.

- [ ] **Step 6: Commit**

  ```bash
  git add lib/data/datasources/local/general_preferences.dart \
          lib/data/datasources/local/general_preferences.g.dart \
          test/data/datasources/local/general_preferences_test.dart
  git commit -m "feat: add GeneralPreferences for auto-commit, terminal app, delete confirmation"
  ```

---

### Task 3: `SessionService` archive methods + `archivedSessionsProvider`

**Files:**
- Modify: `lib/services/session/session_service.dart`
- Modify: `lib/features/chat/chat_notifier.dart`

- [ ] **Step 1: Add `watchArchivedSessions()`, `archiveSession()`, `unarchiveSession()` to `SessionService`**

  In `lib/services/session/session_service.dart`, add these three methods after `watchSessionsByProject()`:

  ```dart
  Stream<List<session_model.ChatSession>> watchArchivedSessions() {
    return _db.sessionDao.watchArchivedSessions().map(
          (rows) => rows.map(_sessionFromRow).toList(),
        );
  }

  Future<void> archiveSession(String sessionId) async {
    await _db.sessionDao.archiveSession(sessionId);
  }

  Future<void> unarchiveSession(String sessionId) async {
    await _db.sessionDao.unarchiveSession(sessionId);
  }
  ```

- [ ] **Step 2: Add `archivedSessionsProvider` to `chat_notifier.dart`**

  In `lib/features/chat/chat_notifier.dart`, add after the existing `projectSessions` provider:

  ```dart
  @riverpod
  Stream<List<ChatSession>> archivedSessions(Ref ref) {
    return ref.watch(sessionServiceProvider).watchArchivedSessions();
  }
  ```

  Add the import if missing (it shares the same file-level imports as `projectSessions`).

- [ ] **Step 3: Run `build_runner`**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Expected: regenerates `chat_notifier.g.dart` with `archivedSessionsProvider`.

- [ ] **Step 4: Verify compilation**

  ```bash
  flutter analyze
  ```
  Expected: no errors.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/services/session/session_service.dart \
          lib/features/chat/chat_notifier.dart \
          lib/features/chat/chat_notifier.g.dart
  git commit -m "feat: add archive/unarchive session methods to SessionService"
  ```

---

### Task 4: `ConversationTile` right-click archive menu

**Files:**
- Modify: `lib/features/project_sidebar/widgets/conversation_tile.dart`
- Modify: `lib/features/project_sidebar/widgets/project_tile.dart`
- Modify: `lib/features/project_sidebar/project_sidebar.dart`
- Create: `test/features/project_sidebar/conversation_tile_archive_test.dart`

- [ ] **Step 1: Write the failing widget test**

  Create `test/features/project_sidebar/conversation_tile_archive_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/chat_session.dart';
  import 'package:code_bench_app/features/project_sidebar/widgets/conversation_tile.dart';

  void main() {
    final session = ChatSession(
      sessionId: 's1',
      title: 'My session',
      modelId: 'gpt-4',
      providerId: 'openai',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

    testWidgets('right-click shows Archive option', (tester) async {
      String? archived;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ConversationTile(
            session: session,
            isActive: false,
            onTap: () {},
            onArchive: () => archived = session.sessionId,
          ),
        ),
      ));

      await tester.sendEventToBinding(
        TestPointer(1, PointerDeviceKind.mouse)
            .hover(tester.getCenter(find.text('My session'))),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('My session')),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Archive'), findsOneWidget);

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(archived, 's1');
    });
  }
  ```

- [ ] **Step 2: Run test to verify it fails**

  ```bash
  flutter test test/features/project_sidebar/conversation_tile_archive_test.dart
  ```
  Expected: FAIL — `ConversationTile` missing `onArchive` parameter.

- [ ] **Step 3: Add `onArchive` to `ConversationTile` and insert Archive item into existing menu**

  > **Phase 1a note:** `ConversationTile` already has a right-click context menu (added in Phase 1a) with **Rename** and **Delete** items using `showInstantMenu`. Do NOT replace the file. Instead make targeted edits:
  >
  > 1. Add `this.onArchive` as an optional `VoidCallback?` parameter (keep `onRename` and `onDelete`)
  > 2. Insert an **Archive** `PopupMenuItem` (with `LucideIcons.archive`) between Rename and the divider before Delete, or before Delete
  > 3. Add `if (action == 'archive') onArchive?.call();` in the action handler
  > 4. Use `showInstantMenu` (already imported as `'../../../core/utils/instant_menu.dart'`) — **do not use `showMenu`**

  The resulting menu order should be: **Rename** → *(divider)* → **Archive** → **Delete**.

- [ ] **Step 4: Update `ProjectTile` to accept and pass `onArchive`**

  In `lib/features/project_sidebar/widgets/project_tile.dart`:

  1. Add `onArchive` parameter to the class:
     ```dart
     final ValueChanged<String> onArchive;
     ```

  2. Add `required this.onArchive,` to the constructor.

  3. In the sessions list builder, pass `onArchive` to each `ConversationTile`:
     ```dart
     ConversationTile(
       session: s,
       isActive: s.sessionId == activeSessionId,
       onTap: () => onSessionTap(s.sessionId),
       onArchive: () => onArchive(s.sessionId),
     ),
     ```

- [ ] **Step 5: Wire `onArchive` in `ProjectSidebar`**

  In `lib/features/project_sidebar/project_sidebar.dart`, add the `onArchive` callback to the `ProjectTile` call:

  ```dart
  ProjectTile(
    // ... existing params ...
    onArchive: (sessionId) =>
        ref.read(sessionServiceProvider).archiveSession(sessionId),
  ),
  ```

- [ ] **Step 6: Run the widget test**

  ```bash
  flutter test test/features/project_sidebar/conversation_tile_archive_test.dart
  ```
  Expected: PASS.

- [ ] **Step 7: Run analyze**

  ```bash
  flutter analyze
  ```
  Expected: no errors.

- [ ] **Step 8: Commit**

  ```bash
  git add lib/features/project_sidebar/widgets/conversation_tile.dart \
          lib/features/project_sidebar/widgets/project_tile.dart \
          lib/features/project_sidebar/project_sidebar.dart \
          test/features/project_sidebar/conversation_tile_archive_test.dart
  git commit -m "feat: add Archive right-click item to conversation tile"
  ```

---

### Task 5: `ArchiveScreen` widget

**Files:**
- Create: `lib/features/settings/archive_screen.dart`
- Create: `test/features/settings/archive_screen_test.dart`

- [ ] **Step 1: Write the failing widget tests**

  Create `test/features/settings/archive_screen_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/chat_session.dart';
  import 'package:code_bench_app/data/models/project.dart';
  import 'package:code_bench_app/features/chat/chat_notifier.dart';
  import 'package:code_bench_app/features/project_sidebar/project_sidebar_notifier.dart';
  import 'package:code_bench_app/features/settings/archive_screen.dart';

  final _emptyArchive = StreamProvider<List<ChatSession>>((ref) =>
      Stream.value([]));
  final _emptyProjects = StreamProvider<List<Project>>((ref) =>
      Stream.value([]));

  Widget _buildArchive({
    List<ChatSession> sessions = const [],
    List<Project> projects = const [],
    void Function(String)? onUnarchive,
  }) {
    return ProviderScope(
      overrides: [
        archivedSessionsProvider.overrideWith(
          (ref) => Stream.value(sessions),
        ),
        projectsProvider.overrideWith(
          (ref) => Stream.value(projects),
        ),
      ],
      child: MaterialApp(
        home: ArchiveScreen(onUnarchive: onUnarchive ?? (_) {}),
      ),
    );
  }

  void main() {
    testWidgets('shows empty state when no archived sessions', (tester) async {
      await tester.pumpWidget(_buildArchive());
      await tester.pump();

      expect(find.text('No archived conversations'), findsOneWidget);
    });

    testWidgets('shows archived session title', (tester) async {
      final session = ChatSession(
        sessionId: 's1',
        title: 'Old chat',
        modelId: 'm',
        providerId: 'anthropic',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      await tester.pumpWidget(_buildArchive(sessions: [session]));
      await tester.pump();

      expect(find.text('Old chat'), findsOneWidget);
      expect(find.text('Unarchive'), findsOneWidget);
    });

    testWidgets('Unarchive button calls onUnarchive', (tester) async {
      String? unarchived;
      final session = ChatSession(
        sessionId: 's2',
        title: 'Another chat',
        modelId: 'm',
        providerId: 'anthropic',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      await tester.pumpWidget(_buildArchive(
        sessions: [session],
        onUnarchive: (id) => unarchived = id,
      ));
      await tester.pump();

      await tester.tap(find.text('Unarchive'));
      await tester.pump();

      expect(unarchived, 's2');
    });
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  ```bash
  flutter test test/features/settings/archive_screen_test.dart
  ```
  Expected: FAIL — `archive_screen.dart` not found.

- [ ] **Step 3: Implement `ArchiveScreen`**

  Create `lib/features/settings/archive_screen.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../core/constants/theme_constants.dart';
  import '../../data/models/chat_session.dart';
  import '../../data/models/project.dart';
  import '../chat/chat_notifier.dart';
  import '../project_sidebar/project_sidebar_notifier.dart';

  class ArchiveScreen extends ConsumerWidget {
    const ArchiveScreen({super.key, required this.onUnarchive});

    final void Function(String sessionId) onUnarchive;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final sessionsAsync = ref.watch(archivedSessionsProvider);
      final projectsAsync = ref.watch(projectsProvider);

      return sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: ThemeConstants.error, fontSize: 11)),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(LucideIcons.archive, size: 32, color: ThemeConstants.mutedFg),
                  SizedBox(height: 12),
                  Text(
                    'No archived conversations',
                    style: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final projects = projectsAsync.valueOrNull ?? [];
          final projectMap = {for (final p in projects) p.id: p.name};

          // Group sessions by projectId
          final groups = <String?, List<ChatSession>>{};
          for (final s in sessions) {
            groups.putIfAbsent(s.projectId, () => []).add(s);
          }

          return ListView(
            children: [
              for (final entry in groups.entries) ...[
                _ProjectHeader(
                  name: projectMap[entry.key] ?? 'No Project',
                ),
                for (final s in entry.value)
                  _ArchivedSessionCard(
                    session: s,
                    onUnarchive: () => onUnarchive(s.sessionId),
                  ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      );
    }
  }

  class _ProjectHeader extends StatelessWidget {
    const _ProjectHeader({required this.name});

    final String name;

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Row(
          children: [
            const Icon(LucideIcons.folder, size: 12, color: ThemeConstants.mutedFg),
            const SizedBox(width: 6),
            Text(
              name.toUpperCase(),
              style: const TextStyle(
                color: ThemeConstants.mutedFg,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
    }
  }

  class _ArchivedSessionCard extends StatelessWidget {
    const _ArchivedSessionCard({
      required this.session,
      required this.onUnarchive,
    });

    final ChatSession session;
    final VoidCallback onUnarchive;

    String _relativeTime(DateTime dt) {
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    @override
    Widget build(BuildContext context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          border: Border.all(color: ThemeConstants.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Archived ${_relativeTime(session.updatedAt)} · Created ${_relativeTime(session.createdAt)}',
                    style: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onUnarchive,
              icon: const Icon(LucideIcons.archiveRestore, size: 12),
              label: const Text('Unarchive'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeConstants.textPrimary,
                side: const BorderSide(color: ThemeConstants.borderColor),
                textStyle: const TextStyle(fontSize: 11),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Run widget tests**

  ```bash
  flutter test test/features/settings/archive_screen_test.dart
  ```
  Expected: all 3 tests PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/settings/archive_screen.dart \
          test/features/settings/archive_screen_test.dart
  git commit -m "feat: add ArchiveScreen with empty state and unarchive action"
  ```

---

### Task 6: `SettingsScreen` two-pane redesign

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Replace `SettingsScreen` with the two-pane layout**

  Replace the full content of `lib/features/settings/settings_screen.dart`:

  ```dart
  import 'package:dio/dio.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../core/constants/api_constants.dart';
  import '../../core/constants/theme_constants.dart';
  import '../../data/datasources/local/general_preferences.dart';
  import '../../data/datasources/local/onboarding_preferences.dart';
  import '../../data/datasources/local/secure_storage_source.dart';
  import '../../data/models/ai_model.dart';
  import '../../services/ai/ai_service_factory.dart';
  import '../../services/session/session_service.dart';
  import 'archive_screen.dart';

  enum _SettingsNav { general, providers, archive }

  class SettingsScreen extends ConsumerStatefulWidget {
    const SettingsScreen({super.key});

    @override
    ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
  }

  class _SettingsScreenState extends ConsumerState<SettingsScreen> {
    _SettingsNav _activeNav = _SettingsNav.general;

    // Provider API key controllers
    final _controllers = <AIProvider, TextEditingController>{
      AIProvider.openai: TextEditingController(),
      AIProvider.anthropic: TextEditingController(),
      AIProvider.gemini: TextEditingController(),
    };
    final _ollamaController = TextEditingController();
    final _customEndpointController = TextEditingController();
    final _customApiKeyController = TextEditingController();

    @override
    void initState() {
      super.initState();
      _loadKeys();
    }

    Future<void> _loadKeys() async {
      final storage = ref.read(secureStorageSourceProvider);
      for (final provider in _controllers.keys) {
        final key = await storage.readApiKey(provider.name);
        if (key != null) _controllers[provider]!.text = key;
      }
      final ollamaUrl = await storage.readOllamaUrl();
      _ollamaController.text = ollamaUrl ?? ApiConstants.ollamaDefaultBaseUrl;
      final customEndpoint = await storage.readCustomEndpoint();
      if (customEndpoint != null) _customEndpointController.text = customEndpoint;
      final customApiKey = await storage.readCustomApiKey();
      if (customApiKey != null) _customApiKeyController.text = customApiKey;
      setState(() {});
    }

    Future<void> _saveKeys() async {
      final storage = ref.read(secureStorageSourceProvider);
      for (final entry in _controllers.entries) {
        final key = entry.value.text.trim();
        if (key.isNotEmpty) {
          await storage.writeApiKey(entry.key.name, key);
        } else {
          await storage.deleteApiKey(entry.key.name);
        }
      }
      final ollamaUrl = _ollamaController.text.trim();
      if (ollamaUrl.isNotEmpty) await storage.writeOllamaUrl(ollamaUrl);
      await storage.writeCustomEndpoint(_customEndpointController.text.trim());
      await storage.writeCustomApiKey(_customApiKeyController.text.trim());
      ref.invalidate(aiServiceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: ThemeConstants.success,
          ),
        );
      }
    }

    Future<void> _deleteKey(AIProvider provider) async {
      final storage = ref.read(secureStorageSourceProvider);
      await storage.deleteApiKey(provider.name);
      _controllers[provider]!.clear();
      ref.invalidate(aiServiceProvider);
    }

    Future<void> _testOllama() async {
      final url = _ollamaController.text.trim();
      try {
        final testDio = Dio(
          BaseOptions(baseUrl: url, connectTimeout: const Duration(seconds: 5)),
        );
        await testDio.get('/api/tags');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ollama is running!'),
              backgroundColor: ThemeConstants.success,
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot connect to Ollama.'),
              backgroundColor: ThemeConstants.error,
            ),
          );
        }
      }
    }

    @override
    void dispose() {
      for (final c in _controllers.values) {
        c.dispose();
      }
      _ollamaController.dispose();
      _customEndpointController.dispose();
      _customApiKeyController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: ThemeConstants.background,
        body: Column(
          children: [
            // Header bar
            _SettingsHeaderBar(
              onRestoreDefaults: _restoreDefaults,
            ),
            Expanded(
              child: Row(
                children: [
                  // Left nav (200px)
                  _SettingsLeftNav(
                    activeNav: _activeNav,
                    onSelect: (nav) => setState(() => _activeNav = nav),
                    onBack: () => context.go('/chat'),
                  ),
                  // Content area
                  Expanded(
                    child: Container(
                      color: ThemeConstants.sidebarBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildContent() {
      switch (_activeNav) {
        case _SettingsNav.general:
          return _GeneralSection(
            generalPrefs: ref.read(generalPreferencesProvider),
          );
        case _SettingsNav.providers:
          return _ProvidersSection(
            controllers: _controllers,
            ollamaController: _ollamaController,
            customEndpointController: _customEndpointController,
            customApiKeyController: _customApiKeyController,
            onSave: _saveKeys,
            onDeleteKey: _deleteKey,
            onTestOllama: _testOllama,
          );
        case _SettingsNav.archive:
          return ArchiveScreen(
            onUnarchive: (id) =>
                ref.read(sessionServiceProvider).unarchiveSession(id),
          );
      }
    }

    Future<void> _restoreDefaults() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ThemeConstants.panelBackground,
          title: const Text(
            'Restore defaults?',
            style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14),
          ),
          content: const Text(
            'All settings will be reset to their default values.',
            style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final prefs = ref.read(generalPreferencesProvider);
      await prefs.setAutoCommit(false);
      await prefs.setTerminalApp('Terminal');
      await prefs.setDeleteConfirmation(true);
      if (mounted) setState(() {});
    }
  }

  // ── Header bar ────────────────────────────────────────────────────────────────

  class _SettingsHeaderBar extends StatelessWidget {
    const _SettingsHeaderBar({required this.onRestoreDefaults});

    final VoidCallback onRestoreDefaults;

    @override
    Widget build(BuildContext context) {
      return Container(
        height: 38,
        decoration: const BoxDecoration(
          color: ThemeConstants.inputBackground,
          border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Spacer(),
            TextButton(
              onPressed: onRestoreDefaults,
              child: const Text(
                '↺ Restore defaults',
                style: TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ── Left nav ──────────────────────────────────────────────────────────────────

  class _SettingsLeftNav extends StatelessWidget {
    const _SettingsLeftNav({
      required this.activeNav,
      required this.onSelect,
      required this.onBack,
    });

    final _SettingsNav activeNav;
    final ValueChanged<_SettingsNav> onSelect;
    final VoidCallback onBack;

    @override
    Widget build(BuildContext context) {
      return Container(
        width: 200,
        decoration: const BoxDecoration(
          color: ThemeConstants.activityBar,
          border: Border(right: BorderSide(color: ThemeConstants.borderColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _NavItem(
              icon: LucideIcons.settings,
              label: 'General',
              isActive: activeNav == _SettingsNav.general,
              onTap: () => onSelect(_SettingsNav.general),
            ),
            _NavItem(
              icon: LucideIcons.messageSquare,
              label: 'Providers',
              isActive: activeNav == _SettingsNav.providers,
              onTap: () => onSelect(_SettingsNav.providers),
            ),
            _NavItem(
              icon: LucideIcons.archive,
              label: 'Archive',
              isActive: activeNav == _SettingsNav.archive,
              onTap: () => onSelect(_SettingsNav.archive),
            ),
            const Spacer(),
            _NavItem(
              icon: LucideIcons.arrowLeft,
              label: '← Back',
              isActive: false,
              onTap: onBack,
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }
  }

  class _NavItem extends StatelessWidget {
    const _NavItem({
      required this.icon,
      required this.label,
      required this.isActive,
      required this.onTap,
    });

    final IconData icon;
    final String label;
    final bool isActive;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? ThemeConstants.inputSurface : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? ThemeConstants.textPrimary
                    : ThemeConstants.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? ThemeConstants.textPrimary
                      : ThemeConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ── General section ───────────────────────────────────────────────────────────

  class _GeneralSection extends StatefulWidget {
    const _GeneralSection({required this.generalPrefs});

    final GeneralPreferences generalPrefs;

    @override
    State<_GeneralSection> createState() => _GeneralSectionState();
  }

  class _GeneralSectionState extends State<_GeneralSection> {
    bool _autoCommit = false;
    bool _deleteConfirmation = true;
    final _ollamaUrlController = TextEditingController();
    final _terminalAppController = TextEditingController();

    @override
    void initState() {
      super.initState();
      _load();
    }

    Future<void> _load() async {
      final autoCommit = await widget.generalPrefs.getAutoCommit();
      final deleteConfirm = await widget.generalPrefs.getDeleteConfirmation();
      final terminalApp = await widget.generalPrefs.getTerminalApp();
      final ollamaUrl = ApiConstants.ollamaDefaultBaseUrl;
      setState(() {
        _autoCommit = autoCommit;
        _deleteConfirmation = deleteConfirm;
        _terminalAppController.text = terminalApp;
        _ollamaUrlController.text = ollamaUrl;
      });
    }

    @override
    void dispose() {
      _ollamaUrlController.dispose();
      _terminalAppController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('General'),
            const SizedBox(height: 8),
            _SettingsGroup(rows: [
              _SettingsRow(
                label: 'Theme',
                description: 'How Code Bench looks',
                trailing: _DropdownField(
                  value: 'Dark',
                  items: const ['Dark', 'Light', 'System'],
                  onChanged: (_) {},
                ),
              ),
              _SettingsRow(
                label: 'Ollama base URL',
                description: 'Base URL for local Ollama',
                trailing: SizedBox(
                  width: 200,
                  child: _InlineTextField(controller: _ollamaUrlController),
                ),
              ),
              _SettingsRow(
                label: 'Delete confirmation',
                description: 'Ask before deleting a session',
                trailing: Switch(
                  value: _deleteConfirmation,
                  onChanged: (v) async {
                    await widget.generalPrefs.setDeleteConfirmation(v);
                    setState(() => _deleteConfirmation = v);
                  },
                ),
              ),
              _SettingsRow(
                label: 'Auto-commit',
                description: 'Skip commit dialog; commit immediately with AI-generated message',
                trailing: Switch(
                  value: _autoCommit,
                  onChanged: (v) async {
                    await widget.generalPrefs.setAutoCommit(v);
                    setState(() => _autoCommit = v);
                  },
                ),
              ),
              _SettingsRow(
                label: 'Terminal app',
                description: 'App to open when "Open Terminal" is tapped',
                trailing: SizedBox(
                  width: 140,
                  child: _InlineTextField(controller: _terminalAppController),
                ),
                isLast: true,
              ),
            ]),
            const SizedBox(height: 24),
            _SectionLabel('About'),
            const SizedBox(height: 8),
            _SettingsGroup(rows: [
              _SettingsRow(
                label: 'Version',
                description: 'Current app version',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ThemeConstants.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Up to Date',
                    style: TextStyle(
                      color: ThemeConstants.success,
                      fontSize: 10,
                    ),
                  ),
                ),
                isLast: true,
              ),
            ]),
          ],
        ),
      );
    }
  }

  // ── Providers section ─────────────────────────────────────────────────────────

  class _ProvidersSection extends StatelessWidget {
    const _ProvidersSection({
      required this.controllers,
      required this.ollamaController,
      required this.customEndpointController,
      required this.customApiKeyController,
      required this.onSave,
      required this.onDeleteKey,
      required this.onTestOllama,
    });

    final Map<AIProvider, TextEditingController> controllers;
    final TextEditingController ollamaController;
    final TextEditingController customEndpointController;
    final TextEditingController customApiKeyController;
    final VoidCallback onSave;
    final void Function(AIProvider) onDeleteKey;
    final VoidCallback onTestOllama;

    @override
    Widget build(BuildContext context) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('API Keys'),
            const SizedBox(height: 8),
            ...AIProvider.values
                .where((p) => p != AIProvider.ollama && p != AIProvider.custom)
                .map(
                  (provider) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProviderKeyCard(
                      provider: provider,
                      controller: controllers[provider]!,
                      onDelete: () => onDeleteKey(provider),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            _SectionLabel('Ollama (Local)'),
            const SizedBox(height: 8),
            _SettingsGroup(rows: [
              _SettingsRow(
                label: 'Base URL',
                description: ApiConstants.ollamaDefaultBaseUrl,
                trailing: SizedBox(
                  width: 200,
                  child: _InlineTextField(controller: ollamaController),
                ),
                isLast: true,
              ),
            ]),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onTestOllama,
              icon: const Icon(LucideIcons.play, size: 12),
              label: const Text('Test Connection',
                  style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(height: 16),
            _SectionLabel('Custom Endpoint (OpenAI-compatible)'),
            const SizedBox(height: 8),
            _SettingsGroup(rows: [
              _SettingsRow(
                label: 'Base URL',
                description: 'http://localhost:1234/v1',
                trailing: SizedBox(
                  width: 200,
                  child: _InlineTextField(controller: customEndpointController),
                ),
              ),
              _SettingsRow(
                label: 'API Key',
                description: 'sk-... or leave blank',
                trailing: SizedBox(
                  width: 200,
                  child: _InlineTextField(
                    controller: customApiKeyController,
                    obscureText: true,
                  ),
                ),
                isLast: true,
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: onSave,
                child: const Text('Save', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    }
  }

  class _ProviderKeyCard extends StatefulWidget {
    const _ProviderKeyCard({
      required this.provider,
      required this.controller,
      required this.onDelete,
    });

    final AIProvider provider;
    final TextEditingController controller;
    final VoidCallback onDelete;

    @override
    State<_ProviderKeyCard> createState() => _ProviderKeyCardState();
  }

  class _ProviderKeyCardState extends State<_ProviderKeyCard> {
    bool _obscure = true;
    bool _expanded = false;

    @override
    Widget build(BuildContext context) {
      final hasKey = widget.controller.text.isNotEmpty;
      return Container(
        decoration: BoxDecoration(
          color: ThemeConstants.inputSurface,
          border: Border.all(color: ThemeConstants.deepBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasKey
                            ? ThemeConstants.success
                            : ThemeConstants.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.provider.displayName,
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasKey ? 'Configured' : 'Not configured',
                      style: const TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 14,
                      color: ThemeConstants.mutedFg,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        obscureText: _obscure,
                        style: const TextStyle(
                          color: ThemeConstants.textPrimary,
                          fontSize: 12,
                          fontFamily: ThemeConstants.editorFontFamily,
                        ),
                        decoration: InputDecoration(
                          hintText: 'API key',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              size: 14,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.x,
                          size: 14, color: ThemeConstants.error),
                      tooltip: 'Remove key',
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
  }

  // ── Shared row/group components ───────────────────────────────────────────────

  class _SectionLabel extends StatelessWidget {
    const _SectionLabel(this.label);

    final String label;

    @override
    Widget build(BuildContext context) {
      return Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: ThemeConstants.mutedFg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
    }
  }

  class _SettingsGroup extends StatelessWidget {
    const _SettingsGroup({required this.rows});

    final List<_SettingsRow> rows;

    @override
    Widget build(BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: ThemeConstants.deepBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  color: ThemeConstants.deepBorder,
                ),
              rows[i],
            ],
          ],
        ),
      );
    }
  }

  class _SettingsRow extends StatelessWidget {
    const _SettingsRow({
      required this.label,
      required this.description,
      required this.trailing,
      this.isLast = false,
    });

    final String label;
    final String description;
    final Widget trailing;
    final bool isLast;

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            trailing,
          ],
        ),
      );
    }
  }

  class _InlineTextField extends StatelessWidget {
    const _InlineTextField({
      required this.controller,
      this.obscureText = false,
    });

    final TextEditingController controller;
    final bool obscureText;

    @override
    Widget build(BuildContext context) {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: 12,
          fontFamily: ThemeConstants.editorFontFamily,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      );
    }
  }

  class _DropdownField extends StatelessWidget {
    const _DropdownField({
      required this.value,
      required this.items,
      required this.onChanged,
    });

    final String value;
    final List<String> items;
    final ValueChanged<String?> onChanged;

    @override
    Widget build(BuildContext context) {
      return DropdownButton<String>(
        value: value,
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: onChanged,
        style: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: 12,
        ),
        dropdownColor: ThemeConstants.panelBackground,
        underline: const SizedBox.shrink(),
      );
    }
  }
  ```

  Note: `ThemeConstants.sidebarBackground` = `#111111`, `ThemeConstants.activityBar` = `#0A0A0A`, `ThemeConstants.deepBorder` = `#222222`, `ThemeConstants.mutedFg` = `#555555` — all defined in Phase 1a Task 1.

  If `ThemeConstants.sidebarBackground` does not exist (check after Phase 1a), use `ThemeConstants.inputBackground` (`#111111`) instead — they share the same value.

- [ ] **Step 2: Run `flutter analyze`**

  ```bash
  flutter analyze
  ```
  Expected: no errors. If `sidebarBackground` is missing, replace with `inputBackground`.

- [ ] **Step 3: Run all tests**

  ```bash
  flutter test
  ```
  Expected: all tests pass.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/settings/settings_screen.dart
  git commit -m "feat: redesign SettingsScreen to two-pane layout (General, Providers, Archive)"
  ```

---

### Task 7: Final quality checks

**Files:** none (read-only verification)

- [ ] **Step 1: Format all Dart files**

  ```bash
  dart format lib/ test/
  ```
  Expected: all files formatted.

- [ ] **Step 2: Analyze**

  ```bash
  flutter analyze
  ```
  Expected: no issues.

- [ ] **Step 3: Run all tests**

  ```bash
  flutter test
  ```
  Expected: all tests pass.

- [ ] **Step 4: Final commit**

  ```bash
  git add -p   # stage any format-only changes
  git commit -m "chore: dart format Phase 1b"
  ```
  (Skip this commit if `dart format` produced no changes.)

---

## Self-Review

**Spec coverage:**
- [x] `isArchived` boolean column on `ChatSessions` → Task 1
- [x] `schemaVersion` bump + migration → Task 1
- [x] `watchAllSessions()` filters archived → Task 1 Step 3
- [x] `watchArchivedSessions()` → Task 1 Step 5
- [x] `archiveSession()` / `unarchiveSession()` → Task 1 Step 5
- [x] Archive item in conversation tile right-click menu → Task 4
- [x] Archive screen (grouped by project, Unarchive button, empty state) → Task 5
- [x] Settings two-pane layout (200px left nav) → Task 6
- [x] General section rows (Theme, Ollama URL, Delete confirmation, Auto-commit, Terminal app) → Task 6
- [x] Providers section (per-provider expand cards, status dot, API key input) → Task 6
- [x] Archive nav item → ArchiveScreen → Task 6
- [x] `GeneralPreferences` with `auto_commit_enabled` key (same key used in Phase 3 Commit dialog) → Task 2
- [x] Restore defaults dialog → Task 6 `_restoreDefaults()`
- [x] "← Back" link in nav → Task 6 `_SettingsLeftNav`

**Missing checks:**
- `ThemeConstants.sidebarBackground` may not exist — noted in Task 6 Step 1 with fallback to `inputBackground`.
- The `debug` Developer section (Reset Onboarding button) is omitted from the Providers section — it was only visible in `kDebugMode`. Add it back to the Providers section if needed, or leave it out (it's a debug tool, not a user-facing setting).
