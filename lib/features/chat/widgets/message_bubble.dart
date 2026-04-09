import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/chat_message.dart';
import 'apply_code_dialog.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _isUser
          ? _UserBubble(message: message)
          : _AssistantBubble(message: message, ref: ref),
    );
  }
}

// ── User bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: ThemeConstants.userMessageBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            message.content,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: ThemeConstants.uiFontSize,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Assistant bubble ─────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message, required this.ref});
  final ChatMessage message;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left accent border
        Container(
          width: 2,
          margin: const EdgeInsets.only(top: 3, bottom: 3),
          color: ThemeConstants.borderColor,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isStreaming) const StreamingDot(),
              _MessageContent(message: message, ref: ref),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Streaming dot ────────────────────────────────────────────────────────────

class StreamingDot extends StatefulWidget {
  const StreamingDot({super.key});

  @override
  State<StreamingDot> createState() => _StreamingDotState();
}

class _StreamingDotState extends State<StreamingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: ThemeConstants.success,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Message content (shared markdown renderer) ───────────────────────────────

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message, required this.ref});
  final ChatMessage message;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (message.role == MessageRole.user) {
      return SelectableText(
        message.content,
        style: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: ThemeConstants.uiFontSize,
          height: 1.5,
        ),
      );
    }
    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: ThemeConstants.uiFontSize,
          height: 1.65,
        ),
        code: const TextStyle(
          fontFamily: ThemeConstants.editorFontFamily,
          backgroundColor: ThemeConstants.codeBlockBg,
          color: ThemeConstants.syntaxString,
          fontSize: ThemeConstants.uiFontSizeSmall,
        ),
        codeblockDecoration: BoxDecoration(
          color: ThemeConstants.codeBlockBg,
          borderRadius: BorderRadius.circular(6),
        ),
        h1: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h2: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        h3: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        blockquote: const TextStyle(color: ThemeConstants.textSecondary),
        listBullet: const TextStyle(color: ThemeConstants.textPrimary),
      ),
      builders: {'code': _CodeBlockBuilder(ref: ref)},
    );
  }
}

// ── Code block builder ───────────────────────────────────────────────────────

class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({required this.ref});
  final WidgetRef ref;

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final language =
        element.attributes['class']?.replaceFirst('language-', '') ??
            'plaintext';
    final code = element.textContent;

    if (!element.attributes.containsKey('class') && !code.contains('\n')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: ThemeConstants.codeBlockBg,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          code,
          style: const TextStyle(
            fontFamily: ThemeConstants.editorFontFamily,
            color: ThemeConstants.syntaxString,
            fontSize: ThemeConstants.uiFontSize,
          ),
        ),
      );
    }
    return _CodeBlockWidget(code: code, language: language, ref: ref);
  }
}

class _CodeBlockWidget extends StatefulWidget {
  const _CodeBlockWidget(
      {required this.code, required this.language, required this.ref});
  final String code;
  final String language;
  final WidgetRef ref;

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ThemeConstants.codeBlockBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ThemeConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  widget.language,
                  style: const TextStyle(
                    color: ThemeConstants.mutedFg,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    fontFamily: ThemeConstants.editorFontFamily,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _applying
                      ? null
                      : () async {
                          setState(() => _applying = true);
                          try {
                            await showApplyCodeDialog(
                              context,
                              widget.ref,
                              widget.code,
                              widget.language,
                            );
                          } finally {
                            if (mounted) setState(() => _applying = false);
                          }
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _applying
                            ? LucideIcons.hourglass
                            : LucideIcons.download,
                        size: 12,
                        color: ThemeConstants.mutedFg,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _applying ? 'Applying...' : 'Apply',
                        style: const TextStyle(
                          color: ThemeConstants.mutedFg,
                          fontSize: ThemeConstants.uiFontSizeSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _CopyButton(code: widget.code),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              widget.code,
              language: widget.language,
              theme: vs2015Theme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(
                fontFamily: ThemeConstants.editorFontFamily,
                fontSize: ThemeConstants.editorFontSize,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.code});
  final String code;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.code));
        setState(() => _copied = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _copied = false);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _copied ? LucideIcons.check : LucideIcons.copy,
            size: 12,
            color: ThemeConstants.mutedFg,
          ),
          const SizedBox(width: 4),
          Text(
            _copied ? 'Copied' : 'Copy',
            style: const TextStyle(
              color: ThemeConstants.mutedFg,
              fontSize: ThemeConstants.uiFontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}
