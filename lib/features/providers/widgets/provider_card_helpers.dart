// lib/features/providers/widgets/provider_card_helpers.dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

enum DotStatus { empty, unsaved, savedVerified, savedUnverified }

class InlineTestButton extends StatefulWidget {
  const InlineTestButton({
    super.key,
    required this.loading,
    required this.onPressed,
    this.testPassed = false,
    this.testFailed = false,
    this.disabled = false,
    this.passedLabel = '✓ Valid',
    this.failedLabel = '✗ Fail',
  });

  final bool loading;
  final VoidCallback onPressed;
  final bool testPassed;
  final bool testFailed;
  final bool disabled;
  final String passedLabel;
  final String failedLabel;

  @override
  State<InlineTestButton> createState() => _InlineTestButtonState();
}

class _InlineTestButtonState extends State<InlineTestButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (widget.loading) {
      return Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        constraints: const BoxConstraints(minWidth: 62),
        alignment: Alignment.center,
        child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent)),
      );
    }

    final Color fgColor;
    final Color bgColor;
    final Color borderColor;
    final String label;

    if (widget.testPassed) {
      fgColor = c.success;
      bgColor = c.success.withValues(alpha: _hovered ? 0.20 : 0.12);
      borderColor = c.success.withValues(alpha: 0.3);
      label = widget.passedLabel;
    } else if (widget.testFailed) {
      fgColor = c.error;
      bgColor = c.error.withValues(alpha: _hovered ? 0.18 : 0.10);
      borderColor = c.error.withValues(alpha: 0.35);
      label = widget.failedLabel;
    } else {
      fgColor = c.accent;
      bgColor = c.accent.withValues(alpha: _hovered ? 0.22 : 0.12);
      borderColor = c.accent.withValues(alpha: 0.35);
      label = 'Test';
    }

    final interactive = !widget.disabled;

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (interactive) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: interactive ? 1.0 : 0.4,
        child: GestureDetector(
          onTap: interactive ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            constraints: const BoxConstraints(minWidth: 62),
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
        ),
      ),
    );
  }
}

class InlineSaveButton extends StatefulWidget {
  const InlineSaveButton({super.key, required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  State<InlineSaveButton> createState() => _InlineSaveButtonState();
}

class _InlineSaveButtonState extends State<InlineSaveButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (widget.loading) {
      return SizedBox(
        width: 54,
        height: 26,
        child: Center(
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 54,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: _hovered ? c.accentHover : c.accent, borderRadius: BorderRadius.circular(5)),
          child: Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: ThemeConstants.uiFontSizeSmall,
              fontWeight: FontWeight.w500,
            ),
          ),
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
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered) ? c.surfaceHoverOverlay : null,
            ),
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

class InlineClearButton extends StatefulWidget {
  const InlineClearButton({super.key, required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  State<InlineClearButton> createState() => _InlineClearButtonState();
}

class _InlineClearButtonState extends State<InlineClearButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasLabel = widget.label != null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: hasLabel ? null : const BoxConstraints(minWidth: 28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? c.error.withValues(alpha: 0.08) : Colors.transparent,
            border: Border.all(color: c.error.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: hasLabel
              ? Text(
                  widget.label!,
                  style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
                )
              : Icon(AppIcons.close, size: 11, color: c.error),
        ),
      ),
    );
  }
}
