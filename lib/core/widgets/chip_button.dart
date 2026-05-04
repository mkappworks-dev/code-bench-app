// lib/core/widgets/chip_button.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ChipButtonSize {
  /// Compact pill used in settings rows and the project sidebar.
  small,

  /// Material-button-sized pill — matches the height of [FilledButton]
  /// so it can sit alongside a primary action without a height mismatch.
  medium,
}

/// Compact pill-shaped button used across settings panels and the
/// onboarding wizard: rounded border, hover-tinted fill, optional
/// leading icon, optional destructive (red) variant.
class ChipButton extends StatefulWidget {
  const ChipButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.size = ChipButtonSize.small,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isDestructive;
  final ChipButtonSize size;

  @override
  State<ChipButton> createState() => _ChipButtonState();
}

class _ChipButtonState extends State<ChipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = widget.isDestructive ? c.error : c.textPrimary;
    final borderColor = widget.isDestructive ? c.error.withValues(alpha: 0.5) : c.chipStroke;
    final bgRest = widget.isDestructive ? c.errorTintBg : c.chipFill;
    final bgHover = widget.isDestructive ? c.error.withValues(alpha: 0.2) : c.chipStroke;

    final (padding, fontSize, iconSize, gap) = switch (widget.size) {
      ChipButtonSize.small => (const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 11.0, 11.0, 6.0),
      ChipButtonSize.medium => (const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 12.0, 14.0, 8.0),
    };

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: padding,
          decoration: BoxDecoration(
            color: _hovered ? bgHover : bgRest,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(widget.size == ChipButtonSize.medium ? 6 : 5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: iconSize, color: fg), SizedBox(width: gap)],
              Text(
                widget.label,
                style: TextStyle(color: fg, fontSize: fontSize),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
