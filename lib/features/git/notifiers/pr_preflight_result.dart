import 'package:freezed_annotation/freezed_annotation.dart';

part 'pr_preflight_result.freezed.dart';

@freezed
sealed class PrPreflightResult with _$PrPreflightResult {
  const factory PrPreflightResult.passed({required String owner, required String repo, required String currentBranch}) =
      PrPreflightPassed;

  // actionUrl/actionLabel surface as a snackbar action — e.g. "Install" for a missing App installation.
  const factory PrPreflightResult.failed(String message, {String? actionUrl, String? actionLabel}) = PrPreflightFailed;
}
