import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/shared/chat_message.dart';
import '../notifiers/chat_notifier.dart';
import '../notifiers/ask_question_notifier.dart';
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
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _isUser ? _UserBubble(message: message) : _AssistantBubble(message: message),
    );
  }
}

// ── User bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
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
            message.content,
            style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSize, height: 1.5),
          ),
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
    ref.listen(chatMessagesProvider(message.sessionId), (_, next) {
      if (next is! AsyncError || !context.mounted) return;
      showErrorSnackBar(context, 'Failed to send response. Please try again.');
    });
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
