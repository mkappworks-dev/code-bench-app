# Provider Settings Passthrough Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire user-selected `model`, `system prompt`, `mode`, `effort`, `permission` through `SessionService` and both datasource interfaces (CLI + HTTP) to all seven providers, and have the chat input bar render only options the active provider+model honour.

**Architecture:** New value objects (`ProviderTurnSettings`, `ProviderCapabilities`) carried as optional named params. Both `AIProviderDatasource.sendAndStream` (CLI) and `TextStreamingDatasource.streamMessage` (HTTP) gain `settings` and `capabilitiesFor(AIModel)`. Pure mapper functions translate app-side enums to per-CLI / per-API field shapes. Capabilities are model-aware — `capabilitiesFor` consults the picked model id and returns shrunken sets for non-reasoning models, Opus 4.7+ adaptive-only, pre-Gemini-2.5, etc.

**Tech Stack:** Flutter, Dart, freezed, Riverpod, Drift (no schema change), Dio, Process.

**Spec:** [docs/superpowers/specs/2026-05-06-cli-provider-settings-passthrough-design.md](../specs/2026-05-06-cli-provider-settings-passthrough-design.md)

**Worktree:** `.worktrees/fix/2026-05-06-tool-call-provider-model-badges` (continuation)

---

## File Structure

### Moved (verbatim)
- `lib/data/session/models/session_settings.dart` → `lib/data/shared/session_settings.dart`

### New
- `lib/data/ai/models/provider_turn_settings.dart` — freezed value object passed through every datasource
- `lib/data/ai/models/provider_capabilities.dart` — freezed value object exposed per-(datasource, model)
- `lib/data/ai/util/setting_mappers.dart` — pure mapping functions (single source of truth)
- `lib/features/chat/notifiers/chat_input_bar_options_notifier.dart` — model-aware capabilities lookup
- `test/data/ai/util/setting_mappers_test.dart`
- `test/data/ai/datasource/anthropic_request_body_test.dart`
- `test/data/ai/datasource/openai_request_body_test.dart`
- `test/data/ai/datasource/gemini_request_body_test.dart`
- `test/data/ai/datasource/claude_cli_args_test.dart`
- `test/data/ai/datasource/codex_cli_thread_start_params_test.dart`
- `test/features/chat/notifiers/chat_input_bar_options_notifier_test.dart`

### Modified
- `lib/data/ai/datasource/ai_provider_datasource.dart`
- `lib/data/ai/datasource/text_streaming_datasource.dart`
- `lib/data/ai/datasource/claude_cli_datasource_process.dart`
- `lib/data/ai/datasource/codex_cli_datasource_process.dart`
- `lib/data/ai/datasource/anthropic_remote_datasource_dio.dart`
- `lib/data/ai/datasource/openai_remote_datasource_dio.dart`
- `lib/data/ai/datasource/gemini_remote_datasource_dio.dart`
- `lib/data/ai/datasource/ollama_remote_datasource_dio.dart`
- `lib/data/ai/datasource/custom_remote_datasource_dio.dart`
- `lib/data/ai/repository/ai_repository_impl.dart`
- `lib/data/ai/repository/text_streaming_repository.dart`
- `lib/services/session/session_service.dart`
- `lib/services/agent/agent_service.dart`
- `lib/features/chat/widgets/chat_input_bar.dart`
- 12 importers (4 features + 4 services + 4 tests) for the enum-migration import-path update
- `test/data/ai/datasource/codex_cli_turn_start_params_test.dart` (extend)

### Generated (committed alongside source)
- `*.freezed.dart` and `*.g.dart` for each new freezed model
- `*.g.dart` for each new `@riverpod` provider

---

## Task 1: Migrate enums to `data/shared/`

**Goal:** Move `ChatMode/ChatEffort/ChatPermission` plus their label extensions verbatim from `data/session/models/` to `data/shared/`. Update all 12 importers.

**Files:**
- Move: `lib/data/session/models/session_settings.dart` → `lib/data/shared/session_settings.dart`
- Modify (import path): `lib/features/chat/notifiers/chat_notifier.dart`, `session_settings_actions.dart`, `lib/features/chat/widgets/work_log_section.dart`, `chat_input_bar.dart`, `lib/services/coding_tools/tool_registry.dart`, `agent_service.dart`, `session_service.dart`, plus 5 test files

- [ ] **Step 1: Move the file**

```bash
git mv lib/data/session/models/session_settings.dart lib/data/shared/session_settings.dart
```

- [ ] **Step 2: Update every importer**

Run: `grep -rln "data/session/models/session_settings.dart\|session/models/session_settings" lib/ test/`

For each match, fix the relative import path. The 12 expected files:

| File | Old import | New import |
|---|---|---|
| `lib/features/chat/notifiers/chat_notifier.dart` | `../../../data/session/models/session_settings.dart` | `../../../data/shared/session_settings.dart` |
| `lib/features/chat/notifiers/session_settings_actions.dart` | same | same |
| `lib/features/chat/widgets/work_log_section.dart` | same | same |
| `lib/features/chat/widgets/chat_input_bar.dart` | same | same |
| `lib/services/coding_tools/tool_registry.dart` | `../../data/session/models/session_settings.dart` | `../../data/shared/session_settings.dart` |
| `lib/services/agent/agent_service.dart` | same | same |
| `lib/services/session/session_service.dart` | same | same |
| `test/features/chat/notifiers/chat_notifier_test.dart` | `package:code_bench_app/data/session/models/session_settings.dart` | `package:code_bench_app/data/shared/session_settings.dart` |
| `test/features/chat/notifiers/chat_notifier_cancel_test.dart` | same | same |
| `test/services/coding_tools/tool_registry_test.dart` | same | same |
| `test/services/agent/agent_service_test.dart` | same | same |
| `test/services/session/session_service_test.dart` | same | same |

Use sed for bulk update:

```bash
grep -rl "data/session/models/session_settings" lib/ test/ | xargs sed -i '' 's|data/session/models/session_settings|data/shared/session_settings|g'
```

- [ ] **Step 3: Format + analyze**

Run: `dart format lib/ test/ && flutter analyze 2>&1 | tail -5`

Expected: `No issues found!`

- [ ] **Step 4: Run full test suite**

Run: `flutter test 2>&1 | tail -5`

Expected: All tests pass — this is a pure path move with no semantic change.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor(data): move ChatMode/ChatEffort/ChatPermission to data/shared/"
```

---

## Task 2: `ProviderTurnSettings` value object

**Files:**
- Create: `lib/data/ai/models/provider_turn_settings.dart`

- [ ] **Step 1: Create the freezed model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/session_settings.dart';

part 'provider_turn_settings.freezed.dart';
part 'provider_turn_settings.g.dart';

@freezed
abstract class ProviderTurnSettings with _$ProviderTurnSettings {
  const factory ProviderTurnSettings({
    String? modelId,
    String? systemPrompt,
    ChatMode? mode,
    ChatEffort? effort,
    ChatPermission? permission,
  }) = _ProviderTurnSettings;

  factory ProviderTurnSettings.fromJson(Map<String, dynamic> json) => _$ProviderTurnSettingsFromJson(json);
}
```

- [ ] **Step 2: Regenerate code**

Run: `dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5`

Expected: `provider_turn_settings.freezed.dart` and `provider_turn_settings.g.dart` are produced.

- [ ] **Step 3: Format + analyze**

Run: `dart format lib/data/ai/models/ && flutter analyze lib/data/ai/models/ 2>&1 | tail -5`

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/data/ai/models/provider_turn_settings.dart lib/data/ai/models/provider_turn_settings.freezed.dart lib/data/ai/models/provider_turn_settings.g.dart
git commit -m "feat(model): add ProviderTurnSettings value object"
```

---

## Task 3: `ProviderCapabilities` value object

**Files:**
- Create: `lib/data/ai/models/provider_capabilities.dart`

- [ ] **Step 1: Create the freezed model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/session_settings.dart';

part 'provider_capabilities.freezed.dart';

@freezed
abstract class ProviderCapabilities with _$ProviderCapabilities {
  const factory ProviderCapabilities({
    @Default(false) bool supportsModelOverride,
    @Default(false) bool supportsSystemPrompt,
    @Default(<ChatMode>{}) Set<ChatMode> supportedModes,
    @Default(<ChatEffort>{}) Set<ChatEffort> supportedEfforts,
    @Default(<ChatPermission>{}) Set<ChatPermission> supportedPermissions,
  }) = _ProviderCapabilities;
}
```

