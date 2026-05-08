import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/ai/models/provider_setting_drop.dart';
import '../../../data/session/models/tool_event.dart';
import '../../../data/shared/chat_message.dart';
import '../notifiers/ask_question_notifier.dart';
import '../notifiers/chat_messages_actions.dart';
import '../notifiers/chat_messages_failure.dart';
import '../notifiers/chat_notifier.dart';
import '../notifiers/dropped_settings_notifier.dart';
import '../../../core/constants/app_icons.dart';
import '../utils/tool_phase_classifier.dart';
import 'ask_user_question_card.dart';
import 'code_block_widget.dart';
import 'iteration_cap_banner.dart';
import 'permission_request_card.dart';
import 'provider_label.dart';
import 'streaming_dot.dart';
import 'tool_call_row.dart';
import 'tool_phase_pill.dart';
import 'work_log_section.dart';

export 'code_block_widget.dart' show CodeBlockBuilder;
export '../utils/code_fence_parser.dart' show parseCodeFenceInfo;
export 'streaming_dot.dart' show StreamingDot;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
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
          // Anchor here so a silent downgrade isn't lost when the assistant turn fails before producing a message.
          _DroppedSettingsNotice(messageId: widget.message.id),
        ],
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

class _AssistantBubble extends ConsumerStatefulWidget {
  const _AssistantBubble({required this.message});
  final ChatMessage message;

  @override
  ConsumerState<_AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends ConsumerState<_AssistantBubble> {
  /// Formats the answer map produced by [AskUserQuestionCard] into a
  /// plain user-message string and re-posts it via [chatMessagesProvider].
  Future<void> _submitAnswer(Map<String, dynamic> answer) async {
    final parts = <String>[];
    final selected = answer['selectedOption'];
    final freeText = answer['freeText'];
    if (selected is String && selected.isNotEmpty) parts.add(selected);
    if (freeText is String && freeText.isNotEmpty) parts.add(freeText);
    if (parts.isEmpty) return;
    final err = await ref.read(chatMessagesProvider(widget.message.sessionId).notifier).sendMessage(parts.join('\n\n'));
    if (!mounted) return;
    if (err != null) showErrorSnackBar(context, 'Failed to send answer. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final allMessages = message.iterationCapReached
        ? (ref.watch(chatMessagesProvider(message.sessionId)).value ?? const <ChatMessage>[])
        : const <ChatMessage>[];
    final capIsActive = message.iterationCapReached && allMessages.isNotEmpty && allMessages.last.id == message.id;
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
              if (message.isStreaming || message.toolEvents.isNotEmpty) ...[
                const SizedBox(height: 4),
                WorkLogSection(sessionId: message.sessionId, messageId: message.id),
              ],
              if (message.toolEvents.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (final event in message.toolEvents)
                  Padding(
                    key: ValueKey('tool-row-${event.id}'),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ToolCallRow(
                      event: event,
                      providerId: message.providerId,
                      providerLabel: providerLabelFor(message.providerId),
                      modelLabel: message.modelId,
                    ),
                  ),
                if (message.isStreaming &&
                    !message.toolEvents.any((e) => e.status == ToolStatus.running) &&
                    message.content.isEmpty) ...[
                  const SizedBox(height: 8),
                  const _SkeletonLines(),
                ] else if (message.content.isNotEmpty)
                  const SizedBox(height: 8),
              ],
              _MessageContent(message: message),
              if (message.isStreaming) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [for (final p in _activePhases(message)) ToolPhasePill(phase: p.phase, label: p.label)],
                ),
              ],
              _DroppedSettingsNotice(messageId: message.id),
              _AssistantActionRow(message: message),
              if (message.iterationCapReached) ...[
                IterationCapBanner(messageId: message.id, sessionId: message.sessionId, isActive: capIsActive),
              ],
              if (message.pendingPermissionRequest != null) ...[
                PermissionRequestCard(request: message.pendingPermissionRequest!),
              ],
              if (message.askQuestion != null) ...[
                const SizedBox(height: 8),
                AskUserQuestionCard(
                  question: message.askQuestion!,
                  sessionId: message.sessionId,
                  onSubmit: _submitAnswer,
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

class _AssistantActionRow extends ConsumerStatefulWidget {
  const _AssistantActionRow({required this.message});
  final ChatMessage message;

  @override
  ConsumerState<_AssistantActionRow> createState() => _AssistantActionRowState();
}

class _AssistantActionRowState extends ConsumerState<_AssistantActionRow> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.message.content));
      if (!mounted) return;
      setState(() => _copied = true);
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() => _copied = false);
      });
    } on PlatformException catch (e) {
      dLog('[_AssistantActionRow] clipboard failed: $e');
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to copy. Please try again.');
    }
  }

  Future<void> _retry() async {
    await ref
        .read(chatMessagesActionsProvider.notifier)
        .retryAssistantMessage(widget.message.sessionId, widget.message.id);
    if (!mounted) return;
    final s = ref.read(chatMessagesActionsProvider);
    if (s.hasError && s.error is ChatMessagesFailure) {
      showErrorSnackBar(context, 'Failed to retry message.');
    }
  }

  Future<void> _delete() async {
    await ref
        .read(chatMessagesActionsProvider.notifier)
        .deleteAssistantMessage(widget.message.sessionId, widget.message.id);
    if (!mounted) return;
    final s = ref.read(chatMessagesActionsProvider);
    if (s.hasError && s.error is ChatMessagesFailure) {
      showErrorSnackBar(context, 'Failed to delete message.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isStreaming || widget.message.content.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final c = AppColors.of(context);
    final copyIcon = _copied ? AppIcons.check : AppIcons.copy;
    final copyColor = _copied ? c.success : c.textMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Copy as markdown',
            child: IconButton(
              icon: Icon(copyIcon, size: ThemeConstants.iconSizeSmall, color: copyColor),
              onPressed: _copy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              visualDensity: VisualDensity.compact,
              splashRadius: 14,
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Retry',
            child: IconButton(
              icon: Icon(AppIcons.refresh, size: ThemeConstants.iconSizeSmall, color: c.textMuted),
              onPressed: _retry,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              visualDensity: VisualDensity.compact,
              splashRadius: 14,
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Delete',
            child: IconButton(
              icon: Icon(AppIcons.trash, size: ThemeConstants.iconSizeSmall, color: c.textMuted),
              onPressed: _delete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              visualDensity: VisualDensity.compact,
              splashRadius: 14,
            ),
          ),
        ],
      ),
    );
  }
}

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
    return SelectionArea(
      child: MarkdownBody(
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
      ),
    );
  }
}

