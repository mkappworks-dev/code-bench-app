import 'package:flutter/material.dart';

import '../../core/constants/theme_constants.dart';

/// A shimmer-style skeleton loader for list items.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 56,
    this.showLeading = true,
    this.lineCount = 2,
  });

  final int itemCount;
  final double itemHeight;
  final bool showLeading;
  final int lineCount;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final shimmerColor = Color.lerp(
          ThemeConstants.inputBackground,
          ThemeConstants.borderColor,
          _animation.value,
        )!;

        return ListView.separated(
          itemCount: widget.itemCount,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            // vary widths so it looks more natural
            final titleWidth =
                index % 3 == 0 ? 0.6 : (index % 3 == 1 ? 0.75 : 0.5);
            final subtitleWidth = index % 2 == 0 ? 0.4 : 0.55;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (widget.showLeading) ...[
                    _SkeletonBox(
                      width: 16,
                      height: 16,
                      color: shimmerColor,
                      borderRadius: 4,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          width: double.infinity,
                          height: 12,
                          color: shimmerColor,
                          borderRadius: 4,
                          widthFactor: titleWidth,
                        ),
                        if (widget.lineCount > 1) ...[
                          const SizedBox(height: 6),
                          _SkeletonBox(
                            width: double.infinity,
                            height: 10,
                            color: shimmerColor,
                            borderRadius: 4,
                            widthFactor: subtitleWidth,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
    this.widthFactor = 1.0,
  });

  final double width;
  final double height;
  final Color color;
  final double borderRadius;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
