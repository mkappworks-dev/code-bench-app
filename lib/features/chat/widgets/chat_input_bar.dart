import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../features/editor/editor_notifier.dart';
import '../chat_notifier.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  bool _isSending = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // rebuild for token count
    _handleAtMention();
  }

  void _handleAtMention() {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    if (cursor < 0) return;

    final before = text.substring(0, cursor);
    final atIndex = before.lastIndexOf('@');
    if (atIndex == -1) {
      _removeOverlay();
      return;
    }

    // Only show if '@' is at the start or after whitespace
    final charBefore = atIndex > 0 ? before[atIndex - 1] : ' ';
    if (charBefore != ' ' && charBefore != '\n') {
      _removeOverlay();
      return;
    }

    final query = before.substring(atIndex + 1).toLowerCase();
    final openFiles = ref.read(editorTabsProvider);
    final filtered = openFiles
        .where((f) => f.displayName.toLowerCase().contains(query))
        .toList();

    if (filtered.isEmpty) {
      _removeOverlay();
      return;
    }

    _showOverlay(filtered, atIndex);
  }

  void _showOverlay(List<OpenFile> files, int atIndex) {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -8),
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          child: Material(
            elevation: 6,
            color: ThemeConstants.sidebarBackground,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: ThemeConstants.borderColor),
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: files.length,
                itemBuilder: (context, i) {
                  final file = files[i];
                  return InkWell(
                    onTap: () => _selectFile(file, atIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined,
                              size: 13, color: ThemeConstants.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file.displayName,
                              style: const TextStyle(
                                color: ThemeConstants.textPrimary,
                                fontSize: 12,
                                fontFamily: ThemeConstants.editorFontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectFile(OpenFile file, int atIndex) {
    _removeOverlay();
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final before = text.substring(0, atIndex); // text before '@'
    final after = text.substring(cursor);
    final fileBlock =
        '\n```${file.language}\n// @${file.displayName}\n${file.content}\n```\n';
    final newText = before + fileBlock + after;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: before.length + fileBlock.length),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _removeOverlay();
    _controller.clear();
    setState(() => _isSending = true);

    try {
      final systemPrompt = ref.read(sessionSystemPromptProvider)[widget.sessionId];
      await ref.read(chatMessagesProvider(widget.sessionId).notifier).sendMessage(
            text,
            systemPrompt:
                (systemPrompt != null && systemPrompt.isNotEmpty) ? systemPrompt : null,
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

  int get _tokenEstimate => (_controller.text.length / 4).ceil();

  int _contextWindow() {
    final model = ref.read(selectedModelProvider);
    return model.contextWindow;
  }

  @override
  Widget build(BuildContext context) {
    final tokenCount = _tokenEstimate;
    final contextWindow = _contextWindow();
    final percentage = contextWindow > 0 ? tokenCount / contextWindow : 0.0;
    final isWarning = percentage >= 0.8;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: const BoxDecoration(
          color: ThemeConstants.sidebarBackground,
          border: Border(top: BorderSide(color: ThemeConstants.borderColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        minLines: 1,
                        style: const TextStyle(
                          color: ThemeConstants.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'Ask a question... (Enter to send, Shift+Enter for newline, @ to mention a file)',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendButton(isSending: _isSending, onSend: _send),
                ],
              ),
            ),
            // Token count footer
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Text(
                    '~$tokenCount tokens',
                    style: TextStyle(
                      color: isWarning
                          ? ThemeConstants.warning
                          : ThemeConstants.textMuted,
                      fontSize: 10,
                      fontFamily: ThemeConstants.editorFontFamily,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 60,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        backgroundColor: ThemeConstants.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isWarning
                              ? ThemeConstants.warning
                              : ThemeConstants.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}% of ${_formatK(contextWindow)}',
                    style: TextStyle(
                      color: isWarning
                          ? ThemeConstants.warning
                          : ThemeConstants.textMuted,
                      fontSize: 10,
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

  String _formatK(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(0)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isSending, required this.onSend});

  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: ElevatedButton(
        onPressed: isSending ? null : onSend,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: isSending
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send, size: 16),
      ),
    );
  }
}
