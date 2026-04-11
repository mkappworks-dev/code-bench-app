import 'package:flutter/material.dart';

import '../constants/theme_constants.dart';

/// Shows a red error snackbar. Use for action failures visible to the user.
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: ThemeConstants.error,
    ),
  );
}

/// Shows a neutral snackbar. Use for confirmations (e.g. "Copied").
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
