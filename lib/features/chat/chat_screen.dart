import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import 'notifiers/chat_notifier.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_list.dart';

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
      if (widget.sessionId != null) {
        ref.read(activeSessionIdProvider.notifier).set(widget.sessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = ref.watch(activeSessionIdProvider);

    if (sessionId == null) {
      return const Scaffold(
        backgroundColor: ThemeConstants.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: ThemeConstants.faintFg),
              SizedBox(height: 16),
              Text(
                'Select a project and start a conversation',
                style: TextStyle(color: ThemeConstants.mutedFg, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Column(
        children: [
          Expanded(child: MessageList(sessionId: sessionId)),
          ChatInputBar(sessionId: sessionId),
        ],
      ),
    );
  }
}
