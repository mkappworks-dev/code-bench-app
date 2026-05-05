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

Strictly one-directional: **Widgets → Notifiers → Services → Repositories → Datasources → External (API/SQLite/OS)**. Widgets may only reach Notifiers. All I/O (`Process.run`, `dart:io`, Dio) lives in Datasources or Services.

**Hard rules — enforced in code review:**

| Allowed                                             | Forbidden in widgets/screens                                                                               |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `ref.watch(someNotifierProvider)`                   | `ref.read(someServiceProvider)`                                                                            |
| `ref.read(someNotifierProvider.notifier).method()`  | `ref.read(applyServiceProvider)`, `ref.read(gitRepositoryProvider)`, `ref.read(someServiceProvider)`, etc. |
| `url_launcher` (`launchUrl`) for opening URLs/files | `Process.run(...)`                                                                                         |
| Path string operations (`p.join`, etc.)             | `Directory(...).existsSync()` or any `dart:io` I/O                                                         |

**Naming conventions — strictly enforced:**

| Layer                       | Suffix rule                                                                              | Examples                                                        |
| --------------------------- | ---------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| Service class               | must end in `Service`                                                                    | `GitService`, `SessionService`                                  |
| Service provider            | `@riverpod` / `@Riverpod` placed **before** the class it instantiates                    | `gitServiceProvider`, `sessionServiceProvider`                  |
| Repository interface        | must end in `Repository`                                                                 | `GitRepository`, `AIRepository`                                 |
| Repository impl + provider  | class ends in `RepositoryImpl`; `@riverpod` / `@Riverpod` before it                      | `GitRepositoryImpl`, `gitRepositoryProvider`                    |
| Datasource interface        | descriptive name matching file suffix convention                                         | `GitDatasource`, `GitLiveStateDatasource`                       |
| Datasource file naming      | suffix encodes I/O type: `*_dio.dart`, `*_process.dart`, `*_io.dart`, `*_drift.dart`     | `git_datasource_process.dart`, `github_api_datasource_dio.dart` |
| Command notifier            | must end in `Actions` — `void build()`, imperative methods, `keepAlive: true`            | `ProjectSidebarActions`, `CodeApplyActions`, `GitActions`       |
| State notifier              | must end in `Notifier` — owns `AsyncValue` or value state                                | `ChatNotifier`, `GitHubAuthNotifier`, `ActiveSessionIdNotifier` |
| Notifier file placement     | `*_notifier.dart`, `*_actions.dart`, `*_failure.dart` all live in `{feature}/notifiers/` | `features/chat/notifiers/chat_notifier.dart`                    |
| `ref.invalidate` in widgets | **forbidden** — route through a notifier method instead                                  | `refreshGitState()`, `refreshArchivedSessions()`                |

> **Named exception:** `ToolRegistry` (`lib/services/coding_tools/tool_registry.dart`) is intentionally not named `ToolRegistryService`. It is a registry pattern (not a pure service) and the `Service` suffix is reserved for the `ToolRegistryService` that Phase 7 MCP integration may introduce. This is the only approved deviation from the `Service` suffix rule.

The Riverpod generator strips the `Notifier` suffix when producing the provider variable name (`class ActiveSessionIdNotifier` → `activeSessionIdProvider`). The `Actions` suffix is kept (`class GitActions` → `gitActionsProvider`).

**Where services live:** `lib/services/` only. Services are instantiated via `@riverpod` / `@Riverpod(keepAlive: true)` provider functions — never constructed directly in widgets or notifiers.

**Where domain models live:** co-located under their owning domain's `models/` subfolder (`lib/data/git/models/`, `lib/data/session/models/`, etc.). Cross-cutting types used by two or more data domains live in `lib/data/shared/` (currently `AIModel` and `ChatMessage`). The rule of thumb: if it is ever stored, returned, or passed as a field it is a model and lives under `models/`; if it is only ever thrown it is an exception and lives at the domain root.

**`Process.run` / `dart:io` / Dio** — allowed only inside `lib/data/**/datasource/` and `lib/services/`. Datasource files encode their I/O type in their filename suffix: `*_dio.dart` for HTTP, `*_process.dart` for shell-outs, `*_io.dart` for filesystem, `*_drift.dart` for SQLite. The one exception is `ApplyRepository.assertWithinProject` (a static security guard), which may be called from widgets that perform their own file reads (e.g. `_loadDiff` in `message_bubble.dart`).

## Riverpod usage rules

- `ref.watch` → widget `build()` methods **and** `@riverpod` provider bodies (both are reactive). Never in event handlers, notifier methods, or async callbacks.
- `ref.read` → everywhere else: event handlers, notifier methods, `initState`. One-shot, no subscription.
- `.notifier` → required when calling a method on the notifier class: `ref.read(fooProvider.notifier).doThing()`, not `ref.read(fooProvider).doThing()`.
- `AsyncValue` unwrapping → prefer exhaustive `switch` over `AsyncData` / `AsyncLoading` / `AsyncError` in `build()`. Only use `.value` for intentional "latest known" reads inside event handlers.

## Error Handling & State Emission

### Rule 1 — Widget try/catch policy

**Forbidden** in `lib/features/**/widgets/**` and `lib/shell/widgets/**` around any business-logic call (notifier method calls, service calls, async I/O).

**Permitted only** around these widget-layer APIs:

- `launchUrl(...)` from `url_launcher`
- `Clipboard.setData(...)` / `Clipboard.getData()`

Enforcement: code review greps for `try\s*\{` in widget files. Any match must wrap a `launchUrl` or `Clipboard` call — no exceptions.

### Rule 2 — Actions notifier shape

Every command notifier (`*Actions` suffix) extends `AsyncNotifier<void>` with `keepAlive: true`, a `void build()`, and imperative methods. Inside each method:

