# Dynamic Model Selection — Spec

## Goal

Fix the bug where custom and Ollama providers always send a hardcoded `"model": "custom"` / static model ID to the inference server. After this change, the chat model picker fetches real model IDs from configured local servers (Custom and Ollama) and surfaces them alongside the static cloud models (Anthropic, OpenAI, Gemini) in a grouped picker.

---

## Scope

**In scope:**
- `AvailableModelsNotifier` — new notifier that merges static + fetched models
- Chat model picker (`_showModelPicker`) — grouped by provider, loading/offline states
- Ollama card — no UI change needed (model selection moves to chat picker)
- Custom endpoint card — no UI change needed (model selection moves to chat picker)
- `AIModels.defaults` — remove `customModel` sentinel

**Out of scope:**
- Dynamic fetching for OpenAI, Anthropic, Gemini (kept static)
- Retry/cancel for failed/hung streams (separate spec)
- Persisting the selected model across app restarts (session-level persistence via `SessionSettings` already covers per-session model memory)

---

## Architecture

```
AvailableModelsNotifier.build()
  → ref.watch(aiRepositoryProvider)         // auto-rebuilds when endpoint saved
  → aiRepo.fetchAvailableModels(ollama)     // hits /api/tags (if URL configured)
  → aiRepo.fetchAvailableModels(custom)     // hits /models  (if endpoint configured)
  → merge with static AIModels list         // Anthropic + OpenAI + Gemini always included
  → AsyncData<List<AIModel>>

chat_input_bar._showModelPicker()
  → ref.watch(availableModelsProvider)
  → renders grouped sections by AIProvider
  → manual refresh icon per dynamic section
```

`AvailableModelsNotifier` watches `aiRepositoryProvider`. Since `ProvidersActions` already invalidates `aiRepositoryProvider` after every endpoint save, the models list rebuilds automatically — no extra invalidation needed anywhere.

---

## Fetch Lifecycle

| Event | Result |
|---|---|
| First picker open (notifier not yet built) | Lazy build — fetches once, cached for session |
| Endpoint saved via `ProvidersActions` | `aiRepositoryProvider` invalidated → `AvailableModelsNotifier` auto-rebuilds |
| Endpoint cleared | Same — notifier rebuilds, that provider's section disappears |
| Manual refresh icon tapped in picker | `ref.invalidateSelf()` on notifier → re-fetches |
| App restart | Notifier rebuilds from scratch on first access |

---

## Data Model Changes

### `AIModels` (`lib/data/shared/ai_model.dart`)

- Remove `customModel` from `defaults`. Static list becomes 5 models: `gpt4o`, `gpt4oMini`, `claude35Sonnet`, `claude3Haiku`, `geminiFlash`.
- `AIModels.fromId()` unchanged — still searches static defaults (used by session settings lookups).

### No new storage keys

The model list is always re-fetched. The selected model ID is persisted per-session via the existing `SessionSettings` mechanism.

---

## New Component: `AvailableModelsNotifier`

**File:** `lib/features/chat/notifiers/available_models_notifier.dart`

```
class AvailableModelsNotifier extends _$AvailableModelsNotifier
  AsyncNotifier<List<AIModel>>, keepAlive: true

build():
  1. await ref.watch(aiRepositoryProvider.future) — gets repo + establishes reactive dependency
  2. Read ollamaUrl + customEndpoint via providersServiceProvider (respects arch layering)
  3. Run fetches concurrently (Future.wait), catching each independently
  4. Merge: static defaults + ollama models (if configured) + custom models (if configured)
  5. Return merged list

refresh():
  ref.invalidateSelf()
```

Fetch failures are **per-provider and non-fatal**. A failing provider contributes an empty list for its section; the notifier itself never enters `AsyncError`.

---

## Chat Model Picker Changes (`chat_input_bar.dart`)

`_showModelPicker()` currently reads `AIModels.defaults`. New behaviour:

1. Read `ref.watch(availableModelsProvider)` — `AsyncValue<List<AIModel>>`
2. Group models by `AIProvider` into sections
3. Render each section with a muted uppercase header item (non-selectable) + model items below
4. **While `AsyncLoading`:** show a muted italic "Loading…" item under Ollama / Custom sections
5. **On fetch error for a provider:** show "⚠ Offline" item — still selectable so the user can attempt to send on last-known model
6. **Manual refresh:** small refresh icon next to Ollama and Custom section headers; calls `refresh()` on the notifier

Section order: Anthropic → OpenAI → Gemini → Ollama (if configured) → Custom (if configured).

---

## Error Handling

- Fetch failures caught per-provider inside `build()`. Logged with `dLog`. No `AsyncError` propagation.
- If the selected model's provider is offline, the model remains selectable. Send failure is handled by the existing `NetworkException` → chat error snackbar path.
- If both Ollama URL and custom endpoint are empty, `AvailableModelsNotifier` returns only the static list — no network calls made.

---

## Testing

- **Unit — `AvailableModelsNotifier`:** mock `aiRepositoryProvider`; assert merged list = static + dynamic, correct grouping
- **Unit — failure isolation:** custom fetch throws → Ollama and static sections unaffected; notifier still returns `AsyncData`
- **Widget — `_showModelPicker`:** section headers per provider; loading row during `AsyncLoading`; offline row during per-provider error
- **Existing `ProvidersActions` tests:** no changes needed
