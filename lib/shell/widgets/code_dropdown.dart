import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/instant_menu.dart';
import '../notifiers/ide_launch_actions.dart';
import 'action_button.dart';
import 'project_guard.dart';

/// Dropdown that opens the project in VS Code, Cursor, Finder, or Terminal.
class CodeDropdown extends ConsumerWidget {
  const CodeDropdown({super.key, required this.projectId, required this.projectPath});

  final String projectId;
  final String projectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Open in…',
      child: Builder(
        builder: (btnContext) => ActionButton(
          icon: AppIcons.code,
          label: 'VS Code',
          trailingCaret: true,
          onTap: () async {
            final action = await showInstantMenuAnchoredTo<String>(
              buttonContext: btnContext,
              color: ThemeConstants.panelBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: const BorderSide(color: ThemeConstants.faintFg),
              ),
              items: [
                _menuItem('vscode', AppIcons.code, 'VS Code'),
                _menuItem('cursor', AppIcons.aiMode, 'Cursor'),
                const PopupMenuDivider(),
                _menuItem('finder', AppIcons.folderOpen, 'Open in Finder'),
                _menuItem('terminal', AppIcons.terminal, 'Open in Terminal'),
              ],
            );
            if (action == null) return;
            if (!btnContext.mounted) return;
            final launcher = ref.read(ideLaunchActionsProvider.notifier);
            String? error;
            switch (action) {
              case 'vscode':
                if (!ensureProjectAvailable(btnContext, ref, projectId, projectPath)) return;
                error = await launcher.openVsCode(projectPath);
              case 'cursor':
                if (!ensureProjectAvailable(btnContext, ref, projectId, projectPath)) return;
                error = await launcher.openCursor(projectPath);
              case 'finder':
                error = await launcher.openInFinder(projectPath);
              case 'terminal':
                error = await launcher.openInTerminal(projectPath);
            }
            if (error != null && btnContext.mounted) {
              ScaffoldMessenger.of(
                btnContext,
              ).showSnackBar(SnackBar(content: Text(error), duration: const Duration(seconds: 4)));
            }
          },
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 12, color: ThemeConstants.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
