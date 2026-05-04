# Provider UI Redesign — Design Spec
_2026-05-04_

## Goal

Unify the visual language for provider configuration across two surfaces — the **Settings › Providers screen** and the **Onboarding › AI Providers step** — while fixing specific interaction and layout issues in both.

## Scope

- `lib/features/providers/` — all provider card widgets, `ProvidersScreen`
- `lib/features/onboarding/widgets/api_keys_step.dart`
- No data layer changes. No notifier logic changes (except one body-copy fix in `_ClaudeCliBody`).

---

## 1. Unified Card Chrome

Every provider card in both settings and onboarding shares one visual shell. There are no longer two different implementations (`SelectableTransportCard` / `OllamaCard` / bespoke onboarding rows) — all surfaces use the same chrome.

### Colour tokens

| Layer | Token | Hex |
|---|---|---|
| Card border | `deepBorder` | `#222222` |
| Header background | `inputSurface` | `#1A1A1A` |
| Header/body divider | `border` | `#2A2A2A` |
| Body background | `sidebarBackground` | `#111111` |
| Input field background | `inputSurface` | `#1A1A1A` |
| Input field border | `border` | `#2A2A2A` |

Body is `sidebarBackground` (`#111111`) — darker than the screen background (`#141414`). This makes the card feel self-contained when expanded and gives the input field (`#1A1A1A`) clear lift.

### Geometry

- Border-radius: `4px` (unified — was `4px` on `SelectableTransportCard`, `8px` on `OllamaCard`)
- Header padding: `7px 10px`
- Body padding: `9px 10px 10px` (transport cards indent left `27px` to align under title past radio dot)
- Gap between stacked transport cards: `4px`

### Header row anatomy

```
[radio dot OR status dot]  [title]  [flex spacer]  [status badge]  [chevron]
```

- **Radio dot** (`10×10px`, `1.5px` border): present only on transport-selectable cards (Anthropic, OpenAI). Teal filled when selected, `mutedFg` border when not selected.
- **Status dot** (`7×7px`): present on single-transport cards (Ollama, Custom). Coloured by `DotStatus`.
- **Chevron**: `9px`, `mutedFg`. Rotates `90°` when expanded.
- **Status badge**: `CardStatusBadge` — dot + label. Tones: `success`, `warning`, `error`, `muted`, `savedUnverified`.

### Hover

- Single-transport cards (Ollama, Custom) + transport cards when **not selectable**: `surfaceHoverOverlay` (`#FFFFFF08`) over header bg.
- Transport cards when **selectable and not selected**: `accentTintMid × 0.3` (`rgba(78,201,176, 0.042)`) over header bg.
- No hover tint when selected (card is already chosen).

### Expand / collapse

- All cards collapsed by default, including unconfigured API Key cards.
- Only exception: `brokenCliActive` state force-expands the CLI transport card.
- Chevron rotates on open; body slides in below the header divider.

---

## 2. Settings — Provider Screen Changes

### 2a. Remove accent border on selected transport card

`SelectableTransportCard` currently applies `c.accent.withValues(alpha: 0.5)` as the border colour when selected. **Remove this.** All cards use `deepBorder` (`#222222`) at all times. Selection is communicated solely by the filled radio dot.

File: `lib/features/providers/widgets/selectable_transport_card.dart`
- Delete `borderColor` logic that references `c.accent` for the selected state.
- Use `widget.errorState ? c.error.withValues(alpha: 0.4) : c.deepBorder` for the border.

### 2b. API Key card collapsed by default

`AnthropicProviderCard`, `OpenAIProviderCard`, `GeminiProviderCard` currently pass `initiallyExpanded: _dotStatus != DotStatus.savedVerified && _dotStatus != DotStatus.savedUnverified` to the API Key `SelectableTransportCard`. Change to `initiallyExpanded: false` for all three.

The `brokenCliActive` case already passes `initiallyExpanded: brokenCliActive` — keep that unchanged.

### 2c. Unified card chrome for Ollama and Custom Endpoint

`OllamaCard` and `CustomEndpointCard` currently use a bespoke `Container` + `InkWell` shell with `border-radius: 8px` and `inputSurface` background for the whole card. Replace with the unified chrome:

- Outer container: `border: deepBorder`, `border-radius: 4px`, no background.
- Header: `background: inputSurface`, same padding as transport cards.
- Body: `background: sidebarBackground` (`#111111`).
- Remove `InkWell` — use `MouseRegion` + `GestureDetector` pattern matching `SelectableTransportCard`.

No status dot changes — these cards already have the correct `DotStatus` logic.

### 2d. Broken-active body — add install command

In `_ClaudeCliBody.build()`, the `if (broken)` branch currently shows only error text + buttons. Add the `InstallCommand` widget between the error text and the buttons.

