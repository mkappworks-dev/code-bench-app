import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/shared/chat_message.dart';
import '../notifiers/chat_messages_actions.dart';
import '../notifiers/chat_messages_failure.dart';
import '../notifiers/chat_notifier.dart';
import 'message_bubble.dart';

const _pageSize = 50;
const _maxInMemory = 100;

class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // ListView is reversed so scroll position at maxExtent = top of chat = oldest messages
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final messages = ref.read(chatMessagesProvider(widget.sessionId)).value;
    if (messages == null) return;
    if (messages.length < _pageSize) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() => _loadingMore = true);
    final offset = messages.length;
    await ref.read(chatMessagesActionsProvider.notifier).loadMore(widget.sessionId, offset);
    if (!mounted) return;
    final actionState = ref.read(chatMessagesActionsProvider);
    if (actionState.hasError && actionState.error is ChatMessagesFailure) {
      showErrorSnackBar(context, 'Couldn\'t load older messages.');
      setState(() => _loadingMore = false);
      return;
    }
    final updated = ref.read(chatMessagesProvider(widget.sessionId)).value;
    if (updated != null) {
      // No more to load: short page returned, OR in-memory cap hit.
      final shortPage = updated.length - messages.length < _pageSize;
      final overCap = updated.length > _maxInMemory;
      if (shortPage || overCap) _hasMore = false;
    }
    setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.sessionId));

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => _ErrorState(error: userMessage(e, fallback: 'Could not load messages.')),
      data: (messages) {
        if (messages.isEmpty) return const _EmptyChat();

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: messages.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Last item (index = messages.length) when reversed = top = load indicator
            if (index == messages.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final msg = messages[messages.length - 1 - index];
            final effectiveLastIdx = messages.lastIndexWhere((m) => m.role != MessageRole.interrupted);
            final isLast = effectiveLastIdx >= 0 && index == messages.length - 1 - effectiveLastIdx;
            return MessageBubble(message: msg, sessionId: widget.sessionId, isLast: isLast, key: ValueKey(msg.id));
          },
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: c.error, size: 40),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: c.textMuted.withAlpha(100)),
          const SizedBox(height: 16),
          Text('Start a conversation', style: TextStyle(color: c.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Ask anything about your code', style: TextStyle(color: c.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
