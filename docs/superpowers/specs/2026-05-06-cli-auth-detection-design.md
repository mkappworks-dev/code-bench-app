# CLI Auth Detection — Design Spec

> **Date:** 2026-05-06
> **Status:** Design (pre-plan)
> **Worktree:** `tech/2026-05-06-chat-stream-registry` (extends the chat-stream-registry work)

## Goal

Distinguish "CLI installed" from "CLI authenticated" across every surface where the distinction matters, and gate the chat input *proactively* on transport readiness so users never type a prompt that's doomed to fail. Both Anthropic Claude CLI and OpenAI Codex CLI gain a real auth probe; HTTP transports keep their existing readiness flow. Replaces today's behaviour where:

- The providers screen reports "Installed" purely from `--version` exit code, so a freshly-installed-but-signed-out CLI looks ready.
- Auth failures only surface mid-stream as `AgentFailure.streamAbortedUnexpectedly` with a verbose stack trace.
- The Codex datasource bundles auth-checking into the streaming flow (`_checkAuth` inside `_send`), coupling unrelated concerns.

## Background — what each CLI exposes

Verified locally on 2026-05-06:

| Probe | Command | Output | Wall time |
|---|---|---|---|
| Claude install | `claude --version` | "x.y.z\n" | <100 ms (existing) |
| Claude auth | `claude auth status --json` | `{"loggedIn": true, "email": "...", ...}` | ~150 ms |
| Codex install | `codex --version` | "x.y.z\n" | <100 ms (existing) |
| Codex auth | `codex login status` | "Logged in using ChatGPT" / "Not logged in" (text only) | ~50 ms |

Both auth probes are subprocess-based, parsing-trivial, and well under 200 ms each. A full sweep of both providers' install + auth costs ~400 ms in parallel — cheap enough to run on every providers-screen mount and session activation without aggressive caching.

## Architecture

Strictly one-directional per [CLAUDE.md](../../../CLAUDE.md):

```
Widgets ─→ Notifiers ─→ Services ─→ Datasources ─→ External (CLI process)
   │           │            │            │
   │           │            │            └─ Process.run('claude auth status --json')
   │           │            │               Process.run('codex login status')
   │           │            │
   │           │            └─ AIProviderService.getAuthStatus(id)
   │           │               returns ProviderEntry { installStatus, authStatus }
   │           │
   │           └─ transportReadinessProvider (derived)
   │              composes selectedModel + apiKeys + aiProviderStatus
   │              → TransportReadiness.{ready|notInstalled|signedOut|httpKeyMissing|unknown}
   │
   └─ chat_input_bar reads readiness; provider cards read aiProviderStatus
```

No widget imports a service or datasource. No service imports a notifier-layer provider.

## File structure

### New files (4)

| Path | Responsibility |
|---|---|
| `lib/data/ai/models/auth_status.dart` | Freezed sealed `AuthStatus`: `authenticated` / `unauthenticated` / `unknown` |
| `lib/features/chat/notifiers/transport_readiness_notifier.dart` | Derived `transportReadinessProvider` + `TransportReadiness` freezed sealed union |
| `test/data/ai/datasource/claude_cli_auth_test.dart` | `verifyAuth` parser + spawn-failure tests (mock `Process.run`) |
| `test/data/ai/datasource/codex_cli_auth_test.dart` | Same shape for Codex |

### Modified files (10)

