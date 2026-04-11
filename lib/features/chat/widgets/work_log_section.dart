import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/tool_event.dart';
import '../chat_notifier.dart';

/// Collapsible in-message tool-call log.
///
/// Reads [ToolEvent]s from [chatProvider] for [sessionId]/[messageId] rather
/// than maintaining a parallel WorkLogNotifier — [ToolEvent] is the single
/// source of truth after Phase 10 added explicit [ToolStatus].
class WorkLogSection extends ConsumerStatefulWidget {
  const WorkLogSection({super.key, required this.sessionId, required this.messageId});

  final String sessionId;
  final String messageId;

  @override
  ConsumerState<WorkLogSection> createState() => _WorkLogSectionState();
}

class _WorkLogSectionState extends ConsumerState<WorkLogSection> {
  Timer? _tickTimer;
  int _elapsedSeconds = 0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final events = _toolEvents();
      final anyRunning = events.any((e) => e.status == ToolStatus.running);
      if (!anyRunning) {
        _tickTimer?.cancel();
        return;
      }
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  List<ToolEvent> _toolEvents() {
    final messages = ref.read(chatMessagesProvider(widget.sessionId)).asData?.value ?? [];
    try {
      return messages.firstWhere((m) => m.id == widget.messageId).toolEvents;
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the tool events for this specific message. The select trims
    // rebuilds to changes in this message's toolEvents only.
    final toolEvents = ref.watch(
      chatMessagesProvider(widget.sessionId).select((async) {
        final messages = async.asData?.value ?? [];
        try {
          return messages.firstWhere((m) => m.id == widget.messageId).toolEvents;
        } catch (_) {
          return const <ToolEvent>[];
        }
      }),
    );

    if (toolEvents.isEmpty) return const SizedBox.shrink();

    final anyRunning = toolEvents.any((e) => e.status == ToolStatus.running);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Toggle row ─────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                if (anyRunning)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF4A7CFF)),
                  )
                else
                  const Icon(Icons.check_circle, size: 11, color: Colors.green),
                const SizedBox(width: 6),
                const Text(
                  'WORK LOG',
                  style: TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text('⏱ ${_elapsedSeconds}s', style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 9)),
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 12,
                  color: ThemeConstants.textSecondary,
                ),
              ],
            ),
          ),
        ),
        // ── Expanded log entries ────────────────────────────────────────────
        if (_isExpanded)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ThemeConstants.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: toolEvents.map((entry) {
                final String icon = switch (entry.status) {
                  ToolStatus.running => '⚡',
                  ToolStatus.success => '✓',
                  ToolStatus.error => '✗',
                  ToolStatus.cancelled => '⊘',
                };
                final Color iconColor = switch (entry.status) {
                  ToolStatus.running => const Color(0xFF4A7CFF),
                  ToolStatus.success => Colors.green,
                  ToolStatus.error => Colors.red,
                  ToolStatus.cancelled => const Color(0xFF888888),
                };
                final arg =
                    entry.filePath ??
                    (entry.input.isNotEmpty && entry.input.values.first is String
                        ? entry.input.values.first as String
                        : null);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(icon, style: TextStyle(color: iconColor, fontSize: 10)),
                      const SizedBox(width: 6),
                      Text(
                        entry.toolName,
                        style: const TextStyle(
                          color: ThemeConstants.textPrimary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (arg != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            arg,
                            style: const TextStyle(
                              color: ThemeConstants.textSecondary,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      if (entry.durationMs != null)
                        Text(
                          '${entry.durationMs}ms',
                          style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 9),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
