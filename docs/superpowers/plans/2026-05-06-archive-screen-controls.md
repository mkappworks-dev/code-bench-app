# Archive Screen Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add collapsible project groups, per-session delete, project-level unarchive-all / delete-all to the Archive screen, and a confirmation dialog to sidebar session delete.

**Architecture:** `ArchiveScreen` is the single `ConsumerStatefulWidget` that owns `archiveActionsProvider` reads and a `_pendingAction` enum for snackbar context. A new `ArchiveProjectGroup` stateful widget handles expand/collapse and group-level actions via callbacks; `ArchivedSessionCard` is refactored to pure `StatefulWidget` receiving action callbacks. The sidebar confirmation is added inline in `project_sidebar.dart`.

**Tech Stack:** Flutter, Riverpod (`ConsumerStatefulWidget`), Freezed, `AppDialog` / `AppSnackBar` from `lib/core/widgets/`, `AppColors` / `AppIcons` / `ThemeConstants` from `lib/core/`.

---

## File Map

| File | Change |
|---|---|
| `lib/features/archive/notifiers/archive_actions.dart` | Add `deleteSession`, `unarchiveAllForProject`, `deleteAllForProject` |
| `lib/features/archive/widgets/archive_project_group.dart` | **New** — collapsible group widget |
| `lib/features/archive/widgets/archived_session_card.dart` | Refactor to `StatefulWidget` with action callbacks; add Delete chip |
| `lib/features/archive/archive_screen.dart` | Wire `ArchiveProjectGroup`; add `_pendingAction` enum + snackbar logic |
| `lib/features/project_sidebar/project_sidebar.dart` | Add confirm dialog before sidebar session delete |
| `test/features/settings/archive_screen_test.dart` | Extend with new action tests |
| `test/features/project_sidebar/conversation_tile_archive_test.dart` | Add sidebar delete-confirm test |

---

## Task 1: Extend `ArchiveActions` with delete and bulk methods

**Files:**
- Modify: `lib/features/archive/notifiers/archive_actions.dart`
- Modify: `test/features/settings/archive_screen_test.dart`

- [ ] **Step 1: Write failing tests for the three new methods**

Add to `test/features/settings/archive_screen_test.dart`, below the existing `_FakeArchiveActions` class. Replace the class entirely with:

```dart
class _FakeArchiveActions extends ArchiveActions {
  final List<String> unarchiveCalls = [];
  final List<String> deleteCalls = [];
  final List<List<String>> unarchiveAllCalls = [];
  final List<List<String>> deleteAllCalls = [];

  @override
  Future<void> unarchiveSession(String id) async => unarchiveCalls.add(id);

  @override
  Future<void> deleteSession(String id) async => deleteCalls.add(id);

  @override
  Future<void> unarchiveAllForProject(List<String> ids) async =>
      unarchiveAllCalls.add(ids);

  @override
  Future<void> deleteAllForProject(List<String> ids) async =>
      deleteAllCalls.add(ids);
}
```

Add these test cases at the bottom of `main()`:

```dart
testWidgets('deleteSession records call on fake', (tester) async {
  final fake = _FakeArchiveActions();
  await fake.deleteSession('s99');
  expect(fake.deleteCalls, contains('s99'));
});

testWidgets('unarchiveAllForProject records ids', (tester) async {
  final fake = _FakeArchiveActions();
  await fake.unarchiveAllForProject(['a', 'b']);
  expect(fake.unarchiveAllCalls, [['a', 'b']]);
});

testWidgets('deleteAllForProject records ids', (tester) async {
  final fake = _FakeArchiveActions();
  await fake.deleteAllForProject(['x', 'y']);
  expect(fake.deleteAllCalls, [['x', 'y']]);
});
```

- [ ] **Step 2: Run tests — expect failures**

```bash
flutter test test/features/settings/archive_screen_test.dart
```

Expected: errors because `deleteSession`, `unarchiveAllForProject`, `deleteAllForProject` don't exist on `ArchiveActions` yet.

- [ ] **Step 3: Add the three methods to `ArchiveActions`**

