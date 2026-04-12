import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/utils/instant_menu.dart';
import '../../core/utils/platform_utils.dart';
import 'archive_screen.dart';
import 'notifiers/settings_notifier.dart';
import 'providers_screen.dart';
import 'settings_widgets.dart';

enum _SettingsNav { general, providers, archive }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _SettingsNav _activeNav = _SettingsNav.general;

  // Bumped whenever the user hits "Restore defaults" so the General section
  // rebuilds with a fresh ValueKey and re-runs `_load()` against the new
  // pref values. Without this, `_GeneralSectionState` holds stale in-memory
  // values (its initState → _load only runs once) and the user has to
  // navigate away and back to see the reset reflected.
  int _generalVersion = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Row(
        children: [
          // Left nav (200px) — extends to y=0, macOS spacer inside nav
          _SettingsLeftNav(
            activeNav: _activeNav,
            onSelect: (nav) => setState(() => _activeNav = nav),
            onBack: () => context.go('/chat'),
            onRestoreDefaults: _restoreDefaults,
          ),
          // Content area — top: 48 (macOS) / 20 keeps label aligned with "Settings" title
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
        return _GeneralSection(key: ValueKey('general-$_generalVersion'));
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
    // Bump the version so _GeneralSection rebuilds with a fresh ValueKey and
    // re-runs its initState → _load(). A bare `setState(() {})` is not
    // enough: Flutter reuses _GeneralSectionState across props-only rebuilds,
    // so the in-memory _autoCommit / _deleteConfirmation / text field stay
    // stale until the user navigates away and back.
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
          // Traffic-light clearance — nav background fills to y=0
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ThemeConstants.inputSurface : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? ThemeConstants.textPrimary : ThemeConstants.textSecondary),
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

// ── General section ───────────────────────────────────────────────────────────

class _GeneralSection extends ConsumerStatefulWidget {
  const _GeneralSection({super.key});

  @override
  ConsumerState<_GeneralSection> createState() => _GeneralSectionState();
}

class _GeneralSectionState extends ConsumerState<_GeneralSection> {
  bool _autoCommit = false;
  bool _deleteConfirmation = true;
  final _terminalAppController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _terminalAppController.addListener(
      () => ref.read(generalPrefsProvider.notifier).setTerminalApp(_terminalAppController.text),
    );
  }

  Future<void> _load() async {
    final state = await ref.read(generalPrefsProvider.future);
    if (!mounted) return;
    setState(() {
      _autoCommit = state.autoCommit;
      _deleteConfirmation = state.deleteConfirmation;
      _terminalAppController.text = state.terminalApp;
    });
  }

  @override
  void dispose() {
    _terminalAppController.dispose();
    super.dispose();
  }

  Future<void> _confirmWipeAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: ThemeConstants.panelBackground,
        title: const Text('Wipe all data?', style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14)),
        content: const Text(
          'This will permanently delete:\n'
          '  • All API keys\n'
          '  • GitHub sign-in\n'
          '  • All chat sessions and messages\n'
          '  • All projects\n\n'
          'You will see the onboarding wizard on next launch. This cannot be undone.',
          style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Wipe everything', style: TextStyle(color: ThemeConstants.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _wipeAllData();
  }

  Future<void> _wipeAllData() async {
    final failures = await ref.read(settingsActionsProvider.notifier).wipeAllData();
    if (!mounted) return;
    if (failures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data wiped. Restart the app to see the onboarding wizard.'),
          backgroundColor: ThemeConstants.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wipe partially failed: ${failures.join(', ')}. Check logs.'),
          backgroundColor: ThemeConstants.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('General'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Theme',
                description: 'How Code Bench looks',
                trailing: Builder(
                  builder: (ctx) => _AppDropdown<String>(
                    value: 'Dark',
                    items: const ['Dark', 'Light', 'System'],
                    label: (s) => s,
                    onChanged: (_) {},
                    context: ctx,
                  ),
                ),
              ),
              SettingsRow(
                label: 'Delete confirmation',
                description: 'Ask before deleting a session',
                trailing: Builder(
                  builder: (ctx) => _AppDropdown<bool>(
                    value: _deleteConfirmation,
                    items: const [true, false],
                    label: (v) => v ? 'Enabled' : 'Disabled',
                    onChanged: (v) async {
                      await ref.read(generalPrefsProvider.notifier).setDeleteConfirmation(v);
                      setState(() => _deleteConfirmation = v);
                    },
                    context: ctx,
                  ),
                ),
              ),
              SettingsRow(
                label: 'Auto-commit',
                description: 'Skip commit dialog; commit immediately with AI-generated message',
                trailing: Builder(
                  builder: (ctx) => _AppDropdown<bool>(
                    value: _autoCommit,
                    items: const [true, false],
                    label: (v) => v ? 'Enabled' : 'Disabled',
                    onChanged: (v) async {
                      await ref.read(generalPrefsProvider.notifier).setAutoCommit(v);
                      setState(() => _autoCommit = v);
                    },
                    context: ctx,
                  ),
                ),
              ),
              SettingsRow(
                label: 'Terminal app',
                description: 'App to open when "Open Terminal" is tapped',
                trailing: SizedBox(width: 140, child: InlineTextField(controller: _terminalAppController)),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionLabel('About'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Version',
                description: 'Current app version',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ThemeConstants.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Up to Date', style: TextStyle(color: ThemeConstants.success, fontSize: 10)),
                ),
                isLast: true,
              ),
            ],
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            SectionLabel('Debug'),
            const SizedBox(height: 8),
            SettingsGroup(
              rows: [
                SettingsRow(
                  label: 'Replay onboarding wizard',
                  description:
                      'Show the 3-step wizard on next launch. Does not clear API keys, GitHub sign-in, or projects.',
                  trailing: Builder(
                    builder: (ctx) => InkWell(
                      onTap: () async {
                        await ref.read(settingsActionsProvider.notifier).replayOnboarding();
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Wizard will replay on next launch'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: ThemeConstants.deepBorder),
                          borderRadius: BorderRadius.circular(5),
                          color: ThemeConstants.inputSurface,
                        ),
                        child: const Text(
                          'Replay',
                          style: TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
                        ),
                      ),
                    ),
                  ),
                ),
                SettingsRow(
                  label: 'Wipe all data',
                  description: 'Delete API keys, GitHub sign-in, chat history, and projects. Cannot be undone.',
                  trailing: InkWell(
                    onTap: _confirmWipeAllData,
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: ThemeConstants.error),
                        borderRadius: BorderRadius.circular(5),
                        color: ThemeConstants.inputSurface,
                      ),
                      child: const Text(
                        'Wipe',
                        style: TextStyle(color: ThemeConstants.error, fontSize: ThemeConstants.uiFontSizeSmall),
                      ),
                    ),
                  ),
                  isLast: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared dropdown ───────────────────────────────────────────────────────────

class _AppDropdown<T> extends StatelessWidget {
  const _AppDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    required this.context,
  });

  final T value;
  final List<T> items;
  final String Function(T) label;
  final void Function(T) onChanged;
  final BuildContext context;

  void _open() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    showInstantMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height + 4,
        overlay.size.width - origin.dx - box.size.width,
        0,
      ),
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      items: items
          .map(
            (item) => PopupMenuItem<T>(
              value: item,
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label(item),
                      style: TextStyle(
                        color: item == value ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                      ),
                    ),
                  ),
                  if (item == value) const Icon(AppIcons.check, size: 11, color: ThemeConstants.accent),
                ],
              ),
            ),
          )
          .toList(),
    ).then((picked) {
      if (picked != null) onChanged(picked);
    });
  }

  @override
  Widget build(BuildContext _) {
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: ThemeConstants.deepBorder),
          borderRadius: BorderRadius.circular(5),
          color: ThemeConstants.inputSurface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label(value),
              style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            const SizedBox(width: 4),
            const Icon(AppIcons.chevronDown, size: 10, color: ThemeConstants.mutedFg),
          ],
        ),
      ),
    );
  }
}
