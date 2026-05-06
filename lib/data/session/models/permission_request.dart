import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_request.freezed.dart';
part 'permission_request.g.dart';

@freezed
abstract class PermissionRequest with _$PermissionRequest {
  const factory PermissionRequest({
    required String toolEventId,
    required String toolName,
    required String summary,
    required Map<String, dynamic> input,
  }) = _PermissionRequest;

  factory PermissionRequest.fromJson(Map<String, dynamic> json) => _$PermissionRequestFromJson(json);
}
