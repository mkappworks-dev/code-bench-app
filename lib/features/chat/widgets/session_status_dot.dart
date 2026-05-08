import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum SessionStatus { idle, streaming, awaiting, errored }

class SessionStatusDot extends StatelessWidget {
  const SessionStatusDot({super.key, required this.status});
  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = switch (status) {
      SessionStatus.streaming => c.accent,
      SessionStatus.awaiting => c.warning,
      SessionStatus.errored => c.error,
      SessionStatus.idle => c.iconInactive,
    };

    return _Dot(color: color, pulse: status == SessionStatus.streaming);
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulse == old.pulse) return;
    if (widget.pulse) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.4 + 0.6 * t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 * t),
                blurRadius: 6 + 2 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