Replace the full content of `lib/features/archive/notifiers/archive_actions.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/session/session_service.dart';
import 'archive_failure.dart';

part 'archive_actions.g.dart';

/// Imperative actions for the Archive screen.
@Riverpod(keepAlive: true)
class ArchiveActions extends _$ArchiveActions {
  @override
  FutureOr<void> build() {}

  ArchiveFailure _asFailure(Object e) => switch (e) {
    StorageException() => ArchiveFailure.storage(e.message),
    _ => ArchiveFailure.unknown(e),
  };

  Future<void> unarchiveSession(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final svc = await ref.read(sessionServiceProvider.future);
        await svc.unarchiveSession(id);
      } catch (e, st) {
        dLog('[ArchiveActions] unarchiveSession failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> deleteSession(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final svc = await ref.read(sessionServiceProvider.future);
        await svc.deleteSession(id);
      } catch (e, st) {
        dLog('[ArchiveActions] deleteSession failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> unarchiveAllForProject(List<String> ids) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final svc = await ref.read(sessionServiceProvider.future);
        for (final id in ids) {
          await svc.unarchiveSession(id);
        }
      } catch (e, st) {
        dLog('[ArchiveActions] unarchiveAllForProject failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> deleteAllForProject(List<String> ids) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final svc = await ref.read(sessionServiceProvider.future);
        for (final id in ids) {
          await svc.deleteSession(id);
        }
      } catch (e, st) {
        dLog('[ArchiveActions] deleteAllForProject failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
```

- [ ] **Step 4: Run tests — expect green**

```bash
flutter test test/features/settings/archive_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/features/archive/notifiers/archive_actions.dart
```

Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/archive/notifiers/archive_actions.dart \
        test/features/settings/archive_screen_test.dart
git commit -m "feat(archive): add deleteSession, unarchiveAllForProject, deleteAllForProject to ArchiveActions"
```

---

## Task 2: Create `ArchiveProjectGroup` widget

**Files:**
- Create: `lib/features/archive/widgets/archive_project_group.dart`

`ArchiveProjectGroup` is a self-contained stateful widget. It owns expand/collapse state and hover state for the header. All archive actions are received as callbacks so the widget has no direct dependency on `archiveActionsProvider`.

The widget renders a clickable header row (chevron + folder icon + project name + hover-reveal chips) and, when expanded, a column of `ArchivedSessionCard` widgets.

The "Delete All" chip shows a confirmation `AppDialog` before calling `onDeleteAll`. The "Unarchive All" chip calls `onUnarchiveAll` directly.

- [ ] **Step 1: Create the file**

Create `lib/features/archive/widgets/archive_project_group.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/session/models/chat_session.dart';
import 'archived_session_card.dart';

class ArchiveProjectGroup extends StatefulWidget {
  const ArchiveProjectGroup({
    super.key,
    required this.projectName,
    required this.sessions,
    required this.initiallyExpanded,
    required this.onUnarchive,
    required this.onDelete,
    required this.onUnarchiveAll,
    required this.onDeleteAll,
  });

  final String projectName;
  final List<ChatSession> sessions;
  final bool initiallyExpanded;
  final void Function(String sessionId) onUnarchive;
  final void Function(String sessionId) onDelete;
  final VoidCallback onUnarchiveAll;
  final VoidCallback onDeleteAll;

  @override
  State<ArchiveProjectGroup> createState() => _ArchiveProjectGroupState();
}

