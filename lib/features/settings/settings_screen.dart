import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/widgets/app_dialog.dart';
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? ThemeConstants.background : ThemeConstants.lightBackground,
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
              color: dark ? ThemeConstants.sidebarBackground : ThemeConstants.lightSidebarBackground,
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
      builder: (ctx) => AppDialog(
        icon: AppIcons.settings,
        iconType: AppDialogIconType.teal,
        title: 'Restore General defaults?',
        content: const Text(
          'Auto-commit, terminal app, and delete confirmation will be reset.\n\n'
          'API keys, GitHub sign-in, chat history, and projects are not affected.',
          style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12),
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.pop(ctx, false)),
          AppDialogAction.primary(label: 'Restore', onPressed: () => Navigator.pop(ctx, true)),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = dark ? ThemeConstants.chipSurface : ThemeConstants.lightChipSurface;
    final chipBorderColor = dark ? ThemeConstants.chipBorder : ThemeConstants.lightChipBorder;
    final secondaryText = dark ? ThemeConstants.textSecondary : ThemeConstants.lightChipText;
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: dark ? ThemeConstants.activityBar : ThemeConstants.lightActivityBar,
        border: Border(right: BorderSide(color: dark ? ThemeConstants.borderColor : ThemeConstants.lightBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (PlatformUtils.isMacOS) const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              'Settings',
              style: TextStyle(
                color: dark ? ThemeConstants.textPrimary : ThemeConstants.lightText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '↺ Restore defaults',
                style: TextStyle(color: dark ? ThemeConstants.mutedFg : ThemeConstants.lightTextMuted, fontSize: 11),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: chipColor,
                  border: Border.all(color: chipBorderColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.arrowLeft, size: 11, color: secondaryText),
                    const SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: secondaryText, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = dark ? ThemeConstants.textSecondary : ThemeConstants.lightTextSecondary;
    final activeTextColor = dark ? ThemeConstants.textPrimary : ThemeConstants.lightText;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: isActive ? const EdgeInsets.only(right: 6) : EdgeInsets.zero,
        padding: EdgeInsets.only(left: isActive ? 11 : 16, right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x124EC9B0) : null,
          borderRadius: isActive ? const BorderRadius.horizontal(right: Radius.circular(6)) : null,
          border: isActive ? const Border(left: BorderSide(color: ThemeConstants.accent, width: 3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? ThemeConstants.accent : inactiveColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? activeTextColor : inactiveColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
