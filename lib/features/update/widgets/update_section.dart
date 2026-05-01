// lib/features/update/widgets/update_section.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../general/widgets/settings_group.dart';
import '../../settings/widgets/section_label.dart';
import '../notifiers/update_notifier.dart';
import '../notifiers/update_state.dart';

class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastCheckedAsync = ref.watch(updateLastCheckedProvider);
    final versionAsync = ref.watch(packageVersionProvider);
    final updateState = ref.watch(updateProvider);
    final isChecking = updateState is UpdateStateChecking;

    final description = lastCheckedAsync.when(
      data: (iso) {
        if (iso == null) return 'Never checked';
        final dt = DateTime.tryParse(iso);
        if (dt == null) return 'Never checked';
        final now = DateTime.now();
        final label = DateUtils.isSameDay(dt, now)
            ? 'Today at ${DateFormat.jm().format(dt)}'
            : DateFormat.MMMd().format(dt);
        return 'Last checked $label';
      },
      loading: () => 'Never checked',
      error: (_, _) => 'Never checked',
    );

    final version = switch (versionAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('About'),
        const SizedBox(height: 8),
        SettingsGroup(
          rows: [
            SettingsRow(
              label: 'Code Bench',
              description: description,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (version != null) ...[_VersionChip(version: version), const SizedBox(width: 6)],
                  _CheckButton(
                    isChecking: isChecking,
                    onTap: () => unawaited(ref.read(updateProvider.notifier).checkForUpdates()),
                  ),
                ],
              ),
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.version});
  final String version;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.accentTintMid,
        border: Border.all(color: c.accentBorderTeal),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'v$version',
        style: TextStyle(color: c.accentLight, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CheckButton extends StatefulWidget {
  const _CheckButton({required this.isChecking, required this.onTap});
  final bool isChecking;
  final VoidCallback onTap;

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: widget.isChecking ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isChecking ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered && !widget.isChecking ? c.chipStroke : c.chipFill,
            border: Border.all(color: c.chipStroke),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            widget.isChecking ? 'Checking…' : 'Check now',
            style: TextStyle(
              color: widget.isChecking ? c.textMuted : c.textPrimary,
              fontSize: ThemeConstants.uiFontSizeSmall,
            ),
          ),
        ),
      ),
    );
  }
}
