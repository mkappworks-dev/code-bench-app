import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitle,
    required this.stepSubtitle,
  });

  final int currentStep;
  final int totalSteps;
  final String stepTitle;
  final String stepSubtitle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dots
        Row(
          children: List.generate(totalSteps, (i) {
            Color dotColor;
            if (i < currentStep) {
              dotColor = c.accent; // completed
            } else if (i == currentStep) {
              dotColor = c.accent.withValues(alpha: 0.45); // current
            } else {
              dotColor = c.borderColor; // upcoming
            }
            return Padding(
              padding: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 6,
                decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(3)),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Step label
        Text(
          'STEP ${currentStep + 1} OF $totalSteps',
          style: TextStyle(color: c.textMuted, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        // Step title
        Text(
          stepTitle,
          style: TextStyle(color: c.headingText, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (stepSubtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(stepSubtitle, style: TextStyle(color: c.textMuted, fontSize: 12)),
        ],
      ],
    );
  }
}
