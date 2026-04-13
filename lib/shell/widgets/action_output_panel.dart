import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../notifiers/action_output_notifier.dart';

class ActionOutputPanel extends ConsumerWidget {
  const ActionOutputPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(actionOutputProvider);
    if (state.status == ActionStatus.idle) return const SizedBox.shrink();

    final statusLabel = switch (state.status) {
      ActionStatus.running => '● Running',
      ActionStatus.done => '✓ Done (exit 0)',
      ActionStatus.failed => '✗ Failed (exit ${state.exitCode})',
      ActionStatus.idle => '',
    };

    final statusColor = switch (state.status) {
      ActionStatus.running => ThemeConstants.info,
      ActionStatus.done => ThemeConstants.success,
      ActionStatus.failed => ThemeConstants.error,
      ActionStatus.idle => ThemeConstants.textSecondary,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      decoration: BoxDecoration(
        color: ThemeConstants.codeBlockBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ThemeConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  state.actionName ?? 'Action',
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: ThemeConstants.uiFontSizeLabel),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => ref.read(actionOutputProvider.notifier).clear(),
                  child: const Icon(Icons.close, size: 14, color: ThemeConstants.textSecondary),
                ),
              ],
            ),
          ),
          // Scrollable output
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.lines.length,
              itemBuilder: (_, i) => Text(
                state.lines[i],
                style: const TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  fontFamily: ThemeConstants.editorFontFamily,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
