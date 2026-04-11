import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dots
        Row(
          children: List.generate(totalSteps, (i) {
            Color dotColor;
            if (i < currentStep) {
              dotColor = const Color(0xFF4A7CFF); // completed
            } else if (i == currentStep) {
              dotColor = const Color(0xFF4A7CFF).withValues(alpha: 0.5); // current
            } else {
              dotColor = const Color(0xFF2A2A2A); // upcoming
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
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        // Step title
        Text(
          stepTitle,
          style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (stepSubtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(stepSubtitle, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
        ],
      ],
    );
  }
}
