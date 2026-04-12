# Code Bench — Claude Instructions

## Development Commands

```bash
# Run on macOS (primary dev target)
flutter run -d macos

# Run on other platforms
flutter run -d windows
flutter run -d linux

# Build
flutter build macos

# Analyze
flutter analyze

# Format
dart format lib/ test/

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Generate code after editing Drift tables, adding @riverpod, or @freezed models
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs
```

> **Never edit generated files manually** (e.g. `*.g.dart`, `*.freezed.dart`). Always regenerate them via `build_runner`. Manual edits will be overwritten on the next build.

## Implementation Plans & Worktrees

Plans are saved to `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`.

When starting work from a plan, always create a git worktree under `.worktrees/` at the repo root. The worktree directory and branch share the same name, using a conventional prefix based on the type of work:

| Prefix  | When to use                      |
| ------- | -------------------------------- |
| `feat/` | New features                     |
| `fix/`  | Bug fixes                        |
| `tech/` | Refactors, tooling, dependencies |
| `doc/`  | Documentation only               |

The name after the prefix is the plan filename stripped of `.md` only — keep the date. For a plan file `2026-04-07-sign-features-flag.md` (a feature):

```bash
git worktree add .worktrees/feat/2026-04-07-sign-features-flag -b feat/2026-04-07-sign-features-flag
cd .worktrees/feat/2026-04-07-sign-features-flag
```

All implementation work happens inside that worktree.

## Architecture — Dependency Rule

The dependency graph is strictly one-directional:

```
Widgets / Screens
      ↓  (ref.watch / ref.read notifier)
  Notifiers          ← the only layer widgets may reach
      ↓  (ref.read service)
  Services           ← Dio, DB, Process.run, filesystem live here
      ↓
 External (API / SQLite / OS)
```

**Hard rules — enforced in code review:**

| Allowed | Forbidden in widgets/screens |
|---|---|
| `ref.watch(someNotifierProvider)` | `ref.read(someServiceProvider)` |
| `ref.read(someNotifierProvider.notifier).method()` | `ref.read(applyServiceProvider)`, `ref.read(projectServiceProvider)`, etc. |
| `url_launcher` (`launchUrl`) for opening URLs/files | `Process.run(...)` |
| Path string operations (`p.join`, etc.) | `Directory(...).existsSync()` or any `dart:io` I/O |

**Naming conventions — strictly enforced:**

| Layer | Suffix rule | Examples |
|---|---|---|
| Service class | must end in `Service` | `GitService`, `SessionService` |
| Service provider | `@riverpod` / `@Riverpod` placed **before** the class it instantiates | `gitServiceProvider`, `sessionServiceProvider` |
| Command notifier | must end in `Actions` — `void build()`, imperative methods, `keepAlive: true` | `ProjectSidebarActions`, `CodeApplyActions`, `GitActions` |
| State notifier | must end in `Notifier` — owns `AsyncValue` or value state | `ChatNotifier`, `GitHubAuthNotifier`, `ActiveSessionIdNotifier` |
| `ref.invalidate` in widgets | **forbidden** — route through a notifier method instead | `refreshGitState()`, `refreshArchivedSessions()` |

The Riverpod generator strips the `Notifier` suffix when producing the provider variable name (`class ActiveSessionIdNotifier` → `activeSessionIdProvider`). The `Actions` suffix is kept (`class GitActions` → `gitActionsProvider`).

**Where services live:** `lib/services/` only. Services are instantiated via `@riverpod` / `@Riverpod(keepAlive: true)` provider functions — never constructed directly in widgets or notifiers.

**`Process.run` / `dart:io` / Dio** — allowed only inside `lib/services/`. The one exception is `ApplyService.assertWithinProject` (a static security guard), which may be called from widgets that perform their own file reads (e.g. `_loadDiff` in `message_bubble.dart`).

## Riverpod usage rules

- `ref.watch` → widget `build()` methods **and** `@riverpod` provider bodies (both are reactive). Never in event handlers, notifier methods, or async callbacks.
- `ref.read` → everywhere else: event handlers, notifier methods, `initState`. One-shot, no subscription.
- `.notifier` → required when calling a method on the notifier class: `ref.read(fooProvider.notifier).doThing()`, not `ref.read(fooProvider).doThing()`.
- `AsyncValue` unwrapping → prefer exhaustive `switch` over `AsyncData` / `AsyncLoading` / `AsyncError` in `build()`. Only use `.value` for intentional "latest known" reads inside event handlers.

## Logging

Two helpers live in [lib/core/utils/debug_logger.dart](lib/core/utils/debug_logger.dart):

| Helper | Survives release builds? | Use for |
|---|---|---|
| `dLog` | No — stripped via `kDebugMode` | Debug breadcrumbs, triage for swallowed exceptions |
| `sLog` | Yes — `dart:developer` structured log | Security events (path-traversal, auth failures, flag-shaped argument rejections, sandbox violations) |

**Where to log:**

| Layer | Logs? | What to log |
|---|---|---|
| Services (`lib/services/`) | Yes | Raw I/O failures — `ProcessException`, Dio errors, `FileSystemException`, security-guard rejections (`sLog`) |
| Notifiers (`*Actions`, `*Notifier`) | Yes | Caught exceptions being turned into `AsyncError` or swallowed; semantic operation failures ("pushToRemote failed") |
| Widgets / screens | **No, with two exceptions** | (1) `AsyncValue.when(error:)` branches that render an error view, (2) widget-layer APIs the arch rule permits in widgets — `launchUrl` failures and `Clipboard` failures |

Log **once**, at the layer that holds the useful context. If a service already `dLog`s a `ProcessException`, the notifier rethrowing it should not log again — it should only log if it's doing additional recovery worth tracing.

Never `dLog` raw HTTP headers, tokens, or response bodies — see [github_api_service.dart](lib/services/github/github_api_service.dart) for the GitHub PAT redaction pattern.

## macOS notes

App Sandbox is **intentionally disabled** on macOS because `ActionRunnerService`, `GitService`, and `IdeLaunchService` all shell out to external binaries. See [macos/Runner/README.md](macos/Runner/README.md) for the rationale, contributor rules (no `runInShell: true`, no PAT header logging), and distribution implications. Any change to `macos/Runner/*.entitlements` or to the process-execution services must be weighed against that threat model.

## Brainstorming Options

When presenting multiple-choice options (A/B/C etc.) during brainstorming:
- Always include a short concrete example for each option
- Always mark the recommended option with a ★ symbol
- If the options involve UI (layouts, components, interactions), always show a visual mockup in the browser companion without waiting to be asked

## Pull Request Template

Use this format both when creating a PR (`gh pr create`) and when asked for a PR summary. When giving a summary (not creating), wrap the output in a markdown code block so it is copyable:

```markdown
## Summary

Brief description of what this PR does and why.

Closes #<!-- issue number -->

## Changes

-
-

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor / internal improvement
- [ ] Documentation

## Checklist

- [ ] `flutter analyze` passes with no issues
- [ ] `dart format lib/` applied
- [ ] `flutter test` passes
- [ ] If Drift tables or Riverpod providers were changed, `build_runner` was re-run and generated files are not committed
- [ ] PR is focused on a single concern
```
