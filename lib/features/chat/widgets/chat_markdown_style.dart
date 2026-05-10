import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import 'code_block_widget.dart';

MarkdownStyleSheet buildChatMarkdownStyleSheet(BuildContext context) {
  final c = AppColors.of(context);
  return MarkdownStyleSheet(
    p: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSize, height: 1.65),
    code: TextStyle(
      fontFamily: ThemeConstants.editorFontFamily,
      backgroundColor: c.inlineCodeFill,
      color: c.inlineCodeText,
      fontSize: ThemeConstants.uiFontSizeSmall,
    ),
    codeblockDecoration: BoxDecoration(
      color: c.codeBlockBg,
      border: Border.all(color: c.subtleBorder),
      borderRadius: BorderRadius.circular(7),
    ),
    h1: TextStyle(color: c.headingText, fontSize: ThemeConstants.markdownH1FontSize, fontWeight: FontWeight.bold),
    h2: TextStyle(color: c.headingText, fontSize: ThemeConstants.markdownH2FontSize, fontWeight: FontWeight.bold),
    h3: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.markdownH3FontSize, fontWeight: FontWeight.w600),
    h4: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSize, fontWeight: FontWeight.w600),
    h5: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
    h6: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
    a: TextStyle(color: c.accent, decoration: TextDecoration.underline, decorationColor: c.accent),
    blockquote: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSize, height: 1.65),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    blockquoteDecoration: BoxDecoration(
      color: c.panelBackground,
      border: Border(left: BorderSide(color: c.accent, width: 2)),
      borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
    ),
    listBullet: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSize),
    strong: TextStyle(color: c.headingText, fontWeight: FontWeight.bold),
    em: const TextStyle(fontStyle: FontStyle.italic),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: c.subtleBorder)),
    ),
  );
}

Map<String, MarkdownElementBuilder> buildChatMarkdownBuilders({
  required BuildContext context,
  required String messageId,
  required String sessionId,
  bool routeMarkdownToDocPanel = true,
}) {
  final c = AppColors.of(context);
  return {
    'code': CodeBlockBuilder(
      messageId: messageId,
      sessionId: sessionId,
      routeMarkdownToDocPanel: routeMarkdownToDocPanel,
    ),
    'h1': HeadingBuilder(
      style: TextStyle(color: c.headingText, fontSize: ThemeConstants.markdownH1FontSize, fontWeight: FontWeight.bold),
      borderColor: c.subtleBorder,
    ),
    'h2': HeadingBuilder(
      style: TextStyle(color: c.headingText, fontSize: ThemeConstants.markdownH2FontSize, fontWeight: FontWeight.bold),
      borderColor: c.subtleBorder,
    ),
  };
}

class HeadingBuilder extends MarkdownElementBuilder {
  HeadingBuilder({required this.style, required this.borderColor});
  final TextStyle style;
  final Color borderColor;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Text(element.textContent, style: style),
    );
  }
}
