import 'package:flutter/material.dart';
import '../widgets/app_snack_bar.dart';

void showErrorSnackBar(BuildContext context, String label, {String? detail}) {
  AppSnackBar.show(context, label, message: detail, type: AppSnackBarType.error);
}

void showSuccessSnackBar(BuildContext context, String label, {String? detail}) {
  AppSnackBar.show(context, label, message: detail, type: AppSnackBarType.success);
}