| Path | Change |
|---|---|
| `lib/data/ai/datasource/ai_provider_datasource.dart` | Add `Future<AuthStatus> verifyAuth();` to the interface |
| `lib/data/ai/datasource/claude_cli_datasource_process.dart` | Implement `verifyAuth` via `claude auth status --json`; parse `loggedIn` boolean |
| `lib/data/ai/datasource/codex_cli_datasource_process.dart` | Implement `verifyAuth` via `codex login status`; **remove** `_checkAuth` invocation in `_send` (currently around line 174) and the throw-from-`_checkAuth` site (around line 616). The new `verifyAuth` replaces both. |
| `lib/services/ai_provider/ai_provider_service.dart` | Add `getAuthStatus(id)`; extend `ProviderEntry` with `final AuthStatus authStatus`; `listWithStatus()` runs install + auth in parallel via `Future.wait` |
| `lib/data/chat/models/agent_failure.dart` | Add `AgentFailure.transportNotReady(TransportReadiness readiness)` variant. Wraps the readiness directly — readiness already encodes the four not-ready cases (`signedOut` / `notInstalled` / `httpKeyMissing` / `unknown`), so we don't need parallel sub-variants on the failure union. |
| `lib/features/chat/notifiers/chat_notifier.dart` | Add the pre-send probe block to `sendMessage` (see "Pre-send sequence" below) |
| `lib/features/providers/widgets/anthropic_provider_card.dart` | `_cliBadge()` returns `Widget` (was `CardStatusBadge`); render install pill + sibling `Signed out` pill via `Wrap` when `authStatus is AuthUnauthenticated` |
| `lib/features/providers/widgets/openai_provider_card.dart` | Same change for the Codex CLI sub-card |
| `lib/features/chat/widgets/chat_input_bar.dart` | Watch `transportReadinessProvider`; render warning/error strip above input + dim Send when not `ready`; add new `AgentTransportNotReady` arm to the existing send-error switch (passive snackbar — strip is the primary surface) |

`*.freezed.dart`, `*.g.dart` codegen outputs are regenerated and committed alongside their sources per the project's "generated files must be committed" convention.

`lib/features/providers/notifiers/ai_provider_status_notifier.dart` does **not** need editing — `recheck()` already routes through `listWithStatus()`, which gains the auth probe at the service layer.

### Type definitions

```dart
// lib/data/ai/models/auth_status.dart
@freezed
sealed class AuthStatus with _$AuthStatus {
  const factory AuthStatus.authenticated() = AuthAuthenticated;
  const factory AuthStatus.unauthenticated({
    required String signInCommand,  // e.g. "claude auth login", "codex login"
    String? hint,                    // e.g. "subscription required"
  }) = AuthUnauthenticated;
  const factory AuthStatus.unknown() = AuthUnknown;
}
```

```dart
// lib/features/chat/notifiers/transport_readiness_notifier.dart
@freezed
sealed class TransportReadiness with _$TransportReadiness {
  const factory TransportReadiness.ready() = TransportReady;
  const factory TransportReadiness.notInstalled({required String provider}) = TransportNotInstalled;
  const factory TransportReadiness.signedOut({
    required String provider,
    required String signInCommand,
  }) = TransportSignedOut;
  const factory TransportReadiness.httpKeyMissing({required String provider}) = TransportHttpKeyMissing;
  const factory TransportReadiness.unknown() = TransportUnknown;
}

@riverpod
TransportReadiness transportReadiness(Ref ref) {
  // body: ref.watch selectedModel + apiKeys + aiProviderStatus → fold into one variant
}
```

`AuthStatus` is a model (used as a field on `ProviderEntry`), not an exception — placed in `lib/data/ai/models/` per the convention.

## Data flow & state machine

### Probe triggers

Three explicit moments run `verifyAuth`:

1. **App start / providers screen first mount** — `aiProviderStatusProvider.build()` → `listWithStatus()` runs install + auth per CLI in parallel.
2. **"Recheck" button** — `aiProviderStatusProvider.recheck()` re-runs the same path. Same cost.
3. **Pre-send (CLI transports only)** — inside `ChatMessagesNotifier.sendMessage`, after resolving `providerId`, run `verifyAuth()` *fresh* (bypassing whatever `aiProviderStatusProvider` cached) for the active CLI. If `unauthenticated`, return `AgentFailure.transportNotReady(TransportReadiness.signedOut(...))` and don't spawn the stream.

No background polling, no window-focus listener, no filesystem watch (per Q3-A — the next Send always re-probes, so externally-changed auth picks up automatically).

