import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.rows});

  final List<SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0x05FFFFFF) // rgba 255,255,255,0.02
            : const Color(0x99FFFFFF), // rgba 255,255,255,0.60
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? ThemeConstants.glassBorderSubtle
              : ThemeConstants.lightBorder,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? ThemeConstants.glassBorderFaint
                    : ThemeConstants.lightDivider,
              ),
            rows[i],
          ],
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
                  style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 11)),
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
