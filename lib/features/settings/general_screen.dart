import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/utils/instant_menu.dart';
import 'notifiers/general_prefs_notifier.dart';
import 'notifiers/settings_actions.dart';
import '../../core/widgets/app_text_field.dart';
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
  ThemeMode _themeMode = ThemeMode.system;
  String _version = '';
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
      final results = await Future.wait([ref.read(generalPrefsProvider.future), PackageInfo.fromPlatform()]);
      final s = results[0] as dynamic;
      final info = results[1] as PackageInfo;
      if (!mounted) return;
      setState(() {
        _autoCommit = s.autoCommit;
        _deleteConfirmation = s.deleteConfirmation;
        _terminalAppController.text = s.terminalApp;
        _themeMode = s.themeMode;
        _version = info.version;
      });
    } catch (e) {
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
              '  • All projects\n\n'
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
                  builder: (ctx) => _AppDropdown<ThemeMode>(
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
          SectionLabel('About'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Version',
                description: 'Current app version',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: c.accentTintMid, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    _version.isEmpty ? '…' : _version,
                    style: TextStyle(color: c.accent, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ),
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
                          border: Border.all(color: c.deepBorder),
                          borderRadius: BorderRadius.circular(5),
                          color: c.inputSurface,
                        ),
                        child: Text(
                          'Replay',
                          style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
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
                        border: Border.all(color: c.error),
                        borderRadius: BorderRadius.circular(5),
                        color: c.inputSurface,
                      ),
                      child: Text(
                        'Wipe',
                        style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
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
    final c = AppColors.of(context);
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
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: c.faintFg),
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
                        color: item == value ? c.textPrimary : c.textSecondary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                      ),
                    ),
                  ),
                  if (item == value) Icon(AppIcons.check, size: 11, color: c.accent),
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.chipFill,
          border: Border.all(color: c.chipStroke),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label(value),
              style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            const SizedBox(width: 4),
            Icon(AppIcons.chevronDown, size: 10, color: c.mutedFg),
          ],
        ),
      ),
    );
  }
}
