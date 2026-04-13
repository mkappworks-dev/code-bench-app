import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/ai/datasource/api_key_test_datasource_dio.dart';
import '../data/models/ai_model.dart';

part 'api_key_test_service.g.dart';

@Riverpod(keepAlive: true)
ApiKeyTestService apiKeyTestService(Ref ref) => ApiKeyTestService(datasource: ApiKeyTestDatasourceDio());

/// Validates AI provider credentials and local Ollama connectivity via live
/// HTTP probes. Delegates all Dio usage to [ApiKeyTestDatasourceDio] to keep
/// the service layer clean of direct HTTP instantiation.
///
/// ### Security
/// API keys are sent as headers, never as query-string parameters. Dio's
/// DioException.toString() serialises the request URL, so a query-param key
/// would be leaked if anything ever prints the exception. See
/// `macos/Runner/README.md` for the full threat model.
class ApiKeyTestService {
  ApiKeyTestService({required ApiKeyTestDatasourceDio datasource}) : _datasource = datasource;

  final ApiKeyTestDatasourceDio _datasource;

  /// Returns `true` when [key] is accepted by [provider]'s API.
  Future<bool> testApiKey(AIProvider provider, String key) => _datasource.testApiKey(provider, key);

  /// Returns `true` when an Ollama instance is reachable at [url].
  Future<bool> testOllamaUrl(String url) => _datasource.testOllamaUrl(url);
}
