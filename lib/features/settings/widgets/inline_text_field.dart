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
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark ? ThemeConstants.textPrimary : ThemeConstants.lightText,
        fontSize: 12,
        fontFamily: ThemeConstants.editorFontFamily,
      ),
      decoration: const InputDecoration(),
    );
  }
}
