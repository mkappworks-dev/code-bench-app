import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_pr_failure.freezed.dart';

@freezed
sealed class CreatePrFailure with _$CreatePrFailure {
  const factory CreatePrFailure.notAuthenticated() = CreatePrNotAuthenticated;

  // GitHub returns 404 (not 403) for unauthorized repo-scoped endpoints.
  const factory CreatePrFailure.appNotInstalled() = CreatePrAppNotInstalled;

  const factory CreatePrFailure.network(String message) = CreatePrNetwork;
  const factory CreatePrFailure.permissionDenied() = CreatePrPermissionDenied;
  const factory CreatePrFailure.unknown(Object error) = CreatePrUnknownError;

  // Pre-formatted user-facing message; no re-translation needed at the widget layer.
  const factory CreatePrFailure.loadContentFailed(String message) = CreatePrLoadContentFailed;
}
