import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/utils/instant_menu.dart';

class ProjectContextMenu {
  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required String projectPath,
    required bool isGit,
    bool isMissing = false,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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

  static PopupMenuItem<String> _buildItem(String value, String label, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 14, color: ThemeConstants.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  static PopupMenuItem<String> _buildDangerItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: Row(
        children: [
          const Icon(Icons.close, size: 14, color: ThemeConstants.error),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: ThemeConstants.error, fontSize: 11)),
        ],
      ),
    );
  }

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
        final result = await Process.run('open', [projectPath]);
        if (result.exitCode != 0 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open in Finder.')));
        }
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
}
