import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_code_response.freezed.dart';
part 'device_code_response.g.dart';

/// Response from `POST https://github.com/login/device/code`.
///
/// `userCode` — 8-character code (e.g. `WDJB-MJHT`) the user types at
/// `verificationUri`. `deviceCode` is the opaque code the app uses when
/// polling `/login/oauth/access_token`. `interval` is the minimum
/// poll-frequency in seconds GitHub asks us to respect.
@freezed
abstract class DeviceCodeResponse with _$DeviceCodeResponse {
  const factory DeviceCodeResponse({
    @JsonKey(name: 'user_code') required String userCode,
    @JsonKey(name: 'verification_uri') required String verificationUri,
    @JsonKey(name: 'device_code') required String deviceCode,
    required int interval,
    @JsonKey(name: 'expires_in') required int expiresIn,
  }) = _DeviceCodeResponse;

  factory DeviceCodeResponse.fromJson(Map<String, dynamic> json) => _$DeviceCodeResponseFromJson(json);
}
