import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/chat_message.dart';
import 'apply_code_dialog.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _isUser
          ? ThemeConstants.userMessageBg
          : ThemeConstants.assistantMessageBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: _isUser
                  ? ThemeConstants.accent.withAlpha(180)
                  : ThemeConstants.success.withAlpha(180),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _isUser ? Icons.person : Icons.smart_toy,
              size: 16,
              color: Colors.white,
            ),
          ),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isUser ? 'You' : 'Assistant',
                      style: const TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (message.isStreaming) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                _MessageContent(message: message, ref: ref),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          fontSize: 13,
          height: 1.5,
        ),
      );
    }

    // Assistant messages: render as markdown
    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: 13,
          height: 1.5,
        ),
        code: const TextStyle(
          fontFamily: ThemeConstants.editorFontFamily,
          backgroundColor: ThemeConstants.codeBlockBg,
          color: ThemeConstants.syntaxString,
          fontSize: 12,
        ),
        codeblockDecoration: BoxDecoration(
          color: ThemeConstants.codeBlockBg,
          borderRadius: BorderRadius.circular(6),
        ),
        h1: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold),
        h2: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold),
        h3: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold),
        blockquote:
            const TextStyle(color: ThemeConstants.textSecondary),
        listBullet:
            const TextStyle(color: ThemeConstants.textPrimary),
      ),
      builders: {
        'code': _CodeBlockBuilder(ref: ref),
      },
    );
  }
}

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
      // Inline code
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
            fontSize: 12,
          ),
        ),
      );
    }

    return _CodeBlockWidget(code: code, language: language, ref: ref);
  }
}

class _CodeBlockWidget extends StatefulWidget {
  const _CodeBlockWidget({
    required this.code,
    required this.language,
    required this.ref,
  });

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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ThemeConstants.borderColor),
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.language,
                  style: const TextStyle(
                    color: ThemeConstants.textMuted,
                    fontSize: 11,
                    fontFamily: ThemeConstants.editorFontFamily,
                  ),
                ),
                const Spacer(),
                // Apply button
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
                            ? Icons.hourglass_empty
                            : Icons.file_download_outlined,
                        size: 13,
                        color: ThemeConstants.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _applying ? 'Applying...' : 'Apply',
                        style: const TextStyle(
                          color: ThemeConstants.textMuted,
                          fontSize: 11,
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
          // Code
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
            _copied ? Icons.check : Icons.copy,
            size: 13,
            color: ThemeConstants.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            _copied ? 'Copied' : 'Copy',
            style: const TextStyle(
              color: ThemeConstants.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
