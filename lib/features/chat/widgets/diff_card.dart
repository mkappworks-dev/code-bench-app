import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'diff_body.dart';

class DiffCard extends StatelessWidget {
  const DiffCard({super.key, required this.rawDiff});
  final String rawDiff;

  static _ParsedDiff _parse(String raw) {
    final lines = raw.split('\n');
    String filename = '';
    int additions = 0;
    int deletions = 0;
    final bodyLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('diff --git')) {
        final parts = line.split(' ');
        if (parts.length >= 3) filename = parts.last.replaceFirst('b/', '');
      } else if (line.startsWith('--- ') || line.startsWith('+++ ')) {
        if (filename.isEmpty && line.startsWith('+++ ')) {
          filename = line.substring(4).replaceFirst('b/', '').replaceFirst('a/', '');
        }
      } else {
        bodyLines.add(line);
        if (line.startsWith('+') && !line.startsWith('++')) additions++;
        if (line.startsWith('-') && !line.startsWith('--')) deletions++;
      }
    }

    return _ParsedDiff(
      filename: filename.isEmpty ? 'diff' : filename,
      additions: additions,
      deletions: deletions,
      body: bodyLines.join('\n'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = _parse(rawDiff);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.04),
        border: Border.all(color: c.accent.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DiffHead(c: c, filename: p.filename, additions: p.additions, deletions: p.deletions),
          DiffBody(diffText: p.body),
        ],
      ),
    );
  }
}

class _ParsedDiff {
  const _ParsedDiff({required this.filename, required this.additions, required this.deletions, required this.body});
  final String filename;
  final int additions;
  final int deletions;
  final String body;
}

class _DiffHead extends StatelessWidget {
  const _DiffHead({required this.c, required this.filename, required this.additions, required this.deletions});
  final AppColors c;
  final String filename;
  final int additions;
  final int deletions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: c.accent.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.difference_outlined, size: 14, color: c.accent),
          const SizedBox(width: 8),
          Text(
            filename,
            style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
          ),
          const SizedBox(width: 8),
          Text(
            '+$additions',
            style: const TextStyle(
              color: Color(0xFFAAD94C),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          Text('·', style: TextStyle(color: c.textMuted, fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            '−$deletions',
            style: const TextStyle(
              color: Color(0xFFF07178),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
