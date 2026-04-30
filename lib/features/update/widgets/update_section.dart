// lib/features/update/widgets/update_section.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/update/models/update_state.dart';
import '../../general/widgets/settings_group.dart';
import '../../settings/widgets/section_label.dart';
import '../notifiers/update_notifier.dart';

class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastCheckedAsync = ref.watch(updateLastCheckedProvider);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Updates'),
        const SizedBox(height: 8),
        SettingsGroup(
          rows: [
            SettingsRow(
              label: 'Check for updates',
              description: description,
              trailing: _CheckButton(
                isChecking: isChecking,
                onTap: () => unawaited(ref.read(updateProvider.notifier).checkForUpdates()),
              ),
              isLast: true,
            ),
          ],
        ),
      ],
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
