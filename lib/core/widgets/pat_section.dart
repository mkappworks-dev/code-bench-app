// lib/core/widgets/pat_section.dart
import 'package:flutter/material.dart';

import '../constants/theme_constants.dart';
import '../theme/app_colors.dart';
import 'app_text_field.dart';

class PatSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: controller,
                obscureText: true,
                labelText: 'Personal Access Token',
                suffixIcon: fieldSuffixIcon,
              ),
            ),
            const SizedBox(width: 8),
            actionButton,
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onOpenTokenPage,
          child: Text(
            'Create a token on GitHub →',
            style: TextStyle(
              color: c.accent,
              fontSize: ThemeConstants.uiFontSizeSmall,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
