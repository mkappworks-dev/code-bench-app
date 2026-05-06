import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/session_settings.dart';

part 'provider_turn_settings.freezed.dart';
part 'provider_turn_settings.g.dart';

@freezed
abstract class ProviderTurnSettings with _$ProviderTurnSettings {
  const factory ProviderTurnSettings({
    String? modelId,
    String? systemPrompt,
    ChatMode? mode,
    ChatEffort? effort,
    ChatPermission? permission,
  }) = _ProviderTurnSettings;

  factory ProviderTurnSettings.fromJson(Map<String, dynamic> json) => _$ProviderTurnSettingsFromJson(json);
}
