import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/shared/chat_message.dart';
import '../../../data/session/models/tool_event.dart';
import '../notifiers/chat_notifier.dart';

/// Collapsible in-message tool-call log.
///
/// Reads [ToolEvent]s from [chatMessagesProvider] for [sessionId]/[messageId]
/// rather than maintaining a parallel WorkLogNotifier — [ToolEvent] is the
/// single source of truth for tool status.
class WorkLogSection extends ConsumerStatefulWidget {
  const WorkLogSection({super.key, required this.sessionId, required this.messageId});

  final String sessionId;
  final String messageId;

  @override
  ConsumerState<WorkLogSection> createState() => _WorkLogSectionState();
}

class _WorkLogSectionState extends ConsumerState<WorkLogSection> {
  Timer? _ticker;

  /// Accumulated "work time" in seconds. Incremented on each ticker fire
  /// while a tool is running and deliberately *not* reset on running→
  /// idle transitions: the displayed counter reflects total seconds the
  /// agent has been actively working on this message across bursts,
  /// which matches the long-running UX this section is meant to show.
  ///
  /// Using an integer counter (rather than `DateTime.now()` minus a
  /// start time) keeps the value deterministic under `tester.pump` —
  /// Flutter's fake async advances `Timer` callbacks but not the system
  /// wall clock, so wall-clock deltas are untestable in widget tests.
  int _elapsedSeconds = 0;
  bool _isExpanded = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Idempotent ticker lifecycle management, driven from [build]. Starts
  /// a 1Hz rebuild ticker when any event flips to running, cancels it
  /// when none are running. Called on every rebuild so a running→idle→
  /// running sequence (multi-tool turn) reliably restarts the ticker —
  /// the earlier `initState`-only version silently froze the counter
  /// after the first tool completed.
  void _syncTicker({required bool anyRunning}) {
    if (anyRunning) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsedSeconds++);
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Watch the tool events for this specific message. `select` trims
    // rebuilds to changes in this message's toolEvents only — and uses
    // firstWhereOrNull so a missing message just produces an empty list
    // without the exception-swallowing try/catch we used to rely on.
    final toolEvents = ref.watch(
      chatMessagesProvider(widget.sessionId).select((async) {
        final messages = async.asData?.value ?? const <ChatMessage>[];
        return messages.firstWhereOrNull((m) => m.id == widget.messageId)?.toolEvents ?? const <ToolEvent>[];
      }),
    );

    if (toolEvents.isEmpty) return const SizedBox.shrink();

    final anyRunning = toolEvents.any((e) => e.status == ToolStatus.running);
    _syncTicker(anyRunning: anyRunning);

    final elapsedSeconds = _elapsedSeconds;

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
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: c.blueAccent),
                  )
                else
                  Icon(Icons.check_circle, size: 11, color: c.success),
                const SizedBox(width: 6),
                Text(
                  'WORK LOG',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text('⏱ ${elapsedSeconds}s', style: TextStyle(color: c.textSecondary, fontSize: 9)),
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 12,
                  color: c.textSecondary,
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
              color: c.sidebarBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: c.borderColor),
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
                  ToolStatus.running => c.blueAccent,
                  ToolStatus.success => c.success,
                  ToolStatus.error => c.error,
                  ToolStatus.cancelled => c.dimFg,
                };
                final arg =
                    entry.filePath ??
                    (entry.input.isNotEmpty && entry.input.values.first is String
                        ? entry.input.values.first as String
                        : null);
                return Padding(
                  key: ValueKey('work-log-${entry.id}'),
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(icon, style: TextStyle(color: iconColor, fontSize: 10)),
                      const SizedBox(width: 6),
                      Text(
                        entry.toolName,
                        style: TextStyle(color: c.textPrimary, fontSize: 10, fontFamily: 'monospace'),
                      ),
                      if (arg != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            arg,
                            style: TextStyle(color: c.textSecondary, fontSize: 9, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      if (entry.durationMs != null)
                        Text('${entry.durationMs}ms', style: TextStyle(color: c.textSecondary, fontSize: 9)),
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
