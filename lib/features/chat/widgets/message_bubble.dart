import 'dart:async';
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
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/project.dart';
import '../../../features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import '../notifiers/code_apply_actions.dart';
import '../notifiers/code_apply_failure.dart';
import '../notifiers/code_diff_provider.dart';
import '../notifiers/project_file_scan_actions.dart';
import '../notifiers/chat_notifier.dart';
import '../notifiers/ask_question_notifier.dart';
import 'ask_user_question_card.dart';
import 'tool_call_row.dart';
import 'work_log_section.dart';

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

class _AssistantBubble extends ConsumerWidget {
  const _AssistantBubble({required this.message});
  final ChatMessage message;

  /// Formats the answer map produced by [AskUserQuestionCard] into a
  /// plain user-message string and re-posts it via [chatMessagesProvider].
  /// This is the minimal wiring that lets an ask-question card behave like
  /// a normal turn without a dedicated agent protocol path: the agent sees
  /// the user's choice as if they'd typed it themselves.
  void _submitAnswer(WidgetRef ref, Map<String, dynamic> answer) {
    final parts = <String>[];
    final selected = answer['selectedOption'];
    final freeText = answer['freeText'];
    if (selected is String && selected.isNotEmpty) parts.add(selected);
    if (freeText is String && freeText.isNotEmpty) parts.add(freeText);
    if (parts.isEmpty) return;
    final formatted = parts.join('\n\n');
    // Fire-and-forget: sendMessage is async but the card's onSubmit is
    // void. sendMessage routes its own errors through AsyncError state.
    unawaited(ref.read(chatMessagesProvider(message.sessionId).notifier).sendMessage(formatted));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // Agentic tool-use cards — one per ToolEvent. Rendered below
              // the markdown content so the assistant's prose reads first
              // and the tool trail reads as a chronological appendix.
              //
              // Each row is keyed by `event.id` so Flutter's list diffing
              // keeps expansion state attached to the right tool event
              // when the model inserts or re-orders events mid-stream.
              // The `ToolEvent.id` requirement exists for this invariant;
              // see `tool_event.dart` doc comments.
              if (message.toolEvents.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final event in message.toolEvents)
                  Padding(
                    key: ValueKey('tool-row-${event.id}'),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ToolCallRow(event: event),
                  ),
              ],
              // Work log — collapsible summary of tool-call progress.
              // Shown for any assistant message that has tool events.
              if (message.toolEvents.isNotEmpty) ...[
                const SizedBox(height: 4),
                WorkLogSection(sessionId: message.sessionId, messageId: message.id),
              ],
              // Structured question card — shown when the agent asks the user
              // to choose an option or provide free-text input. The submit
              // path re-posts the formatted answer through the normal
              // chat send pipeline (see `_submitAnswer`).
              if (message.askQuestion != null) ...[
                const SizedBox(height: 8),
                AskUserQuestionCard(
                  question: message.askQuestion!,
                  sessionId: message.sessionId,
                  onSubmit: (answer) => _submitAnswer(ref, answer),
                  // "Clear answer" (rendered in the card as that
                  // label, not "Back"): only clears the stored answer
                  // for the current step so the user can re-pick an
                  // option. Shown on step > 0. Real multi-step rewind
                  // across prior messages is deferred to a future
                  // edit-and-fork on user messages (Pattern B).
                  onBack: message.askQuestion!.stepIndex > 0
                      ? () => ref
                            .read(askQuestionProvider.notifier)
                            .setAnswer(
                              sessionId: message.sessionId,
                              stepIndex: message.askQuestion!.stepIndex,
                              selectedOption: null,
                              freeText: null,
                            )
                      : null,
                ),
              ],
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
  bool _diffRequested = false;
  int _activeTab = 1; // 0=Before, 1=Diff, 2=After
  bool _applying = false;

