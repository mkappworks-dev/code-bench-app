import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_pr_failure.freezed.dart';

@freezed
sealed class CreatePrFailure with _$CreatePrFailure {
  const factory CreatePrFailure.notAuthenticated() = CreatePrNotAuthenticated;
  const factory CreatePrFailure.network(String message) = CreatePrNetwork;
  const factory CreatePrFailure.permissionDenied() = CreatePrPermissionDenied;
  const factory CreatePrFailure.unknown(Object error) = CreatePrUnknownError;
}
