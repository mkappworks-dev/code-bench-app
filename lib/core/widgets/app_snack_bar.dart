import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppSnackBarType { success, error, warning, info }

class AppSnackBar extends StatelessWidget {
  const AppSnackBar({
    super.key,
    required this.label,
    this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    this.onClose,
  });

  final String label;
  final String? message;
  final AppSnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  static const _typeIcon = {
    AppSnackBarType.success: Icons.check_circle_outline,
    AppSnackBarType.error: Icons.error_outline,
    AppSnackBarType.warning: Icons.warning_amber_outlined,
    AppSnackBarType.info: Icons.info_outline,
  };

  // Tracks the currently visible toast so a new one dismisses the old one.
  static _ToastState? _current;

  /// Shows a frosted toast in the top-right corner of the screen.
  static void show(
    BuildContext context,
    String label, {
    String? message,
    AppSnackBarType type = AppSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _current?.dismiss();
    _current = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        label: label,
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        onDismiss: () {
          entry.remove();
          if (_current?.mounted == false) _current = null;
        },
        onRegister: (state) => _current = state,
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final typeColor = {
      AppSnackBarType.success: c.success,
      AppSnackBarType.error: c.error,
      AppSnackBarType.warning: c.warning,
      AppSnackBarType.info: c.info,
    }[type]!;
    final iconBg = {
      AppSnackBarType.success: c.successTintBg,
      AppSnackBarType.error: c.errorTintBg,
      AppSnackBarType.warning: c.warningTintBg,
      AppSnackBarType.info: c.infoTintBg,
    }[type]!;
    final iconData = _typeIcon[type]!;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.subtleBorder),
          boxShadow: [BoxShadow(color: c.shadowHeavy, blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            color: c.frostedSurface,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: typeColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(5)),
                            child: Icon(iconData, size: 13, color: typeColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(color: c.headingText, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                if (message != null) ...[
                                  const SizedBox(height: 1),
                                  Text(message!, style: TextStyle(color: c.dimFg, fontSize: 10)),
                                ],
                              ],
                            ),
                          ),
                          if (actionLabel != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onAction,
                              child: Text(
                                actionLabel!,
                                style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onClose,
                            child: Icon(Icons.close, size: 13, color: c.mutedFg),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.label,
    required this.message,
    required this.type,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onDismiss,
    required this.onRegister,
  });

  final String label;
  final String? message;
  final AppSnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismiss;
  final ValueChanged<_ToastState> onRegister;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.onRegister(this);
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _slide = Tween(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _timer = Timer(widget.duration, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: AppSnackBar(
            label: widget.label,
            message: widget.message,
            type: widget.type,
            actionLabel: widget.actionLabel,
            onAction: widget.onAction,
            onClose: dismiss,
          ),
        ),
      ),
    );
  }
}
