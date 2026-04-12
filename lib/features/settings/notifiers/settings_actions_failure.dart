import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_actions_failure.freezed.dart';

@freezed
sealed class SettingsActionsFailure with _$SettingsActionsFailure {
  const factory SettingsActionsFailure.storageFailed(String providerName) = SettingsStorageFailed;
  const factory SettingsActionsFailure.unknown(Object error) = SettingsUnknownError;
}
