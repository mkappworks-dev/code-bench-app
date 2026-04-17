import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_settings_failure.freezed.dart';

@freezed
sealed class SessionSettingsFailure with _$SessionSettingsFailure {
  const factory SessionSettingsFailure.unknown(Object error) = SessionSettingsUnknownFailure;
}
