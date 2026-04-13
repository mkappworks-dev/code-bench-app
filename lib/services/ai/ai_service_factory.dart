import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../data/_core/secure_storage.dart';
import '../../data/models/ai_model.dart';
import 'ai_service.dart';
import 'anthropic_service.dart';
import 'gemini_service.dart';
import 'ollama_service.dart';
import 'custom_ai_service.dart';
import 'openai_service.dart';

part 'ai_service_factory.g.dart';

@riverpod
Future<AIService?> aiService(Ref ref, AIProvider aiProvider) async {
  final storage = ref.watch(secureStorageProvider);

  switch (aiProvider) {
    case AIProvider.openai:
      final key = await storage.readApiKey('openai');
      if (key == null || key.isEmpty) return null;
      return OpenAIService(key);

    case AIProvider.anthropic:
      final key = await storage.readApiKey('anthropic');
      if (key == null || key.isEmpty) return null;
      return AnthropicService(key);

    case AIProvider.gemini:
      final key = await storage.readApiKey('gemini');
      if (key == null || key.isEmpty) return null;
      return GeminiService(key);

    case AIProvider.ollama:
      final url = await storage.readOllamaUrl() ?? ApiConstants.ollamaDefaultBaseUrl;
      return OllamaService(url);

    case AIProvider.custom:
      final endpoint = await storage.readCustomEndpoint();
      if (endpoint == null || endpoint.isEmpty) return null;
      final key = await storage.readCustomApiKey() ?? '';
      return CustomAIService(endpoint, key);
  }
}

@riverpod
Future<List<AIModel>> availableModels(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  final models = <AIModel>[];

  // Add defaults first
  models.addAll(AIModels.defaults);

  // Try to fetch Ollama models
  final ollamaUrl = await storage.readOllamaUrl() ?? ApiConstants.ollamaDefaultBaseUrl;
  final ollamaService = OllamaService(ollamaUrl);
  try {
    final ollamaModels = await ollamaService.fetchAvailableModels('');
    models.addAll(ollamaModels);
  } catch (_) {}

  return models;
}
