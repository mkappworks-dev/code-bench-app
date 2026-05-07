import 'package:code_bench_app/data/ai/datasource/anthropic_remote_datasource_dio.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:flutter_test/flutter_test.dart';

AIModel _m(String id) => AIModel(id: id, provider: AIProvider.anthropic, name: id, modelId: id);

void main() {
  group('dropSupersededAnthropicSnapshots', () {
    test('keeps newest dated snapshot per family', () {
      final input = [
        _m('claude-3-5-sonnet-20240620'),
        _m('claude-3-5-sonnet-20241022'),
        _m('claude-3-5-haiku-20241022'),
      ];
      final ids = dropSupersededAnthropicSnapshots(input).map((m) => m.modelId).toList();
      expect(ids, ['claude-3-5-sonnet-20241022', 'claude-3-5-haiku-20241022']);
    });

    test('respects API order when picking the slot for the kept entry', () {
      final input = [
        _m('claude-opus-4-7-20251201'),
        _m('claude-3-5-sonnet-20240620'),
        _m('claude-3-5-sonnet-20241022'),
      ];
      final ids = dropSupersededAnthropicSnapshots(input).map((m) => m.modelId).toList();
      expect(ids, ['claude-opus-4-7-20251201', 'claude-3-5-sonnet-20241022']);
    });

    test('passes undated entries through verbatim', () {
      final input = [
        _m('claude-3-5-sonnet-latest'),
        _m('claude-3-5-sonnet-20240620'),
        _m('claude-3-5-sonnet-20241022'),
      ];
      final ids = dropSupersededAnthropicSnapshots(input).map((m) => m.modelId).toList();
      expect(ids, ['claude-3-5-sonnet-latest', 'claude-3-5-sonnet-20241022']);
    });

    test('different families with the same date are independent', () {
      final input = [_m('claude-opus-4-20250514'), _m('claude-sonnet-4-20250514')];
      final ids = dropSupersededAnthropicSnapshots(input).map((m) => m.modelId).toList();
      expect(ids, ['claude-opus-4-20250514', 'claude-sonnet-4-20250514']);
    });

    test('older revision before newer still results in newer kept', () {
      final input = [
        _m('claude-3-5-sonnet-20240620'),
        _m('claude-3-5-sonnet-20241022'),
        _m('claude-3-5-sonnet-20240307'),
      ];
      final ids = dropSupersededAnthropicSnapshots(input).map((m) => m.modelId).toList();
      expect(ids, ['claude-3-5-sonnet-20241022']);
    });
  });
}
