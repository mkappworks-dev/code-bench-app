import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/github_glass_button.dart';
import '../../../data/github/models/repository.dart';
import '../notifiers/github_auth_notifier.dart';
import 'github_device_flow_dialog.dart';

class GithubStep extends ConsumerStatefulWidget {
  const GithubStep({super.key, required this.onContinue, required this.onSkip});
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  ConsumerState<GithubStep> createState() => _GithubStepState();
}

class _GithubStepState extends ConsumerState<GithubStep> {
  Future<void> _connectOAuth() async {
    await GitHubDeviceFlowDialog.show(context);
  }

  Future<void> _disconnect() async {
    await ref.read(gitHubAuthProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final authAsync = ref.watch(gitHubAuthProvider);
    final (account, isLoading) = switch (authAsync) {
      AsyncLoading() => (null, true),
      AsyncError() => (null, false),
      AsyncData(:final value) => (value, false),
    };

    if (account != null) {
      return _ConnectedView(
        account: account,
        onDisconnect: _disconnect,
        onContinue: widget.onContinue,
        onSkip: widget.onSkip,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GitHubGlassButton(onPressed: _connectOAuth, isLoading: isLoading),
        const Spacer(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: c.textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Skip for now', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConnectedView extends StatelessWidget {
  const _ConnectedView({
    required this.account,
    required this.onDisconnect,
    required this.onContinue,
    required this.onSkip,
  });

  final GitHubAccount account;
  final VoidCallback onDisconnect;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.panelBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.faintFg),
          ),
          child: Row(
            children: [
              if (account.avatarUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(account.avatarUrl, width: 40, height: 40),
                )
              else
                Icon(Icons.person, size: 40, color: c.textSecondary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: c.success),
                      const SizedBox(width: 4),
                      Text(
                        account.username,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: ThemeConstants.uiFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (account.name != null)
                    Text(
                      account.name!,
                      style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                    ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: onDisconnect,
                child: Text(
                  'Disconnect',
                  style: TextStyle(color: c.textMuted, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: c.textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Skip for now', style: TextStyle(fontSize: 12)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: onContinue,
              child: const Text('Continue →', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}
