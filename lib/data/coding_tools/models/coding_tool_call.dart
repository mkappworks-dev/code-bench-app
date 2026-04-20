/// A single tool invocation emitted by the model. Constructed by
/// [AgentService] after assembling [StreamEvent]s into a complete call.
class CodingToolCall {
  const CodingToolCall({required this.id, required this.name, required this.args});

  final String id;
  final String name;
  final Map<String, dynamic> args;
}
