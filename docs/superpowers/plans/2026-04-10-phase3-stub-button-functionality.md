# Phase 3 — Stub Button Functionality Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up every stub button in the top action bar — VS Code/Cursor/Finder/Terminal launch, Initialize Git, Commit (AI-generated message), Push, Pull (with behind-upstream badge), Create PR (AI-generated title/body), Add Action (run shell commands with floating output panel), and Rename dialogs for projects and conversations.

**Architecture:** Three new services (`GitService`, `IdeLaunchService`, `ActionRunnerService`) are Riverpod-injected singletons. Git operations shell out via `Process.run`/`Process.start`. The actions list is persisted as JSON on the `WorkspaceProjects` row (schema v4). The floating output panel is a widget slot in `ChatShell`. All git commit/PR text is generated via the active AI model through the existing `AiService`.

**Tech Stack:** Flutter, Riverpod (keepAlive notifiers), `freezed`, `dart:io` (`Process.run`/`Process.start`), Drift (schema migration), existing `GitHubApiService`, `GeneralPreferences`, `SecureStorageSource`.

---

## File Map

| Status | File | Responsibility |
|---|---|---|
| Modify | `lib/data/datasources/local/app_database.dart` | Add `actionsJson` column to `WorkspaceProjects`; bump schemaVersion to 4; add migration |
| **Create** | `lib/data/models/project_action.dart` | `@freezed` `ProjectAction` model (name, command) |
| Modify | `lib/data/models/project.dart` | Add `@Default([]) List<ProjectAction> actions` field |
| Modify | `lib/services/project/project_service.dart` | Decode `actionsJson` in `_projectFromRow`; add `updateProjectActions` |
| **Create** | `lib/services/git/git_service.dart` | Async git: `initGit`, `commit`, `push`, `pull`, `fetchBehindCount`, `listRemotes` |
| **Create** | `lib/services/ide/ide_launch_service.dart` | `openVsCode`, `openCursor`, `openInFinder`, `openInTerminal` via `Process.run` |
| **Create** | `lib/services/actions/action_runner_service.dart` | `Process.start` wrapper + `ActionOutputNotifier` |
| **Create** | `lib/shell/widgets/action_output_panel.dart` | Floating output panel anchored below top bar |
| Modify | `lib/shell/widgets/top_action_bar.dart` | Wire all buttons: IDE launch, Initialize Git, Commit & Push split button, + Add action |
| Modify | `lib/features/project_sidebar/widgets/project_context_menu.dart` | Add "Rename project" item |
| **Create** | `lib/features/project_sidebar/widgets/rename_project_dialog.dart` | Rename project dialog (prefilled name, validation) |
| **Create** | `lib/features/project_sidebar/widgets/rename_conversation_dialog.dart` | Rename conversation dialog |
| Modify | `lib/features/project_sidebar/widgets/project_tile.dart` | Pass `onRename` to `ConversationTile`; handle `rename_project` action |
| Modify | `lib/services/github/github_api_service.dart` | Add `validateToken`, `createPullRequest`, `listRepoBranches` |
| **Create** | `lib/features/chat/widgets/commit_dialog.dart` | Commit message dialog with auto-commit toggle |
| **Create** | `lib/features/chat/widgets/create_pr_dialog.dart` | PR title/body/base-branch/draft dialog |
| **Create** | `test/services/git/git_service_test.dart` | Unit tests for `GitService` |
| **Create** | `test/services/ide/ide_launch_service_test.dart` | Unit tests for `IdeLaunchService` |
| **Create** | `test/services/actions/action_runner_service_test.dart` | Unit tests for `ActionOutputNotifier` |

---

## Task 1: Schema v4 + `ProjectAction` model

**Files:**
- Modify: `lib/data/datasources/local/app_database.dart`
- Create: `lib/data/models/project_action.dart`
- Modify: `lib/data/models/project.dart`
- Modify: `lib/services/project/project_service.dart`

- [ ] **Step 1.1: Create `ProjectAction` freezed model**

  Create `lib/data/models/project_action.dart`:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'project_action.freezed.dart';
  part 'project_action.g.dart';

  @freezed
  class ProjectAction with _$ProjectAction {
    const factory ProjectAction({
      required String name,
      required String command,
    }) = _ProjectAction;

    factory ProjectAction.fromJson(Map<String, dynamic> json) =>
        _$ProjectActionFromJson(json);
  }
  ```

- [ ] **Step 1.2: Add `actions` field to `Project` model**

  In `lib/data/models/project.dart`, add the import and field:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  import 'project_action.dart';

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
      @Default([]) List<ProjectAction> actions,   // ← new
    }) = _Project;

    factory Project.fromJson(Map<String, dynamic> json) =>
        _$ProjectFromJson(json);
  }
  ```

