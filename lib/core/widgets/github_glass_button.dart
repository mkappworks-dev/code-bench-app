import 'package:flutter/material.dart';

import '../constants/theme_constants.dart';
import '../theme/app_colors.dart';
import 'github_icon.dart';

class GitHubGlassButton extends StatefulWidget {
  const GitHubGlassButton({super.key, required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<GitHubGlassButton> createState() => _GitHubGlassButtonState();
}

class _GitHubGlassButtonState extends State<GitHubGlassButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final interactive = !widget.isLoading && widget.onPressed != null;

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (interactive) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: interactive ? widget.onPressed : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
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
                    if (widget.isLoading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.githubButtonForeground),
                      )
                    else
                      GitHubIcon(color: c.githubButtonForeground),
                    const SizedBox(width: 8),
                    Text(
                      widget.isLoading ? 'Connecting…' : 'Connect with GitHub',
                      style: TextStyle(
                        color: c.githubButtonForeground,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: _hovered ? c.glassHoverOverlay : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
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
