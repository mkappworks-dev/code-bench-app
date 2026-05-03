// lib/features/integrations/widgets/github_disconnected_card.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/github_glass_button.dart';

class GithubDisconnectedCard extends StatelessWidget {
  const GithubDisconnectedCard({super.key, required this.isLoading, required this.onConnectOAuth});

  final bool isLoading;
  final VoidCallback onConnectOAuth;

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
      child: GitHubGlassButton(onPressed: onConnectOAuth, isLoading: isLoading),
    );
  }
}
