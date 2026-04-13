import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/_core/http/dio_factory.dart';
import '../data/models/ai_model.dart';

part 'api_key_test_service.g.dart';

@Riverpod(keepAlive: true)
ApiKeyTestService apiKeyTestService(Ref ref) => ApiKeyTestService();

/// Validates AI provider credentials and local Ollama connectivity via live
/// HTTP probes. All Dio instantiation and network calls are confined here so
/// no widget or notifier ever touches Dio directly.
///
/// ### Security
/// API keys are sent as headers, never as query-string parameters. Dio's
/// DioException.toString() serialises the request URL, so a query-param key
/// would be leaked if anything ever prints the exception. See
/// `macos/Runner/README.md` for the full threat model.
class ApiKeyTestService {
  /// Returns `true` when [key] is accepted by [provider]'s API.
  Future<bool> testApiKey(AIProvider provider, String key) {
    return switch (provider) {
      AIProvider.openai => _testOpenAI(key),
      AIProvider.anthropic => _testAnthropic(key),
      AIProvider.gemini => _testGemini(key),
      _ => Future.value(false),
    };
  }

  /// Returns `true` when an Ollama instance is reachable at [url].
  Future<bool> testOllamaUrl(String url) async {
    try {
      final dio = DioFactory.create(baseUrl: url, connectTimeout: const Duration(seconds: 5));
      await dio.get('/api/tags');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _testOpenAI(String key) async {
    try {
      final dio = DioFactory.create(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer $key'},
      );
      await dio.get('/models');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _testAnthropic(String key) async {
    try {
      final dio = DioFactory.create(
        baseUrl: 'https://api.anthropic.com/v1',
        connectTimeout: const Duration(seconds: 10),
        headers: {'x-api-key': key, 'anthropic-version': '2023-06-01', 'content-type': 'application/json'},
      );
      await dio.post(
        '/messages',
        data: {
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'hi'},
          ],
        },
      );
      return true;
    } on DioException catch (e) {
      // Inspect the typed status code rather than searching e.toString() for
      // "400" — a URL fragment or unrelated error message containing "400"
      // would otherwise flip a broken key to "valid".
      //   400 → key accepted, request body rejected → key is valid
      //   401/403 → key rejected → key is invalid
      //   anything else (timeout, 5xx, no response) → can't verify → invalid
      return e.response?.statusCode == 400;
    }
  }

  Future<bool> _testGemini(String key) async {
    try {
      // SECURITY: Send the key via the `x-goog-api-key` header, NOT as a
      // query-string parameter. See class-level doc for rationale.
      final dio = DioFactory.create(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        connectTimeout: const Duration(seconds: 10),
        headers: {'x-goog-api-key': key},
      );
      await dio.get('/models');
      return true;
    } catch (_) {
      return false;
    }
  }
}
