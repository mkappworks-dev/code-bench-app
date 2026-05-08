import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class DiffBody extends StatelessWidget {
  const DiffBody({super.key, required this.diffText});
  final String diffText;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lines = diffText.split('\n').toList();
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();

    return Container(
      color: c.codeBlockBg,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final line in lines) _DiffLine(line: line, c: c)],
      ),
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine({required this.line, required this.c});
  final String line;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final isAdd = line.startsWith('+');
    final isDel = line.startsWith('-');
    final isHunk = line.startsWith('@@');

    Color? rowBg;
    Color markerColor;
    Color textColor;

    if (isAdd) {
      rowBg = const Color(0xFFAAD94C).withValues(alpha: 0.08);
      markerColor = const Color(0xFFAAD94C);
      textColor = const Color(0xFFAAD94C);
    } else if (isDel) {
      rowBg = const Color(0xFFF07178).withValues(alpha: 0.08);
      markerColor = const Color(0xFFF07178);
      textColor = const Color(0xFFF07178);
    } else if (isHunk) {
      rowBg = c.info.withValues(alpha: 0.06);
      markerColor = c.info;
      textColor = c.info;
    } else {
      markerColor = c.textMuted;
      textColor = c.textSecondary;
    }

    final marker = isAdd
        ? '+'
        : isDel
        ? '−'
        : ' ';
    final content = (isAdd || isDel || line.startsWith(' ')) ? line.substring(1) : line;

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            child: Text(
              marker,
              style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: markerColor, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              content,
              style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
