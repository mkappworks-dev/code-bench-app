# Phase 8 — Missing Project Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Detect when a tracked project's folder has been deleted from the filesystem; render it in a muted "missing" state in the sidebar; allow the user to **Relocate** (pick a new folder) or **Remove** (with optional cascade-delete of its sessions); block all write operations (apply, git, IDE launch, actions, commit, push) on missing projects with clear feedback.

**Architecture:** Status is **computed**, not persisted. `ProjectService._projectFromRow` calls `Directory(path).existsSync()` for each row and sets a new `ProjectStatus` enum field. Missing projects stay in the DB with all their sessions intact; the sidebar renders them with a muted/strikethrough label + warning icon and exposes a `Relocate…` context-menu action. Write call-sites (top action bar buttons, `ApplyService`) do an additional fresh `existsSync` check at the moment of the action — defense in depth against UI staleness.

**Tech Stack:** Flutter, Riverpod (keepAlive notifiers), `freezed`, `dart:io` (`Directory.existsSync`), Drift (existing `ProjectDao.updateProject` from phase 3), `file_picker` (already in `pubspec.yaml` at ^8.1.2).

**Prerequisite:** This plan depends on `feat/2026-04-10-phase3-stub-button-functionality` — specifically the `ProjectDao.updateProject` method and the `kDebugMode` + `debugPrint` error-logging pattern. Branch from `main` **after phase 3 is merged**, or rebase this branch onto phase 3's tip if working in parallel.

> **Note:** There is no project-rename feature — `Project.name` is derived from the folder basename on disk and must stay in lockstep with the filesystem. If you see `onRename` / `renameProject` / `RenameProjectDialog` anywhere, it is stale and must not be reintroduced.

**Worktree:**

```bash
git worktree add .worktrees/feat/2026-04-10-missing-project-detection -b feat/2026-04-10-missing-project-detection
cd .worktrees/feat/2026-04-10-missing-project-detection
```

---

## File Map

| Status | File | Responsibility |
|---|---|---|
| Modify | `lib/data/models/project.dart` | Add `ProjectStatus` enum; add `@Default(ProjectStatus.available) status` field |
| Modify | `lib/services/project/project_service.dart` | Compute `status` in `_projectFromRow`; add `relocateProject(id, newPath)`; add `refreshProjectStatuses()` |
| **Create** | `lib/features/project_sidebar/widgets/relocate_project_dialog.dart` | Folder-picker dialog bound to `relocateProject` |
| **Create** | `lib/features/project_sidebar/widgets/remove_project_dialog.dart` | Remove confirmation dialog with optional "Also delete N conversations" toggle |
| Modify | `lib/features/project_sidebar/widgets/project_context_menu.dart` | Add `relocate` menu item; pass `isMissing` through `show()` to reorder items |
| Modify | `lib/features/project_sidebar/widgets/project_tile.dart` | Render muted/strikethrough label + warning icon for missing state; hide hover new-chat affordance; wire `relocate` and new remove-with-cascade flow |
| Modify | `lib/features/project_sidebar/project_sidebar.dart` | Replace direct `removeProject(id)` call with `RemoveProjectDialog.show(...)`; wire relocate flow |
| Modify | `lib/services/apply/apply_service.dart` | Replace generic `StateError('Project root does not exist...')` with typed `ProjectMissingException` |
| Modify | `lib/shell/widgets/top_action_bar.dart` | Fresh `existsSync` guard before every write action; disabled-look and snackbar for missing state |
| **Create** | `test/services/project/project_service_missing_test.dart` | Unit tests: detection on create/read, relocate updates path + status, refreshProjectStatuses re-emits |

---

## Task 1: `ProjectStatus` enum + `Project.status` field

**Files:**
- Modify: `lib/data/models/project.dart`

