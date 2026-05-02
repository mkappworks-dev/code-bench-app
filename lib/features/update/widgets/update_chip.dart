// lib/features/update/widgets/update_chip.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../notifiers/update_notifier.dart';
import '../notifiers/update_state.dart';
import 'update_dialog.dart';

class UpdateChip extends ConsumerStatefulWidget {
  const UpdateChip({super.key});

  @override
  ConsumerState<UpdateChip> createState() => _UpdateChipState();
}

class _UpdateChipState extends ConsumerState<UpdateChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateProvider);
    final (info, label, showChevron) = switch (updateState) {
      UpdateStateAvailable(:final info) => (info, 'v${info.version} available', true),
      UpdateStateDownloading(:final info, :final progress) => (info, 'Downloading ${(progress * 100).round()}%', false),
      UpdateStateInstalling(:final info) => (info, 'Installing…', false),
      _ => (null, null, false),
    };
    if (info == null) return const SizedBox.shrink();

    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => UpdateDialog.show(context, info),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: _hovered ? c.accentTintMid : c.accentTintLight,
              border: Border.all(color: c.accentBorderTeal),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(AppIcons.update, size: 12, color: c.accentLight),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label!,
                    style: TextStyle(color: c.accentLight, fontSize: 10.5, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showChevron) Icon(AppIcons.chevronRight, size: 10, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
