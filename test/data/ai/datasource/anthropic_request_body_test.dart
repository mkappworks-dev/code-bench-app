import 'package:code_bench_app/data/ai/datasource/anthropic_remote_datasource_dio.dart';
import 'package:code_bench_app/data/ai/models/provider_turn_settings.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sonnet = AIModel(
    id: 'claude-sonnet-4-5',
    provider: AIProvider.anthropic,
    name: 'Sonnet 4.5',
    modelId: 'claude-sonnet-4-5',
  );
  const opus47 = AIModel(
    id: 'claude-opus-4-7',
    provider: AIProvider.anthropic,
    name: 'Opus 4.7',
    modelId: 'claude-opus-4-7',
  );

  group('buildAnthropicRequestBody', () {
    test('no settings → no thinking field', () {
      final body = buildAnthropicRequestBody(model: sonnet, messages: const [], maxTokens: 4096);
      expect(body.containsKey('thinking'), isFalse);
      expect(body['model'], 'claude-sonnet-4-5');
    });

    test('effort=high on Sonnet → thinking with budget 16384', () {
      final body = buildAnthropicRequestBody(
        model: sonnet,
        messages: const [],
        maxTokens: 32768,
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body['thinking'], {'type': 'enabled', 'budget_tokens': 16384});
    });

    test('effort=high on Opus 4.7+ → no thinking field', () {
      final body = buildAnthropicRequestBody(
        model: opus47,
        messages: const [],
        maxTokens: 32768,
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body.containsKey('thinking'), isFalse);
    });

    test('clamps budget when raw >= maxTokens', () {
      final body = buildAnthropicRequestBody(
        model: sonnet,
        messages: const [],
        maxTokens: 4096,
        settings: const ProviderTurnSettings(effort: ChatEffort.max),
      );
      expect(body['thinking']['budget_tokens'], 4095);
    });

    test('systemPrompt populates system field', () {
      final body = buildAnthropicRequestBody(
        model: sonnet,
        messages: const [],
        maxTokens: 4096,
        systemPrompt: 'be concise',
      );
      expect(body['system'], 'be concise');
    });
  });
}