`installCommand` is already passed into `_ClaudeCliBody` (it's used in the `!available` branch). No new parameters needed.

**Before (broken branch):**
```dart
Row(children: [
  Expanded(child: Text('⚠ $binaryName no longer detected', ...)),
  _CardButton(label: 'Switch to API Key', ...),
  _CardButton(label: 'Recheck', ...),
])
```

**After:**
```dart
Column(children: [
  Text('⚠ $binaryName no longer detected', ...),
  const SizedBox(height: 6),
  Row(children: [
    Expanded(child: InstallCommand(command: installCommand)),
    _CardButton(label: 'Switch to API Key', ...),
    _CardButton(label: 'Recheck', ...),
  ]),
])
```

### 2e. CLI not installed — only header dimmed, body at full opacity

`SelectableTransportCard` currently wraps the entire `Column(header + body)` in `Opacity(opacity: widget.disabled ? 0.6 : 1.0)`. Split this:

- Header row: wrapped in `Opacity(opacity: widget.disabled ? 0.6 : 1.0)`.
- Body: always full opacity. The install command pill inside can be dimmed separately if desired, but the action buttons (Recheck) must never be dimmed.

File: `lib/features/providers/widgets/selectable_transport_card.dart`

---

## 3. Onboarding — Provider Step Redesign

Replace the current flat `_ProviderRow` list in `ApiKeysStep` with collapsible provider cards using the unified chrome.

### 3a. Card structure

Each provider is a collapsible card:
- **Header**: provider display name + status badge + optional ✕ remove button + chevron.
- **Body** (`sidebarBackground`): input field(s) + action buttons.
- No radio dot — onboarding is API-key only (no transport selection).

The ✕ remove button is hidden when only one provider card remains (same rule as current `canRemove` logic).

### 3b. Default state

- Anthropic pre-added, **collapsed** by default (not expanded).
- Body expands on header tap.
- When a key is saved the badge shows `Valid & saved` (success tone); collapsed state communicates progress without needing the field visible.

### 3c. CLI detection (option C)

On load, `ApiKeysStep` calls `ref.watch(aiProviderStatusProvider)` to probe for CLI tools. If `claude-cli` is detected as `ProviderAvailable`:

- The Anthropic card auto-expands.
- A teal banner is shown at the top of the body:
  ```
  [● dot]  Claude Code CLI found · no API key needed   [Use CLI]
  ```
  - Banner bg: `rgba(78,201,176, 0.06)`, border: `rgba(78,201,176, 0.20)`.
  - "Use CLI" button: same style as `InlineTestButton` at 20px height.
- The API key field is still shown below the banner as an alternative.
- Tapping "Use CLI" calls `providersActionsProvider.notifier.saveAnthropicTransport('cli')` and advances to the next step.

### 3d. Scrollable list

The provider list is wrapped in `Expanded` + `ListView`. When cards overflow the panel the list scrolls independently of the footer action row (Skip / Save & Continue).

### 3e. Add another provider

The "+ Add another provider" `TextButton.icon` uses `showInstantMenuAnchoredTo` (same as current). The popup lists only providers not yet added. When all 5 providers are added the button is hidden.

### 3f. Action buttons

- **Save & Continue**: enabled as soon as at least one provider has a non-empty saved key (or CLI selected). Disabled (opacity 0.4) otherwise.
- **Skip for now**: always enabled.

---

## 4. Shared Helpers — No Changes

The following are **unchanged**:

- `InlineTestButton`, `InlineSaveButton` — same teal-tinted style.
- `InlineClearButton` — stays red (`c.error`). Destructive intent is intentional.
- `_CardButton` (Recheck / Switch to API Key) — 26px, `border-radius: 5px`, teal tinted.
- `CardStatusBadge` — unchanged.
- `DotStatus` enum — unchanged.
- All notifier logic (`ProvidersActions`, `ApiKeysNotifier`, `AiProviderStatusNotifier`) — unchanged.

---

## 5. Files Changed

| File | Change |
|---|---|
| `selectable_transport_card.dart` | Remove accent border on selected; split Opacity to header-only |
| `anthropic_provider_card.dart` | `initiallyExpanded: false` on API Key card; add InstallCommand to broken branch |
| `openai_provider_card.dart` | `initiallyExpanded: false` on API Key card |
| `gemini_provider_card.dart` | `initiallyExpanded: false` |
| `ollama_card.dart` | Replace shell with unified chrome (border-radius 4px, sidebarBg body) |
| `custom_endpoint_card.dart` | Replace shell with unified chrome |
| `api_keys_step.dart` | Full redesign — collapsible cards, CLI detection banner, scrollable list |

---

## 6. Out of Scope

- No provider logos / icons.
- No transport selection in onboarding (remains API-key only, CLI via banner only).
- No new providers added.
- No changes to `ProvidersScreen` layout (section labels, dividers, scroll behaviour).
- No data migration (app not yet released).
