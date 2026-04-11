import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_icons.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/project.dart';
import '../../data/models/tool_event.dart';
import '../../features/chat/chat_notifier.dart';
import '../../features/project_sidebar/project_sidebar_notifier.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(activeProjectIdProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);
    final panelVisible = ref.watch(changesPanelVisibleProvider);

    Project? activeProject;
    if (projectId != null) {
      activeProject = projectsAsync.whenOrNull(data: (list) => list.firstWhereOrNull((p) => p.id == projectId));
    }

    // Count changes for the current session (watch unconditionally — Riverpod rule)
    final allChanges = ref.watch(appliedChangesProvider);
    final changeCount = activeSessionId != null ? (allChanges[activeSessionId]?.length ?? 0) : 0;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: ThemeConstants.activityBar,
        border: Border(top: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: Row(
        children: [
          // Left: Local indicator
          Icon(AppIcons.storage, size: 10, color: ThemeConstants.faintFg),
          const SizedBox(width: 5),
          Text(
            'Local',
            style: const TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
          const Spacer(),
          // Working pill — shown while the agent is running tool calls.
          Consumer(
            builder: (context, ref, child) {
              final sessionId = ref.watch(activeSessionIdProvider);
              if (sessionId == null) return const SizedBox.shrink();
              final messageId = ref.watch(activeMessageIdProvider);
              if (messageId == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _WorkingPill(sessionId: sessionId, messageId: messageId),
              );
            },
          ),
          // Centre-right: N changes indicator (hidden when 0)
          if (changeCount > 0) ...[
            GestureDetector(
              onTap: () => ref.read(changesPanelVisibleProvider.notifier).toggle(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: panelVisible ? ThemeConstants.accent : ThemeConstants.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$changeCount ${changeCount == 1 ? 'change' : 'changes'}',
                    style: TextStyle(
                      color: panelVisible ? ThemeConstants.accent : ThemeConstants.warning,
                      fontSize: ThemeConstants.uiFontSizeLabel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Right: Git branch
          if (activeProject != null && activeProject.isGit) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: ThemeConstants.success, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              activeProject.currentBranch ?? 'unknown',
              style: const TextStyle(color: ThemeConstants.success, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          ] else if (activeProject != null) ...[
            Text(
              'Not git',
              style: const TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Status bar pill that shows "Working for Xs" while the agent runs tool calls.
///
/// Watches [chatMessagesProvider] for [sessionId] and checks whether the
/// message with [messageId] has any [ToolStatus.running] events, avoiding
/// a parallel WorkLogNotifier after Phase 10 landed.
class _WorkingPill extends ConsumerStatefulWidget {
  const _WorkingPill({required this.sessionId, required this.messageId});

  final String sessionId;
  final String messageId;

  @override
  ConsumerState<_WorkingPill> createState() => _WorkingPillState();
}

class _WorkingPillState extends ConsumerState<_WorkingPill> {
  Timer? _ticker;

  /// Seconds elapsed in the current running burst. Incremented on each
  /// ticker fire, reset to 0 on every running→idle transition so the
  /// next burst's "Working for Xs" pill starts fresh — each tool call
  /// is its own timer. Using an integer counter (rather than
  /// `DateTime.now()` minus a start time) keeps the value deterministic
  /// under `tester.pump` — Flutter's fake async advances `Timer`
  /// callbacks but not the system wall clock.
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Idempotent ticker lifecycle, driven from [build]. Starts a 1Hz
  /// rebuild ticker on the first running observation, cancels it when
  /// none are running. A running→idle transition also zeroes
  /// [_elapsedSeconds] so the next burst starts fresh at 0s — matches
  /// the "Working for Xs" UX: each burst is its own timer.
  void _syncTicker({required bool anyRunning}) {
    if (anyRunning) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsedSeconds++);
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
      _elapsedSeconds = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final anyRunning = ref.watch(
      chatMessagesProvider(widget.sessionId).select((async) {
        final messages = async.asData?.value ?? const <ChatMessage>[];
        final msg = messages.firstWhereOrNull((m) => m.id == widget.messageId);
        return msg?.toolEvents.any((e) => e.status == ToolStatus.running) ?? false;
      }),
    );

    _syncTicker(anyRunning: anyRunning);

    if (!anyRunning) return const SizedBox.shrink();

    final seconds = _elapsedSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Text('Working for ${seconds}s', style: const TextStyle(color: Color(0xFF4A7CFF), fontSize: 10)),
    );
  }
}
