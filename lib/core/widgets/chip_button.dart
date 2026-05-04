// lib/core/widgets/chip_button.dart
import 'package:flutter/material.dart';

import '../constants/theme_constants.dart';
import '../theme/app_colors.dart';

/// Compact pill-shaped button used across settings panels and the
/// onboarding wizard: rounded border, hover-tinted fill, optional
/// leading icon, optional destructive (red) variant.
class ChipButton extends StatefulWidget {
  const ChipButton({super.key, required this.label, required this.onPressed, this.icon, this.isDestructive = false});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isDestructive;

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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered ? bgHover : bgRest,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 11, color: fg), const SizedBox(width: 6)],
              Text(
                widget.label,
                style: TextStyle(color: fg, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