  // Filename supplied by the user via the inline picker when the AI's
  // code fence didn't include one. Once set, it shadows `widget.filename`
  // via [_effectiveFilename] for all downstream operations (diff, apply,
  // header display).
  String? _pickedFilename;
  // Whether the picker panel is currently showing. Mutually exclusive with
  // the diff card: the user either picks a file or views a diff, never both.
  bool _showingPicker = false;

  /// Effective filename used for diff / apply. Prefers the user-picked one
  /// over the AI-supplied one; null means the code fence is still nameless
  /// and the Diff… picker button should be offered instead of plain Diff.
  String? get _effectiveFilename => _pickedFilename ?? widget.filename;

  Project? _resolveActiveProject() {
    final projectId = ref.read(activeProjectIdProvider);
    final projects = ref.read(projectsProvider).value ?? <Project>[];
    return projects.firstWhereOrNull((p) => p.id == projectId);
  }

  Future<void> _applyChange() async {
    final project = _resolveActiveProject();
    if (project == null) return;
    final filename = _effectiveFilename;
    if (filename == null) return;

    final absolutePath = p.join(project.path, filename);
    setState(() => _applying = true);
    try {
      await ref
          .read(codeApplyActionsProvider.notifier)
          .applyChange(
            projectId: project.id,
            filePath: absolutePath,
            projectPath: project.path,
            newContent: widget.code,
            sessionId: widget.sessionId,
            messageId: widget.messageId,
          );
      if (!mounted) return;
      final applyState = ref.read(codeApplyActionsProvider);
      if (!applyState.hasError) {
        ref.read(changesPanelVisibleProvider.notifier).show();
        setState(() => _diffRequested = false);
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(codeApplyActionsProvider, (_, next) {
      if (!_applying) return; // not our operation
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      if (failure is! CodeApplyFailure) return;
      switch (failure) {
        case CodeApplyProjectMissing():
          showErrorSnackBar(
            context,
            'Project folder is missing. Right-click the project in the sidebar to Relocate or Remove it.',
          );
        case CodeApplyOutsideProject():
          showErrorSnackBar(context, 'This file is outside the current project.');
        case CodeApplyDiskWrite(:final message):
          showErrorSnackBar(context, 'Could not write file to disk: $message');
        case CodeApplyFileRead(:final path):
          showErrorSnackBar(context, 'Could not read file: $path');
        case CodeApplyUnknownError():
          showErrorSnackBar(context, 'Unable to apply change.');
      }
    });

    final project = _resolveActiveProject();

    AsyncValue<DiffResult?>? diffAsync;
    if (_diffRequested && _effectiveFilename != null && project != null) {
      final absolutePath = p.join(project.path, _effectiveFilename!);
      diffAsync = ref.watch(
        codeDiffProvider(absolutePath: absolutePath, projectPath: project.path, newContent: widget.code),
      );
    }
    final bool diffLoaded = diffAsync?.asData?.value != null;

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
          _buildHeader(diffLoaded),
          if (_showingPicker)
            _FilePickerPanel(
              project: project,
              onCancel: () => setState(() => _showingPicker = false),
              onPicked: (picked) {
                setState(() {
                  _pickedFilename = picked;
                  _showingPicker = false;
                  _diffRequested = true;
                });
              },
            )
          else if (diffAsync != null)
            switch (diffAsync) {
              AsyncLoading() => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
                ),
              ),
              AsyncData(:final value) when value != null => _buildDiffCard(value),
              _ => Padding(
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'Unable to compute diff.',
                  style: TextStyle(color: ThemeConstants.error, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ),
            }
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

  Widget _buildHeader(bool diffLoaded) {
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
          if (_effectiveFilename != null) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _effectiveFilename!,
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
          if (_effectiveFilename != null && !_diffRequested && !_showingPicker)
            _HeaderButton(label: 'Diff', icon: AppIcons.gitDiff, onTap: () => setState(() => _diffRequested = true)),
          if (_effectiveFilename == null && !_showingPicker)
            _HeaderButton(label: 'Diff…', icon: AppIcons.gitDiff, onTap: () => setState(() => _showingPicker = true)),
          if (diffLoaded) ...[
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
                _diffRequested = false;
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

  Widget _buildDiffCard(DiffResult diffResult) {
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
                ? _buildPlainContent(diffResult.originalContent ?? '(new file)')
                : _activeTab == 2
                ? _buildPlainContent(widget.code)
                : _buildDiffContent(diffResult.diffs),
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

  Widget _buildDiffContent(List<Diff> diffs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: diffs.map((diff) {
            final bg = diff.operation == DIFF_INSERT
                ? ThemeConstants.diffAdditionBg
                : diff.operation == DIFF_DELETE
                ? ThemeConstants.diffDeletionBg
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

// ── File picker panel ─────────────────────────────────────────────────────────

/// Inline picker shown when the user clicks Diff… on a code fence that has
/// no filename. Scans the project directory for common code files and
/// substring-filters them as the user types, similar to a fuzzy file
/// opener. On pick, [onPicked] is called with the project-relative path.
///
/// The scan is deliberately eager but bounded ([kMaxScanFiles]) — a huge
/// project would otherwise pause the UI on open. We pick bounded-eager
/// over streamed-lazy because the suggestion list is tiny and users expect
/// instant filtering after the first keystroke.
class _FilePickerPanel extends ConsumerStatefulWidget {
  const _FilePickerPanel({required this.project, required this.onCancel, required this.onPicked});
  final Project? project;
  final VoidCallback onCancel;
  final void Function(String relativePath) onPicked;

  @override
  ConsumerState<_FilePickerPanel> createState() => _FilePickerPanelState();
}

class _FilePickerPanelState extends ConsumerState<_FilePickerPanel> {
  final _controller = TextEditingController();
  List<String> _allFiles = const [];
  List<String> _suggestions = const [];
  bool _scanning = true;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _scanProjectFiles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scanProjectFiles() async {
    final project = widget.project;
    if (project == null) {
      setState(() => _scanning = false);
      return;
    }
    var files = const <String>[];
    String? error;
    try {
      files = await ref.read(projectFileScanActionsProvider.notifier).scanCodeFiles(project.path);
    } on FileSystemException catch (e) {
      // Surface the reason in the UI instead of producing an empty
      // picker that looks identical to "project has no code files".
      error = 'Couldn\'t scan project — ${e.message}';
    } on Exception {
      error = 'Couldn\'t scan project.';
    }
    if (!mounted) return;
    setState(() {
      _allFiles = files;
      _scanning = false;
      _scanError = error;
    });
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = const []);
      return;
    }
    final q = query.toLowerCase();
    final matches = <String>[];
    for (final f in _allFiles) {
      if (f.toLowerCase().contains(q)) {
        matches.add(f);
        if (matches.length >= 20) break;
      }
    }
    setState(() => _suggestions = matches);
  }

  void _submit() {
    final text = _controller.text.trim();
    if (_suggestions.isNotEmpty) {
      widget.onPicked(_suggestions.first);
    } else if (text.isNotEmpty) {
      widget.onPicked(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Which file does this update?',
            style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _filter,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: _scanError ?? (_scanning ? 'Scanning project…' : 'lib/features/…'),
                    hintStyle: const TextStyle(color: ThemeConstants.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: ThemeConstants.borderColor),
                    ),
                  ),
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    fontFamily: ThemeConstants.editorFontFamily,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _HeaderButton(label: 'Diff', icon: AppIcons.gitDiff, onTap: _submit),
              const SizedBox(width: 8),
              _HeaderButton(label: 'Cancel', icon: AppIcons.chevronUp, onTap: widget.onCancel),
            ],
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                border: Border.all(color: ThemeConstants.borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (_, i) => InkWell(
                  onTap: () => widget.onPicked(_suggestions[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      _suggestions[i],
                      style: const TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                        fontFamily: ThemeConstants.editorFontFamily,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
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