class _ArchiveProjectGroupState extends State<ArchiveProjectGroup> {
  late bool _expanded = widget.initiallyExpanded;
  bool _hovered = false;

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final count = widget.sessions.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: AppIcons.trash,
        iconType: AppDialogIconType.destructive,
        title: 'Delete all archived conversations for "${widget.projectName}"?',
        content: Builder(
          builder: (context) {
            final c = AppColors.of(context);
            return Text(
              'This will permanently delete $count archived conversation${count == 1 ? '' : 's'} '
              'and all their messages. This cannot be undone.',
              style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
            );
          },
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(ctx).pop(false)),
          AppDialogAction.destructive(
            label: 'Delete All',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDeleteAll();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(AppIcons.chevronRight, size: 10, color: c.mutedFg),
                  ),
                  const SizedBox(width: 6),
                  Icon(AppIcons.folder, size: 11, color: c.mutedFg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.projectName.toUpperCase(),
                      style: TextStyle(
                        color: c.mutedFg,
                        fontSize: ThemeConstants.uiFontSizeLabel,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 120),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionChip(
                          icon: AppIcons.archiveRestore,
                          label: 'Unarchive All',
                          isDestructive: false,
                          onTap: widget.onUnarchiveAll,
                        ),
                        const SizedBox(width: 5),
                        _ActionChip(
                          icon: AppIcons.trash,
                          label: 'Delete All',
                          isDestructive: true,
                          onTap: () => _confirmDeleteAll(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded)
          Column(
            children: widget.sessions
                .map(
                  (s) => ArchivedSessionCard(
                    session: s,
                    onUnarchive: () => widget.onUnarchive(s.sessionId),
                    onDelete: () => widget.onDelete(s.sessionId),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ActionChip extends StatefulWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isDestructive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hovered = _hovered;
    final Color fg = widget.isDestructive
        ? (hovered ? c.error : c.chipText)
        : (hovered ? c.accent : c.chipText);
    final Color bg = widget.isDestructive
        ? (hovered ? c.error.withValues(alpha: 0.12) : c.chipFill)
        : (hovered ? c.accentTintMid : c.chipFill);
    final Color border = widget.isDestructive
        ? (hovered ? c.destructiveBorder : c.chipStroke)
        : (hovered ? c.accentBorderTeal : c.chipStroke);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 10, color: fg),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                  fontWeight: FontWeight.w500,
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

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/archive/widgets/archive_project_group.dart
```

Expected: no issues. Fix any import errors before proceeding.

- [ ] **Step 3: Commit**

```bash
git add lib/features/archive/widgets/archive_project_group.dart
git commit -m "feat(archive): add ArchiveProjectGroup collapsible widget"
```

---

## Task 3: Refactor `ArchivedSessionCard` — add Delete chip and confirmation dialog

**Files:**
- Modify: `lib/features/archive/widgets/archived_session_card.dart`
- Modify: `test/features/settings/archive_screen_test.dart`

`ArchivedSessionCard` currently reads `archiveActionsProvider` directly. We refactor it to receive action callbacks, which lets `ArchiveScreen` own all provider access and track `_pendingAction` centrally. The card becomes a plain `StatefulWidget`.

- [ ] **Step 1: Write failing tests for the Delete button**

Add to `test/features/settings/archive_screen_test.dart`, inside `main()`:

```dart
testWidgets('archived session card shows Delete button', (tester) async {
  final session = ChatSession(
    sessionId: 's3',
    title: 'Chat to delete',
    modelId: 'm',
    providerId: 'anthropic',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
  await tester.pumpWidget(_buildArchive(sessions: [session]));
  await tester.pump();

  expect(find.text('Delete'), findsOneWidget);
});

testWidgets('Delete button shows confirmation dialog', (tester) async {
  final session = ChatSession(
    sessionId: 's4',
    title: 'Deletable chat',
    modelId: 'm',
    providerId: 'anthropic',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
  await tester.pumpWidget(_buildArchive(sessions: [session]));
  await tester.pump();

  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  expect(find.text('Delete archived conversation?'), findsOneWidget);
  expect(find.text('Deletable chat'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests — expect failures**

```bash
flutter test test/features/settings/archive_screen_test.dart
```

Expected: failures — no Delete button exists yet.

- [ ] **Step 3: Rewrite `archived_session_card.dart`**

Replace the full file content:

```dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/session/models/chat_session.dart';

class ArchivedSessionCard extends StatefulWidget {
  const ArchivedSessionCard({
    super.key,
    required this.session,
    required this.onUnarchive,
    required this.onDelete,
  });

  final ChatSession session;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  @override
  State<ArchivedSessionCard> createState() => _ArchivedSessionCardState();
}

class _ArchivedSessionCardState extends State<ArchivedSessionCard> {
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: AppIcons.trash,
        iconType: AppDialogIconType.destructive,
        title: 'Delete archived conversation?',
        content: Builder(
          builder: (context) {
            final c = AppColors.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.chipFill,
                    border: Border.all(color: c.chipStroke),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.session.title,
                    style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will permanently delete the conversation and all its messages. '
                  'This cannot be undone.',
                  style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ],
            );
          },
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(ctx).pop(false)),
          AppDialogAction.destructive(
            label: 'Delete',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.background,
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.title,
                  style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Archived ${widget.session.updatedAt.relativeTime} · Created ${widget.session.createdAt.relativeTime}',
                  style: TextStyle(color: c.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CardChip(
                icon: AppIcons.archiveRestore,
                label: 'Unarchive',
                isDestructive: false,
                onTap: widget.onUnarchive,
              ),
              const SizedBox(width: 6),
              _CardChip(
                icon: AppIcons.trash,
                label: 'Delete',
                isDestructive: true,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardChip extends StatefulWidget {
  const _CardChip({
    required this.icon,
    required this.label,
    required this.isDestructive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  State<_CardChip> createState() => _CardChipState();
}

class _CardChipState extends State<_CardChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hovered = _hovered;
    final Color fg = widget.isDestructive
        ? (hovered ? c.error : c.chipText)
        : (hovered ? c.accent : c.chipText);
    final Color bg = widget.isDestructive
        ? (hovered ? c.error.withValues(alpha: 0.12) : c.chipFill)
        : (hovered ? c.accentTintMid : c.chipFill);
    final Color border = widget.isDestructive
        ? (hovered ? c.destructiveBorder : c.chipStroke)
        : (hovered ? c.accentBorderTeal : c.chipStroke);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 12, color: fg),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  fontWeight: FontWeight.w500,
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

- [ ] **Step 4: Run tests — expect green**

```bash
flutter test test/features/settings/archive_screen_test.dart
```

Expected: all tests pass including the two new ones. The existing `Unarchive button calls archiveActionsProvider.unarchiveSession` test will now fail because `ArchivedSessionCard` no longer reads the provider directly — fix it by updating `_buildArchive` to pass a fake action and updating the test to verify the callback fires instead. Update that test:

```dart
testWidgets('Unarchive button fires onUnarchive callback', (tester) async {
  // The archive screen now passes callbacks down; we verify via the
  // fake actions notifier that the provider method is still called.
  final fake = _FakeArchiveActions();
  final session = ChatSession(
    sessionId: 's2',
    title: 'Another chat',
    modelId: 'm',
    providerId: 'anthropic',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
  await tester.pumpWidget(_buildArchive(sessions: [session], archiveActions: fake));
  await tester.pump();

  await tester.tap(find.text('Unarchive'));
  await tester.pump();

  expect(fake.unarchiveCalls, contains('s2'));
});
```

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/features/archive/widgets/archived_session_card.dart
```

Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/archive/widgets/archived_session_card.dart \
        test/features/settings/archive_screen_test.dart
git commit -m "feat(archive): add Delete chip and confirmation dialog to ArchivedSessionCard"
```

---

## Task 4: Update `ArchiveScreen` — wire `ArchiveProjectGroup` and `_pendingAction`

**Files:**
- Modify: `lib/features/archive/archive_screen.dart`
- Modify: `test/features/settings/archive_screen_test.dart`

`ArchiveScreen` is the only consumer of `archiveActionsProvider`. It tracks `_pendingAction` (set just before each action call) so the `ref.listen` can show the right snackbar.

The `_ArchivePendingAction` enum is defined at file scope.

- [ ] **Step 1: Write failing test for smart-default expansion**

Add to `test/features/settings/archive_screen_test.dart` inside `main()`:

```dart
testWidgets('single project group is expanded by default', (tester) async {
  final session = ChatSession(
    sessionId: 'exp1',
    title: 'Expandable session',
    modelId: 'm',
    providerId: 'anthropic',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
  await tester.pumpWidget(_buildArchive(sessions: [session]));
  await tester.pump();

  // Session card is visible without tapping the header (expanded by default).
  expect(find.text('Expandable session'), findsOneWidget);
  expect(find.text('Unarchive'), findsOneWidget);
});

testWidgets('multiple project groups are collapsed by default', (tester) async {
  final project1 = Project(id: 'p1', path: '/a', name: 'alpha', status: ProjectStatus.active, actions: const []);
  final project2 = Project(id: 'p2', path: '/b', name: 'beta', status: ProjectStatus.active, actions: const []);
  final s1 = ChatSession(
    sessionId: 'c1', title: 'Alpha session', modelId: 'm', providerId: 'anthropic',
    projectId: 'p1', createdAt: DateTime(2025), updatedAt: DateTime(2025),
  );
  final s2 = ChatSession(
    sessionId: 'c2', title: 'Beta session', modelId: 'm', providerId: 'anthropic',
    projectId: 'p2', createdAt: DateTime(2025), updatedAt: DateTime(2025),
  );
  await tester.pumpWidget(_buildArchive(
    sessions: [s1, s2],
    projects: [project1, project2],
  ));
  await tester.pump();

  // Session cards not visible — groups are collapsed.
  expect(find.text('Alpha session'), findsNothing);
  expect(find.text('Beta session'), findsNothing);
  // But project name headers are visible.
  expect(find.textContaining('ALPHA'), findsOneWidget);
  expect(find.textContaining('BETA'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests — expect failures**

```bash
flutter test test/features/settings/archive_screen_test.dart
```

Expected: the new tests fail because the archive screen still uses the old flat rendering with no expand/collapse.

- [ ] **Step 3: Rewrite `archive_screen.dart`**

Replace the full file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/project/models/project.dart';
import '../../data/session/models/chat_session.dart';
import '../project_sidebar/notifiers/project_sidebar_actions.dart';
import '../project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'notifiers/archive_actions.dart';
import 'notifiers/archive_failure.dart';
import '../settings/widgets/section_label.dart';
import 'widgets/archive_error_view.dart';
import 'widgets/archive_project_group.dart';

enum _ArchivePendingAction { unarchive, unarchiveAll, delete, deleteAll }

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  _ArchivePendingAction? _pendingAction;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sessionsAsync = ref.watch(archivedSessionsProvider);
    final projectsAsync = ref.watch(projectsProvider);

    ref.listen(archiveActionsProvider, (prev, next) {
      if (!mounted) return;
      if (next is AsyncError) {
        final failure = next.error;
        if (failure is! ArchiveFailure) return;
        switch (failure) {
          case ArchiveStorageError():
            AppSnackBar.show(context, 'Storage error — please try again.', type: AppSnackBarType.error);
          case ArchiveUnknownError():
            AppSnackBar.show(context, 'Unexpected error — please try again.', type: AppSnackBarType.error);
        }
        return;
      }
      if (next is AsyncData && prev is AsyncLoading) {
        final message = switch (_pendingAction) {
          _ArchivePendingAction.unarchive => 'Session unarchived',
          _ArchivePendingAction.unarchiveAll => 'All sessions unarchived',
          _ArchivePendingAction.delete => 'Session deleted',
          _ArchivePendingAction.deleteAll => 'All archived sessions deleted',
          null => 'Done',
        };
        AppSnackBar.show(context, message, type: AppSnackBarType.success);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Archive'),
        const SizedBox(height: 8),
        Expanded(
          child: sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, st) {
              dLog('[archive] load failed: $e\n$st');
              return ArchiveErrorView(
                onRetry: () => ref.read(projectSidebarActionsProvider.notifier).refreshArchivedSessions(),
              );
            },
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.archive, size: 32, color: c.mutedFg),
                      const SizedBox(height: 12),
                      Text('No archived conversations', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                    ],
                  ),
                );
              }

              final projects = switch (projectsAsync) {
                AsyncData(:final value) => value,
                _ => const <Project>[],
              };
              final projectMap = {for (final p in projects) p.id: p.name};

              final groups = <String?, List<ChatSession>>{};
              for (final s in sessions) {
                groups.putIfAbsent(s.projectId, () => []).add(s);
              }

              return ListView(
                padding: const EdgeInsets.only(right: 24, bottom: 24),
                children: [
                  for (final entry in groups.entries)
                    ArchiveProjectGroup(
                      projectName: projectMap[entry.key] ?? 'No Project',
                      sessions: entry.value,
                      initiallyExpanded: groups.length == 1,
                      onUnarchive: (id) {
                        _pendingAction = _ArchivePendingAction.unarchive;
                        ref.read(archiveActionsProvider.notifier).unarchiveSession(id);
                      },
                      onDelete: (id) {
                        _pendingAction = _ArchivePendingAction.delete;
                        ref.read(archiveActionsProvider.notifier).deleteSession(id);
                      },
                      onUnarchiveAll: () {
                        _pendingAction = _ArchivePendingAction.unarchiveAll;
                        final ids = entry.value.map((s) => s.sessionId).toList();
                        ref.read(archiveActionsProvider.notifier).unarchiveAllForProject(ids);
                      },
                      onDeleteAll: () {
                        _pendingAction = _ArchivePendingAction.deleteAll;
                        final ids = entry.value.map((s) => s.sessionId).toList();
                        ref.read(archiveActionsProvider.notifier).deleteAllForProject(ids);
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests — expect green**

```bash
flutter test test/features/settings/archive_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/features/archive/
```

Expected: no issues.

- [ ] **Step 6: Format and commit**

```bash
dart format lib/features/archive/
git add lib/features/archive/archive_screen.dart \
        lib/features/archive/widgets/archive_project_group.dart \
        lib/features/archive/widgets/archived_session_card.dart \
        test/features/settings/archive_screen_test.dart
git commit -m "feat(archive): wire ArchiveProjectGroup into ArchiveScreen with smart expansion and _pendingAction snackbars"
```

---

## Task 5: Add confirmation dialog to sidebar session delete

**Files:**
- Modify: `lib/features/project_sidebar/widgets/conversation_tile.dart`
- Modify: `test/features/project_sidebar/conversation_tile_archive_test.dart`

`ConversationTile._showContextMenu` currently fires `onDelete?.call()` immediately when the user picks Delete from the context menu. We intercept that to show an `AppDialog` confirmation first. `ConversationTile` already has `widget.session.title`, so no session lookup is needed. The pattern mirrors `ArchivedSessionCard`'s confirm-before-delete.

- [ ] **Step 1: Write failing test**

Add to `test/features/project_sidebar/conversation_tile_archive_test.dart`, inside `main()`:

```dart
testWidgets('right-click Delete shows confirmation dialog before firing onDelete', (tester) async {
  bool deleted = false;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [AppColors.dark]),
      home: Scaffold(
        body: ConversationTile(
          session: session,
          isActive: false,
          onTap: () {},
          onDelete: () => deleted = true,
        ),
      ),
    ),
  );

  await tester.sendEventToBinding(
    TestPointer(1, PointerDeviceKind.mouse).hover(tester.getCenter(find.text('My session'))),
  );
  final gesture = await tester.startGesture(
    tester.getCenter(find.text('My session')),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();

  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  // Dialog shown, onDelete not yet called.
  expect(find.text('Delete this conversation?'), findsOneWidget);
  expect(deleted, isFalse);

  // Confirm deletion.
  await tester.tap(find.text('Delete').last);
  await tester.pumpAndSettle();

  expect(deleted, isTrue);
});

testWidgets('right-click Delete — Cancel does not call onDelete', (tester) async {
  bool deleted = false;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [AppColors.dark]),
      home: Scaffold(
        body: ConversationTile(
          session: session,
          isActive: false,
          onTap: () {},
          onDelete: () => deleted = true,
        ),
      ),
    ),
  );

  await tester.sendEventToBinding(
    TestPointer(1, PointerDeviceKind.mouse).hover(tester.getCenter(find.text('My session'))),
  );
  final gesture = await tester.startGesture(
    tester.getCenter(find.text('My session')),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();

  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();

  expect(deleted, isFalse);
});
```

- [ ] **Step 2: Run tests — expect failures**

```bash
flutter test test/features/project_sidebar/conversation_tile_archive_test.dart
```

Expected: the two new tests fail — `onDelete` fires immediately without a dialog.

- [ ] **Step 3: Update `conversation_tile.dart`**

Add the missing import at the top of the file:

```dart
import '../../../core/widgets/app_dialog.dart';
```

Then in `_showContextMenu`, replace:

```dart
if (action == 'delete') onDelete?.call();
```

With:

```dart
if (action == 'delete') {
  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: AppIcons.trash,
      iconType: AppDialogIconType.destructive,
      title: 'Delete this conversation?',
      content: Builder(
        builder: (context) {
          final c = AppColors.of(context);
          return Text(
            '"${session.title}" and all its messages will be permanently deleted. '
            'This cannot be undone.',
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
          );
        },
      ),
      actions: [
        AppDialogAction.cancel(onPressed: () => Navigator.of(ctx).pop(false)),
        AppDialogAction.destructive(
          label: 'Delete',
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  if (confirmed == true) onDelete?.call();
}
```

- [ ] **Step 4: Run tests — expect green**

```bash
flutter test test/features/project_sidebar/conversation_tile_archive_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Analyze and format**

```bash
flutter analyze lib/features/project_sidebar/widgets/conversation_tile.dart
dart format lib/features/project_sidebar/widgets/conversation_tile.dart
```

Expected: no issues.

- [ ] **Step 7: Final commit**

```bash
git add lib/features/project_sidebar/widgets/conversation_tile.dart \
        test/features/project_sidebar/conversation_tile_archive_test.dart
git commit -m "feat(sidebar): add confirmation dialog before session delete"
```

---

## Post-Implementation Checklist

- [ ] `flutter analyze` — clean across all changed files
- [ ] `dart format lib/ test/` — no diffs
- [ ] `flutter test` — all green
- [ ] Manual smoke test: open Archive screen with one project → verify it's expanded; open with multiple → verify collapsed; hover group header → verify chips appear; delete a session via confirm → verify snackbar says "Session deleted"; right-click a sidebar conversation → Delete → verify confirm dialog appears
