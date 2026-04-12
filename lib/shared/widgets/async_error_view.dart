import 'package:flutter/material.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/errors/app_exception.dart';

/// A Riverpod-aware error view used in `AsyncValue.when` error callbacks.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: ThemeConstants.error),
            const SizedBox(height: 12),
            Text(
              userMessage(error, fallback: 'An unexpected error occurred.'),
              style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
