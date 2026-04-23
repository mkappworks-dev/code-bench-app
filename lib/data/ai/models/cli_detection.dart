import 'package:freezed_annotation/freezed_annotation.dart';

part 'cli_detection.freezed.dart';

/// Authentication status of the Claude Code CLI binary.
enum CliAuthStatus { authenticated, unauthenticated, unknown }

/// Result of probing the local filesystem/shell for the Claude Code CLI.
///
/// Cached by `CliDetectionService` with a short TTL so UI can render the
/// provider-card badge without re-running `claude --version` on every paint.
@freezed
sealed class CliDetection with _$CliDetection {
  const factory CliDetection.notInstalled() = CliNotInstalled;

  const factory CliDetection.installed({
    required String version,
    required String binaryPath,
    required CliAuthStatus authStatus,
    required DateTime checkedAt,
  }) = CliInstalled;
}
