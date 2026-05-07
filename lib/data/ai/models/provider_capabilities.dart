import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/session_settings.dart';

part 'provider_capabilities.freezed.dart';

@freezed
abstract class ProviderCapabilities with _$ProviderCapabilities {
  const factory ProviderCapabilities({
    @Default(false) bool supportsModelOverride,
    @Default(false) bool supportsSystemPrompt,
    @Default(<ChatMode>{}) Set<ChatMode> supportedModes,
    @Default(<ChatEffort>{}) Set<ChatEffort> supportedEfforts,
    @Default(<ChatPermission>{}) Set<ChatPermission> supportedPermissions,
  }) = _ProviderCapabilities;
}
