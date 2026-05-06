import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/shared/session_settings.dart';
import '../../../data/shared/chat_message.dart';
import '../../../data/session/models/tool_event.dart';
import '../notifiers/chat_notifier.dart';

/// Collapsible in-message tool-call log.
///
/// Reads [ToolEvent]s from [chatMessagesProvider] for [sessionId]/[messageId]
/// rather than maintaining a parallel WorkLogNotifier — [ToolEvent] is the
/// single source of truth for tool status.
///
/// Also handles the pre-tool "WORKING…" state shown in [ChatMode.act] sessions
/// while the agent is thinking before its first tool call.
class WorkLogSection extends ConsumerStatefulWidget {
  const WorkLogSection({super.key, required this.sessionId, required this.messageId});

  final String sessionId;
  final String messageId;

  @override
  ConsumerState<WorkLogSection> createState() => _WorkLogSectionState();
}

class _WorkLogSectionState extends ConsumerState<WorkLogSection> with SingleTickerProviderStateMixin {
  Timer? _ticker;

  /// Accumulated "work time" in seconds. Incremented on each ticker fire
  /// while the work log is active and deliberately *not* reset on running→
  /// idle transitions: the displayed counter reflects total seconds the
  /// agent has been actively working on this message across bursts.
  ///
  /// Using an integer counter (rather than `DateTime.now()` minus a
  /// start time) keeps the value deterministic under `tester.pump` —
  /// Flutter's fake async advances `Timer` callbacks but not the system
  /// wall clock, so wall-clock deltas are untestable in widget tests.
  int _elapsedSeconds = 0;
  bool _isExpanded = false;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Idempotent ticker lifecycle management, driven from [build]. Starts
  /// a 1Hz rebuild ticker when active, cancels it when inactive.
  void _syncTicker({required bool active}) {
    if (active) {
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
    final (toolEvents, isStreaming) = ref.watch(
      chatMessagesProvider(widget.sessionId).select((async) {
        final messages = async.asData?.value ?? const <ChatMessage>[];
        final msg = messages.firstWhereOrNull((m) => m.id == widget.messageId);
        return (msg?.toolEvents ?? const <ToolEvent>[], msg?.isStreaming ?? false);
      }),
    );

    if (toolEvents.isEmpty) {
      _syncTicker(active: isStreaming);
      if (!isStreaming) return const SizedBox.shrink();
      final isActMode = ref.watch(sessionModeProvider) == ChatMode.act;
      if (!isActMode) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.blueAccent)),
            const SizedBox(width: 6),
            FadeTransition(
              opacity: Tween<double>(
                begin: 0.4,
                end: 1.0,
              ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)),
              child: Text(
                'WORKING\u2026',
                style: TextStyle(color: c.blueAccent, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Icon(AppIcons.clock, size: 9, color: c.textSecondary),
            const SizedBox(width: 3),
            Text('${_elapsedSeconds}s', style: TextStyle(color: c.textSecondary, fontSize: 9)),
          ],
        ),
      );
    }

    final anyRunning = toolEvents.any((e) => e.status == ToolStatus.running);
    _syncTicker(active: anyRunning);

    final elapsedSeconds = _elapsedSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                Icon(AppIcons.clock, size: 9, color: c.textSecondary),
                const SizedBox(width: 3),
                Text('${elapsedSeconds}s', style: TextStyle(color: c.textSecondary, fontSize: 9)),
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
