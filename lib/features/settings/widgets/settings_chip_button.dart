import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

class SettingsChipButton extends StatefulWidget {
  const SettingsChipButton({super.key, required this.label, required this.onPressed, this.isDestructive = false});

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  State<SettingsChipButton> createState() => _SettingsChipButtonState();
}

class _SettingsChipButtonState extends State<SettingsChipButton> {
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
          child: Text(
            widget.label,
            style: TextStyle(color: fg, fontSize: ThemeConstants.uiFontSizeSmall),
          ),
        ),
      ),
    );
  }
}
