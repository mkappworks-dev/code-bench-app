import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/theme_constants.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => Future.microtask(windowManager.startDragging),
      child: Container(
        height: 36,
        color: ThemeConstants.titleBar,
        child: Row(
          children: [
            const SizedBox(width: 80), // space for native traffic lights
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
            const SizedBox(width: 80), // balance left offset
          ],
        ),
      ),
    );
  }
}
