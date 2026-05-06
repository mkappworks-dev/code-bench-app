import 'package:code_bench_app/features/chat/widgets/provider_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('providerLabelFor', () {
    test('null id returns null', () {
      expect(providerLabelFor(null), isNull);
    });

    test('empty string returns null', () {
      expect(providerLabelFor(''), isNull);
    });

    test('"claude-cli" returns "Claude Code CLI"', () {
      expect(providerLabelFor('claude-cli'), 'Claude Code CLI');
    });

    test('"codex" returns "Codex CLI"', () {
      expect(providerLabelFor('codex'), 'Codex CLI');
    });

    test('"anthropic" returns "Anthropic API"', () {
      expect(providerLabelFor('anthropic'), 'Anthropic API');
    });

    test('"openai" returns "OpenAI API"', () {
      expect(providerLabelFor('openai'), 'OpenAI API');
    });

    test('"gemini" returns "Gemini API"', () {
      expect(providerLabelFor('gemini'), 'Gemini API');
    });

    test('"ollama" returns "Ollama"', () {
      expect(providerLabelFor('ollama'), 'Ollama');
    });

    test('"custom" returns "Custom"', () {
      expect(providerLabelFor('custom'), 'Custom');
    });

    test('unknown id returns the raw id (last-resort fallback)', () {
      expect(providerLabelFor('something-new'), 'something-new');
    });
  });
}
