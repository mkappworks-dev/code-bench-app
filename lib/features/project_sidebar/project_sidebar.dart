import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/utils/instant_menu.dart';
import '../../core/utils/platform_utils.dart';
import '../../features/chat/chat_notifier.dart';
import '../../services/project/project_service.dart';
import '../../services/session/session_service.dart';
import 'project_sidebar_notifier.dart';
import 'widgets/project_tile.dart';
import 'widgets/relocate_project_dialog.dart';
import 'widgets/remove_project_dialog.dart';

class ProjectSidebar extends ConsumerStatefulWidget {
  const ProjectSidebar({super.key});

  @override
  ConsumerState<ProjectSidebar> createState() => _ProjectSidebarState();
}

class _ProjectSidebarState extends ConsumerState<ProjectSidebar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectServiceProvider).refreshProjectStatuses();
    });
  }

  Future<void> _addProject() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.getDirectoryPath(dialogTitle: 'Select project folder');
    if (result == null) return;

    try {
      final service = ref.read(projectServiceProvider);
      final project = await service.addExistingFolder(result);
      ref.read(activeProjectIdProvider.notifier).set(project.id);
      ref.read(expandedProjectIdsProvider.notifier).expand(project.id);
    } on DuplicateProjectPathException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _newConversation(BuildContext context, String projectId) async {
    final model = ref.read(selectedModelProvider);
    final service = ref.read(sessionServiceProvider);
    final sessionId = await service.createSession(model: model, projectId: projectId);
    ref.read(activeSessionIdProvider.notifier).set(sessionId);
    ref.read(activeProjectIdProvider.notifier).set(projectId);
    if (context.mounted) context.go('/chat/$sessionId');
  }

  void _showSortMenu(BuildContext context) {
    final sortAsync = ref.read(projectSortProvider);
    final current = sortAsync.value;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    // Sidebar header is at the top — open downward by using full overlay rect.
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromLTRB(
      origin.dx,
      origin.dy + box.size.height,
      overlay.size.width - origin.dx - box.size.width,
      0,
    );

    showInstantMenu<String>(
      context: context,
      position: position,
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      items: [
        _sortHeader('SORT PROJECTS'),
        _sortItem('proj_lastMessage', 'Last user message', current?.projectSort == ProjectSortOrder.lastMessage),
        _sortItem('proj_createdAt', 'Created at', current?.projectSort == ProjectSortOrder.createdAt),
        _sortItem('proj_manual', 'Manual', current?.projectSort == ProjectSortOrder.manual),
        const PopupMenuDivider(),
        _sortHeader('SORT THREADS'),
        _sortItem('thread_lastMessage', 'Last user message', current?.threadSort == ThreadSortOrder.lastMessage),
        _sortItem('thread_createdAt', 'Created at', current?.threadSort == ThreadSortOrder.createdAt),
      ],
    ).then((value) {
      if (value == null) return;
      final notifier = ref.read(projectSortProvider.notifier);
      switch (value) {
        case 'proj_lastMessage':
          notifier.setProjectSort(ProjectSortOrder.lastMessage);
        case 'proj_createdAt':
          notifier.setProjectSort(ProjectSortOrder.createdAt);
        case 'proj_manual':
          notifier.setProjectSort(ProjectSortOrder.manual);
        case 'thread_lastMessage':
          notifier.setThreadSort(ThreadSortOrder.lastMessage);
        case 'thread_createdAt':
          notifier.setThreadSort(ThreadSortOrder.createdAt);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final expandedIds = ref.watch(expandedProjectIdsProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);
    // Watch activeProjectId to rebuild when it changes.
    ref.watch(activeProjectIdProvider);

    return Container(
      width: 224,
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          // Traffic-light clearance on macOS (TitleBarStyle.hidden)
          if (PlatformUtils.isMacOS) const SizedBox(height: 28),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
            ),
            child: Row(
              children: [
                const Text(
                  'PROJECTS',
                  style: TextStyle(
                    color: ThemeConstants.mutedFg,
                    fontSize: ThemeConstants.uiFontSizeLabel,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                // Sort icon
                Builder(
                  builder: (ctx) => InkWell(
                    onTap: () => _showSortMenu(ctx),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(AppIcons.arrowUpDown, size: 13, color: ThemeConstants.mutedFg),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Add project icon
                InkWell(
                  onTap: () => _addProject(),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(AppIcons.add, size: 13, color: ThemeConstants.mutedFg),
                  ),
                ),
              ],
            ),
          ),
          // Project list
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
                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.folder, size: 32, color: ThemeConstants.faintFg),
                        const SizedBox(height: 12),
                        const Text(
                          'No projects yet',
                          style: TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSize),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _addProject(),
                          icon: Icon(AppIcons.add, size: 12),
                          label: const Text('Open folder', style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, i) {
                    final project = projects[i];
                    final sessionsAsync = ref.watch(projectSessionsProvider(project.id));
                    final sessions = sessionsAsync.value ?? [];

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
                        onArchive: (sessionId) => unawaited(ref.read(sessionServiceProvider).archiveSession(sessionId)),
                        onDelete: (sessionId) => unawaited(ref.read(sessionServiceProvider).deleteSession(sessionId)),
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
              child: Row(
                children: [
                  Icon(AppIcons.settings, size: 14, color: ThemeConstants.mutedFg),
                  const SizedBox(width: 7),
                  Text(
                    'Settings',
                    style: const TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSize),
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

PopupMenuItem<String> _sortHeader(String label) => PopupMenuItem<String>(
  enabled: false,
  height: 24,
  child: Text(
    label,
    style: const TextStyle(
      color: ThemeConstants.mutedFg,
      fontSize: ThemeConstants.uiFontSizeLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ),
  ),
);

PopupMenuItem<String> _sortItem(String value, String label, bool selected) => PopupMenuItem<String>(
  value: value,
  height: 32,
  child: Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
            fontSize: ThemeConstants.uiFontSizeSmall,
          ),
        ),
      ),
      if (selected) const Icon(AppIcons.check, size: 11, color: ThemeConstants.accent),
    ],
  ),
);
