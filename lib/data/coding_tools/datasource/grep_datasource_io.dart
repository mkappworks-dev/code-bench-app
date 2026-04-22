import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/grep_match.dart';
import 'grep_datasource.dart';

/// Pure-Dart grep backend. Falls back from [GrepDatasourceProcess] when
/// ripgrep is not installed. Reads files via dart:io directly.
class GrepDatasourceIo implements GrepDatasource {
  @override
  Future<GrepResult> grep({
    required String pattern,
    required String rootPath,
    int contextLines = 2,
    int maxMatches = 100,
    List<String> fileExtensions = const [],
  }) async {
    final regex = RegExp(pattern); // throws FormatException on bad pattern
    final sentinel = maxMatches + 1;
    final matches = <GrepMatch>[];
    await _walkDir(rootPath, rootPath, fileExtensions, regex, contextLines, matches, sentinel);
    final wasCapped = matches.length >= sentinel;
    return GrepResult(
      matches: matches.take(maxMatches).toList(),
      totalFound: wasCapped ? sentinel : matches.length,
      wasCapped: wasCapped,
    );
  }

  Future<void> _walkDir(
    String dir,
    String rootPath,
    List<String> extensions,
    RegExp regex,
    int contextLines,
    List<GrepMatch> matches,
    int sentinel,
  ) async {
    if (matches.length >= sentinel) return;
    List<FileSystemEntity> entries;
    try {
      entries = await Directory(dir).list(followLinks: false).toList();
    } on FileSystemException {
      return;
    }
    for (final entity in entries) {
      if (matches.length >= sentinel) return;
      if (entity is Directory) {
        await _walkDir(entity.path, rootPath, extensions, regex, contextLines, matches, sentinel);
      } else if (entity is File) {
        if (extensions.isNotEmpty) {
          final ext = p.extension(entity.path).replaceFirst('.', '');
          if (!extensions.contains(ext)) continue;
        }
        await _scanFile(entity.path, rootPath, regex, contextLines, matches, sentinel);
      }
    }
  }

  Future<void> _scanFile(
    String filePath,
    String rootPath,
    RegExp regex,
    int contextLines,
    List<GrepMatch> matches,
    int sentinel,
  ) async {
    if (matches.length >= sentinel) return;
    List<int> bytes;
    try {
      bytes = await File(filePath).readAsBytes();
    } on FileSystemException {
      return;
    }
    if (bytes.contains(0)) return; // binary file
    String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      return; // not UTF-8
    }
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (matches.length >= sentinel) return;
      if (!regex.hasMatch(lines[i])) continue;
      final beforeStart = (i - contextLines).clamp(0, i);
      final afterEnd = (i + 1 + contextLines).clamp(0, lines.length);
      matches.add(
        GrepMatch(
          file: p.relative(filePath, from: rootPath),
          lineNumber: i + 1,
          lineContent: lines[i],
          contextBefore: lines.sublist(beforeStart, i),
          contextAfter: lines.sublist(i + 1, afterEnd),
        ),
      );
    }
  }
}