- [ ] **Step 1.3: Add `actionsJson` column to `WorkspaceProjects` table**

  In `lib/data/datasources/local/app_database.dart`, add the column to the `WorkspaceProjects` class and bump `schemaVersion`:

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
    TextColumn get actionsJson =>
        text().withDefault(const Constant('[]'))();   // ← new

    @override
    Set<Column> get primaryKey => {id};
  }
  ```

  Then update the database version and migration:

  ```dart
  @override
  int get schemaVersion => 4;   // was 3

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
          if (from < 4) {
            await migrator.addColumn(
              workspaceProjects,
              workspaceProjects.actionsJson,
            );
          }
        },
      );
  ```

- [ ] **Step 1.4: Update `ProjectService` to decode/encode actions**

  In `lib/services/project/project_service.dart`, add the import and update `_projectFromRow` and add `updateProjectActions`:

  ```dart
  import 'dart:convert';

  // ... existing imports ...
  import '../../data/models/project_action.dart';
  ```

  Update `_projectFromRow`:

  ```dart
  Project _projectFromRow(WorkspaceProjectRow row) {
    List<ProjectAction> actions = [];
    try {
      final decoded = jsonDecode(row.actionsJson) as List<dynamic>;
      actions = decoded
          .map((e) => ProjectAction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    return Project(
      id: row.id,
      name: row.name,
      path: row.path,
      isGit: row.isGit,
      currentBranch: row.currentBranch,
      createdAt: row.createdAt,
      sortOrder: row.sortOrder,
      actions: actions,
    );
  }
  ```

  Add `updateProjectActions` after `renameProject`:

  ```dart
  Future<void> updateProjectActions(
    String projectId,
    List<ProjectAction> actions,
  ) async {
    final json = jsonEncode(actions.map((a) => a.toJson()).toList());
    await _db.projectDao.upsertProject(
      WorkspaceProjectsCompanion(
        id: Value(projectId),
        actionsJson: Value(json),
      ),
    );
  }
  ```

- [ ] **Step 1.5: Run build_runner**

  ```bash
  cd /path/to/repo && dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `project_action.freezed.dart`, `project_action.g.dart`, and updated `project.freezed.dart` and `app_database.g.dart` generated with no errors.

- [ ] **Step 1.6: Verify analyze is clean**

  ```bash
  flutter analyze
  ```

  Expected: no issues.

- [ ] **Step 1.7: Commit**

  ```bash
  git add lib/data/models/project_action.dart \
         lib/data/models/project_action.freezed.dart \
         lib/data/models/project_action.g.dart \
         lib/data/models/project.dart \
         lib/data/models/project.freezed.dart \
         lib/data/models/project.g.dart \
         lib/data/datasources/local/app_database.dart \
         lib/data/datasources/local/app_database.g.dart \
         lib/services/project/project_service.dart
  git commit -m "feat: schema v4 — actionsJson on WorkspaceProjects; ProjectAction model"
  ```

---

## Task 2: `GitService`

**Files:**
- Create: `lib/services/git/git_service.dart`
- Create: `test/services/git/git_service_test.dart`

- [ ] **Step 2.1: Write failing tests**

  Create `test/services/git/git_service_test.dart`:

  ```dart
  import 'dart:io';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench/services/git/git_service.dart';

  void main() {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('git_service_test_');
      // Initialize a real git repo for integration-style tests
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      await Process.run(
        'git', ['config', 'user.email', 'test@test.com'],
        workingDirectory: tempDir.path,
      );
      await Process.run(
        'git', ['config', 'user.name', 'Test'],
        workingDirectory: tempDir.path,
      );
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('initGit creates .git directory', () async {
      final dir = await Directory.systemTemp.createTemp('git_init_test_');
      addTearDown(() => dir.delete(recursive: true));
      final svc = GitService(dir.path);
      await svc.initGit();
      expect(Directory('${dir.path}/.git').existsSync(), isTrue);
    });

    test('commit stages and commits a file', () async {
      final file = File('${tempDir.path}/hello.txt')..writeAsStringSync('hi');
      final svc = GitService(tempDir.path);
      final sha = await svc.commit('test: initial commit');
      expect(sha, isNotEmpty);
      expect(sha.length, greaterThanOrEqualTo(7));
    });

    test('fetchBehindCount returns 0 for repo with no remote', () async {
      final svc = GitService(tempDir.path);
      final count = await svc.fetchBehindCount();
      expect(count, 0);
    });

    test('listRemotes returns empty list when no remotes configured', () async {
      final svc = GitService(tempDir.path);
      final remotes = await svc.listRemotes();
      expect(remotes, isEmpty);
    });
  }
  ```

- [ ] **Step 2.2: Run tests to confirm they fail**

  ```bash
  flutter test test/services/git/git_service_test.dart
  ```

  Expected: compilation error — `GitService` not found.

- [ ] **Step 2.3: Create `GitService`**

  Create `lib/services/git/git_service.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  part 'git_service.g.dart';

  @Riverpod(keepAlive: true)
  GitService gitService(Ref ref, String projectPath) =>
      GitService(projectPath);

  class GitRemote {
    const GitRemote({required this.name, required this.url});
    final String name;
    final String url;
  }

  class GitService {
    GitService(this.projectPath);

    final String projectPath;

    /// Runs `git init` in [projectPath]. Throws [GitException] on failure.
    Future<void> initGit() async {
      final result = await Process.run(
        'git', ['init'],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) {
        throw GitException('git init failed: ${result.stderr}');
      }
    }

    /// Stages all changes and commits with [message].
    /// Returns the short SHA of the new commit.
    Future<String> commit(String message) async {
      final addResult = await Process.run(
        'git', ['add', '-A'],
        workingDirectory: projectPath,
      );
      if (addResult.exitCode != 0) {
        throw GitException('git add failed: ${addResult.stderr}');
      }
      final commitResult = await Process.run(
        'git', ['commit', '-m', message],
        workingDirectory: projectPath,
      );
      if (commitResult.exitCode != 0) {
        throw GitException('git commit failed: ${commitResult.stderr}');
      }
      // Extract short SHA from output like "[main abc1234] message"
      final out = commitResult.stdout as String;
      final match = RegExp(r'\[[\w/]+ ([a-f0-9]+)\]').firstMatch(out);
      return match?.group(1) ?? '';
    }

    /// Runs `git push`. Returns the branch name pushed to.
    Future<String> push() async {
      final branchResult = await Process.run(
        'git', ['rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: projectPath,
      );
      final branch = (branchResult.stdout as String).trim();

      final result = await Process.run(
        'git', ['push'],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) {
        final stderr = result.stderr as String;
        if (stderr.contains('no upstream')) {
          throw GitNoUpstreamException(branch);
        }
        if (stderr.contains('Authentication') ||
            stderr.contains('could not read Username')) {
          throw GitAuthException();
        }
        throw GitException(stderr.trim());
      }
      return branch;
    }

    /// Runs `git pull`. Returns number of new commits pulled.
    Future<int> pull() async {
      final result = await Process.run(
        'git', ['pull'],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) {
        final stderr = result.stderr as String;
        if (stderr.contains('CONFLICT') ||
            (result.stdout as String).contains('CONFLICT')) {
          throw GitConflictException();
        }
        if (stderr.contains('no tracking information') ||
            stderr.contains('no upstream')) {
          throw GitNoUpstreamException('');
        }
        throw GitException(stderr.trim());
      }
      // Count "new commits" from stdout pattern
      final match = RegExp(r'(\d+) file').firstMatch(result.stdout as String);
      return match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
    }

    /// Fetches and returns how many commits HEAD is behind origin/<branch>.
    /// Returns 0 if no remote is configured or fetch fails.
    Future<int> fetchBehindCount() async {
      final branchResult = await Process.run(
        'git', ['rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: projectPath,
      );
      if (branchResult.exitCode != 0) return 0;
      final branch = (branchResult.stdout as String).trim();

      final fetchResult = await Process.run(
        'git', ['fetch', '--quiet'],
        workingDirectory: projectPath,
      );
      if (fetchResult.exitCode != 0) return 0;

      final countResult = await Process.run(
        'git', ['rev-list', 'HEAD..origin/$branch', '--count'],
        workingDirectory: projectPath,
      );
      if (countResult.exitCode != 0) return 0;
      return int.tryParse((countResult.stdout as String).trim()) ?? 0;
    }

    /// Returns list of configured git remotes.
    Future<List<GitRemote>> listRemotes() async {
      final result = await Process.run(
        'git', ['remote', '-v'],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) return [];
      final lines = (result.stdout as String).trim().split('\n');
      final seen = <String>{};
      final remotes = <GitRemote>[];
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 2) continue;
        final name = parts[0];
        final url = parts[1];
        if (seen.add(name)) {
          remotes.add(GitRemote(name: name, url: url));
        }
      }
      return remotes;
    }

    /// Pushes to a named [remote].
    Future<void> pushToRemote(String remote) async {
      final branchResult = await Process.run(
        'git', ['rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: projectPath,
      );
      final branch = (branchResult.stdout as String).trim();

      final result = await Process.run(
        'git', ['push', remote, branch],
        workingDirectory: projectPath,
      );
      if (result.exitCode != 0) {
        throw GitException((result.stderr as String).trim());
      }
    }
  }

  class GitException implements Exception {
    const GitException(this.message);
    final String message;
    @override
    String toString() => 'GitException: $message';
  }

  class GitNoUpstreamException extends GitException {
    const GitNoUpstreamException(String branch)
        : super('No upstream branch for $branch');
  }

  class GitAuthException extends GitException {
    const GitAuthException() : super('Authentication failed');
  }

  class GitConflictException extends GitException {
    const GitConflictException() : super('Merge conflict detected');
  }
  ```

- [ ] **Step 2.4: Run build_runner**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `lib/services/git/git_service.g.dart` generated.

- [ ] **Step 2.5: Run tests to confirm they pass**

  ```bash
  flutter test test/services/git/git_service_test.dart
  ```

  Expected: all 4 tests pass. (The `commit` test requires git to be on PATH, which it is on macOS dev machines.)

- [ ] **Step 2.6: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 2.7: Commit**

  ```bash
  git add lib/services/git/ test/services/git/
  git commit -m "feat: GitService — async git commit, push, pull, fetch, remotes"
  ```

---

## Task 3: `IdeLaunchService` + VS Code/Cursor/Finder/Terminal dropdown

**Files:**
- Create: `lib/services/ide/ide_launch_service.dart`
- Create: `test/services/ide/ide_launch_service_test.dart`
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 3.1: Write failing tests for `IdeLaunchService`**

  Create `test/services/ide/ide_launch_service_test.dart`:

  ```dart
  import 'dart:io';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench/services/ide/ide_launch_service.dart';

  void main() {
    test('buildVsCodeArgs returns correct arguments', () {
      expect(
        IdeLaunchService.buildVsCodeArgs('/path/to/project'),
        equals(['/path/to/project']),
      );
    });

    test('buildFinderArgs returns open command args', () {
      expect(
        IdeLaunchService.buildFinderArgs('/path/to/project'),
        equals(['/path/to/project']),
      );
    });

    test('buildTerminalArgs returns -a <app> <path>', () {
      expect(
        IdeLaunchService.buildTerminalArgs('/path', 'iTerm'),
        equals(['-a', 'iTerm', '/path']),
      );
    });
  }
  ```

- [ ] **Step 3.2: Run tests to confirm they fail**

  ```bash
  flutter test test/services/ide/ide_launch_service_test.dart
  ```

  Expected: compilation error — `IdeLaunchService` not found.

- [ ] **Step 3.3: Create `IdeLaunchService`**

  Create `lib/services/ide/ide_launch_service.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../data/datasources/local/general_preferences.dart';

  part 'ide_launch_service.g.dart';

  @Riverpod(keepAlive: true)
  IdeLaunchService ideLaunchService(Ref ref) =>
      IdeLaunchService(ref.watch(generalPreferencesProvider));

  class IdeLaunchService {
    IdeLaunchService(this._prefs);

    final GeneralPreferences _prefs;

    static const _vsCodeNotFoundMessage =
        "VS Code CLI not found — install it from the Command Palette "
        "(Shell Command: Install 'code' in PATH)";
    static const _cursorNotFoundMessage =
        "Cursor CLI not found — install it from the Command Palette "
        "(Shell Command: Install 'cursor' in PATH)";

    static List<String> buildVsCodeArgs(String path) => [path];
    static List<String> buildFinderArgs(String path) => [path];
    static List<String> buildTerminalArgs(String path, String terminalApp) =>
        ['-a', terminalApp, path];

    /// Opens [path] in VS Code. Returns error message string if CLI not found,
    /// null on success.
    Future<String?> openVsCode(String path) async {
      final result = await Process.run('code', buildVsCodeArgs(path));
      if (result.exitCode != 0 && (result.stderr as String).contains('not found')) {
        return _vsCodeNotFoundMessage;
      }
      return null;
    }

    /// Opens [path] in Cursor, falling back to `open -a Cursor` if CLI missing.
    Future<String?> openCursor(String path) async {
      final result = await Process.run('cursor', buildVsCodeArgs(path));
      if (result.exitCode != 0) {
        // Try open -a Cursor as fallback
        final fallback = await Process.run('open', ['-a', 'Cursor', path]);
        if (fallback.exitCode != 0) return _cursorNotFoundMessage;
      }
      return null;
    }

    /// Opens [path] in Finder.
    Future<void> openInFinder(String path) async {
      await Process.run('open', buildFinderArgs(path));
    }

    /// Opens [path] in the configured terminal app.
    Future<void> openInTerminal(String path) async {
      final app = await _prefs.getTerminalApp();
      await Process.run('open', buildTerminalArgs(path, app));
    }
  }
  ```

- [ ] **Step 3.4: Run build_runner**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 3.5: Run tests to confirm they pass**

  ```bash
  flutter test test/services/ide/ide_launch_service_test.dart
  ```

  Expected: 3 tests pass.

- [ ] **Step 3.6: Add VS Code/Cursor/Finder/Terminal dropdown to `TopActionBar`**

  In `lib/shell/widgets/top_action_bar.dart`, add imports and wire the IDE dropdown. Find the section in `build` where the right-side buttons are built (after the `Spacer()`). Replace or add the IDE launch button:

  ```dart
  // Add these imports at top of file
  import '../../services/ide/ide_launch_service.dart';
  import '../../../core/utils/platform_utils.dart';
  ```

  Inside `build`, after the existing widget tree, add the IDE dropdown button in the right-side `Row` before the existing buttons. Replace the placeholder `// IDE launch` area (or add before the closing `]` of the right-side children list):

  ```dart
  // ── IDE launch dropdown ──────────────────────────────────
  if (project != null)
    _IdeDropdownButton(projectPath: project.path),
  const SizedBox(width: 8),
  ```

  Add the private widget class at the bottom of the file (outside `TopActionBar`):

  ```dart
  class _IdeDropdownButton extends ConsumerWidget {
    const _IdeDropdownButton({required this.projectPath});
    final String projectPath;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final svc = ref.watch(ideLaunchServiceProvider);
      return PopupMenuButton<String>(
        tooltip: 'Open in…',
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'vscode', child: Text('VS Code')),
          const PopupMenuItem(value: 'cursor', child: Text('Cursor')),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'finder', child: Text('Open in Finder')),
          const PopupMenuItem(value: 'terminal', child: Text('Open in Terminal')),
        ],
        onSelected: (action) async {
          String? error;
          switch (action) {
            case 'vscode':
              error = await svc.openVsCode(projectPath);
            case 'cursor':
              error = await svc.openCursor(projectPath);
            case 'finder':
              await svc.openInFinder(projectPath);
            case 'terminal':
              await svc.openInTerminal(projectPath);
          }
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), duration: const Duration(seconds: 4)),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: const Row(
            children: [
              Text('VS Code ↓',
                  style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 11)),
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 3.7: Verify analyze + hot restart**

  ```bash
  flutter analyze
  ```

  Then `flutter run -d macos` and verify the IDE dropdown appears when a project is active.

- [ ] **Step 3.8: Commit**

  ```bash
  git add lib/services/ide/ lib/shell/widgets/top_action_bar.dart \
         test/services/ide/
  git commit -m "feat: IdeLaunchService + VS Code/Cursor/Finder/Terminal dropdown"
  ```

---

## Task 4: `ActionRunnerService` + `ActionOutputPanel`

**Files:**
- Create: `lib/services/actions/action_runner_service.dart`
- Create: `test/services/actions/action_runner_service_test.dart`
- Create: `lib/shell/widgets/action_output_panel.dart`
- Modify: `lib/shell/chat_shell.dart`

- [ ] **Step 4.1: Write failing tests for `ActionOutputNotifier`**

  Create `test/services/actions/action_runner_service_test.dart`:

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench/services/actions/action_runner_service.dart';

  void main() {
    test('ActionOutputState starts idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(actionOutputNotifierProvider);
      expect(state.status, ActionStatus.idle);
      expect(state.lines, isEmpty);
      expect(state.actionName, isNull);
    });

    test('ActionOutputNotifier.clear resets state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(actionOutputNotifierProvider.notifier)
          .appendLine('hello', ActionStatus.running, 'test');
      container.read(actionOutputNotifierProvider.notifier).clear();
      final state = container.read(actionOutputNotifierProvider);
      expect(state.status, ActionStatus.idle);
      expect(state.lines, isEmpty);
    });
  }
  ```

- [ ] **Step 4.2: Run tests to confirm they fail**

  ```bash
  flutter test test/services/actions/action_runner_service_test.dart
  ```

  Expected: compilation error.

- [ ] **Step 4.3: Create `ActionRunnerService`**

  Create `lib/services/actions/action_runner_service.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:freezed_annotation/freezed_annotation.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../data/models/project_action.dart';

  part 'action_runner_service.freezed.dart';
  part 'action_runner_service.g.dart';

  enum ActionStatus { idle, running, done, failed }

  @freezed
  class ActionOutputState with _$ActionOutputState {
    const factory ActionOutputState({
      @Default(ActionStatus.idle) ActionStatus status,
      @Default([]) List<String> lines,
      String? actionName,
      int? exitCode,
    }) = _ActionOutputState;
  }

  @Riverpod(keepAlive: true)
  class ActionOutputNotifier extends _$ActionOutputNotifier {
    Process? _currentProcess;

    @override
    ActionOutputState build() => const ActionOutputState();

    void appendLine(String line, ActionStatus status, String? name) {
      state = state.copyWith(
        lines: [...state.lines, line],
        status: status,
        actionName: name ?? state.actionName,
      );
    }

    void clear() {
      _currentProcess?.kill();
      _currentProcess = null;
      state = const ActionOutputState();
    }

    Future<void> run(ProjectAction action, String workingDirectory) async {
      // Kill any running process
      _currentProcess?.kill();
      _currentProcess = null;
      state = ActionOutputState(
        status: ActionStatus.running,
        lines: [],
        actionName: action.name,
      );

      // Split command into executable + args
      final parts = action.command.split(RegExp(r'\s+'));
      final executable = parts.first;
      final args = parts.skip(1).toList();

      try {
        final process = await Process.start(
          executable,
          args,
          workingDirectory: workingDirectory,
        );
        _currentProcess = process;

        process.stdout.transform(const SystemEncoding().decoder).listen((chunk) {
          for (final line in chunk.split('\n')) {
            if (line.isNotEmpty) {
              state = state.copyWith(lines: [...state.lines, line]);
            }
          }
        });

        process.stderr.transform(const SystemEncoding().decoder).listen((chunk) {
          for (final line in chunk.split('\n')) {
            if (line.isNotEmpty) {
              state = state.copyWith(lines: [...state.lines, line]);
            }
          }
        });

        final exitCode = await process.exitCode;
        _currentProcess = null;
        state = state.copyWith(
          status: exitCode == 0 ? ActionStatus.done : ActionStatus.failed,
          exitCode: exitCode,
        );
      } catch (e) {
        state = state.copyWith(
          status: ActionStatus.failed,
          lines: [...state.lines, 'Error: $e'],
          exitCode: -1,
        );
      }
    }
  }
  ```

- [ ] **Step 4.4: Run build_runner**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 4.5: Run tests to confirm they pass**

  ```bash
  flutter test test/services/actions/action_runner_service_test.dart
  ```

  Expected: 2 tests pass.

- [ ] **Step 4.6: Create `ActionOutputPanel` widget**

  Create `lib/shell/widgets/action_output_panel.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../core/constants/theme_constants.dart';
  import '../../services/actions/action_runner_service.dart';

  class ActionOutputPanel extends ConsumerWidget {
    const ActionOutputPanel({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final state = ref.watch(actionOutputNotifierProvider);
      if (state.status == ActionStatus.idle) return const SizedBox.shrink();

      final statusLabel = switch (state.status) {
        ActionStatus.running => '● Running',
        ActionStatus.done => '✓ Done (exit 0)',
        ActionStatus.failed => '✗ Failed (exit ${state.exitCode})',
        ActionStatus.idle => '',
      };

      final statusColor = switch (state.status) {
        ActionStatus.running => ThemeConstants.accentBlue,
        ActionStatus.done => ThemeConstants.success,
        ActionStatus.failed => ThemeConstants.error,
        ActionStatus.idle => ThemeConstants.textSecondary,
      };

      return Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        decoration: BoxDecoration(
          color: ThemeConstants.codeBlockBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ThemeConstants.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: ThemeConstants.borderColor),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    state.actionName ?? 'Action',
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        ref.read(actionOutputNotifierProvider.notifier).clear(),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Output
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: state.lines.length,
                itemBuilder: (_, i) => Text(
                  state.lines[i],
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 4.7: Add `ActionOutputPanel` slot in `ChatShell`**

  In `lib/shell/chat_shell.dart`, read the file first, then add the panel below the `TopActionBar`. Find the `Column` that contains `TopActionBar()` and insert the panel after it:

  ```dart
  // Add import
  import 'widgets/action_output_panel.dart';

  // In the Column children, after TopActionBar():
  const TopActionBar(),
  const ActionOutputPanel(),   // ← new
  // ... rest of children
  ```

- [ ] **Step 4.8: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 4.9: Commit**

  ```bash
  git add lib/services/actions/ lib/shell/widgets/action_output_panel.dart \
         lib/shell/chat_shell.dart test/services/actions/
  git commit -m "feat: ActionRunnerService + floating ActionOutputPanel"
  ```

---

## Task 5: Add Action dialog + chips in `TopActionBar`

**Files:**
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 5.1: Add the `+` actions dropdown to `TopActionBar`**

  In `lib/shell/widgets/top_action_bar.dart`, add imports:

  ```dart
  import '../../services/actions/action_runner_service.dart';
  import '../../data/models/project_action.dart';
  import '../../services/project/project_service.dart';
  import '../../features/project_sidebar/project_sidebar_notifier.dart';
  ```

  Add a provider to read the active project (it already watches `projectsProvider` and `activeProjectIdProvider`). Add the `+` dropdown button in the right-side row, after the IDE dropdown button:

  ```dart
  // ── Actions dropdown ──────────────────────────────────
  if (project != null)
    _ActionsDropdownButton(project: project),
  const SizedBox(width: 8),
  ```

  Add the private widget class at the bottom of the file:

  ```dart
  class _ActionsDropdownButton extends ConsumerWidget {
    const _ActionsDropdownButton({required this.project});
    final Project project;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return PopupMenuButton<Object>(
        tooltip: 'Actions',
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
        itemBuilder: (_) => [
          // Existing actions as runnable chips
          for (final action in project.actions)
            PopupMenuItem<Object>(
              value: action,
              child: Row(
                children: [
                  const Icon(Icons.play_arrow, size: 12,
                      color: Color(0xFF888888)),
                  const SizedBox(width: 6),
                  Text(action.name,
                      style: const TextStyle(
                          color: Color(0xFFB0B0B0), fontSize: 11)),
                ],
              ),
            ),
          if (project.actions.isNotEmpty) const PopupMenuDivider(),
          const PopupMenuItem<Object>(
            value: '__add__',
            child: Row(
              children: [
                Icon(Icons.add, size: 12, color: Color(0xFF888888)),
                SizedBox(width: 6),
                Text('+ Add action',
                    style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 11)),
              ],
            ),
          ),
        ],
        onSelected: (value) async {
          if (value == '__add__') {
            final action = await _showAddActionDialog(context);
            if (action != null) {
              final newActions = [...project.actions, action];
              await ref
                  .read(projectServiceProvider)
                  .updateProjectActions(project.id, newActions);
            }
          } else if (value is ProjectAction) {
            await ref
                .read(actionOutputNotifierProvider.notifier)
                .run(value, project.path);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: const Row(
            children: [
              Icon(Icons.add, size: 12, color: Color(0xFF888888)),
              SizedBox(width: 4),
              Text('Actions',
                  style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 11)),
            ],
          ),
        ),
      );
    }

    Future<ProjectAction?> _showAddActionDialog(BuildContext context) {
      return showDialog<ProjectAction>(
        context: context,
        builder: (_) => const _AddActionDialog(),
      );
    }
  }

  class _AddActionDialog extends StatefulWidget {
    const _AddActionDialog();

    @override
    State<_AddActionDialog> createState() => _AddActionDialogState();
  }

  class _AddActionDialogState extends State<_AddActionDialog> {
    final _nameController = TextEditingController();
    final _commandController = TextEditingController();

    @override
    void dispose() {
      _nameController.dispose();
      _commandController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Action',
            style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Name (e.g. Run tests)',
                labelStyle: TextStyle(color: Color(0xFF888888), fontSize: 11),
              ),
              style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: 'Command (e.g. flutter test)',
                labelStyle: TextStyle(color: Color(0xFF888888), fontSize: 11),
              ),
              style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 12,
                  fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final command = _commandController.text.trim();
              if (name.isEmpty || command.isEmpty) return;
              Navigator.of(context)
                  .pop(ProjectAction(name: name, command: command));
            },
            child: const Text('Save',
                style: TextStyle(color: Color(0xFF4A7CFF))),
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 5.2: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 5.3: Commit**

  ```bash
  git add lib/shell/widgets/top_action_bar.dart
  git commit -m "feat: Add action dialog + chips in top action bar"
  ```

