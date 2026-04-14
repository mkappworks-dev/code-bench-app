import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/platform_utils.dart';
import 'archive_screen.dart';
import 'general_screen.dart';
import 'notifiers/general_prefs_notifier.dart';
import 'providers_screen.dart';

enum _SettingsNav { general, providers, archive }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _SettingsNav _activeNav = _SettingsNav.general;

  // Bumped whenever the user hits "Restore defaults" so GeneralScreen
  // rebuilds with a fresh ValueKey and re-runs its initState → _load()
  // against the new pref values.
  int _generalVersion = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsLeftNav(
            activeNav: _activeNav,
            onSelect: (nav) => setState(() => _activeNav = nav),
            onBack: () => context.go('/chat'),
            onRestoreDefaults: _restoreDefaults,
          ),
          Expanded(
            child: Container(
              color: ThemeConstants.sidebarBackground,
              padding: EdgeInsets.only(left: 24, right: 24, top: PlatformUtils.isMacOS ? 48 : 20),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeNav) {
      case _SettingsNav.general:
        return GeneralScreen(key: ValueKey('general-$_generalVersion'));
      case _SettingsNav.providers:
        return const ProvidersScreen();
      case _SettingsNav.archive:
        return const ArchiveScreen();
    }
  }

  Future<void> _restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.panelBackground,
        title: const Text(
          'Restore General defaults?',
          style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14),
        ),
        content: const Text(
          'Auto-commit, terminal app, and delete confirmation will be reset.\n\n'
          'API keys, GitHub sign-in, chat history, and projects are not affected.',
          style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(generalPrefsProvider.notifier).restoreDefaults();
    if (mounted) setState(() => _generalVersion++);
  }
}

// ── Left nav ──────────────────────────────────────────────────────────────────

class _SettingsLeftNav extends StatelessWidget {
  const _SettingsLeftNav({
    required this.activeNav,
    required this.onSelect,
    required this.onBack,
    required this.onRestoreDefaults,
  });

  final _SettingsNav activeNav;
  final ValueChanged<_SettingsNav> onSelect;
  final VoidCallback onBack;
  final VoidCallback onRestoreDefaults;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: ThemeConstants.activityBar,
        border: Border(right: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (PlatformUtils.isMacOS) const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              'Settings',
              style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          _NavItem(
            icon: AppIcons.settings,
            label: 'General',
            isActive: activeNav == _SettingsNav.general,
            onTap: () => onSelect(_SettingsNav.general),
          ),
          _NavItem(
            icon: AppIcons.chat,
            label: 'Providers',
            isActive: activeNav == _SettingsNav.providers,
            onTap: () => onSelect(_SettingsNav.providers),
          ),
          _NavItem(
            icon: AppIcons.archive,
            label: 'Archive',
            isActive: activeNav == _SettingsNav.archive,
            onTap: () => onSelect(_SettingsNav.archive),
          ),
          const Spacer(),
          InkWell(
            onTap: onRestoreDefaults,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('↺ Restore defaults', style: TextStyle(color: ThemeConstants.mutedFg, fontSize: 11)),
            ),
          ),
          _NavItem(icon: AppIcons.arrowLeft, label: 'Back', isActive: false, onTap: onBack),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(left: isActive ? 14 : 16, right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isActive ? ThemeConstants.selectionBg : null,
          border: isActive ? const Border(left: BorderSide(color: ThemeConstants.accent, width: 2)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? ThemeConstants.accent : ThemeConstants.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