### `transportReadiness` resolution

```
inputs: selectedModel, apiKeys (transport pref + saved keys), providerEntries

(model.provider, transport-pref) →
  ┌─ HTTP transport (anthropic/openai/gemini API key, custom endpoint) ─────
  │   apiKey is savedVerified or savedUnverified?  → TransportReady
  │   apiKey is empty/unsaved?                     → TransportHttpKeyMissing
  │
  ├─ CLI transport (claude-cli / codex) ────────────────────────────────────
  │   AsyncLoading (not yet probed)?               → TransportUnknown
  │   installStatus is ProviderUnavailable?        → TransportNotInstalled
  │   authStatus is AuthUnauthenticated?           → TransportSignedOut(cmd)
  │   authStatus is AuthUnknown?                   → TransportReady (honest bias — don't block)
  │   installStatus available && authStatus authenticated? → TransportReady
  │
  └─ Ollama (local server) ────────────────────────────────────────────────
      existing connect dot status `savedVerified`? → TransportReady, else HttpKeyMissing
```

The `AuthUnknown → TransportReady` rule is intentional. A probe failure (process spawn fails, JSON parse fails, RPC times out) must not over-block — if the user can actually send, we let them. If the CLI then emits an auth error mid-stream, the existing `AgentFailure.streamAbortedUnexpectedly` path catches it and the user sees the same error they would have today (no regression).

### Pre-send sequence inside `sendMessage`

```dart
Future<Object?> sendMessage(String input, {String? systemPrompt}) async {
  // ... existing setup through `final providerId = _resolveProviderId(model, prefs);` ...

  // (1) Cheap pre-flight against the cached/derived readiness.
  // Belt + suspenders for code paths that bypass the chat input (e.g.
  // ChatMessagesNotifier.continueAgenticTurn).
  final readiness = ref.read(transportReadinessProvider);
  if (readiness is! TransportReady && readiness is! TransportUnknown) {
    return AgentFailure.transportNotReady(readiness);
  }

  // (2) Fresh re-probe — only for CLI transports. HTTP transports' readiness
  //     is fully captured in apiKeysProvider; no datasource probe needed.
  if (providerId != null) {
    final ds = ref.read(aIProviderServiceProvider.notifier).getProvider(providerId);
    if (ds != null) {
      final freshAuth = await ds.verifyAuth();
      if (freshAuth is AuthUnauthenticated) {
        return AgentFailure.transportNotReady(
          TransportReadiness.signedOut(
            provider: providerId,
            signInCommand: freshAuth.signInCommand,
          ),
        );
      }
    }
  }

  // ... existing registry.start flow ...
}
```

**Cache vs fresh:** Step (1) reads `transportReadinessProvider`, which derives from `aiProviderStatusProvider` — a keepAlive notifier that caches `listWithStatus()` results until next mount/recheck. Step (2) bypasses the cache by going directly to the datasource, ensuring an externally-changed auth state (user just ran `claude auth login` between session activation and Send) is picked up. The cached `aiProviderStatusProvider` is **not** invalidated by the fresh probe — the providers screen would re-probe on its next mount/recheck. Keeping cache and fresh-probe results decoupled avoids the chat path triggering UI re-renders elsewhere.

### Edge & race cases

| Scenario | Behaviour |
|---|---|
| Auth probe times out / process spawn fails | `AuthStatus.unknown` → `TransportReady` → user can send. CLI's own auth error (if any) surfaces via existing `streamAbortedUnexpectedly`. |
| User signs in externally, then sends | Pre-send fresh `verifyAuth()` succeeds → `AgentFailure.transportNotReady` not raised → send proceeds. Cached `aiProviderStatusProvider` updates on next mount/recheck (no auto-refresh). |
| User signs out externally while typing | Strip won't appear until next probe trigger. Pre-send catches it. UX same as "signed out the moment they hit Send." |
| Both CLIs signed out, user has Codex selected | Only Codex's strip drives chat input. Both cards still update independently. |
| `ChatMessagesNotifier` disposes mid-probe | Existing chat-stream-registry refactor handles this — `verifyAuth()` is a one-shot Future, not a long-lived stream, so no ref-after-dispose hazard. |