---

## Task 6: Rename dialogs (project + conversation)

**Files:**
- Create: `lib/features/project_sidebar/widgets/rename_project_dialog.dart`
- Create: `lib/features/project_sidebar/widgets/rename_conversation_dialog.dart`
- Modify: `lib/features/project_sidebar/widgets/project_context_menu.dart`
- Modify: `lib/features/project_sidebar/widgets/project_tile.dart`

- [ ] **Step 6.1: Create `RenameProjectDialog`**

  Create `lib/features/project_sidebar/widgets/rename_project_dialog.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';

  class RenameProjectDialog extends StatefulWidget {
    const RenameProjectDialog({super.key, required this.currentName});
    final String currentName;

    /// Shows the dialog and returns the new name, or null if cancelled.
    static Future<String?> show(BuildContext context, String currentName) {
      return showDialog<String>(
        context: context,
        builder: (_) => RenameProjectDialog(currentName: currentName),
      );
    }

    @override
    State<RenameProjectDialog> createState() => _RenameProjectDialogState();
  }

  class _RenameProjectDialogState extends State<RenameProjectDialog> {
    late final TextEditingController _controller;
    String? _error;

    @override
    void initState() {
      super.initState();
      _controller = TextEditingController(text: widget.currentName);
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    void _submit() {
      final name = _controller.text.trim();
      if (name.isEmpty) {
        setState(() => _error = 'Name cannot be empty');
        return;
      }
      if (name.length > 60) {
        setState(() => _error = 'Name must be 60 characters or fewer');
        return;
      }
      Navigator.of(context).pop(name);
    }

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Rename Project',
            style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14)),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 60,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            errorText: _error,
            labelText: 'Project name',
            labelStyle:
                const TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
          style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: _submit,
            child: const Text('Rename',
                style: TextStyle(color: Color(0xFF4A7CFF))),
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 6.2: Create `RenameConversationDialog`**

  Create `lib/features/project_sidebar/widgets/rename_conversation_dialog.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';

  class RenameConversationDialog extends StatefulWidget {
    const RenameConversationDialog({super.key, required this.currentTitle});
    final String currentTitle;

    static Future<String?> show(BuildContext context, String currentTitle) {
      return showDialog<String>(
        context: context,
        builder: (_) =>
            RenameConversationDialog(currentTitle: currentTitle),
      );
    }

    @override
    State<RenameConversationDialog> createState() =>
        _RenameConversationDialogState();
  }

  class _RenameConversationDialogState
      extends State<RenameConversationDialog> {
    late final TextEditingController _controller;
    String? _error;

    @override
    void initState() {
      super.initState();
      _controller = TextEditingController(text: widget.currentTitle);
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    void _submit() {
      final title = _controller.text.trim();
      if (title.isEmpty) {
        setState(() => _error = 'Title cannot be empty');
        return;
      }
      Navigator.of(context).pop(title);
    }

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Rename Conversation',
            style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14)),
        content: TextField(
          controller: _controller,
          autofocus: true,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            errorText: _error,
            labelText: 'Conversation title',
            labelStyle:
                const TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
          style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: _submit,
            child: const Text('Rename',
                style: TextStyle(color: Color(0xFF4A7CFF))),
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 6.3: Add "Rename project" to `ProjectContextMenu`**

  In `lib/features/project_sidebar/widgets/project_context_menu.dart`, update the `show` method's items list to add "Rename project" before "Remove":

  ```dart
  items: [
    _buildItem('open_finder', 'Open in Finder', Icons.folder_open_outlined),
    _buildItem('copy_path', 'Copy path', Icons.copy_outlined),
    const PopupMenuDivider(),
    _buildItem('new_conversation', 'New conversation', Icons.add),
    _buildItem('rename_project', 'Rename project', Icons.edit_outlined), // ← new
    const PopupMenuDivider(),
    _buildDangerItem('remove', 'Remove from Code Bench'),
  ],
  ```

- [ ] **Step 6.4: Update `ProjectContextMenu.handleAction` signature + rename case**

  The `handleAction` method needs an `onRename` callback. Update its signature and add the `rename_project` case:

  ```dart
  static Future<void> handleAction({
    required String action,
    required String projectId,
    required String projectPath,
    required BuildContext context,
    required Function(String) onRemove,
    required Function(String) onNewConversation,
    Function(String)? onRename,       // ← new
  }) async {
    switch (action) {
      case 'open_finder':
        Process.run('open', [projectPath]);
      case 'copy_path':
        await Clipboard.setData(ClipboardData(text: projectPath));
      case 'new_conversation':
        onNewConversation(projectId);
      case 'rename_project':
        onRename?.call(projectId);    // ← new
      case 'remove':
        onRemove(projectId);
    }
  }
  ```

  Add the import at top of the file:

  ```dart
  import 'rename_project_dialog.dart';
  ```

- [ ] **Step 6.5: Wire rename in `ProjectTile`**

  In `lib/features/project_sidebar/widgets/project_tile.dart`:

  a) Add `onRename` to the widget's constructor and the `ProjectTile` class:

  ```dart
  class ProjectTile extends ConsumerStatefulWidget {
    const ProjectTile({
      super.key,
      required this.project,
      required this.sessions,
      required this.isExpanded,
      required this.activeSessionId,
      required this.onToggleExpand,
      required this.onSessionTap,
      required this.onRemove,
      required this.onNewConversation,
      required this.onArchive,
      this.onRenameProject,            // ← new (optional for back compat)
    });
    // ...existing fields...
    final ValueChanged<String>? onRenameProject;  // ← new
  ```

  b) Update the `handleAction` call to pass the rename handler:

  ```dart
  await ProjectContextMenu.handleAction(
    action: action,
    projectId: widget.project.id,
    projectPath: widget.project.path,
    context: context,
    onRemove: widget.onRemove,
    onNewConversation: widget.onNewConversation,
    onRename: (id) async {            // ← new
      final newName = await RenameProjectDialog.show(
        context, widget.project.name);
      if (newName != null) {
        widget.onRenameProject?.call(id);
        // Actual rename done in ProjectSidebar via the callback
      }
    },
  );
  ```

  Wait — the rename dialog returns the new name. The rename should happen here, not upstream. Update to use `ProjectService` directly:

  ```dart
  onRename: (id) async {
    if (!context.mounted) return;
    final newName = await RenameProjectDialog.show(
      context, widget.project.name);
    if (newName != null) {
      await ref.read(projectServiceProvider).renameProject(id, newName);
    }
  },
  ```

  c) Pass `onRename` to `ConversationTile` for conversation rename. First add the import:

  ```dart
  import 'rename_conversation_dialog.dart';
  ```

  Then in `_buildConversationTile` (or wherever `ConversationTile` is constructed), add:

  ```dart
  onRename: () async {
    if (!context.mounted) return;
    final newTitle = await RenameConversationDialog.show(
      context, session.title);
    if (newTitle != null) {
      await ref.read(sessionServiceProvider).renameSession(
        session.sessionId, newTitle);
    }
  },
  ```

  Note: `SessionService` needs a `renameSession` method — add it in Step 6.6.

