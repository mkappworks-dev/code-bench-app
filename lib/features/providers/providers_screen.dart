// lib/features/providers/providers_screen.dart
import 'package:flutter/material.dart';

import '../settings/widgets/section_label.dart';
import 'widgets/api_keys_list.dart';

class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Providers'),
        SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(padding: EdgeInsets.only(right: 24, bottom: 24), child: ApiKeysList()),
        ),
      ],
    );
  }
}
