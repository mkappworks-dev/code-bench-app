# Tool-Call Provider/Model Badges — Design Spec

> **Date:** 2026-05-06
> **Status:** Design (pre-plan)
> **Worktree:** `fix/2026-05-06-tool-call-provider-model-badges`

## Goal

Replace the hardcoded `'via Claude Code'` badge on tool-call rows ([tool_call_row.dart:94](../../../lib/features/chat/widgets/tool_call_row.dart)) with two accurate badges — one for the **transport/provider** that produced the tool call, one for the **model** used. Make the gating accurate across every provider (Anthropic API, custom HTTP, Claude Code CLI, Codex CLI), and persist enough attribution per message that history remains correct after a mid-session model switch.

The hardcoded label was a v1 stand-in dating from when Claude Code was the only CLI transport. Codex CLI now ships, and the Provider screen already exposes both transports as first-class. The badge needs to reflect reality.

## Background

### Today's behaviour

| Concern | Today |
|---|---|
| Badge text | Hardcoded literal `'via Claude Code'` |
| Gating | Shown only when `event.source == ToolEventSource.cliTransport` (any CLI, mislabelled) |
| Per-message attribution | None — `ChatMessages` table has no `providerId` / `modelId` columns; the chat-session row is the only source of truth |
| Mid-session model switch | [session_settings_actions.dart:64](../../../lib/features/chat/notifiers/session_settings_actions.dart) calls `patchSessionSettings(modelId: ...)` — historical messages silently re-attribute to the new model |
| Mid-session **provider** switch | Not supported by the data model — `patchSessionSettings` accepts `modelId` but not `providerId`. `providerId` is set once at session creation and never updated. |

### What we have to work with

- [`ChatSession`](../../../lib/data/session/models/chat_session.dart): `providerId` + `modelId` (session snapshot, mutable for `modelId` only)
- [`ChatMessage`](../../../lib/data/shared/chat_message.dart) — freezed, persisted via [`session_service.persistMessage`](../../../lib/services/session/session_service.dart): `id`, `sessionId`, `role`, `content`, `codeBlocks`, `toolEvents`, `timestamp`, `isStreaming`, plus a few status flags. **No provider/model fields.**
- [`AIProviderDatasource`](../../../lib/data/ai/datasource/ai_provider_datasource.dart) registry — every datasource exposes `String get id` and `String get displayName` (e.g. `Codex` → `'Codex'`).
- Six message-persistence sites in [`session_service.dart`](../../../lib/services/session/session_service.dart): user-message insert, agent-loop final, plain-text final, provider-stream mid-stream-failure, provider-stream interrupted, provider-stream final.

## Architecture

Strictly one-directional per [CLAUDE.md](../../../CLAUDE.md):

```
Widgets ─→ Notifiers ─→ Services ─→ Datasources ─→ External (DB / CLI / API)
   │           │            │            │
   │           │            │            └─ Drift table now has providerId, modelId
   │           │            │               TEXT columns (both nullable)
   │           │            │
   │           │            └─ SessionService captures providerId/modelId at every
   │           │               assistant-message persistence site
   │           │
   │           └─ ChatMessage now carries providerId / modelId; ChatNotifier
   │              streams pass them through unchanged
   │
   └─ MessageBubble reads message.providerId/modelId, passes to ToolCallRow
      ToolCallRow renders 0/1/2 accent badges (graceful when fields are null)
```

No widget imports a service or datasource. No service imports a notifier-layer provider. The `ToolEventSource` gate is dropped entirely — gating is now "do we know the provider/model", which is decided at write-time, not at render-time.

## Data model changes

### Drift table

Add two nullable columns to [`ChatMessages`](../../../lib/data/_core/app_database.dart):

```dart
class ChatMessages extends Table {
  // ...existing columns...
  TextColumn get providerId => text().nullable()();   // e.g. 'codex', 'claude-cli', 'anthropic'
  TextColumn get modelId => text().nullable()();      // e.g. 'gpt-5', 'claude-sonnet-4-5'
}
```

**Schema bump.** Per [project_release_status](memory) the app is unreleased, so the migration is `onUpgrade` add-column, no backfill. Existing dev databases get NULL for legacy rows — the widget gracefully hides null badges.

Both columns are nullable by intent:

