import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../github/widgets/github_account_view.dart';

/// "GitHub" sub-section of the integrations panel: sub-title + account
/// view. The account view owns the auth state, connect/disconnect, and
/// the info banner — this widget just adds the section header above it.
class GithubSection extends StatelessWidget {
  const GithubSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GitHub',
          style: TextStyle(color: c.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const GithubAccountView(),
      ],
    );
  }
}
