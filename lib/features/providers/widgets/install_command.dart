import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Inline shell-command pill with a leading `$` prompt and a copy button.
/// Used in CLI transport cards when the binary is not detected, so the user
/// can copy the install command in one click without reaching for the
/// terminal.
class InstallCommand extends StatelessWidget {
  const InstallCommand({super.key, required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: c.inputBackground,
              border: Border.all(color: c.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  r'$',
                  style: TextStyle(color: c.textSecondary, fontFamily: ThemeConstants.editorFontFamily, fontSize: 11),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    command,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textPrimary, fontFamily: ThemeConstants.editorFontFamily, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _CopyButton(text: command),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _hovered = false;

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.text));
      if (!mounted) return;
      AppSnackBar.show(context, 'Copied to clipboard', type: AppSnackBarType.success);
    } catch (e) {
      // Clipboard.setData is one of the two widget-layer APIs the arch rule
      // permits a try/catch around (the other is launchUrl). Surface the
      // failure as a snackbar; the install command stays visible and the
      // user can still copy by selection.
      dLog('[InstallCommand] copy failed: $e');
      if (!mounted) return;
      AppSnackBar.show(context, 'Copy failed — please copy manually', type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _copy,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 26,
          width: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: _hovered ? 0.22 : 0.12),
            border: Border.all(color: c.accent.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(AppIcons.copy, size: 12, color: c.accent),
        ),
      ),
    );
  }
}
