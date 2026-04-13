import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/api_key_test_datasource_dio.dart';
import '../../../data/models/ai_model.dart';
import 'api_key_test_repository.dart';

part 'api_key_test_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ApiKeyTestRepository apiKeyTestRepository(Ref ref) => ApiKeyTestRepositoryImpl(datasource: ApiKeyTestDatasourceDio());

/// Validates AI provider credentials and local Ollama connectivity via live
/// HTTP probes. Delegates all Dio usage to [ApiKeyTestDatasourceDio] to keep
/// the repository layer clean of direct HTTP instantiation.
///
/// ### Security
/// API keys are sent as headers, never as query-string parameters. Dio's
/// DioException.toString() serialises the request URL, so a query-param key
/// would be leaked if anything ever prints the exception. See
/// `macos/Runner/README.md` for the full threat model.
class ApiKeyTestRepositoryImpl implements ApiKeyTestRepository {
  ApiKeyTestRepositoryImpl({required ApiKeyTestDatasourceDio datasource}) : _datasource = datasource;

  final ApiKeyTestDatasourceDio _datasource;

  @override
  Future<bool> testApiKey(AIProvider provider, String key) => _datasource.testApiKey(provider, key);

  @override
  Future<bool> testOllamaUrl(String url) => _datasource.testOllamaUrl(url);
}
