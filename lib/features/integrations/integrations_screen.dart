// lib/features/integrations/integrations_screen.dart
import 'package:flutter/material.dart';

import '../settings/widgets/section_label.dart';
import 'widgets/github_section.dart';

class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Integrations'),
        SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(padding: EdgeInsets.only(right: 24, bottom: 24), child: GithubSection()),
        ),
      ],
    );
  }
}
