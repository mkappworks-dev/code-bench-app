import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';

class SideNavRail extends StatelessWidget {
  const SideNavRail({super.key, required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      color: ThemeConstants.activityBar,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            route: '/dashboard',
            currentLocation: currentLocation,
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Chat',
            route: '/chat/new',
            currentLocation: currentLocation,
            matchPrefix: '/chat',
          ),
          _NavItem(
            icon: Icons.code_outlined,
            activeIcon: Icons.code,
            label: 'Editor',
            route: '/editor',
            currentLocation: currentLocation,
          ),
          _NavItem(
            icon: Icons.source_outlined,
            activeIcon: Icons.source,
            label: 'GitHub',
            route: '/github',
            currentLocation: currentLocation,
          ),
          const Spacer(),
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
            route: '/settings',
            currentLocation: currentLocation,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.currentLocation,
    this.matchPrefix,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String currentLocation;
  final String? matchPrefix;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  bool get _isActive {
    final prefix = widget.matchPrefix ?? widget.route;
    return widget.currentLocation.startsWith(prefix);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.route),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: _isActive
                  ? const Border(
                      left: BorderSide(color: ThemeConstants.accent, width: 2),
                    )
                  : null,
            ),
            child: Icon(
              _isActive ? widget.activeIcon : widget.icon,
              size: 20,
              color: _isActive
                  ? ThemeConstants.textPrimary
                  : (_hovered
                        ? ThemeConstants.textPrimary
                        : ThemeConstants.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
