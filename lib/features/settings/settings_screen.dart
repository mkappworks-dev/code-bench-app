import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../archive/archive_screen.dart';
import '../coding_tools/coding_tools_screen.dart';
import '../coding_tools/notifiers/coding_tools_denylist_actions.dart';
import '../integrations/integrations_screen.dart';
import '../providers/providers_screen.dart';
import 'general_screen.dart';
import 'notifiers/general_prefs_notifier.dart';

enum _SettingsNav { general, providers, integrations, codingTools, archive }

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

  // Bumped whenever the user hits "Restore defaults" on Coding Tools so
  // CodingToolsScreen rebuilds with a fresh ValueKey.
  int _codingToolsVersion = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
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
              color: c.sidebarBackground,
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
      case _SettingsNav.integrations:
        return const IntegrationsScreen();
      case _SettingsNav.codingTools:
        return CodingToolsScreen(key: ValueKey('coding-tools-$_codingToolsVersion'));
      case _SettingsNav.archive:
        return const ArchiveScreen();
    }
  }

  Future<void> _restoreDefaults() async {
    switch (_activeNav) {
      case _SettingsNav.general:
        await _restoreGeneralDefaults();
      case _SettingsNav.codingTools:
        await _restoreCodingToolsDefaults();
      case _SettingsNav.providers:
      case _SettingsNav.integrations:
      case _SettingsNav.archive:
        return;
    }
  }

  Future<void> _restoreGeneralDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: AppIcons.settings,
        iconType: AppDialogIconType.teal,
        title: 'Restore General defaults?',
        content: Builder(
          builder: (context) {
            final c = AppColors.of(context);
            return Text(
              'Auto-commit, terminal app, and delete confirmation will be reset.\n\n'
              'API keys, GitHub sign-in, chat history, and projects are not affected.',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            );
          },
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.pop(ctx, false)),
          AppDialogAction.primary(label: 'Restore', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(generalPrefsProvider.notifier).restoreDefaults();
    if (!mounted) return;
    if (ref.read(generalPrefsProvider).hasError) {
      AppSnackBar.show(context, 'Could not restore defaults — please try again.', type: AppSnackBarType.error);
    } else {
      setState(() => _generalVersion++);
    }
  }

  Future<void> _restoreCodingToolsDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: AppIcons.settings,
        iconType: AppDialogIconType.teal,
        title: 'Restore coding-tools denylist defaults?',
        content: Builder(
          builder: (context) {
            final c = AppColors.of(context);
            return Text(
              'Your additions and any defaults you have opted out of will be cleared.',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            );
          },
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.pop(ctx, false)),
          AppDialogAction.primary(label: 'Restore', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(codingToolsDenylistActionsProvider.notifier).restoreAll();
    if (!mounted) return;
    if (ref.read(codingToolsDenylistActionsProvider).hasError) {
      AppSnackBar.show(context, 'Could not restore defaults — please try again.', type: AppSnackBarType.error);
    } else {
      setState(() => _codingToolsVersion++);
    }
  }
}

// ── Left nav ──────────────────────────────────────────────────────────────────

class _SettingsLeftNav extends StatefulWidget {
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
  State<_SettingsLeftNav> createState() => _SettingsLeftNavState();
}

class _SettingsLeftNavState extends State<_SettingsLeftNav> {
  bool _backHovered = false;
  bool _restoreHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final showRestore = widget.activeNav == _SettingsNav.general || widget.activeNav == _SettingsNav.codingTools;
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: c.activityBar,
        border: Border(right: BorderSide(color: c.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (PlatformUtils.isMacOS) const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              'Settings',
              style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          _NavItem(
            icon: AppIcons.settings,
            label: 'General',
            isActive: widget.activeNav == _SettingsNav.general,
            onTap: () => widget.onSelect(_SettingsNav.general),
          ),
          _NavItem(
            icon: AppIcons.chat,
            label: 'Providers',
            isActive: widget.activeNav == _SettingsNav.providers,
            onTap: () => widget.onSelect(_SettingsNav.providers),
          ),
          _NavItem(
            icon: AppIcons.gitPullRequest,
            label: 'Integrations',
            isActive: widget.activeNav == _SettingsNav.integrations,
            onTap: () => widget.onSelect(_SettingsNav.integrations),
          ),
          _NavItem(
            icon: AppIcons.terminal,
            label: 'Coding Tools',
            isActive: widget.activeNav == _SettingsNav.codingTools,
            onTap: () => widget.onSelect(_SettingsNav.codingTools),
          ),
          _NavItem(
            icon: AppIcons.archive,
            label: 'Archive',
            isActive: widget.activeNav == _SettingsNav.archive,
            onTap: () => widget.onSelect(_SettingsNav.archive),
          ),
          const Spacer(),
          if (showRestore)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _restoreHovered = true),
              onExit: (_) => setState(() => _restoreHovered = false),
              child: GestureDetector(
                onTap: widget.onRestoreDefaults,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _restoreHovered ? c.chipStroke : c.chipFill,
                    border: Border.all(color: c.chipStroke),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '↺ Restore defaults',
                        style: TextStyle(color: _restoreHovered ? c.textPrimary : c.mutedFg, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _backHovered = true),
              onExit: (_) => setState(() => _backHovered = false),
              child: GestureDetector(
                onTap: widget.onBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _backHovered ? c.chipStroke : c.chipFill,
                    border: Border.all(color: c.chipStroke),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.arrowLeft, size: 11, color: _backHovered ? c.textPrimary : c.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(color: _backHovered ? c.textPrimary : c.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
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
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: isActive ? const EdgeInsets.only(right: 6) : EdgeInsets.zero,
        padding: EdgeInsets.only(left: isActive ? 11 : 16, right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isActive ? c.accentTintMid : null,
          borderRadius: isActive ? const BorderRadius.horizontal(right: Radius.circular(6)) : null,
          border: isActive ? Border(left: BorderSide(color: c.accent, width: 3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? c.accent : c.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? c.textPrimary : c.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
