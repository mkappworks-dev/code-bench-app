import '../../../core/utils/debug_logger.dart';
import '../../shared/ai_model.dart';
import '../../shared/session_settings.dart';
import '../models/provider_setting_drop.dart';

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

int? mapAnthropicThinkingBudget(
  ChatEffort effort, {
  required int maxTokens,
  required String modelId,
  ProviderSettingDropSink? onSettingDropped,
}) {
  if (AIModels.isAnthropicAdaptiveOnly(modelId)) return null;
  final raw = switch (effort) {
    ChatEffort.low => 2048,
    ChatEffort.medium => 8192,
    ChatEffort.high => 16384,
    ChatEffort.max => 32768,
  };
  if (raw >= maxTokens) {
    final clamped = maxTokens - 1;
    dLog('[setting_mappers] Anthropic thinking budget clamped from $raw to $clamped (max_tokens=$maxTokens)');
    onSettingDropped?.call(
      ProviderSettingDropThinkingBudget(
        requestedTokens: raw,
        appliedTokens: clamped,
        reason: 'Provider max_tokens=$maxTokens leaves no room for the requested budget',
      ),
    );
    return clamped;
  }
  return raw;
}

/// Maps to OpenAI's `reasoning_effort`; `ChatEffort.max` clamps to `high` since `xhigh` 400s on reasoning models.
String mapOpenAIReasoningEffort(ChatEffort e, {ProviderSettingDropSink? onSettingDropped}) {
  if (e == ChatEffort.max) {
    onSettingDropped?.call(
      const ProviderSettingDropEffort(
        requested: ChatEffort.max,
        applied: ChatEffort.high,
        reason: 'OpenAI reasoning_effort does not accept "xhigh" — clamped to "high"',
      ),
    );
    return 'high';
  }
  return switch (e) {
    ChatEffort.low => 'low',
    ChatEffort.medium => 'medium',
    ChatEffort.high => 'high',
    ChatEffort.max => 'high',
  };
}

int mapGeminiThinkingBudget(ChatEffort e) => switch (e) {
  ChatEffort.low => 2048,
  ChatEffort.medium => 8192,
  ChatEffort.high => 16384,
  ChatEffort.max => -1,
};

String mapGeminiThinkingLevel(ChatEffort e, {ProviderSettingDropSink? onSettingDropped}) {
  if (e == ChatEffort.max) {
    onSettingDropped?.call(
      const ProviderSettingDropEffort(
        requested: ChatEffort.max,
        applied: ChatEffort.high,
        reason: 'Gemini 3 thinkingLevel does not have a tier above "high" — clamped',
      ),
    );
    return 'high';
  }
  return switch (e) {
    ChatEffort.low => 'low',
    ChatEffort.medium => 'medium',
    ChatEffort.high => 'high',
    ChatEffort.max => 'high',
  };
}
