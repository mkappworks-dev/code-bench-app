import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../notifiers/ripgrep_availability_notifier.dart';

/// Shows nothing when ripgrep is available. Shows an install-hint banner
/// when it is not. "Check again" re-runs the rg version check.
class RipgrepAvailabilityBanner extends ConsumerWidget {
  const RipgrepAvailabilityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ripgrepAvailabilityProvider);
    return state.when(
      loading: () => const Padding(padding: EdgeInsets.only(bottom: 16), child: LinearProgressIndicator()),
      error: (e, st) => _buildBanner(context, ref),
      data: (available) => available ? const SizedBox.shrink() : _buildBanner(context, ref),
    );
  }

  Widget _buildBanner(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final installCmd = switch (defaultTargetPlatform) {
      TargetPlatform.macOS => 'brew install ripgrep',
      TargetPlatform.linux => 'sudo apt install ripgrep',
      _ => 'winget install ripgrep',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warningTintBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 16),
              const SizedBox(width: 6),
              Text(
                'Grep backend: Pure Dart (fallback)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Install ripgrep for faster searches.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            installCmd,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => ref.read(ripgrepAvailabilityProvider.notifier).recheck(),
              child: const Text('Check again'),
            ),
          ),
        ],
      ),
    );
  }
}
