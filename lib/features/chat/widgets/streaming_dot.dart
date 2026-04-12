import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';

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
