import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/github/models/repository.dart';
import '../onboarding/notifiers/github_auth_notifier.dart';
import 'widgets/section_label.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  bool _showPat = false;
  final _patController = TextEditingController();

  @override
  void dispose() {
    _patController.dispose();
    super.dispose();
  }

  Future<void> _connectOAuth() async {
    await ref.read(gitHubAuthProvider.notifier).authenticate();
  }

  Future<void> _signOut() async {
    await ref.read(gitHubAuthProvider.notifier).signOut();
  }

  Future<void> _signInWithPat() async {
    final token = _patController.text.trim();
    if (token.isEmpty) return;
    await ref.read(gitHubAuthProvider.notifier).signInWithPat(token);
    if (!mounted) return;
    if (!ref.read(gitHubAuthProvider).hasError) {
      _patController.clear();
      setState(() => _showPat = false);
    }
  }

  Future<void> _openTokenCreationPage() async {
    final uri = Uri.parse('https://github.com/settings/tokens/new');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        AppSnackBar.show(
          context,
          'Could not open browser — visit github.com/settings/tokens/new',
          type: AppSnackBarType.warning,
        );
      }
    } catch (e, st) {
      dLog('[IntegrationsScreen] launchUrl failed: $e\n$st');
      if (mounted) {
        AppSnackBar.show(
          context,
          'Could not open browser — visit github.com/settings/tokens/new',
          type: AppSnackBarType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    ref.listen(gitHubAuthProvider, (_, next) {
      if (!mounted) return;
      if (next is AsyncError) {
        AppSnackBar.show(context, 'GitHub auth failed — please try again.', type: AppSnackBarType.error);
      }
    });

    final authAsync = ref.watch(gitHubAuthProvider);
    final (account, isLoading) = switch (authAsync) {
      AsyncLoading() => (null as GitHubAccount?, true),
      AsyncError() => (null as GitHubAccount?, false),
      AsyncData(:final value) => (value, false),
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('GitHub'),
          const SizedBox(height: 8),
          if (account != null)
            _ConnectedCard(account: account, onDisconnect: _signOut)
          else
            _DisconnectedCard(
              isLoading: isLoading,
              showPat: _showPat,
              patController: _patController,
              onConnectOAuth: _connectOAuth,
              onTogglePat: () => setState(() => _showPat = !_showPat),
              onSignInWithPat: _signInWithPat,
              onOpenTokenPage: _openTokenCreationPage,
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.accentTintMid,
              border: Border.all(color: c.accent.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'GitHub is used to create pull requests and list branches from within chat sessions.',
              style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.account, required this.onDisconnect});

  final GitHubAccount account;
  final VoidCallback onDisconnect;

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
      child: Row(
        children: [
          if (account.avatarUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                account.avatarUrl,
                width: 36,
                height: 36,
                errorBuilder: (_, _, _) => _PersonIcon(c: c),
              ),
            )
          else
            _PersonIcon(c: c),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.username,
                style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: c.success),
                  const SizedBox(width: 3),
                  Text('Connected', style: TextStyle(color: c.success, fontSize: 10)),
                ],
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: onDisconnect,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: c.deepBorder),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Disconnect',
                style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonIcon extends StatelessWidget {
  const _PersonIcon({required this.c});

  final AppColors c;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: c.inputSurface, shape: BoxShape.circle),
    child: Icon(Icons.person, size: 20, color: c.textSecondary),
  );
}

class _DisconnectedCard extends StatelessWidget {
  const _DisconnectedCard({
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
            onPressed: isLoading ? null : onConnectOAuth,
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const _GitHubIcon(),
            label: Text(isLoading ? 'Connecting…' : 'Continue with GitHub', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTogglePat,
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
                Icon(showPat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 14, color: c.accent),
              ],
            ),
          ),
          if (showPat) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppTextField(controller: patController, obscureText: true, labelText: 'Personal Access Token'),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: isLoading ? null : onSignInWithPat,
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.accentTintMid,
                      border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Connect',
                      style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeSmall),
                    ),
                  ),
                ),
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
        ],
      ),
    );
  }
}

class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(16, 16), painter: _GitHubPainter());
  }
}

class _GitHubPainter extends CustomPainter {
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
  bool shouldRepaint(_GitHubPainter oldDelegate) => false;
}
