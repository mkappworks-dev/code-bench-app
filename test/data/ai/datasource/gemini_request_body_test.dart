import 'package:code_bench_app/data/ai/datasource/gemini_remote_datasource_dio.dart';
import 'package:code_bench_app/data/ai/models/provider_turn_settings.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gem25 = AIModel(
    id: 'gemini-2.5-flash',
    provider: AIProvider.gemini,
    name: 'Gemini 2.5 Flash',
    modelId: 'gemini-2.5-flash',
  );
  const gem3 = AIModel(id: 'gemini-3-pro', provider: AIProvider.gemini, name: 'Gemini 3 Pro', modelId: 'gemini-3-pro');
  const gem15 = AIModel(
    id: 'gemini-1.5-pro',
    provider: AIProvider.gemini,
    name: 'Gemini 1.5 Pro',
    modelId: 'gemini-1.5-pro',
  );

  group('buildGeminiRequestBody', () {
    test('Gemini 2.5 + effort=high → thinkingBudget integer', () {
      final body = buildGeminiRequestBody(
        model: gem25,
        contents: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body['generationConfig']['thinkingConfig'], {'thinkingBudget': 16384});
    });

    test('Gemini 2.5 + effort=max → thinkingBudget=-1 (dynamic)', () {
      final body = buildGeminiRequestBody(
        model: gem25,
        contents: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.max),
      );
      expect(body['generationConfig']['thinkingConfig'], {'thinkingBudget': -1});
    });

    test('Gemini 3 + effort=max → thinkingLevel=high', () {
      final body = buildGeminiRequestBody(
        model: gem3,
        contents: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.max),
      );
      expect(body['generationConfig']['thinkingConfig'], {'thinkingLevel': 'high'});
    });

    test('Gemini 1.5 → no generationConfig', () {
      final body = buildGeminiRequestBody(
        model: gem15,
        contents: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body.containsKey('generationConfig'), isFalse);
    });

    test('systemPrompt populates system_instruction', () {
      final body = buildGeminiRequestBody(model: gem25, contents: const [], systemPrompt: 'be concise');
      expect(body['system_instruction'], {
        'parts': [
          {'text': 'be concise'},
        ],
      });
    });
  });
}
