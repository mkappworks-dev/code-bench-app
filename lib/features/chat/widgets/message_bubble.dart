import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/shared/chat_message.dart';
import '../notifiers/ask_question_notifier.dart';
import '../notifiers/chat_messages_actions.dart';
import '../notifiers/chat_messages_failure.dart';
import '../notifiers/chat_notifier.dart';
import '../../../core/constants/app_icons.dart';
import 'ask_user_question_card.dart';
import 'code_block_widget.dart';
import 'streaming_dot.dart';
import 'tool_call_row.dart';
import 'work_log_section.dart';

export 'code_block_widget.dart' show CodeBlockBuilder;
export '../utils/code_fence_parser.dart' show parseCodeFenceInfo;
export 'streaming_dot.dart' show StreamingDot;

// ── MessageBubble ─────────────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.sessionId, this.isLast = false});

  final ChatMessage message;
  final String sessionId;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: switch (message.role) {
        MessageRole.user => _UserBubble(message: message, sessionId: sessionId, isLast: isLast),
        MessageRole.interrupted => const _InterruptedBubble(),
        _ => _AssistantBubble(message: message),
      },
    );
  }
}

// ── User bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends ConsumerStatefulWidget {
  const _UserBubble({required this.message, required this.sessionId, required this.isLast});

  final ChatMessage message;
  final String sessionId;
  final bool isLast;

  @override
  ConsumerState<_UserBubble> createState() => _UserBubbleState();
}

class _UserBubbleState extends ConsumerState<_UserBubble> {
  bool _hovered = false;

  /// Inline-checked delete (per CLAUDE.md Rule 2 exception): N user bubbles can
  /// share the `chatMessagesActionsProvider`, so a `ref.listen` fires once per
  /// instance and would yield N snackbars. Awaiting the action and reading
  /// `hasError` inline keeps a single snackbar for the bubble that triggered it.
  Future<void> _delete() async {
    await ref.read(chatMessagesActionsProvider.notifier).deleteMessage(widget.sessionId, widget.message.id);
    if (!mounted) return;
    final actionState = ref.read(chatMessagesActionsProvider);
    if (actionState.hasError && actionState.error is ChatMessagesFailure) {
      showErrorSnackBar(context, 'Failed to delete message.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isSending = ref.watch(activeMessageIdProvider) != null;
    final showActions = widget.isLast && _hovered && !isSending;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showActions) ...[
              _BubbleActionButton(icon: AppIcons.trash, tooltip: 'Delete', color: c.warning, onTap: _delete),
              const SizedBox(width: 6),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: c.userBubbleFill,
                  border: Border.all(color: c.userBubbleStroke),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(color: c.userBubbleHighlight, blurRadius: 0, offset: const Offset(0, 1))],
                ),
                child: SelectableText(
                  widget.message.content,
                  style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSize, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleActionButton extends StatelessWidget {
  const _BubbleActionButton({required this.icon, required this.tooltip, required this.color, required this.onTap});

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: c.panelBackground,
            border: Border.all(color: c.subtleBorder),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 12, color: color),
        ),
      ),
    );
  }
}

// ── Interrupted badge ────────────────────────────────────────────────────────

class _InterruptedBubble extends StatelessWidget {
  const _InterruptedBubble();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.panelBackground,
          border: Border.all(color: c.subtleBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.stop, size: 11, color: c.warning),
            const SizedBox(width: 4),
            Text(
              'Interrupted',
              style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assistant bubble ─────────────────────────────────────────────────────────

class _AssistantBubble extends ConsumerWidget {
  const _AssistantBubble({required this.message});
  final ChatMessage message;

  /// Formats the answer map produced by [AskUserQuestionCard] into a
  /// plain user-message string and re-posts it via [chatMessagesProvider].
  void _submitAnswer(WidgetRef ref, Map<String, dynamic> answer) {
    final parts = <String>[];
    final selected = answer['selectedOption'];
    final freeText = answer['freeText'];
    if (selected is String && selected.isNotEmpty) parts.add(selected);
    if (freeText is String && freeText.isNotEmpty) parts.add(freeText);
    if (parts.isEmpty) return;
    unawaited(ref.read(chatMessagesProvider(message.sessionId).notifier).sendMessage(parts.join('\n\n')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 2, margin: const EdgeInsets.only(top: 3, bottom: 3), color: AppColors.of(context).borderColor),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isStreaming) const StreamingDot(),
              _MessageContent(message: message),
              if (message.toolEvents.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final event in message.toolEvents)
                  Padding(
                    key: ValueKey('tool-row-${event.id}'),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ToolCallRow(event: event),
                  ),
              ],
              if (message.toolEvents.isNotEmpty) ...[
                const SizedBox(height: 4),
                WorkLogSection(sessionId: message.sessionId, messageId: message.id),
              ],
              if (message.askQuestion != null) ...[
                const SizedBox(height: 8),
                AskUserQuestionCard(
                  question: message.askQuestion!,
                  sessionId: message.sessionId,
                  onSubmit: (answer) => _submitAnswer(ref, answer),
                  onBack: message.askQuestion!.stepIndex > 0
                      ? () => ref
                            .read(askQuestionProvider.notifier)
                            .setAnswer(
                              sessionId: message.sessionId,
                              stepIndex: message.askQuestion!.stepIndex,
                              selectedOption: null,
                              freeText: null,
                            )
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Message content ───────────────────────────────────────────────────────────

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (message.role == MessageRole.user) {
      return SelectableText(
        message.content,
        style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSize, height: 1.5),
      );
    }
    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSize, height: 1.65),
        code: TextStyle(
          fontFamily: ThemeConstants.editorFontFamily,
          backgroundColor: c.inlineCodeFill,
          color: c.inlineCodeText,
          fontSize: ThemeConstants.uiFontSizeSmall,
        ),
        codeblockDecoration: BoxDecoration(
          color: c.codeBlockBg,
          border: Border.all(color: c.subtleBorder),
          borderRadius: BorderRadius.circular(7),
        ),
        h1: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        h2: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        h3: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        blockquote: TextStyle(color: c.textSecondary),
        listBullet: TextStyle(color: c.textPrimary),
      ),
      builders: {'code': CodeBlockBuilder(messageId: message.id, sessionId: message.sessionId)},
    );
  }
}
