# Providers Screen Redesign — Spec

## Goal

Replace the current `ProvidersScreen` (mixed expandable-card + inline-row styles, no Save button) with a unified expandable-card design where every provider — API keys, Ollama, Custom Endpoint — uses the same layout and the same Test / Save interaction model.

---

## Layout

All providers use a single card pattern:

**Collapsed:**
```
● Provider Name     status text     ▼
```

**Expanded:**
```
● Provider Name     status text     ▲
  [ field(s)                        ]
  [Test]  [Save]  [✕]
```

Sections (separated by a `SectionLabel` + `Divider`):
1. **API Keys** — OpenAI, Anthropic, Gemini (one card each, single field)
2. **Ollama (Local)** — single URL field
3. **Custom Endpoint (OpenAI-compatible)** — two fields: Base URL + API Key (optional)

No global Save button. No mixed row/card styles.

---

## Dot States

The dot reflects **persistence state only** — never the live test result.

| Dot | Meaning |
|---|---|
| Gray | Nothing saved for this provider |
| Yellow | Field content differs from what is stored (unsaved changes) |
| Dim green (50% opacity) | Saved but unverified — user chose "Save anyway" after a failed connection test |
| Full green | Saved and verified — last Save passed validation |

The dot changes only when Save succeeds or when the field is cleared.

---

## Test Button

- Runs the appropriate validation (API key validity or connectivity check to `/models`)
- Shows a toast: success or error
- **Does not save anything**
- **Does not change the dot**
- After a successful test the button label updates to `✓ Valid` (API keys) or `✓ Connected` (URL-based)
- The label resets to `Test` if the field text changes or the card is collapsed and re-expanded

---

## Save Button

Save always validates first, then conditionally persists:

### API Key providers (OpenAI, Anthropic, Gemini)

1. Run key validation
2. **Success** → write key to storage → dot goes full green → toast: "Saved"
3. **Failure** → do not save → toast: "Invalid key" (no "Save anyway" — an invalid key is always invalid)

### URL-only provider (Ollama)

1. Run connectivity check
2. **Success** → write URL to storage → dot goes full green → toast: "Saved"
3. **Failure** → toast: "Cannot connect" with inline **"Save anyway"** action
   - "Save anyway" → write URL to storage → dot goes dim green → toast: "Saved (unverified)"

### URL + API Key provider (Custom Endpoint)

1. Run connectivity check using both URL and API key together
2. **Success** → write URL and API key atomically → dot goes full green → toast: "Saved"
3. **Failure** → toast: "Cannot connect" with inline **"Save anyway"** action
   - "Save anyway" → write both fields atomically → dot goes dim green → toast: "Saved (unverified)"

---

## Clear Button (✕)

- Clears the field(s) and deletes from storage
- Custom Endpoint: clears both URL and API key, labeled `✕ Clear all`
- Dot goes gray immediately
- No validation step

---

## Unsaved Changes Detection

The yellow dot appears when the controller text differs from the value loaded from storage. Each provider card stores a `_savedValue` string (set when the screen loads and updated on every successful Save or Clear). The `_onTextChanged` listener compares the controller text against `_savedValue` to determine whether to show yellow.

---

## Custom Endpoint — Two-Field Layout

```
[ Base URL field               ] [Test] [Save] [✕ Clear all]
[ API Key (optional)           ]
```

One Test covers both fields. One Save writes both atomically. One ✕ clears both. The API Key row has no independent Test or Save button — it participates in the shared Custom Endpoint action set.

---

## Provider Card State Machine

```
empty (gray)
  → user types → unsaved (yellow)
    → Test clicked → toast shown, dot unchanged
    → Save clicked, validation passes → saved+verified (full green)
    → Save clicked, validation fails (URL providers) → toast + "Save anyway"
      → "Save anyway" tapped → saved+unverified (dim green)
  
saved+verified (full green)
  → user edits field → unsaved (yellow)  [via didUpdateWidget / listener]
  → ✕ tapped → empty (gray)

saved+unverified (dim green)
  → user edits field → unsaved (yellow)
  → Save clicked, validation passes → saved+verified (full green)
  → ✕ tapped → empty (gray)
```

---

## Files to Change

| File | Change |
|---|---|
| `lib/features/settings/providers_screen.dart` | Full redesign — unified card component, new dot/status system, Save-validates-then-persists flow |

All notifier methods (`saveKey`, `saveOllamaUrl`, `clearOllamaUrl`, `saveCustomEndpoint`, `clearCustomEndpoint`, `clearCustomApiKey`, `testCustomEndpoint`) are already implemented and available.

---

## Out of Scope

- No changes to `SettingsActions`, `ApiKeysNotifier`, or the storage chain — all persistence methods already exist
- No changes to `IntegrationsScreen`
- No new Riverpod providers
