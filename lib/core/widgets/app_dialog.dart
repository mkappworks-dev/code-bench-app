import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppDialogIconType { teal, destructive }

class AppDialogAction {
  const AppDialogAction._({required this.label, required this.onPressed, required _ActionStyle style}) : _style = style;

  factory AppDialogAction.cancel({required VoidCallback onPressed}) =>
      AppDialogAction._(label: 'Cancel', onPressed: onPressed, style: _ActionStyle.ghost);

  factory AppDialogAction.primary({required String label, required VoidCallback? onPressed}) =>
      AppDialogAction._(label: label, onPressed: onPressed, style: _ActionStyle.primary);

  factory AppDialogAction.destructive({required String label, required VoidCallback onPressed}) =>
      AppDialogAction._(label: label, onPressed: onPressed, style: _ActionStyle.destructive);

  final String label;
  final VoidCallback? onPressed;
  final _ActionStyle _style;
}

enum _ActionStyle { primary, ghost, destructive }

/// Frosted-glass dialog surface with icon badge + standardised footer.
///
/// Content and dialog state belong in the caller's widget. AppDialog provides
/// only the visual chrome: background, border, icon badge, and footer buttons.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.icon,
    required this.iconType,
    required this.title,
    this.subtitle,
    this.hasInputField = false,
    required this.content,
    this.actions,
    this.minWidth = 300,
    this.maxWidth = 480,
  });

  final IconData icon;
  final AppDialogIconType iconType;
  final String title;
  final String? subtitle;
  final bool hasInputField;
  final Widget content;

  /// Footer action buttons. Pass `null` to suppress the footer entirely —
  /// useful when the content widget provides its own action row.
  final List<AppDialogAction>? actions;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final badgeSize = hasInputField ? 28.0 : 36.0;
    final badgeRadius = hasInputField ? 7.0 : 9.0;
    final headerBottomPad = hasInputField ? 12.0 : 14.0;

    final (iconBg, iconFg) = switch (iconType) {
      AppDialogIconType.teal => (c.accent.withValues(alpha: 0.1), c.accent),
      AppDialogIconType.destructive => (c.error.withValues(alpha: 0.1), c.error),
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: c.dialogFill,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: c.dialogBorder),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xF2000000)
                        : const Color(0x33000000),
                    blurRadius: Theme.of(context).brightness == Brightness.dark ? 64 : 48,
                    offset: Offset(0, Theme.of(context).brightness == Brightness.dark ? 24 : 16),
                  ),
                  BoxShadow(color: c.dialogHighlight, blurRadius: 0, spreadRadius: 0, offset: const Offset(0, 1)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header row (icon badge + title + subtitle)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, headerBottomPad),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: badgeSize,
                          height: badgeSize,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(badgeRadius),
                            border: Border.all(
                              color: iconType == AppDialogIconType.teal
                                  ? c.accentBorderTeal
                                  : c.error.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: iconType == AppDialogIconType.teal
                                    ? c.accentGlowBadge
                                    : c.error.withValues(alpha: 0.18),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Icon(icon, size: badgeSize * 0.5, color: iconFg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: (badgeSize - 16.0) / 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 3),
                                  Text(subtitle!, style: TextStyle(color: c.textSecondary, fontSize: 11)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: content),
                  const SizedBox(height: 12),
                  if (actions != null)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.faintBorder)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions!.indexed
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(left: entry.$1 > 0 ? 8.0 : 0.0),
                                child: _ActionButton(action: entry.$2),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  else
                    const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final AppDialogAction action;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    switch (action._style) {
      case _ActionStyle.primary:
        return GestureDetector(
          onTap: action.onPressed,
          child: Opacity(
            opacity: action.onPressed == null ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.accent, c.accentHover],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: c.sendGlow, blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Text(
                action.label,
                style: TextStyle(color: c.onAccent, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      case _ActionStyle.ghost:
        return GestureDetector(
          onTap: action.onPressed,
          child: Opacity(
            opacity: action.onPressed == null ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: c.chipFill,
                border: Border.all(color: c.chipStroke),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                action.label,
                style: TextStyle(color: c.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        );
      case _ActionStyle.destructive:
        return GestureDetector(
          onTap: action.onPressed,
          child: Opacity(
            opacity: action.onPressed == null ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: c.destructiveBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                action.label,
                style: TextStyle(color: c.error, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        );
    }
  }
}
