import 'package:freezed_annotation/freezed_annotation.dart';

part 'pr_preflight_result.freezed.dart';

/// Result of the fast GitHub preflight. Either the basic checks passed and we
/// have enough context to open the dialog, or something blocked the flow.
@freezed
sealed class PrPreflightResult with _$PrPreflightResult {
  /// Fast checks passed — owner/repo/branch are resolved, no existing PR was
  /// found. The dialog can open immediately while slow content loads async.
  const factory PrPreflightResult.passed({required String owner, required String repo, required String currentBranch}) =
      PrPreflightPassed;

  /// [actionUrl] / [actionLabel] are surfaced as a snackbar action button —
  /// e.g. "Install" linking to the GitHub App installation page when the
  /// preflight detects the App is not installed on the target repo.
  const factory PrPreflightResult.failed(String message, {String? actionUrl, String? actionLabel}) = PrPreflightFailed;
}
