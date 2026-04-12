import 'dart:async';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/utils/platform_utils.dart';
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
    // Swallow errors at the widget edge — the notifier already logs them.
    // The lifecycle trigger must not surface failures as uncaught exceptions.
    try {
      await ref.read(projectSidebarActionsProvider.notifier).refreshProjectStatuses();
    } catch (_) {}
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

  Future<void> _newConversation(BuildContext context, String projectId) async {
    final model = ref.read(selectedModelProvider);
    final sessionId = await ref
        .read(projectSidebarActionsProvider.notifier)
        .createSession(model: model, projectId: projectId);
    ref.read(activeSessionIdProvider.notifier).set(sessionId);
    ref.read(activeProjectIdProvider.notifier).set(projectId);
    if (context.mounted) context.go('/chat/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(projectSidebarActionsProvider, (_, next) {
      if (!_adding) return;
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      final message = switch (failure) {
        ProjectSidebarDuplicatePath() => 'This project is already added.',
        ProjectSidebarInvalidPath() => 'Invalid folder path.',
        ProjectSidebarStorageError() => 'Failed to save project — please try again.',
        ProjectSidebarUnknownError() => 'Failed to add project — please try again.',
        _ => 'Failed to add project — please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });

    final projectsAsync = ref.watch(projectsProvider);
    final expandedIds = ref.watch(expandedProjectIdsProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);
    // Watch activeProjectId to rebuild when it changes.
    ref.watch(activeProjectIdProvider);

    return Container(
      width: 224,
      color: ThemeConstants.activityBar,
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
                  style: const TextStyle(color: ThemeConstants.error, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ),
              data: (projects) {
                if (projects.isEmpty) return SidebarEmptyState(onAdd: _addProject);

                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, i) {
                    final project = projects[i];
                    final sessions = ref.watch(projectSessionsProvider(project.id)).value ?? [];
                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: ThemeConstants.deepBackground)),
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
                        onArchive: (sessionId) =>
                            unawaited(ref.read(projectSidebarActionsProvider.notifier).archiveSession(sessionId)),
                        onDelete: (sessionId) =>
                            unawaited(ref.read(projectSidebarActionsProvider.notifier).deleteSession(sessionId)),
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
