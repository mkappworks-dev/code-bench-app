# Onboarding: Optional API Key Entry + In-App Key Management

**Date:** 2026-04-07
**Status:** Approved

## Summary

Allow users to enter API keys during onboarding or skip straight to the app. Once in the app, they can add, change, or delete keys from the Settings screen at any time. The current hack of writing a fake `api_key_ollama = 'local'` placeholder to pass the router guard is removed and replaced with a proper `onboarding_completed` flag.

---

## 1. Data Layer

### New: `OnboardingPreferences`

A thin service wrapping `SharedPreferences` that tracks whether the user has seen and dismissed onboarding (either by saving keys or explicitly skipping).

**File:** `lib/data/datasources/local/onboarding_preferences.dart`

```dart
@Riverpod(keepAlive: true)
OnboardingPreferences onboardingPreferences(Ref ref) => OnboardingPreferences();

class OnboardingPreferences {
  static const _key = 'onboarding_completed';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
```

`shared_preferences: ^2.3.3` is already in `pubspec.yaml` — no new dependency required.

### Router guard change

`lib/router/app_router.dart` — replace the `hasAnyApiKey()` guard with `onboardingPreferences.isCompleted()`:

```dart
// Before
final hasKey = await storage.hasAnyApiKey();
if (!hasKey && state.matchedLocation != '/onboarding') return '/onboarding';

// After
final done = await ref.read(onboardingPreferencesProvider).isCompleted();
if (!done && state.matchedLocation != '/onboarding') return '/onboarding';
```

`SecureStorageSource.hasAnyApiKey()` is left intact but is no longer called by the router guard.

---

## 2. Onboarding Screen

**File:** `lib/features/onboarding/onboarding_screen.dart` — full rewrite of the screen body.

### Layout — Split panel

The screen is a full-window `Row` with two panels:

- **Left panel — 38% width**, near-black gradient (`#111111 → #050505`, angle 170°), separated by a `#2a2a2a` border.
  - Top: icon + title on the same row (`Row`, `crossAxisAlignment.center`), tagline (`#9d9d9d`) directly below.
  - Middle: three frosted feature cards (`rgba(255,255,255,0.04)` background, `rgba(255,255,255,0.07)` border, 8px radius) — Multi-provider AI, Smart Code Editor, GitHub Integration. Card title: `#d4d4d4` 12px bold. Card subtitle: `#7a7a7a` 11px.
  - Bottom: keychain note (`#666`, 11px) pinned to the bottom of the panel.
- **Right panel — remaining width** (`#141414` background), vertically centred content, 40px horizontal padding.

### Expandable provider list (right panel)

- Maintains a `List<AIProvider> _addedProviders` in state, initialised to `[AIProvider.anthropic]`.
- Renders one `_ProviderRow` widget per added provider — single horizontal line: provider label (78px, 9px, `#9d9d9d`) + text field + show/hide toggle + Test button + `×` remove button.
- `×` is disabled (colour `#2e2e2e`) when only one provider remains.
- **"Add another provider"** text button (`+` icon, `accent` blue) is shown while `_addedProviders.length < AIProvider.values.length`. Tapping opens a `showDialog` picker (`panelBackground`) listing only providers not yet added.
- Supported providers: OpenAI, Anthropic, Gemini, Ollama (URL field, no obscure/test), Custom endpoint (URL field).

### Bottom actions (right panel)

| Button | Style | Behaviour |
|---|---|---|
| Skip | Outlined secondary (`flex: 1`) | `markCompleted()` → `context.go('/dashboard')` |
| Save & Continue | Filled primary (`flex: 2`) | Saves all non-empty fields to `SecureStorageSource`, calls `markCompleted()`, navigates to `/dashboard`. Empty fields are ignored — **no minimum key requirement**. |

### Removed

- The `api_key_ollama = 'local'` placeholder hack in the old Skip handler.
- The "Please enter at least one API key" SnackBar guard.
- The old centered single-column layout.

---

## 3. Settings Screen — Explicit Delete

**File:** `lib/features/settings/settings_screen.dart`

The existing screen already handles add (fill field + Save) and change (edit field + Save). One gap: deleting a key requires clearing a field and saving, which is not discoverable.

**Change:** Add a small `×` `IconButton` next to each API key field. Tapping it:
1. Clears the `TextEditingController` for that provider.
2. Immediately calls `storage.deleteApiKey(provider.name)`.
3. Calls `ref.invalidate(aiServiceProvider)` to refresh the active AI service.
4. Shows a brief SnackBar: `"<Provider> key removed"`.

No changes needed to the Ollama URL or Custom Endpoint fields — those are not sensitive credentials and clearing + saving is sufficient.

---

## 4. Implementation Plan Note

The implementation plan should create a git worktree and branch named after this spec:
`feature/onboarding-api-keys`

---

## Out of Scope

- Re-showing onboarding after all keys are deleted (the `onboarding_completed` flag is permanent).
- Per-provider onboarding wizard steps.
- GitHub token management (separate flow, not touched here).
