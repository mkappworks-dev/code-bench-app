import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/ai_model.dart';
import '../chat_notifier.dart';

class ChatInputBarV2 extends ConsumerStatefulWidget {
  const ChatInputBarV2({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ChatInputBarV2> createState() => _ChatInputBarV2State();
}

class _ChatInputBarV2State extends ConsumerState<ChatInputBarV2> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() => _isSending = true);

    try {
      final systemPrompt = ref.read(
        sessionSystemPromptProvider,
      )[widget.sessionId];
      await ref
          .read(chatMessagesProvider(widget.sessionId).notifier)
          .sendMessage(
            text,
            systemPrompt: (systemPrompt != null && systemPrompt.isNotEmpty)
                ? systemPrompt
                : null,
          );
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

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(selectedModelProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF222222)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text input
            KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  _send();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                style: const TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 12,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask anything, @tag files/folders, or use /command',
                  hintStyle: TextStyle(color: Color(0xFF444444), fontSize: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Controls row
            Container(
              padding: const EdgeInsets.only(top: 7),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
              ),
              child: Row(
                children: [
                  // Model selector
                  _ControlChip(
                    icon: Icons.bolt,
                    label: model.name,
                    onTap: () => _showModelPicker(context, ref),
                  ),
                  const _Separator(),
                  // Effort
                  _ControlChip(label: 'High', onTap: () {}),
                  const _Separator(),
                  // Mode
                  _ControlChip(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    onTap: () {},
                  ),
                  const _Separator(),
                  // Permissions
                  _ControlChip(
                    icon: Icons.lock_outline,
                    label: 'Full access',
                    onTap: () {},
                  ),
                  const Spacer(),
                  // Send button
                  GestureDetector(
                    onTap: _isSending ? null : _send,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: ThemeConstants.accent,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(BuildContext context, WidgetRef ref) {
    final models = AIModels.defaults;
    showMenu<AIModel>(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      color: const Color(0xFF1E1E1E),
      items: models
          .map(
            (m) => PopupMenuItem(
              value: m,
              child: Text(
                '${m.provider.displayName} / ${m.name}',
                style: const TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 11,
                ),
              ),
            ),
          )
          .toList(),
    ).then((selected) {
      if (selected != null) {
        ref.read(selectedModelProvider.notifier).select(selected);
      }
    });
  }
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: const Color(0xFF888888)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_drop_down,
              size: 10,
              color: Color(0xFF333333),
            ),
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        '|',
        style: TextStyle(color: Color(0xFF222222), fontSize: 11),
      ),
    );
  }
}
