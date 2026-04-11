import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/datasources/local/onboarding_preferences.dart';
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
    final step = ref.watch(onboardingControllerProvider);

    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Row(
        children: [
          // ── Left: branding (38% width, unchanged from original) ──────────
          const _BrandingPanel(),
          // ── Right: content (62% width) ───────────────────────────────────
          Expanded(
            flex: 62,
            child: _ContentPanel(step: step, stepTitles: _stepTitles, stepSubtitles: _stepSubtitles),
          ),
        ],
      ),
    );
  }
}

// ── Left branding panel ────────────────────────────────────────────────────

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 38,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [ThemeConstants.sidebarBackground, ThemeConstants.activityBar, ThemeConstants.deepBackground],
          ),
          border: Border(right: BorderSide(color: ThemeConstants.borderColor)),
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
                    gradient: const LinearGradient(
                      colors: [ThemeConstants.accent, ThemeConstants.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 2))],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'C',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Code Bench',
                  style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-powered coding workspace',
              style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 28),
            _FeatureCard(icon: '⚡', title: 'Multi-provider AI', subtitle: 'OpenAI · Anthropic · Gemini · Ollama'),
            const SizedBox(height: 8),
            _FeatureCard(icon: '🖊', title: 'Smart Code Editor', subtitle: 'AI apply · diff view · file explorer'),
            const SizedBox(height: 8),
            _FeatureCard(icon: '🐙', title: 'GitHub Integration', subtitle: 'PRs · commits · repo browser'),
            const Spacer(),
            const Text(
              '🔒 Keys stored in your OS keychain',
              style: TextStyle(color: ThemeConstants.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Right content panel ────────────────────────────────────────────────────

class _ContentPanel extends ConsumerWidget {
  const _ContentPanel({required this.step, required this.stepTitles, required this.stepSubtitles});

  final int step;
  final List<String> stepTitles;
  final List<String> stepSubtitles;

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(onboardingPreferencesProvider);
    await prefs.markCompleted();
    if (context.mounted) context.go('/chat');
  }

  void _next(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    if (step < OnboardingController.totalSteps - 1) {
      controller.next();
    } else {
      _finish(context, ref);
    }
  }

  void _skip(BuildContext context, WidgetRef ref) => _next(context, ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: ThemeConstants.background,
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button (steps 1 and 2 only)
          if (step > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ref.read(onboardingControllerProvider.notifier).back(),
                icon: const Icon(Icons.chevron_left, size: 16, color: Color(0xFF888888)),
                label: const Text('Back', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              ),
            )
          else
            const SizedBox(height: 32),
          const SizedBox(height: 16),
          StepProgressIndicator(
            currentStep: step,
            totalSteps: OnboardingController.totalSteps,
            stepTitle: stepTitles[step],
            stepSubtitle: stepSubtitles[step],
          ),
          const SizedBox(height: 32),
          // Step content
          Expanded(
            child: switch (step) {
              0 => ApiKeysStep(onContinue: () => _next(context, ref)),
              1 => GithubStep(onContinue: () => _next(context, ref)),
              2 => AddProjectStep(onComplete: () => _finish(context, ref)),
              _ => const SizedBox.shrink(),
            },
          ),
          // Footer navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _skip(context, ref),
                child: const Text('Skip for now', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
              ),
              if (step == 1)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ThemeConstants.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _next(context, ref),
                  child: const Text('Continue →', style: TextStyle(fontSize: 12)),
                ),
            ],
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
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeConstants.frostedBg,
        border: Border.all(color: ThemeConstants.frostedBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$icon  $title',
            style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: ThemeConstants.textMuted, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
