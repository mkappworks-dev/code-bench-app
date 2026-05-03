import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_snack_bar.dart';
import 'notifiers/general_prefs_notifier.dart';
import '../settings/notifiers/settings_actions.dart';
import '../../core/widgets/app_text_field.dart';
import 'widgets/app_dropdown.dart';
import '../settings/widgets/section_label.dart';
import 'widgets/settings_group.dart';
import '../settings/widgets/settings_chip_button.dart';
import '../update/widgets/update_section.dart';

class GeneralScreen extends ConsumerStatefulWidget {
  const GeneralScreen({super.key});

  @override
  ConsumerState<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends ConsumerState<GeneralScreen> {
  bool? _autoCommit;
  bool? _deleteConfirmation;
  ThemeMode _themeMode = ThemeMode.system;
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
    try {
      final s = await ref.read(generalPrefsProvider.future);
      if (!mounted) return;
      setState(() {
        _autoCommit = s.autoCommit;
        _deleteConfirmation = s.deleteConfirmation;
        _terminalAppController.text = s.terminalApp;
        _themeMode = s.themeMode;
      });
    } catch (e, st) {
      dLog('[GeneralScreen] _load failed: $e\n$st');
      if (mounted) {
        AppSnackBar.show(context, 'Could not load settings — showing defaults.', type: AppSnackBarType.warning);
      }
    }
  }

  @override
  void dispose() {
    _terminalAppController.dispose();
    super.dispose();
  }

  Future<void> _restoreDefaults() async {
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
      await _load();
    }
  }

  Future<void> _confirmWipeAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AppDialog(
        icon: AppIcons.trash,
        iconType: AppDialogIconType.destructive,
        title: 'Wipe all data?',
        content: Builder(
          builder: (context) {
            final c = AppColors.of(context);
            return Text(
              'This will permanently delete:\n'
              '  • All API keys\n'
              '  • GitHub sign-in\n'
              '  • All chat sessions and messages\n'
              '  • All projects\n'
              '  • All MCP servers\n\n'
              'You will see the onboarding wizard on next launch. This cannot be undone.',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            );
          },
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.pop(dialogCtx, false)),
          AppDialogAction.destructive(label: 'Wipe everything', onPressed: () => Navigator.pop(dialogCtx, true)),
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
    ref.listen(generalPrefsProvider, (_, next) {
      if (next is! AsyncError || !mounted) return;
      AppSnackBar.show(context, 'Could not save setting — please try again.', type: AppSnackBarType.error);
    });
    ref.listen(settingsActionsProvider, (_, next) {
      if (next is! AsyncError || !mounted) return;
      AppSnackBar.show(context, 'Failed to reset — please try again.', type: AppSnackBarType.error);
    });
    final c = AppColors.of(context);
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
                  builder: (ctx) => AppDropdown<ThemeMode>(
                    value: _themeMode,
                    items: const [ThemeMode.system, ThemeMode.dark, ThemeMode.light],
                    label: (m) => switch (m) {
                      ThemeMode.system => 'System',
                      ThemeMode.dark => 'Dark',
                      ThemeMode.light => 'Light',
                    },
                    onChanged: (mode) async {
                      await ref.read(generalPrefsProvider.notifier).setThemeMode(mode);
                      setState(() => _themeMode = mode);
                    },
                    context: ctx,
                  ),
                ),
              ),
              SettingsRow(
                label: 'Delete confirmation',
                description: 'Ask before deleting a session',
                trailing: _deleteConfirmation == null
                    ? const SizedBox()
                    : Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: _deleteConfirmation!,
                          onChanged: (v) async {
                            await ref.read(generalPrefsProvider.notifier).setDeleteConfirmation(v);
                            setState(() => _deleteConfirmation = v);
                          },
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return Colors.white;
                            return c.sendDisabledIconColor;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return c.accent;
                            return c.sendDisabledFill;
                          }),
                          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return Colors.transparent;
                            return c.sendDisabledStroke;
                          }),
                        ),
                      ),
              ),
              SettingsRow(
                label: 'Auto-commit',
                description: 'Skip commit dialog; commit immediately with AI-generated message',
                trailing: _autoCommit == null
                    ? const SizedBox()
                    : Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: _autoCommit!,
                          onChanged: (v) async {
                            await ref.read(generalPrefsProvider.notifier).setAutoCommit(v);
                            setState(() => _autoCommit = v);
                          },
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return Colors.white;
                            return c.sendDisabledIconColor;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return c.accent;
                            return c.sendDisabledFill;
                          }),
                          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return Colors.transparent;
                            return c.sendDisabledStroke;
                          }),
                        ),
                      ),
              ),
              SettingsRow(
                label: 'Terminal app',
                description: 'App to open when "Open Terminal" is tapped',
                trailing: SizedBox(
                  width: 140,
                  child: AppTextField(controller: _terminalAppController, fontFamily: ThemeConstants.editorFontFamily),
                ),
                isLast: true,
              ),
            ],
          ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          const UpdateSection(),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Reset'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Restore defaults',
                description: 'Reset auto-commit, terminal app, and delete confirmation to their defaults.',
                trailing: SettingsChipButton(label: 'Restore', onPressed: _restoreDefaults),
              ),
              SettingsRow(
                label: 'Wipe all data',
                description:
                    'Delete API keys, GitHub sign-in, chat history, projects, and MCP servers. Cannot be undone.',
                trailing: SettingsChipButton(label: 'Wipe', onPressed: _confirmWipeAllData, isDestructive: true),
                isLast: true,
              ),
            ],
          ),
          if (kDebugMode) ...[
            Divider(height: 36, thickness: 1, color: c.borderColor),
            SectionLabel('Debug'),
            const SizedBox(height: 8),
            SettingsGroup(
              rows: [
                SettingsRow(
                  label: 'Replay onboarding wizard',
                  description:
                      'Show the 3-step wizard on next launch. Does not clear API keys, GitHub sign-in, or projects.',
                  trailing: Builder(
                    builder: (ctx) => SettingsChipButton(
                      label: 'Replay',
                      onPressed: () async {
                        await ref.read(settingsActionsProvider.notifier).replayOnboarding();
                        if (!ctx.mounted) return;
                        if (!ref.read(settingsActionsProvider).hasError) {
                          AppSnackBar.show(
                            ctx,
                            'Wizard will replay on next launch',
                            type: AppSnackBarType.info,
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
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
