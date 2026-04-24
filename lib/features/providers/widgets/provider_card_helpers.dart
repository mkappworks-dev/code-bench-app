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
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: c.onAccent)),
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
            style: TextStyle(color: c.onAccent, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
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

class ActivePill extends StatelessWidget {
  const ActivePill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.18),
        border: Border.all(color: c.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Active',
        style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeLabel, fontWeight: FontWeight.w500),
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

/// Two-option radio selector used in [AnthropicProviderCard] to choose between
/// API Key and Claude Code CLI transports.
class TransportRadio extends StatelessWidget {
  const TransportRadio({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.selectedIndex,
    this.onChanged,
    this.rightDisabled = false,
    this.rightDisabledTooltip,
    this.loading = false,
  });

  final String leftLabel;
  final String rightLabel;

  /// 0 = left option selected, 1 = right option selected.
  final int selectedIndex;

  /// Null disables both options (e.g. while saving).
  final ValueChanged<int>? onChanged;

  /// Disables only the right option (e.g. CLI not installed).
  final bool rightDisabled;

  /// Tooltip shown on the right option when [rightDisabled] is true.
  final String? rightDisabledTooltip;

  /// When true, shows a small spinner on the currently selected option (e.g.
  /// while the transport switch is being persisted).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RadioOption(
          label: leftLabel,
          selected: selectedIndex == 0,
          loading: loading && selectedIndex == 0,
          disabled: onChanged == null,
          onTap: onChanged == null ? null : () => onChanged!(0),
        ),
        const SizedBox(width: 14),
        _MaybeTooltip(
          message: rightDisabled ? rightDisabledTooltip : null,
          child: _RadioOption(
            label: rightLabel,
            selected: selectedIndex == 1,
            loading: loading && selectedIndex == 1,
            disabled: onChanged == null || rightDisabled,
            onTap: (onChanged == null || rightDisabled) ? null : () => onChanged!(1),
          ),
        ),
      ],
    );
  }
}

class _RadioOption extends StatefulWidget {
  const _RadioOption({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.loading,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_RadioOption> createState() => _RadioOptionState();
}

class _RadioOptionState extends State<_RadioOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dotColor = widget.selected ? c.accent : (widget.disabled ? c.mutedFg : c.textSecondary);
    final labelColor = widget.selected ? c.textPrimary : (widget.disabled ? c.mutedFg : c.textSecondary);

    final Widget dot;
    if (widget.loading) {
      dot = SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.accent));
    } else {
      dot = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: dotColor, width: 1.5),
        ),
        child: widget.selected
            ? Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent),
                ),
              )
            : null,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (widget.onTap != null) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Opacity(
          opacity: widget.disabled ? 0.45 : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot,
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: (_hovered && widget.onTap != null) ? c.textPrimary : labelColor,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaybeTooltip extends StatelessWidget {
  const _MaybeTooltip({required this.child, this.message});

  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return child;
    return Tooltip(message: message!, child: child);
  }
}
