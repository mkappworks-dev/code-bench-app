import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/instant_menu.dart';
import '../../core/utils/snackbar_helper.dart';
import '../notifiers/ide_launch_actions.dart';
import 'action_button.dart';
import 'project_guard.dart';

/// Dropdown that opens the project in VS Code, Cursor, Finder, or Terminal.
class CodeDropdown extends ConsumerStatefulWidget {
  const CodeDropdown({super.key, required this.projectId, required this.projectPath});

  final String projectId;
  final String projectPath;

  @override
  ConsumerState<CodeDropdown> createState() => _CodeDropdownState();
}

class _CodeDropdownState extends ConsumerState<CodeDropdown> {
  @override
  void initState() {
    super.initState();
    // Listen for IDE launch errors and surface them as snack-bars.
    // Error is already inside IdeLaunchFailure at this point — the notifier
    // did the exception-to-failure mapping.
    ref.listenManual(ideLaunchActionsProvider, (prev, next) {
      if (next is! AsyncError) return;
      final failure = next.error;
      if (failure is! IdeLaunchFailure) return;
      if (!mounted) return;
      switch (failure) {
        case IdeLaunchFailed(:final message):
          showErrorSnackBar(context, message);
        case IdeLaunchUnknownError():
          showErrorSnackBar(context, 'Could not open the editor — unexpected error.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            switch (action) {
              case 'vscode':
                if (!ensureProjectAvailable(btnContext, ref, widget.projectId, widget.projectPath)) return;
                unawaited(launcher.openVsCode(widget.projectPath));
              case 'cursor':
                if (!ensureProjectAvailable(btnContext, ref, widget.projectId, widget.projectPath)) return;
                unawaited(launcher.openCursor(widget.projectPath));
              case 'finder':
                unawaited(launcher.openInFinder(widget.projectPath));
              case 'terminal':
                unawaited(launcher.openInTerminal(widget.projectPath));
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
