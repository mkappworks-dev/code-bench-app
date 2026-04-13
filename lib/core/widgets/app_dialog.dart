import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

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
    required this.actions,
    this.minWidth = 300,
    this.maxWidth = 480,
  });

  final IconData icon;
  final AppDialogIconType iconType;
  final String title;
  final String? subtitle;
  final bool hasInputField;
  final Widget content;
  final List<AppDialogAction> actions;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final badgeSize = hasInputField ? 28.0 : 36.0;
    final badgeRadius = hasInputField ? 7.0 : 9.0;
    final headerBottomPad = hasInputField ? 12.0 : 14.0;

    final (iconBg, iconFg) = switch (iconType) {
      AppDialogIconType.teal => (ThemeConstants.accent.withValues(alpha: 0.1), ThemeConstants.accent),
      AppDialogIconType.destructive => (ThemeConstants.error.withValues(alpha: 0.1), ThemeConstants.error),
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: ThemeConstants.frostedSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ThemeConstants.borderColor),
            boxShadow: const [
              BoxShadow(color: Color(0xD9000000), blurRadius: 60, offset: Offset(0, 20)),
              BoxShadow(color: Color(0x0AFFFFFF), blurRadius: 0, spreadRadius: 0.5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, headerBottomPad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(badgeRadius)),
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
                              style: const TextStyle(
                                color: ThemeConstants.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle!,
                                style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 11),
                              ),
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
              Container(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: ThemeConstants.panelSeparator)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions.indexed
                      .map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(left: entry.$1 > 0 ? 8.0 : 0.0),
                          child: _ActionButton(action: entry.$2),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
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
    final (bg, border, textColor) = switch (action._style) {
      _ActionStyle.primary => (ThemeConstants.accent, Border.all(color: Colors.transparent), ThemeConstants.onAccent),
      _ActionStyle.ghost => (
        Colors.transparent,
        Border.all(color: ThemeConstants.borderColor),
        ThemeConstants.textPrimary,
      ),
      _ActionStyle.destructive => (
        Colors.transparent,
        Border.all(color: ThemeConstants.destructiveBorder),
        ThemeConstants.error,
      ),
    };

    return GestureDetector(
      onTap: action.onPressed,
      child: Opacity(
        opacity: action.onPressed == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: border),
          child: Text(
            action.label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: action._style == _ActionStyle.primary ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
