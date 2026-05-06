import '../../../core/utils/debug_logger.dart';
import '../../shared/session_settings.dart';

const _anthropicAdaptiveOnly = <String>{'claude-opus-4-7', 'claude-opus-4-7-20251201'};

String mapClaudeEffort(ChatEffort e) => switch (e) {
  ChatEffort.low => 'low',
  ChatEffort.medium => 'medium',
  ChatEffort.high => 'high',
  ChatEffort.max => 'max',
};

String mapClaudePermissionMode({required ChatMode mode, required ChatPermission permission}) {
  if (mode == ChatMode.plan) return 'plan';
  return switch (permission) {
    ChatPermission.readOnly => 'plan',
    ChatPermission.askBefore => 'default',
    ChatPermission.fullAccess => 'bypassPermissions',
  };
}

String mapCodexEffort(ChatEffort e) => switch (e) {
  ChatEffort.low => 'low',
  ChatEffort.medium => 'medium',
  ChatEffort.high => 'high',
  ChatEffort.max => 'xhigh',
};

Map<String, dynamic> mapCodexSandboxPolicy(ChatPermission p) => switch (p) {
  ChatPermission.readOnly => const {'type': 'readOnly'},
  ChatPermission.askBefore => const {'type': 'workspaceWrite'},
  ChatPermission.fullAccess => const {'type': 'dangerFullAccess'},
};

String mapCodexApprovalPolicy(ChatPermission p) => switch (p) {
  ChatPermission.readOnly => 'on-request',
  ChatPermission.askBefore => 'on-request',
  ChatPermission.fullAccess => 'never',
};

int? mapAnthropicThinkingBudget(ChatEffort effort, {required int maxTokens, required String modelId}) {
  if (_anthropicAdaptiveOnly.contains(modelId)) return null;
  final raw = switch (effort) {
    ChatEffort.low => 2048,
    ChatEffort.medium => 8192,
    ChatEffort.high => 16384,
    ChatEffort.max => 32768,
  };
  if (raw >= maxTokens) {
    final clamped = maxTokens - 1;
    dLog('[setting_mappers] Anthropic thinking budget clamped from $raw to $clamped (max_tokens=$maxTokens)');
    return clamped;
  }
  return raw;
}

bool isAnthropicAdaptiveOnly(String modelId) => _anthropicAdaptiveOnly.contains(modelId);

/// OpenAI's `reasoning_effort` accepts only `minimal|low|medium|high`.
/// `ChatEffort.max` is clamped to `high` rather than emitted as `xhigh` (which
/// would 400 on o1/o3/o4-mini/gpt-5). The custom-endpoint datasource shares
/// this mapper but layers a one-shot retry that strips the field entirely
/// when an OpenAI-compatible server still rejects it.
String mapOpenAIReasoningEffort(ChatEffort e) => switch (e) {
  ChatEffort.low => 'low',
  ChatEffort.medium => 'medium',
  ChatEffort.high => 'high',
  ChatEffort.max => 'high',
};

const _openAiReasoningPrefixes = <String>['o1', 'o3', 'o4-mini', 'gpt-5'];

bool isOpenAiReasoningModel(String modelId) => _openAiReasoningPrefixes.any(modelId.startsWith);

int mapGeminiThinkingBudget(ChatEffort e) => switch (e) {
  ChatEffort.low => 2048,
  ChatEffort.medium => 8192,
  ChatEffort.high => 16384,
  ChatEffort.max => -1,
};

String mapGeminiThinkingLevel(ChatEffort e) => switch (e) {
  ChatEffort.low => 'low',
  ChatEffort.medium => 'medium',
  ChatEffort.high => 'high',
  ChatEffort.max => 'high',
};

bool isGemini3(String modelId) => modelId.startsWith('gemini-3');

bool supportsGeminiThinking(String modelId) => modelId.startsWith('gemini-2.5') || modelId.startsWith('gemini-3');

bool mapOllamaThink(ChatEffort? e) => e != null;
