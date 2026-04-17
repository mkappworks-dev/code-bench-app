import 'dart:async';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/project/models/project.dart';
import '../../data/session/models/chat_session.dart';
import '../chat/notifiers/chat_notifier.dart';
import 'notifiers/project_sidebar_actions.dart';
import 'notifiers/project_sidebar_failure.dart';
import 'notifiers/project_sidebar_notifier.dart';
import 'widgets/project_tile.dart';
import 'widgets/relocate_project_dialog.dart';
import 'widgets/remove_project_dialog.dart';
import 'widgets/sidebar_empty_state.dart';
import 'widgets/sidebar_footer.dart';
import 'widgets/sidebar_header.dart';

class ProjectSidebar extends ConsumerStatefulWidget {
  const ProjectSidebar({super.key});

  @override
  ConsumerState<ProjectSidebar> createState() => _ProjectSidebarState();
}

class _ProjectSidebarState extends ConsumerState<ProjectSidebar> with WidgetsBindingObserver {
  bool _adding = false;
  // Set while an archive/delete-session mutation is in flight so the
  // provider-level listener knows which in-flight op the AsyncError belongs
  // to. Dialog-scoped flows (add/remove/relocate) have their own gates.
  bool _mutating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_safeRefresh()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check every project's folder on disk whenever the user returns
    // to Code Bench. Catches the common flow: delete/move a folder in
    // Finder, alt-tab back to the app, expect the sidebar to reflect it.
    if (state == AppLifecycleState.resumed) {
      unawaited(_safeRefresh());
    }
  }

  Future<void> _safeRefresh() async {
    await ref.read(projectSidebarActionsProvider.notifier).refreshProjectStatuses();
  }

  Future<void> _addProject() async {
    final result = await FilePicker.getDirectoryPath(dialogTitle: 'Select project folder');
    if (result == null) return;

    setState(() => _adding = true);
    try {
      await ref.read(projectSidebarActionsProvider.notifier).addExistingFolder(result);
      if (!mounted) return;
      if (!ref.read(projectSidebarActionsProvider).hasError) {
        final added = ref.read(projectsProvider).value?.firstWhereOrNull((p) => p.path == result);
        if (added != null) {
          ref.read(activeProjectIdProvider.notifier).set(added.id);
          ref.read(expandedProjectIdsProvider.notifier).expand(added.id);
        }
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _runSessionMutation(Future<void> Function() op) async {
    setState(() => _mutating = true);
    try {
      await op();
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _newConversation(BuildContext context, String projectId) async {
    final model = ref.read(selectedModelProvider);
    final sessionId = await ref
        .read(projectSidebarActionsProvider.notifier)
        .createSession(model: model, projectId: projectId);
    ref.read(activeSessionIdProvider.notifier).set(sessionId);
    ref.read(activeProjectIdProvider.notifier).set(projectId);
    if (context.mounted) context.go('/chat/$sessionId');
  }

  List<Project> _sortedProjects(List<Project> projects, ProjectSortState? sortState, WidgetRef ref) {
    final order = sortState?.projectSort ?? ProjectSortOrder.lastMessage;
    if (order == ProjectSortOrder.createdAt) {
      return [...projects]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    if (order == ProjectSortOrder.lastMessage) {
      final lastTimes = {
        for (final p in projects)
          p.id: ref
              .watch(projectSessionsProvider(p.id))
              .value
              ?.map((s) => s.updatedAt)
              .fold<DateTime?>(null, (max, t) => max == null || t.isAfter(max) ? t : max),
      };
      return [...projects]..sort((a, b) {
        final aTime = lastTimes[a.id];
        final bTime = lastTimes[b.id];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
    }
    // manual — preserve DB insertion order (sortOrder field)
    return [...projects]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<ChatSession> _sortedSessions(List<ChatSession> sessions, ProjectSortState? sortState) {
    final order = sortState?.threadSort ?? ThreadSortOrder.lastMessage;
    if (order == ThreadSortOrder.createdAt) {
      return [...sessions]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return [...sessions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    ref.listen(projectSidebarActionsProvider, (_, next) {
      if (!_adding && !_mutating) return;
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      final inAddFlow = _adding;
      final message = switch (failure) {
        ProjectSidebarDuplicatePath() => 'This project is already added.',
        ProjectSidebarInvalidPath() => 'Invalid folder path.',
        ProjectSidebarStorageError() =>
          inAddFlow ? 'Failed to save project — please try again.' : 'Operation failed — please try again.',
        ProjectSidebarUnknownError() =>
          inAddFlow ? 'Failed to add project — please try again.' : 'Operation failed — please try again.',
        _ => inAddFlow ? 'Failed to add project — please try again.' : 'Operation failed — please try again.',
      };
      AppSnackBar.show(context, message, type: AppSnackBarType.error);
    });

    final projectsAsync = ref.watch(projectsProvider);
    final expandedIds = ref.watch(expandedProjectIdsProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);
    // Watch activeProjectId to rebuild when it changes.
    ref.watch(activeProjectIdProvider);
    final sortState = ref.watch(projectSortProvider).value;

    return Container(
      width: 224,
      color: c.activityBar,
      child: Column(
        children: [
          // Traffic-light clearance on macOS (TitleBarStyle.hidden)
          if (PlatformUtils.isMacOS) const SizedBox(height: 28),
          SidebarHeader(onAdd: _addProject),
          Expanded(
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ),
              data: (projects) {
                if (projects.isEmpty) return SidebarEmptyState(onAdd: _addProject);

                final sorted = _sortedProjects(projects, sortState, ref);
                return ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final project = sorted[i];
                    final rawSessions = ref.watch(projectSessionsProvider(project.id)).value ?? [];
                    final sessions = _sortedSessions(rawSessions, sortState);
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.deepBackground)),
                      ),
                      child: ProjectTile(
                        project: project,
                        sessions: sessions,
                        isExpanded: expandedIds.contains(project.id),
                        activeSessionId: activeSessionId,
                        onToggleExpand: () => ref.read(expandedProjectIdsProvider.notifier).toggle(project.id),
                        onSessionTap: (sessionId) {
                          ref.read(activeSessionIdProvider.notifier).set(sessionId);
                          ref.read(activeProjectIdProvider.notifier).set(project.id);
                          context.go('/chat/$sessionId');
                        },
                        onRemove: (id) async {
                          final p = projects.firstWhere((p) => p.id == id);
                          await RemoveProjectDialog.show(context, p);
                        },
                        onRelocate: (id) async {
                          final p = projects.firstWhere((p) => p.id == id);
                          await RelocateProjectDialog.show(context, p);
                        },
                        onNewConversation: (id) => _newConversation(context, id),
                        onArchive: (sessionId) => unawaited(
                          _runSessionMutation(
                            () => ref.read(projectSidebarActionsProvider.notifier).archiveSession(sessionId),
                          ),
                        ),
                        onDelete: (sessionId) => unawaited(
                          _runSessionMutation(
                            () => ref.read(projectSidebarActionsProvider.notifier).deleteSession(sessionId),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SidebarFooter(),
        ],
      ),
    );
  }
}
