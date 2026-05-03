// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_code_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceCodeResponse _$DeviceCodeResponseFromJson(Map<String, dynamic> json) =>
    _DeviceCodeResponse(
      userCode: json['user_code'] as String,
      verificationUri: json['verification_uri'] as String,
      deviceCode: json['device_code'] as String,
      interval: (json['interval'] as num).toInt(),
      expiresIn: (json['expires_in'] as num).toInt(),
    );

Map<String, dynamic> _$DeviceCodeResponseToJson(_DeviceCodeResponse instance) =>
    <String, dynamic>{
      'user_code': instance.userCode,
      'verification_uri': instance.verificationUri,
      'device_code': instance.deviceCode,
      'interval': instance.interval,
      'expires_in': instance.expiresIn,
    };
