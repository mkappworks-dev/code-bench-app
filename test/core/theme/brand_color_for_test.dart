import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/core/theme/brand_color_for.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const c = AppColors.dark;

  group('brandColorFor', () {
    test('claude-cli and anthropic share Anthropic brand', () {
      expect(brandColorFor('claude-cli', c), c.brandAnthropic);
      expect(brandColorFor('anthropic', c), c.brandAnthropic);
    });
    test('codex and openai share OpenAI brand', () {
      expect(brandColorFor('codex', c), c.brandOpenAI);
      expect(brandColorFor('openai', c), c.brandOpenAI);
    });
    test('gemini → brandGemini', () {
      expect(brandColorFor('gemini', c), c.brandGemini);
    });
    test('ollama → brandOllama', () {
      expect(brandColorFor('ollama', c), c.brandOllama);
    });
    test('custom and unknown ids → accent fallback', () {
      expect(brandColorFor('custom', c), c.accent);
      expect(brandColorFor('definitely-not-a-provider', c), c.accent);
    });
    test('null id → accent fallback', () {
      expect(brandColorFor(null, c), c.accent);
    });
  });
}
