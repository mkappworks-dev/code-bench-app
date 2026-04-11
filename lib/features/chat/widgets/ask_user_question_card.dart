import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/ask_user_question.dart';
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
  final ValueChanged<Map<String, dynamic>> onSubmit;
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
    widget.onSubmit({
      'step': widget.question.stepIndex,
      'selectedOption': _selectedOption,
      'freeText': _freeTextController.text.trim().isEmpty ? null : _freeTextController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3550)),
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
            style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
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
              decoration: const InputDecoration(
                hintText: 'Or describe your own approach…',
                hintStyle: TextStyle(color: Color(0xFF555555), fontSize: 11),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 12),
              maxLines: 3,
              minLines: 1,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton(
                onPressed: widget.question.stepIndex > 0 ? widget.onBack : null,
                child: const Text('← Back', style: TextStyle(fontSize: 11)),
              ),
              const Spacer(),
              if (!_isLastStep)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7CFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  onPressed: _canSubmit ? _handleSubmit : null,
                  child: const Text('Next →', style: TextStyle(fontSize: 11)),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7CFF),
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

// ── Progress dots header ────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep, required this.totalSteps, required this.sectionLabel});

  final int currentStep;
  final int totalSteps;
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            Color dotColor;
            if (i < currentStep) {
              dotColor = const Color(0xFF4A7CFF);
            } else if (i == currentStep) {
              dotColor = const Color(0xFF4A7CFF).withValues(alpha: 0.5);
            } else {
              dotColor = const Color(0xFF2A2A2A);
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
          style: const TextStyle(color: Color(0xFF666666), fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        if (sectionLabel != null)
          Text(sectionLabel!, style: const TextStyle(color: Color(0xFF888888), fontSize: 9, letterSpacing: 0.5)),
      ],
    );
  }
}

// ── Option row ──────────────────────────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.index, required this.label, required this.isSelected, required this.onTap});

  final int index;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A2540) : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF4A7CFF) : const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4A7CFF) : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF888888),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
