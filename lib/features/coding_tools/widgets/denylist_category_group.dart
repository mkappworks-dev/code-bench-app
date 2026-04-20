import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import 'denylist_chip.dart';

/// A self-contained card for one denylist category.
///
/// Pure widget — no ref, no ConsumerWidget. All callbacks are provided by the
/// caller, which owns the confirm dialogs and Riverpod state.
class DenylistCategoryGroup extends StatefulWidget {
  const DenylistCategoryGroup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.baseline,
    required this.userAdded,
    required this.suppressed,
    required this.inputHint,
    required this.isSubmitting,
    required this.onAdd,
    required this.onRemoveUser,
    required this.onSuppressBaseline,
    required this.onRestoreBaseline,
    required this.onRestoreCategory,
  });

  final String title;
  final String subtitle;

  /// Active baseline entries (not suppressed).
  final Set<String> baseline;

  /// User-added entries.
  final Set<String> userAdded;

  /// Baseline entries the user has suppressed (re-blocked).
  final Set<String> suppressed;

  final String inputHint;
  final bool isSubmitting;

  /// Called when the user submits a new entry via the text field.
  final void Function(String) onAdd;

  /// × on a userAdded chip.
  final void Function(String) onRemoveUser;

  /// × on an active baseline chip — caller shows a confirm dialog.
  final void Function(String) onSuppressBaseline;

  /// × on a suppressed chip — restores the baseline entry (no confirm needed).
  final void Function(String) onRestoreBaseline;

  /// ↺ in the header — resets all user-added and suppressed entries for the
  /// category back to baseline defaults.
  final VoidCallback onRestoreCategory;

  @override
  State<DenylistCategoryGroup> createState() => _DenylistCategoryGroupState();
}

class _DenylistCategoryGroupState extends State<DenylistCategoryGroup> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final isDefault = widget.userAdded.isEmpty && widget.suppressed.isEmpty;

    // Active baseline entries = baseline minus suppressed
    final activeBaseline = widget.baseline.difference(widget.suppressed);

    return Container(
      decoration: BoxDecoration(
        color: c.glassFill,
        border: Border.all(color: c.subtleBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                widget.title,
                style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              GestureDetector(
                onTap: isDefault ? null : widget.onRestoreCategory,
                child: Text(
                  '↺ Reset',
                  style: TextStyle(
                    color: isDefault ? c.textMuted : c.accent,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Subtitle ───────────────────────────────────────────────────────
          Text(
            widget.subtitle,
            style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
          ),

          // ── Chip wall ──────────────────────────────────────────────────────
          if (widget.userAdded.isNotEmpty || activeBaseline.isNotEmpty || widget.suppressed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in widget.userAdded)
                  DenylistChip(
                    key: ValueKey('user-$entry'),
                    label: entry,
                    variant: DenylistChipVariant.userAdded,
                    onRemove: () => widget.onRemoveUser(entry),
                  ),
                for (final entry in activeBaseline)
                  DenylistChip(
                    key: ValueKey('baseline-$entry'),
                    label: entry,
                    variant: DenylistChipVariant.baseline,
                    onRemove: () => widget.onSuppressBaseline(entry),
                  ),
                for (final entry in widget.suppressed)
                  DenylistChip(
                    key: ValueKey('suppressed-$entry'),
                    label: entry,
                    variant: DenylistChipVariant.suppressed,
                    onRemove: () => widget.onRestoreBaseline(entry),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ── Add entry row ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _controller,
                  hintText: widget.inputHint,
                  isDense: true,
                  fontFamily: ThemeConstants.editorFontFamily,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: TextButton(
                  onPressed: widget.isSubmitting ? null : _submit,
                  style: TextButton.styleFrom(
                    foregroundColor: c.accent,
                    textStyle: const TextStyle(fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: widget.isSubmitting
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: c.accent),
                        )
                      : const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
