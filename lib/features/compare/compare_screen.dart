import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart';
import '../../features/chat/widgets/message_bubble.dart';
import '../../services/session/session_service.dart';

// ---------------------------------------------------------------------------
// Providers for the two comparison panes
// ---------------------------------------------------------------------------

@immutable
class _ComparePaneId {
  const _ComparePaneId(this.slot);
  final int slot; // 0 = left, 1 = right
  @override
  bool operator ==(Object other) =>
      other is _ComparePaneId && other.slot == slot;
  @override
  int get hashCode => slot.hashCode;
}

final _comparePaneModelProvider = StateProvider.family<AIModel, _ComparePaneId>(
  (ref, id) {
    return id.slot == 0 ? AIModels.gpt4o : AIModels.claude35Sonnet;
  },
);

final _comparePaneSessionProvider =
    StateProvider.family<String?, _ComparePaneId>((ref, id) => null);

final _comparePaneMessagesProvider =
    StateProvider.family<List<ChatMessage>, _ComparePaneId>(
  (ref, id) => const [],
);

// ---------------------------------------------------------------------------
// Compare Screen
// ---------------------------------------------------------------------------

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<String> _ensureSession(_ComparePaneId paneId) async {
    var sessionId = ref.read(_comparePaneSessionProvider(paneId));
    if (sessionId == null) {
      final model = ref.read(_comparePaneModelProvider(paneId));
      final service = ref.read(sessionServiceProvider);
      sessionId = await service.createSession(
        model: model,
        title: 'Compare ${paneId.slot == 0 ? 'A' : 'B'}',
      );
      ref.read(_comparePaneSessionProvider(paneId).notifier).state = sessionId;
    }
    return sessionId;
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputController.clear();
    setState(() => _isSending = true);

    try {
      final leftId = const _ComparePaneId(0);
      final rightId = const _ComparePaneId(1);

      // Ensure sessions exist
      final leftSession = await _ensureSession(leftId);
      final rightSession = await _ensureSession(rightId);

      // Send to both panes concurrently
      await Future.wait([
        _streamToPane(leftId, leftSession, text),
        _streamToPane(rightId, rightSession, text),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
      _focusNode.requestFocus();
    }
  }

  Future<void> _streamToPane(
    _ComparePaneId paneId,
    String sessionId,
    String input,
  ) async {
    final model = ref.read(_comparePaneModelProvider(paneId));
    final sessionService = ref.read(sessionServiceProvider);

    await for (final msg in sessionService.sendAndStream(
      sessionId: sessionId,
      userInput: input,
      model: model,
    )) {
      if (mounted) {
        final current = ref.read(_comparePaneMessagesProvider(paneId));
        final idx = current.indexWhere((m) => m.id == msg.id);
        if (idx >= 0) {
          final updated = List<ChatMessage>.from(current);
          updated[idx] = msg;
          ref.read(_comparePaneMessagesProvider(paneId).notifier).state =
              updated;
        } else {
          ref.read(_comparePaneMessagesProvider(paneId).notifier).state = [
            ...current,
            msg,
          ];
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Column(
        children: [
          // Header
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: ThemeConstants.sidebarBackground,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  onPressed: () => context.go('/chat/new'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: ThemeConstants.textMuted,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Model Comparison',
                  style: TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Split panes
          Expanded(
            child: Row(
              children: [
                Expanded(child: _ComparePane(paneId: const _ComparePaneId(0))),
                const VerticalDivider(width: 1),
                Expanded(child: _ComparePane(paneId: const _ComparePaneId(1))),
              ],
            ),
          ),

          // Shared input
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12),
            color: ThemeConstants.sidebarBackground,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _send();
                      }
                    },
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 1,
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Send to both models... (Enter to send)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual comparison pane
// ---------------------------------------------------------------------------

class _ComparePane extends ConsumerWidget {
  const _ComparePane({required this.paneId});

  final _ComparePaneId paneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(_comparePaneModelProvider(paneId));
    final messages = ref.watch(_comparePaneMessagesProvider(paneId));
    final models = AIModels.defaults;

    return Column(
      children: [
        // Pane header with model selector
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: ThemeConstants.inputBackground,
          child: Row(
            children: [
              Text(
                paneId.slot == 0 ? 'Model A' : 'Model B',
                style: const TextStyle(
                  color: ThemeConstants.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<AIModel>(
                onSelected: (m) => ref
                    .read(_comparePaneModelProvider(paneId).notifier)
                    .state = m,
                color: ThemeConstants.sidebarBackground,
                itemBuilder: (_) => models
                    .map(
                      (m) => PopupMenuItem(
                        value: m,
                        child: Text(
                          '${m.provider.displayName} / ${m.name}',
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: ThemeConstants.borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${model.provider.displayName} / ${model.name}',
                        style: const TextStyle(
                          color: ThemeConstants.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more,
                        size: 12,
                        color: ThemeConstants.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (messages.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref
                        .read(_comparePaneMessagesProvider(paneId).notifier)
                        .state = [];
                    ref
                        .read(_comparePaneSessionProvider(paneId).notifier)
                        .state = null;
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Messages
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    'Send a message below to compare\n${model.provider.displayName} / ${model.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ThemeConstants.textMuted,
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: messages.length,
                  itemBuilder: (context, i) =>
                      MessageBubble(message: messages[i]),
                ),
        ),
      ],
    );
  }
}
