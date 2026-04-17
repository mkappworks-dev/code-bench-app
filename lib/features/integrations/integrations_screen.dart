// lib/features/integrations/integrations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/github/models/repository.dart';
import '../onboarding/notifiers/github_auth_notifier.dart';
import '../settings/widgets/section_label.dart';
import 'widgets/github_connected_card.dart';
import 'widgets/github_disconnected_card.dart';

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
    if (!mounted) return;
    if (!ref.read(gitHubAuthProvider).hasError) {
      AppSnackBar.show(context, 'Connected to GitHub', type: AppSnackBarType.success);
    }
  }

  Future<void> _signOut() async {
    await ref.read(gitHubAuthProvider.notifier).signOut();
    if (!mounted) return;
    if (!ref.read(gitHubAuthProvider).hasError) {
      AppSnackBar.show(context, 'Disconnected from GitHub', type: AppSnackBarType.success);
    }
  }

  Future<void> _signInWithPat() async {
    final token = _patController.text.trim();
    if (token.isEmpty) return;
    await ref.read(gitHubAuthProvider.notifier).signInWithPat(token);
    if (!mounted) return;
    if (!ref.read(gitHubAuthProvider).hasError) {
      AppSnackBar.show(context, 'Connected to GitHub', type: AppSnackBarType.success);
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
        AppSnackBar.show(
          context,
          'GitHub auth failed — please try again.',
          type: AppSnackBarType.error,
        );
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
            GithubConnectedCard(account: account, onDisconnect: _signOut)
          else
            GithubDisconnectedCard(
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
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