- [ ] **Step 6.6: Add `renameSession` to `SessionService`**

  In `lib/services/session/session_service.dart`, add:

  ```dart
  Future<void> renameSession(String sessionId, String newTitle) async {
    await _db.sessionDao.upsertSession(
      ChatSessionsCompanion(
        sessionId: Value(sessionId),
        title: Value(newTitle),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  ```

- [ ] **Step 6.7: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 6.8: Commit**

  ```bash
  git add lib/features/project_sidebar/widgets/rename_project_dialog.dart \
         lib/features/project_sidebar/widgets/rename_conversation_dialog.dart \
         lib/features/project_sidebar/widgets/project_context_menu.dart \
         lib/features/project_sidebar/widgets/project_tile.dart \
         lib/services/session/session_service.dart
  git commit -m "feat: rename project and conversation dialogs"
  ```

---

## Task 7: Initialize Git flow

**Files:**
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 7.1: Add Initialize Git button to `TopActionBar`**

  In `lib/shell/widgets/top_action_bar.dart`, add the Initialize Git button in the right-side row. This button replaces the Commit & Push split button when `project.isGit == false`:

  Add the import:

  ```dart
  import '../../services/git/git_service.dart';
  import '../../services/project/project_service.dart';
  ```

  In the right-side children list, replace the hard-coded Commit & Push button area with:

  ```dart
  if (project != null) ...[
    if (!project.isGit)
      _InitGitButton(project: project)
    else
      _CommitPushButton(project: project),
  ],
  ```

  Add the `_InitGitButton` class at the bottom of the file:

  ```dart
  class _InitGitButton extends ConsumerWidget {
    const _InitGitButton({required this.project});
    final Project project;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          side: const BorderSide(color: Color(0xFF333333)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
        onPressed: () async {
          try {
            final svc = GitService(project.path);
            await svc.initGit();
            await ref.read(projectServiceProvider).refreshGitStatus(project.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Git repository initialized')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to initialize git: $e')),
              );
            }
          }
        },
        child: const Text('Initialize Git',
            style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 11)),
      );
    }
  }
  ```

