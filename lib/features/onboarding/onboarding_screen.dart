import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/chip_button.dart';
import '../settings/notifiers/settings_actions.dart';
import 'notifiers/onboarding_notifier.dart';
import 'widgets/step_progress_indicator.dart';
import 'widgets/api_keys_step.dart';
import 'widgets/github_step.dart';
import 'widgets/add_project_step.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _stepTitles = ['Connect AI Providers', 'Connect GitHub', 'Add Your First Project'];

  static const _stepSubtitles = [
    'Add API keys to use AI in Code Bench',
    'Link your GitHub account for PR features',
    'Point Code Bench at a local folder to begin',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final step = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: Row(
        children: [
          const _BrandingPanel(),
          Expanded(
            flex: 75,
            child: _ContentPanel(step: step, stepTitles: _stepTitles, stepSubtitles: _stepSubtitles),
          ),
        ],
      ),
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      flex: 38,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
            colors: [c.brandingGradientTop, c.brandingGradientMid, c.deepBackground],
          ),
          border: Border(right: BorderSide(color: c.borderColor)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.panelBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.borderColor),
                    boxShadow: [BoxShadow(color: c.accentGlow, blurRadius: 16, spreadRadius: 2)],
                  ),
                  child: const _CodeGlyph(),
                ),
                const SizedBox(width: 10),
                Text(
                  'Code Bench',
                  style: TextStyle(color: c.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('AI-powered coding workspace', style: TextStyle(color: c.subtleTealFg, fontSize: 11)),
            const SizedBox(height: 28),
            _FeatureCard(icon: '⚡', title: 'Multi-provider AI', subtitle: 'OpenAI · Anthropic · Gemini · Ollama'),
            const SizedBox(height: 8),
            _FeatureCard(icon: '🖊', title: 'Smart Code Editor', subtitle: 'AI apply · diff view · file explorer'),
            const SizedBox(height: 8),
            _FeatureCard(icon: '🐙', title: 'GitHub Integration', subtitle: 'PRs · commits · repo browser'),
            const Spacer(),
            Text('🔒 Keys stored in your OS keychain', style: TextStyle(color: c.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ContentPanel extends ConsumerWidget {
  const _ContentPanel({required this.step, required this.stepTitles, required this.stepSubtitles});

  final int step;
  final List<String> stepTitles;
  final List<String> stepSubtitles;

  /// Marks onboarding complete and navigates to the chat screen.
  ///
  /// This method swallows its own errors deliberately: if `markCompleted()`
  /// throws (disk full, prefs corruption), we still want the user to land
  /// in the app rather than be trapped on the final step. The worst case
  /// is that onboarding reappears on next launch — a smaller UX failure
  /// than stranding the user with a non-working "Finish" button.
  ///
  /// Callers can safely fire-and-forget this future.
  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(settingsActionsProvider.notifier).markOnboardingCompleted();
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          'Could not save onboarding progress — you may see this screen again',
          type: AppSnackBarType.warning,
        );
      }
    }
    if (context.mounted) context.go('/chat');
  }

  void _next(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingProvider.notifier);
    if (step < OnboardingNotifier.totalSteps - 1) {
      controller.next();
    } else {
      // `_finish` catches its own errors and navigates on every path, so
      // dropping this future is intentional.
      unawaited(_finish(context, ref));
    }
  }

  void _skip(BuildContext context, WidgetRef ref) => _next(context, ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return Container(
      color: c.background,
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button (steps 1 and 2 only)
          if (step > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: ChipButton(
                label: 'Back',
                icon: AppIcons.arrowLeft,
                onPressed: () => ref.read(onboardingProvider.notifier).back(),
              ),
            )
          else
            const SizedBox(height: 32),
          const SizedBox(height: 16),
          StepProgressIndicator(
            currentStep: step,
            totalSteps: OnboardingNotifier.totalSteps,
            stepTitle: stepTitles[step],
            stepSubtitle: stepSubtitles[step],
          ),
          const SizedBox(height: 32),
          // Step content
          Expanded(
            child: switch (step) {
              0 => ApiKeysStep(onContinue: () => _next(context, ref), onSkip: () => _skip(context, ref)),
              1 => GithubStep(onContinue: () => _next(context, ref), onSkip: () => _skip(context, ref)),
              2 => AddProjectStep(onComplete: () => _finish(context, ref), onSkip: () => _skip(context, ref)),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

// ── Feature card (used in branding panel) ─────────────────────────────────

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.subtitle});

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 54,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.fieldFill,
        border: Border.all(color: c.accentBorderTeal),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$icon  $title',
            style: TextStyle(color: c.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: c.textSecondary, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── </> logo mark ──────────────────────────────────────────────────────────

class _CodeGlyph extends StatelessWidget {
  const _CodeGlyph();

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.of(context).accent;
    return CustomPaint(
      size: const Size(32, 32),
      painter: _CodeGlyphPainter(color: accentColor),
    );
  }
}

class _CodeGlyphPainter extends CustomPainter {
  const _CodeGlyphPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2 * (size.width / 32)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final s = size.width / 32;
    // Left bracket <
    canvas.drawLine(Offset(5 * s, 16 * s), Offset(11 * s, 10 * s), paint);
    canvas.drawLine(Offset(5 * s, 16 * s), Offset(11 * s, 22 * s), paint);
    // Right bracket >
    canvas.drawLine(Offset(27 * s, 16 * s), Offset(21 * s, 10 * s), paint);
    canvas.drawLine(Offset(27 * s, 16 * s), Offset(21 * s, 22 * s), paint);
    // Slash /
    canvas.drawLine(Offset(19 * s, 9 * s), Offset(13 * s, 23 * s), paint);
  }

  @override
  bool shouldRepaint(covariant _CodeGlyphPainter oldDelegate) => oldDelegate.color != color;
}