- **User messages**: NULL on both. The user didn't pick a provider; the *response* will.
- **Assistant messages from CLI transports where we don't know the model** (e.g. Codex picks its own model server-side and we haven't captured it): provider non-null, model NULL.
- **Legacy rows** written before this change: both NULL.

### ChatMessage freezed model

Add the same two fields:

```dart
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    // ...existing fields...
    String? providerId,
    String? modelId,
  }) = _ChatMessage;
}
```

`fromJson` / `toJson` are auto-generated. `toolEventsJson` serialisation already round-trips through `ChatMessage.toJson`, so no datasource changes are needed beyond reading/writing the new columns.

## Population — per-persistence-site

Six sites in `session_service.dart` persist messages today. The mapping:

| Line | Path | Role | Source of `providerId` | Source of `modelId` |
|---|---|---|---|---|
| `123` | user-message insert | `user` | NULL | NULL |
| `186` | agent loop final | `assistant` | derived from `model.provider` (enum → string) | `model.modelId` |
| `225` | plain-text final | `assistant` | derived from `model.provider` | `model.modelId` |
| `311` | provider-stream mid-stream-failure | `assistant` | `ds.id` | from `ProviderInit` event payload (see below) |
| `326` | provider-stream interrupted | `interrupted` | `ds.id` | as captured during stream |
| `332` | provider-stream final | `assistant` | `ds.id` | as captured during stream |

