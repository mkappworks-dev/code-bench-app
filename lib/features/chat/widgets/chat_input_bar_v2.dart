import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/ai_model.dart';
import '../chat_notifier.dart';

enum _Effort { low, medium, high, max }

enum _Mode { chat, plan, act }

enum _Permission { readOnly, askBefore, fullAccess }

extension _EffortLabel on _Effort {
  String get label => switch (this) {
        _Effort.low => 'Low',
        _Effort.medium => 'Medium',
        _Effort.high => 'High',
        _Effort.max => 'Max',
      };
}

extension _ModeLabel on _Mode {
  String get label => switch (this) {
        _Mode.chat => 'Chat',
        _Mode.plan => 'Plan',
        _Mode.act => 'Act',
      };
}

extension _PermissionLabel on _Permission {
  String get label => switch (this) {
        _Permission.readOnly => 'Read only',
        _Permission.askBefore => 'Ask before changes',
        _Permission.fullAccess => 'Full access',
      };
}

class ChatInputBarV2 extends ConsumerStatefulWidget {
  const ChatInputBarV2({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<ChatInputBarV2> createState() => _ChatInputBarV2State();
}

class _ChatInputBarV2State extends ConsumerState<ChatInputBarV2> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _keyboardFocusNode = FocusNode();
  bool _isSending = false;
  _Effort _effort = _Effort.high;
  _Mode _mode = _Mode.chat;
  _Permission _permission = _Permission.fullAccess;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    setState(() => _isSending = true);
    try {
      final systemPrompt =
          ref.read(sessionSystemPromptProvider)[widget.sessionId];
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
              backgroundColor: ThemeConstants.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _focusNode.requestFocus();
      }
    }
  }

  void _showDropdown<T>(
    BuildContext context,
    List<T> items,
    T selected,
    String Function(T) label,
    void Function(T) onSelect,
  ) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        0,
      ),
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      items: items
          .map((item) => PopupMenuItem<T>(
                value: item,
                height: 32,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label(item),
                        style: TextStyle(
                          color: item == selected
                              ? ThemeConstants.textPrimary
                              : ThemeConstants.textSecondary,
                          fontSize: ThemeConstants.uiFontSizeSmall,
                        ),
                      ),
                    ),
                    if (item == selected)
                      const Icon(LucideIcons.check,
                          size: 11, color: ThemeConstants.accent),
                  ],
                ),
              ))
          .toList(),
    ).then((value) {
      if (value != null) onSelect(value);
    });
  }

  void _showModelPicker(BuildContext context) {
    final models = AIModels.defaults;
    final selected = ref.read(selectedModelProvider);
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    showMenu<AIModel>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        0,
      ),
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      items: models
          .map((m) => PopupMenuItem<AIModel>(
                value: m,
                height: 32,
                child: Text(
                  '${m.provider.displayName} / ${m.name}',
                  style: TextStyle(
                    color: m == selected
                        ? ThemeConstants.textPrimary
                        : ThemeConstants.textSecondary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                ),
              ))
          .toList(),
    ).then((value) {
      if (value != null) ref.read(selectedModelProvider.notifier).select(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(selectedModelProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ThemeConstants.deepBorder)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeConstants.inputSurface,
          border: Border.all(color: ThemeConstants.deepBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyboardListener(
              focusNode: _keyboardFocusNode,
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
                  fontSize: ThemeConstants.uiFontSize,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask anything, @tag files/folders, or use /command',
                  hintStyle: TextStyle(
                      color: ThemeConstants.faintFg,
                      fontSize: ThemeConstants.uiFontSize),
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
            Container(
              padding: const EdgeInsets.only(top: 7),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: ThemeConstants.deepBorder)),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => _ControlChip(
                      icon: LucideIcons.zap,
                      label: model.name,
                      onTap: () => _showModelPicker(ctx),
                    ),
                  ),
                  const _Separator(),
                  Builder(
                    builder: (ctx) => _ControlChip(
                      label: _effort.label,
                      onTap: () => _showDropdown(
                        ctx,
                        _Effort.values,
                        _effort,
                        (e) => e.label,
                        (e) => setState(() => _effort = e),
                      ),
                    ),
                  ),
                  const _Separator(),
                  Builder(
                    builder: (ctx) => _ControlChip(
                      icon: LucideIcons.messageSquare,
                      label: _mode.label,
                      onTap: () => _showDropdown(
                        ctx,
                        _Mode.values,
                        _mode,
                        (m) => m.label,
                        (m) => setState(() => _mode = m),
                      ),
                    ),
                  ),
                  const _Separator(),
                  Builder(
                    builder: (ctx) => _ControlChip(
                      icon: LucideIcons.lock,
                      label: _permission.label,
                      onTap: () => _showDropdown(
                        ctx,
                        _Permission.values,
                        _permission,
                        (p) => p.label,
                        (p) => setState(() => _permission = p),
                      ),
                    ),
                  ),
                  const Spacer(),
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
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.arrowUp,
                              size: 14, color: Colors.white),
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
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({this.icon, required this.label, required this.onTap});
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
              Icon(icon, size: 11, color: ThemeConstants.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: const TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: ThemeConstants.uiFontSizeSmall)),
            const SizedBox(width: 3),
            const Icon(LucideIcons.chevronDown,
                size: 10, color: ThemeConstants.faintFg),
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
      child: Text('|',
          style: TextStyle(
              color: ThemeConstants.deepBorder,
              fontSize: ThemeConstants.uiFontSizeSmall)),
    );
  }
}
