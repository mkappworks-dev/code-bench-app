import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import 'chat_markdown_style.dart';

class MarkdownDocPanel extends StatefulWidget {
  const MarkdownDocPanel({
    super.key,
    required this.rawSource,
    required this.messageId,
    required this.sessionId,
    this.filename,
  });

  final String rawSource;
  final String? filename;
  final String messageId;
  final String sessionId;

  @override
  State<MarkdownDocPanel> createState() => _MarkdownDocPanelState();
}

class _MarkdownDocPanelState extends State<MarkdownDocPanel> {
  bool _copied = false;

  Future<void> _copyRaw() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.rawSource));
      if (!mounted) return;
      setState(() => _copied = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _copied = false);
    } catch (e) {
      dLog('[clipboard] doc-panel copy failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: c.userBubbleFill,
        border: Border.all(color: c.subtleBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
            child: Row(
              children: [
                Icon(AppIcons.document, size: 12, color: c.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.filename ?? 'markdown',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                      fontFamily: ThemeConstants.editorFontFamily,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _copyRaw,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_copied ? AppIcons.check : AppIcons.copy, size: 12, color: c.accent),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied' : 'Copy raw',
                        style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeSmall),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: c.subtleBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: MarkdownBody(
              data: widget.rawSource,
              styleSheet: buildChatMarkdownStyleSheet(context),
              builders: buildChatMarkdownBuilders(
                context: context,
                messageId: widget.messageId,
                sessionId: widget.sessionId,
                routeMarkdownToDocPanel: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
