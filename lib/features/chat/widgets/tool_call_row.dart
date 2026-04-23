import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/session/models/tool_event.dart';

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
    if (toolName.contains('/')) return Icons.extension_outlined;
    return switch (toolName) {
      'read_file' || 'read' => Icons.description_outlined,
      'write_file' || 'write' => Icons.edit_outlined,
      'run_command' || 'bash' => Icons.terminal,
      'search' || 'grep' => Icons.search,
      _ => Icons.build_outlined,
    };
  }

  String _displayName(String toolName) {
    if (!toolName.contains('/')) return toolName;
    final parts = toolName.split('/');
    return '${parts.first} › ${parts.skip(1).join('/')}';
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
    final c = AppColors.of(context);
    final arg = _primaryArg(widget.event);
    final status = widget.event.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Collapsed row ─────────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: status == ToolStatus.cancelled ? c.inputSurface.withValues(alpha: 0.5) : c.inputSurface,
              borderRadius: BorderRadius.circular(_expanded ? 0 : 6),
              border: Border.all(
                color: status == ToolStatus.cancelled ? c.borderColor.withValues(alpha: 0.5) : c.borderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _iconForTool(widget.event.toolName),
                  size: 13,
                  color: status == ToolStatus.cancelled ? c.dimFg : c.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _displayName(widget.event.toolName),
                  style: TextStyle(
                    color: status == ToolStatus.cancelled ? c.textMuted : c.textPrimary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                if (widget.event.source == ToolEventSource.cliTransport) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: c.accent.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Text('via Claude Code', style: TextStyle(fontSize: 10, color: c.accent, letterSpacing: 0.3)),
                  ),
                ],
                if (arg.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      arg,
                      style: TextStyle(
                        color: status == ToolStatus.cancelled ? c.dimFg : c.textSecondary,
                        fontSize: 10,
                        decoration: status == ToolStatus.cancelled ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: status == ToolStatus.cancelled ? c.dimFg : null,
                        decorationThickness: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                const SizedBox(width: 8),
                switch (status) {
                  ToolStatus.running => SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: c.blueAccent),
                  ),
                  ToolStatus.success => Icon(Icons.check_circle, size: 11, color: c.success),
                  ToolStatus.error => Tooltip(
                    message: widget.event.error ?? '${widget.event.toolName} — failed',
                    child: Icon(Icons.error, size: 11, color: c.error),
                  ),
                  ToolStatus.cancelled => Tooltip(
                    message: '${widget.event.toolName} — cancelled',
                    child: Icon(Icons.cancel_outlined, size: 11, color: c.dimFg),
                  ),
                },
                if (widget.event.durationMs != null) ...[
                  const SizedBox(width: 6),
                  Text('${widget.event.durationMs}ms', style: TextStyle(color: c.textSecondary, fontSize: 9)),
                ],
                if (widget.event.tokensIn != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '↑${widget.event.tokensIn} ↓${widget.event.tokensOut ?? 0}',
                    style: TextStyle(color: c.textSecondary, fontSize: 9),
                  ),
                ],
                const SizedBox(width: 6),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 12, color: c.textSecondary),
              ],
            ),
          ),
        ),
        // ── Expanded section ───────────────────────────────────────────────
        if (_expanded)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.sidebarBackground,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
              border: Border.all(color: c.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.event.input.isNotEmpty) ...[
                  Text('INPUT', style: TextStyle(color: c.textSecondary, fontSize: 9, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  for (final entry in widget.event.input.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: TextStyle(color: c.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                          ),
                          Expanded(
                            child: Text(
                              '${entry.value}',
                              style: TextStyle(color: c.textPrimary, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                if (widget.event.output != null) ...[
                  Text('OUTPUT', style: TextStyle(color: c.textSecondary, fontSize: 9, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  _ExpandableOutput(text: widget.event.output!),
                  const SizedBox(height: 8),
                ],
                if (widget.event.status == ToolStatus.error && widget.event.error != null) ...[
                  Text('ERROR', style: TextStyle(color: c.error, fontSize: 9, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    widget.event.error!,
                    style: TextStyle(color: c.textPrimary, fontSize: 10, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.event.durationMs != null)
                  Row(
                    children: [
                      Text('${widget.event.durationMs}ms', style: TextStyle(color: c.textSecondary, fontSize: 9)),
                      if (widget.event.tokensIn != null) ...[
                        Text(' · ', style: TextStyle(color: c.textSecondary, fontSize: 9)),
                        Text(
                          '↑${widget.event.tokensIn} ↓${widget.event.tokensOut ?? 0} tokens',
                          style: TextStyle(color: c.textSecondary, fontSize: 9),
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
    final c = AppColors.of(context);
    final lines = widget.text.split('\n');
    final truncated = !_showAll && lines.length > 5;
    final visible = truncated ? lines.take(5).join('\n') : widget.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          visible,
          style: TextStyle(color: c.textPrimary, fontSize: 10, fontFamily: 'monospace'),
        ),
        if (truncated)
          GestureDetector(
            onTap: () => setState(() => _showAll = true),
            child: Text('Show more…', style: TextStyle(color: c.blueAccent, fontSize: 10)),
          ),
      ],
    );
  }
}
