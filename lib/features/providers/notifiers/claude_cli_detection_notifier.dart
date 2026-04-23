import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/cli_detection.dart';
import '../../../services/cli/cli_detection_service.dart';

part 'claude_cli_detection_notifier.g.dart';

/// Widget-facing read-through for the local Claude Code CLI detection probe.
///
/// Widgets watch this for the latest [CliDetection] state. The underlying
/// [CliDetectionService] is a TTL-cached probe; [recheck] bypasses the cache.
@Riverpod(keepAlive: true)
class ClaudeCliDetectionNotifier extends _$ClaudeCliDetectionNotifier {
  static const _binary = 'claude';

  @override
  Future<CliDetection> build() async {
    return ref.read(cliDetectionServiceProvider.notifier).probe(_binary);
  }

  /// Forces a fresh probe (bypasses the service-level TTL cache) and updates
  /// the notifier's state. Callers should `await` this before reading state
  /// to ensure the new probe has completed.
  Future<void> recheck() async {
    ref.read(cliDetectionServiceProvider.notifier).invalidate(_binary);
    ref.invalidateSelf();
    await future;
  }
}
