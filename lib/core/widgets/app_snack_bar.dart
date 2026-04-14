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
    AppSnackBarType.success: ThemeConstants.successTintBg,
    AppSnackBarType.error: ThemeConstants.errorTintBg,
    AppSnackBarType.warning: ThemeConstants.warningTintBg,
    AppSnackBarType.info: ThemeConstants.infoTintBg,
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
        // Uniform border — safe to combine with borderRadius.
        border: Border.all(color: ThemeConstants.borderColor),
        boxShadow: const [BoxShadow(color: ThemeConstants.shadowHeavy, blurRadius: 32, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: ThemeConstants.frostedSurface,
          // IntrinsicHeight lets the left accent strip fill the full height
          // without a non-uniform border (which Flutter forbids with borderRadius).
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
