# Chat-First Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the editor-centric VS Code layout with a chat-first interface where conversations are the primary workspace, organized under folder-based projects with git auto-detection.

**Architecture:** Two-zone layout — a sidebar (project tree + conversations) on the left, and a full chat panel on the right. The existing nav rail, editor pane, file explorer, and chat side panel are removed. The Drift database gains a schema migration to link sessions to projects. New UI widgets are built for the sidebar, top bar, input controls, and status bar.

**Tech Stack:** Flutter, Riverpod, Drift (SQLite), GoRouter, freezed, dart:io (for git detection and file system), window_manager

---

## File Map

### New Files
- `lib/data/models/project.dart` — Freezed Project model
- `lib/services/project/project_service.dart` — Project CRUD, git detection, folder creation
- `lib/services/project/git_detector.dart` — Git repo detection + branch reading via dart:io
- `lib/features/project_sidebar/project_sidebar.dart` — Sidebar widget (project list + conversations)
- `lib/features/project_sidebar/widgets/project_tile.dart` — Single project row with collapse/expand
- `lib/features/project_sidebar/widgets/conversation_tile.dart` — Single conversation row
- `lib/features/project_sidebar/widgets/project_context_menu.dart` — Right-click context menu
- `lib/features/project_sidebar/project_sidebar_notifier.dart` — Riverpod state for sidebar (expanded projects, active project)
- `lib/shell/chat_shell.dart` — New shell replacing DesktopShell (sidebar + right panel)
- `lib/shell/widgets/top_action_bar.dart` — Conversation title + project badge + action buttons
- `lib/shell/widgets/status_bar.dart` — Bottom status bar (Local + git branch)
- `lib/features/chat/widgets/chat_input_bar_v2.dart` — Redesigned input with model/effort/mode/permissions controls

### Modified Files
- `lib/data/datasources/local/app_database.dart` — Modify WorkspaceProjects columns, add projectId to ChatSessions, schema v2 migration
- `lib/data/models/chat_session.dart` — Add projectId field
- `lib/services/session/session_service.dart` — Accept projectId in createSession, filter sessions by project
- `lib/features/chat/chat_notifier.dart` — Add activeProjectId provider, filter chatSessions by project
- `lib/features/chat/chat_screen.dart` — Remove _ChatHeader and _ModelSelector (moved to top bar and input bar)
- `lib/router/app_router.dart` — Replace DesktopShell with ChatShell, simplify routes
- `lib/app.dart` — No changes needed
- `lib/main.dart` — No changes needed
- `lib/core/constants/app_constants.dart` — Remove pane width constants, add sidebar width constant

### Removed Files (delete)
- `lib/shell/desktop_shell.dart` — Replaced by chat_shell.dart
- `lib/shell/widgets/side_nav_rail.dart` — Replaced by project_sidebar
- `lib/shell/widgets/app_title_bar.dart` — Replaced by macOS native title bar
- `lib/features/file_explorer/file_explorer_panel.dart` — No longer needed
- `lib/features/dashboard/dashboard_screen.dart` — No longer needed
- `lib/features/editor/editor_screen.dart` — No longer needed
- `lib/features/editor/editor_notifier.dart` — No longer needed
- `lib/features/editor/editor_notifier.g.dart` — Generated, remove with source
- `lib/features/editor/widgets/code_editor_widget.dart` — No longer needed
- `lib/features/editor/widgets/file_tab_bar.dart` — No longer needed
- `lib/features/compare/compare_screen.dart` — No longer needed
- `lib/features/github/github_screen.dart` — No longer needed
- `lib/features/github/widgets/pr_list_widget.dart` — No longer needed
- `lib/features/github/widgets/commit_dialog.dart` — No longer needed
- `lib/features/github/widgets/repo_file_tree.dart` — No longer needed
- `lib/features/chat/chat_panel.dart` — No longer needed (chat is now full-screen)
- `lib/features/chat/chat_home_screen.dart` — Replaced by sidebar conversation list

---

## Task 1: Database Schema Migration

**Files:**
- Modify: `lib/data/datasources/local/app_database.dart`
- Modify: `lib/data/models/chat_session.dart`

- [ ] **Step 1: Update WorkspaceProjects table**

In `lib/data/datasources/local/app_database.dart`, replace the `WorkspaceProjects` table:

```dart
@DataClassName('WorkspaceProjectRow')
class WorkspaceProjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get path => text()();
  BoolColumn get isGit => boolean().withDefault(const Constant(false))();
  TextColumn get currentBranch => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 2: Add projectId to ChatSessions table**

In the same file, add a `projectId` column to `ChatSessions`:

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

  @override
  Set<Column> get primaryKey => {sessionId};
}
```

- [ ] **Step 3: Update ProjectDao**

