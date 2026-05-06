# Provider Settings Passthrough — Design Spec

> **Date:** 2026-05-06
> **Status:** Design (pre-plan)
> **Worktree:** `fix/2026-05-06-tool-call-provider-model-badges` (continuation)
> **Companion to:** [2026-05-06-tool-call-provider-model-badges-design.md](./2026-05-06-tool-call-provider-model-badges-design.md)

## Goal

Wire the user's per-session selections — **model**, **system prompt**, **mode** (chat/plan/act), **effort** (low/medium/high/max), **permission** (readOnly/askBefore/fullAccess) — through `SessionService` and `AIProviderDatasource` to every provider that has a server-side or argv-side knob for them, and have the chat input bar dynamically reveal only the controls each provider honours. Today most of these settings are silently dropped on most paths:

- Both CLI providers (Claude Code, Codex) hardcode their own permissions and never see the user's mode/effort/permission/model picks; the only thing they get is the prompt.
- All five HTTP providers (Anthropic, OpenAI, Gemini, Ollama, Custom) receive `model` and `system` only — no effort, no thinking budget, no tool gating.

After this change, every option the active provider supports flows through unmodified, and options the provider can't honour are hidden so the UI never lies. Two user-visible bugs close as side effects:

1. The tool-call-row model badge from the [companion spec](./2026-05-06-tool-call-provider-model-badges-design.md) becomes accurate on Codex turns (we send `model`, so we know what to display).
2. Effort/system-prompt picks become functional on Anthropic, OpenAI, and Gemini HTTP sessions.

## Non-goals (explicit follow-up scope)

