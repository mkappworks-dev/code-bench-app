import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';

/// Shows a before/after diff dialog and applies the AI code to the active file.
///
/// TODO: Re-implement once the new chat-first editor integration is available.
Future<void> showApplyCodeDialog(BuildContext context, WidgetRef ref, String newCode, String language) async {
  AppSnackBar.show(context, 'Apply code is not yet available in the new layout.', type: AppSnackBarType.warning);
}
