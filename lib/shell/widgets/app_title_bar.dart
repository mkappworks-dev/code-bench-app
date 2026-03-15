import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/theme_constants.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 36,
        color: ThemeConstants.titleBar,
        child: Row(
          children: [
            const SizedBox(width: 80), // macOS traffic lights space
            Expanded(
              child: Center(
                child: Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Windows/Linux window controls
            _WindowControls(),
          ],
        ),
      ),
    );
  }
}

class _WindowControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleBarButton(
          icon: Icons.remove,
          onPressed: () => windowManager.minimize(),
          tooltip: 'Minimize',
        ),
        _TitleBarButton(
          icon: Icons.crop_square,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          tooltip: 'Maximize',
        ),
        _TitleBarButton(
          icon: Icons.close,
          onPressed: () => windowManager.close(),
          tooltip: 'Close',
          isClose: true,
        ),
      ],
    );
  }
}

class _TitleBarButton extends StatefulWidget {
  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 40,
            height: 36,
            color: _hovered
                ? (widget.isClose ? Colors.red.withAlpha(200) : Colors.white.withAlpha(20))
                : Colors.transparent,
            child: Icon(
              widget.icon,
              size: 14,
              color: ThemeConstants.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
