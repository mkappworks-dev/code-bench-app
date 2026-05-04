import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/buttons.dart';
import '../../github/notifiers/github_auth_notifier.dart';
import '../../github/widgets/github_account_view.dart';

class GithubStep extends ConsumerWidget {
  const GithubStep({super.key, required this.onContinue, required this.onSkip});
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            if (account != null) PrimaryButton(label: 'Continue →', onPressed: onContinue),
          ],
        ),
      ],
    );
  }
}
