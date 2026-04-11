import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/tool_event.dart';

/// A compact, expandable card that renders a single agent tool-use event
/// inline in the chat stream. Collapsed state shows the tool name, primary
/// argument, status, duration, and token counts. Expanding reveals the full
/// input map and (truncated) output.
class ToolCallRow extends StatefulWidget {
  const ToolCallRow({super.key, required this.event});
  final ToolEvent event;

  @override
  State<ToolCallRow> createState() => _ToolCallRowState();
}

class _ToolCallRowState extends State<ToolCallRow> {
  bool _expanded = false;

  IconData _iconForTool(String toolName) {
    return switch (toolName) {
      'read_file' || 'read' => Icons.description_outlined,
      'write_file' || 'write' => Icons.edit_outlined,
      'run_command' || 'bash' => Icons.terminal,
      'search' || 'grep' => Icons.search,
      _ => Icons.build_outlined,
    };
  }

  String _primaryArg(ToolEvent event) {
    if (event.filePath != null) return event.filePath!;
    if (event.input.isNotEmpty) {
      final first = event.input.values.first;
      if (first is String) {
        return first.length > 60 ? '${first.substring(0, 60)}…' : first;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final arg = _primaryArg(widget.event);
    // A tool event is "running" when we have neither a duration nor an
    // output — both are written once the tool returns.
    final isRunning = widget.event.durationMs == null && widget.event.output == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Collapsed row ─────────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(_expanded ? 0 : 6),
              border: Border.all(color: ThemeConstants.borderColor),
            ),
            child: Row(
              children: [
                Icon(_iconForTool(widget.event.toolName), size: 13, color: ThemeConstants.textSecondary),
                const SizedBox(width: 6),
                Text(
                  widget.event.toolName,
                  style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 11, fontFamily: 'monospace'),
                ),
                if (arg.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      arg,
                      style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                const SizedBox(width: 8),
                if (isRunning)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF4A7CFF)),
                  )
                else if (widget.event.output != null)
                  const Icon(Icons.check_circle, size: 11, color: Colors.green)
                else
                  const Icon(Icons.error, size: 11, color: Colors.red),
                if (widget.event.durationMs != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${widget.event.durationMs}ms',
                    style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 9),
                  ),
                ],
                if (widget.event.tokensIn != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '↑${widget.event.tokensIn} ↓${widget.event.tokensOut ?? 0}',
                    style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 9),
                  ),
                ],
                const SizedBox(width: 6),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 12, color: ThemeConstants.textSecondary),
              ],
            ),
          ),
        ),
        // ── Expanded section ───────────────────────────────────────────────
        if (_expanded)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF131313),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
              border: Border.all(color: ThemeConstants.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.event.input.isNotEmpty) ...[
                  const Text(
                    'INPUT',
                    style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 9, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  for (final entry in widget.event.input.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: const TextStyle(
                              color: ThemeConstants.textSecondary,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${entry.value}',
                              style: const TextStyle(
                                color: ThemeConstants.textPrimary,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                if (widget.event.output != null) ...[
                  const Text(
                    'OUTPUT',
                    style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 9, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  _ExpandableOutput(text: widget.event.output!),
                  const SizedBox(height: 8),
                ],
                if (widget.event.durationMs != null)
                  Row(
                    children: [
                      Text(
                        '${widget.event.durationMs}ms',
                        style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 9),
                      ),
                      if (widget.event.tokensIn != null) ...[
                        const Text(' · ', style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 9)),
                        Text(
                          '↑${widget.event.tokensIn} ↓${widget.event.tokensOut ?? 0} tokens',
                          style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 9),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpandableOutput extends StatefulWidget {
  const _ExpandableOutput({required this.text});
  final String text;

  @override
  State<_ExpandableOutput> createState() => _ExpandableOutputState();
}

class _ExpandableOutputState extends State<_ExpandableOutput> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.text.split('\n');
    final truncated = !_showAll && lines.length > 5;
    final visible = truncated ? lines.take(5).join('\n') : widget.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          visible,
          style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 10, fontFamily: 'monospace'),
        ),
        if (truncated)
          GestureDetector(
            onTap: () => setState(() => _showAll = true),
            child: const Text('Show more…', style: TextStyle(color: Color(0xFF4A7CFF), fontSize: 10)),
          ),
      ],
    );
  }
}