- [ ] **Step 1.1: Replace `project.dart` with the new model**

  Replace the entire contents of `lib/data/models/project.dart` with:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  import 'project_action.dart';

  part 'project.freezed.dart';
  part 'project.g.dart';

  enum ProjectStatus {
    /// The project folder exists on disk and is usable for all operations.
    available,

    /// The project folder is missing from disk. The project row stays in the
    /// DB (along with any linked chat sessions) but all write operations are
    /// blocked until the user either Relocates or Removes it.
    missing,
  }

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
      @Default([]) List<ProjectAction> actions,
      @Default(ProjectStatus.available) ProjectStatus status,
    }) = _Project;

    factory Project.fromJson(Map<String, dynamic> json) =>
        _$ProjectFromJson(json);
  }
  ```

  Note: the `actions` field is already present from phase 3; this task only adds `ProjectStatus` and the `status` field.

- [ ] **Step 1.2: Regenerate freezed + json code**

  Run: `dart run build_runner build --delete-conflicting-outputs`
  Expected: build succeeds; `project.freezed.dart` and `project.g.dart` regenerate with the new field.

- [ ] **Step 1.3: Verify the project compiles unchanged**

  Run: `flutter analyze`
  Expected: 0 issues. All existing call-sites keep working because `status` has a default value.

- [ ] **Step 1.4: Commit**

  ```bash
  git add lib/data/models/project.dart lib/data/models/project.freezed.dart lib/data/models/project.g.dart
  git commit -m "feat: add ProjectStatus enum and status field to Project model"
  ```

---

## Task 2: Compute `status` in `ProjectService._projectFromRow` (TDD)

**Files:**
- Create: `test/services/project/project_service_missing_test.dart`
- Modify: `lib/services/project/project_service.dart`

- [ ] **Step 2.1: Write the failing test**

  Create `test/services/project/project_service_missing_test.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/datasources/local/app_database.dart';
  import 'package:code_bench_app/data/models/project.dart';
  import 'package:code_bench_app/services/project/project_service.dart';
  import 'package:drift/native.dart';

  void main() {
    late Directory tmpDir;
    late ProviderContainer container;
    late ProjectService service;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('project_missing_test_');
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith(
            (ref) => AppDatabase.forTesting(NativeDatabase.memory()),
          ),
        ],
      );
      service = container.read(projectServiceProvider);
    });

    tearDown(() async {
      container.dispose();
      if (tmpDir.existsSync()) await tmpDir.delete(recursive: true);
    });

    test('addExistingFolder returns status=available for an existing folder',
        () async {
      final project = await service.addExistingFolder(tmpDir.path);
      expect(project.status, ProjectStatus.available);
    });

    test('watchAllProjects reports status=missing after the folder is deleted',
        () async {
      final added = await service.addExistingFolder(tmpDir.path);
      await tmpDir.delete(recursive: true);

      // Force a re-emission by touching the row.
      await service.refreshProjectStatuses();

      final list = await service.watchAllProjects().first;
      final reloaded = list.firstWhere((p) => p.id == added.id);
      expect(reloaded.status, ProjectStatus.missing);
    });

    test('relocateProject updates path and flips status back to available',
        () async {
      final added = await service.addExistingFolder(tmpDir.path);
      await tmpDir.delete(recursive: true);
      await service.refreshProjectStatuses();

      final newDir =
          await Directory.systemTemp.createTemp('project_relocate_test_');
      addTearDown(() async {
        if (newDir.existsSync()) await newDir.delete(recursive: true);
      });

      await service.relocateProject(added.id, newDir.path);

      final list = await service.watchAllProjects().first;
      final reloaded = list.firstWhere((p) => p.id == added.id);
      expect(reloaded.path, newDir.path);
      expect(reloaded.status, ProjectStatus.available);
    });
  }
  ```

  This test uses an in-memory Drift database. If `AppDatabase.forTesting` does not exist yet, add a factory constructor to `lib/data/datasources/local/app_database.dart`:

  ```dart
  // Inside class AppDatabase, after the default constructor:
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);
  ```

- [ ] **Step 2.2: Run the test, verify it fails**

  Run: `flutter test test/services/project/project_service_missing_test.dart`
  Expected: FAIL — `refreshProjectStatuses` and `relocateProject` don't exist yet, and `status` is always `available`.

- [ ] **Step 2.3: Update `_projectFromRow` to compute status**

  In `lib/services/project/project_service.dart`, replace `_projectFromRow` with:

  ```dart
  Project _projectFromRow(WorkspaceProjectRow row) {
    List<ProjectAction> actions = const [];
    try {
      final decoded = jsonDecode(row.actionsJson) as List<dynamic>;
      actions = decoded
          .map((e) => ProjectAction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ProjectService] Failed to decode actionsJson: $e\n$st');
      }
    }

    final status = Directory(row.path).existsSync()
        ? ProjectStatus.available
        : ProjectStatus.missing;

    return Project(
      id: row.id,
      name: row.name,
      path: row.path,
      isGit: row.isGit,
      currentBranch: row.currentBranch,
      createdAt: row.createdAt,
      sortOrder: row.sortOrder,
      actions: actions,
      status: status,
    );
  }
  ```

- [ ] **Step 2.4: Add `refreshProjectStatuses` method**

  In `lib/services/project/project_service.dart`, add after `refreshGitStatus`:

  ```dart
  /// Touches every project row with a no-op write so Drift re-emits the
  /// `watchAllProjects` stream. Call this after operations that may have
  /// changed filesystem state outside the app (e.g. the user deleted a
  /// folder in Finder while Code Bench was running).
  Future<void> refreshProjectStatuses() async {
    final rows = await _db.projectDao.getAllProjects();
    for (final r in rows) {
      await _db.projectDao.updateProject(
        r.id,
        WorkspaceProjectsCompanion(sortOrder: Value(r.sortOrder)),
      );
    }
  }
  ```

- [ ] **Step 2.5: Add `relocateProject` method**

  In `lib/services/project/project_service.dart`, add after `refreshProjectStatuses`:

  ```dart
  /// Point an existing project at a new folder on disk. Used by the
  /// "Relocate…" action when the user has moved or restored a project
  /// folder under a different path. Preserves id, name, sessions, actions,
  /// and sortOrder; only the path (and derived git status) changes.
  Future<void> relocateProject(String projectId, String newPath) async {
    final dir = Directory(newPath);
    if (!dir.existsSync()) {
      throw ArgumentError('Directory does not exist: $newPath');
    }

    final isGit = GitDetector.isGitRepo(newPath);
    final branch = isGit ? GitDetector.getCurrentBranch(newPath) : null;

    await _db.projectDao.updateProject(
      projectId,
      WorkspaceProjectsCompanion(
        path: Value(newPath),
        isGit: Value(isGit),
        currentBranch: Value(branch),
      ),
    );
  }
  ```

- [ ] **Step 2.6: Run the test, verify it passes**

  Run: `flutter test test/services/project/project_service_missing_test.dart`
  Expected: PASS, all 3 tests green.

- [ ] **Step 2.7: Run full suite**

  Run: `flutter test`
  Expected: PASS — all existing tests keep passing.

- [ ] **Step 2.8: Format, analyze, commit**

  ```bash
  dart format lib/ test/
  flutter analyze
  git add lib/services/project/project_service.dart \
          lib/data/datasources/local/app_database.dart \
          test/services/project/project_service_missing_test.dart
  git commit -m "feat: compute Project.status and add relocate/refresh service methods"
  ```

---

## Task 3: Render missing state in `ProjectTile`

**Files:**
- Modify: `lib/features/project_sidebar/widgets/project_tile.dart`

- [ ] **Step 3.1: Add the missing-state imports**

  At the top of `lib/features/project_sidebar/widgets/project_tile.dart`, the existing imports are sufficient (`LucideIcons`, `Project`, `ThemeConstants`). No new imports needed.

- [ ] **Step 3.2: Compute `isMissing` inside `build`**

  In `_ProjectTileState.build`, at the top of the method, add:

  ```dart
  final isMissing = widget.project.status == ProjectStatus.missing;
  ```

- [ ] **Step 3.3: Update folder icon + label + hover affordance**

  Replace the children of the `Row` (currently: chevron, folder icon, project name, new-chat icon, git icon) with:

  ```dart
  // Chevron
  Icon(
    widget.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
    size: 14,
    color: ThemeConstants.faintFg,
  ),
  const SizedBox(width: 4),
  // Folder icon — warning triangle when missing
  Icon(
    isMissing ? LucideIcons.triangleAlert : LucideIcons.folder,
    size: 13,
    color: isMissing ? ThemeConstants.warning : ThemeConstants.textSecondary,
  ),
  const SizedBox(width: 6),
  // Project name — muted + strikethrough when missing
  Expanded(
    child: Tooltip(
      message: isMissing ? 'Folder not found: ${widget.project.path}' : '',
      child: Text(
        widget.project.name,
        style: TextStyle(
          color: isMissing
              ? ThemeConstants.mutedFg
              : ThemeConstants.textPrimary,
          fontSize: ThemeConstants.uiFontSize,
          fontWeight: FontWeight.w500,
          decoration: isMissing ? TextDecoration.lineThrough : null,
          decorationColor: ThemeConstants.mutedFg,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ),
  // New-chat icon — hidden entirely when missing
  if (!isMissing)
    AnimatedOpacity(
      opacity: _hovered ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 120),
      child: InkWell(
        onTap: () => widget.onNewConversation(widget.project.id),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(
            LucideIcons.messageSquarePlus,
            size: 13,
            color: ThemeConstants.mutedFg,
          ),
        ),
      ),
    ),
  const SizedBox(width: 4),
  // Git icon — faint when missing (no reliable branch info)
  Tooltip(
    message: (!isMissing && widget.project.isGit)
        ? (widget.project.currentBranch ?? 'git')
        : '',
    child: Icon(
      LucideIcons.gitBranch,
      size: 13,
      color: (!isMissing && widget.project.isGit)
          ? ThemeConstants.success
          : ThemeConstants.faintFg,
    ),
  ),
  ```

  If `ThemeConstants.warning` does not exist, add it to `lib/core/constants/theme_constants.dart` as `static const warning = Color(0xFFE0AF68);` (Tokyo Night yellow — matches the existing palette). If `LucideIcons.triangleAlert` is not available in the installed version, use `LucideIcons.alertTriangle`.

- [ ] **Step 3.4: Pass `isMissing` to the context menu**

  Update the `onSecondaryTapUp` callback in the same file:

  ```dart
  onSecondaryTapUp: (details) async {
    final action = await ProjectContextMenu.show(
      context: context,
      position: details.globalPosition,
      projectPath: widget.project.path,
      isGit: widget.project.isGit,
      isMissing: isMissing,
    );
    if (action != null && context.mounted) {
      await ProjectContextMenu.handleAction(
        action: action,
        projectId: widget.project.id,
        projectPath: widget.project.path,
        context: context,
        onRemove: widget.onRemove,
        onNewConversation: widget.onNewConversation,
        onRelocate: widget.onRelocate,
      );
    }
  },
  ```

- [ ] **Step 3.5: Add `onRelocate` to the widget's constructor**

  In `ProjectTile`, add the field and constructor parameter (alongside `onRemove`):

  ```dart
  final ValueChanged<String> onRelocate;
  ```

  And add `required this.onRelocate,` to the constructor.

- [ ] **Step 3.6: Format, analyze, commit**

  ```bash
  dart format lib/
  flutter analyze
  git add lib/features/project_sidebar/widgets/project_tile.dart \
          lib/core/constants/theme_constants.dart
  git commit -m "feat: render missing-state muted/strikethrough in ProjectTile"
  ```

---

## Task 4: Add "Relocate…" to the context menu

**Files:**
- Modify: `lib/features/project_sidebar/widgets/project_context_menu.dart`

- [ ] **Step 4.1: Add `isMissing` parameter and new menu item**

  Replace `ProjectContextMenu.show` with:

  ```dart
  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required String projectPath,
    required bool isGit,
    bool isMissing = false,
  }) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    return showInstantMenu<String>(
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
        if (!isMissing) ...[
          _buildItem('open_finder', 'Open in Finder', Icons.folder_open_outlined),
          _buildItem('copy_path', 'Copy path', Icons.copy_outlined),
          const PopupMenuDivider(),
          _buildItem('new_conversation', 'New conversation', Icons.add),
          const PopupMenuDivider(),
        ] else ...[
          _buildItem('copy_path', 'Copy path', Icons.copy_outlined),
          const PopupMenuDivider(),
          _buildItem('relocate', 'Relocate…', Icons.drive_file_move_outlined),
          const PopupMenuDivider(),
        ],
        _buildDangerItem('remove', 'Remove from Code Bench'),
      ],
    );
  }
  ```

  Rationale: when missing, `open_finder` and `new_conversation` make no sense, so the menu collapses to `copy_path` (for debugging) + `Relocate…` + `Remove`.

- [ ] **Step 4.2: Wire `onRelocate` through `handleAction`**

  Replace `ProjectContextMenu.handleAction` with:

  ```dart
  static Future<void> handleAction({
    required String action,
    required String projectId,
    required String projectPath,
    required BuildContext context,
    required Function(String) onRemove,
    required Function(String) onNewConversation,
    Function(String)? onRelocate,
  }) async {
    switch (action) {
      case 'open_finder':
        Process.run('open', [projectPath]);
      case 'copy_path':
        await Clipboard.setData(ClipboardData(text: projectPath));
      case 'new_conversation':
        onNewConversation(projectId);
      case 'relocate':
        onRelocate?.call(projectId);
      case 'remove':
        onRemove(projectId);
    }
  }
  ```

- [ ] **Step 4.3: Format, analyze, commit**

  ```bash
  dart format lib/
  flutter analyze
  git add lib/features/project_sidebar/widgets/project_context_menu.dart
  git commit -m "feat: add Relocate… item to project context menu"
  ```

---

## Task 5: `RelocateProjectDialog` widget

**Files:**
- Create: `lib/features/project_sidebar/widgets/relocate_project_dialog.dart`

- [ ] **Step 5.1: Create the dialog**

  Create `lib/features/project_sidebar/widgets/relocate_project_dialog.dart`:

  ```dart
  import 'package:file_picker/file_picker.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/project.dart';
  import '../../../services/project/project_service.dart';

  class RelocateProjectDialog extends ConsumerStatefulWidget {
    const RelocateProjectDialog({super.key, required this.project});

    final Project project;

    static Future<bool?> show(BuildContext context, Project project) {
      return showDialog<bool>(
        context: context,
        builder: (_) => RelocateProjectDialog(project: project),
      );
    }

    @override
    ConsumerState<RelocateProjectDialog> createState() =>
        _RelocateProjectDialogState();
  }

  class _RelocateProjectDialogState
      extends ConsumerState<RelocateProjectDialog> {
    String? _newPath;
    bool _submitting = false;
    String? _error;

    Future<void> _pick() async {
      final picked = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select new folder for "${widget.project.name}"',
      );
      if (picked != null) {
        setState(() {
          _newPath = picked;
          _error = null;
        });
      }
    }

    Future<void> _submit() async {
      if (_newPath == null) return;
      setState(() {
        _submitting = true;
        _error = null;
      });
      try {
        await ref
            .read(projectServiceProvider)
            .relocateProject(widget.project.id, _newPath!);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[RelocateProjectDialog] relocate failed: $e\n$st');
        }
        setState(() {
          _submitting = false;
          _error = 'Could not relocate: $e';
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Relocate "${widget.project.name}"',
          style: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 14,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 360, maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original path:',
                style: TextStyle(
                  color: ThemeConstants.mutedFg,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.project.path,
                style: const TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'New path:',
                style: TextStyle(
                  color: ThemeConstants.mutedFg,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _newPath ?? '(none selected)',
                      style: TextStyle(
                        color: _newPath == null
                            ? ThemeConstants.faintFg
                            : ThemeConstants.textPrimary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _submitting ? null : _pick,
                    child: const Text('Browse…'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: ThemeConstants.error,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                _submitting ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed:
                _submitting || _newPath == null ? null : _submit,
            child: Text(_submitting ? 'Relocating…' : 'Relocate'),
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 5.2: Format, analyze, commit**

  ```bash
  dart format lib/
  flutter analyze
  git add lib/features/project_sidebar/widgets/relocate_project_dialog.dart
  git commit -m "feat: add RelocateProjectDialog with folder picker"
  ```

---

## Task 6: `RemoveProjectDialog` with cascade-delete toggle

**Files:**
- Create: `lib/features/project_sidebar/widgets/remove_project_dialog.dart`

- [ ] **Step 6.1: Create the dialog**

  Create `lib/features/project_sidebar/widgets/remove_project_dialog.dart`:

  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/project.dart';
  import '../../../services/project/project_service.dart';
  import '../../../services/session/session_service.dart';

  class RemoveProjectDialog extends ConsumerStatefulWidget {
    const RemoveProjectDialog({super.key, required this.project});

    final Project project;

    static Future<bool?> show(BuildContext context, Project project) {
      return showDialog<bool>(
        context: context,
        builder: (_) => RemoveProjectDialog(project: project),
      );
    }

    @override
    ConsumerState<RemoveProjectDialog> createState() =>
        _RemoveProjectDialogState();
  }

  class _RemoveProjectDialogState extends ConsumerState<RemoveProjectDialog> {
    bool _alsoDeleteSessions = false;
    bool _submitting = false;
    int _sessionCount = 0;
    bool _sessionCountLoaded = false;

    @override
    void initState() {
      super.initState();
      _loadSessionCount();
    }

    Future<void> _loadSessionCount() async {
      final sessions = await ref
          .read(sessionServiceProvider)
          .watchSessionsByProject(widget.project.id)
          .first;
      if (!mounted) return;
      setState(() {
        _sessionCount = sessions.length;
        _sessionCountLoaded = true;
      });
    }

    Future<void> _submit() async {
      setState(() => _submitting = true);
      try {
        if (_alsoDeleteSessions) {
          final sessions = await ref
              .read(sessionServiceProvider)
              .watchSessionsByProject(widget.project.id)
              .first;
          for (final s in sessions) {
            await ref.read(sessionServiceProvider).deleteSession(s.sessionId);
          }
        }
        await ref.read(projectServiceProvider).removeProject(widget.project.id);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[RemoveProjectDialog] remove failed: $e\n$st');
        }
        if (mounted) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove project: $e')),
          );
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      final isMissing = widget.project.status == ProjectStatus.missing;
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Remove "${widget.project.name}"?',
          style: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 14,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 360, maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMissing
                    ? 'This project folder is already missing from disk. '
                        'Removing it will only delete the entry from Code Bench.'
                    : 'This will remove the project from Code Bench. '
                        'The folder on disk will NOT be deleted.',
                style: TextStyle(
                  color: ThemeConstants.mutedFg,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              if (_sessionCountLoaded && _sessionCount > 0)
                InkWell(
                  onTap: _submitting
                      ? null
                      : () => setState(
                          () => _alsoDeleteSessions = !_alsoDeleteSessions),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _alsoDeleteSessions,
                        onChanged: _submitting
                            ? null
                            : (v) => setState(
                                () => _alsoDeleteSessions = v ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'Also delete $_sessionCount '
                          '${_sessionCount == 1 ? "conversation" : "conversations"} '
                          'linked to this project',
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                _submitting ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _submitting ? null : _submit,
            style: TextButton.styleFrom(foregroundColor: ThemeConstants.error),
            child: Text(_submitting ? 'Removing…' : 'Remove'),
          ),
        ],
      );
    }
  }
  ```

  Note: conversations are NOT deleted by default. If the user leaves the box unchecked, the sessions keep their `projectId` — but since the row is gone, `watchSessionsByProject` will return empty until a project with that id is recreated (which never happens because ids are UUIDs). The sessions remain accessible only if they appear in a global archive list; if that's undesirable, we can follow up by clearing `projectId` on orphaned sessions. Leaving this for a follow-up.

- [ ] **Step 6.2: Format, analyze, commit**

  ```bash
  dart format lib/
  flutter analyze
  git add lib/features/project_sidebar/widgets/remove_project_dialog.dart
  git commit -m "feat: add RemoveProjectDialog with cascade-delete toggle"
  ```

---

## Task 7: Wire relocate + remove dialogs in `project_sidebar.dart`

**Files:**
- Modify: `lib/features/project_sidebar/project_sidebar.dart`

- [ ] **Step 7.1: Add imports**

  At the top of `lib/features/project_sidebar/project_sidebar.dart`, add:

  ```dart
  import 'widgets/relocate_project_dialog.dart';
  import 'widgets/remove_project_dialog.dart';
  ```

- [ ] **Step 7.2: Replace the `onRemove` wiring**

  Find the `ProjectTile` usage at around line 231 (the block that currently contains `onRemove: (id) => ref.read(projectServiceProvider).removeProject(id),`). Replace its `onRemove` line and add `onRelocate` so the relevant block looks like:

  ```dart
  ProjectTile(
    // ...existing fields...
    onRemove: (id) async {
      final project = projects.firstWhere((p) => p.id == id);
      await RemoveProjectDialog.show(context, project);
    },
    onRelocate: (id) async {
      final project = projects.firstWhere((p) => p.id == id);
      await RelocateProjectDialog.show(context, project);
    },
  ),
  ```

  Note: `projects` is the list variable already in scope from the `watchAllProjects` stream. If the variable name differs in the current code, use whatever name is in scope.

- [ ] **Step 7.3: Format, analyze, commit**

  ```bash
  dart format lib/
  flutter analyze
  git add lib/features/project_sidebar/project_sidebar.dart
  git commit -m "feat: wire relocate and remove-with-cascade dialogs in sidebar"
  ```

---

## Task 8: `ProjectMissingException` + guard in `ApplyService`

**Files:**
- Modify: `lib/services/apply/apply_service.dart`

- [ ] **Step 8.1: Add the typed exception**

  Near the top of `lib/services/apply/apply_service.dart` (after the imports, before `class ApplyService`), add:

  ```dart
  /// Thrown when a write is attempted against a project whose root folder
  /// has been deleted or moved. The UI should catch this and prompt the
  /// user to Relocate or Remove.
  class ProjectMissingException implements Exception {
    ProjectMissingException(this.projectPath);
    final String projectPath;

    @override
    String toString() => 'Project folder is missing: $projectPath';
  }
  ```

- [ ] **Step 8.2: Replace the existing `StateError` at line ~83**

  In `assertWithinProject`, find the line that throws `StateError('Project root does not exist: "$projectPath"')` and replace with:

  ```dart
  throw ProjectMissingException(projectPath);
  ```

  The surrounding code (normalization, path-inside check) stays unchanged.

- [ ] **Step 8.3: Update the test, if any references the old error type**

  Run: `flutter test test/services/apply/apply_service_test.dart`
  Expected: PASS. If a test asserts `throwsStateError` for the missing-root case, update it to `throwsA(isA<ProjectMissingException>())`.

- [ ] **Step 8.4: Format, analyze, commit**

  ```bash
  dart format lib/ test/
  flutter analyze
  git add lib/services/apply/apply_service.dart test/services/apply/apply_service_test.dart
  git commit -m "feat: ProjectMissingException from ApplyService for missing roots"
  ```

---

## Task 9: Block write actions in `top_action_bar.dart`

**Files:**
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 9.1: Add a shared guard helper at the top of the file**

  Near the top of `lib/shell/widgets/top_action_bar.dart` (after the imports, outside any class), add:

  ```dart
  /// Returns `true` if the project is usable for writes. If the folder is
  /// missing, shows a snackbar prompting the user to relocate and returns
  /// `false`. Checks the filesystem directly — does NOT rely on cached
  /// `project.status`, which may be stale.
  bool _ensureProjectAvailable(BuildContext context, String projectPath) {
    if (Directory(projectPath).existsSync()) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This project folder is missing. Right-click the project in the '
          'sidebar to Relocate or Remove it.',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
    return false;
  }
  ```

- [ ] **Step 9.2: Apply the guard at every write call-site**

  For every button in `top_action_bar.dart` that performs a write (IDE launch, open Finder, open Terminal, Initialize Git, Commit, Push, Pull, Run Action, Add Action, Create PR), wrap the existing `onPressed`/async body with the guard as the first check. Example for `_InitGitButton`:

  ```dart
  onPressed: () async {
    if (!_ensureProjectAvailable(context, project.path)) return;
    try {
      await ref.read(gitServiceProvider).initGit(project.path);
      // ...existing body...
    } catch (e, st) {
      // ...existing logging/snackbar...
    }
  },
  ```

  IDE-launch and Finder/Terminal buttons also count as writes (spawning `xed`/`open`/etc. against a missing path fails confusingly) and should use the same guard.

  **Read-only actions** (copy path, show current branch badge) do NOT need the guard.

- [ ] **Step 9.3: Visually indicate disabled state**

  In the same file, use `project.status == ProjectStatus.missing` to apply `opacity: 0.4` around the row of write buttons so the UI clearly signals they are blocked. The guard in Step 9.2 stays as the authoritative check; the opacity is purely visual.

  ```dart
  final isMissing = project.status == ProjectStatus.missing;
  return Opacity(
    opacity: isMissing ? 0.4 : 1.0,
    child: Row(
      // ...existing buttons...
    ),
  );
  ```

  Place this at whichever level wraps the write-button row — if the current build method constructs the row inline, wrap that inline `Row`. If buttons are top-level children of a `Wrap` or similar, wrap them with a single `Opacity`.

- [ ] **Step 9.4: Format, analyze, commit**

  ```bash
  dart format lib/
  flutter analyze
  git add lib/shell/widgets/top_action_bar.dart
  git commit -m "feat: guard top-bar write actions when project is missing"
  ```

---

## Task 10: Refresh on app startup

**Files:**
- Modify: `lib/features/project_sidebar/project_sidebar.dart`

- [ ] **Step 10.1: Call `refreshProjectStatuses` on first build**

  In `lib/features/project_sidebar/project_sidebar.dart`, find the `ConsumerStatefulWidget` (or its equivalent). If the sidebar is currently a `ConsumerWidget`, convert to `ConsumerStatefulWidget`. Add:

  ```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectServiceProvider).refreshProjectStatuses();
    });
  }
  ```

  This guarantees that when the app opens, every project row is re-checked against the filesystem even if no other DB change has occurred.

- [ ] **Step 10.2: Format, analyze, commit**

  ```bash
  dart format lib/
  flutter analyze
  git add lib/features/project_sidebar/project_sidebar.dart
  git commit -m "feat: refresh project statuses on sidebar mount"
  ```

---

## Task 11: Manual QA + full test pass

- [ ] **Step 11.1: Run the full test suite**

  Run: `flutter test`
  Expected: ALL PASS.

- [ ] **Step 11.2: Manual QA checklist**

  Run: `flutter run -d macos`

  Verify:
  1. Add a new folder via the sidebar — renders normal (available).
  2. In Finder, delete the folder. Restart the app — project renders muted + strikethrough + warning triangle.
  3. Right-click the missing project → context menu shows `Copy path`, `Relocate…`, `Remove from Code Bench` only.
  4. Click `Relocate…` → folder picker opens → select a new folder → project switches back to available, name unchanged.
  5. Delete the folder again. In top action bar, try **every** write button (Open in VS Code, Open in Finder, Commit, Push, Pull, Run Action, Initialize Git, Create PR) — each should show the "project folder is missing" snackbar and not attempt the action.
  6. Right-click missing project → `Remove from Code Bench` → confirm dialog shows "project folder is already missing" copy + (if sessions exist) "Also delete N conversations" checkbox.
  7. Remove without cascade → project disappears from sidebar, sessions remain in DB (verifiable by inspecting the DB via Drift inspector or by quickly checking `SessionDao.watchAllSessions`).
  8. Re-add a fresh folder → works as before.
  9. Clicking on a missing project in the sidebar still selects it and lets you READ linked chat history in the chat pane — only writes are blocked.

- [ ] **Step 11.3: Final format + analyze**

  ```bash
  dart format lib/ test/
  flutter analyze
  flutter test
  ```

  All should be clean / green.

- [ ] **Step 11.4: Push the branch and open a PR**

  ```bash
  git push -u origin feat/2026-04-10-missing-project-detection
  ```

  Then open a PR using the template from `CLAUDE.md`. Summary bullet points:
  - Detect missing project folders with a computed `ProjectStatus` (no schema change).
  - Muted/strikethrough rendering + warning icon in the sidebar.
  - `Relocate…` context-menu action with a folder picker.
  - `Remove from Code Bench` now prompts with an optional cascade-delete of linked conversations.
  - All top-bar write actions short-circuit with a snackbar when the folder is missing.

---

## Out of Scope (deferred)

- Reactive filesystem watchers (e.g. FSEvents on macOS) — current design relies on Drift stream re-emission + on-startup refresh. Add if users complain about stale UI.
- Orphan-session cleanup policy (sessions left behind when a project is removed without cascade) — leave for a follow-up once usage patterns are clearer.
- Detection for folders that exist but are no longer git repos — `refreshGitStatus` already handles this; not part of this plan.
- Bulk "Refresh all projects" menu action — covered by on-startup refresh; re-visit if needed.
