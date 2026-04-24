import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'models/cli_detection.dart';

part 'claude_cli_detector.g.dart';

/// Probe contract the Claude CLI datasource depends on to resolve an
/// absolute binary path + installed status.
///
/// Declared here (data layer) rather than in `lib/services/` so the data
/// layer stays a dependency-graph leaf. The production implementation
/// lives in `CliDetectionService` (service layer, TTL cache) and is wired
/// via an `overrideWith` in `lib/main.dart` — see
/// `lib/services/cli/cli_detection_service.dart` for the concrete probe.
typedef ClaudeCliDetector = Future<CliDetection> Function();

/// Default probe used when no override is registered — reports "not
/// installed" so tests and headless tools don't need the full service
/// graph just to construct `AIRepositoryImpl`.
@Riverpod(keepAlive: true)
ClaudeCliDetector claudeCliDetector(Ref ref) {
  return () async => const CliDetection.notInstalled();
}