1. Set `state = const AsyncLoading()`
2. Wrap body in `AsyncValue.guard(() async { try { ... } catch (e, st) { dLog(...); Error.throwWithStackTrace(_asFailure(e), st); } })`
3. Provide `_asFailure(Object e)` that returns a typed `{Name}Failure` via `switch`

Widgets drive loading via `ref.watch(fooActionsProvider).isLoading`. Errors surface via `ref.listen(fooActionsProvider, ...)` with an exhaustive switch on the failure type.

**Exception — shared provider across multiple widget instances:** `ref.listen` fires once per widget, producing N snackbars for one operation. For self-initiated ops in that case, check `ref.read(fooActionsProvider).hasError` inline after the `await` instead. Keep the `ref.listen` for externally-triggered errors.

Canonical examples:

- Actions shape: [`lib/features/chat/notifiers/code_apply_actions.dart`](lib/features/chat/notifiers/code_apply_actions.dart)
- Widget `ref.listen` pattern: [`lib/features/chat/widgets/message_bubble.dart`](lib/features/chat/widgets/message_bubble.dart)

### Rule 3 — Typed failure unions

Each Actions/Notifier that can fail owns a `freezed` sealed class named `{Notifier}Failure`:

**Convention:** Strip the `Actions` or `Notifier` suffix from the class name. `FooActions` → `FooFailure`; `BranchPickerNotifier` → `BranchPickerFailure`. The failure class lives in `{feature}/notifiers/{name}_failure.dart` — the same subfolder as the notifier that owns it.

```dart
@freezed
sealed class FooFailure with _$FooFailure {
  const factory FooFailure.specificError([String? detail]) = FooSpecificError;
  const factory FooFailure.unknown(Object error) = FooUnknownError;
}
```

Widgets never `import '../../services/...'` for exception types — they only `switch` on the local failure type. The `switch` must be exhaustive (Dart enforces this at compile time).

### Rule 4 — Family-provider escalation

Default to a single `AsyncValue<void>` slot per Actions notifier. Only escalate to a `family` provider when a **named, concrete** concurrency scenario exists (documented in the notifier's doc comment). Unapproved family usage is rejected in code review.

## Logging

Two helpers live in [lib/core/utils/debug_logger.dart](lib/core/utils/debug_logger.dart):

| Helper | Survives release builds?              | Use for                                                                                              |
| ------ | ------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `dLog` | No — stripped via `kDebugMode`        | Debug breadcrumbs, triage for swallowed exceptions                                                   |
| `sLog` | Yes — `dart:developer` structured log | Security events (path-traversal, auth failures, flag-shaped argument rejections, sandbox violations) |

**Where to log:**

| Layer                                                               | Logs?                       | What to log                                                                                                                                                              |
| ------------------------------------------------------------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Services & Datasources (`lib/services/`, `lib/data/**/datasource/`) | Yes                         | Raw I/O failures — `ProcessException`, Dio errors, `FileSystemException`, security-guard rejections (`sLog`)                                                             |
| Notifiers (`*Actions`, `*Notifier`)                                 | Yes                         | Caught exceptions being turned into `AsyncError` or swallowed; semantic operation failures ("pushToRemote failed")                                                       |
| Widgets / screens                                                   | **No, with two exceptions** | (1) `AsyncValue.when(error:)` branches that render an error view, (2) widget-layer APIs the arch rule permits in widgets — `launchUrl` failures and `Clipboard` failures |

Log **once**, at the layer that holds the useful context. If a service already `dLog`s a `ProcessException`, the notifier rethrowing it should not log again — it should only log if it's doing additional recovery worth tracing.

Never `dLog` raw HTTP headers, tokens, or response bodies — see [github_service.dart](lib/services/github/github_service.dart) for the GitHub PAT redaction pattern.

## Code Comments

Default to **no comments**. Add one only when the **WHY** is non-obvious — a hidden constraint, a subtle invariant, a workaround for a specific bug, or behaviour that would surprise a reader.

**Remove or never write:**
- Comments that explain WHAT the code does (well-named identifiers already do this)
- Comments that reference callers, tasks, or issues ("used by X", "added for Y flow", "see issue #123")
- File-header comments that repeat the file path (`// lib/path/to/file.dart`)
- Section-header dividers (`// ── Label ──`) in widget build methods
- Doc comments on private helpers that only restate the method name

**Keep, at most 1 line:**
- Non-obvious ordering invariants ("must assign state before invalidating — invalidation cascades into build()")
- Race-condition guards ("cancel in-flight poll before starting a new one")
- Security constraints ("only log `e.runtimeType` — `$e` serialises the Authorization header")
- Linter-suppress directives (`// ignore: unnecessary_statements`) — always keep; add a trailing inline comment only when the suppressed statement needs explanation

**Multi-line comments:** trim to 1 line. If the WHY cannot be expressed in one line, the constraint probably belongs in a commit message or PR description instead.

## macOS notes

App Sandbox is intentionally **disabled** — services shell out to external binaries. Before changing `macos/Runner/*.entitlements` or any process-execution service, read [macos/Runner/README.md](macos/Runner/README.md) for the threat model and contributor rules (no `runInShell: true` except the documented `bash_datasource_process.dart` case; no PAT header logging).

## Brainstorming Options

When presenting multiple-choice options (A/B/C etc.) during brainstorming:

- Always include a short concrete example for each option
- Always mark the recommended option with a ★ symbol
- If the options involve UI (layouts, components, interactions), always show a visual mockup in the browser companion without waiting to be asked

## Pull Requests

`gh pr create` auto-uses [`.github/pull_request_template.md`](.github/pull_request_template.md). When asked for a PR summary (not creating), output the same template wrapped in a markdown code block so it's copyable.
