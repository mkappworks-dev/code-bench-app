import 'package:flutter/material.dart';

import '../constants/theme_constants.dart';
import '../theme/app_colors.dart';

/// Standard text field — labeled or hint-only, single or multiline.
///
/// Bakes in the default `labelStyle` and `helperStyle` so call sites don't
/// repeat those everywhere. Pass [fontFamily] (e.g. [ThemeConstants.editorFontFamily])
/// to switch to monospace for API keys, shell commands, and paths.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.hintStyle,
    this.helperText,
    this.errorText,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.isDense = false,
    this.autofocus = false,
    this.alignLabelWithHint = false,
    this.fontSize = ThemeConstants.uiFontSize,
    this.fontFamily,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final TextStyle? hintStyle;
  final String? helperText;
  final String? errorText;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final bool isDense;
  final bool autofocus;
  final bool alignLabelWithHint;
  final double fontSize;
  final String? fontFamily;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: c.textPrimary, fontSize: fontSize, fontFamily: fontFamily),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
        hintText: hintText,
        hintStyle: hintStyle,
        helperText: helperText,
        helperStyle: TextStyle(color: c.faintFg, fontSize: ThemeConstants.uiFontSizeLabel),
        errorText: errorText,
        suffixIcon: suffixIcon,
        isDense: isDense,
        alignLabelWithHint: alignLabelWithHint,
      ),
    );
  }
}
