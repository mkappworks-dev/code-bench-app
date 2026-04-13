import 'package:flutter/material.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/errors/app_exception.dart';

export 'async_error_view.dart';

/// Wraps a widget and catches any Flutter errors thrown during build,
/// showing a friendly error UI with an optional retry callback.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({super.key, required this.child, this.onRetry});

  final Widget child;
  final VoidCallback? onRetry;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _error = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorFallback(
        error: userMessage(_error!, fallback: 'An unexpected error occurred.'),
        onRetry: widget.onRetry != null
            ? () {
                setState(() => _error = null);
                widget.onRetry!();
              }
            : () => setState(() => _error = null),
      );
    }

    return widget.child;
  }
}

class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: ThemeConstants.error),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: ThemeConstants.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
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
