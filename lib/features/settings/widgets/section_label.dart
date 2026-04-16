import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(
      label.toUpperCase(),
      style: TextStyle(color: c.mutedFg, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8),
    );
  }
}
