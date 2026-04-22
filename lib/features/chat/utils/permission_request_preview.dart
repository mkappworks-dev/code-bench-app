import 'dart:convert';

import '../../../data/session/models/permission_request.dart';

/// Pure display helpers for [PermissionRequest].
///
/// Produces the preview lines shown in [PermissionRequestCard] for each tool
/// type, and sanitizes shell commands before they reach the UI.
abstract final class PermissionRequestPreview {
  /// Returns display lines for [req], or `null` when no preview is available.
  static List<String>? buildLines(PermissionRequest req) {
    // MCP tool: name contains "/"
    if (req.toolName.contains('/')) {
      if (req.input.isEmpty) return null;
      final encoded = const JsonEncoder.withIndent('  ').convert(req.input);
      return encoded.split('\n');
    }
    if (req.toolName == 'write_file') {
      final content = req.input['content'];
      if (content is! String || content.isEmpty) return null;
      final allLines = content.split('\n');
      final truncated = allLines.length > 5;
      final lines = allLines.take(5).toList();
      if (truncated) lines.add('…');
      return lines;
    }
    if (req.toolName == 'str_replace') {
      final oldStr = req.input['old_str'];
      final newStr = req.input['new_str'];
      if (oldStr is! String || oldStr.isEmpty) return null;
      if (newStr is! String) return null;
      final oldLines = oldStr.split('\n').take(3).map((l) => '- $l').toList();
      final newLines = newStr.split('\n').take(3).map((l) => '+ $l').toList();
      return [...oldLines, ...newLines];
    }
    if (req.toolName == 'bash') {
      final command = req.input['command'];
      if (command is! String || command.isEmpty) return null;
      return [sanitizeCommand(command)];
    }
    return null;
  }

  /// Strips characters that could visually mislead an approver: ANSI escapes,
  /// Unicode bidi overrides, and non-printable controls (preserving \n and \t).
  static String sanitizeCommand(String command) {
    final noAnsi = command.replaceAll(RegExp(r'\x1b\[[0-9;]*[A-Za-z]'), '');
    final buf = StringBuffer();
    for (final rune in noAnsi.runes) {
      // Skip bidi overrides (U+202A-202E), directional isolates (U+2066-2069),
      // right-to-left mark (U+200F), and Arabic letter mark (U+061C).
      if ((rune >= 0x202a && rune <= 0x202e) || (rune >= 0x2066 && rune <= 0x2069) || rune == 0x200f || rune == 0x061c)
        continue;
      // Skip non-printable controls except \t (0x09) and \n (0x0a).
      if (rune != 0x09 && rune != 0x0a && rune < 0x20) continue;
      if (rune == 0x7f) continue;
      buf.writeCharCode(rune);
    }
    return buf.toString();
  }
}
