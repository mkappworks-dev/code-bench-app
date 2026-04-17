# Settings, Providers & Integrations — Design Spec

Date: 2026-04-17

## Overview

Six distinct improvements to the Settings area and project sidebar:

1. Bump app version to `0.1.0` and display it in the About section
2. Wire the Sort projects preference into the actual sidebar list order
3. Per-provider inline API key testing (test = validate + save)
4. Redesign Ollama URL and Custom Endpoint rows with inline test/save/clear
5. Add an Integrations settings screen exposing GitHub auth
6. Remove the global Save button from the Providers screen

---

## 1 · Version bump

**pubspec.yaml**: change `version: 1.0.0+1` → `version: 0.1.0+1`.

**General screen — About section**: replace the hardcoded `'Up to Date'` chip with the actual version string read from `PackageInfo` (via `package_info_plus`). Display it as a small badge styled with `accentTintMid` background and `accent` text colour (matching the existing chip decoration but showing `0.1.0` instead of `'Up to Date'`).

---

## 2 · Sort projects wiring

**Problem**: `ProjectSortNotifier` persists the user's sort choice but `projectsProvider` (in `project_sidebar_notifier.dart`) streams `svc.watchAllProjects()` without passing any sort parameter — the list order never changes.

**Fix**: Sort the project list in-memory inside the `projects` provider, after the stream emits. Watch both `projectsProvider` (raw DB stream) and `projectSortProvider`, then apply the sort in the derived provider body:

```
ProjectSortOrder.lastMessage → sort by most-recent session's last-message timestamp (desc)
ProjectSortOrder.createdAt   → sort by project.createdAt (desc)
ProjectSortOrder.manual      → preserve DB insertion order (no-op sort)
```

The thread sort (`ThreadSortOrder`) is already stored; apply it similarly when building the session list inside each `ProjectTile`.

No changes to the datasource or service layers — sorting stays at the notifier/provider level.

---

## 3 · API key cards — per-provider inline test

### Status dot — four states

| Dot colour | Meaning | When set |
|---|---|---|
| Gray | Empty — no key present | Field is blank |
| Yellow | Unsaved — key typed/changed but not tested | Any keystroke after empty or after a saved state |
| Green | Valid & saved | Test API call succeeded; key written to DB |
| Red | Invalid | Test API call failed; key NOT written to DB |

Card header subtitle text mirrors the state: `Not configured` / `Unsaved changes` / `Valid & saved` / `Invalid key`.

### Interaction model (Option A — agreed)

- **Test button** (fixed width `62 px`): calls `SettingsActions.testApiKey(provider, key)`. On success → saves key via `ApiKeysNotifier.saveKey`, updates dot to green, shows toast `"API key saved"`. On failure → dot turns red, shows toast `"Invalid key — not saved"`. Button label updates to `✓ Valid` (green) or `✗ Invalid` (red) after the call; resets to `Test` when the field is edited again.
- **✕ button**: clears the text field and calls `ApiKeysNotifier.deleteKey(provider)`, dot → gray, shows toast `"Key cleared"`.
- **Any keystroke** on a green or red field → dot immediately returns to yellow and button resets to `Test`.
- Input text colour stays the default theme colour at all times — only the dot and button carry state colour.

### `ApiKeysNotifier` additions needed

`saveKey(AIProvider, String)` — persists a single key and invalidates `aiRepositoryProvider`. The existing `saveAll` remains for any other callers.

---

## 4 · Ollama URL and Custom Endpoint — inline test / clear

### Current state
- Ollama: standalone `TextButton.icon('Test Connection')` below the settings group; no clear button; save happens via the global Save button.
- Custom: no test button; save via global Save button.
- Global `ElevatedButton('Save')` at the bottom of the Providers screen.

### New design

**Global Save button removed.**

Both sections get inline trailing controls inside each `SettingsRow`:

```
[ url text field ]  [ Test ]  [ ✕ ]
```

For Custom Endpoint the API Key row gets its own `[ ✕ ]` (no Test — tested as part of the URL row).

#### Ollama URL behaviour
- **Test**: HTTP ping via `SettingsActions.testOllamaUrl(url)`. On success → persists URL via `ApiKeysNotifier.saveOllamaUrl`, shows toast `"Ollama URL saved"`. On failure → toast `"Cannot connect to Ollama"`. URL is only written on a successful test.
- **✕**: clears the field and removes the stored URL from secure storage; shows toast `"Ollama URL cleared"`.

#### Custom Endpoint behaviour
- **Test** (on the Base URL row): pings the endpoint (HTTP GET to `baseUrl/models` with the stored API key if present). On success → persists both `customEndpoint` and `customApiKey`; toast `"Custom endpoint saved"`. On failure → toast `"Cannot connect to endpoint"`.
- **✕** on Base URL row: clears URL field and DB entry; toast `"Custom URL cleared"`.
- **✕** on API Key row: clears key field and DB entry; toast `"Custom API key cleared"`.

`ApiKeysNotifier` needs `saveOllamaUrl(String)`, `clearOllamaUrl()`, `saveCustomEndpoint(String, String)`, `clearCustomEndpoint()`, `clearCustomApiKey()` methods (or appropriate equivalents). Existing `saveAll` logic can remain for backward compatibility.

---

## 5 · Integrations settings screen

### Navigation

Add `_SettingsNav.integrations` to the `_SettingsNav` enum in `settings_screen.dart`. Insert a new nav item **"Integrations"** between Providers and Archive in `_SettingsLeftNav`.

### `IntegrationsScreen` widget

Location: `lib/features/settings/integrations_screen.dart`

Watches `gitHubAuthProvider` and renders one of two states:

**Not connected**
```
Section label: GITHUB
SettingsGroup containing:
  FilledButton with GitHub SVG mark + "Continue with GitHub"
  TextButton "Use a Personal Access Token instead" (collapsible PAT field, reusing GithubStep PAT logic)
Usage note: "GitHub is used to create pull requests and list branches from within chat sessions."
```

**Connected**
```
Section label: GITHUB
Card showing:
  Avatar (ClipRRect Image.network if avatarUrl non-empty, else person icon)
  Username + "✓ Connected" label
  "Disconnect" button (calls gitHubAuthProvider.notifier.signOut())
Usage note (same as above)
```

Auth actions (`authenticate`, `signInWithPat`, `signOut`) delegate directly to `gitHubAuthProvider.notifier` — no new notifier needed. Error handling via `ref.listen(gitHubAuthProvider, ...)` → `AppSnackBar.show`.

---

## 6 · `.gitignore` update

Add `.superpowers/` to the project `.gitignore` so brainstorm artefacts aren't committed.

---

## Scope boundaries

- No changes to `GitHubRepository`, `GitHubService`, or any auth datasource.
- No changes to how sort order is stored — only how it is applied when rendering.
- No new Drift migrations — all new persistence fields (ollamaUrl, customEndpoint, customApiKey) already exist in `SettingsService`.
- `testCustomEndpoint` uses a simple HTTP GET to `$baseUrl/models` with the stored key — same pattern as the existing OpenAI test in `ApiKeyTestDatasourceDio`.
