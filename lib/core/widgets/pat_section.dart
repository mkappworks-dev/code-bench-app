// lib/core/widgets/pat_section.dart
import 'package:flutter/material.dart';

import '../constants/theme_constants.dart';
import '../theme/app_colors.dart';
import 'app_text_field.dart';

class PatSection extends StatefulWidget {
  const PatSection({
    super.key,
    required this.controller,
    required this.actionButton,
    required this.onOpenTokenPage,
    this.fieldSuffixIcon,
  });

  final TextEditingController controller;
  final Widget actionButton;
  final VoidCallback onOpenTokenPage;
  final Widget? fieldSuffixIcon;

  @override
  State<PatSection> createState() => _PatSectionState();
}

class _PatSectionState extends State<PatSection> {
  bool _linkHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: widget.controller,
                obscureText: true,
                labelText: 'Personal Access Token',
                suffixIcon: widget.fieldSuffixIcon,
              ),
            ),
            const SizedBox(width: 8),
            widget.actionButton,
          ],
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _linkHovered = true),
          onExit: (_) => setState(() => _linkHovered = false),
          child: GestureDetector(
            onTap: widget.onOpenTokenPage,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _linkHovered ? 0.65 : 1.0,
              child: Text(
                'Create a token on GitHub →',
                style: TextStyle(
                  color: c.accent,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
