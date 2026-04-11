import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';

/// Shows a before/after diff dialog and applies the AI code to the active file.
///
/// TODO: Re-implement once the new chat-first editor integration is available.
Future<void> showApplyCodeDialog(BuildContext context, WidgetRef ref, String newCode, String language) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Apply code is not yet available in the new layout.'),
      backgroundColor: ThemeConstants.warning,
    ),
  );
}