- [ ] **Step 7.2: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 7.3: Commit**

  ```bash
  git add lib/shell/widgets/top_action_bar.dart
  git commit -m "feat: Initialize Git button in top action bar"
  ```

---

## Task 8: Commit dialog + AI commit message

**Files:**
- Create: `lib/features/chat/widgets/commit_dialog.dart`
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 8.1: Create `CommitDialog`**

  Create `lib/features/chat/widgets/commit_dialog.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../data/datasources/local/general_preferences.dart';

  class CommitDialog extends ConsumerStatefulWidget {
    const CommitDialog({super.key, required this.initialMessage});
    final String initialMessage;

    static Future<String?> show(
        BuildContext context, WidgetRef ref, String initialMessage) {
      return showDialog<String>(
        context: context,
        builder: (_) => CommitDialog(initialMessage: initialMessage),
      );
    }

    @override
    ConsumerState<CommitDialog> createState() => _CommitDialogState();
  }

  class _CommitDialogState extends ConsumerState<CommitDialog> {
    late final TextEditingController _controller;
    bool _autoCommit = false;

    @override
    void initState() {
      super.initState();
      _controller = TextEditingController(text: widget.initialMessage);
      _loadAutoCommit();
    }

    Future<void> _loadAutoCommit() async {
      final prefs = ref.read(generalPreferencesProvider);
      final value = await prefs.getAutoCommit();
      if (mounted) setState(() => _autoCommit = value);
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Commit',
            style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                maxLines: 3,
                maxLength: 72,
                decoration: const InputDecoration(
                  labelText: 'Commit message',
                  labelStyle:
                      TextStyle(color: Color(0xFF888888), fontSize: 11),
                ),
                style: const TextStyle(
                    color: Color(0xFFE0E0E0), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Switch(
                    value: _autoCommit,
                    onChanged: (v) async {
                      setState(() => _autoCommit = v);
                      await ref
                          .read(generalPreferencesProvider)
                          .setAutoCommit(v);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text('⚡ Auto-commit future commits',
                      style: TextStyle(
                          color: Color(0xFF888888), fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () {
              final msg = _controller.text.trim();
              if (msg.isEmpty) return;
              Navigator.of(context).pop(msg);
            },
            child: const Text('Commit',
                style: TextStyle(color: Color(0xFF4A7CFF))),
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 8.2: Add `_CommitPushButton` to `TopActionBar`**

  In `lib/shell/widgets/top_action_bar.dart`, add imports:

  ```dart
  import '../../features/chat/chat_notifier.dart';
  import '../../features/chat/widgets/commit_dialog.dart';
  import '../../services/ai/ai_service_factory.dart';
  ```

  Add the `_CommitPushButton` class at the bottom of the file. This is the split button that appears when `project.isGit == true`:

  ```dart
  class _CommitPushButton extends ConsumerStatefulWidget {
    const _CommitPushButton({required this.project});
    final Project project;

    @override
    ConsumerState<_CommitPushButton> createState() =>
        _CommitPushButtonState();
  }

  class _CommitPushButtonState extends ConsumerState<_CommitPushButton> {
    bool _pushing = false;
    bool _pulling = false;
    int _behindCount = 0;

    @override
    void initState() {
      super.initState();
      _checkBehindCount();
    }

    Future<void> _checkBehindCount() async {
      final count = await GitService(widget.project.path).fetchBehindCount();
      if (mounted) setState(() => _behindCount = count);
    }

    Future<void> _doCommit() async {
      final prefs = ref.read(generalPreferencesProvider);
      final autoCommit = await prefs.getAutoCommit();

      // Collect context: changed files + last 10 messages
      final changedFiles = ref
          .read(appliedChangesNotifierProvider)
          .where((c) => c.sessionId ==
              ref.read(activeSessionIdProvider))
          .map((c) => c.filePath)
          .toList();

      // Generate commit message via AI
      final svc = ref.read(aiServiceFactoryProvider).getService(
        ref.read(selectedModelProvider),
      );
      final prompt =
          'Write a conventional commit message (subject line only, max 72 chars) '
          'summarising these file changes: ${changedFiles.join(', ')}. '
          'Reply with only the commit message, no explanation.';

      String message;
      try {
        message = await svc.sendMessage(
          [ChatMessage.user(content: prompt)],
          model: ref.read(selectedModelProvider).id,
        ).last;
      } catch (_) {
        message = 'chore: update files';
      }
      message = message.trim().replaceAll('"', '').split('\n').first;

      if (autoCommit) {
        // Skip dialog
        await _runCommit(message);
        return;
      }

      if (!mounted) return;
      final confirmed = await CommitDialog.show(context, ref, message);
      if (confirmed != null) {
        await _runCommit(confirmed);
      }
    }

    Future<void> _runCommit(String message) async {
      try {
        final sha = await GitService(widget.project.path).commit(message);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Committed — $sha')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Commit failed: $e')),
          );
        }
      }
    }

    Future<void> _doPush() async {
      setState(() => _pushing = true);
      try {
        final branch =
            await GitService(widget.project.path).push();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pushed to origin/$branch')),
          );
        }
      } on GitNoUpstreamException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No upstream branch. Run `git push -u origin <branch>` in your terminal.'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } on GitAuthException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Push failed — check your git credentials.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Push failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _pushing = false);
      }
    }

    Future<void> _doPull() async {
      setState(() => _pulling = true);
      try {
        final n = await GitService(widget.project.path).pull();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Pulled — $n new commit(s) from origin')),
          );
          setState(() => _behindCount = 0);
        }
      } on GitConflictException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pull failed — merge conflict detected. Resolve conflicts in your editor.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } on GitNoUpstreamException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No upstream branch set.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pull failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _pulling = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      final badgeLabel = _behindCount > 0 ? ' ↓$_behindCount' : '';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left: Commit
          _buildSegment(
            label: 'Commit',
            onTap: _pushing || _pulling ? null : _doCommit,
          ),
          const SizedBox(width: 1),
          // Right: dropdown for Push / Pull / Create PR
          PopupMenuButton<String>(
            tooltip: 'Git actions',
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFF333333)),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'push',
                child: Text(
                  _pushing ? '● Pushing…' : 'Push ↑',
                  style: const TextStyle(
                      color: Color(0xFFB0B0B0), fontSize: 11),
                ),
              ),
              if (_behindCount > 0)
                PopupMenuItem(
                  value: 'pull',
                  child: Text(
                    'Pull ↓$_behindCount',
                    style: const TextStyle(
                        color: Color(0xFF4A7CFF), fontSize: 11),
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'pull',
                  child: Text('Pull',
                      style: TextStyle(
                          color: Color(0xFFB0B0B0), fontSize: 11)),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'create_pr',
                child: Text('Create PR',
                    style: TextStyle(
                        color: Color(0xFFB0B0B0), fontSize: 11)),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case 'push':
                  _doPush();
                case 'pull':
                  _doPull();
                case 'create_pr':
                  _showCreatePrDialog();
              }
            },
            child: _buildSegment(
              label: 'Push ↓$badgeLabel',
              onTap: null,
              isDropdown: true,
            ),
          ),
        ],
      );
    }

    Widget _buildSegment({
      required String label,
      VoidCallback? onTap,
      bool isDropdown = false,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: isDropdown
                ? const BorderRadius.horizontal(right: Radius.circular(5))
                : const BorderRadius.horizontal(left: Radius.circular(5)),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFFB0B0B0), fontSize: 11)),
        ),
      );
    }

    Future<void> _showCreatePrDialog() async {
      // Implemented in Task 11
    }
  }
  ```

  Note: `appliedChangesNotifierProvider` and `aiServiceFactoryProvider` will be available from Phase 2 and existing code respectively. If `AiServiceFactory.getService` signature differs, adjust to match actual API in `lib/services/ai/ai_service_factory.dart`.

- [ ] **Step 8.3: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 8.4: Commit**

  ```bash
  git add lib/features/chat/widgets/commit_dialog.dart \
         lib/shell/widgets/top_action_bar.dart
  git commit -m "feat: Commit dialog + AI commit message + Commit & Push split button"
  ```

---

## Task 9: `GitHubApiService` additions + Create PR dialog

**Files:**
- Modify: `lib/services/github/github_api_service.dart`
- Create: `lib/features/chat/widgets/create_pr_dialog.dart`
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 9.1: Add `validateToken` and `createPullRequest` to `GitHubApiService`**

  In `lib/services/github/github_api_service.dart`, add after `_repoFromGitHub`:

  ```dart
  /// Returns the GitHub username if token is valid, null otherwise.
  Future<String?> validateToken() async {
    try {
      final response = await _dio.get('/user');
      final data = response.data as Map<String, dynamic>;
      return data['login'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Creates a pull request. Returns the HTML URL of the created PR.
  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
  }) async {
    try {
      final response = await _dio.post(
        '/repos/$owner/$repo/pulls',
        data: {
          'title': title,
          'body': body,
          'head': head,
          'base': base,
          'draft': draft,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['html_url'] as String;
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to create pull request',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<List<String>> listRepoBranches(String owner, String repo) async {
    try {
      final response = await _dio.get(
        '/repos/$owner/$repo/branches',
        queryParameters: {'per_page': 50},
      );
      return (response.data as List)
          .map((b) => (b as Map<String, dynamic>)['name'] as String)
          .toList();
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to list branches',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }
  ```

- [ ] **Step 9.2: Create `CreatePrDialog`**

  Create `lib/features/chat/widgets/create_pr_dialog.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  class PrFormResult {
    const PrFormResult({
      required this.title,
      required this.body,
      required this.base,
      required this.draft,
    });
    final String title;
    final String body;
    final String base;
    final bool draft;
  }

  class CreatePrDialog extends ConsumerStatefulWidget {
    const CreatePrDialog({
      super.key,
      required this.initialTitle,
      required this.initialBody,
      required this.branches,
    });
    final String initialTitle;
    final String initialBody;
    final List<String> branches;

    static Future<PrFormResult?> show(
      BuildContext context, {
      required String initialTitle,
      required String initialBody,
      required List<String> branches,
    }) {
      return showDialog<PrFormResult>(
        context: context,
        builder: (_) => CreatePrDialog(
          initialTitle: initialTitle,
          initialBody: initialBody,
          branches: branches,
        ),
      );
    }

    @override
    ConsumerState<CreatePrDialog> createState() => _CreatePrDialogState();
  }

  class _CreatePrDialogState extends ConsumerState<CreatePrDialog> {
    late final TextEditingController _titleController;
    late final TextEditingController _bodyController;
    late String _base;
    bool _draft = false;

    @override
    void initState() {
      super.initState();
      _titleController =
          TextEditingController(text: widget.initialTitle);
      _bodyController = TextEditingController(text: widget.initialBody);
      _base = widget.branches.contains('main')
          ? 'main'
          : (widget.branches.isNotEmpty ? widget.branches.first : 'main');
    }

    @override
    void dispose() {
      _titleController.dispose();
      _bodyController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Create Pull Request',
            style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                maxLength: 70,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle:
                      TextStyle(color: Color(0xFF888888), fontSize: 11),
                ),
                style: const TextStyle(
                    color: Color(0xFFE0E0E0), fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle:
                      TextStyle(color: Color(0xFF888888), fontSize: 11),
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(
                    color: Color(0xFFE0E0E0), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Base branch:',
                      style: TextStyle(
                          color: Color(0xFF888888), fontSize: 11)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: widget.branches.contains(_base)
                        ? _base
                        : null,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(
                        color: Color(0xFFE0E0E0), fontSize: 11),
                    items: widget.branches
                        .map((b) => DropdownMenuItem(
                            value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _base = v);
                    },
                  ),
                  const Spacer(),
                  const Text('Draft PR',
                      style: TextStyle(
                          color: Color(0xFF888888), fontSize: 11)),
                  Switch(
                    value: _draft,
                    onChanged: (v) => setState(() => _draft = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.of(context).pop(PrFormResult(
                title: title,
                body: _bodyController.text.trim(),
                base: _base,
                draft: _draft,
              ));
            },
            child: const Text('Create PR',
                style: TextStyle(color: Color(0xFF4A7CFF))),
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 9.3: Wire `_showCreatePrDialog` in `_CommitPushButtonState`**

  In `lib/shell/widgets/top_action_bar.dart`, add imports:

  ```dart
  import '../../features/chat/widgets/create_pr_dialog.dart';
  import '../../data/datasources/local/secure_storage_source.dart';
  ```

  Replace the empty `_showCreatePrDialog` stub with:

  ```dart
  Future<void> _showCreatePrDialog() async {
    // 1. Check GitHub token
    final storage = ref.read(secureStorageSourceProvider);
    final token = await storage.readGitHubToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Connect GitHub in Settings → Providers')),
        );
      }
      return;
    }

    // 2. Check current branch
    final branch = await Process.run(
      'git', ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: widget.project.path,
    );
    final currentBranch = (branch.stdout as String).trim();
    if (currentBranch == 'main' || currentBranch == 'master') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "You're on the default branch — create a feature branch first.")),
        );
      }
      return;
    }

    // 3. Generate PR title + body via AI
    final changedFiles = ref
        .read(appliedChangesNotifierProvider)
        .where((c) => c.sessionId == ref.read(activeSessionIdProvider))
        .map((c) => c.filePath)
        .toList();
    final aiSvc = ref
        .read(aiServiceFactoryProvider)
        .getService(ref.read(selectedModelProvider));
    final prompt =
        'Generate a PR title (max 70 chars) and bullet-point body for these '
        'changes: ${changedFiles.join(', ')}. '
        'Reply in this format:\nTITLE: <title>\nBODY:\n<bullets>';
    String aiOutput = '';
    try {
      aiOutput = await aiSvc
          .sendMessage(
            [ChatMessage.user(content: prompt)],
            model: ref.read(selectedModelProvider).id,
          )
          .last;
    } catch (_) {}

    String prTitle = currentBranch.replaceAll('-', ' ');
    String prBody = '';
    final titleMatch = RegExp(r'TITLE:\s*(.+)').firstMatch(aiOutput);
    final bodyMatch = RegExp(r'BODY:\n([\s\S]+)').firstMatch(aiOutput);
    if (titleMatch != null) prTitle = titleMatch.group(1)!.trim();
    if (bodyMatch != null) prBody = bodyMatch.group(1)!.trim();

    // 4. Fetch branches
    List<String> branches = ['main', 'master'];
    // (Full implementation with GitHubApiService.listRepoBranches would need
    //  owner/repo detection from git remote URL — use defaults here)

    if (!mounted) return;

    // 5. Show dialog
    final result = await CreatePrDialog.show(
      context,
      initialTitle: prTitle,
      initialBody: prBody,
      branches: branches,
    );

    if (result == null) return;

    // 6. Create PR
    // Parse owner/repo from git remote
    final remoteResult = await Process.run(
      'git', ['remote', 'get-url', 'origin'],
      workingDirectory: widget.project.path,
    );
    final remoteUrl = (remoteResult.stdout as String).trim();
    final repoMatch =
        RegExp(r'github\.com[:/]([^/]+)/([^/\.]+)').firstMatch(remoteUrl);
    if (repoMatch == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not detect GitHub owner/repo from remote')),
        );
      }
      return;
    }
    final owner = repoMatch.group(1)!;
    final repo = repoMatch.group(2)!;

    try {
      final apiSvc = GitHubApiService(token);
      final prUrl = await apiSvc.createPullRequest(
        owner: owner,
        repo: repo,
        title: result.title,
        body: result.body,
        head: currentBranch,
        base: result.base,
        draft: result.draft,
      );
      await Process.run('open', [prUrl]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pull request created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create PR: $e')),
        );
      }
    }
  }
  ```

  Add the necessary imports at the top of the file:

  ```dart
  import '../../services/github/github_api_service.dart';
  ```

- [ ] **Step 9.4: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 9.5: Commit**

  ```bash
  git add lib/services/github/github_api_service.dart \
         lib/features/chat/widgets/create_pr_dialog.dart \
         lib/shell/widgets/top_action_bar.dart
  git commit -m "feat: Create PR dialog + GitHubApiService.createPullRequest"
  ```

---

## Task 10: Final integration check

- [ ] **Step 10.1: Run full test suite**

  ```bash
  flutter test
  ```

  Expected: all tests pass.

- [ ] **Step 10.2: Run dart format**

  ```bash
  dart format lib/ test/
  ```

- [ ] **Step 10.3: Run flutter analyze**

  ```bash
  flutter analyze
  ```

  Expected: no issues.

- [ ] **Step 10.4: Manual smoke test on macOS**

  Run `flutter run -d macos` and verify:
  - VS Code/Cursor/Finder/Terminal dropdown works for an active project
  - "Initialize Git" button appears for non-git projects and disappears after init
  - "+ Add action" dialog saves and action chip appears in dropdown
  - Running an action shows the floating output panel with live output
  - Right-clicking a project tile shows "Rename project" → dialog prefills name → sidebar updates
  - Right-clicking a conversation shows "Rename" → dialog works
  - "Commit" button: generates AI message → dialog shown → `git log` shows new commit
  - "Push ↑" button shows toast on success/failure
  - "Pull" shows behind count badge and clears on pull
  - "Create PR" checks token, generates AI title/body, opens PR dialog
