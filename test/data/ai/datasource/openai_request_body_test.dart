import 'package:code_bench_app/data/ai/datasource/openai_remote_datasource_dio.dart';
import 'package:code_bench_app/data/ai/models/provider_turn_settings.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gpt5 = AIModel(id: 'gpt-5', provider: AIProvider.openai, name: 'GPT-5', modelId: 'gpt-5');
  const gpt4o = AIModel(id: 'gpt-4o', provider: AIProvider.openai, name: 'GPT-4o', modelId: 'gpt-4o');

  group('buildOpenAiRequestBody', () {
    test('reasoning model + effort → reasoning_effort field present', () {
      final body = buildOpenAiRequestBody(
        model: gpt5,
        messages: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.medium),
      );
      expect(body['reasoning_effort'], 'medium');
    });

    test('non-reasoning model + effort → no reasoning_effort', () {
      final body = buildOpenAiRequestBody(
        model: gpt4o,
        messages: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body.containsKey('reasoning_effort'), isFalse);
    });

    test('max → xhigh', () {
      final body = buildOpenAiRequestBody(
        model: gpt5,
        messages: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.max),
      );
      expect(body['reasoning_effort'], 'xhigh');
    });
  });
}
