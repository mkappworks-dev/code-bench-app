// lib/data/coding_tools/models/tool.dart

import 'coding_tool_result.dart';
import 'tool_capability.dart';
import 'tool_context.dart';

/// A single tool the agent loop may call. Concrete implementations live
/// in `lib/services/coding_tools/tools/`; each holds its own dependencies
/// via constructor injection and is registered into [ToolRegistry]
/// through a Riverpod provider.
abstract class Tool {
  String get name;
  String get description;
  Map<String, dynamic> get inputSchema;
  ToolCapability get capability;

  Future<CodingToolResult> execute(ToolContext ctx);

  /// Serializes to the OpenAI chat-completions `tools[]` schema, used by
  /// [CustomRemoteDatasourceDio] when building the request body. Replaces
  /// `CodingToolDefinition.toOpenAiToolJson()`.
  Map<String, dynamic> toOpenAiToolJson() => {
    'type': 'function',
    'function': {'name': name, 'description': description, 'parameters': inputSchema},
  };
}
