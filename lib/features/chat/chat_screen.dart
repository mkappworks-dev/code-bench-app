import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_session.dart';
import '../../services/session/session_service.dart';
import 'chat_notifier.dart';
import 'widgets/message_list.dart';
import 'widgets/chat_input_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  Future<void> _initSession() async {
    if (widget.sessionId != null) {
      ref.read(activeSessionIdProvider.notifier).set(widget.sessionId);
    } else {
      final service = ref.read(sessionServiceProvider);
      final model = ref.read(selectedModelProvider);
      final sessionId = await service.createSession(model: model);
      ref.read(activeSessionIdProvider.notifier).set(sessionId);
      if (mounted) context.go('/chat/$sessionId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = ref.watch(activeSessionIdProvider);

    if (sessionId == null) {
      return const Scaffold(
        backgroundColor: ThemeConstants.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Column(
        children: [
          _ChatHeader(sessionId: sessionId),
          const Divider(height: 1),
          _SystemPromptBar(sessionId: sessionId),
          Expanded(child: MessageList(sessionId: sessionId)),
          ChatInputBar(sessionId: sessionId),
        ],
      ),
    );
  }
}

class _SystemPromptBar extends ConsumerStatefulWidget {
  const _SystemPromptBar({required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<_SystemPromptBar> createState() => _SystemPromptBarState();
}

class _SystemPromptBarState extends ConsumerState<_SystemPromptBar> {
  bool _expanded = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(sessionSystemPromptProvider)[widget.sessionId];
    _controller = TextEditingController(text: existing ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: ThemeConstants.sidebarBackground,
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 12,
                  color: ThemeConstants.textMuted,
                ),
                const SizedBox(width: 6),
                const Text(
                  'System Prompt',
                  style: TextStyle(
                    color: ThemeConstants.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                if ((ref.watch(sessionSystemPromptProvider)[widget.sessionId] ?? '').isNotEmpty)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ThemeConstants.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: ThemeConstants.inputBackground,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 12,
                      fontFamily: ThemeConstants.editorFontFamily,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Set a system prompt for this session (e.g. "Reply only in JSON")',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      ref
                          .read(sessionSystemPromptProvider.notifier)
                          .setPrompt(widget.sessionId, value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _controller.clear();
                    ref
                        .read(sessionSystemPromptProvider.notifier)
                        .setPrompt(widget.sessionId, '');
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

class _ChatHeader extends ConsumerWidget {
  const _ChatHeader({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(selectedModelProvider);
    final sessions = ref.watch(chatSessionsProvider);

    final sessionTitle = sessions.whenOrNull(
          data: (List<ChatSession> list) {
            try {
              return list.firstWhere((s) => s.sessionId == sessionId).title;
            } catch (_) {
              return 'New Chat';
            }
          },
        ) ??
        'New Chat';

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: ThemeConstants.sidebarBackground,
      child: Row(
        children: [
          Text(
            sessionTitle,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          // Compare button
          TextButton.icon(
            onPressed: () => context.go('/compare'),
            icon: const Icon(Icons.compare, size: 13),
            label: const Text('Compare', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
              foregroundColor: ThemeConstants.textMuted,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          // Model selector
          _ModelSelector(currentModel: model),
        ],
      ),
    );
  }
}

class _ModelSelector extends ConsumerWidget {
  const _ModelSelector({required this.currentModel});

  final AIModel currentModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = AIModels.defaults;

    return PopupMenuButton<AIModel>(
      onSelected: (m) => ref.read(selectedModelProvider.notifier).select(m),
      color: ThemeConstants.sidebarBackground,
      itemBuilder: (_) => models
          .map((m) => PopupMenuItem(
                value: m,
                child: Text(
                  '${m.provider.displayName} / ${m.name}',
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: ThemeConstants.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentModel.name,
              style: const TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more,
                size: 14, color: ThemeConstants.textMuted),
          ],
        ),
      ),
    );
  }
}
