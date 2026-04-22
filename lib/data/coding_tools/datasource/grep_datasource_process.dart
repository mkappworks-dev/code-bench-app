import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/utils/debug_logger.dart';
import '../coding_tools_exceptions.dart';
import '../models/grep_match.dart';
import 'grep_datasource.dart';

/// Grep backend that shells out to ripgrep (`rg`). Selected when `rg` is
/// available at startup (see RipgrepAvailabilityDatasource). Uses `--json`
/// output for structured parsing. [CodingToolsDiskException] is thrown if
/// rg disappears mid-session — ToolRegistry crash-catch surfaces it as an
/// error result.
class GrepDatasourceProcess implements GrepDatasource {
  @override
  Future<GrepResult> grep({
    required String pattern,
    required String rootPath,
    int contextLines = 2,
    int maxMatches = 100,
    List<String> fileExtensions = const [],
  }) async {
    final args = [
      '--json',
      '--context',
      '$contextLines',
      ...fileExtensions.expand((e) => ['--glob', '*.$e']),
      pattern,
      rootPath,
    ];

    ProcessResult result;
    try {
      result = await Process.run('rg', args);
    } on ProcessException catch (e) {
      dLog('[GrepDatasourceProcess] rg not available: $e');
      throw CodingToolsDiskException('ripgrep not available: ${e.message}');
    }

    // Exit code 1 = no matches (normal); 2 = rg error (bad regex, path, etc.)
    if (result.exitCode == 2) {
      final msg = (result.stderr as String).trim().split('\n').first;
      throw CodingToolsDiskException(msg);
    }

    return _parseJson(result.stdout as String, rootPath, maxMatches);
  }

  GrepResult _parseJson(String stdout, String rootPath, int maxMatches) {
    final sentinel = maxMatches + 1;
    final matches = <GrepMatch>[];

    final List<({String type, String file, int lineNumber, String text})> groupEvents = [];

    void flushGroup() {
      final matchPositions = <int>[];
      for (var i = 0; i < groupEvents.length; i++) {
        if (groupEvents[i].type == 'match') matchPositions.add(i);
      }
      for (var mi = 0; mi < matchPositions.length; mi++) {
        if (matches.length >= sentinel) return;
        final pos = matchPositions[mi];
        final prevPos = mi == 0 ? -1 : matchPositions[mi - 1];
        final nextPos = mi < matchPositions.length - 1 ? matchPositions[mi + 1] : groupEvents.length;
        final contextBefore = groupEvents
            .sublist(prevPos + 1, pos)
            .where((e) => e.type == 'context')
            .map((e) => e.text)
            .toList();
        final contextAfter = groupEvents
            .sublist(pos + 1, nextPos)
            .where((e) => e.type == 'context')
            .map((e) => e.text)
            .toList();
        final ev = groupEvents[pos];
        matches.add(
          GrepMatch(
            file: p.relative(ev.file, from: rootPath),
            lineNumber: ev.lineNumber,
            lineContent: ev.text,
            contextBefore: contextBefore,
            contextAfter: contextAfter,
          ),
        );
      }
      groupEvents.clear();
    }

    for (final line in stdout.split('\n')) {
      if (line.isEmpty) continue;
      Map<String, dynamic> event;
      try {
        event = jsonDecode(line) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>?;
      if (type == null || data == null) continue;

      switch (type) {
        case 'begin':
          groupEvents.clear();
        case 'match':
        case 'context':
          if (matches.length >= sentinel) continue;
          final filePath = ((data['path'] as Map?) ?? {})['text'] as String? ?? '';
          final lineNum = data['line_number'] as int? ?? 0;
          final text = (((data['lines'] as Map?) ?? {})['text'] as String? ?? '').trimRight();
          groupEvents.add((type: type, file: filePath, lineNumber: lineNum, text: text));
        case 'end':
          flushGroup();
      }
    }

    final wasCapped = matches.length >= sentinel;
    return GrepResult(
      matches: matches.take(maxMatches).toList(),
      totalFound: wasCapped ? sentinel : matches.length,
      wasCapped: wasCapped,
    );
  }
}
