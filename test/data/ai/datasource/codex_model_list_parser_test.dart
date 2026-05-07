import 'package:code_bench_app/data/ai/datasource/codex_cli_datasource_process.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCodexModelList', () {
    // Real shape captured from `codex app-server` model/list — version 0.128.
    final liveResult = {
      'data': [
        {
          'id': 'gpt-5.5',
          'model': 'gpt-5.5',
          'displayName': 'GPT-5.5',
          'isDefault': true,
          'hidden': false,
          'description': '',
          'defaultReasoningEffort': 'medium',
          'supportedReasoningEfforts': [],
        },
        {
          'id': 'gpt-5.4-mini',
          'model': 'gpt-5.4-mini',
          'displayName': 'GPT-5.4-Mini',
          'isDefault': false,
          'hidden': false,
          'description': '',
          'defaultReasoningEffort': 'medium',
          'supportedReasoningEfforts': [],
        },
        {
          'id': 'gpt-oss-120b',
          'model': 'gpt-oss-120b',
          'displayName': 'gpt-oss-120b',
          'isDefault': false,
          'hidden': true,
          'description': '',
          'defaultReasoningEffort': 'medium',
          'supportedReasoningEfforts': [],
        },
        {
          'id': 'codex-auto-review',
          'model': 'codex-auto-review',
          'displayName': 'Codex Auto Review',
          'isDefault': false,
          'hidden': true,
          'description': '',
          'defaultReasoningEffort': 'medium',
          'supportedReasoningEfforts': [],
        },
      ],
    };

    test('keeps non-hidden entries and drops hidden ones', () {
      final models = parseCodexModelList(liveResult);
      expect(models.map((m) => m.modelId).toList(), ['gpt-5.5', 'gpt-5.4-mini']);
    });

    test('attributes everything to the OpenAI provider slot', () {
      final models = parseCodexModelList(liveResult);
      expect(models.every((m) => m.provider == AIProvider.openai), isTrue);
    });

    test('uses displayName for the user-facing label', () {
      final models = parseCodexModelList(liveResult);
      expect(models.first.name, 'GPT-5.5');
      expect(models.last.name, 'GPT-5.4-Mini');
    });

    test('falls back to id when displayName is missing or empty', () {
      final result = {
        'data': [
          {'id': 'foo', 'model': 'foo', 'hidden': false},
          {'id': 'bar', 'model': 'bar', 'displayName': '', 'hidden': false},
        ],
      };
      final models = parseCodexModelList(result);
      expect(models.map((m) => m.name).toList(), ['foo', 'bar']);
    });

    test('skips entries missing id or model', () {
      final result = {
        'data': [
          {'model': 'no-id', 'hidden': false},
          {'id': 'no-model', 'hidden': false},
          {'id': 'good', 'model': 'good', 'hidden': false},
        ],
      };
      final models = parseCodexModelList(result);
      expect(models.map((m) => m.modelId).toList(), ['good']);
    });

    test('returns empty when data is missing or wrong shape', () {
      expect(parseCodexModelList(<String, dynamic>{}), isEmpty);
      expect(parseCodexModelList({'data': 'not a list'}), isEmpty);
      expect(parseCodexModelList({'data': []}), isEmpty);
    });
  });
}