## UI specifics

### Provider card — two-pill state

`_cliBadge()` returns `Widget` instead of `CardStatusBadge`. Wraps install + auth pills in a `Wrap(spacing: 6, alignment: WrapAlignment.end)` so they reflow on narrow widths. Order: install pill (success), then auth pill (warning) — left-to-right matches resolution order.

| `(installStatus, authStatus)` | Pills rendered |
|---|---|
| `(available v$VER, authenticated)` | `✓ Installed · v$VER` (success) |
| `(available v$VER, unauthenticated)` | `✓ Installed · v$VER` + `⚠ Signed out` |
| `(available v$VER, unknown)` | `✓ Installed · v$VER` (alone — honest bias) |
| `(unavailable, *)` | existing single pill (`Active · Not installed` / `Not installed` / `Checking…`) — auth is meaningless without an installed binary |
| `AsyncLoading` | existing `Checking…` muted pill |

### Chat input — strip + dimmed Send

Strip sits *above* the existing input, sharing the rounded outer container (top-rounded strip, bottom-rounded input, joined corners). Only renders when `transportReadiness` is one of the `not-ready` variants.

| `TransportReadiness` | Strip text | CTA | Border tone |
|---|---|---|---|
| `signedOut(claude-cli)` | "Claude isn't signed in — run `claude auth login`" | `claude auth login` + `AppIcons.copy` | warning |
| `signedOut(codex)` | "Codex isn't signed in — run `codex login`" | `codex login` + `AppIcons.copy` | warning |
| `notInstalled(claude-cli)` | "Claude CLI isn't installed." | `Open providers screen` (existing nav helper) | error |
| `notInstalled(codex)` | "Codex CLI isn't installed." | `Open providers screen` | error |
| `httpKeyMissing(...)` | "$Provider API key not configured." | `Open providers screen` | error |

