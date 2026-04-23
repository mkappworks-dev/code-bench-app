import '../../shared/ai_model.dart';

/// Domain-level AI API for provider-selection primitives (auth + model
/// enumeration).
///
/// Text streaming and tool-use streaming are separate, orthogonal
/// capabilities declared by `TextStreamingRepository` and
/// `ToolStreamingRepository`. Consumers that need those capabilities
/// depend on the narrow interfaces directly.
abstract interface class AIRepository {
  Future<bool> testConnection(AIModel model, String apiKey);

  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey);
}
