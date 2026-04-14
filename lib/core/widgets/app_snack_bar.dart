import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

enum AppSnackBarType { success, error, warning, info }

class AppSnackBar extends StatelessWidget {
  const AppSnackBar({
    super.key,
    required this.label,
    this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final String? message;
  final AppSnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const _typeColor = {
    AppSnackBarType.success: ThemeConstants.success,
    AppSnackBarType.error: ThemeConstants.error,
    AppSnackBarType.warning: ThemeConstants.warning,
    AppSnackBarType.info: ThemeConstants.info,
  };

  static const _typeIconBg = {
    AppSnackBarType.success: Color(0x1F4EC9B0),
    AppSnackBarType.error: Color(0x1FF44747),
    AppSnackBarType.warning: Color(0x1FCCA700),
    AppSnackBarType.info: Color(0x1F4FC1FF),
  };

  static const _typeIcon = {
    AppSnackBarType.success: Icons.check_circle_outline,
    AppSnackBarType.error: Icons.error_outline,
    AppSnackBarType.warning: Icons.warning_amber_outlined,
    AppSnackBarType.info: Icons.info_outline,
  };

  /// Shows a frosted snackbar anchored to the bottom of the nearest Scaffold.
  static void show(
    BuildContext context,
    String label, {
    String? message,
    AppSnackBarType type = AppSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: AppSnackBar(
            label: label,
            message: message,
            type: type,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor[type]!;
    final iconBg = _typeIconBg[type]!;
    final iconData = _typeIcon[type]!;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0xB3000000), blurRadius: 32, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: ThemeConstants.frostedSurface,
            border: Border(
              top: BorderSide(color: ThemeConstants.borderColor),
              right: BorderSide(color: ThemeConstants.borderColor),
              bottom: BorderSide(color: ThemeConstants.borderColor),
              left: BorderSide(color: typeColor, width: 3),
            ),
          ),
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
                        style: const TextStyle(
                          color: ThemeConstants.headingText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 1),
                        Text(message!, style: const TextStyle(color: ThemeConstants.dimFg, fontSize: 10)),
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
                  onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  child: const Icon(Icons.close, size: 13, color: ThemeConstants.mutedFg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