(No `fromJson` — never serialised.)

- [ ] **Step 2: Regenerate code**

Run: `dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5`

- [ ] **Step 3: Format + analyze**

Run: `dart format lib/data/ai/models/provider_capabilities.dart lib/data/ai/models/provider_capabilities.freezed.dart && flutter analyze lib/data/ai/models/ 2>&1 | tail -5`

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/data/ai/models/provider_capabilities.dart lib/data/ai/models/provider_capabilities.freezed.dart
git commit -m "feat(model): add ProviderCapabilities value object"
```

---

## Task 4: Pure mapping functions (TDD)

**Files:**
- Create: `lib/data/ai/util/setting_mappers.dart`
- Create: `test/data/ai/util/setting_mappers_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/data/ai/util/setting_mappers_test.dart`:

```dart
import 'package:code_bench_app/data/ai/util/setting_mappers.dart';
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
      expect(
        mapAnthropicThinkingBudget(ChatEffort.low, maxTokens: 4096, modelId: 'claude-sonnet-4-5'),
        2048,
      );
      expect(
        mapAnthropicThinkingBudget(ChatEffort.medium, maxTokens: 16384, modelId: 'claude-sonnet-4-5'),
        8192,
      );
      expect(
        mapAnthropicThinkingBudget(ChatEffort.high, maxTokens: 32768, modelId: 'claude-sonnet-4-5'),
        16384,
      );
      expect(
        mapAnthropicThinkingBudget(ChatEffort.max, maxTokens: 65536, modelId: 'claude-sonnet-4-5'),
        32768,
      );
    });

    test('clamps when raw budget >= maxTokens', () {
      expect(
        mapAnthropicThinkingBudget(ChatEffort.high, maxTokens: 4096, modelId: 'claude-sonnet-4-5'),
        4095,
      );
    });

    test('returns null on Opus 4.7+ adaptive-only models', () {
      expect(
        mapAnthropicThinkingBudget(ChatEffort.high, maxTokens: 32768, modelId: 'claude-opus-4-7'),
        isNull,
      );
    });
  });

  group('OpenAI reasoning_effort', () {
    test('max maps to xhigh', () {
      expect(mapOpenAIReasoningEffort(ChatEffort.max), 'xhigh');
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
    test('isGemini3 detects v3 family', () {
      expect(isGemini3('gemini-3-pro'), isTrue);
      expect(isGemini3('gemini-2.5-flash'), isFalse);
      expect(isGemini3('gemini-1.5-pro'), isFalse);
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
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `flutter test test/data/ai/util/setting_mappers_test.dart 2>&1 | tail -5`

Expected: FAIL — `setting_mappers.dart` not found.

- [ ] **Step 3: Write the implementation**

Create `lib/data/ai/util/setting_mappers.dart`:

```dart
import '../../shared/session_settings.dart';

const _anthropicAdaptiveOnly = <String>{
  'claude-opus-4-7',
  'claude-opus-4-7-20251201',
};

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
  return raw >= maxTokens ? maxTokens - 1 : raw;
}

bool isAnthropicAdaptiveOnly(String modelId) => _anthropicAdaptiveOnly.contains(modelId);

String mapOpenAIReasoningEffort(ChatEffort e) => switch (e) {
  ChatEffort.low => 'low',
  ChatEffort.medium => 'medium',
  ChatEffort.high => 'high',
  ChatEffort.max => 'xhigh',
};

const _openAiReasoningPrefixes = <String>['o1', 'o3', 'o4-mini', 'gpt-5'];

bool isOpenAiReasoningModel(String modelId) =>
    _openAiReasoningPrefixes.any(modelId.startsWith);

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

bool supportsGeminiThinking(String modelId) =>
    modelId.startsWith('gemini-2.5') || modelId.startsWith('gemini-3');

bool mapOllamaThink(ChatEffort? e) => e != null;
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `flutter test test/data/ai/util/setting_mappers_test.dart 2>&1 | tail -5`

Expected: All tests pass.

- [ ] **Step 5: Format + analyze**

Run: `dart format lib/data/ai/util/ test/data/ai/util/ && flutter analyze lib/data/ai/util/ test/data/ai/util/ 2>&1 | tail -5`

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/data/ai/util/setting_mappers.dart test/data/ai/util/setting_mappers_test.dart
git commit -m "feat(ai-util): pure mappers for provider settings (Claude/Codex/Anthropic/OpenAI/Gemini/Ollama)"
```

---

## Task 5: Extend `AIProviderDatasource` interface

**Files:**
- Modify: `lib/data/ai/datasource/ai_provider_datasource.dart`

- [ ] **Step 1: Add capabilities getter and settings param**

Replace the current interface body. The new contract:

```dart
import '../../shared/ai_model.dart';
import '../models/auth_status.dart';
import '../models/detection_result.dart';
import '../models/provider_capabilities.dart';
import '../models/provider_runtime_event.dart';
import '../models/provider_turn_settings.dart';

export '../models/auth_status.dart';
export '../models/detection_result.dart';
export '../models/provider_capabilities.dart';
export '../models/provider_runtime_event.dart';
export '../models/provider_turn_settings.dart';

abstract interface class AIProviderDatasource {
  String get id;
  String get displayName;
  Future<DetectionResult> detect();

  /// Capability surface for the *picked* model. CLI providers usually
  /// return the same value for any model (CLI accepts every flag for any
  /// model); HTTP providers can shrink based on model id.
  ProviderCapabilities capabilitiesFor(AIModel model);

  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
    ProviderTurnSettings? settings,
  });

  void cancel();
  void respondToPermissionRequest(String requestId, {required bool approved});
  Future<AuthStatus> verifyAuth();
}
```

- [ ] **Step 2: Format + analyze**

Run: `dart format lib/data/ai/datasource/ai_provider_datasource.dart && flutter analyze lib/data/ai/datasource/ 2>&1 | tail -10`

Expected: Errors in `claude_cli_datasource_process.dart` and `codex_cli_datasource_process.dart` because they don't implement `capabilitiesFor` yet — leave those for Tasks 7–8. The interface file itself should be clean.

- [ ] **Step 3: Commit (skip until implementations land)**

Hold this commit; combine with Task 7 to keep CI green.

---

## Task 6: Extend `TextStreamingDatasource` interface + repo seam

**Files:**
- Modify: `lib/data/ai/datasource/text_streaming_datasource.dart`
- Modify: `lib/data/ai/repository/text_streaming_repository.dart`
- Modify: `lib/data/ai/repository/ai_repository_impl.dart`

- [ ] **Step 1: Inspect the current interface**

Run: `cat lib/data/ai/datasource/text_streaming_datasource.dart`

Note the current `streamMessage` signature — typically `({history, prompt, model, systemPrompt})`. Capture exact param names for Step 2.

- [ ] **Step 2: Add `capabilitiesFor` getter and `settings` param**

Replace the interface. Pattern (preserve existing param names from Step 1):

```dart
import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';
import '../models/provider_capabilities.dart';
import '../models/provider_turn_settings.dart';

abstract class TextStreamingDatasource {
  ProviderCapabilities capabilitiesFor(AIModel model);

  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
    ProviderTurnSettings? settings,
  });

  Future<bool> testConnection(AIModel model, String apiKey);

  // Preserve any other methods (fetchAvailableModels, etc.) verbatim.
}
```

- [ ] **Step 3: Forward `settings` through `TextStreamingRepository`**

Run: `grep -n "streamMessage\|class TextStreamingRepository" lib/data/ai/repository/text_streaming_repository.dart`

Add `ProviderTurnSettings? settings` to `streamMessage` and forward to the underlying datasource.

- [ ] **Step 4: Forward `settings` through `AIRepositoryImpl`**

Same in `lib/data/ai/repository/ai_repository_impl.dart` — the `streamMessage` it exposes accepts `settings` and passes through.

- [ ] **Step 5: Format + analyze**

Run: `dart format lib/data/ai/ && flutter analyze lib/data/ai/ 2>&1 | tail -10`

Expected: Errors in the five HTTP datasources because they don't implement `capabilitiesFor` yet — leave those for Tasks 9–13.

- [ ] **Step 6: Hold commit (combine with Task 9)**

---

## Task 7: Wire Claude CLI

**Files:**
- Modify: `lib/data/ai/datasource/claude_cli_datasource_process.dart`
- Create: `test/data/ai/datasource/claude_cli_args_test.dart`

- [ ] **Step 1: Extract the argv builder so it's testable**

In `claude_cli_datasource_process.dart`, hoist the existing inline `args` list (around line 173) into a top-level `@visibleForTesting` function. Pattern:

```dart
import 'package:meta/meta.dart';
import '../../shared/session_settings.dart';
import '../models/provider_turn_settings.dart';
import '../util/setting_mappers.dart';

@visibleForTesting
List<String> buildClaudeCliArgs({
  required String sessionId,
  required String prompt,
  required bool isFirstTurn,
  ProviderTurnSettings? settings,
}) {
  final modelId = settings?.modelId;
  final effort = settings?.effort;
  final systemPrompt = settings?.systemPrompt;
  final permissionMode = mapClaudePermissionMode(
    mode: settings?.mode ?? ChatMode.chat,
    permission: settings?.permission ?? ChatPermission.fullAccess,
  );

  return [
    '-p',
    '--output-format', 'stream-json',
    '--include-partial-messages',
    '--verbose',
    if (modelId != null) ...['--model', modelId],
    if (effort != null) ...['--effort', mapClaudeEffort(effort)],
    if (systemPrompt != null && systemPrompt.isNotEmpty)
      ...['--append-system-prompt', systemPrompt],
    '--permission-mode', permissionMode,
    if (isFirstTurn) ...['--session-id', sessionId] else ...['--resume', sessionId],
    '--', prompt,
  ];
}
```

- [ ] **Step 2: Replace the inline args block with a call to the helper**

Inside `_stream`, replace the `final args = <String>[ ... ]` block with:

```dart
final args = buildClaudeCliArgs(
  sessionId: sessionId,
  prompt: prompt,
  isFirstTurn: isFirstTurn,
  settings: settings,
);
```

- [ ] **Step 3: Add `settings` param + `capabilitiesFor` to the class**

```dart
@override
ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
  supportsModelOverride: true,
  supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat, ChatMode.plan, ChatMode.act},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess},
);

@override
Stream<ProviderRuntimeEvent> sendAndStream({
  required String prompt,
  required String sessionId,
  required String workingDirectory,
  ProviderTurnSettings? settings,
}) {
  // ...existing controller setup...
  // pass `settings` to _stream(...)
}
```

The internal `_stream(...)` method takes `settings` too. Forward it to `buildClaudeCliArgs`.

- [ ] **Step 4: Update `ProviderInit` emit to use `settings.modelId`**

Replace:
```dart
controller.add(ProviderInit(provider: id));
```
With:
```dart
controller.add(ProviderInit(provider: id, modelId: settings?.modelId));
```

- [ ] **Step 5: Write tests for the argv builder**

Create `test/data/ai/datasource/claude_cli_args_test.dart`:

```dart
import 'package:code_bench_app/data/ai/datasource/claude_cli_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/provider_turn_settings.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildClaudeCliArgs', () {
    test('no settings → minimal args with default permission-mode', () {
      final args = buildClaudeCliArgs(
        sessionId: 'session-1', prompt: 'hello', isFirstTurn: true,
      );
      expect(args, contains('--permission-mode'));
      final permIdx = args.indexOf('--permission-mode');
      expect(args[permIdx + 1], 'bypassPermissions');  // default fullAccess
      expect(args, isNot(contains('--model')));
      expect(args, isNot(contains('--effort')));
      expect(args, isNot(contains('--append-system-prompt')));
      expect(args.last, 'hello');
    });

    test('full settings → every flag present', () {
      final args = buildClaudeCliArgs(
        sessionId: 'session-2', prompt: 'world', isFirstTurn: true,
        settings: const ProviderTurnSettings(
          modelId: 'sonnet',
          systemPrompt: 'be concise',
          mode: ChatMode.chat,
          effort: ChatEffort.high,
          permission: ChatPermission.askBefore,
        ),
      );
      expect(args, containsAllInOrder(['--model', 'sonnet']));
      expect(args, containsAllInOrder(['--effort', 'high']));
      expect(args, containsAllInOrder(['--append-system-prompt', 'be concise']));
      expect(args, containsAllInOrder(['--permission-mode', 'default']));
    });

    test('mode=plan overrides permission to plan', () {
      final args = buildClaudeCliArgs(
        sessionId: 's', prompt: 'p', isFirstTurn: true,
        settings: const ProviderTurnSettings(
          mode: ChatMode.plan, permission: ChatPermission.fullAccess,
        ),
      );
      expect(args, containsAllInOrder(['--permission-mode', 'plan']));
    });

    test('readOnly permission maps to plan', () {
      final args = buildClaudeCliArgs(
        sessionId: 's', prompt: 'p', isFirstTurn: true,
        settings: const ProviderTurnSettings(
          mode: ChatMode.chat, permission: ChatPermission.readOnly,
        ),
      );
      expect(args, containsAllInOrder(['--permission-mode', 'plan']));
    });

    test('isFirstTurn=false uses --resume', () {
      final args = buildClaudeCliArgs(
        sessionId: 'sess', prompt: 'hi', isFirstTurn: false,
      );
      expect(args, containsAllInOrder(['--resume', 'sess']));
      expect(args, isNot(contains('--session-id')));
    });

    test('empty system prompt is dropped', () {
      final args = buildClaudeCliArgs(
        sessionId: 's', prompt: 'p', isFirstTurn: true,
        settings: const ProviderTurnSettings(systemPrompt: ''),
      );
      expect(args, isNot(contains('--append-system-prompt')));
    });
  });
}
```

- [ ] **Step 6: Run tests + lint**

```bash
flutter test test/data/ai/datasource/claude_cli_args_test.dart 2>&1 | tail -5
dart format lib/data/ai/datasource/claude_cli_datasource_process.dart test/data/ai/datasource/claude_cli_args_test.dart
flutter analyze lib/data/ai/datasource/ai_provider_datasource.dart lib/data/ai/datasource/claude_cli_datasource_process.dart 2>&1 | tail -5
```

Expected: tests pass; `claude_cli_datasource_process.dart` clean (Codex still errors — handled in Task 8).

- [ ] **Step 7: Commit (combines with Task 5)**

```bash
git add lib/data/ai/datasource/ai_provider_datasource.dart \
        lib/data/ai/datasource/claude_cli_datasource_process.dart \
        test/data/ai/datasource/claude_cli_args_test.dart
git commit -m "feat(claude-cli): honour ProviderTurnSettings via argv flags + capabilities surface"
```

---

## Task 8: Wire Codex CLI

**Files:**
- Modify: `lib/data/ai/datasource/codex_cli_datasource_process.dart`
- Modify: `test/data/ai/datasource/codex_cli_turn_start_params_test.dart`
- Create: `test/data/ai/datasource/codex_cli_thread_start_params_test.dart`

- [ ] **Step 1: Extend `buildCodexTurnStartParams` with optional fields**

Replace the helper at the top of `codex_cli_datasource_process.dart`:

```dart
@visibleForTesting
Map<String, dynamic> buildCodexTurnStartParams(
  String threadId,
  String prompt, {
  String? modelId,
  ChatEffort? effort,
  ChatPermission? permission,
}) {
  return {
    'threadId': threadId,
    'input': [{'type': 'text', 'text': prompt}],
    if (modelId != null) 'model': modelId,
    if (effort != null) 'effort': mapCodexEffort(effort),
    if (permission != null) 'sandboxPolicy': mapCodexSandboxPolicy(permission),
    if (permission != null) 'approvalPolicy': mapCodexApprovalPolicy(permission),
  };
}
```

Add the imports:

```dart
import '../../shared/session_settings.dart';
import '../models/provider_turn_settings.dart';
import '../util/setting_mappers.dart';
```

- [ ] **Step 2: Add `buildCodexThreadStartParams` for `developerInstructions`**

Just below `buildCodexTurnStartParams`:

```dart
@visibleForTesting
Map<String, dynamic> buildCodexThreadStartParams({
  required String workingDirectory,
  required String sessionId,
  String? developerInstructions,
}) {
  return {
    'cwd': workingDirectory,
    if (sessionId.isNotEmpty) 'resumeThreadId': sessionId,
    if (developerInstructions != null && developerInstructions.isNotEmpty)
      'developerInstructions': developerInstructions,
  };
}
```

- [ ] **Step 3: Use both helpers in the class**

Replace the inline `_request('thread/start', { ... })` body with:
```dart
final result = await _request(
  'thread/start',
  buildCodexThreadStartParams(
    workingDirectory: workingDirectory,
    sessionId: sessionId,
    developerInstructions: settings?.systemPrompt,
  ),
);
```

Replace `_request('turn/start', buildCodexTurnStartParams(_providerThreadId!, prompt))` with:
```dart
await _request(
  'turn/start',
  buildCodexTurnStartParams(
    _providerThreadId!,
    prompt,
    modelId: settings?.modelId,
    effort: settings?.effort,
    permission: settings?.permission,
  ),
);
```

- [ ] **Step 4: Add `capabilitiesFor` + accept `settings`**

```dart
@override
ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
  supportsModelOverride: true,
  supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat, ChatMode.act},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess},
);
```

Update `sendAndStream` signature to include `ProviderTurnSettings? settings` and pipe it down through `_send`/`_startThread`/`_sendTurn`.

- [ ] **Step 5: Update `ProviderInit` emit — drop the `_version` stand-in**

Replace:
```dart
_streamController?.add(ProviderInit(provider: id, modelId: _version));
```
With:
```dart
_streamController?.add(ProviderInit(provider: id, modelId: settings?.modelId));
```

The earlier companion-spec stand-in is removed.

- [ ] **Step 6: Extend turn-start-params tests**

Update `test/data/ai/datasource/codex_cli_turn_start_params_test.dart` — append:

```dart
test('includes model when provided', () {
  final params = buildCodexTurnStartParams('thread-1', 'hi', modelId: 'gpt-5-codex');
  expect(params['model'], 'gpt-5-codex');
});

test('includes effort when provided', () {
  final params = buildCodexTurnStartParams('t', 'p', effort: ChatEffort.max);
  expect(params['effort'], 'xhigh');
});

test('includes sandboxPolicy + approvalPolicy when permission provided', () {
  final params = buildCodexTurnStartParams('t', 'p', permission: ChatPermission.fullAccess);
  expect(params['sandboxPolicy'], {'type': 'dangerFullAccess'});
  expect(params['approvalPolicy'], 'never');
});

test('omits all optional fields when nothing is provided', () {
  final params = buildCodexTurnStartParams('t', 'p');
  expect(params.containsKey('model'), isFalse);
  expect(params.containsKey('effort'), isFalse);
  expect(params.containsKey('sandboxPolicy'), isFalse);
  expect(params.containsKey('approvalPolicy'), isFalse);
});
```

- [ ] **Step 7: Write thread-start-params tests**

Create `test/data/ai/datasource/codex_cli_thread_start_params_test.dart`:

```dart
import 'package:code_bench_app/data/ai/datasource/codex_cli_datasource_process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCodexThreadStartParams', () {
    test('cwd + resumeThreadId only when no developerInstructions', () {
      final params = buildCodexThreadStartParams(
        workingDirectory: '/tmp/proj', sessionId: 'sess',
      );
      expect(params['cwd'], '/tmp/proj');
      expect(params['resumeThreadId'], 'sess');
      expect(params.containsKey('developerInstructions'), isFalse);
    });

    test('includes developerInstructions when non-empty', () {
      final params = buildCodexThreadStartParams(
        workingDirectory: '/tmp/proj', sessionId: 'sess',
        developerInstructions: 'be concise',
      );
      expect(params['developerInstructions'], 'be concise');
    });

    test('drops empty developerInstructions', () {
      final params = buildCodexThreadStartParams(
        workingDirectory: '/tmp/proj', sessionId: 'sess',
        developerInstructions: '',
      );
      expect(params.containsKey('developerInstructions'), isFalse);
    });

    test('omits resumeThreadId when sessionId empty', () {
      final params = buildCodexThreadStartParams(
        workingDirectory: '/tmp/proj', sessionId: '',
      );
      expect(params.containsKey('resumeThreadId'), isFalse);
    });
  });
}
```

- [ ] **Step 8: Run tests + lint**

```bash
flutter test test/data/ai/datasource/codex_cli_turn_start_params_test.dart \
              test/data/ai/datasource/codex_cli_thread_start_params_test.dart 2>&1 | tail -5
dart format lib/data/ai/datasource/codex_cli_datasource_process.dart \
            test/data/ai/datasource/codex_cli_turn_start_params_test.dart \
            test/data/ai/datasource/codex_cli_thread_start_params_test.dart
flutter analyze lib/data/ai/ 2>&1 | tail -5
```

Expected: tests pass; CLI half of the analyzer is clean.

- [ ] **Step 9: Commit**

```bash
git add lib/data/ai/datasource/codex_cli_datasource_process.dart \
        test/data/ai/datasource/codex_cli_turn_start_params_test.dart \
        test/data/ai/datasource/codex_cli_thread_start_params_test.dart
git commit -m "feat(codex-cli): pass model/effort/permission/system-prompt via JSON-RPC + capabilities surface"
```

---

## Task 9: Wire Anthropic API

**Files:**
- Modify: `lib/data/ai/datasource/anthropic_remote_datasource_dio.dart`
- Create: `test/data/ai/datasource/anthropic_request_body_test.dart`

- [ ] **Step 1: Hoist the request-body builder**

In `anthropic_remote_datasource_dio.dart`, replace the inline `final body = ...` block (around line 39) with a call to a hoisted helper. Add at top of file:

```dart
import 'package:meta/meta.dart';
import '../models/provider_turn_settings.dart';
import '../util/setting_mappers.dart';
import '../../shared/ai_model.dart';

@visibleForTesting
Map<String, dynamic> buildAnthropicRequestBody({
  required AIModel model,
  required List<Map<String, dynamic>> messages,
  required int maxTokens,
  String? systemPrompt,
  ProviderTurnSettings? settings,
}) {
  final body = <String, dynamic>{
    'model': model.modelId,
    'max_tokens': maxTokens,
    'messages': messages,
    'stream': true,
    if (systemPrompt != null) 'system': systemPrompt,
  };
  final effort = settings?.effort;
  if (effort != null) {
    final budget = mapAnthropicThinkingBudget(
      effort, maxTokens: maxTokens, modelId: model.modelId,
    );
    if (budget != null) body['thinking'] = {'type': 'enabled', 'budget_tokens': budget};
  }
  return body;
}
```

- [ ] **Step 2: Add `capabilitiesFor` + use the helper in `streamMessage`**

```dart
@override
ProviderCapabilities capabilitiesFor(AIModel model) => ProviderCapabilities(
  supportsModelOverride: true,
  supportsSystemPrompt: true,
  supportedModes: const {ChatMode.chat},
  supportedEfforts: isAnthropicAdaptiveOnly(model.modelId)
      ? const <ChatEffort>{}
      : const {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: const <ChatPermission>{},
);

@override
Stream<String> streamMessage({
  required List<ChatMessage> history,
  required String prompt,
  required AIModel model,
  String? systemPrompt,
  ProviderTurnSettings? settings,
}) async* {
  final messages = _buildMessages(history, prompt);  // existing helper
  final body = buildAnthropicRequestBody(
    model: model, messages: messages, maxTokens: 4096,
    systemPrompt: systemPrompt, settings: settings,
  );
  // ...rest unchanged...
}
```

(Adapt to whatever the existing `_buildMessages` signature is.)

- [ ] **Step 3: Write tests**

Create `test/data/ai/datasource/anthropic_request_body_test.dart`:

```dart
import 'package:code_bench_app/data/ai/datasource/anthropic_remote_datasource_dio.dart';
import 'package:code_bench_app/data/ai/models/provider_turn_settings.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sonnet = AIModel(
    id: 'claude-sonnet-4-5', provider: AIProvider.anthropic,
    name: 'Sonnet 4.5', modelId: 'claude-sonnet-4-5',
  );
  const opus47 = AIModel(
    id: 'claude-opus-4-7', provider: AIProvider.anthropic,
    name: 'Opus 4.7', modelId: 'claude-opus-4-7',
  );

  group('buildAnthropicRequestBody', () {
    test('no settings → no thinking field', () {
      final body = buildAnthropicRequestBody(
        model: sonnet, messages: const [], maxTokens: 4096,
      );
      expect(body.containsKey('thinking'), isFalse);
      expect(body['model'], 'claude-sonnet-4-5');
    });

    test('effort=high on Sonnet → thinking with budget 16384', () {
      final body = buildAnthropicRequestBody(
        model: sonnet, messages: const [], maxTokens: 32768,
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body['thinking'], {'type': 'enabled', 'budget_tokens': 16384});
    });

    test('effort=high on Opus 4.7+ → no thinking field', () {
      final body = buildAnthropicRequestBody(
        model: opus47, messages: const [], maxTokens: 32768,
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body.containsKey('thinking'), isFalse);
    });

    test('clamps budget when raw >= maxTokens', () {
      final body = buildAnthropicRequestBody(
        model: sonnet, messages: const [], maxTokens: 4096,
        settings: const ProviderTurnSettings(effort: ChatEffort.max),
      );
      expect(body['thinking']['budget_tokens'], 4095);
    });

    test('systemPrompt populates system field', () {
      final body = buildAnthropicRequestBody(
        model: sonnet, messages: const [], maxTokens: 4096,
        systemPrompt: 'be concise',
      );
      expect(body['system'], 'be concise');
    });
  });
}
```

- [ ] **Step 4: Run tests + lint**

```bash
flutter test test/data/ai/datasource/anthropic_request_body_test.dart 2>&1 | tail -5
dart format lib/data/ai/datasource/anthropic_remote_datasource_dio.dart test/data/ai/datasource/anthropic_request_body_test.dart
flutter analyze lib/data/ai/datasource/anthropic_remote_datasource_dio.dart 2>&1 | tail -5
```

Expected: tests pass; analyzer clean for Anthropic file.

- [ ] **Step 5: Commit**

```bash
git add lib/data/ai/datasource/anthropic_remote_datasource_dio.dart \
        test/data/ai/datasource/anthropic_request_body_test.dart
git commit -m "feat(anthropic-api): add thinking.budget_tokens via effort + capabilities surface"
```

---

## Task 10: Wire OpenAI API

**Files:**
- Modify: `lib/data/ai/datasource/openai_remote_datasource_dio.dart`
- Create: `test/data/ai/datasource/openai_request_body_test.dart`

- [ ] **Step 1: Hoist the body builder**

```dart
@visibleForTesting
Map<String, dynamic> buildOpenAiRequestBody({
  required AIModel model,
  required List<Map<String, String>> messages,
  ProviderTurnSettings? settings,
}) {
  final body = <String, dynamic>{
    'model': model.modelId,
    'messages': messages,
    'stream': true,
  };
  if (settings?.effort != null && isOpenAiReasoningModel(model.modelId)) {
    body['reasoning_effort'] = mapOpenAIReasoningEffort(settings!.effort!);
  }
  return body;
}
```

- [ ] **Step 2: Add `capabilitiesFor` + call the helper from `streamMessage`**

```dart
@override
ProviderCapabilities capabilitiesFor(AIModel model) => ProviderCapabilities(
  supportsModelOverride: true,
  supportsSystemPrompt: true,
  supportedModes: const {ChatMode.chat},
  supportedEfforts: isOpenAiReasoningModel(model.modelId)
      ? const {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max}
      : const <ChatEffort>{},
  supportedPermissions: const <ChatPermission>{},
);
```

- [ ] **Step 3: Tests**

Create `test/data/ai/datasource/openai_request_body_test.dart`:

```dart
import 'package:code_bench_app/data/ai/datasource/openai_remote_datasource_dio.dart';
import 'package:code_bench_app/data/ai/models/provider_turn_settings.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gpt5 = AIModel(id: 'gpt-5', provider: AIProvider.openai, name: 'GPT-5', modelId: 'gpt-5');
  const gpt4o = AIModel(id: 'gpt-4o', provider: AIProvider.openai, name: 'GPT-4o', modelId: 'gpt-4o');

  group('buildOpenAiRequestBody', () {
    test('reasoning model + effort → reasoning_effort field present', () {
      final body = buildOpenAiRequestBody(
        model: gpt5, messages: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.medium),
      );
      expect(body['reasoning_effort'], 'medium');
    });

    test('non-reasoning model + effort → no reasoning_effort', () {
      final body = buildOpenAiRequestBody(
        model: gpt4o, messages: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body.containsKey('reasoning_effort'), isFalse);
    });

    test('max → xhigh', () {
      final body = buildOpenAiRequestBody(
        model: gpt5, messages: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.max),
      );
      expect(body['reasoning_effort'], 'xhigh');
    });
  });
}
```

- [ ] **Step 4: Run + lint + commit**

```bash
flutter test test/data/ai/datasource/openai_request_body_test.dart 2>&1 | tail -5
dart format lib/data/ai/datasource/openai_remote_datasource_dio.dart test/data/ai/datasource/openai_request_body_test.dart
flutter analyze lib/data/ai/datasource/openai_remote_datasource_dio.dart 2>&1 | tail -5
git add lib/data/ai/datasource/openai_remote_datasource_dio.dart test/data/ai/datasource/openai_request_body_test.dart
git commit -m "feat(openai-api): add reasoning_effort for o1/o3/o4-mini/gpt-5 + capabilities surface"
```

---

## Task 11: Wire Gemini API

**Files:**
- Modify: `lib/data/ai/datasource/gemini_remote_datasource_dio.dart`
- Create: `test/data/ai/datasource/gemini_request_body_test.dart`

- [ ] **Step 1: Hoist + branch on Gemini 3**

```dart
@visibleForTesting
Map<String, dynamic> buildGeminiRequestBody({
  required AIModel model,
  required List<Map<String, dynamic>> contents,
  String? systemPrompt,
  ProviderTurnSettings? settings,
}) {
  final body = <String, dynamic>{
    'contents': contents,
    if (systemPrompt != null)
      'system_instruction': {'parts': [{'text': systemPrompt}]},
  };
  if (settings?.effort != null && supportsGeminiThinking(model.modelId)) {
    final thinkingConfig = isGemini3(model.modelId)
        ? {'thinkingLevel': mapGeminiThinkingLevel(settings!.effort!)}
        : {'thinkingBudget': mapGeminiThinkingBudget(settings!.effort!)};
    body['generationConfig'] = {'thinkingConfig': thinkingConfig};
  }
  return body;
}
```

- [ ] **Step 2: Add `capabilitiesFor` + use the helper**

```dart
@override
ProviderCapabilities capabilitiesFor(AIModel model) => ProviderCapabilities(
  supportsModelOverride: true,
  supportsSystemPrompt: true,
  supportedModes: const {ChatMode.chat},
  supportedEfforts: supportsGeminiThinking(model.modelId)
      ? const {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max}
      : const <ChatEffort>{},
  supportedPermissions: const <ChatPermission>{},
);
```

- [ ] **Step 3: Tests**

Create `test/data/ai/datasource/gemini_request_body_test.dart`:

```dart
import 'package:code_bench_app/data/ai/datasource/gemini_remote_datasource_dio.dart';
import 'package:code_bench_app/data/ai/models/provider_turn_settings.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gem25 = AIModel(id: 'gemini-2.5-flash', provider: AIProvider.gemini, name: 'Gemini 2.5 Flash', modelId: 'gemini-2.5-flash');
  const gem3 = AIModel(id: 'gemini-3-pro', provider: AIProvider.gemini, name: 'Gemini 3 Pro', modelId: 'gemini-3-pro');
  const gem15 = AIModel(id: 'gemini-1.5-pro', provider: AIProvider.gemini, name: 'Gemini 1.5 Pro', modelId: 'gemini-1.5-pro');

  group('buildGeminiRequestBody', () {
    test('Gemini 2.5 + effort=high → thinkingBudget integer', () {
      final body = buildGeminiRequestBody(
        model: gem25, contents: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body['generationConfig']['thinkingConfig'], {'thinkingBudget': 16384});
    });

    test('Gemini 2.5 + effort=max → thinkingBudget=-1 (dynamic)', () {
      final body = buildGeminiRequestBody(
        model: gem25, contents: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.max),
      );
      expect(body['generationConfig']['thinkingConfig'], {'thinkingBudget': -1});
    });

    test('Gemini 3 + effort=max → thinkingLevel=high', () {
      final body = buildGeminiRequestBody(
        model: gem3, contents: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.max),
      );
      expect(body['generationConfig']['thinkingConfig'], {'thinkingLevel': 'high'});
    });

    test('Gemini 1.5 → no generationConfig', () {
      final body = buildGeminiRequestBody(
        model: gem15, contents: const [],
        settings: const ProviderTurnSettings(effort: ChatEffort.high),
      );
      expect(body.containsKey('generationConfig'), isFalse);
    });

    test('systemPrompt populates system_instruction', () {
      final body = buildGeminiRequestBody(
        model: gem25, contents: const [], systemPrompt: 'be concise',
      );
      expect(body['system_instruction'], {'parts': [{'text': 'be concise'}]});
    });
  });
}
```

- [ ] **Step 4: Run + lint + commit**

```bash
flutter test test/data/ai/datasource/gemini_request_body_test.dart 2>&1 | tail -5
dart format lib/data/ai/datasource/gemini_remote_datasource_dio.dart test/data/ai/datasource/gemini_request_body_test.dart
flutter analyze lib/data/ai/datasource/gemini_remote_datasource_dio.dart 2>&1 | tail -5
git add lib/data/ai/datasource/gemini_remote_datasource_dio.dart test/data/ai/datasource/gemini_request_body_test.dart
git commit -m "feat(gemini-api): add thinkingBudget (2.5) / thinkingLevel (3) via effort + capabilities surface"
```

---

## Task 12: Wire Ollama API

**Files:**
- Modify: `lib/data/ai/datasource/ollama_remote_datasource_dio.dart`

- [ ] **Step 1: Add `capabilitiesFor` + `think` field**

In `streamMessage`, modify the body construction:

```dart
final body = <String, dynamic>{
  'model': model.modelId,
  'messages': messages,
  'stream': true,
  if (settings?.effort != null) 'think': mapOllamaThink(settings!.effort),
};
```

Add capabilities:

```dart
@override
ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
  supportsModelOverride: true,
  supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: <ChatPermission>{},
);
```

- [ ] **Step 2: Format + analyze + commit**

```bash
dart format lib/data/ai/datasource/ollama_remote_datasource_dio.dart
flutter analyze lib/data/ai/datasource/ollama_remote_datasource_dio.dart 2>&1 | tail -5
git add lib/data/ai/datasource/ollama_remote_datasource_dio.dart
git commit -m "feat(ollama-api): add think:true via effort + capabilities surface"
```

(No new test file; this is a single-line body change. Exercised by integration tests in Task 18.)

---

## Task 13: Wire Custom (OpenAI-compat) API

**Files:**
- Modify: `lib/data/ai/datasource/custom_remote_datasource_dio.dart`

- [ ] **Step 1: Add `capabilitiesFor` + best-effort `reasoning_effort`**

In the body construction inside `streamMessage`:

```dart
final body = <String, dynamic>{
  'model': model.modelId,
  'messages': messages,
  'stream': true,
  if (settings?.effort != null) 'reasoning_effort': mapOpenAIReasoningEffort(settings!.effort!),
};
```

Add capabilities — Custom is the one HTTP provider that runs the agent loop:

```dart
@override
ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
  supportsModelOverride: true,
  supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat, ChatMode.act},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess},
);
```

- [ ] **Step 2: Retry-without-effort on 400 if the endpoint rejects `reasoning_effort`**

Some self-hosted OpenAI-compatible endpoints (vLLM, llama.cpp, LiteLLM in strict mode) reject unknown JSON keys with a 400. Without protection, **this PR would regress those users**: their previously-working sessions would start failing the moment effort flowed through.

Wrap the request in a try/catch that detects this specific 400 and retries without the field:

```dart
Stream<String> streamMessage(...) async* {
  final body = buildCustomRequestBody(model: model, messages: messages, settings: settings);
  yield* _attemptStream(body, settings: settings, model: model, messages: messages);
}

Stream<String> _attemptStream(
  Map<String, dynamic> body, {
  required ProviderTurnSettings? settings,
  required AIModel model,
  required List<Map<String, String>> messages,
}) async* {
  try {
    final response = await _dio.post(...);
    // existing yield-loop body
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    final bodyText = e.response?.data?.toString() ?? '';
    final mentionsEffort = status == 400 && bodyText.contains('reasoning_effort');
    if (mentionsEffort && body.containsKey('reasoning_effort')) {
      sLog('[CustomRemoteDatasource] endpoint rejected reasoning_effort; retrying without it');
      final fallback = Map<String, dynamic>.from(body)..remove('reasoning_effort');
      yield* _attemptStream(fallback, settings: settings, model: model, messages: messages);
      return;
    }
    rethrow;
  }
}
```

The `sLog` (release-build-surviving) makes the silent degradation visible in support logs. The retry happens at most once because the second invocation has `body.containsKey('reasoning_effort')` false.

Hoist `buildCustomRequestBody` as a `@visibleForTesting` helper so the body shape is testable.

- [ ] **Step 3: Format + analyze + commit**

```bash
dart format lib/data/ai/datasource/custom_remote_datasource_dio.dart
flutter analyze lib/data/ai/datasource/ 2>&1 | tail -5
git add lib/data/ai/datasource/custom_remote_datasource_dio.dart
git commit -m "feat(custom-api): add reasoning_effort with rejection-retry + capabilities surface"
```

---

## Task 14: Plumb settings through `SessionService`

**Files:**
- Modify: `lib/services/session/session_service.dart`

- [ ] **Step 1: Drop the "ignored" log**

Remove the block at `lib/services/session/session_service.dart:146-156`:

```dart
if (mode == ChatMode.act || permission != ChatPermission.fullAccess) {
  dLog(
    '[SessionService] CLI provider $providerId — '
    'mode=$mode and permission=$permission ignored; CLI manages its own permissions',
  );
}
```

- [ ] **Step 2: Build `ProviderTurnSettings` once at the top of `sendAndStream`**

After the user-message persistence (around line 130) and before the provider-fork branch:

```dart
final session = await _session.getSession(sessionId);
final providerSettings = ProviderTurnSettings(
  modelId: model.modelId,
  systemPrompt: systemPrompt,
  mode: mode,
  effort: ChatEffort.values.firstWhereOrNull((e) => e.name == session?.effort),
  permission: permission,
);
```

Add the import:

```dart
import 'package:collection/collection.dart';
import '../../data/ai/models/provider_turn_settings.dart';
```

(`ChatEffort` already in scope via `session_settings.dart`.)

- [ ] **Step 3: Forward to `_streamProvider` (CLI path)**

Update the call site:

```dart
yield* _streamProvider(
  ds: ds,
  sessionId: sessionId,
  prompt: userInput,
  projectPath: projectPath,
  requestPermission: requestPermission,
  cancelFlag: cancelFlag,
  settings: providerSettings,
);
```

Update `_streamProvider`'s signature to accept `ProviderTurnSettings? settings`, and forward it to `ds.sendAndStream(... settings: settings)`.

- [ ] **Step 4: Forward to `_ai.streamMessage` (plain-text path)**

In the plain-text path (around line 201):

```dart
await for (final chunk in _ai.streamMessage(
  history: historyExcludingCurrent,
  prompt: userInput,
  model: model,
  systemPrompt: systemPrompt,
  settings: providerSettings,
)) {
  ...
}
```

- [ ] **Step 5: Forward to `_agent.runAgenticTurn` (custom-act path)**

```dart
await for (final msg in _agent.runAgenticTurn(
  ...
  settings: providerSettings,
)) {
  ...
}
```

(`AgentService.runAgenticTurn` will be updated in Task 15 to accept the new param.)

- [ ] **Step 6: Format + analyze**

```bash
dart format lib/services/session/session_service.dart
flutter analyze lib/services/session/session_service.dart 2>&1 | tail -5
```

Expected: errors in `agent_service.dart` (Task 15 fixes those). Session file itself clean.

- [ ] **Step 7: Hold commit (combine with Task 15)**

---

## Task 15: Plumb settings through `AgentService` and the streaming repos

**Files:**
- Modify: `lib/services/agent/agent_service.dart`
- Modify: `lib/data/ai/repository/text_streaming_repository.dart` (already touched in Task 6 — reconfirm)
- Modify: `lib/data/ai/repository/ai_repository_impl.dart`

- [ ] **Step 1: Add `settings` param to `runAgenticTurn`**

In `agent_service.dart`, add `ProviderTurnSettings? settings` to `runAgenticTurn` and forward it to every internal `streamMessage` call.

```dart
Stream<ChatMessage> runAgenticTurn({
  required String sessionId,
  required List<ChatMessage> history,
  required String userInput,
  required AIModel model,
  required ChatPermission permission,
  required String projectPath,
  required bool Function() cancelFlag,
  Future<bool> Function(PermissionRequest req)? requestPermission,
  McpStatusCallback? onMcpStatusChanged,
  McpRemoveCallback? onMcpServerRemoved,
  ProviderTurnSettings? settings,
}) async* {
  // ... existing body ...
  // every internal _ai.streamMessage(...) call gets `settings: settings,`
}
```

- [ ] **Step 2: Confirm `AIRepositoryImpl` and `TextStreamingRepository` accept and forward `settings`**

If Task 6 was complete, this is already done. Otherwise, ensure both `streamMessage` methods carry `ProviderTurnSettings? settings` and pass it to the underlying datasource.

- [ ] **Step 3: Run existing service tests**

```bash
flutter test test/services/session/ test/services/agent/ 2>&1 | tail -5
```

Existing tests should pass — they don't pass `settings`, and `null` is the safe default.

- [ ] **Step 4: Format + analyze + commit (combines Tasks 6, 14, 15)**

```bash
dart format lib/services/ lib/data/ai/repository/ lib/data/ai/datasource/text_streaming_datasource.dart
flutter analyze lib/ 2>&1 | tail -5
```

Expected: clean across the board (all 7 datasources are now compliant).

```bash
git add lib/services/session/session_service.dart \
        lib/services/agent/agent_service.dart \
        lib/data/ai/repository/text_streaming_repository.dart \
        lib/data/ai/repository/ai_repository_impl.dart \
        lib/data/ai/datasource/text_streaming_datasource.dart
git commit -m "feat(services): plumb ProviderTurnSettings through SessionService/AgentService/repos"
```

---

## Task 16: `chatInputBarOptions` notifier

**Files:**
- Create: `lib/features/chat/notifiers/chat_input_bar_options_notifier.dart`
- Create: `test/features/chat/notifiers/chat_input_bar_options_notifier_test.dart`

- [ ] **Step 1: Identify the model-id → AIModel lookup helper**

Run: `grep -n "AIModels\.\|byId\|firstWhere.*modelId" lib/data/shared/ai_model.dart`

Confirm there's a static `AIModels.byId(String)` or similar. If not, add one:

```dart
class AIModels {
  // ...existing const list of models...

  static AIModel? byId(String? id) {
    if (id == null) return null;
    return [gpt4o, sonnet45, opus47 /* etc */].firstWhereOrNull((m) => m.modelId == id);
  }
}
```

If a helper already exists, use it.

- [ ] **Step 2: Identify the HTTP datasource lookup**

Run: `grep -n "TextStreamingDatasource\|provider.*datasource" lib/services/ai_provider/ai_provider_service.dart`

The notifier needs to map `AIProvider` enum → `TextStreamingDatasource` instance. If a provider exists, reuse it. Otherwise, build a thin wrapper:

```dart
@riverpod
TextStreamingDatasource? textStreamingDatasourceFor(Ref ref, AIProvider provider) {
  return switch (provider) {
    AIProvider.anthropic => ref.watch(anthropicRemoteDatasourceProvider),
    AIProvider.openai => ref.watch(openaiRemoteDatasourceProvider),
    AIProvider.gemini => ref.watch(geminiRemoteDatasourceProvider),
    AIProvider.ollama => ref.watch(ollamaRemoteDatasourceProvider),
    AIProvider.custom => ref.watch(customRemoteDatasourceProvider),
  };
}
```

(Replace provider names with whatever `@riverpod` providers actually exist for each datasource.)

- [ ] **Step 3: Write the failing test**

Create `test/features/chat/notifiers/chat_input_bar_options_notifier_test.dart`:

```dart
import 'package:code_bench_app/data/ai/models/provider_capabilities.dart';
import 'package:code_bench_app/data/shared/session_settings.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_input_bar_options_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ...overrides for activeSessionProvider, providers...

void main() {
  // Detailed test setup uses a ProviderContainer with overrides for:
  //   - activeSessionProvider(sessionId)
  //   - aIProviderServiceProvider (CLI lookup)
  //   - textStreamingDatasourceFor (HTTP lookup)

  test('returns null when session is null', () async {
    final container = ProviderContainer(overrides: [/* session→null */]);
    expect(container.read(chatInputBarOptionsProvider('s1')), isNull);
  });

  test('returns CLI capabilities for a Claude CLI session', () async {
    // override session.providerId='claude-cli', model='sonnet'
    // override AIProviderService.getProvider('claude-cli') → fake CLI ds
    // expect supportedModes contains plan + act + chat
  });

  test('returns shrunken capabilities on OpenAI gpt-4o (no effort)', () async {
    // override session with providerId=null (HTTP path), modelId='gpt-4o'
    // expect supportedEfforts is empty
  });

  test('returns full capabilities on OpenAI gpt-5 (effort enabled)', () async {
    // expect supportedEfforts has 4 values
  });
}
```

(Actual test setup uses `ProviderContainer` overrides; exact override calls match the providers identified in Step 2.)

- [ ] **Step 4: Write the notifier**

Create `lib/features/chat/notifiers/chat_input_bar_options_notifier.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/provider_capabilities.dart';
import '../../../data/shared/ai_model.dart';
import '../../../services/ai_provider/ai_provider_service.dart';
import '../../../services/session/session_service.dart';

part 'chat_input_bar_options_notifier.g.dart';

@riverpod
ProviderCapabilities? chatInputBarOptions(Ref ref, String sessionId) {
  final session = ref.watch(activeSessionProvider(sessionId)).valueOrNull;
  if (session == null) return null;
  final model = AIModels.byId(session.modelId);
  if (model == null) return null;

  // CLI path
  final cliDs = ref.watch(aIProviderServiceProvider.notifier).getProvider(session.providerId);
  if (cliDs != null) return cliDs.capabilitiesFor(model);

  // HTTP path
  final httpDs = ref.watch(textStreamingDatasourceForProvider(model.provider));
  return httpDs?.capabilitiesFor(model);
}
```

(Adjust the exact provider/getter names to match what the codebase already exposes — confirmed in Steps 1-2.)

- [ ] **Step 5: Regenerate riverpod code**

Run: `dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5`

- [ ] **Step 6: Run tests + lint**

```bash
flutter test test/features/chat/notifiers/chat_input_bar_options_notifier_test.dart 2>&1 | tail -5
dart format lib/features/chat/notifiers/chat_input_bar_options_notifier.dart \
            lib/features/chat/notifiers/chat_input_bar_options_notifier.g.dart \
            test/features/chat/notifiers/chat_input_bar_options_notifier_test.dart
flutter analyze lib/features/chat/notifiers/ test/features/chat/notifiers/ 2>&1 | tail -5
```

Expected: tests pass; analyzer clean.

- [ ] **Step 7: Commit**

```bash
git add lib/features/chat/notifiers/chat_input_bar_options_notifier.dart \
        lib/features/chat/notifiers/chat_input_bar_options_notifier.g.dart \
        test/features/chat/notifiers/chat_input_bar_options_notifier_test.dart
git commit -m "feat(chat): chatInputBarOptions notifier — model-aware provider capabilities"
```

---

## Task 17: Gate `ChatInputBar` controls on capabilities

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar.dart`

- [ ] **Step 1: Inspect current options strip**

Run: `grep -n "ChatMode\|ChatEffort\|ChatPermission\|DropdownButton\|PopupMenu" lib/features/chat/widgets/chat_input_bar.dart | head -30`

Identify where each dropdown is rendered (mode picker, effort picker, permission picker, model picker, system-prompt textarea).

- [ ] **Step 2: Read capabilities at the top of `build`**

```dart
final caps = ref.watch(chatInputBarOptionsProvider(widget.sessionId));
```

- [ ] **Step 3: Gate each control**

Wrap each existing dropdown:

```dart
// Model picker — visible only when the provider supports model override.
// (Every current provider returns true; the gate exists for future fixed-model bots.)
if (caps?.supportsModelOverride == true) _ModelPicker(...),

// Mode dropdown — render only when more than one mode supported
if ((caps?.supportedModes ?? const <ChatMode>{}).length > 1)
  _ModeDropdown(supported: caps!.supportedModes, ...),

// Effort dropdown — only when non-empty
if ((caps?.supportedEfforts ?? const <ChatEffort>{}).isNotEmpty)
  _EffortDropdown(supported: caps!.supportedEfforts, ...),

// Permission dropdown — only when non-empty
if ((caps?.supportedPermissions ?? const <ChatPermission>{}).isNotEmpty)
  _PermissionDropdown(supported: caps!.supportedPermissions, ...),

// System prompt textarea — only when supportsSystemPrompt
if (caps?.supportsSystemPrompt == true) _SystemPromptField(...),
```

If `caps == null`, render the entire options strip with all controls disabled (greyed) and a tooltip "Provider not detected".

- [ ] **Step 4: Filter dropdown items to the supported set**

Inside each `_*Dropdown` widget, change the items list from `EnumName.values` to the passed-in `supported` set (preserving the existing label extension).

Example for the effort dropdown:

```dart
DropdownButton<ChatEffort>(
  value: ...,
  items: supported.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
  onChanged: ...,
);
```

- [ ] **Step 5: Format + analyze + manual UI smoke**

```bash
dart format lib/features/chat/widgets/chat_input_bar.dart
flutter analyze lib/features/chat/widgets/ 2>&1 | tail -5
```

Manual: `flutter run -d macos`. Verify:
- Open new session, no provider selected → strip rendered disabled.
- Select Claude CLI provider → mode/effort/permission/system-prompt all visible; mode dropdown shows chat/plan/act.
- Switch to Codex → mode dropdown shows chat/act only (no plan).
- Switch to OpenAI + gpt-5 → effort visible; mode/permission hidden.
- Switch to OpenAI + gpt-4o → effort hidden too; only model + system prompt remain.

(Per `feedback_smoke_test_launch` memory: report the path and let the user launch the build.)

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/widgets/chat_input_bar.dart
git commit -m "feat(chat): gate input-bar controls on provider+model capabilities"
```

---

## Task 18: Final verification

- [ ] **Step 1: Full format pass**

Run: `dart format lib/ test/ 2>&1 | tail -3`

Expected: any drift gets cleaned up. Commit it under `chore: dart format` if non-empty.

- [ ] **Step 2: Full analyzer pass**

Run: `flutter analyze 2>&1 | tail -5`

Expected: `No issues found!`

- [ ] **Step 3: Full test suite**

Run: `flutter test 2>&1 | tail -10`

Expected: All tests pass — existing 659+ plus the 6 new test files (mappers, claude argv, codex thread/turn params, anthropic body, openai body, gemini body, options notifier).

- [ ] **Step 4: Manual smoke per provider**

Per [feedback_post_plan_qa_checklist](memory):

| Scenario | Expectation |
|---|---|
| Codex session + model `gpt-5-codex` + effort `max` + permission `fullAccess` | Tool-call rows show `[Codex CLI] [gpt-5-codex]` badges; no permission prompts |
| Claude CLI session + permission `readOnly` | Tool calls execute in `--permission-mode plan`; no edits attempted |
| Claude CLI session + mode `plan` | Same as above (override doesn't matter) |
| Anthropic session on Sonnet 4.x + effort `high` | Network inspector shows `thinking: {type:'enabled', budget_tokens:16384}` in request |
| Anthropic session on Opus 4.7+ + effort `high` | Network inspector shows NO `thinking` field |
| OpenAI session on `gpt-5` + effort `medium` | Network inspector shows `reasoning_effort: 'medium'` |
| OpenAI session on `gpt-4o` + effort dropdown | Effort dropdown is hidden |
| Gemini 2.5 + effort `max` | `generationConfig.thinkingConfig.thinkingBudget == -1` |
| New session, no provider yet | Options strip rendered fully disabled with tooltip |

- [ ] **Step 5: Confirm no stale CLI argv**

Run: `grep -rn "bypassPermissions\|via Claude Code" lib/ test/ 2>/dev/null`

Expected: only matches inside test regression-guards (`tool_call_row_test.dart`) and inside the Claude CLI mapper (which now uses `bypassPermissions` only via `mapClaudePermissionMode`).

- [ ] **Step 6: Commit any final formatting**

```bash
git status
# If anything uncommitted:
git add -A
git commit -m "chore: dart format"
```

- [ ] **Step 7: Push branch and open PR**

```bash
git push -u origin fix/2026-05-06-tool-call-provider-model-badges
gh pr create --title "feat(provider-settings): wire model/system-prompt/mode/effort/permission to all providers" --body "$(cat <<'EOF'
## Summary
- Wires user picks for `model`, `system prompt`, `mode`, `effort`, `permission` through `SessionService` to every provider that has a server-side or argv-side knob for them
- Both datasource interfaces (`AIProviderDatasource` for CLI; `TextStreamingDatasource` for HTTP) gain optional `ProviderTurnSettings settings` and a `capabilitiesFor(AIModel)` getter
- Chat input bar renders only the controls the active provider+model actually honour; whole strip is disabled when no provider is detected
- Relocates `ChatMode/ChatEffort/ChatPermission` to `lib/data/shared/`

## Test plan
- [ ] `dart format lib/ test/` clean
- [ ] `flutter analyze` clean
- [ ] `flutter test` green
- [ ] Codex session shows `[Codex CLI] [<model>]` badges with the picked model
- [ ] Claude CLI `permission=readOnly` enforces `--permission-mode plan`
- [ ] Anthropic Sonnet 4.x with `effort=high` sends `thinking.budget_tokens=16384`
- [ ] Anthropic Opus 4.7+ omits `thinking` entirely
- [ ] OpenAI `gpt-5` sends `reasoning_effort`; `gpt-4o` does not (and dropdown hides)
- [ ] Gemini 2.5 + `effort=max` sends `thinkingBudget=-1`
- [ ] No-provider session renders disabled options strip
EOF
)"
```

---

## Self-review notes

**Spec coverage:** Each spec section maps to a task — enum migration (Task 1), value objects (Tasks 2–3), mappers (Task 4), interface extensions (Tasks 5–6), per-datasource (Tasks 7–13), service plumbing (Tasks 14–15), notifier (Task 16), widget (Task 17), verification (Task 18). All 11 acceptance criteria covered in Task 18 Step 4.

**Placeholder scan:** Task 16 Step 1–2 say "if a helper already exists, use it" — these are real lookups (the codebase shape is known but specific provider names need confirmation), not placeholders. Task 17 Step 1 is a `grep` to discover existing dropdown widget names; the work itself is concrete.

**Type consistency:**
- `mapClaudeEffort` / `mapCodexEffort` / `mapOpenAIReasoningEffort` / `mapGeminiThinkingBudget` / `mapGeminiThinkingLevel` / `mapAnthropicThinkingBudget` / `mapOllamaThink` — all defined in Task 4, all referenced consistently in Tasks 7-12.
- `isAnthropicAdaptiveOnly` / `isOpenAiReasoningModel` / `isGemini3` / `supportsGeminiThinking` — same.
- `ProviderTurnSettings` field names (`modelId`, `systemPrompt`, `mode`, `effort`, `permission`) consistent across all 17 tasks.
- `ProviderCapabilities` field names (`supportsModelOverride`, `supportsSystemPrompt`, `supportedModes`, `supportedEfforts`, `supportedPermissions`) consistent.
- `buildClaudeCliArgs` / `buildCodexTurnStartParams` / `buildCodexThreadStartParams` / `buildAnthropicRequestBody` / `buildOpenAiRequestBody` / `buildGeminiRequestBody` — all hoisted helpers, all `@visibleForTesting`, named consistently.

**Risks acknowledged in spec:**
- Adaptive-only Anthropic model 400s → Task 4 mapper returns null + Task 9 caps shrink.
- Non-reasoning OpenAI model rejects effort → Task 4 allowlist + Task 10 caps shrink.
- Pre-Gemini-2.5 has no thinking → Task 4 `supportsGeminiThinking` + Task 11 caps shrink.