Replace the `ProjectDao` in the same file:

```dart
@DriftAccessor(tables: [WorkspaceProjects])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.db);

  Future<List<WorkspaceProjectRow>> getAllProjects() => (select(
        workspaceProjects,
      )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<WorkspaceProjectRow>> watchAllProjects() => (select(
        workspaceProjects,
      )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<WorkspaceProjectRow?> getProject(String id) => (select(
        workspaceProjects,
      )..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertProject(WorkspaceProjectsCompanion project) =>
      into(workspaceProjects).insertOnConflictUpdate(project);

  Future<void> deleteProject(String id) =>
      (delete(workspaceProjects)..where((t) => t.id.equals(id))).go();
}
```

- [ ] **Step 4: Update SessionDao to filter by projectId**

Add a method to `SessionDao`:

```dart
Stream<List<ChatSessionRow>> watchSessionsByProject(String projectId) =>
    (select(chatSessions)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
```

- [ ] **Step 5: Add schema migration**

Update `AppDatabase` class:

```dart
@DriftDatabase(
  tables: [ChatSessions, ChatMessages, WorkspaceProjects],
  daos: [SessionDao, ProjectDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            // Add projectId column to chat_sessions
            await migrator.addColumn(chatSessions, chatSessions.projectId);
            // Recreate workspace_projects with new schema
            await migrator.deleteTable('workspace_projects');
            await migrator.createTable(workspaceProjects);
          }
        },
      );
}
```

- [ ] **Step 6: Update ChatSession freezed model**

In `lib/data/models/chat_session.dart`:

```dart
@freezed
class ChatSession with _$ChatSession {
  const factory ChatSession({
    required String sessionId,
    required String title,
    required String modelId,
    required String providerId,
    String? projectId,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isPinned,
  }) = _ChatSession;

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);
}
```

- [ ] **Step 7: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Build completes successfully, generates updated `.g.dart` and `.freezed.dart` files.

- [ ] **Step 8: Verify compilation**

Run: `flutter analyze`
Expected: No errors (warnings OK).

- [ ] **Step 9: Commit**

```bash
git add lib/data/datasources/local/app_database.dart lib/data/models/chat_session.dart
git commit -m "feat: migrate database schema for chat-first redesign (v2)"
```

---

## Task 2: Project Model and Git Detector

**Files:**
- Create: `lib/data/models/project.dart`
- Create: `lib/services/project/git_detector.dart`

- [ ] **Step 1: Create Project freezed model**

Create `lib/data/models/project.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    required String path,
    @Default(false) bool isGit,
    String? currentBranch,
    required DateTime createdAt,
    @Default(0) int sortOrder,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
```

- [ ] **Step 2: Create GitDetector**

Create `lib/services/project/git_detector.dart`:

```dart
import 'dart:io';

class GitDetector {
  /// Check if a directory is a git repository.
  static bool isGitRepo(String directoryPath) {
    final gitDir = Directory('$directoryPath/.git');
    return gitDir.existsSync();
  }

  /// Get the current branch name for a git repo.
  /// Returns null if not a git repo or branch cannot be determined.
  static String? getCurrentBranch(String directoryPath) {
    if (!isGitRepo(directoryPath)) return null;
    try {
      final result = Process.runSync(
        'git',
        ['rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: directoryPath,
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 3: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `project.freezed.dart` and `project.g.dart`.

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/project.dart lib/data/models/project.freezed.dart lib/data/models/project.g.dart lib/services/project/git_detector.dart
git commit -m "feat: add Project model and GitDetector"
```

---

## Task 3: Project Service

**Files:**
- Create: `lib/services/project/project_service.dart`
- Modify: `lib/services/session/session_service.dart`

- [ ] **Step 1: Create ProjectService**

Create `lib/services/project/project_service.dart`:

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/models/project.dart';
import 'git_detector.dart';

part 'project_service.g.dart';

@Riverpod(keepAlive: true)
ProjectService projectService(Ref ref) {
  return ProjectService(ref);
}

class ProjectService {
  ProjectService(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  Stream<List<Project>> watchAllProjects() {
    return _db.projectDao.watchAllProjects().map(
          (rows) => rows.map(_projectFromRow).toList(),
        );
  }

  Future<Project> addExistingFolder(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      throw ArgumentError('Directory does not exist: $directoryPath');
    }

    final id = _uuid.v4();
    final name = dir.uri.pathSegments
        .lastWhere((s) => s.isNotEmpty, orElse: () => directoryPath);
    final isGit = GitDetector.isGitRepo(directoryPath);
    final branch = isGit ? GitDetector.getCurrentBranch(directoryPath) : null;

    await _db.projectDao.upsertProject(
      WorkspaceProjectsCompanion(
        id: Value(id),
        name: Value(name),
        path: Value(directoryPath),
        isGit: Value(isGit),
        currentBranch: Value(branch),
        createdAt: Value(DateTime.now()),
        sortOrder: Value(0),
      ),
    );

    return Project(
      id: id,
      name: name,
      path: directoryPath,
      isGit: isGit,
      currentBranch: branch,
      createdAt: DateTime.now(),
    );
  }

