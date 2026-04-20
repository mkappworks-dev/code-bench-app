import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_request.freezed.dart';
part 'permission_request.g.dart';

/// A pending approval request emitted by the agent loop in [ChatPermission.askBefore]
/// mode. Rendered by [PermissionRequestCard]; resolved through
/// [AgentPermissionRequestNotifier].
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
