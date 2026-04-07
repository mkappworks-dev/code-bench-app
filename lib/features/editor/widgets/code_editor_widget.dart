import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/styles/vs2015.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../services/session/session_service.dart';
import '../../chat/chat_notifier.dart';
import '../editor_notifier.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key, required this.file});

  final OpenFile file;

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeLineEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.file.content);
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _controller.dispose();
      _controller = CodeLineEditingController.fromText(widget.file.content);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveFile() async {
    if (widget.file.isReadOnly) return;
    ref
        .read(editorTabsProvider.notifier)
        .updateContent(widget.file.path, _controller.text);
    await ref.read(saveFileProvider(widget.file.path).future);
  }

  /// Returns selected text if any, otherwise the full file content.
  String _getContextContent() {
    try {
      final selected = _controller.selectedText;
      if (selected.isNotEmpty) return selected;
    } catch (_) {}
    return _controller.text;
  }

  bool _hasSelection() {
    try {
      return _controller.selectedText.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _askAI() async {
    final service = ref.read(sessionServiceProvider);
    final model = ref.read(selectedModelProvider);
    final contextContent = _getContextContent();
    final isSelection = _hasSelection();

    final sessionId = await service.createSession(
      model: model,
      title: 'About: ${widget.file.displayName}',
    );
    ref.read(activeSessionIdProvider.notifier).set(sessionId);

    final contextLabel = isSelection
        ? 'selected code from ${widget.file.displayName}'
        : widget.file.displayName;
    final systemPrompt =
        'The user is asking about the following $contextLabel:\n\n```${widget.file.language}\n$contextContent\n```';

    await ref
        .read(chatMessagesProvider(sessionId).notifier)
        .sendMessage('What does this code do?', systemPrompt: systemPrompt);

    if (mounted) context.go('/chat/$sessionId');
  }

  Future<void> _generateTests() async {
    final service = ref.read(sessionServiceProvider);
    final model = ref.read(selectedModelProvider);
    final content = _controller.text;

    final sessionId = await service.createSession(
      model: model,
      title: 'Tests: ${widget.file.displayName}',
    );
    ref.read(activeSessionIdProvider.notifier).set(sessionId);

    const systemPrompt =
        'You are an expert test engineer. Write comprehensive unit tests for the following code. '
        'Use idiomatic testing patterns for the language. Return only test code with no explanation.';

    await ref
        .read(chatMessagesProvider(sessionId).notifier)
        .sendMessage(
          '```${widget.file.language}\n$content\n```',
          systemPrompt: systemPrompt,
        );

    if (mounted) context.go('/chat/$sessionId');
  }

  Future<void> _reviewCode() async {
    final service = ref.read(sessionServiceProvider);
    final model = ref.read(selectedModelProvider);
    final content = _controller.text;

    final sessionId = await service.createSession(
      model: model,
      title: 'Review: ${widget.file.displayName}',
    );
    ref.read(activeSessionIdProvider.notifier).set(sessionId);

    const systemPrompt =
        'You are a senior code reviewer. Review the following code for: correctness, performance, '
        'security vulnerabilities, and style. Format your response with clear sections and actionable suggestions.';

    await ref
        .read(chatMessagesProvider(sessionId).notifier)
        .sendMessage(
          '```${widget.file.language}\n$content\n```',
          systemPrompt: systemPrompt,
        );

    if (mounted) context.go('/chat/$sessionId');
  }

  CodeHighlightTheme _buildTheme(String language) {
    final Mode? mode = switch (language) {
      'dart' => langDart,
      'javascript' => langJavascript,
      'typescript' => langTypescript,
      'python' => langPython,
      'go' => langGo,
      'rust' => langRust,
      'json' => langJson,
      'yaml' => langYaml,
      'markdown' => langMarkdown,
      'bash' => langBash,
      'xml' => langXml,
      _ => null,
    };

    return CodeHighlightTheme(
      languages: mode != null
          ? {language: CodeHighlightThemeMode(mode: mode)}
          : {},
      theme: vs2015Theme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        _EditorToolbar(
          fileName: widget.file.displayName,
          isDirty: widget.file.isDirty,
          isReadOnly: widget.file.isReadOnly,
          onSave: _saveFile,
          onAskAI: _askAI,
          onGenerateTests: _generateTests,
          onReview: _reviewCode,
        ),
        // Editor
        Expanded(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
                  _saveFile,
              const SingleActivator(LogicalKeyboardKey.keyS, control: true):
                  _saveFile,
            },
            child: Focus(
              child: CodeEditor(
                controller: _controller,
                onChanged: (_) {
                  if (!widget.file.isReadOnly) {
                    ref
                        .read(editorTabsProvider.notifier)
                        .updateContent(widget.file.path, _controller.text);
                  }
                },
                style: CodeEditorStyle(
                  fontFamily: ThemeConstants.editorFontFamily,
                  fontSize: ThemeConstants.editorFontSize,
                  backgroundColor: ThemeConstants.editorBackground,
                  textColor: ThemeConstants.textPrimary,
                  selectionColor: ThemeConstants.accent.withAlpha(80),
                  cursorColor: ThemeConstants.accent,
                  codeTheme: _buildTheme(widget.file.language),
                ),
                wordWrap: false,
                readOnly: widget.file.isReadOnly,
                hint: 'Start typing...',
                indicatorBuilder:
                    (context, editingController, chunkController, notifier) {
                      return Row(
                        children: [
                          DefaultCodeLineNumber(
                            controller: editingController,
                            notifier: notifier,
                            textStyle: const TextStyle(
                              color: ThemeConstants.editorGutterForeground,
                              fontSize: ThemeConstants.editorFontSize,
                              fontFamily: ThemeConstants.editorFontFamily,
                            ),
                          ),
                        ],
                      );
                    },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.fileName,
    required this.isDirty,
    required this.isReadOnly,
    required this.onSave,
    required this.onAskAI,
    required this.onGenerateTests,
    required this.onReview,
  });

  final String fileName;
  final bool isDirty;
  final bool isReadOnly;
  final VoidCallback onSave;
  final VoidCallback onAskAI;
  final VoidCallback onGenerateTests;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: ThemeConstants.sidebarBackground,
      child: Row(
        children: [
          Text(
            fileName,
            style: const TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 12,
            ),
          ),
          if (isDirty)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                '●',
                style: TextStyle(color: ThemeConstants.warning, fontSize: 10),
              ),
            ),
          if (isReadOnly)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ThemeConstants.inputBackground,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'READ ONLY',
                style: TextStyle(
                  color: ThemeConstants.textMuted,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          const Spacer(),
          if (!isReadOnly)
            TextButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined, size: 14),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.rate_review_outlined,
            label: 'Review',
            onPressed: onReview,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.science_outlined,
            label: 'Tests',
            onPressed: onGenerateTests,
          ),
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: onAskAI,
            icon: const Icon(Icons.smart_toy_outlined, size: 14),
            label: const Text('Ask AI'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: ThemeConstants.borderColor),
              foregroundColor: ThemeConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: ThemeConstants.textMuted,
      ),
    );
  }
}
