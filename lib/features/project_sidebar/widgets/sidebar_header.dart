import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
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
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: ThemeConstants.faintFg),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = dark ? ThemeConstants.mutedFg : ThemeConstants.lightTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dark ? ThemeConstants.borderColor : ThemeConstants.lightBorder)),
      ),
      child: Row(
        children: [
          Text(
            'PROJECTS',
            style: TextStyle(
              color: labelColor,
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
                child: Icon(AppIcons.arrowUpDown, size: 13, color: labelColor),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(AppIcons.add, size: 13, color: labelColor),
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
