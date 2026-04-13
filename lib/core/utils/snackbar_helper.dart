import 'package:flutter/material.dart';
import '../widgets/app_snack_bar.dart';

/// Shows a frosted error snackbar.
void showErrorSnackBar(BuildContext context, String label, {String? detail}) {
  AppSnackBar.show(context, label, message: detail, type: AppSnackBarType.error);
}

/// Shows a frosted success snackbar.
void showSuccessSnackBar(BuildContext context, String label, {String? detail}) {
  AppSnackBar.show(context, label, message: detail, type: AppSnackBarType.success);
}
