// lib/features/integrations/widgets/github_disconnected_card.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';

class GithubDisconnectedCard extends StatefulWidget {
  const GithubDisconnectedCard({
    super.key,
    required this.isLoading,
    required this.showPat,
    required this.patController,
    required this.onConnectOAuth,
    required this.onTogglePat,
    required this.onSignInWithPat,
    required this.onOpenTokenPage,
  });

  final bool isLoading;
  final bool showPat;
  final TextEditingController patController;
  final VoidCallback onConnectOAuth;
  final VoidCallback onTogglePat;
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
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: c.githubBrandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: widget.isLoading ? null : widget.onConnectOAuth,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const GitHubIcon(),
            label: Text(
              widget.isLoading ? 'Connecting…' : 'Continue with GitHub',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onTogglePat,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Use a Personal Access Token instead',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(widget.showPat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 14, color: c.accent),
              ],
            ),
          ),
          if (widget.showPat) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: widget.patController,
                    obscureText: true,
                    labelText: 'Personal Access Token',
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _patConnectHovered = true),
                  onExit: (_) => setState(() => _patConnectHovered = false),
                  child: GestureDetector(
                    onTap: widget.isLoading ? null : widget.onSignInWithPat,
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
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onOpenTokenPage,
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
        ],
      ),
    );
  }
}

class GitHubIcon extends StatelessWidget {
  const GitHubIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(16, 16), painter: GitHubPainter());
  }
}

class GitHubPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    final s = size.width / 16;
    path.addPath(
      _githubPath()..transform(Float64List.fromList([s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])),
      Offset.zero,
    );
    canvas.drawPath(path, paint);
  }

  Path _githubPath() {
    return Path()
      ..moveTo(8, 0)
      ..cubicTo(3.58, 0, 0, 3.58, 0, 8)
      ..cubicTo(0, 11.54, 2.29, 14.53, 5.47, 15.59)
      ..cubicTo(5.87, 15.66, 6.02, 15.42, 6.02, 15.21)
      ..cubicTo(6.02, 15.02, 6.01, 14.39, 6.01, 13.72)
      ..cubicTo(4, 14.09, 3.48, 13.23, 3.32, 12.78)
      ..cubicTo(3.23, 12.55, 2.84, 11.84, 2.5, 11.65)
      ..cubicTo(2.22, 11.5, 1.82, 11.13, 2.49, 11.12)
      ..cubicTo(3.12, 11.11, 3.57, 11.7, 3.72, 11.94)
      ..cubicTo(4.44, 13.15, 5.59, 12.81, 6.05, 12.6)
      ..cubicTo(6.12, 12.08, 6.33, 11.73, 6.56, 11.53)
      ..cubicTo(4.78, 11.33, 2.92, 10.64, 2.92, 7.58)
      ..cubicTo(2.92, 6.71, 3.23, 5.99, 3.74, 5.43)
      ..cubicTo(3.66, 5.23, 3.38, 4.41, 3.82, 3.31)
      ..cubicTo(3.82, 3.31, 4.49, 3.1, 6.02, 4.12)
      ..cubicTo(6.66, 3.94, 7.34, 3.85, 8.02, 3.85)
      ..cubicTo(8.7, 3.85, 9.38, 3.94, 10.02, 4.12)
      ..cubicTo(11.55, 3.08, 12.22, 3.31, 12.22, 3.31)
      ..cubicTo(12.66, 4.41, 12.38, 5.23, 12.3, 5.43)
      ..cubicTo(12.81, 5.99, 13.12, 6.7, 13.12, 7.58)
      ..cubicTo(13.12, 10.65, 11.25, 11.33, 9.47, 11.53)
      ..cubicTo(9.76, 11.78, 10.01, 12.26, 10.01, 13.01)
      ..cubicTo(10.01, 14.08, 10, 14.94, 10, 15.21)
      ..cubicTo(10, 15.42, 10.15, 15.67, 10.55, 15.59)
      ..cubicTo(13.71, 14.53, 16, 11.53, 16, 8)
      ..cubicTo(16, 3.58, 12.42, 0, 8, 0)
      ..close();
  }

  @override
  bool shouldRepaint(GitHubPainter oldDelegate) => false;
}
