import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/instant_menu.dart';
import '../../../core/widgets/app_snack_bar.dart';

class ProjectContextMenu {
  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required String projectPath,
    required bool isGit,
    bool isMissing = false,
  }) async {
    final c = AppColors.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    return showInstantMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: c.faintFg),
      ),
      items: [
        if (!isMissing) ...[
          _buildItem('open_finder', 'Open in Finder', Icons.folder_open_outlined, c),
          _buildItem('copy_path', 'Copy path', Icons.copy_outlined, c),
          const PopupMenuDivider(),
          _buildItem('new_conversation', 'New conversation', Icons.add, c),
          const PopupMenuDivider(),
          _buildItem('archive_all', 'Archive all conversations', AppIcons.archive, c),
          _buildDangerItem('delete_all', 'Delete all conversations', c, icon: Icons.delete_sweep),
          const PopupMenuDivider(),
        ] else ...[
          _buildItem('copy_path', 'Copy path', Icons.copy_outlined, c),
          const PopupMenuDivider(),
          _buildItem('relocate', 'Relocate…', Icons.drive_file_move_outlined, c),
          const PopupMenuDivider(),
        ],
        _buildDangerItem('remove', 'Remove from Code Bench', c),
      ],
    );
  }

  static PopupMenuItem<String> _buildItem(String value, String label, IconData icon, AppColors c) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: c.textPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  static PopupMenuItem<String> _buildDangerItem(
    String value,
    String label,
    AppColors c, {
    IconData icon = Icons.close,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.error),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: c.error, fontSize: 11)),
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
    required Function(String) onArchiveAll,
    required Function(String) onDeleteAll,
    Function(String)? onRelocate,
  }) async {
    switch (action) {
      case 'open_finder':
        try {
          final launched = await launchUrl(Uri.file(projectPath), mode: LaunchMode.platformDefault);
          if (!launched && context.mounted) {
            AppSnackBar.show(context, 'Could not open in Finder.', type: AppSnackBarType.error);
          }
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.show(context, 'Could not open in Finder.', type: AppSnackBarType.error);
          }
        }
      case 'copy_path':
        try {
          await Clipboard.setData(ClipboardData(text: projectPath));
          if (context.mounted) {
            AppSnackBar.show(context, 'Path copied.', type: AppSnackBarType.success);
          }
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.show(context, 'Could not copy path.', type: AppSnackBarType.error);
          }
        }
      case 'new_conversation':
        onNewConversation(projectId);
      case 'relocate':
        onRelocate?.call(projectId);
      case 'archive_all':
        onArchiveAll(projectId);
      case 'delete_all':
        onDeleteAll(projectId);
      case 'remove':
        onRemove(projectId);
    }
  }
}
