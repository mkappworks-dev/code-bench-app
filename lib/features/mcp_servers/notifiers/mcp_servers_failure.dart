import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_servers_failure.freezed.dart';

@freezed
sealed class McpServersFailure with _$McpServersFailure {
  const factory McpServersFailure.saveError([String? detail]) = McpServersSaveError;
  const factory McpServersFailure.removeError([String? detail]) = McpServersRemoveError;
  const factory McpServersFailure.unknown(Object error) = McpServersUnknownError;
}
