import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AIModels.isOpenAiChatModelId', () {
    test('keeps chat / reasoning / codex families', () {
      expect(AIModels.isOpenAiChatModelId('gpt-4o'), isTrue);
      expect(AIModels.isOpenAiChatModelId('gpt-5'), isTrue);
      expect(AIModels.isOpenAiChatModelId('gpt-5-mini'), isTrue);
      expect(AIModels.isOpenAiChatModelId('o1'), isTrue);
      expect(AIModels.isOpenAiChatModelId('o3-mini'), isTrue);
      expect(AIModels.isOpenAiChatModelId('o4-mini'), isTrue);
      expect(AIModels.isOpenAiChatModelId('codex-mini-latest'), isTrue);
      expect(AIModels.isOpenAiChatModelId('chatgpt-4o-latest'), isFalse, reason: 'no matching prefix');
    });

    test('drops non-chat substrings even when prefix matches', () {
      expect(AIModels.isOpenAiChatModelId('gpt-image-1'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-image-1-mini'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-4o-audio-preview'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-4o-mini-audio-preview-2024-12-17'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-realtime'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-4o-realtime-preview'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-4o-transcribe'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-4o-mini-transcribe'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-4o-mini-tts'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-4o-search-preview'), isFalse);
      expect(AIModels.isOpenAiChatModelId('gpt-4o-mini-search-preview'), isFalse);
    });
  });

  group('AIModels.geminiNonChatSubstrings', () {
    test('catches Nano Banana, embeddings, TTS, live, native-audio', () {
      bool blocked(String id) => AIModels.geminiNonChatSubstrings.any(id.contains);
      expect(blocked('gemini-2.5-flash-image-preview'), isTrue, reason: 'Nano Banana');
      expect(blocked('gemini-2.0-flash-preview-image-generation'), isTrue);
      expect(blocked('gemini-embedding-001'), isTrue);
      expect(blocked('gemini-2.5-flash-preview-tts'), isTrue);
      expect(blocked('gemini-2.5-pro-preview-tts'), isTrue);
      expect(blocked('gemini-2.5-flash-live-001'), isTrue);
      expect(blocked('gemini-2.0-flash-live-001'), isTrue);
      expect(blocked('gemini-2.5-flash-native-audio-thinking-dialog'), isTrue);
    });

    test('does not block real chat LLMs', () {
      bool blocked(String id) => AIModels.geminiNonChatSubstrings.any(id.contains);
      expect(blocked('gemini-2.5-pro'), isFalse);
      expect(blocked('gemini-2.5-flash'), isFalse);
      expect(blocked('gemini-2.5-flash-lite'), isFalse);
      expect(blocked('gemini-3-pro-preview'), isFalse);
      expect(blocked('gemini-1.5-pro'), isFalse);
      expect(blocked('gemini-1.5-flash'), isFalse);
    });
  });
}
