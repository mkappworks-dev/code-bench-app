# Code Bench — UI Polish Phase 4: Onboarding Redesign

## Overview

Phase 4 replaces the existing single-screen API-key onboarding with a polished three-step wizard: **API Keys → GitHub → Add First Project**. All steps are skippable. The split-panel chrome (left 38% branding, right 62% content) is preserved from the current implementation.

This is Phase 4 of the UI improvement queue.

---

## Decisions Made

### 1. Overall Structure

The existing `OnboardingScreen` becomes a three-step wizard shell. Only the right panel content changes between steps; the left branding panel is unchanged.

**Progress indicator** (top of right panel):
- Three pill-shaped dots — completed steps are solid blue (`#4A7CFF`), current step is blue at 50% opacity, upcoming steps are grey (`#2A2A2A`)
- Step label below the dots: `STEP N OF 3` in small-caps, `labelSmall` style
- Step title in `titleMedium`, subtitle in `bodySmall` colour `#666`

**Navigation:**
- Back button (top-left of content area, Lucide `ChevronLeft` icon) shown on steps 2 and 3
- "Continue →" or "Add Project" primary button (bottom-right)
- "Skip for now" text button (bottom-left) — always present, advances to the next step; on step 3 navigates to the main chat screen

**State management:**
- `OnboardingController` — Riverpod `StateNotifier<int>` holding `currentStep` (0–2)
- Scoped to the `OnboardingScreen` widget lifetime; no persistence needed (not keepAlive)

---

### 2. Step 1 — API Keys

Content is the existing API key form, extracted into a dedicated widget and visually polished.

**Changes:**
- Existing provider list (expandable rows, test connection buttons) preserved
- Icons updated to Lucide equivalents (Phase 1 dependency)
- Typography updated to Phase 1 scale (`titleMedium` for step title, `bodySmall` for provider rows)
- "Continue →" primary button — always enabled (user may continue with zero providers)
- "Skip for now" text button — same behaviour as Continue

**Extracted widget:** `lib/features/onboarding/widgets/api_keys_step.dart`

---

### 3. Step 2 — GitHub Connection

Two-part layout: OAuth primary flow with a collapsible PAT fallback.

#### OAuth flow

| State | UI |
|---|---|
| Default | Full-width "Continue with GitHub" button (GitHub Lucide icon + label) |
| Pending | Button shows spinner, disabled |
| Connected | Green checkmark + GitHub avatar + username + "Disconnect" link |

**Implementation:**
- Tap opens OAuth URL in system browser via `Process.run('open', [oauthUrl])`
- App registers a custom URL scheme (`codebench://github-callback`) to receive the redirect
- `GitHubOAuthService` exchanges the code for a token, stores it via `SecureStorageSource`
- On success the step transitions to the connected state; "Continue →" advances to step 3

#### PAT fallback

- `"Use a Personal Access Token instead ↓"` — tapping expands a text field below the OAuth button
- Text field (`obscureText: true`) + "Test" button
- "Test" calls `GitHubApiService.validateToken(token)` — on success shows connected state (username only, no avatar)
- Link: `"Create a token on GitHub →"` — opens `https://github.com/settings/tokens/new` via `Process.run('open', [url])`

**New service:** `lib/services/github/github_oauth_service.dart`

Responsibilities:
- Build the OAuth authorisation URL (client ID, scopes, state param)
- Register the `codebench://` URL scheme handler
- Exchange authorisation code for an access token
- Expose `Future<String> authenticate()` returning the token

**Widget:** `lib/features/onboarding/widgets/github_step.dart`

---

### 4. Step 3 — Add First Project

Drop zone that accepts a dragged folder from Finder, with a browse-button fallback.

#### Default state

- Dashed-border drop zone (border `#2A2A2A`, border-radius 8)
- Drag-over: border transitions to `#4A7CFF`, background tints to `#1A1F2E`
- Inside the zone: folder emoji + "Drop a folder here" label + `"— or —"` divider + "Browse for folder…" button
- "Browse for folder…" calls `FilePicker.getDirectoryPath()` (`file_picker` package — already in project)
- "Add Project" primary button — disabled until a folder is selected

#### Selected state

Zone is replaced by a project preview row:
- Folder icon (Lucide `FolderOpen`) + project name (basename of path) + truncated path
- Green `git` badge if a `.git` directory is detected via `GitDetector`
- "Change folder" link — re-opens picker / clears selection to return to the drop zone

#### Confirm action

"Add Project" calls `ProjectDao.upsertProject(path: selectedPath)` then navigates to the main chat screen with that project active.

**Widget:** `lib/features/onboarding/widgets/add_project_step.dart`

---

### 5. Files Touched

| File | Change |
|---|---|
| `lib/features/onboarding/onboarding_screen.dart` | Rewrite — wizard shell, `OnboardingController` provider, step routing |
| `lib/features/onboarding/widgets/api_keys_step.dart` | New — extracted from existing onboarding screen |
| `lib/features/onboarding/widgets/github_step.dart` | New — OAuth + PAT fallback step |
| `lib/features/onboarding/widgets/add_project_step.dart` | New — drag & drop + browse step |
| `lib/services/github/github_oauth_service.dart` | New — OAuth URL construction, code→token exchange, URL scheme handling |

**No new packages** — `file_picker` is already in the project; `Process.run('open', [url])` handles browser launch.

---

## Out of Scope for This Phase

- Cloning a repo from GitHub during onboarding — Phase 5
- Multi-account GitHub support — Phase 5+
- Re-running onboarding from Settings
- Importing existing projects from a GitHub org list
