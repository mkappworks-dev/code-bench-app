import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../notifiers/chat_notifier.dart';

/// Inline banner shown below a capped assistant bubble. [isActive] controls
/// whether the `[Continue]` button is enabled. The dismissal rule lives in
/// the caller: active when the capped message is the most recent in the
/// session, otherwise dismissed.
class IterationCapBanner extends ConsumerWidget {
  const IterationCapBanner({super.key, required this.messageId, required this.sessionId, required this.isActive});

  final String messageId;
  final String sessionId;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final borderColor = isActive ? c.warning.withValues(alpha: 0.4) : c.borderColor;
    final bgColor = isActive ? c.warning.withValues(alpha: 0.07) : c.inputSurface.withValues(alpha: 0.02);
    final iconColor = isActive ? c.warning : c.textMuted;
    final titleColor = isActive ? c.warning : c.textMuted;
    final subColor = isActive ? c.textSecondary : c.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pause_circle_outline, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paused at 10-step limit.',
                  style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive ? 'Run 10 more steps, or send a new message to redirect.' : 'Continued via new message.',
                  style: TextStyle(color: subColor, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isActive
                ? () => ref.read(chatMessagesProvider(sessionId).notifier).continueAgenticTurn(messageId)
                : null,
            style: TextButton.styleFrom(
              foregroundColor: isActive ? c.warning : c.textMuted,
              backgroundColor: isActive ? c.warning.withValues(alpha: 0.12) : Colors.transparent,
              side: BorderSide(color: isActive ? c.warning.withValues(alpha: 0.4) : c.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
