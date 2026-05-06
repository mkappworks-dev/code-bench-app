import 'package:code_bench_app/data/ai/util/setting_mappers.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Claude effort', () {
    test('low/medium/high/max map to themselves', () {
      expect(mapClaudeEffort(ChatEffort.low), 'low');
      expect(mapClaudeEffort(ChatEffort.medium), 'medium');
      expect(mapClaudeEffort(ChatEffort.high), 'high');
      expect(mapClaudeEffort(ChatEffort.max), 'max');
    });
  });

  group('Claude permission mode', () {
    test('mode=plan always wins', () {
      for (final p in ChatPermission.values) {
        expect(mapClaudePermissionMode(mode: ChatMode.plan, permission: p), 'plan');
      }
    });
    test('readOnly maps to plan', () {
      expect(mapClaudePermissionMode(mode: ChatMode.chat, permission: ChatPermission.readOnly), 'plan');
    });
    test('askBefore maps to default', () {
      expect(mapClaudePermissionMode(mode: ChatMode.chat, permission: ChatPermission.askBefore), 'default');
    });
    test('fullAccess maps to bypassPermissions', () {
      expect(mapClaudePermissionMode(mode: ChatMode.chat, permission: ChatPermission.fullAccess), 'bypassPermissions');
    });
  });

  group('Codex effort', () {
    test('max maps to xhigh', () {
      expect(mapCodexEffort(ChatEffort.max), 'xhigh');
    });
    test('low/medium/high map to themselves', () {
      expect(mapCodexEffort(ChatEffort.low), 'low');
      expect(mapCodexEffort(ChatEffort.medium), 'medium');
      expect(mapCodexEffort(ChatEffort.high), 'high');
    });
  });

  group('Codex sandbox + approval', () {
    test('readOnly', () {
      expect(mapCodexSandboxPolicy(ChatPermission.readOnly), {'type': 'readOnly'});
      expect(mapCodexApprovalPolicy(ChatPermission.readOnly), 'on-request');
    });
    test('askBefore', () {
      expect(mapCodexSandboxPolicy(ChatPermission.askBefore), {'type': 'workspaceWrite'});
      expect(mapCodexApprovalPolicy(ChatPermission.askBefore), 'on-request');
    });
    test('fullAccess', () {
      expect(mapCodexSandboxPolicy(ChatPermission.fullAccess), {'type': 'dangerFullAccess'});
      expect(mapCodexApprovalPolicy(ChatPermission.fullAccess), 'never');
    });
  });

  group('Anthropic thinking budget', () {
    test('low/medium/high/max return canonical budgets', () {
      expect(mapAnthropicThinkingBudget(ChatEffort.low, maxTokens: 4096, modelId: 'claude-sonnet-4-5'), 2048);
      expect(mapAnthropicThinkingBudget(ChatEffort.medium, maxTokens: 16384, modelId: 'claude-sonnet-4-5'), 8192);
      expect(mapAnthropicThinkingBudget(ChatEffort.high, maxTokens: 32768, modelId: 'claude-sonnet-4-5'), 16384);
      expect(mapAnthropicThinkingBudget(ChatEffort.max, maxTokens: 65536, modelId: 'claude-sonnet-4-5'), 32768);
    });

    test('clamps when raw budget >= maxTokens', () {
      expect(mapAnthropicThinkingBudget(ChatEffort.high, maxTokens: 4096, modelId: 'claude-sonnet-4-5'), 4095);
    });

    test('returns null on Opus 4.7+ adaptive-only models', () {
      expect(mapAnthropicThinkingBudget(ChatEffort.high, maxTokens: 32768, modelId: 'claude-opus-4-7'), isNull);
    });
  });

  group('OpenAI reasoning_effort', () {
    test('max clamps to high (OpenAI rejects xhigh)', () {
      expect(mapOpenAIReasoningEffort(ChatEffort.max), 'high');
    });
    test('others map to themselves', () {
      expect(mapOpenAIReasoningEffort(ChatEffort.low), 'low');
      expect(mapOpenAIReasoningEffort(ChatEffort.medium), 'medium');
      expect(mapOpenAIReasoningEffort(ChatEffort.high), 'high');
    });
  });

  group('Gemini thinking', () {
    test('thinkingBudget: max is dynamic (-1)', () {
      expect(mapGeminiThinkingBudget(ChatEffort.max), -1);
    });
    test('thinkingBudget: lower tiers are concrete', () {
      expect(mapGeminiThinkingBudget(ChatEffort.low), 2048);
      expect(mapGeminiThinkingBudget(ChatEffort.medium), 8192);
      expect(mapGeminiThinkingBudget(ChatEffort.high), 16384);
    });
    test('thinkingLevel: max caps at high', () {
      expect(mapGeminiThinkingLevel(ChatEffort.max), 'high');
      expect(mapGeminiThinkingLevel(ChatEffort.high), 'high');
      expect(mapGeminiThinkingLevel(ChatEffort.medium), 'medium');
      expect(mapGeminiThinkingLevel(ChatEffort.low), 'low');
    });
  });

  // Model-id predicates moved to `AIModels` so model knowledge has one home.
  // Coverage here ensures the wire-format mappers above keep matching the
  // predicates' categorisation.
  group('AIModels.isGemini3', () {
    test('detects v3 family only', () {
      expect(AIModels.isGemini3('gemini-3-pro'), isTrue);
      expect(AIModels.isGemini3('gemini-2.5-flash'), isFalse);
      expect(AIModels.isGemini3('gemini-1.5-pro'), isFalse);
    });
  });

  group('AIModels.supportsGeminiThinking', () {
    test('2.5 + 3 family yes; 1.5 and earlier no', () {
      expect(AIModels.supportsGeminiThinking('gemini-3-pro'), isTrue);
      expect(AIModels.supportsGeminiThinking('gemini-2.5-flash'), isTrue);
      expect(AIModels.supportsGeminiThinking('gemini-2.5-pro'), isTrue);
      expect(AIModels.supportsGeminiThinking('gemini-2.0-flash'), isFalse);
      expect(AIModels.supportsGeminiThinking('gemini-1.5-pro'), isFalse);
    });
  });

  group('AIModels.isOpenAiReasoningModel', () {
    test('reasoning families yes; gpt-4o family no', () {
      expect(AIModels.isOpenAiReasoningModel('o1'), isTrue);
      expect(AIModels.isOpenAiReasoningModel('o3'), isTrue);
      expect(AIModels.isOpenAiReasoningModel('o3-mini'), isTrue);
      expect(AIModels.isOpenAiReasoningModel('o4-mini'), isTrue);
      expect(AIModels.isOpenAiReasoningModel('gpt-5'), isTrue);
      expect(AIModels.isOpenAiReasoningModel('gpt-5-codex'), isTrue);
      expect(AIModels.isOpenAiReasoningModel('gpt-4o'), isFalse);
      expect(AIModels.isOpenAiReasoningModel('gpt-4o-mini'), isFalse);
    });
  });

  group('AIModels.isAnthropicAdaptiveOnly', () {
    test('Opus 4.7 (and dated build) yes; Sonnet/Haiku no', () {
      expect(AIModels.isAnthropicAdaptiveOnly('claude-opus-4-7'), isTrue);
      expect(AIModels.isAnthropicAdaptiveOnly('claude-opus-4-7-20251201'), isTrue);
      expect(AIModels.isAnthropicAdaptiveOnly('claude-sonnet-4-6'), isFalse);
      expect(AIModels.isAnthropicAdaptiveOnly('claude-haiku-4-5-20251001'), isFalse);
    });
  });

  group('Ollama think coercion', () {
    test('null effort returns false', () {
      expect(mapOllamaThink(null), isFalse);
    });
    test('any non-null effort returns true', () {
      for (final e in ChatEffort.values) {
        expect(mapOllamaThink(e), isTrue);
      }
    });
  });
}
