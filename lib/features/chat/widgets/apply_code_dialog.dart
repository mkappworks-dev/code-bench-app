import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../features/editor/editor_notifier.dart';

/// Shows a before/after diff dialog and applies the AI code to the active file.
Future<void> showApplyCodeDialog(
  BuildContext context,
  WidgetRef ref,
  String newCode,
  String language,
) async {
  final activePath = ref.read(activeFilePathProvider);
  final tabs = ref.read(editorTabsProvider);

  if (activePath == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No active file to apply code to. Open a file first.'),
        backgroundColor: ThemeConstants.warning,
      ),
    );
    return;
  }

  final activeFile = tabs.cast<OpenFile?>().firstWhere(
        (f) => f?.path == activePath,
        orElse: () => null,
      );

  if (activeFile == null || activeFile.isReadOnly) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot apply code: file is read-only or not found.'),
        backgroundColor: ThemeConstants.error,
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ApplyDiffDialog(
      fileName: activeFile.displayName,
      before: activeFile.content,
      after: newCode,
      language: language,
    ),
  );

  if (confirmed == true) {
    ref.read(editorTabsProvider.notifier).updateContent(activePath, newCode);
    // Save to disk if local file
    if (!activePath.startsWith('[')) {
      await ref.read(saveFileProvider(activePath).future);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code applied to file'),
          backgroundColor: ThemeConstants.success,
        ),
      );
    }
  }
}

class _ApplyDiffDialog extends StatelessWidget {
  const _ApplyDiffDialog({
    required this.fileName,
    required this.before,
    required this.after,
    required this.language,
  });

  final String fileName;
  final String before;
  final String after;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeConstants.sidebarBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ThemeConstants.borderColor),
      ),
      child: SizedBox(
        width: 900,
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  const Icon(
                    Icons.difference_outlined,
                    size: 18,
                    color: ThemeConstants.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Apply AI Code to $fileName',
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.of(context).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      maxWidth: 24,
                      maxHeight: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Before / After panels
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Before
                    Expanded(
                      child: _CodePanel(
                        label: 'Before',
                        code: before,
                        language: language,
                        headerColor: ThemeConstants.error.withAlpha(40),
                        headerTextColor: ThemeConstants.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // After
                    Expanded(
                      child: _CodePanel(
                        label: 'After (AI)',
                        code: after,
                        language: language,
                        headerColor: ThemeConstants.success.withAlpha(40),
                        headerTextColor: ThemeConstants.success,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  const _CodePanel({
    required this.label,
    required this.code,
    required this.language,
    required this.headerColor,
    required this.headerTextColor,
  });

  final String label;
  final String code;
  final String language;
  final Color headerColor;
  final Color headerTextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              border: const Border(
                bottom: BorderSide(color: ThemeConstants.borderColor),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: headerTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: ThemeConstants.editorFontFamily,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HighlightView(
                  code.isEmpty ? '(empty)' : code,
                  language: language,
                  theme: vs2015Theme,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(
                    fontFamily: ThemeConstants.editorFontFamily,
                    fontSize: ThemeConstants.editorFontSize,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
