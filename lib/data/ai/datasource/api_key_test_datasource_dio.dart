import 'package:dio/dio.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/http/dio_factory.dart';
import '../../../data/shared/ai_model.dart';

/// HTTP probes for validating AI provider API keys.
/// Called by [ApiKeyTestRepositoryImpl] — this file owns all Dio usage.
class ApiKeyTestDatasourceDio {
  Future<bool> testApiKey(AIProvider provider, String key) {
    return switch (provider) {
      AIProvider.openai => _testOpenAI(key),
      AIProvider.anthropic => _testAnthropic(key),
      AIProvider.gemini => _testGemini(key),
      _ => Future.value(false),
    };
  }

  Future<bool> testOllamaUrl(String url) async {
    try {
      final dio = DioFactory.create(baseUrl: url, connectTimeout: const Duration(seconds: 5));
      await dio.get('/api/tags');
      return true;
    } on DioException catch (e) {
      dLog('[ApiKeyTestDatasource] testOllamaUrl failed: ${e.type} ${e.response?.statusCode}');
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
    } on DioException catch (e) {
      dLog('[ApiKeyTestDatasource] testOpenAI failed: ${e.type} ${e.response?.statusCode}');
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
    } on DioException catch (e) {
      dLog('[ApiKeyTestDatasource] testGemini failed: ${e.type} ${e.response?.statusCode}');
      return false;
    }
  }
}
