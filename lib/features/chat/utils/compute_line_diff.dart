import 'package:diff_match_patch/diff_match_patch.dart' as dmp;

enum DiffOp { context, add, del }

class DiffLine {
  const DiffLine(this.op, this.text);
  final DiffOp op;
  final String text;
}

class LineDiffResult {
  const LineDiffResult({required this.lines, required this.additions, required this.deletions});
  final List<DiffLine> lines;
  final int additions;
  final int deletions;

  String toUnifiedText() {
    final buffer = StringBuffer();
    for (final line in lines) {
      switch (line.op) {
        case DiffOp.add:
          buffer.writeln('+${line.text}');
        case DiffOp.del:
          buffer.writeln('-${line.text}');
        case DiffOp.context:
          buffer.writeln(' ${line.text}');
      }
    }
    return buffer.toString();
  }
}

/// Computes a line-level diff between [oldText] and [newText]. Encodes each
/// distinct line as a single character, runs `diff_match_patch.diff` on the
/// encoded strings, then expands back. This avoids the bogus "+N -N" header
/// that resulted from counting raw line totals as deltas.
///
/// Mirrors the helper inside `ApplyService._computeLineCounts` (the package's
/// own `linesToChars` is internal and not exported).
LineDiffResult computeLineDiff(String oldText, String newText) {
  if (oldText.isEmpty && newText.isEmpty) {
    return const LineDiffResult(lines: [], additions: 0, deletions: 0);
  }

  final aLines = oldText.isEmpty ? <String>[] : oldText.split('\n');
  final bLines = newText.isEmpty ? <String>[] : newText.split('\n');

  final lineToChar = <String, String>{};
  final charToLine = <String>[''];
  String encode(List<String> lines) {
    final buf = StringBuffer();
    for (final line in lines) {
      var code = lineToChar[line];
      if (code == null) {
        charToLine.add(line);
        code = String.fromCharCode(charToLine.length - 1);
        lineToChar[line] = code;
      }
      buf.write(code);
    }
    return buf.toString();
  }

  final diffs = dmp.diff(encode(aLines), encode(bLines), checklines: false);

  final out = <DiffLine>[];
  var additions = 0;
  var deletions = 0;
  for (final d in diffs) {
    for (final code in d.text.runes) {
      final line = charToLine[code];
      switch (d.operation) {
        case dmp.DIFF_INSERT:
          out.add(DiffLine(DiffOp.add, line));
          additions++;
        case dmp.DIFF_DELETE:
          out.add(DiffLine(DiffOp.del, line));
          deletions++;
        case dmp.DIFF_EQUAL:
          out.add(DiffLine(DiffOp.context, line));
      }
    }
  }
  return LineDiffResult(lines: out, additions: additions, deletions: deletions);
}
