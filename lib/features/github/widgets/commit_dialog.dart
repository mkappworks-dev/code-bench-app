import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/repository.dart';
import '../../../features/chat/chat_notifier.dart';
import '../../../services/ai/ai_service_factory.dart';

/// Conventional commit prefix chips
const _commitPrefixes = [
  'feat',
  'fix',
  'docs',
  'refactor',
  'test',
  'chore',
  'perf',
  'style',
];

class CommitDialog extends ConsumerStatefulWidget {
  const CommitDialog({
    super.key,
    required this.repo,
    required this.branch,
    required this.branches,
  });

  final Repository repo;
  final String branch;
  final List<String> branches;

  @override
  ConsumerState<CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends ConsumerState<CommitDialog> {
  final _messageController = TextEditingController();
  String _selectedPrefix = 'feat';
  late String _selectedBranch;
  bool _submitting = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.branch;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String get _fullMessage {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return '';
    return '$_selectedPrefix: $msg';
  }

  Future<void> _generateMessage() async {
    final model = ref.read(selectedModelProvider);
    final service = await ref.read(aiServiceProvider(model.provider).future);

    if (service == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No AI service configured. Add an API key in Settings.',
            ),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _generating = true;
      _messageController.clear();
    });

    final userNotes = _messageController.text.trim();
    final prompt =
        'Generate a conventional commit message body (the text AFTER the type prefix) '
        'for a "$_selectedPrefix" type commit to the "${widget.repo.name}" repository '
        'on branch "$_selectedBranch". '
        '${userNotes.isNotEmpty ? 'User notes: "$userNotes". ' : ''}'
        'Return ONLY the message body — no type prefix, no quotes, no markdown.';

    try {
      await for (final chunk in service.streamMessage(
        history: [],
        prompt: prompt,
        model: model,
      )) {
        if (mounted) {
          setState(() {
            _messageController.text = _messageController.text + chunk;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI generation failed: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _commit() async {
    final msg = _fullMessage;
    if (msg.isEmpty) return;

    setState(() => _submitting = true);
    try {
      // Note: full commit implementation requires file SHA and new content.
      // This dialog demonstrates the UX — actual commit wiring is done in the
      // editor flow when the user edits a GitHub file and saves.
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commit prepared. Open a file to stage changes.'),
            backgroundColor: ThemeConstants.info,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commit failed: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeConstants.sidebarBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ThemeConstants.borderColor),
      ),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  const Icon(
                    Icons.commit,
                    size: 18,
                    color: ThemeConstants.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Commit to ${widget.repo.name}',
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      maxWidth: 24,
                      maxHeight: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Branch selector
              const Text(
                'Branch',
                style: TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedBranch,
                dropdownColor: ThemeConstants.inputBackground,
                style: const TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(isDense: true),
                items: widget.branches
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedBranch = v);
                },
              ),
              const SizedBox(height: 16),

              // Prefix chips
              const Text(
                'Type',
                style: TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _commitPrefixes.map((prefix) {
                  final selected = prefix == _selectedPrefix;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPrefix = prefix),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? ThemeConstants.accent
                            : ThemeConstants.inputBackground,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: selected
                              ? ThemeConstants.accent
                              : ThemeConstants.borderColor,
                        ),
                      ),
                      child: Text(
                        prefix,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : ThemeConstants.textSecondary,
                          fontSize: 11,
                          fontFamily: ThemeConstants.editorFontFamily,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Message label row
              Row(
                children: [
                  const Text(
                    'Message',
                    style: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _generating ? null : _generateMessage,
                    icon: _generating
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : const Icon(Icons.auto_awesome, size: 13),
                    label: Text(
                      _generating ? 'Generating...' : 'Generate',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeConstants.inputBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                      border: const Border(
                        top: BorderSide(color: ThemeConstants.borderColor),
                        left: BorderSide(color: ThemeConstants.borderColor),
                        bottom: BorderSide(color: ThemeConstants.borderColor),
                      ),
                    ),
                    child: Text(
                      '$_selectedPrefix: ',
                      style: const TextStyle(
                        color: ThemeConstants.syntaxKeyword,
                        fontSize: 13,
                        fontFamily: ThemeConstants.editorFontFamily,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'describe your change...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                          borderSide: BorderSide(
                            color: ThemeConstants.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                          borderSide: BorderSide(
                            color: ThemeConstants.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                          borderSide: BorderSide(color: ThemeConstants.accent),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _commit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.commit, size: 14),
                    label: const Text('Commit'),
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
