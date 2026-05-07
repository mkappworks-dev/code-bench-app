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
| Claude CLI | `readOnly` → `--permission-mode plan` (true read-only enforcement); `askBefore` → `--permission-mode default`; `fullAccess` → `--permission-mode bypassPermissions` |
| Codex CLI | `sandboxPolicy` (`readOnly`/`workspaceWrite`/`dangerFullAccess`) + `approvalPolicy` (`on-request`/`on-request`/`never`) on `turn/start` |
| HTTP providers | Out of scope — enforced app-side by the agent loop on `custom + act` only (already implemented) |

**Mode×Permission collision rule for Claude:** if `mode == plan` *or* `permission == readOnly`, both produce `--permission-mode plan`. They're semantically equivalent (read-only execution) so this collapse is intentional. `mode == plan` always wins regardless of permission (planning is the stronger constraint).

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

`ChatMode/ChatEffort/ChatPermission` are **relocated in this PR** from `lib/data/session/models/session_settings.dart` to `lib/data/shared/session_settings.dart`. Per [CLAUDE.md](../../../CLAUDE.md): "Cross-cutting types used by two or more domains live in `lib/data/shared/`." These enums are already imported by `features/chat/`, `services/{session,agent,coding_tools}/`, and `data/session/`; adding `data/ai/` as a fourth importer (this PR's plumbing) makes the relocation overdue rather than optional. The file moves verbatim — no API change, just a path change. Every existing import is updated.

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

**Model-aware** — each datasource exposes a function, not a const, so capabilities can shrink based on the *picked* model. Two interfaces gain getters:

```dart
// AIProviderDatasource (CLI providers)
ProviderCapabilities capabilitiesFor(AIModel model);

// TextStreamingDatasource (HTTP providers)
ProviderCapabilities capabilitiesFor(AIModel model);
```

CLI datasources usually return the same capability for any model (the CLI itself accepts every flag for every model it can run). HTTP datasources gate on model id:

- **Anthropic**: effort dropped from `supportedEfforts` when `model.modelId` is on the Opus 4.7+ adaptive-only allowlist (the API 400s on manual `thinking` for those models).
- **OpenAI**: effort included only when `model.modelId` matches the reasoning-model allowlist (`o1*`, `o3*`, `o4-mini*`, `gpt-5*` family). Non-reasoning models render no effort dropdown.
- **Gemini**: effort included on Gemini 2.5+ family ids; on Gemini 3 family the implementation switches the request body to `thinkingLevel` (see `mapGeminiThinkingLevel` below); pre-2.5 ids render no effort.
- **Ollama / Custom**: effort always advertised (single boolean for Ollama; best-effort enum for Custom — endpoint may ignore).

A separate `defaultCapabilities` const is exposed so the chat-input bar can render "what does this provider support in principle" while a session is being created (no model picked yet). Once a model is picked, the notifier switches to `capabilitiesFor(model)`.

Implementation per datasource:

```dart
// CLI providers — capability is model-independent
class ClaudeCliDatasourceProcess implements AIProviderDatasource {
  static const _allEfforts = {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max};
  static const _allPermissions = {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess};

  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
    supportsModelOverride: true, supportsSystemPrompt: true,
    supportedModes: {ChatMode.chat, ChatMode.plan, ChatMode.act},
    supportedEfforts: _allEfforts,
    supportedPermissions: _allPermissions,
  );
}

class CodexCliDatasourceProcess implements AIProviderDatasource {
  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
    supportsModelOverride: true, supportsSystemPrompt: true,
    supportedModes: {ChatMode.chat, ChatMode.act},  // no `plan` equivalent
    supportedEfforts: _allEfforts,
    supportedPermissions: _allPermissions,
  );
}

// HTTP providers — capability is model-aware
class AnthropicRemoteDatasourceDio implements TextStreamingDatasource {
  static const _adaptiveOnly = {'claude-opus-4-7', 'claude-opus-4-7-20251201'};
  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => ProviderCapabilities(
    supportsModelOverride: true, supportsSystemPrompt: true,
    supportedModes: const {ChatMode.chat},
    supportedEfforts: _adaptiveOnly.contains(model.modelId)
        ? const {}
        : const {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
    supportedPermissions: const {},
  );
}

class OpenAIRemoteDatasourceDio implements TextStreamingDatasource {
  static const _reasoningPrefixes = ['o1', 'o3', 'o4-mini', 'gpt-5'];
  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => ProviderCapabilities(
    supportsModelOverride: true, supportsSystemPrompt: true,
    supportedModes: const {ChatMode.chat},
    supportedEfforts: _reasoningPrefixes.any(model.modelId.startsWith)
        ? const {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max}
        : const {},
    supportedPermissions: const {},
  );
}

class GeminiRemoteDatasourceDio implements TextStreamingDatasource {
  // Gemini 2.5 (thinkingBudget int) and Gemini 3 (thinkingLevel enum) both surface effort.
  // Pre-2.5 (e.g. 1.5 family) doesn't.
  static bool _supportsThinking(String modelId) =>
      modelId.startsWith('gemini-2.5') || modelId.startsWith('gemini-3');
  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => ProviderCapabilities(
    supportsModelOverride: true, supportsSystemPrompt: true,
    supportedModes: const {ChatMode.chat},
    supportedEfforts: _supportsThinking(model.modelId)
        ? const {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max}
        : const {},
    supportedPermissions: const {},
  );
}

class OllamaRemoteDatasourceDio implements TextStreamingDatasource {
  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
    supportsModelOverride: true, supportsSystemPrompt: true,
    supportedModes: {ChatMode.chat},
    supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
    supportedPermissions: {},
  );
}

class CustomRemoteDatasourceDio implements TextStreamingDatasource {
  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
    supportsModelOverride: true, supportsSystemPrompt: true,
    supportedModes: {ChatMode.chat, ChatMode.act},  // act runs the agent loop today
    supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
    supportedPermissions: {ChatPermission.readOnly, ChatPermission.askBefore, ChatPermission.fullAccess},
  );
}
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
    ChatPermission.readOnly => 'plan',  // Claude's `plan` is true read-only enforcement
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

/// Gemini 2.5 — integer thinkingBudget token allowance. `-1` = dynamic.
int mapGeminiThinkingBudget(ChatEffort e) => switch (e) {
  ChatEffort.low => 2048,
  ChatEffort.medium => 8192,
  ChatEffort.high => 16384,
  ChatEffort.max => -1,  // dynamic = "use as much as you need"
};

/// Gemini 3 — enum thinkingLevel.
String mapGeminiThinkingLevel(ChatEffort e) => switch (e) {
  ChatEffort.low => 'low',
  ChatEffort.medium => 'medium',
  ChatEffort.high => 'high',
  ChatEffort.max => 'high',  // Gemini 3 caps at "high"; map max → high
};

/// True when the Gemini model id is on the v3 family (uses `thinkingLevel`
/// instead of `thinkingBudget`).
bool isGemini3(String modelId) => modelId.startsWith('gemini-3');

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
| Effort `low/medium/high/max` | ✓ | ✓ (max→xhigh) | ✓ on Sonnet/Opus 4.x; **hidden on Opus 4.7+** | ✓ (max→xhigh) **only on o1/o3/o4-mini/gpt-5 family** | ✓ on Gemini 2.5 (token budget) and Gemini 3 (`thinkingLevel`); hidden on 1.5 | ✓ (any → `think:true`) | ✓ (best-effort `reasoning_effort`) |
| Permission `readOnly` | ✓ (`--permission-mode plan`) | ✓ (`readOnly` sandbox) | — | — | — | — | ✓ (agent loop) |
| Permission `askBefore` | ✓ (`--permission-mode default`) | ✓ (`workspaceWrite` + `on-request`) | — | — | — | — | ✓ (agent loop) |
| Permission `fullAccess` | ✓ (`bypassPermissions`) | ✓ (`dangerFullAccess` + `never`) | — | — | — | — | ✓ (agent loop) |

**Model-aware columns** (Anthropic / OpenAI / Gemini): the matrix shows the *most-permissive* row per provider. Whether the dropdown actually renders depends on `capabilitiesFor(model)` for the user's currently-picked model — for example, an OpenAI session on `gpt-4o` shows no effort dropdown at all; switching to `gpt-5` makes it appear.

## Population — what flows where

### 1. `ChatInputBar` reads capabilities (model-aware)

New notifier `lib/features/chat/notifiers/chat_input_bar_options_notifier.dart`:

```dart
@riverpod
ProviderCapabilities? chatInputBarOptions(Ref ref, String sessionId) {
  final session = ref.watch(activeSessionProvider(sessionId));
  if (session == null) return null;
  final model = AIModels.byId(session.modelId);
  if (model == null) return null;

  // CLI providers → AIProviderDatasource
  final cliDs = ref.watch(aIProviderServiceProvider).getProvider(session.providerId);
  if (cliDs != null) return cliDs.capabilitiesFor(model);

  // HTTP providers → TextStreamingDatasource lookup by AIProvider enum
  final httpDs = ref.watch(textStreamingDatasourceForProvider(model.provider));
  return httpDs?.capabilitiesFor(model);
}
```

Widget gates each dropdown:
- `null` → entire options strip rendered disabled with tooltip "Provider not detected"
- non-null → render only options where `caps.supportedX` is non-empty / true; filter dropdown items to the supported subset

Switching the model mid-session (already a supported flow via `patchSessionSettings`) re-runs the notifier and the strip re-renders with the new model's capabilities.

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
Map<String, dynamic>? thinkingConfig() {
  if (settings?.effort == null) return null;
  if (isGemini3(model.modelId)) {
    return {'thinkingLevel': mapGeminiThinkingLevel(settings!.effort!)};
  }
  return {'thinkingBudget': mapGeminiThinkingBudget(settings!.effort!)};
}

final body = <String, dynamic>{
  ...,
  if (thinkingConfig() != null) 'generationConfig': {'thinkingConfig': thinkingConfig()},
};
```

Branches on `isGemini3(modelId)` so v2.5 gets the integer budget and v3 gets the enum level. Pre-2.5 models render no effort dropdown (per `capabilitiesFor`) so this code path isn't reached.

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

### Moved (verbatim — only paths and imports change)

| From → To |
|---|
| `lib/data/session/models/session_settings.dart` → `lib/data/shared/session_settings.dart` |

Importers updated (15 files): `lib/features/chat/notifiers/chat_notifier.dart`, `session_settings_actions.dart`, `lib/features/chat/widgets/chat_input_bar.dart`, `work_log_section.dart`, `lib/services/session/session_service.dart`, `lib/services/agent/agent_service.dart`, `lib/services/agent/agent_exceptions.dart`, `lib/services/coding_tools/tool_registry.dart`, plus matching test files (`session_service_test.dart`, `agent_service_test.dart`, `tool_registry_test.dart`, `chat_notifier_test.dart`, `chat_notifier_cancel_test.dart`).

### Modified

| Path | Change |
|---|---|
| `lib/data/ai/datasource/ai_provider_datasource.dart` | Add `capabilitiesFor(AIModel)` getter; add `settings` param to `sendAndStream` |
| `lib/data/ai/datasource/text_streaming_datasource.dart` | Add `capabilitiesFor(AIModel)` getter; add `settings` param to `streamMessage` |
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
| OpenAI non-reasoning model rejects `reasoning_effort` | Capability matrix is model-aware — `capabilitiesFor(model)` returns empty `supportedEfforts` for non-reasoning models, so the dropdown is hidden. Defence-in-depth: the request-body builder also gates via the same allowlist. |
| Anthropic adaptive-only models (Opus 4.7+) 400 on manual `thinking` | Same — `capabilitiesFor` returns empty `supportedEfforts` for those ids; dropdown hidden. Mapper returns null as a second guard. |
| New model lands without an entry in the reasoning/adaptive allowlists | Default capability is "effort not supported" → dropdown hidden until the allowlist is updated. Fail-closed is the safer default. |
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
- Auto-detecting model lists per provider.
