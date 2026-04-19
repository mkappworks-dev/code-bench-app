import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/ai/repository/api_key_test_repository.dart';
import '../../data/ai/repository/api_key_test_repository_impl.dart';
import '../../data/shared/ai_model.dart';

export '../../data/shared/ai_model.dart' show AIProvider;

part 'api_key_test_service.g.dart';

@Riverpod(keepAlive: true)
ApiKeyTestService apiKeyTestService(Ref ref) {
  return ApiKeyTestService(repo: ref.watch(apiKeyTestRepositoryProvider));
}

/// Thin delegation service for API key validation operations.
class ApiKeyTestService {
  ApiKeyTestService({required ApiKeyTestRepository repo}) : _repo = repo;

  final ApiKeyTestRepository _repo;

  Future<bool> testApiKey(AIProvider provider, String key) => _repo.testApiKey(provider, key);

  Future<bool> testOllamaUrl(String url) => _repo.testOllamaUrl(url);

  Future<bool> testCustomEndpoint(String url, String apiKey) => _repo.testCustomEndpoint(url, apiKey);
}
