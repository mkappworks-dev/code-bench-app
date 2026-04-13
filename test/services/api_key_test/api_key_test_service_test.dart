import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/ai/repository/api_key_test_repository.dart';
import 'package:code_bench_app/services/api_key_test/api_key_test_service.dart';

class _FakeRepo extends Fake implements ApiKeyTestRepository {
  @override
  Future<bool> testApiKey(AIProvider provider, String key) async => true;
  @override
  Future<bool> testOllamaUrl(String url) async => false;
}

void main() {
  test('testApiKey delegates to repository', () async {
    final svc = ApiKeyTestService(repo: _FakeRepo());
    expect(await svc.testApiKey(AIProvider.anthropic, 'key'), isTrue);
  });

  test('testOllamaUrl delegates to repository', () async {
    final svc = ApiKeyTestService(repo: _FakeRepo());
    expect(await svc.testOllamaUrl('http://localhost:11434'), isFalse);
  });
}
