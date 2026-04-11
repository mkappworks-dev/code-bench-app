import 'dart:io';

import 'package:collection/collection.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/theme_constants.dart';
import '../../../core/utils/debug_logger.dart';
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

/// Regex matching Windows drive-letter paths (e.g. `C:\...`) and UNC
/// paths (`\\server\...`). Needed because `p.isAbsolute` on POSIX hosts
/// only recognises `/`-rooted paths.
final RegExp _windowsAbsoluteRe = RegExp(r'^([A-Za-z]:[/\\]|\\\\)');

bool _isWindowsAbsolute(String path) => _windowsAbsoluteRe.hasMatch(path);

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
  //
  // p.isAbsolute uses the host platform's context, so on macOS it misses
  // Windows drive-letter (C:\...) and UNC (\\server\...) paths. We check
  // those explicitly since AI-generated filenames can contain any syntax.
  final candidate = parts.sublist(1).join(' ');
  if (candidate.isEmpty ||
      candidate.length > _kMaxFilenameLength ||
      candidate.contains('\u0000') ||
      p.isAbsolute(candidate) ||
      _isWindowsAbsolute(candidate)) {
    return (language, null);
  }
  return (language, candidate);
}

// ── MessageBubble ─────────────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _isUser ? _UserBubble(message: message) : _AssistantBubble(message: message),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(color: ThemeConstants.userMessageBg, borderRadius: BorderRadius.circular(10)),
          child: SelectableText(
            message.content,
            style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize, height: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Assistant bubble ─────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 2, margin: const EdgeInsets.only(top: 3, bottom: 3), color: ThemeConstants.borderColor),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isStreaming) const StreamingDot(),
              _MessageContent(message: message),
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
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
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
          decoration: const BoxDecoration(color: ThemeConstants.success, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// ── Message content ───────────────────────────────────────────────────────────

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.role == MessageRole.user) {
      return SelectableText(
        message.content,
        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize, height: 1.5),
      );
    }
    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize, height: 1.65),
        code: const TextStyle(
          fontFamily: ThemeConstants.editorFontFamily,
          backgroundColor: ThemeConstants.codeBlockBg,
          color: ThemeConstants.syntaxString,
          fontSize: ThemeConstants.uiFontSizeSmall,
        ),
        codeblockDecoration: BoxDecoration(color: ThemeConstants.codeBlockBg, borderRadius: BorderRadius.circular(6)),
        h1: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        h2: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        h3: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        blockquote: const TextStyle(color: ThemeConstants.textSecondary),
        listBullet: const TextStyle(color: ThemeConstants.textPrimary),
      ),
      builders: {'code': _CodeBlockBuilder(messageId: message.id, sessionId: message.sessionId)},
    );
  }
}

// ── Code block builder ───────────────────────────────────────────────────────