- **Routing Anthropic/OpenAI/Gemini/Ollama HTTP providers through the agent loop.** Today only `provider == custom + mode == act + projectPath != null` reaches `AgentService.runAgenticTurn` ([session_service.dart:172](../../../lib/services/session/session_service.dart#L172)). That's the *only* path where our `ToolRegistry` (and therefore the user's denylist + MCP servers) fires. Wiring tool execution into the other HTTP datasources is a separate, larger PR.
- **Denylist (segment / filename / extension / prefix) propagation to providers.** Stays scoped to `custom + act + projectPath` until the agent-loop refactor lands.
- **MCP server passthrough.** Our app-configured MCP servers stay scoped to the same `custom + act` path. Anthropic's server-side MCP connector (beta `mcp-client-2025-11-20`) and OpenAI Responses API's remote-MCP feature remain untouched — they're correct candidates for a follow-up but require new datasource code paths.
- **Gemini 3 thinking.** Gemini 3 replaced `thinkingConfig.thinkingBudget` with `thinkingLevel`. We target the Gemini 2.5 shape only; Gemini 3 effort is dropped silently with a `dLog` until a follow-up.
- **OpenAI Responses migration.** Sticking with `/v1/chat/completions`.
- **Auto-detecting model lists from the CLI / API itself.** Model picker still uses the static `AIModels` catalog.

## Background — what each provider accepts

The matrix is grounded in 2025–2026 docs and the schemas captured at design time (see research transcripts).

### Effort

| Provider | Field | Shape | Notes |
|---|---|---|---|
| Claude CLI | argv `--effort` | enum `low\|medium\|high\|xhigh\|max` | All five values supported |
| Codex CLI | `turn/start.effort` | enum `none\|minimal\|low\|medium\|high\|xhigh` | No `max`; we map → `xhigh` |
| Anthropic Messages | `thinking.budget_tokens` (top-level alongside `system`) | integer; **must be `< max_tokens`**; minimum `1024` | **Returns 400 on Opus 4.7+ models** (those require "adaptive thinking"); skip on those |
| OpenAI Chat Completions | `reasoning_effort` | enum `none\|minimal\|low\|medium\|high\|xhigh` | o-series / gpt-5 family only — silently ignored on others |
| Gemini API | `generationConfig.thinkingConfig.thinkingBudget` | integer (`-1` = dynamic, `0` = off) | Gemini 2.5 series; Gemini 3 uses `thinkingLevel` (out of scope) |
| Ollama (`/api/chat`) | `think` | boolean | No granularity — coerce |
| Custom (OpenAI-compat) | `reasoning_effort` | enum, narrower than upstream OpenAI (typically `low\|medium\|high\|none`) | Endpoint may accept or ignore |

### System prompt

| Provider | Field | Shape |
|---|---|---|
| Claude CLI | argv `--append-system-prompt` | free text (positional) |
| Codex CLI | `thread/start.developerInstructions` | string (thread-sticky) |
| Anthropic Messages | `system` (top-level) | string |
| OpenAI Chat Completions | `messages` with `role: "system"` (already wired) | string |
| Gemini API | `systemInstruction.parts[0].text` (already wired) | text |
| Ollama | `messages` with `role: "system"` (already wired) | string |
| Custom | `messages` with `role: "system"` (already wired) | string |

### Mode (chat / plan / act)

| Provider | Mapping |
|---|---|
| Claude CLI | `plan` → `--permission-mode plan` (overrides Permission). `chat`/`act` → derived from Permission |
| Codex CLI | No equivalent — silent no-op (Codex always allows tool use; client-side gating only) |
| HTTP providers | Out of scope for this PR — they don't currently send `tools`, so chat/act distinction is moot until the agent-loop refactor |

### Permission (readOnly / askBefore / fullAccess)

| Provider | Mapping |
|---|---|
| Claude CLI | `readOnly`/`askBefore` → `--permission-mode default`; `fullAccess` → `--permission-mode bypassPermissions` |
| Codex CLI | `sandboxPolicy` (`readOnly`/`workspaceWrite`/`dangerFullAccess`) + `approvalPolicy` (`on-request`/`on-request`/`never`) on `turn/start` |
| HTTP providers | Out of scope — enforced app-side by the agent loop on `custom + act` only (already implemented) |

## Architecture

```
Widgets ─→ Notifiers ─→ Services ─→ Datasources ─→ External (CLI / HTTP API)
   │           │            │            │
   │           │            │            └─ Datasources accept ProviderTurnSettings.
   │           │            │               Each maps fields it can honour; ignores
   │           │            │               the rest. Capability surface is a const.
   │           │            │
   │           │            └─ SessionService builds ProviderTurnSettings from the
   │           │               session row + sendAndStream args; forwards verbatim.
   │           │
   │           └─ chatInputBarOptionsProvider returns the active provider's
   │              ProviderCapabilities (or null when no provider detected).
   │
   └─ ChatInputBar gates dropdowns on capabilities; disables strip when null.
```

The dependency rule from [CLAUDE.md](../../../CLAUDE.md) is preserved.

## Data model

### `ProviderTurnSettings` (new — `lib/data/ai/models/provider_turn_settings.dart`)

```dart
@freezed
abstract class ProviderTurnSettings with _$ProviderTurnSettings {
  const factory ProviderTurnSettings({
    String? modelId,
    String? systemPrompt,
    ChatMode? mode,
    ChatEffort? effort,
    ChatPermission? permission,
  }) = _ProviderTurnSettings;
}
```

`ChatMode/ChatEffort/ChatPermission` come from `lib/data/session/models/session_settings.dart` — already cross-cutting across `services/`, `features/chat/`, `data/session/`. Letting `data/ai/` import the same is consistent. (A relocation to `data/shared/` is a deferred cleanup.)

### `ProviderCapabilities` (new — `lib/data/ai/models/provider_capabilities.dart`)

```dart
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

Exposed via a new `ProviderCapabilities get capabilities` getter on `AIProviderDatasource`. Each datasource owns its own const; the widget reads it through a notifier.

Capability constants per datasource (matrix at the bottom of this section):

```dart
// claude_cli_datasource_process.dart
static const _capabilities = ProviderCapabilities(
  supportsModelOverride: true, supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat, ChatMode.plan, ChatMode.act},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess},
);

