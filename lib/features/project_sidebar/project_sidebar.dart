import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
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
    // Watch activeProjectId to rebuild when it changes.
    ref.watch(activeProjectIdProvider);

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
