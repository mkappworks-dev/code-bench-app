// lib/features/integrations/integrations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/github/models/repository.dart';
import '../onboarding/notifiers/github_auth_notifier.dart';
import '../onboarding/widgets/github_device_flow_dialog.dart';
import '../settings/widgets/section_label.dart';
import 'widgets/github_connected_card.dart';
import 'widgets/github_disconnected_card.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  Future<void> _connectOAuth() async {
    await GitHubDeviceFlowDialog.show(context);
    if (!mounted) return;
    // Only celebrate when an account actually landed — the dialog can also
    // dismiss via Cancel (state stays AsyncData(null)) or via an error
    // (state is AsyncError). Reading account != null distinguishes the
    // genuine success case from those.
    final account = ref.read(gitHubAuthProvider).value;
    if (account != null) {
      AppSnackBar.show(context, 'Connected to GitHub', type: AppSnackBarType.success);
    }
  }

  Future<void> _signOut() async {
    await ref.read(gitHubAuthProvider.notifier).signOut();
    if (!mounted) return;
    if (!ref.read(gitHubAuthProvider).hasError) {
      // Local Disconnect only clears the keychain — Device Flow has no
      // client_secret, so this client cannot revoke the grant on
      // GitHub's side. Surface a "Revoke on GitHub" action so the user
      // can close the loop themselves on the GitHub App connections page.
      AppSnackBar.show(
        context,
        'Disconnected from GitHub',
        message: 'Token cleared locally. To revoke on GitHub, open the app connections page.',
        type: AppSnackBarType.success,
        actionLabel: 'Revoke on GitHub',
        onAction: _openRevocationPage,
      );
    }
  }

  Future<void> _openRevocationPage() async {
    final uri = Uri.parse('https://github.com/settings/connections/applications/${ApiConstants.githubClientId}');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        AppSnackBar.show(
          context,
          'Could not open browser — visit github.com/settings/applications',
          type: AppSnackBarType.warning,
        );
      }
    } catch (e, st) {
      dLog('[IntegrationsScreen] launchUrl revoke failed: $e\n$st');
      if (mounted) {
        AppSnackBar.show(
          context,
          'Could not open browser — visit github.com/settings/applications',
          type: AppSnackBarType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    ref.listen(gitHubAuthProvider, (_, next) {
      if (!mounted || next is! AsyncError) return;
      final e = next.error;
      final msg = e is AuthException ? e.message : 'GitHub auth failed — please try again.';
      AppSnackBar.show(context, msg, type: AppSnackBarType.error);
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
            GithubDisconnectedCard(isLoading: isLoading, onConnectOAuth: _connectOAuth),
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
