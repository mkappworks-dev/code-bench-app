import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';

class InlineTextField extends StatelessWidget {
  const InlineTextField({super.key, required this.controller, this.obscureText = false});

  final TextEditingController controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: ThemeConstants.textPrimary,
        fontSize: 12,
        fontFamily: ThemeConstants.editorFontFamily,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }
}
