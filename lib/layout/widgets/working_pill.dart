import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../notifiers/working_pill_notifier.dart';

/// Status-bar pill that shows "Working for Xs" while the agent runs tool
/// calls for the given [sessionId] / [messageId].
///
/// [workingPillRunningProvider] handles the running detection and only
/// triggers a rebuild when the running status flips, so the elapsed-second
/// timer below is not reset by unrelated message updates.
///
/// Using an integer counter (rather than `DateTime.now()` minus a start
/// time) keeps [_elapsedSeconds] deterministic under `tester.pump` —
/// Flutter's fake async advances `Timer` callbacks but not the system
/// wall clock.
class WorkingPill extends ConsumerStatefulWidget {
  const WorkingPill({super.key, required this.sessionId, required this.messageId});

  final String sessionId;
  final String messageId;

  @override
  ConsumerState<WorkingPill> createState() => _WorkingPillState();
}

class _WorkingPillState extends ConsumerState<WorkingPill> {
  Timer? _ticker;
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Idempotent ticker lifecycle, driven from [build]. Starts a 1 Hz timer
  /// on the first running observation; cancels it on the running→idle
  /// transition. Each running→idle transition also zeroes [_elapsedSeconds]
  /// so the next burst's "Working for Xs" pill starts fresh.
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
    final anyRunning = ref.watch(workingPillRunningProvider(widget.sessionId, widget.messageId));

    _syncTicker(anyRunning: anyRunning);

    if (!anyRunning) return const SizedBox.shrink();

    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.selectionBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.selectionBorder),
      ),
      child: Text('Working for ${_elapsedSeconds}s', style: TextStyle(color: c.blueAccent, fontSize: 10)),
    );
  }
}