When strip is visible:
- **Send button** uses existing `disabled` look (theme-driven — `mutedFg` on `inputSurface`).
- **Text field** stays editable (the user may want to type their thought now).
- Empty-field placeholder: `Sign in to send a message…` / `Configure $provider to send…`
- Filled-field placeholder: unchanged (don't clobber the draft hint).

### CTA button behaviour — two icon buttons

The strip's right side has the command text inline (`claude auth login` / `codex login`) followed by **two icon buttons** placed next to each other:

| Button | Icon | Behaviour |
|---|---|---|
| **Copy** | `AppIcons.copy` (`LucideIcons.copy`) | `Clipboard.setData(ClipboardData(text: signInCommand))` then snackbar `'"$cmd" copied — paste in your terminal'` |
| **Open in terminal** | `LucideIcons.terminal` (add new entry in `lib/core/constants/app_icons.dart` as `AppIcons.terminal`) | First `Clipboard.setData(...)`, then `await ref.read(ideLaunchActionsProvider.notifier).openInTerminal(projectPath);` — opens the user's configured terminal app (`generalPrefs.terminalApp`, default `Terminal`) at the active project's working directory. Snackbar reports either success (`'Opened $terminalApp — paste to sign in'`) or the existing failure-string surface from `IdeLaunchDatasourceProcess.openInTerminal`. |

Reusing `ideLaunchActionsProvider.openInTerminal` means: ✅ existing flag-shape defense in `IdeLaunchDatasourceProcess.buildTerminalArgs` applies; ✅ `terminalApp` preference is honoured (Terminal / iTerm / Warp / Ghostty etc.); ✅ no new service needed; ✅ `Process.run` stays in the existing datasource per the dependency rule.

The clipboard call is wrapped in try/catch (per CLAUDE.md Rule 1, clipboard is one of the two permitted widget-level exceptions); the `openInTerminal` call routes through the Actions notifier so it doesn't need a widget-layer try/catch.

The terminal app does **not** auto-type the command — `open -a $TERMINAL_APP -- $PROJECT_PATH` opens a fresh shell at the project cwd. The user pastes from clipboard. We deliberately don't try to drive keystrokes (security-sensitive, terminal-app-coupled, not portable).

### Visual tokens (no new tokens needed)

- `c.warningTintBg`, `c.warning` for the signed-out strip.
- `c.errorTintBg`, `c.error` for not-installed / api-key-missing strips.
- `TransportBadgeTone.warning` for the `Signed out` pill (already exists).

### Accessibility

- Strip is a `Semantics` node with `liveRegion: true` so screen readers announce on appear.
- `Tooltip` on disabled Send: `'Sign in to send'` / `'Configure $provider to send'`.
- Tab order: input → strip CTA → Send.

## Testing strategy

### Datasource tests (new)

`test/data/ai/datasource/claude_cli_auth_test.dart`:
- `verifyAuth` returns `AuthAuthenticated` when subprocess prints `{"loggedIn": true, ...}` and exit 0.
- Returns `AuthUnauthenticated(signInCommand: 'claude auth login')` when JSON shows `loggedIn: false`.
- Returns `AuthUnknown` when subprocess errors / non-JSON output / non-zero exit.
- Returns `AuthUnknown` when `Process.run` throws `ProcessException` (binary missing).

`test/data/ai/datasource/codex_cli_auth_test.dart`:
- Returns `AuthAuthenticated` when stdout contains `Logged in` and exit 0.
- Returns `AuthUnauthenticated(signInCommand: 'codex login')` when exit non-zero or stdout starts with `Not logged in`.
- Returns `AuthUnknown` on probe error.

Both use the existing `Process.run` mock pattern from sibling tests in `test/data/ai/datasource/`.

### Service tests (extend existing `ai_provider_service_test.dart`)

- `listWithStatus()` runs install + auth in parallel (verify both `Process.run` futures spawn before either completes).
- `ProviderEntry` carries through both fields.
- Auth probe is **skipped** when install probe returns `DetectionMissing` (no point probing auth on a missing binary).

### Notifier tests (new file: `test/features/chat/notifiers/transport_readiness_test.dart`)

Exhaustive matrix over `(transport-pref, providerEntry, apiKey)` → expected `TransportReadiness`:
- HTTP, key savedVerified → `Ready`
- HTTP, key empty → `HttpKeyMissing`
- CLI, install missing → `NotInstalled`
- CLI, install ok + auth unauthenticated → `SignedOut`
- CLI, install ok + auth unknown → `Ready` (honest bias)
- AsyncLoading → `Unknown`

### Widget tests (extend providers screen + chat input bar tests)

- Provider card renders both pills when `authStatus` is unauthenticated.
- Provider card renders single pill when `authStatus` is authenticated or unknown.
- Chat input renders strip + dims Send when `TransportReadiness != Ready/Unknown`.
- CTA button copies the right command and fires snackbar.

### Integration test (new — extend `chat_notifier_test.dart`)

- Pre-send `verifyAuth` returning `unauthenticated` → `sendMessage` returns `AgentFailure.transportNotReady(TransportReadiness.signedOut(...))` without invoking the registry.
- Pre-send `verifyAuth` returning `unknown` → `sendMessage` proceeds (existing flow).

## Out of scope (YAGNI)

- **No window-focus auto-recheck** (Q3-A — recheck button + next Send re-probes are sufficient).
- **No filesystem watch** on `~/.codex/` / `~/.claude/`.
- **No Open Terminal.app** action — clipboard-only, leaves the user in control.
- **No persisted auth-required marker** in chat history — the proactive gate makes this unnecessary.
- **No "Sign in" inline launcher** that runs `claude auth login` / `codex login` in a pseudo-terminal — those commands are interactive and security-sensitive; clipboard handoff is the correct affordance.
- **No probe-result cache TTL** — probes are cheap (~150 ms / ~50 ms), and freshness is more valuable than the savings.

  *How we'd know to add a TTL later (concrete trigger criteria):*

  | Signal | How to gather | Threshold that justifies a TTL |
  |---|---|---|
  | Probe wall-time | Wrap each `verifyAuth()` call in `dLog('[AIProviderService] verifyAuth($id) took ${sw.elapsedMilliseconds}ms')` and read the breadcrumbs during normal use | Any single probe consistently > 500 ms (e.g. a slow-mounted volume, antivirus scan delaying `Process.start`) |
  | Probe frequency | Count `verifyAuth` invocations per second via the same dLog; `grep -c verifyAuth` over a 60 s session | More than 3 invocations per second sustained, or more than once per keystroke (would indicate the chat input is over-watching) |
  | Frame-budget impact | Flutter DevTools → Performance → Timeline; record while opening providers screen / switching sessions; look for `verifyAuth` frames in the >16 ms band | Any frame > 16 ms with `verifyAuth` on the critical path (causes a dropped frame) |
  | UI rebuild churn | dLog at the top of `aiProviderStatusProvider.build()`; observe rebuild count during navigation | Provider rebuilds during interactions that shouldn't invalidate it (e.g., typing in chat → status rebuild) |

  Adding a 30 s TTL would live inside `AIProviderService` (not the datasource, so the freshness guarantee in the pre-send path is preserved). Implementation sketch: a per-`(providerId, probeKind)` `(DateTime stampedAt, Future<X> result)` map; reads return the cached future if `now - stampedAt < 30s`, else re-probe. ~30 LoC, easily added if any signal above hits its threshold.

## Architecture compliance

| Rule (from [CLAUDE.md](../../../CLAUDE.md)) | Status |
|---|---|
| Widgets → Notifiers → Services → Datasources (one-directional) | ✅ chat_input_bar reads `transportReadinessProvider`; provider reads other notifiers + the keepAlive `aiProviderStatusProvider`; service calls datasource `verifyAuth`; datasource does the `Process.run`. |
| Widgets never `ref.read(serviceProvider)` | ✅ Only notifier reads. |
| `try/catch` in widgets forbidden except `launchUrl`/`Clipboard` | ✅ Single new try/catch around `Clipboard.setData` in CTA button. |
| Service/Notifier/Actions naming | ✅ `AIProviderService` (existing), `transportReadinessProvider` (derived value provider, function-shape — no Notifier suffix needed), `AuthStatus` is a model. |
| Domain models in `lib/data/{domain}/models/` | ✅ `auth_status.dart` lives in `lib/data/ai/models/`. |
| `Process.run` only in datasources/services | ✅ Both `verifyAuth` impls run `Process.run` inside the datasource. |
| `ref.invalidate` in widgets forbidden | ✅ Recheck routes through `aiProviderStatusProvider.recheck()` (existing). |
| Notifiers subfolder convention | ✅ `transport_readiness_notifier.dart` lives in `lib/features/chat/notifiers/`. |
| AsyncValue exhaustive switch | ✅ Provider cards exhaustively switch on `ProviderEntry` shape (existing pattern preserved). |

## Decision log (questions answered during brainstorming)

- **Q1 — Type-system shape:** B (separate `verifyAuth` capability, not a fourth `DetectionResult` variant). Install and auth are independent axes.
- **Q2 — Probe trigger points:** B (mount + recheck + pre-send). No background polling.
- **Q3 — External sign-in pickup:** A (existing recheck button + next-Send re-probe are sufficient).
- **Q4 — Provider card UX:** B (two pills side-by-side: existing install pill + new `Signed out` pill, only when applicable). Scope expanded post-Q4 to cover Claude CLI as well, after discovering `claude auth status --json`.
- **Q5 — Chat error UX:** Proactive gate (dim Send + warning strip above input bar; unified `transportReadinessProvider`). Replaces the earlier reactive-bubble plan after the user pointed out we already know transport state at session activation.
