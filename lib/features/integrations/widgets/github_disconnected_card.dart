// lib/features/integrations/widgets/github_disconnected_card.dart
import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/github_glass_button.dart';
import '../../../core/widgets/pat_section.dart';

class GithubDisconnectedCard extends StatefulWidget {
  const GithubDisconnectedCard({
    super.key,
    required this.isLoading,
    required this.patController,
    required this.onConnectOAuth,
    required this.onSignInWithPat,
    required this.onOpenTokenPage,
  });

  final bool isLoading;
  final TextEditingController patController;
  final VoidCallback onConnectOAuth;
  final VoidCallback onSignInWithPat;
  final VoidCallback onOpenTokenPage;

  @override
  State<GithubDisconnectedCard> createState() => _GithubDisconnectedCardState();
}

class _GithubDisconnectedCardState extends State<GithubDisconnectedCard> {
  bool _patConnectHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GitHubGlassButton(onPressed: widget.onConnectOAuth, isLoading: widget.isLoading),
          const SizedBox(height: 14),
          const OrDivider(),
          const SizedBox(height: 10),

          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.patController,
            builder: (context, value, _) {
              final hasPat = value.text.trim().isNotEmpty;
              final interactive = hasPat && !widget.isLoading;
              return PatSection(
                controller: widget.patController,
                onOpenTokenPage: widget.onOpenTokenPage,
                actionButton: MouseRegion(
                  cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
                  onEnter: (_) {
                    if (interactive) setState(() => _patConnectHovered = true);
                  },
                  onExit: (_) => setState(() => _patConnectHovered = false),
                  child: Opacity(
                    opacity: interactive ? 1.0 : 0.4,
                    child: GestureDetector(
                      onTap: interactive ? widget.onSignInWithPat : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _patConnectHovered ? c.accent.withValues(alpha: 0.2) : c.accentTintMid,
                          border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'Connect',
                          style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeSmall),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
