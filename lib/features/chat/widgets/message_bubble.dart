import 'dart:io';

import 'package:collection/collection.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/project.dart';
import '../../../features/project_sidebar/project_sidebar_notifier.dart';
import '../../../services/apply/apply_service.dart';
import '../chat_notifier.dart';

// ── Public helper (also used by tests) ───────────────────────────────────────

/// Maximum filename length accepted from a code fence info string.
/// Prevents DoS via megabyte-long filename headers and matches the
/// common POSIX/Windows PATH_MAX ballpark.
const int _kMaxFilenameLength = 260;

/// Splits a code fence info string (e.g. "dart lib/main.dart") into
/// (language, filename?). Filename is null if no second word is present.
///
/// The filename is **untrusted AI input** and is validated here:
/// rejects empty, absolute paths, null bytes, control characters,
/// line breaks, and paths longer than [_kMaxFilenameLength]. Invalid
/// filenames are dropped (treated as no filename) rather than raising,
/// so the Diff button simply does not appear.
(String language, String? filename) parseCodeFenceInfo(String info) {
  final parts = info.trim().split(RegExp(r'\s+'));
  final language = parts.first;
  if (parts.length < 2) return (language, null);

  // Whitespace (including \n, \r, \t) is stripped by the \s+ split, so we
  // only need to guard against null-byte injection, over-length, and
  // absolute paths that would bypass the project-root join.
  final candidate = parts.sublist(1).join(' ');
  if (candidate.isEmpty ||
      candidate.length > _kMaxFilenameLength ||
      candidate.contains('\u0000') ||
      p.isAbsolute(candidate)) {
    return (language, null);
  }
  return (language, candidate);
}

// ── MessageBubble ─────────────────────────────────────────────────────────────

class MessageBubble extends ConsumerWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _isUser ? _UserBubble(message: message) : _AssistantBubble(message: message, ref: ref),
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

class _StreamingDotState extends State<StreamingDot> with SingleTickerProviderStateMixin {
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

// ── Message content ───────────────────────────────────────────────────────────

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
      builders: {
        'code': _CodeBlockBuilder(
          ref: ref,
          messageId: message.id,
          sessionId: message.sessionId,
        ),
      },
    );
  }
}

// ── Code block builder ───────────────────────────────────────────────────────

class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({
    required this.ref,
    required this.messageId,
    required this.sessionId,
  });
  final WidgetRef ref;
  final String messageId;
  final String sessionId;

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final fullInfo = element.attributes['class']?.replaceFirst('language-', '') ?? 'plaintext';
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

    final (language, filename) = parseCodeFenceInfo(fullInfo);
    return _CodeBlockWidget(
      code: code,
      language: language,
      filename: filename,
      messageId: messageId,
      sessionId: sessionId,
    );
  }
}

// ── Code block widget ─────────────────────────────────────────────────────────

enum _DiffCardState { hidden, loading, loaded, error }

class _CodeBlockWidget extends ConsumerStatefulWidget {
  const _CodeBlockWidget({
    required this.code,
    required this.language,
    this.filename,
    required this.messageId,
    required this.sessionId,
  });
  final String code;
  final String language;
  final String? filename;
  final String messageId;
  final String sessionId;

