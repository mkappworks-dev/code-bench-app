// lib/core/widgets/buttons.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ChipButtonSize {
  /// Compact pill used in settings rows and the project sidebar.
  small,

  /// Larger pill — pairs with [PrimaryButton] of the same size for
  /// the "Skip / Continue" pattern in the onboarding wizard.
  medium,
}

/// Hover-state shell shared by [ChipButton], [PrimaryButton], and
/// feature-specific chips. Callers supply all visual tokens; the shell
/// owns only the hover state machine, animated transitions, and layout.
class ChipButtonShell extends StatefulWidget {
  const ChipButtonShell({
    super.key,
    required this.label,
    required this.onPressed,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.gap,
    required this.radius,
    required this.restFill,
    required this.hoverFill,
    required this.foreground,
    this.hoverForeground,
    this.borderColor,
    this.hoverBorderColor,
    this.fontWeight,
    this.icon,
    this.loadingChild,
  });

  final String label;
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double gap;
  final double radius;
  final Color restFill;
  final Color hoverFill;
  final Color foreground;
  final Color? hoverForeground;
  final Color? borderColor;
  final Color? hoverBorderColor;
  final FontWeight? fontWeight;
  final IconData? icon;

  /// When non-null, replaces the label/icon row — used to show a spinner
  /// without changing the button's dimensions.
  final Widget? loadingChild;

  @override
  State<ChipButtonShell> createState() => _ChipButtonShellState();
}

class _ChipButtonShellState extends State<ChipButtonShell> {
  bool _hovered = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final active = _hovered && _enabled;
    final fg = active && widget.hoverForeground != null ? widget.hoverForeground! : widget.foreground;
    final effectiveBorder = active && widget.hoverBorderColor != null ? widget.hoverBorderColor! : widget.borderColor;

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (_enabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: active ? widget.hoverFill : widget.restFill,
            border: effectiveBorder != null ? Border.all(color: effectiveBorder) : null,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: widget.loadingChild ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: widget.iconSize, color: fg),
                    SizedBox(width: widget.gap),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(color: fg, fontSize: widget.fontSize, fontWeight: widget.fontWeight),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

/// Compact pill-shaped button used across settings panels and the
/// onboarding wizard: rounded border, hover-tinted fill, optional
/// leading icon, optional destructive (red) variant.
class ChipButton extends StatelessWidget {
  const ChipButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.size = ChipButtonSize.small,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isDestructive;
  final ChipButtonSize size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = isDestructive ? c.error : c.textPrimary;
    final borderColor = isDestructive ? c.error.withValues(alpha: 0.5) : c.chipStroke;
    final restFill = isDestructive ? c.errorTintBg : c.chipFill;
    final hoverFill = isDestructive ? c.error.withValues(alpha: 0.2) : c.chipStroke;
    final (padding, fontSize, iconSize, gap) = switch (size) {
      ChipButtonSize.small => (const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 11.0, 11.0, 6.0),
      ChipButtonSize.medium => (const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 12.0, 14.0, 8.0),
    };
    final radius = size == ChipButtonSize.medium ? 6.0 : 5.0;

    return ChipButtonShell(
      label: label,
      onPressed: onPressed,
      padding: padding,
      fontSize: fontSize,
      iconSize: iconSize,
      gap: gap,
      radius: radius,
      restFill: restFill,
      hoverFill: hoverFill,
      foreground: fg,
      borderColor: borderColor,
      icon: icon,
    );
  }
}

/// Filled pill-shaped button for primary actions ("Continue", "Add Project").
/// Pixel-identical layout to [ChipButton] of the same [size] — same
/// padding, font size, corner radius, and hover timing — just with an
/// accent fill and on-accent foreground instead of an outline.
///
/// Pass `onPressed: null` to disable; the button dims to 40% opacity
/// and the cursor reverts. Pass `loading: true` to swap the label for
/// a small spinner without changing the button's dimensions.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = ChipButtonSize.medium,
    this.color,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ChipButtonSize size;

  /// Fill color override. Defaults to [AppColors.accent]; the hover
  /// state then uses [AppColors.accentHover]. When [color] is set, the
  /// hover state is a 10% darkened blend of [color].
  final Color? color;

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final base = color ?? c.accent;
    final hover = color == null ? c.accentHover : Color.alphaBlend(Colors.black.withValues(alpha: 0.1), base);
    final disabled = onPressed == null;
    final (padding, fontSize, iconSize, gap) = switch (size) {
      ChipButtonSize.small => (const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 11.0, 11.0, 6.0),
      ChipButtonSize.medium => (const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 12.0, 14.0, 8.0),
    };
    final radius = size == ChipButtonSize.medium ? 6.0 : 5.0;
    final spinnerSize = size == ChipButtonSize.medium ? 14.0 : 11.0;

    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: ChipButtonShell(
        label: label,
        onPressed: onPressed,
        padding: padding,
        fontSize: fontSize,
        iconSize: iconSize,
        gap: gap,
        radius: radius,
        restFill: base,
        hoverFill: hover,
        foreground: c.onAccent,
        icon: icon,
        loadingChild: loading
            ? SizedBox(
                width: spinnerSize,
                height: spinnerSize,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.onAccent),
              )
            : null,
      ),
    );
  }
}
