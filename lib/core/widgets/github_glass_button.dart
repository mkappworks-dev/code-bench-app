// lib/core/widgets/github_glass_button.dart
import 'package:flutter/material.dart';

import '../constants/theme_constants.dart';
import '../theme/app_colors.dart';
import 'github_icon.dart';

class GitHubGlassButton extends StatelessWidget {
  const GitHubGlassButton({super.key, required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(6),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered) ? Colors.white.withValues(alpha: 0.07) : null,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.githubButtonGradientStart, c.githubButtonGradientEnd],
          ),
          border: Border.all(color: c.githubButtonBorder),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: c.githubButtonShadow, blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.githubButtonForeground),
              )
            else
              GitHubIcon(color: c.githubButtonForeground),
            const SizedBox(width: 8),
            Text(
              isLoading ? 'Connecting…' : 'Continue with GitHub',
              style: TextStyle(
                color: c.githubButtonForeground,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: c.deepBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or',
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
          ),
        ),
        Expanded(child: Divider(color: c.deepBorder, thickness: 1)),
      ],
    );
  }
}
