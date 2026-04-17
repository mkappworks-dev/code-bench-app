// lib/features/providers/widgets/provider_card_helpers.dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

enum DotStatus { empty, unsaved, savedVerified, savedUnverified }

class InlineTestButton extends StatelessWidget {
  const InlineTestButton({
    super.key,
    required this.loading,
    required this.onPressed,
    this.testPassed = false,
    this.passedLabel = '✓ Valid',
  });

  final bool loading;
  final VoidCallback onPressed;
  final bool testPassed;
  final String passedLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (loading) {
      return SizedBox(
        width: 62,
        height: 26,
        child: Center(
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent)),
        ),
      );
    }

    final fgColor = testPassed ? c.success : c.accent;
    final bgColor = testPassed ? c.success.withValues(alpha: 0.12) : c.accentTintMid;
    final borderColor = testPassed ? c.success.withValues(alpha: 0.3) : c.accent.withValues(alpha: 0.35);
    final label = testPassed ? passedLabel : 'Test';

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 62,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(color: fgColor, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class InlineSaveButton extends StatelessWidget {
  const InlineSaveButton({super.key, required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (loading) {
      return SizedBox(
        width: 54,
        height: 26,
        child: Center(
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        ),
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 54,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(5)),
        child: Text(
          'Save',
          style: TextStyle(color: Colors.white, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class InlineErrorRow extends StatelessWidget {
  const InlineErrorRow({super.key, required this.message, required this.onSaveAnyway});

  final String message;
  final VoidCallback onSaveAnyway;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.errorTintBg,
        border: Border.all(color: c.error.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ),
          InkWell(
            onTap: onSaveAnyway,
            borderRadius: BorderRadius.circular(2),
            child: Text(
              'Save anyway',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InlineClearButton extends StatelessWidget {
  const InlineClearButton({super.key, required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasLabel = label != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        constraints: hasLabel ? null : const BoxConstraints(minWidth: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: c.deepBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: hasLabel
            ? Text(
                label!,
                style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
              )
            : Icon(AppIcons.close, size: 11, color: c.error),
      ),
    );
  }
}
