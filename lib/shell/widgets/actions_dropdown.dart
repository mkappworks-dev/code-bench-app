import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/instant_menu.dart';
import '../../data/models/project.dart';
import '../../data/models/project_action.dart';
import '../../features/project_sidebar/notifiers/project_sidebar_actions.dart';
import '../notifiers/action_output_notifier.dart';
import 'action_button.dart';
import 'add_action_dialog.dart';
import 'project_guard.dart';

/// Dropdown button that lists project actions and exposes an "Add action"
/// entry. Shown in the top action bar when a project is active.
class ActionsDropdown extends ConsumerWidget {
  const ActionsDropdown({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Actions',
      child: Builder(
        builder: (btnContext) => ActionButton(
          icon: AppIcons.add,
          label: 'Actions',
          trailingCaret: true,
          onTap: () async {
            final value = await showInstantMenuAnchoredTo<Object>(
              buttonContext: btnContext,
              color: ThemeConstants.panelBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: const BorderSide(color: ThemeConstants.faintFg),
              ),
              items: [
                for (final action in project.actions)
                  PopupMenuItem<Object>(
                    value: action,
                    height: 32,
                    child: Row(
                      children: [
                        const Icon(AppIcons.run, size: 12, color: ThemeConstants.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          action.name,
                          style: const TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: ThemeConstants.uiFontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (project.actions.isNotEmpty) const PopupMenuDivider(),
                PopupMenuItem<Object>(
                  value: '__add__',
                  height: 32,
                  child: Row(
                    children: const [
                      Icon(AppIcons.add, size: 12, color: ThemeConstants.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'Add action',
                        style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                      ),
                    ],
                  ),
                ),
              ],
            );
            if (value == null) return;
            if (!btnContext.mounted) return;
            if (!ensureProjectAvailable(btnContext, ref, project.id, project.path)) return;
            if (value == '__add__') {
              if (!btnContext.mounted) return;
              final action = await showDialog<ProjectAction>(
                context: btnContext,
                builder: (_) => const AddActionDialog(),
              );
              if (action != null) {
                final newActions = [...project.actions, action];
                await ref.read(projectSidebarActionsProvider.notifier).updateProjectActions(project.id, newActions);
              }
            } else if (value is ProjectAction) {
              await ref.read(actionOutputProvider.notifier).run(value, project.path);
            }
          },
        ),
      ),
    );
  }
}
