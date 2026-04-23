import '../../shared/ai_model.dart';

/// Single-provider I/O boundary. Every concrete transport implements this.
/// Speaks wire protocol only — no persistence, no retries, no
/// provider-selection logic.
///
/// Text-token streaming is a separate, orthogonal capability declared by
/// `TextStreamingDatasource` in `text_streaming_datasource.dart`. Callers
/// that need raw text streaming must check `ds is TextStreamingDatasource`
/// before invoking `streamMessage`.
abstract interface class AIRemoteDatasource {
  AIProvider get provider;

  Future<bool> testConnection(AIModel model, String apiKey);

  Future<List<AIModel>> fetchAvailableModels(String apiKey);
}
