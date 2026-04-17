import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.rows});

  final List<SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.glassFill,
        border: Border.all(color: c.subtleBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[if (i > 0) Divider(height: 1, color: c.faintBorder), rows[i]],
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.description,
    required this.trailing,
    this.isLast = false,
  });

  final String label;
  final String description;
  final Widget trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: c.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }
}
