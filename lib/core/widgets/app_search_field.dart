import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/theme_constants.dart';
import '../theme/app_colors.dart';

/// Search / filter text field with a leading magnifier icon.
///
/// Sized at [ThemeConstants.uiFontSizeSmall] to match compact list contexts
/// (branch picker, file picker). Fill and border come from [InputDecorationTheme].
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Search…',
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Icon(LucideIcons.search, size: 11, color: c.mutedFg),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
