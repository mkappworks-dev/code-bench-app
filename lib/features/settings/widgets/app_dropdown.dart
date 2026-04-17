// lib/features/settings/widgets/app_dropdown.dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/instant_menu.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    required this.context,
  });

  final T value;
  final List<T> items;
  final String Function(T) label;
  final void Function(T) onChanged;
  final BuildContext context;

  void _open() {
    final c = AppColors.of(context);
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    showInstantMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height + 4,
        overlay.size.width - origin.dx - box.size.width,
        0,
      ),
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: c.faintFg),
      ),
      items: items
          .map(
            (item) => PopupMenuItem<T>(
              value: item,
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label(item),
                      style: TextStyle(
                        color: item == value ? c.textPrimary : c.textSecondary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                      ),
                    ),
                  ),
                  if (item == value) Icon(AppIcons.check, size: 11, color: c.accent),
                ],
              ),
            ),
          )
          .toList(),
    ).then((picked) {
      if (picked != null) onChanged(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.chipFill,
          border: Border.all(color: c.chipStroke),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label(value),
              style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            const SizedBox(width: 4),
            Icon(AppIcons.chevronDown, size: 10, color: c.mutedFg),
          ],
        ),
      ),
    );
  }
}