// codex_cli_datasource_process.dart
static const _capabilities = ProviderCapabilities(
  supportsModelOverride: true, supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat, ChatMode.act},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess},
);

// anthropic_remote_datasource_dio.dart
static const _capabilities = ProviderCapabilities(
  supportsModelOverride: true, supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: {},
);

// openai_remote_datasource_dio.dart
static const _capabilities = ProviderCapabilities(
  supportsModelOverride: true, supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: {},
);

// gemini_remote_datasource_dio.dart
static const _capabilities = ProviderCapabilities(
  supportsModelOverride: true, supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: {},
);

// ollama_remote_datasource_dio.dart
static const _capabilities = ProviderCapabilities(
  supportsModelOverride: true, supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat},
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},  // boolean coercion
  supportedPermissions: {},
);

// custom_remote_datasource_dio.dart
static const _capabilities = ProviderCapabilities(
  supportsModelOverride: true, supportsSystemPrompt: true,
  supportedModes: {ChatMode.chat, ChatMode.act},  // act runs the agent loop today
  supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
  supportedPermissions: {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess},
);
```

### Mapping functions — `lib/data/ai/util/setting_mappers.dart`

Pure functions, exhaustive `switch`, single source of truth, all unit-tested.

```dart
String mapClaudeEffort(ChatEffort e) => switch (e) {
  ChatEffort.low => 'low',
  ChatEffort.medium => 'medium',
  ChatEffort.high => 'high',
  ChatEffort.max => 'max',
};

