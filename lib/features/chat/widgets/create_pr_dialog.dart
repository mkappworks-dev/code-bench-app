import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';

class PrFormResult {
  const PrFormResult({required this.title, required this.body, required this.base, required this.draft});
  final String title;
  final String body;
  final String base;
  final bool draft;
}

class CreatePrDialog extends ConsumerStatefulWidget {
  const CreatePrDialog({super.key, required this.initialTitle, required this.initialBody, required this.branches});

  final String initialTitle;
  final String initialBody;
  final List<String> branches;

  static Future<PrFormResult?> show(
    BuildContext context, {
    required String initialTitle,
    required String initialBody,
    required List<String> branches,
  }) {
    return showDialog<PrFormResult>(
      context: context,
      builder: (_) => CreatePrDialog(initialTitle: initialTitle, initialBody: initialBody, branches: branches),
    );
  }

  @override
  ConsumerState<CreatePrDialog> createState() => _CreatePrDialogState();
}

class _CreatePrDialogState extends ConsumerState<CreatePrDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late String _base;
  bool _draft = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _bodyController = TextEditingController(text: widget.initialBody);
    _base = widget.branches.contains('main') ? 'main' : (widget.branches.isNotEmpty ? widget.branches.first : 'main');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(
      context,
    ).pop(PrFormResult(title: title, body: _bodyController.text.trim(), base: _base, draft: _draft));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _titleController,
      builder: (_, _) => AppDialog(
        icon: AppIcons.gitPullRequest,
        iconType: AppDialogIconType.teal,
        title: 'Create pull request',
        hasInputField: true,
        maxWidth: 480,
        content: Builder(
          builder: (context) {
            final c = AppColors.of(context);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(controller: _titleController, maxLength: 70, labelText: 'Title'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _bodyController,
                  maxLines: 6,
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Base',
                      style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      onSelected: (v) => setState(() => _base = v),
                      color: c.panelBackground,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: c.deepBorder),
                      ),
                      itemBuilder: (_) => widget.branches
                          .map(
                            (b) => PopupMenuItem(
                              value: b,
                              height: 32,
                              child: Text(
                                b,
                                style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
                              ),
                            ),
                          )
                          .toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.chipFill,
                          border: Border.all(color: c.chipStroke),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_split, size: 12, color: c.accent),
                            const SizedBox(width: 4),
                            Text(
                              _base,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: ThemeConstants.uiFontSizeSmall,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 14, color: c.dimFg),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 6),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() => _draft = !_draft),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _draft ? c.accentTintLight : c.chipFill,
                            border: Border.all(color: _draft ? c.accentBorderTeal : c.chipStroke),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: _draft ? c.accent : c.mutedFg, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Draft',
                                style: TextStyle(
                                  color: _draft ? c.accent : c.chipText,
                                  fontSize: ThemeConstants.uiFontSizeSmall,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
          AppDialogAction.primary(label: 'Create PR', onPressed: _titleController.text.trim().isEmpty ? null : _submit),
        ],
      ),
    );
  }
}