**CLI model capture.** The `_streamProvider` flow ([session_service.dart:241–334](../../../lib/services/session/session_service.dart)) consumes a `ProviderInit` event today (line 269) but only logs it. We extend `ProviderInit` to carry the model identifier when the CLI exposes one (Codex's `initialize` response includes `userAgent`; Claude Code emits a `model` field in its session-init JSON). The capture is best-effort — if a CLI version doesn't surface it, `modelId` stays NULL and the model badge is hidden for that turn.

**Helper.** A single private helper in `SessionService` resolves `(model, providerId?) → (providerId, modelId)` so the six call sites stay terse:

```dart
({String? providerId, String? modelId}) _attribution({
  required AIModel? model,
  String? cliProviderId,
  String? cliModelId,
}) {
  if (cliProviderId != null) return (providerId: cliProviderId, modelId: cliModelId);
  if (model != null) return (providerId: model.provider.name, modelId: model.modelId);
  return (providerId: null, modelId: null);
}
```

## Widget changes

### `ToolCallRow`

- Drop the `event.source == cliTransport` gate.
- Drop the hardcoded `'via Claude Code'` literal.
- Accept two new optional widget params: `String? providerLabel`, `String? modelLabel`.
- Render up to two badges in the same accent style as today, rendered only when their corresponding label is non-null:

```
[icon] tool_name [Codex CLI] [gpt-5]  arg…  ✓ 142ms
```

### `MessageBubble`

- Resolve `providerLabel` from `message.providerId` via a small `providerLabelFor(providerId)` helper that wraps the registry's `displayName` and appends the transport word per the requirement for explicit labels:
  - `claude-cli` → `Claude Code CLI`
  - `codex` → `Codex CLI`
  - `anthropic` → `Anthropic API`
  - `openai` → `OpenAI API`
  - unknown id → raw id (last-resort fallback; no crash)
- Pass `modelLabel = message.modelId` through unchanged (raw id is fine; `gpt-5`, `claude-sonnet-4-5` read well).

The helper lives at [`lib/features/chat/widgets/provider_label.dart`](../../../lib/features/chat/widgets/provider_label.dart). Pure function; no widget tree access required.

**ID mapping note.** `model.provider.name` returns the Dart enum value (`'anthropic'`, `'openai'`, `'gemini'`, `'ollama'`, `'custom'`). CLI datasources expose their own ids via `ds.id` (`'codex'`, `'claude-cli'`). Both feed into `providerLabelFor` which is the single point that translates id → display string.

## Display contract

| `providerId` | `modelId` | Rendered badges |
|---|---|---|
| non-null | non-null | `[Codex CLI]` `[gpt-5]` |
| non-null | null | `[Codex CLI]` |
| null | null | (no badges) |
| null | non-null | `[gpt-5]` (degenerate; theoretically unreachable but rendered for safety) |

`agentLoop` vs `cliTransport` source on the event no longer affects visibility — the field stays on `ToolEvent` purely for the existing telemetry/serialisation contract.

## Files

### New (3)

| Path | Responsibility |
|---|---|
| `lib/features/chat/widgets/provider_label.dart` | Pure function `providerLabelFor(String?) -> String?` |
| `test/features/chat/widgets/provider_label_test.dart` | Coverage for known ids, fallback, null |
| (migration is in-place in `app_database.dart`; no new file) | — |

### Modified

| Path | Change |
|---|---|
| `lib/data/_core/app_database.dart` | `ChatMessages` table: add nullable `providerId`, `modelId` columns; bump schema version |
| `lib/data/shared/chat_message.dart` | Add `providerId`, `modelId` fields to `ChatMessage` |
| `lib/data/session/datasource/session_datasource_drift.dart` | Read/write the two new columns in `persistMessage` and `loadHistory` |
| `lib/services/session/session_service.dart` | Plumb attribution through every assistant-message persistence site; introduce `_attribution()` helper |
| `lib/data/ai/datasource/ai_provider_datasource.dart` | Extend `ProviderInit` event with optional `modelId` field |
| `lib/data/ai/datasource/codex_cli_datasource_process.dart` | Emit `modelId` on `ProviderInit` from the `initialize` `userAgent` (best-effort) |
| `lib/data/ai/datasource/claude_cli_datasource_process.dart` | Emit `modelId` on `ProviderInit` from the session-init `model` field (best-effort) |
| `lib/features/chat/widgets/message_bubble.dart` | Pass `providerLabel` and `modelLabel` to `ToolCallRow` |
| `lib/features/chat/widgets/tool_call_row.dart` | Replace hardcoded badge with two-badge renderer; accept new params |
| `test/features/chat/widgets/tool_call_row_test.dart` | Update to assert badge rendering against the new contract |

### Deleted

None.

## Testing

| Layer | Test |
|---|---|
| `provider_label_test.dart` | Maps `claude-cli`/`codex`/`anthropic`/`openai` to expected display strings; `null` → `null`; unknown id → raw id |
| `tool_call_row_test.dart` | (a) Both badges render when both labels are non-null. (b) Only provider badge renders when `modelLabel` is null. (c) No badges render when both are null. (d) Hardcoded `'via Claude Code'` string is gone (regression guard). |
| `session_service_test.dart` (existing) | New cases: assistant message persisted via custom-model path carries `providerId='anthropic'` (or whatever the model maps to) and the model id; CLI path persists `ds.id` and the captured CLI model when available. |
| `session_datasource_drift_test.dart` (existing or new) | Round-trip: persist `ChatMessage` with provider/model → reload → fields preserved. NULL round-trip works. |

No e2e UI test — the widget tests cover the visible contract.

## Out of scope

- Per-tool-event attribution (each event carrying its own provider/model). Message-level granularity is sufficient for the badge use case; tool events are always emitted within a single assistant turn so they share the message's attribution.
- Allowing mid-session **provider** changes (currently impossible by design — the `patchSessionSettings` API doesn't expose `providerId`). Out of scope for this fix.
- Backfilling provider/model onto historical messages. Legacy rows render with no badges, which matches reality (we genuinely don't know).
- Any change to how the chat-header pill displays provider/model. The badges are inline, scoped to tool-call rows.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| CLI doesn't surface its model id in the protocol | `modelId` stays NULL, model badge hidden — graceful. The provider badge alone still fixes the original bug. |
| Adding columns breaks dev databases that someone built without migration | App is pre-release; we accept the wipe. Devs can `rm` the local SQLite. |
| Display label drifts from the registry's `displayName` | The widget helper is the single source of truth for badge labels; a test pins the four known mappings. |
| Mid-session model switch produces mixed history (old turns with old model, new turns with new model) | Correct — that's the *point* of per-message storage. Each turn now records the model that produced it. |

## Acceptance

1. The literal string `'via Claude Code'` does not appear in the codebase.
2. A Codex CLI session shows `[Codex CLI]` `[<model>]` (or just `[Codex CLI]` if the CLI didn't disclose its model) on every tool-call row.
3. A Claude Code CLI session shows `[Claude Code CLI]` plus model on every tool-call row.
4. A custom Anthropic-API session shows `[Anthropic API]` plus the configured model on every tool-call row.
5. Switching the model mid-session, then sending another turn, results in the *new* turn's tool calls being labelled with the new model — old turns keep the old label.
6. `flutter analyze` clean. `flutter test` green. `dart format` clean.
