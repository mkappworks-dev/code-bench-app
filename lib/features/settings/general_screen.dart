import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/utils/instant_menu.dart';
import 'notifiers/general_prefs_notifier.dart';
import 'notifiers/settings_actions.dart';
import 'widgets/inline_text_field.dart';
import 'widgets/section_label.dart';
import 'widgets/settings_group.dart';

class GeneralScreen extends ConsumerStatefulWidget {
  const GeneralScreen({super.key});

  @override
  ConsumerState<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends ConsumerState<GeneralScreen> {
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
    final s = await ref.read(generalPrefsProvider.future);
    if (!mounted) return;
    setState(() {
      _autoCommit = s.autoCommit;
      _deleteConfirmation = s.deleteConfirmation;
      _terminalAppController.text = s.terminalApp;
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
      AppSnackBar.show(
        context,
        'All data wiped. Restart the app to see the onboarding wizard.',
        type: AppSnackBarType.success,
      );
    } else {
      AppSnackBar.show(
        context,
        'Wipe partially failed: ${failures.join(', ')}. Check logs.',
        type: AppSnackBarType.error,
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
                trailing: Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _deleteConfirmation,
                    onChanged: (v) async {
                      await ref.read(generalPrefsProvider.notifier).setDeleteConfirmation(v);
                      setState(() => _deleteConfirmation = v);
                    },
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return Colors.white;
                      return const Color(0x40FFFFFF); // rgba(255,255,255,0.25)
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return ThemeConstants.accent;
                      return const Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
                    }),
                    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return Colors.transparent;
                      return const Color(0x17FFFFFF); // rgba(255,255,255,0.09)
                    }),
                  ),
                ),
              ),
              SettingsRow(
                label: 'Auto-commit',
                description: 'Skip commit dialog; commit immediately with AI-generated message',
                trailing: Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _autoCommit,
                    onChanged: (v) async {
                      await ref.read(generalPrefsProvider.notifier).setAutoCommit(v);
                      setState(() => _autoCommit = v);
                    },
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return Colors.white;
                      return const Color(0x40FFFFFF);
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return ThemeConstants.accent;
                      return const Color(0x0DFFFFFF);
                    }),
                    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return Colors.transparent;
                      return const Color(0x17FFFFFF);
                    }),
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
          const Divider(height: 36, thickness: 1, color: ThemeConstants.borderColor),
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
            const Divider(height: 36, thickness: 1, color: ThemeConstants.borderColor),
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
                          AppSnackBar.show(
                            ctx,
                            'Wizard will replay on next launch',
                            type: AppSnackBarType.info,
                            duration: const Duration(seconds: 2),
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

// ── Dropdown — only used within General settings ──────────────────────────────

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
        side: const BorderSide(color: ThemeConstants.faintFg),
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
          color: ThemeConstants.chipSurface,
          border: Border.all(color: ThemeConstants.chipBorder),
          borderRadius: BorderRadius.circular(6),
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
