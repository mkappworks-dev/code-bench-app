import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_tool_info.freezed.dart';
part 'mcp_tool_info.g.dart';

@freezed
abstract class McpToolInfo with _$McpToolInfo {
  const factory McpToolInfo({
    required String name,
    required String description,
    required Map<String, dynamic> inputSchema,
  }) = _McpToolInfo;

  factory McpToolInfo.fromJson(Map<String, dynamic> json) => _$McpToolInfoFromJson(json);
}