String mapClaudePermissionMode({required ChatMode mode, required ChatPermission permission}) {
  if (mode == ChatMode.plan) return 'plan';
  return switch (permission) {
    ChatPermission.readOnly => 'default',
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
  ChatPermission.readOnly => {'type': 'readOnly'},
  ChatPermission.askBefore => {'type': 'workspaceWrite'},
  ChatPermission.fullAccess => {'type': 'dangerFullAccess'},
};

String mapCodexApprovalPolicy(ChatPermission p) => switch (p) {
  ChatPermission.readOnly => 'on-request',
  ChatPermission.askBefore => 'on-request',
  ChatPermission.fullAccess => 'never',
};

/// Anthropic thinking budget. Returns null when [model.modelId] is on the
/// Opus 4.7+ adaptive-thinking allowlist (passing manual budget 400s).
int? mapAnthropicThinkingBudget(ChatEffort effort, {required int maxTokens, required String modelId}) {
  if (_anthropicAdaptiveOnly.contains(modelId)) return null;
  final raw = switch (effort) {
    ChatEffort.low => 2048,
    ChatEffort.medium => 8192,
    ChatEffort.high => 16384,
    ChatEffort.max => 32768,
  };
  // Must be strictly less than max_tokens; clamp to a safe ceiling.
  return raw >= maxTokens ? maxTokens - 1 : raw;
}

const _anthropicAdaptiveOnly = <String>{
  'claude-opus-4-7',
  'claude-opus-4-7-20251201',  // placeholder; align with AIModels catalog
};

/// OpenAI reasoning_effort. Maps `max` → `xhigh`.
String mapOpenAIReasoningEffort(ChatEffort e) => switch (e) {
  ChatEffort.low => 'low',
  ChatEffort.medium => 'medium',
  ChatEffort.high => 'high',
  ChatEffort.max => 'xhigh',
};

/// Gemini thinkingBudget — integer token allowance. `-1` = dynamic.
int mapGeminiThinkingBudget(ChatEffort e) => switch (e) {
  ChatEffort.low => 2048,
  ChatEffort.medium => 8192,
  ChatEffort.high => 16384,
  ChatEffort.max => -1,  // dynamic = "use as much as you need"
};

/// Ollama coerces effort to a boolean: anything ≥ low → think enabled.
bool mapOllamaThink(ChatEffort? e) => e != null;
```

## Capability matrix (rendered on the chat input bar)

| Setting | Claude CLI | Codex CLI | Anthropic | OpenAI | Gemini | Ollama | Custom |
|---|---|---|---|---|---|---|---|
| Model picker | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| System prompt | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Mode `chat` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Mode `plan` | ✓ | — | — | — | — | — | — |
| Mode `act` | ✓ | ✓ | — | — | — | — | ✓ |
| Effort `low/medium/high/max` | ✓ | ✓ (max→xhigh) | ✓ (token budget; null on Opus 4.7+) | ✓ (max→xhigh; only on reasoning models) | ✓ (token budget; max=`-1` dynamic) | ✓ (any → `think:true`) | ✓ (Ollama-compat enum) |
| Permission `readOnly`/`askBefore` | ✓ (degrades to `default`) | ✓ | — | — | — | — | ✓ (agent loop) |
| Permission `fullAccess` | ✓ (`bypassPermissions`) | ✓ (`dangerFullAccess`) | — | — | — | — | ✓ (agent loop) |

## Population — what flows where

### 1. `ChatInputBar` reads capabilities

New notifier `lib/features/chat/notifiers/chat_input_bar_options_notifier.dart`:

```dart
@riverpod
ProviderCapabilities? chatInputBarOptions(Ref ref, String sessionId) {
  final session = ref.watch(activeSessionProvider(sessionId));
  if (session == null) return null;
  final ds = ref.watch(aIProviderServiceProvider).getProvider(session.providerId);
  return ds?.capabilities;
}
```

Widget gates each dropdown:
- `null` → entire options strip rendered disabled with tooltip "Provider not detected"
- non-null → render only options where `caps.supportedX` is non-empty / true; filter dropdown items to the supported subset

### 2. `SessionService` builds `ProviderTurnSettings`

In `sendAndStream`, before forwarding to either CLI or HTTP path:

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

Forwarded into `_streamProvider(ds: ds, ..., settings: providerSettings)` for CLI and into the HTTP datasource calls (described per-provider below).

The "ignored" log at `session_service.dart:147-156` is removed — settings now flow through.

### 3. Both datasource interfaces accept settings

The CLI interface (`AIProviderDatasource`) and the HTTP interface (`TextStreamingDatasource`) each gain an optional `settings` param:

```dart
// lib/data/ai/datasource/ai_provider_datasource.dart  (CLI providers)
Stream<ProviderRuntimeEvent> sendAndStream({
  required String prompt,
  required String sessionId,
  required String workingDirectory,
  ProviderTurnSettings? settings,
});

// lib/data/ai/datasource/text_streaming_datasource.dart  (HTTP providers)
Stream<String> streamMessage({
  required List<ChatMessage> history,
  required String prompt,
  required AIModel model,
  String? systemPrompt,
  ProviderTurnSettings? settings,
});
```

Default null preserves existing call sites until they're updated. `ai_repository_impl.dart` and the streaming repo seam forward the param verbatim. `AgentService.runAgenticTurn` (custom-act path) also forwards `settings` so the agent's HTTP fan-out picks up effort/system-prompt picks.

### 4. Per-datasource changes

**Claude CLI** ([claude_cli_datasource_process.dart](../../../lib/data/ai/datasource/claude_cli_datasource_process.dart)):

```dart
final args = <String>[
  '-p', '--output-format', 'stream-json', '--include-partial-messages', '--verbose',
  if (settings?.modelId != null) ...['--model', settings!.modelId!],
  if (settings?.effort != null) ...['--effort', mapClaudeEffort(settings!.effort!)],
  if (settings?.systemPrompt?.isNotEmpty == true)
    ...['--append-system-prompt', settings!.systemPrompt!],
  '--permission-mode',
  mapClaudePermissionMode(
    mode: settings?.mode ?? ChatMode.chat,
    permission: settings?.permission ?? ChatPermission.fullAccess,
  ),
  if (isFirstTurn) ...['--session-id', sessionId] else ...['--resume', sessionId],
  '--', prompt,
];
```

Hardcoded `bypassPermissions` is removed; permission is always derived. Emits `ProviderInit(provider: id, modelId: settings?.modelId)`.

**Codex CLI** ([codex_cli_datasource_process.dart](../../../lib/data/ai/datasource/codex_cli_datasource_process.dart)):

`buildCodexTurnStartParams` extended:

```dart
{
  'threadId': threadId,
  'input': [{'type': 'text', 'text': prompt}],
  if (modelId != null) 'model': modelId,
  if (effort != null) 'effort': mapCodexEffort(effort),
  if (permission != null) 'sandboxPolicy': mapCodexSandboxPolicy(permission),
  if (permission != null) 'approvalPolicy': mapCodexApprovalPolicy(permission),
}
```

`_startThread` (first turn only) extended to include `developerInstructions: settings?.systemPrompt`. Emits `ProviderInit(provider: id, modelId: settings?.modelId)` — the v1 `_version` stand-in is dropped.

**Anthropic Messages API** ([anthropic_remote_datasource_dio.dart](../../../lib/data/ai/datasource/anthropic_remote_datasource_dio.dart)):

```dart
final body = <String, dynamic>{
  'model': model.modelId,
  'max_tokens': maxTokens,  // existing 4096
  'messages': messages,
  'stream': true,
  if (systemPrompt != null) 'system': systemPrompt,
};
if (settings?.effort != null) {
  final budget = mapAnthropicThinkingBudget(
    settings!.effort!, maxTokens: maxTokens, modelId: model.modelId,
  );
  if (budget != null) body['thinking'] = {'type': 'enabled', 'budget_tokens': budget};
}
```

Datasource interface for `streamMessage` already takes `model`/`systemPrompt`; we extend it with optional `ProviderTurnSettings? settings`. Same pattern for OpenAI/Gemini/Ollama/Custom.

**OpenAI Chat Completions**:

```dart
final body = <String, dynamic>{
  'model': model.modelId,
  'messages': messages,
  'stream': true,
};
if (settings?.effort != null && _isReasoningModel(model.modelId)) {
  body['reasoning_effort'] = mapOpenAIReasoningEffort(settings!.effort!);
}
```

`_isReasoningModel` checks the `AIModel`'s id against a small allowlist (`o1`, `o3`, `o4-mini`, `gpt-5`, `gpt-5-mini`, etc.). Non-reasoning models silently skip the field.

**Gemini**:

```dart
final body = <String, dynamic>{
  ...,
  if (settings?.effort != null)
    'generationConfig': {
      'thinkingConfig': {
        'thinkingBudget': mapGeminiThinkingBudget(settings!.effort!),
      },
    },
};
```

Gemini 3 models (when added to catalog) are detected via id prefix and skipped with `dLog`.

**Ollama** (`/api/chat`):

```dart
final body = <String, dynamic>{
  'model': model.modelId,
  'messages': messages,
  'stream': true,
  if (settings?.effort != null) 'think': mapOllamaThink(settings!.effort),
};
```

**Custom**:

```dart
final body = <String, dynamic>{
  'model': model.modelId,
  'messages': messages,
  'stream': true,
  if (settings?.effort != null) 'reasoning_effort': mapOpenAIReasoningEffort(settings!.effort!),
};
```

Some custom endpoints will reject unknown fields. We swallow that as a `BadRequestException` with a recoverable message ("Endpoint rejected reasoning_effort — try setting effort to off") rather than a hard fail. See [risks](#risks--mitigations).

## Files

### New (4)

| Path | Responsibility |
|---|---|
| `lib/data/ai/models/provider_turn_settings.dart` | Freezed value object passed through every datasource |
| `lib/data/ai/models/provider_capabilities.dart` | Freezed value object exposed per-datasource |
| `lib/data/ai/util/setting_mappers.dart` | Pure mapping functions (single source of truth) |
| `lib/features/chat/notifiers/chat_input_bar_options_notifier.dart` | Reactive capabilities lookup |

### Modified

| Path | Change |
|---|---|
| `lib/data/ai/datasource/ai_provider_datasource.dart` | Add `capabilities` getter; add `settings` param to `sendAndStream` |
| `lib/data/ai/datasource/claude_cli_datasource_process.dart` | Capabilities const; honour settings in argv; drop hardcoded `bypassPermissions`; emit `modelId` on `ProviderInit` |
| `lib/data/ai/datasource/codex_cli_datasource_process.dart` | Capabilities const; pass settings through `buildCodexTurnStartParams` and `_startThread`; emit `modelId` on `ProviderInit` (drop `_version`) |
| `lib/data/ai/datasource/anthropic_remote_datasource_dio.dart` | Capabilities const; add `thinking.budget_tokens` from effort (with Opus 4.7+ skip + clamp) |
| `lib/data/ai/datasource/openai_remote_datasource_dio.dart` | Capabilities const; add `reasoning_effort` for reasoning-model allowlist |
| `lib/data/ai/datasource/gemini_remote_datasource_dio.dart` | Capabilities const; add `generationConfig.thinkingConfig.thinkingBudget` |
| `lib/data/ai/datasource/ollama_remote_datasource_dio.dart` | Capabilities const; add `think: true` when effort is set |
| `lib/data/ai/datasource/custom_remote_datasource_dio.dart` | Capabilities const; add `reasoning_effort` (best-effort) |
| `lib/data/ai/repository/ai_repository_impl.dart` and the streaming repo seam it backs | Plumb optional `ProviderTurnSettings` through `streamMessage` |
| `lib/services/session/session_service.dart` | Build `ProviderTurnSettings`; forward through agent loop, plain-text, and CLI paths; drop "ignored" log |
| `lib/services/agent/agent_service.dart` | Forward settings to `_ai.streamMessage` so the agent-loop's HTTP fan-out also gets them |
| `lib/features/chat/widgets/chat_input_bar.dart` | Read `chatInputBarOptionsProvider`; gate every options control; "disabled strip" state when null |

### Deleted

None.

## Testing

| Layer | Test |
|---|---|
| `setting_mappers_test.dart` | Every enum value × CLI / HTTP mapper. Anthropic budget clamps when `>= max_tokens`. Anthropic returns null for Opus 4.7+ allowlist. OpenAI reasoning model allowlist. |
| `claude_cli_args_test.dart` (new) | Pure helper that builds the argv list — assert `--model`, `--effort`, `--append-system-prompt`, `--permission-mode` appear with the right values across permutations. |
| `codex_cli_turn_start_params_test.dart` (existing) | Extend with cases that assert `model`, `effort`, `sandboxPolicy`, `approvalPolicy` appear when settings are passed. |
| `codex_cli_thread_start_params_test.dart` (new) | Assert `developerInstructions` is included when `settings.systemPrompt` is set. |
| `anthropic_request_body_test.dart` (new) | Asserts `thinking.budget_tokens` shape; clamping; Opus 4.7+ skip; `system` field unchanged. |
| `openai_request_body_test.dart` (new) | `reasoning_effort` set only on allowlisted models. |
| `gemini_request_body_test.dart` (new) | `thinkingConfig.thinkingBudget` shape; max → `-1`. |
| `chat_input_bar_options_notifier_test.dart` (new) | Returns capabilities of active provider; null when no provider; updates when provider changes. |
| `session_service_test.dart` (existing) | New cases: settings flow through `_streamProvider` and through plain-text path to a fake datasource. |

No e2e UI tests — capability filtering is exercised via the notifier test; widget composition is straightforward.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Anthropic Opus 4.7+ 400s on manual `thinking` | `mapAnthropicThinkingBudget` returns null on the allowlist; the `thinking` field is omitted entirely, falling back to the model's adaptive thinking |
| OpenAI non-reasoning model rejects `reasoning_effort` | `_isReasoningModel` allowlist gates the field |
| Capabilities are static-per-datasource but effort applies only to *some* models (OpenAI o-series, Anthropic Sonnet 4+, Gemini 2.5+) — UI shows the dropdown even when the picked model ignores it | Accepted: keep capabilities datasource-scoped; document as "soft UI lie" in the README. A model-aware capability surface (capability per provider × model) is a follow-up if it becomes painful |
| Custom endpoint rejects `reasoning_effort` | `BadRequestException` is wrapped with a recoverable message, not a hard fail; user can switch effort to a lower value or pick a different endpoint |
| Gemini 3 model would be misconfigured by `thinkingBudget` | Gemini 3 prefix detection skips with `dLog`; capability matrix unchanged for now |
| Capability drift — adding a new app enum without updating each datasource | Dart's exhaustive `switch` in the mapper file fail-compiles. Each datasource also has explicit `Set` literals — adding a value won't auto-include it (default = "not supported", which is the safer default) |
| Claude CLI doesn't recognise `--effort` (older versions) | CLI errors loudly on stderr; routed through `ProviderStreamFailure`. User downgrades or updates Claude. |
| Existing `bypassPermissions` regression for Claude CLI users | Default `ChatPermission.fullAccess` → `bypassPermissions`. Behaviour preserved for the common case. |
| User flips a setting mid-session | Codex thread settings (sandbox/approval) are session-sticky; new picks apply on next turn. Same for Claude. Acceptable. |

## Acceptance

1. **Codex** session with model `gpt-5-codex` + effort `max` → `turn/start` includes `model: "gpt-5-codex"` and `effort: "xhigh"`. Tool-call rows show `[Codex CLI] [gpt-5-codex]` badges.
2. **Claude CLI** session with permission `readOnly` + mode `chat` → argv contains `--permission-mode default`. With mode `plan` → argv contains `--permission-mode plan`. With effort `max` + system prompt → argv contains `--effort max` and `--append-system-prompt "<prompt>"`.
3. **Anthropic** session on a Sonnet 4.x model with effort `high` → request body has `thinking: {type: 'enabled', budget_tokens: 16384}`.
4. **Anthropic** session on an Opus 4.7+ model with effort `high` → request body has **no** `thinking` field.
5. **OpenAI** session with effort `medium` on `gpt-5` → request body has `reasoning_effort: "medium"`. On `gpt-4o` → no `reasoning_effort` field.
6. **Gemini** 2.5 Flash session with effort `max` → request body has `generationConfig.thinkingConfig.thinkingBudget: -1`.
7. **Ollama** session with any non-null effort → request body has `think: true`.
8. With **no** provider yet detected, the chat-input-bar options strip is rendered fully disabled with a tooltip.
9. With Codex active, the `Plan` mode option is hidden.
10. With Anthropic active, only model picker, system-prompt, and effort dropdown render in the options strip; mode and permission controls hide.
11. `flutter analyze` clean. `flutter test` green. `dart format` clean.

## Out of scope (re-stated)

- Routing Anthropic / OpenAI / Gemini / Ollama through the agent loop (and thus exposing tools / denylist / our app-side MCP servers to them).
- Anthropic server-side MCP connector and OpenAI Responses-API remote MCP — both are correct future-PR candidates.
- Migrating the existing `ChatMode/ChatEffort/ChatPermission` enums to `data/shared/`.
- Auto-detecting model lists per provider.
- Gemini 3 `thinkingLevel` enum (added when Gemini 3 models enter the catalog).