  @override
  ConsumerState<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends ConsumerState<_CodeBlockWidget> {
  _DiffCardState _diffState = _DiffCardState.hidden;
  String? _originalContent;
  List<Diff>? _diffs;
  String? _diffError;
  int _activeTab = 1; // 0=Before, 1=Diff, 2=After
  bool _applying = false;

  Project? _resolveActiveProject() {
    final projectId = ref.read(activeProjectIdProvider);
    final projects = ref.read(projectsProvider).valueOrNull ?? <Project>[];
    return projects.firstWhereOrNull((p) => p.id == projectId);
  }

  Future<void> _loadDiff() async {
    setState(() => _diffState = _DiffCardState.loading);
    try {
      final project = _resolveActiveProject();
      if (project == null) throw Exception('No active project');

      final absolutePath = p.join(project.path, widget.filename!);
      ApplyService.assertWithinProject(absolutePath, project.path);

      String? original;
      final file = File(absolutePath);
      if (file.existsSync()) {
        original = await file.readAsString();
      }

      final dmp = DiffMatchPatch();
      final diffs = dmp.diff(original ?? '', widget.code);
      dmp.diffCleanupSemantic(diffs);

      setState(() {
        _originalContent = original;
        _diffs = diffs;
        _diffState = _DiffCardState.loaded;
      });
    } catch (e) {
      setState(() {
        _diffError = e.toString();
        _diffState = _DiffCardState.error;
      });
    }
  }

  Future<void> _applyChange() async {
    setState(() => _applying = true);
    try {
      final project = _resolveActiveProject();
      if (project == null) throw Exception('Active project not found');

      final absolutePath = p.join(project.path, widget.filename!);
      ApplyService.assertWithinProject(absolutePath, project.path);
      await ref.read(applyServiceProvider).applyChange(
            filePath: absolutePath,
            projectPath: project.path,
            newContent: widget.code,
            sessionId: widget.sessionId,
            messageId: widget.messageId,
          );

      // Auto-open the changes panel on first apply
      ref.read(changesPanelVisibleProvider.notifier).show();

      setState(() => _diffState = _DiffCardState.hidden);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apply failed: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

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
          _buildHeader(),
          if (_diffState == _DiffCardState.loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            )
          else if (_diffState == _DiffCardState.loaded)
            _buildDiffCard()
          else if (_diffState == _DiffCardState.error)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _diffError ?? 'Error computing diff',
                style: const TextStyle(
                  color: ThemeConstants.error,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
              ),
            )
          else
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
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
          if (widget.filename != null) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.filename!,
                style: const TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  fontFamily: ThemeConstants.editorFontFamily,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          if (widget.filename != null && _diffState == _DiffCardState.hidden)
            _HeaderButton(
              label: 'Diff',
              icon: LucideIcons.gitCompare,
              onTap: _loadDiff,
            ),
          if (_diffState == _DiffCardState.loaded) ...[
            _HeaderButton(
              label: _applying ? 'Applying...' : 'Apply',
              icon: _applying ? LucideIcons.hourglass : LucideIcons.download,
              onTap: _applying ? null : _applyChange,
            ),
            const SizedBox(width: 8),
            _HeaderButton(
              label: 'Collapse',
              icon: LucideIcons.chevronUp,
              onTap: () => setState(() {
                _diffState = _DiffCardState.hidden;
                _activeTab = 1;
              }),
            ),
          ],
          const SizedBox(width: 12),
          _CopyButton(code: widget.code),
        ],
      ),
    );
  }

  Widget _buildDiffCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab bar
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
          ),
          child: Row(
            children: [
              _Tab(label: 'Before', index: 0, activeIndex: _activeTab, onTap: (i) => setState(() => _activeTab = i)),
              _Tab(label: 'Diff', index: 1, activeIndex: _activeTab, onTap: (i) => setState(() => _activeTab = i)),
              _Tab(label: 'After', index: 2, activeIndex: _activeTab, onTap: (i) => setState(() => _activeTab = i)),
            ],
          ),
        ),
        // Tab content
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: SingleChildScrollView(
            child: _activeTab == 0
                ? _buildPlainContent(_originalContent ?? '(new file)')
                : _activeTab == 2
                    ? _buildPlainContent(widget.code)
                    : _buildDiffContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlainContent(String content) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: HighlightView(
        content,
        language: widget.language,
        theme: vs2015Theme,
        padding: const EdgeInsets.all(12),
        textStyle: const TextStyle(
          fontFamily: ThemeConstants.editorFontFamily,
          fontSize: ThemeConstants.editorFontSize,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildDiffContent() {
    final diffs = _diffs ?? [];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: diffs.map((diff) {
            final bg = diff.operation == DIFF_INSERT
                ? const Color(0x3300CC66)
                : diff.operation == DIFF_DELETE
                    ? const Color(0x33FF4444)
                    : Colors.transparent;
            final prefix = diff.operation == DIFF_INSERT
                ? '+'
                : diff.operation == DIFF_DELETE
                    ? '−'
                    : ' ';
            return Container(
              color: bg,
              child: Text(
                diff.text.split('\n').map((line) => '$prefix $line').join('\n'),
                style: const TextStyle(
                  fontFamily: ThemeConstants.editorFontFamily,
                  fontSize: ThemeConstants.editorFontSize,
                  color: ThemeConstants.textPrimary,
                  height: 1.5,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Small reusable header button ─────────────────────────────────────────────

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ThemeConstants.mutedFg),
          const SizedBox(width: 4),
          Text(
            label,
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

// ── Tab ───────────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.index,
    required this.activeIndex,
    required this.onTap,
  });
  final String label;
  final int index;
  final int activeIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == activeIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? ThemeConstants.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: ThemeConstants.uiFontSizeSmall,
            color: isActive ? ThemeConstants.textPrimary : ThemeConstants.mutedFg,
          ),
        ),
      ),
    );
  }
}

// ── Copy button ───────────────────────────────────────────────────────────────

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
