import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

class InlineTextField extends StatelessWidget {
  const InlineTextField({super.key, required this.controller, this.obscureText = false});

  final TextEditingController controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: c.textPrimary, fontSize: 12, fontFamily: ThemeConstants.editorFontFamily),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }
}
