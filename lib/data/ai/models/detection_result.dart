import 'package:freezed_annotation/freezed_annotation.dart';

part 'detection_result.freezed.dart';

/// Result of a CLI provider detection probe.
/// `installed` — binary found and version probe succeeded.
/// `unhealthy` — binary found but probe failed; UI can distinguish reinstall vs first-time install.
/// `missing` — binary not on PATH.
@freezed
sealed class DetectionResult with _$DetectionResult {
  const factory DetectionResult.installed(String version) = DetectionInstalled;
  const factory DetectionResult.unhealthy(String reason) = DetectionUnhealthy;
  const factory DetectionResult.missing() = DetectionMissing;
}