  Future<Project> createNewFolder(String parentPath, String folderName) async {
    final fullPath = '$parentPath/$folderName';
    final dir = Directory(fullPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return addExistingFolder(fullPath);
  }

  Future<void> removeProject(String projectId) async {
    // Only removes from the database — does NOT delete the folder from disk
    await _db.projectDao.deleteProject(projectId);
  }

  Future<void> renameProject(String projectId, String newName) async {
    await _db.projectDao.upsertProject(
      WorkspaceProjectsCompanion(
        id: Value(projectId),
        name: Value(newName),
      ),
    );
  }

  Future<void> refreshGitStatus(String projectId) async {
    final row = await _db.projectDao.getProject(projectId);
    if (row == null) return;

    final isGit = GitDetector.isGitRepo(row.path);
    final branch = isGit ? GitDetector.getCurrentBranch(row.path) : null;

    await _db.projectDao.upsertProject(
      WorkspaceProjectsCompanion(
        id: Value(projectId),
        isGit: Value(isGit),
        currentBranch: Value(branch),
      ),
    );
  }

  Project _projectFromRow(WorkspaceProjectRow row) {
    return Project(
      id: row.id,
      name: row.name,
      path: row.path,
      isGit: row.isGit,
      currentBranch: row.currentBranch,
      createdAt: row.createdAt,
      sortOrder: row.sortOrder,
    );
  }
}
```

- [ ] **Step 2: Update SessionService to accept projectId**

In `lib/services/session/session_service.dart`, update `createSession`:

```dart
Future<String> createSession({required AIModel model, String? title, String? projectId}) async {
  final sessionId = _uuid.v4();
  final now = DateTime.now();
  await _db.sessionDao.upsertSession(
    ChatSessionsCompanion(
      sessionId: Value(sessionId),
      title: Value(title ?? 'New Chat'),
      modelId: Value(model.modelId),
      providerId: Value(model.provider.name),
      projectId: Value(projectId),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
  return sessionId;
}
```

Also add a method to watch sessions by project:

```dart
Stream<List<session_model.ChatSession>> watchSessionsByProject(String projectId) {
  return _db.sessionDao.watchSessionsByProject(projectId).map(
        (rows) => rows.map(_sessionFromRow).toList(),
      );
}
```

And update `_sessionFromRow` to include `projectId`:

```dart
session_model.ChatSession _sessionFromRow(ChatSessionRow row) {
  return session_model.ChatSession(
    sessionId: row.sessionId,
    title: row.title,
    modelId: row.modelId,
    providerId: row.providerId,
    projectId: row.projectId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    isPinned: row.isPinned,
  );
}
```

- [ ] **Step 3: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/project/project_service.dart lib/services/session/session_service.dart
git commit -m "feat: add ProjectService with folder and git operations"
```

---

## Task 4: Sidebar State Management

**Files:**
- Create: `lib/features/project_sidebar/project_sidebar_notifier.dart`
- Modify: `lib/features/chat/chat_notifier.dart`

- [ ] **Step 1: Create sidebar notifier**

Create `lib/features/project_sidebar/project_sidebar_notifier.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/project.dart';
import '../../services/project/project_service.dart';

part 'project_sidebar_notifier.g.dart';

/// Currently active project ID
@Riverpod(keepAlive: true)
class ActiveProjectId extends _$ActiveProjectId {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

/// Set of expanded project IDs in the sidebar
@Riverpod(keepAlive: true)
class ExpandedProjectIds extends _$ExpandedProjectIds {
  @override
  Set<String> build() => {};

  void toggle(String projectId) {
    if (state.contains(projectId)) {
      state = {...state}..remove(projectId);
    } else {
      state = {...state, projectId};
    }
  }

  void expand(String projectId) {
    state = {...state, projectId};
  }

  void collapse(String projectId) {
    state = {...state}..remove(projectId);
  }
}

/// Watch all projects from the database
@riverpod
Stream<List<Project>> projects(Ref ref) {
  final service = ref.watch(projectServiceProvider);
  return service.watchAllProjects();
}
```

- [ ] **Step 2: Update chat_notifier to support project-scoped sessions**

In `lib/features/chat/chat_notifier.dart`, replace the `chatSessions` provider:

```dart
// Sessions for a specific project
@riverpod
Stream<List<ChatSession>> projectSessions(Ref ref, String projectId) {
  final service = ref.watch(sessionServiceProvider);
  return service.watchSessionsByProject(projectId);
}

// All sessions (for backwards compat during migration)
@riverpod
Stream<List<ChatSession>> chatSessions(Ref ref) {
  final service = ref.watch(sessionServiceProvider);
  return service.watchAllSessions();
}
```

- [ ] **Step 3: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/project_sidebar/project_sidebar_notifier.dart lib/features/chat/chat_notifier.dart
git commit -m "feat: add sidebar state management and project-scoped sessions"
```

---

## Task 5: Project Sidebar UI

**Files:**
- Create: `lib/features/project_sidebar/project_sidebar.dart`
- Create: `lib/features/project_sidebar/widgets/project_tile.dart`
- Create: `lib/features/project_sidebar/widgets/conversation_tile.dart`
- Create: `lib/features/project_sidebar/widgets/project_context_menu.dart`

- [ ] **Step 1: Create ConversationTile**

Create `lib/features/project_sidebar/widgets/conversation_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/chat_session.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.session,
    required this.isActive,
    required this.onTap,
  });

  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A1A1A) : null,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isActive ? ThemeConstants.accent : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            // Title
            Expanded(
              child: Text(
                session.title,
                style: TextStyle(
                  color: isActive
                      ? ThemeConstants.textPrimary
                      : const Color(0xFF555555),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Time
            Text(
              _relativeTime(session.updatedAt),
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create ProjectContextMenu**

Create `lib/features/project_sidebar/widgets/project_context_menu.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/theme_constants.dart';

class ProjectContextMenu {
  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required String projectPath,
    required bool isGit,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      items: [
        _buildItem('open_finder', 'Open in Finder', Icons.folder_open_outlined),
        _buildItem('copy_path', 'Copy path', Icons.copy_outlined),
        _buildItem('rename', 'Rename project', Icons.edit_outlined),
        const PopupMenuDivider(),
        _buildItem('new_conversation', 'New conversation', Icons.add),
        const PopupMenuDivider(),
        _buildDangerItem('remove', 'Remove from Code Bench'),
      ],
    );
  }

  static PopupMenuItem<String> _buildItem(
    String value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 14, color: ThemeConstants.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static PopupMenuItem<String> _buildDangerItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: Row(
        children: [
          const Icon(Icons.close, size: 14, color: ThemeConstants.error),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: ThemeConstants.error,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> handleAction({
    required String action,
    required String projectId,
    required String projectPath,
    required BuildContext context,
    required Function(String) onRemove,
    required Function(String) onRename,
    required Function(String) onNewConversation,
  }) async {
    switch (action) {
      case 'open_finder':
        Process.run('open', [projectPath]);
      case 'copy_path':
        await Clipboard.setData(ClipboardData(text: projectPath));
      case 'rename':
        onRename(projectId);
      case 'new_conversation':
        onNewConversation(projectId);
      case 'remove':
        onRemove(projectId);
    }
  }
}
```

Add `import 'dart:io';` at the top of the file.

- [ ] **Step 3: Create ProjectTile**

Create `lib/features/project_sidebar/widgets/project_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/chat_session.dart';
import '../../../data/models/project.dart';
import 'conversation_tile.dart';
import 'project_context_menu.dart';

class ProjectTile extends ConsumerWidget {
  const ProjectTile({
    super.key,
    required this.project,
    required this.sessions,
    required this.isExpanded,
    required this.activeSessionId,
    required this.onToggleExpand,
    required this.onSessionTap,
    required this.onRemove,
    required this.onRename,
    required this.onNewConversation,
  });

  final Project project;
  final List<ChatSession> sessions;
  final bool isExpanded;
  final String? activeSessionId;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onSessionTap;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onNewConversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project header
        GestureDetector(
          onSecondaryTapUp: (details) async {
            final action = await ProjectContextMenu.show(
              context: context,
              position: details.globalPosition,
              projectPath: project.path,
              isGit: project.isGit,
            );
            if (action != null && context.mounted) {
              await ProjectContextMenu.handleAction(
                action: action,
                projectId: project.id,
                projectPath: project.path,
                context: context,
                onRemove: onRemove,
                onRename: onRename,
                onNewConversation: onNewConversation,
              );
            }
          },
          child: InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Chevron
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 16,
                    color: const Color(0xFF444444),
                  ),
                  const SizedBox(width: 4),
                  // Folder icon
                  const Icon(
                    Icons.folder_outlined,
                    size: 14,
                    color: Color(0xFF9D9D9D),
                  ),
                  const SizedBox(width: 6),
                  // Project name
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Git tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: project.isGit
                          ? const Color(0xFF0D2818)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      project.isGit
                          ? project.currentBranch ?? 'git'
                          : 'Not git',
                      style: TextStyle(
                        color: project.isGit
                            ? ThemeConstants.success
                            : const Color(0xFF555555),
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Conversations list (when expanded)
        if (isExpanded && sessions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 10, bottom: 6),
            child: Column(
              children: sessions
                  .map(
                    (s) => ConversationTile(
                      session: s,
                      isActive: s.sessionId == activeSessionId,
                      onTap: () => onSessionTap(s.sessionId),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Create ProjectSidebar**

Create `lib/features/project_sidebar/project_sidebar.dart`:

```dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/ai_model.dart';
import '../../features/chat/chat_notifier.dart';
import '../../services/project/project_service.dart';
import '../../services/session/session_service.dart';
import 'project_sidebar_notifier.dart';
import 'widgets/project_tile.dart';

class ProjectSidebar extends ConsumerWidget {
  const ProjectSidebar({super.key});

  Future<void> _addProject(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select project folder',
    );
    if (result == null) return;

    final service = ref.read(projectServiceProvider);
    final project = await service.addExistingFolder(result);
    ref.read(activeProjectIdProvider.notifier).set(project.id);
    ref.read(expandedProjectIdsProvider.notifier).expand(project.id);
  }

  Future<void> _newConversation(
    BuildContext context,
    WidgetRef ref,
    String projectId,
  ) async {
    final model = ref.read(selectedModelProvider);
    final service = ref.read(sessionServiceProvider);
    final sessionId = await service.createSession(
      model: model,
      projectId: projectId,
    );
    ref.read(activeSessionIdProvider.notifier).set(sessionId);
    ref.read(activeProjectIdProvider.notifier).set(projectId);
    if (context.mounted) context.go('/chat/$sessionId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final expandedIds = ref.watch(expandedProjectIdsProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);
    final activeProjectId = ref.watch(activeProjectIdProvider);

    return Container(
      width: 224,
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E1E1E)),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'PROJECTS',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _addProject(context, ref),
                  child: const Icon(
                    Icons.add,
                    size: 14,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
          // Project list
          Expanded(
            child: projectsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(
                    color: ThemeConstants.error,
                    fontSize: 11,
                  ),
                ),
              ),
              data: (projects) {
                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.folder_outlined,
                          size: 32,
                          color: Color(0xFF333333),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No projects yet',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _addProject(context, ref),
                          icon: const Icon(Icons.add, size: 12),
                          label: const Text(
                            'Open folder',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, i) {
                    final project = projects[i];
                    final sessionsAsync = ref.watch(
                      projectSessionsProvider(project.id),
                    );
                    final sessions = sessionsAsync.valueOrNull ?? [];

                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF141414)),
                        ),
                      ),
                      child: ProjectTile(
                        project: project,
                        sessions: sessions,
                        isExpanded: expandedIds.contains(project.id),
                        activeSessionId: activeSessionId,
                        onToggleExpand: () => ref
                            .read(expandedProjectIdsProvider.notifier)
                            .toggle(project.id),
                        onSessionTap: (sessionId) {
                          ref
                              .read(activeSessionIdProvider.notifier)
                              .set(sessionId);
                          ref
                              .read(activeProjectIdProvider.notifier)
                              .set(project.id);
                          context.go('/chat/$sessionId');
                        },
                        onRemove: (id) =>
                            ref.read(projectServiceProvider).removeProject(id),
                        onRename: (_) {
                          // TODO: show rename dialog
                        },
                        onNewConversation: (id) =>
                            _newConversation(context, ref, id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Settings footer
          InkWell(
            onTap: () => context.go('/settings'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 14,
                    color: Color(0xFF555555),
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Verify compilation**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/project_sidebar/
git commit -m "feat: add project sidebar with collapsible projects and context menu"
```

---

## Task 6: New Shell, Top Bar, Status Bar, and Input Bar

**Files:**
- Create: `lib/shell/chat_shell.dart`
- Create: `lib/shell/widgets/top_action_bar.dart`
- Create: `lib/shell/widgets/status_bar.dart`
- Create: `lib/features/chat/widgets/chat_input_bar_v2.dart`

- [ ] **Step 1: Create TopActionBar**

Create `lib/shell/widgets/top_action_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/project.dart';
import '../../features/chat/chat_notifier.dart';
import '../../features/project_sidebar/project_sidebar_notifier.dart';

class TopActionBar extends ConsumerWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = ref.watch(activeSessionIdProvider);
    final projectId = ref.watch(activeProjectIdProvider);
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final projectsAsync = ref.watch(projectsProvider);

    final sessionTitle = sessionsAsync.whenOrNull(
          data: (List<ChatSession> list) {
            if (sessionId == null) return 'Code Bench';
            try {
              return list.firstWhere((s) => s.sessionId == sessionId).title;
            } catch (_) {
              return 'New Chat';
            }
          },
        ) ??
        'Code Bench';

    final projectName = projectsAsync.whenOrNull(
          data: (List<Project> list) {
            if (projectId == null) return null;
            try {
              return list.firstWhere((p) => p.id == projectId).name;
            } catch (_) {
              return null;
            }
          },
        );

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Row(
        children: [
          Text(
            sessionTitle,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (projectName != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                projectName,
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 10,
                ),
              ),
            ),
          ],
          const Spacer(),
          // Action buttons
          _ActionButton(
            icon: Icons.add,
            label: 'Add action',
            onTap: () {},
          ),
          const SizedBox(width: 5),
          _ActionButton(
            icon: Icons.folder_open_outlined,
            label: 'Open',
            onTap: () {},
          ),
          const SizedBox(width: 5),
          _ActionButton(
            icon: Icons.commit_outlined,
            label: 'Commit & Push',
            isPrimary: true,
            onTap: () {
              // Prompt user for review before committing
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isPrimary ? ThemeConstants.accent : const Color(0xFF1A1A1A),
          border: Border.all(
            color: isPrimary ? ThemeConstants.accent : const Color(0xFF222222),
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isPrimary ? Colors.white : const Color(0xFF888888),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF888888),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create StatusBar**

Create `lib/shell/widgets/status_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/project.dart';
import '../../features/project_sidebar/project_sidebar_notifier.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(activeProjectIdProvider);
    final projectsAsync = ref.watch(projectsProvider);

    Project? activeProject;
    if (projectId != null) {
      activeProject = projectsAsync.whenOrNull(
        data: (list) {
          try {
            return list.firstWhere((p) => p.id == projectId);
          } catch (_) {
            return null;
          }
        },
      );
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Row(
        children: [
          // Left: Local indicator
          const Icon(
            Icons.folder_outlined,
            size: 10,
            color: Color(0xFF444444),
          ),
          const SizedBox(width: 5),
          const Text(
            'Local',
            style: TextStyle(color: Color(0xFF444444), fontSize: 10),
          ),
          const Spacer(),
          // Right: Git branch
          if (activeProject != null && activeProject.isGit) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: ThemeConstants.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              activeProject.currentBranch ?? 'unknown',
              style: const TextStyle(
                color: ThemeConstants.success,
                fontSize: 10,
              ),
            ),
          ] else if (activeProject != null) ...[
            const Text(
              'Not git',
              style: TextStyle(color: Color(0xFF444444), fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create ChatInputBarV2**

Create `lib/features/chat/widgets/chat_input_bar_v2.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/ai_model.dart';
import '../chat_notifier.dart';

class ChatInputBarV2 extends ConsumerStatefulWidget {
  const ChatInputBarV2({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ChatInputBarV2> createState() => _ChatInputBarV2State();
}

class _ChatInputBarV2State extends ConsumerState<ChatInputBarV2> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() => _isSending = true);

    try {
      final systemPrompt = ref.read(
        sessionSystemPromptProvider,
      )[widget.sessionId];
      await ref
          .read(chatMessagesProvider(widget.sessionId).notifier)
          .sendMessage(
            text,
            systemPrompt: (systemPrompt != null && systemPrompt.isNotEmpty)
                ? systemPrompt
                : null,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(selectedModelProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF222222)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text input
            KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  _send();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                style: const TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 12,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask anything, @tag files/folders, or use /command',
                  hintStyle: TextStyle(color: Color(0xFF444444), fontSize: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Controls row
            Container(
              padding: const EdgeInsets.only(top: 7),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
              ),
              child: Row(
                children: [
                  // Model selector
                  _ControlChip(
                    icon: Icons.bolt,
                    label: model.name,
                    onTap: () => _showModelPicker(context, ref),
                  ),
                  const _Separator(),
                  // Effort
                  _ControlChip(label: 'High', onTap: () {}),
                  const _Separator(),
                  // Mode
                  _ControlChip(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    onTap: () {},
                  ),
                  const _Separator(),
                  // Permissions
                  _ControlChip(
                    icon: Icons.lock_outline,
                    label: 'Full access',
                    onTap: () {},
                  ),
                  const Spacer(),
                  // Send button
                  GestureDetector(
                    onTap: _isSending ? null : _send,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: ThemeConstants.accent,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(BuildContext context, WidgetRef ref) {
    final models = AIModels.defaults;
    showMenu<AIModel>(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      color: const Color(0xFF1E1E1E),
      items: models
          .map(
            (m) => PopupMenuItem(
              value: m,
              child: Text(
                '${m.provider.displayName} / ${m.name}',
                style: const TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 11,
                ),
              ),
            ),
          )
          .toList(),
    ).then((selected) {
      if (selected != null) {
        ref.read(selectedModelProvider.notifier).select(selected);
      }
    });
  }
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: const Color(0xFF888888)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_drop_down,
              size: 10,
              color: Color(0xFF333333),
            ),
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        '|',
        style: TextStyle(color: Color(0xFF222222), fontSize: 11),
      ),
    );
  }
}
```

- [ ] **Step 4: Create ChatShell**

Create `lib/shell/chat_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/theme_constants.dart';
import '../features/chat/chat_notifier.dart';
import '../features/project_sidebar/project_sidebar.dart';
import '../features/project_sidebar/project_sidebar_notifier.dart';
import '../services/session/session_service.dart';
import 'widgets/status_bar.dart';
import 'widgets/top_action_bar.dart';

class ChatShell extends ConsumerWidget {
  const ChatShell({super.key, required this.child});

  final Widget child;

  Future<void> _newChat(WidgetRef ref, BuildContext context) async {
    final projectId = ref.read(activeProjectIdProvider);
    if (projectId == null) return;
    final model = ref.read(selectedModelProvider);
    final service = ref.read(sessionServiceProvider);
    final sessionId = await service.createSession(
      model: model,
      projectId: projectId,
    );
    ref.read(activeSessionIdProvider.notifier).set(sessionId);
    if (context.mounted) context.go('/chat/$sessionId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: ThemeConstants.background,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
              _newChat(ref, context),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
              _newChat(ref, context),
          const SingleActivator(LogicalKeyboardKey.comma, meta: true): () =>
              context.go('/settings'),
          const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
              context.go('/settings'),
        },
        child: Focus(
          autofocus: true,
          child: Row(
            children: [
              // Sidebar
              const ProjectSidebar(),
              // Right panel
              Expanded(
                child: Column(
                  children: [
                    const TopActionBar(),
                    Expanded(child: child),
                    const StatusBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Verify compilation**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/shell/chat_shell.dart lib/shell/widgets/top_action_bar.dart lib/shell/widgets/status_bar.dart lib/features/chat/widgets/chat_input_bar_v2.dart
git commit -m "feat: add new shell layout with sidebar, top bar, status bar, and input controls"
```

---

## Task 7: Update Router and Chat Screen

**Files:**
- Modify: `lib/router/app_router.dart`
- Modify: `lib/features/chat/chat_screen.dart`
- Modify: `lib/core/constants/app_constants.dart`

- [ ] **Step 1: Simplify router**

Replace `lib/router/app_router.dart`:

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/datasources/local/onboarding_preferences.dart';
import '../features/chat/chat_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shell/chat_shell.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/chat',
    redirect: (context, state) async {
      final prefs = ref.read(onboardingPreferencesProvider);
      final done = await prefs.isCompleted();
      if (!done && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ChatShell(child: child),
        routes: [
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/chat/:sessionId',
            builder: (context, state) =>
                ChatScreen(sessionId: state.pathParameters['sessionId']),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
```

- [ ] **Step 2: Simplify ChatScreen**

Replace `lib/features/chat/chat_screen.dart` — remove the header and model selector (now in TopActionBar and InputBar):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import 'chat_notifier.dart';
import 'widgets/chat_input_bar_v2.dart';
import 'widgets/message_list.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sessionId != null) {
        ref.read(activeSessionIdProvider.notifier).set(widget.sessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = ref.watch(activeSessionIdProvider);

    if (sessionId == null) {
      return const Scaffold(
        backgroundColor: ThemeConstants.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Color(0xFF333333),
              ),
              SizedBox(height: 16),
              Text(
                'Select a project and start a conversation',
                style: TextStyle(color: Color(0xFF555555), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Column(
        children: [
          Expanded(child: MessageList(sessionId: sessionId)),
          ChatInputBarV2(sessionId: sessionId),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Update AppConstants**

In `lib/core/constants/app_constants.dart`, remove pane width constants and add sidebar constant:

```dart
class AppConstants {
  AppConstants._();

  static const String appName = 'Code Bench';
  static const String appVersion = '1.0.0';
  static const String oauthScheme = 'codebench';
  static const String oauthCallbackUrl = 'codebench://oauth/callback';

  // Window
  static const double minWindowWidth = 900;
  static const double minWindowHeight = 600;

  // Sidebar
  static const double sidebarWidth = 224;

  // Chat
  static const int maxInMemoryMessages = 100;
  static const int messagePaginationLimit = 50;

  // SharedPreferences keys
  static const String prefWindowX = 'window_x';
  static const String prefWindowY = 'window_y';
  static const String prefWindowWidth = 'window_width';
  static const String prefWindowHeight = 'window_height';
}
```

- [ ] **Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Verify compilation**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/router/app_router.dart lib/features/chat/chat_screen.dart lib/core/constants/app_constants.dart
git commit -m "feat: simplify router and chat screen for chat-first layout"
```

---

## Task 8: Remove Old Files

**Files:**
- Delete: All files listed in the "Removed Files" section of the file map

- [ ] **Step 1: Delete old shell and feature files**

```bash
rm lib/shell/desktop_shell.dart
rm lib/shell/widgets/side_nav_rail.dart
rm lib/shell/widgets/app_title_bar.dart
rm lib/features/file_explorer/file_explorer_panel.dart
rm lib/features/dashboard/dashboard_screen.dart
rm lib/features/editor/editor_screen.dart
rm lib/features/editor/editor_notifier.dart
rm lib/features/editor/editor_notifier.g.dart
rm lib/features/editor/widgets/code_editor_widget.dart
rm lib/features/editor/widgets/file_tab_bar.dart
rm lib/features/compare/compare_screen.dart
rm lib/features/github/github_screen.dart
rm lib/features/github/widgets/pr_list_widget.dart
rm lib/features/github/widgets/commit_dialog.dart
rm lib/features/github/widgets/repo_file_tree.dart
rm lib/features/chat/chat_panel.dart
rm lib/features/chat/chat_home_screen.dart
rm lib/features/chat/widgets/chat_input_bar.dart
```

- [ ] **Step 2: Remove empty directories**

```bash
rmdir lib/features/editor/widgets 2>/dev/null
rmdir lib/features/editor 2>/dev/null
rmdir lib/features/file_explorer 2>/dev/null
rmdir lib/features/dashboard 2>/dev/null
rmdir lib/features/compare 2>/dev/null
rmdir lib/features/github/widgets 2>/dev/null
rmdir lib/features/github 2>/dev/null
```

- [ ] **Step 3: Remove stale imports**

Check for any remaining imports of deleted files. Grep for them:

```bash
grep -r "editor_notifier" lib/ --include="*.dart" -l
grep -r "desktop_shell" lib/ --include="*.dart" -l
grep -r "chat_panel" lib/ --include="*.dart" -l
grep -r "chat_home_screen" lib/ --include="*.dart" -l
grep -r "file_explorer" lib/ --include="*.dart" -l
grep -r "dashboard_screen" lib/ --include="*.dart" -l
grep -r "github_screen" lib/ --include="*.dart" -l
grep -r "compare_screen" lib/ --include="*.dart" -l
grep -r "side_nav_rail" lib/ --include="*.dart" -l
grep -r "app_title_bar" lib/ --include="*.dart" -l
grep -r "chat_input_bar.dart" lib/ --include="*.dart" -l
```

Remove any stale import lines found.

- [ ] **Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Verify compilation**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: remove old editor-centric shell, nav rail, and feature screens"
```

---

## Task 9: Update Window Configuration

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Update window options**

In `lib/main.dart`, update the `WindowOptions` to use the new constants and remove the normal title bar (use macOS native traffic lights):

```dart
await windowManager.waitUntilReadyToShow(
  WindowOptions(
    size: const Size(
      AppConstants.minWindowWidth + 200,
      AppConstants.minWindowHeight + 100,
    ),
    minimumSize: const Size(
      AppConstants.minWindowWidth,
      AppConstants.minWindowHeight,
    ),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
    title: AppConstants.appName,
  ),
  () async {
    await windowManager.show();
    await windowManager.focus();
  },
);
```

- [ ] **Step 2: Verify the app runs**

Run: `flutter run -d macos`
Expected: App launches with the new chat-first layout — sidebar on left, chat on right, no editor panes.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: update window config for chat-first layout with hidden title bar"
```

---

## Task 10: Final Verification

- [ ] **Step 1: Run dart format**

Run: `dart format lib/ test/`

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 3: Run flutter test**

Run: `flutter test`
Expected: All existing tests pass (some may need updating if they reference deleted screens).

- [ ] **Step 4: Manual smoke test**

Run: `flutter run -d macos` and verify:
- Sidebar shows "PROJECTS" header with add button
- Can add a project via folder picker
- Git repos show branch name; non-git folders show "Not git"
- Can collapse/expand projects
- Right-click shows context menu with Copy path, Remove from Code Bench, etc.
- Can create a new conversation under a project
- Chat messages stream correctly
- Input bar shows model selector, effort, mode, permissions
- Status bar shows Local + git branch
- Top bar shows conversation title + project badge
- Settings accessible from sidebar footer
- ⌘N creates new chat, ⌘, opens settings

- [ ] **Step 5: Commit and format fixes**

```bash
git add -A
git commit -m "chore: final formatting and verification for chat-first redesign"
```
