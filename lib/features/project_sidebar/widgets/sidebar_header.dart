import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/instant_menu.dart';
import '../notifiers/project_sidebar_notifier.dart';

/// Sidebar "PROJECTS" header row — sort icon and add-project icon.
///
/// Owns the sort-menu interaction; delegates the add-project flow
/// to [onAdd] (which needs `_adding` state from the parent).
class SidebarHeader extends ConsumerWidget {
  const SidebarHeader({super.key, required this.onAdd});

  final VoidCallback onAdd;

  void _showSortMenu(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final current = ref.read(projectSortProvider).value;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(color: c.faintFg),
      ),
      items: [
        _sortHeader('SORT PROJECTS', c),
        _sortItem('proj_lastMessage', 'Last user message', current?.projectSort == ProjectSortOrder.lastMessage, c),
        _sortItem('proj_createdAt', 'Created at', current?.projectSort == ProjectSortOrder.createdAt, c),
        _sortItem('proj_manual', 'Manual', current?.projectSort == ProjectSortOrder.manual, c),
        const PopupMenuDivider(),
        _sortHeader('SORT THREADS', c),
        _sortItem('thread_lastMessage', 'Last user message', current?.threadSort == ThreadSortOrder.lastMessage, c),
        _sortItem('thread_createdAt', 'Created at', current?.threadSort == ThreadSortOrder.createdAt, c),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderColor)),
      ),
      child: Row(
        children: [
          Text(
            'PROJECTS',
            style: TextStyle(
              color: c.mutedFg,
              fontSize: ThemeConstants.uiFontSizeLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Builder(
            builder: (ctx) => InkWell(
              onTap: () => _showSortMenu(ctx, ref),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(AppIcons.arrowUpDown, size: 13, color: c.mutedFg),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(AppIcons.add, size: 13, color: c.mutedFg),
            ),
          ),
        ],
      ),
    );
  }
}

PopupMenuItem<String> _sortHeader(String label, AppColors c) => PopupMenuItem<String>(
  enabled: false,
  height: 24,
  child: Text(
    label,
    style: TextStyle(
      color: c.mutedFg,
      fontSize: ThemeConstants.uiFontSizeLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ),
  ),
);

PopupMenuItem<String> _sortItem(String value, String label, bool selected, AppColors c) => PopupMenuItem<String>(
  value: value,
  height: 32,
  child: Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(color: selected ? c.textPrimary : c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
        ),
      ),
      if (selected) Icon(AppIcons.check, size: 11, color: c.accent),
    ],
  ),
);
