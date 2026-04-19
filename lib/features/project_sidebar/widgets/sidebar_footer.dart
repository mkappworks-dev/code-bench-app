import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';

/// Settings link pinned to the bottom of the project sidebar.
class SidebarFooter extends StatefulWidget {
  const SidebarFooter({super.key});

  @override
  State<SidebarFooter> createState() => _SidebarFooterState();
}

class _SidebarFooterState extends State<SidebarFooter> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => context.go('/settings'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _hovered ? c.chipStroke : c.chipFill,
                border: Border.all(color: c.chipStroke),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.settings, size: 11, color: _hovered ? c.textPrimary : c.textSecondary),
                  const SizedBox(width: 6),
                  Text('Settings', style: TextStyle(color: _hovered ? c.textPrimary : c.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
