import '../../coding_tools/models/tool.dart';
import '../../shared/ai_model.dart';
import '../models/stream_event.dart';

/// Capability for repositories that stream function-calling / tool-use
/// events. Only the custom OpenAI-compatible path supports this in the MVP;
/// other transports omit the capability rather than declaring it and
/// throwing at runtime.
abstract interface class ToolStreamingRepository {
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> wireMessages,
    required List<Tool> tools,
    required AIModel model,
  });
}
