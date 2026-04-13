import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/project.dart';
import '../../project_sidebar/notifiers/project_sidebar_notifier.dart';
import '../notifiers/chat_notifier.dart';
import '../notifiers/code_apply_actions.dart';
import '../notifiers/code_apply_failure.dart';
import '../notifiers/code_diff_provider.dart';
import '../notifiers/project_file_scan_actions.dart';
import '../notifiers/project_file_scan_failure.dart';
import '../utils/code_fence_parser.dart';

// ── Public builder (used by _MessageContent in message_bubble.dart) ───────────

class CodeBlockBuilder extends MarkdownElementBuilder {
  CodeBlockBuilder({required this.messageId, required this.sessionId});
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

  Future<void> _applyChange() async {
    final project = ref.read(activeProjectProvider);
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
      if (!_applying) return;
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
        case CodeApplyTooLarge(:final bytes):
          showErrorSnackBar(context, 'Content too large to apply ($bytes bytes).');
        case CodeApplyUnknownError():
          showErrorSnackBar(context, 'Unable to apply change.');
      }
    });

    final project = ref.watch(activeProjectProvider);

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
              _ => const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
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

// ── Small header button ───────────────────────────────────────────────────────

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

// ── File picker panel ─────────────────────────────────────────────────────────

/// Inline picker shown when the user clicks Diff… on a code fence that has
/// no filename. Scans the project directory for common code files and
/// substring-filters them as the user types. On pick, [onPicked] is called
/// with the project-relative path.
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
    if (project == null) return;
    final files = await ref.read(projectFileScanActionsProvider.notifier).scanCodeFiles(project.path);
    if (!mounted) return;
    setState(() => _allFiles = files);
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
    ref.listen(projectFileScanActionsProvider, (_, next) {
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      final message = failure is ProjectFileScanFailure
          ? switch (failure) {
              ProjectFileScanScan(:final message) => 'Couldn\'t scan project — $message',
            }
          : 'Couldn\'t scan project.';
      setState(() => _scanError = message);
    });

    final isScanning = ref.watch(projectFileScanActionsProvider).isLoading;

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
                    hintText: _scanError ?? (isScanning ? 'Scanning project…' : 'lib/features/…'),
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
