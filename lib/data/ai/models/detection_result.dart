import 'package:freezed_annotation/freezed_annotation.dart';

part 'detection_result.freezed.dart';

/// Result of a CLI/CLI provider detection probe.
///
/// `installed` — binary on PATH and `--version` succeeded.
/// `unhealthy` — binary on PATH but the version probe failed (broken
///               install, hung process, garbage stdout). Surfacing this as
///               its own state lets the UI tell users to reinstall vs
///               install for the first time.
/// `missing`   — binary not on PATH.
@freezed
sealed class DetectionResult with _$DetectionResult {
  const factory DetectionResult.installed(String version) = DetectionInstalled;
  const factory DetectionResult.unhealthy(String reason) = DetectionUnhealthy;
  const factory DetectionResult.missing() = DetectionMissing;
}
