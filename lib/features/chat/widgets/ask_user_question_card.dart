import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/session/models/ask_user_question.dart';
import '../notifiers/ask_question_notifier.dart';

class AskUserQuestionCard extends ConsumerStatefulWidget {
  const AskUserQuestionCard({
    super.key,
    required this.question,
    required this.sessionId,
    required this.onSubmit,
    this.onBack,
  });

  final AskUserQuestion question;
  final String sessionId;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final VoidCallback? onBack;

  @override
  ConsumerState<AskUserQuestionCard> createState() => _AskUserQuestionCardState();
}

class _AskUserQuestionCardState extends ConsumerState<AskUserQuestionCard> {
  String? _selectedOption;
  final _freeTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Restore prior answer if backing into this step.
    final prior = ref.read(askQuestionProvider.notifier).getAnswer(widget.sessionId, widget.question.stepIndex);
    if (prior != null) {
      _selectedOption = prior.selectedOption;
      if (prior.freeText != null) {
        _freeTextController.text = prior.freeText!;
      }
    }
  }

  @override
  void dispose() {
    _freeTextController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selectedOption != null || _freeTextController.text.trim().isNotEmpty;

  bool get _isLastStep => widget.question.stepIndex == widget.question.totalSteps - 1;

  void _handleSubmit() {
    if (!_canSubmit) return;
    ref
        .read(askQuestionProvider.notifier)
        .setAnswer(
          sessionId: widget.sessionId,
          stepIndex: widget.question.stepIndex,
          selectedOption: _selectedOption,
          freeText: _freeTextController.text.trim().isEmpty ? null : _freeTextController.text.trim(),
        );
    unawaited(
      widget.onSubmit({
        'step': widget.question.stepIndex,
        'selectedOption': _selectedOption,
        'freeText': _freeTextController.text.trim().isEmpty ? null : _freeTextController.text.trim(),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.questionCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.selectionBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeader(
            currentStep: widget.question.stepIndex,
            totalSteps: widget.question.totalSteps,
            sectionLabel: widget.question.sectionLabel,
          ),
          const SizedBox(height: 12),
          Text(
            widget.question.question,
            style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          if (widget.question.options.isNotEmpty)
            ...widget.question.options.asMap().entries.map(
              (entry) => _OptionRow(
                index: entry.key,
                label: entry.value,
                isSelected: _selectedOption == entry.value,
                onTap: () => setState(() => _selectedOption = entry.value),
              ),
            ),
          if (widget.question.allowFreeText) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _freeTextController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Or describe your own approach…',
                hintStyle: TextStyle(color: c.mutedFg, fontSize: 11),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              style: TextStyle(color: c.textPrimary, fontSize: 12),
              maxLines: 3,
              minLines: 1,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              // "Clear answer" rather than "Back": the handler only
              // clears the stored answer for the current step so the
              // user can re-answer — it does NOT rewind the chat to a
              // previous question. Real rewind is tracked for a future
              // edit-and-fork on user messages (Pattern B).
              TextButton(
                onPressed: widget.question.stepIndex > 0 ? widget.onBack : null,
                child: const Text('Clear answer', style: TextStyle(fontSize: 11)),
              ),
              const Spacer(),
              if (!_isLastStep)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.blueAccent,
                    foregroundColor: c.onAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  onPressed: _canSubmit ? _handleSubmit : null,
                  child: const Text('Next →', style: TextStyle(fontSize: 11)),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.blueAccent,
                    foregroundColor: c.onAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  onPressed: _canSubmit ? _handleSubmit : null,
                  child: const Text('Submit', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep, required this.totalSteps, required this.sectionLabel});

  final int currentStep;
  final int totalSteps;
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            Color dotColor;
            if (i < currentStep) {
              dotColor = c.blueAccent;
            } else if (i == currentStep) {
              dotColor = c.blueAccent.withValues(alpha: 0.5);
            } else {
              dotColor = c.borderColor;
            }
            return Padding(
              padding: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
              child: Container(
                width: 16,
                height: 4,
                decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(2)),
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          '${currentStep + 1} / $totalSteps',
          style: TextStyle(color: c.textMuted, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        if (sectionLabel != null)
          Text(sectionLabel!, style: TextStyle(color: c.dimFg, fontSize: 9, letterSpacing: 0.5)),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.index, required this.label, required this.isSelected, required this.onTap});

  final int index;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.selectionBg : c.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? c.blueAccent : c.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? c.blueAccent : c.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : c.dimFg,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: TextStyle(color: isSelected ? c.textPrimary : c.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