class _DroppedSettingsNotice extends ConsumerWidget {
  const _DroppedSettingsNotice({required this.messageId});
  final String messageId;

  String _label(ProviderSettingDrop drop) => switch (drop) {
    ProviderSettingDropMode(:final requested) =>
      '${requested.name} mode not supported on this transport — sent as chat',
    ProviderSettingDropEffort(:final requested, :final applied) =>
      applied != null ? 'Effort ${requested.name} → ${applied.name}' : 'Effort ${requested.name} dropped',
    ProviderSettingDropThinkingBudget(:final requestedTokens, :final appliedTokens) =>
      'Thinking budget clamped from $requestedTokens to $appliedTokens tokens',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drops = ref.watch(messageDroppedSettingsProvider)[messageId] ?? const <ProviderSettingDrop>[];
    if (drops.isEmpty) return const SizedBox.shrink();
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final drop in drops)
            Tooltip(
              message: drop.reason,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: c.panelBackground,
                  border: Border.all(color: c.subtleBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.warning, size: 10, color: c.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      _label(drop),
                      style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkeletonLines extends StatefulWidget {
  const _SkeletonLines();

  @override
  State<_SkeletonLines> createState() => _SkeletonLinesState();
}

class _SkeletonLinesState extends State<_SkeletonLines> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _opacity = Tween(begin: 0.3, end: 0.75).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return FadeTransition(
      opacity: _opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_line(c.borderColor, 0.88), const SizedBox(height: 7), _line(c.borderColor, 0.60)],
      ),
    );
  }

  Widget _line(Color color, double widthFactor) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    ),
  );
}

List<({PhaseClass phase, String label})> _activePhases(ChatMessage m) {
  if (!m.isStreaming) return const [];
  final out = <({PhaseClass phase, String label})>[];
  final running = m.toolEvents.where((e) => e.status == ToolStatus.running).toList();
  for (final e in running) {
    out.add((phase: classifyTool(e.toolName, null), label: _phaseLabelFor(e)));
  }
  if (running.isEmpty) {
    out.add((phase: PhaseClass.think, label: 'thinking'));
  }
  return out;
}

String _phaseLabelFor(ToolEvent e) {
  return switch (e.toolName.toLowerCase()) {
    'bash' => 'running ${_truncate(e.input["command"]?.toString() ?? "command", 24)}',
    'web_fetch' || 'webfetch' => 'fetching url',
    'read' || 'read_file' => 'reading ${_truncate(e.filePath ?? "file", 32)}',
    'write' || 'write_file' || 'edit' || 'str_replace' => 'editing ${_truncate(e.filePath ?? "file", 32)}',
    'glob' => 'finding files',
    'grep' => 'searching',
    _ => 'running ${e.toolName}',
  };
}

String _truncate(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}…';
