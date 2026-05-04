import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chip_button.dart';
import '../../github/notifiers/github_auth_notifier.dart';
import '../../github/widgets/github_account_view.dart';

class GithubStep extends ConsumerWidget {
  const GithubStep({super.key, required this.onContinue, required this.onSkip});
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final account = ref.watch(gitHubAuthProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GithubAccountView(),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ChipButton(label: 'Skip for now', onPressed: onSkip, size: ChipButtonSize.medium),
            if (account != null)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
