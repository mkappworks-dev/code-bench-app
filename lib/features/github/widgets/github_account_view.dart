// lib/features/github/widgets/github_account_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/github/models/repository.dart';
import '../notifiers/github_auth_failure.dart';
import '../notifiers/github_auth_notifier.dart';
import 'github_connected_card.dart';
import 'github_device_flow_dialog.dart';
import 'github_disconnect_dialog.dart';
import 'github_disconnected_card.dart';

/// Shared by [GithubSection] (settings) and [GithubStep] (onboarding) so the
/// GitHub auth interaction is identical across both entry points.
class GithubAccountView extends ConsumerStatefulWidget {
  const GithubAccountView({super.key});

  @override
  ConsumerState<GithubAccountView> createState() => _GithubAccountViewState();
}

class _GithubAccountViewState extends ConsumerState<GithubAccountView> {
  // Prevents a flash to disconnected during the brief AsyncLoading cascade after Device Flow.
  GitHubAccount? _lastAccount;

  Future<void> _connectOAuth() async {
    await GitHubDeviceFlowDialog.show(context);
    if (!mounted) return;
    final account = ref.read(gitHubAuthProvider).value;
    if (account != null) {
      AppSnackBar.show(context, 'Connected to GitHub', type: AppSnackBarType.success);
    }
  }

  Future<void> _signOut() async {
    await ref.read(gitHubAuthProvider.notifier).signOut();
    if (!mounted) return;
    // Skip the success snackbar when signOut failed — the ref.listen below
    // surfaces the typed failure message. Showing both produces a green
    // "Disconnected" toast immediately followed by a red error toast.
    if (ref.read(gitHubAuthProvider).hasError) return;
    AppSnackBar.show(context, 'Disconnected from GitHub', type: AppSnackBarType.success);
  }

  void _requestDisconnect() {
    GitHubDisconnectDialog.show(context, onConfirmed: _signOut);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    ref.listen(gitHubAuthProvider, (_, next) {
      if (!mounted || next is! AsyncError) return;
      final error = next.error;
      final msg = switch (error) {
        GitHubAuthTokenRevoked() => 'Signed out: your GitHub token was revoked. Please reconnect.',
        GitHubAuthSignOutFailed(:final message) => message,
        GitHubAuthRequestFailed(:final message) => message,
        GitHubAuthPollFailed(:final message) => message,
        AuthException(:final message) => message,
        _ => 'GitHub auth failed — please try again.',
      };
      AppSnackBar.show(context, msg, type: AppSnackBarType.error);
    });

    final authAsync = ref.watch(gitHubAuthProvider);
    if (authAsync case AsyncData(:final value)) _lastAccount = value;
    final account = _lastAccount;
    final isLoading = authAsync.isLoading && account == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (account != null)
          GithubConnectedCard(account: account, onDisconnect: _requestDisconnect)
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
    );
  }
}
