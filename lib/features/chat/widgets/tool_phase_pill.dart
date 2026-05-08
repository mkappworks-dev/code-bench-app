import 'package:flutter/material.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../utils/tool_phase_classifier.dart';

class ToolPhasePill extends StatefulWidget {
  const ToolPhasePill({super.key, required this.phase, required this.label});
  final PhaseClass phase;
  final String label;

  @override
  State<ToolPhasePill> createState() => _ToolPhasePillState();
}

class _ToolPhasePillState extends State<ToolPhasePill> with SingleTickerProviderStateMixin {
  // only rendered while a tool is active; always pulsing by design
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = switch (widget.phase) {
      PhaseClass.think => c.accent,
      PhaseClass.tool => c.warning,
      PhaseClass.io => c.info,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_ctrl.value);
              return Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.4 + 0.6 * t),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: ThemeConstants.uiFontSizeSmall,
              color: color,
              fontFamily: ThemeConstants.editorFontFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