class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({required this.messageId, required this.sessionId});
  final String messageId;
  final String sessionId;

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final fullInfo = element.attributes['class']?.replaceFirst('language-', '') ?? 'plaintext';
    final code = element.textContent;

    if (!element.attributes.containsKey('class') && !code.contains('\n')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(color: ThemeConstants.codeBlockBg, borderRadius: BorderRadius.circular(3)),
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
    final projects = ref.read(projectsProvider).value ?? <Project>[];
    return projects.firstWhereOrNull((p) => p.id == projectId);
  }

  Future<void> _loadDiff() async {
    final project = _resolveActiveProject();
    if (project == null) {
      setState(() {
        _diffError = 'No active project.';
        _diffState = _DiffCardState.error;
      });
      return;
    }

    setState(() => _diffState = _DiffCardState.loading);
    try {
      final absolutePath = p.join(project.path, widget.filename!);
      ApplyService.assertWithinProject(absolutePath, project.path);

      // TOCTOU-safe read: attempt the read directly and treat a missing
      // file as "new file" instead of stat-then-read.
      String? original;
      try {
        original = await File(absolutePath).readAsString();
      } on PathNotFoundException {
        original = null;
      }

      final dmp = DiffMatchPatch();
      final diffs = dmp.diff(original ?? '', widget.code);
      dmp.diffCleanupSemantic(diffs);

      if (!mounted) return;
      setState(() {
        _originalContent = original;
        _diffs = diffs;
        _diffState = _DiffCardState.loaded;
      });
    } on StateError catch (e) {
      // assertWithinProject rejection — a path-traversal attempt or a
      // guard-layer failure. Log with a security marker so it's grep-able.
      dLog('[security] _loadDiff path rejected: $e');
      if (!mounted) return;
      setState(() {
        _diffError = 'This file is outside the current project.';
        _diffState = _DiffCardState.error;
      });
    } on FileSystemException catch (e) {
      dLog('[_loadDiff] filesystem: $e');
      if (!mounted) return;
      setState(() {
        _diffError = 'Could not read file from disk.';
        _diffState = _DiffCardState.error;
      });
    } catch (e, st) {
      dLog('[_loadDiff] unexpected: $e\n$st');
      if (!mounted) return;
      setState(() {
        _diffError = 'Unable to compute diff.';
        _diffState = _DiffCardState.error;
      });
    }
  }

  Future<void> _applyChange() async {
    final project = _resolveActiveProject();
    if (project == null) {
      _showApplyError('No active project.');
      return;
    }

    setState(() => _applying = true);
    try {
      final absolutePath = p.join(project.path, widget.filename!);
      ApplyService.assertWithinProject(absolutePath, project.path);
      await ref
          .read(applyServiceProvider)
          .applyChange(
            filePath: absolutePath,
            projectPath: project.path,
            newContent: widget.code,
            sessionId: widget.sessionId,
            messageId: widget.messageId,
          );

      if (!mounted) return;
      // Auto-open the changes panel on first apply
      ref.read(changesPanelVisibleProvider.notifier).show();
      setState(() => _diffState = _DiffCardState.hidden);
    } on StateError catch (e) {
      dLog('[security] _applyChange path rejected: $e');
      _showApplyError('This file is outside the current project.');
    } on FileSystemException catch (e) {
      dLog('[_applyChange] filesystem: $e');
      _showApplyError('Could not write file to disk.');
    } catch (e, st) {
      dLog('[_applyChange] unexpected: $e\n$st');
      _showApplyError('Unable to apply change.');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _showApplyError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: ThemeConstants.error));
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
              child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))),
            )
          else if (_diffState == _DiffCardState.loaded)
            _buildDiffCard()
          else if (_diffState == _DiffCardState.error)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _diffError ?? 'Error computing diff',
                style: const TextStyle(color: ThemeConstants.error, fontSize: ThemeConstants.uiFontSizeSmall),
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
            _HeaderButton(label: 'Diff', icon: AppIcons.gitDiff, onTap: _loadDiff),
          if (_diffState == _DiffCardState.loaded) ...[
            _HeaderButton(
              label: _applying ? 'Applying...' : 'Apply',
              icon: _applying ? AppIcons.applying : AppIcons.apply,
              onTap: _applying ? null : _applyChange,
            ),
            const SizedBox(width: 8),
            _HeaderButton(
              label: 'Collapse',
              icon: AppIcons.chevronUp,
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
                (diff.text.endsWith('\n') ? diff.text.substring(0, diff.text.length - 1) : diff.text)
                    .split('\n')
                    .map((line) => '$prefix $line')
                    .join('\n'),
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
  const _HeaderButton({required this.label, required this.icon, required this.onTap});
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
            style: const TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
          ),
        ],
      ),
    );
  }
}

// ── Tab ───────────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.index, required this.activeIndex, required this.onTap});
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
          border: Border(bottom: BorderSide(color: isActive ? ThemeConstants.accent : Colors.transparent, width: 2)),
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
        try {
          await Clipboard.setData(ClipboardData(text: widget.code));
          setState(() => _copied = true);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _copied = false);
        } catch (e) {
          dLog('[clipboard] copy failed: $e');
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_copied ? AppIcons.check : AppIcons.copy, size: 12, color: ThemeConstants.mutedFg),
          const SizedBox(width: 4),
          Text(
            _copied ? 'Copied' : 'Copy',
            style: const TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
          ),
        ],
      ),
    );
  }
}
