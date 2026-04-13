# Full Clean Architecture — Service Layer Design

**Status:** Draft
**Date:** 2026-04-13
**Predecessor:** `2026-04-13-services-hybrid-di-migration.md` (Phase 1 — collapses services into repositories)
**Successor:** Implementation plan to be written after this spec is approved

## Goal

Introduce a dedicated **Service** layer between Notifiers and Repositories, restoring strict Clean Architecture separation:

- **Notifiers** become ViewModels: own `AsyncValue<*>` state and map exceptions to UI-facing `*Failure` types. No business rules, no orchestration.
- **Services** own all business logic: policy enforcement, composition across repositories, derived values, domain exceptions.
- **Repositories** are stripped to domain-scoped I/O facades with no policy.
- **Datasources** are unchanged — single-technology I/O primitives.

## Motivation

After Phase 1 (services → repositories migration), business logic ended up co-located with I/O. `ApplyRepositoryImpl.applyChange` performs six distinct responsibilities: security validation, size policy, file read, file write, checksum computation, UUID generation. Similar accumulation exists in `GitRepositoryImpl` (16 public methods including retry/parse composition), `AIRepositoryImpl` (stream buffering for `sendMessage`), and `SettingsActions.wipeAllData` (4-step cascade in the notifier).

Two forces pull business logic into the wrong layers today:

1. **Up from repositories/datasources** — policy and composition live alongside I/O.
2. **Down from notifiers/actions** — multi-repository orchestration lives in UI controllers.

This refactor introduces a service layer to absorb both.

## Target architecture

```
Widgets / Screens
      ↓  (ref.watch / ref.read notifier)
  Notifiers (ViewModels)           ← UI state only; no business rules
      ↓  (ref.read service)
  Services (Use Cases)             ← business rules; orchestration
      ↓  (ref.read repository)
  Repositories                     ← domain-scoped I/O facades
      ↓
  Datasources                      ← Dio, Drift, Process, dart:io
      ↓
 External (API / SQLite / OS)
```

### Hard dependency rules (enforced in code review + arch test)

| Layer | May call | May NOT call |
|-------|----------|-------------|
| Widget | Notifier | Service, Repository, Datasource |
| Notifier | Service | Repository, Datasource |
| Service | Repository, other Service | Datasource directly (except through its feature's Repository) |
| Repository | Datasource, **`FilesystemRepository` (only)** | Service, Notifier, any other Repository |
| Datasource | External | Anything else in `lib/` |

**Cross-repository exception — `FilesystemRepository`.** `FilesystemRepository` is a shared I/O primitive exposing `readFile`, `writeFile`, `createFile`, `listDirectory`, `watchDirectory`, `detectLanguage`, and related helpers. Today only `ApplyRepositoryImpl` depends on it; that dependency is preserved after the refactor. This is the only sanctioned repository-to-repository call — all other repositories talk exclusively to their datasources. The arch test allowlists `lib/data/filesystem/repository/` imports from `lib/data/apply/repository/`.

**New arch-test invariants:**

- `ref.read(*RepositoryProvider)` inside `lib/features/**/notifiers/**` → test failure.
- Imports from `lib/features/**` inside `lib/services/**` → test failure.
- Imports from `lib/services/**` inside `lib/data/**` → test failure.

## Layer contracts

### Notifiers (`*Actions`, `*Notifier`)

**Own:** `AsyncValue<void>` loading state, domain-exception-to-`*Failure` mapping, `ref.listen` targets for widgets.
**Do not:** sequence repository calls, enforce policy, compute derived values, validate inputs, import from `lib/data/`.

### Services (`*Service`)

**Own:** business rules, policy enforcement (size caps, path validation, auth checks), composition across repositories and other services, domain exceptions, derived value computation (checksums, UUIDs, buffered streams).
**Do not:** construct `AsyncValue`, emit UI state, import anything from `lib/features/`, hold `Ref` as a field.

### Repositories (`*Repository`)

**Own:** domain-named I/O methods (`readFile`, `listBranches`, `insertProject`), datasource selection (e.g., picking a per-provider `*DatasourceDio`).
**Do not:** validate inputs, enforce policy, compose multi-step workflows, translate raw exceptions into domain exceptions.

### Datasources (`*Datasource*`)

**Own:** single-technology I/O via Dio, Drift, `Process.run`, or `dart:io`.
**Do not:** anything above.

## File structure and naming

```
lib/
  services/
    <feature>/
      <feature>_service.dart           ← class {Feature}Service
      <feature>_service.g.dart
      <feature>_exceptions.dart        ← domain exceptions (sealed hierarchy)
  data/
    <feature>/
      repository/                      ← stripped to I/O + delegation
      datasource/                      ← unchanged
  features/
    <feature>/
      notifiers/                       ← thinned to ViewModel duties
      widgets/                         ← unchanged
```

### Naming rules

- Service class: `{Feature}Service` (e.g., `ApplyService`, `GitService`).
- Service provider: `@Riverpod(keepAlive: true) {Feature}Service {feature}Service(Ref ref) => ...`.
- Domain exceptions: `{Feature}Exception` base + specific subclasses in `{feature}_exceptions.dart`. Never prefix with service name (`ApplyTooLargeException`, not `ApplyServiceTooLargeException`).
- Service dependencies: the feature's own `Repository` interface(s) and other `Service`s when orchestration requires it.

## Dependency injection

Services follow the hybrid DI pattern already used for repositories: constructor injection on the class, `@Riverpod` provider function does the wiring. `Ref` is never stored on the service.

### Baseline

```dart
// lib/services/apply/apply_service.dart
@Riverpod(keepAlive: true)
ApplyService applyService(Ref ref) {
  return ApplyService(repo: ref.watch(applyRepositoryProvider));
}

class ApplyService {
  ApplyService({required ApplyRepository repo}) : _repo = repo;
  final ApplyRepository _repo;

  Future<AppliedChange> applyChange({...}) async { ... }
}
```

### Service-to-service composition

```dart
@Riverpod(keepAlive: true)
ProjectService projectService(Ref ref) {
  return ProjectService(
    repo: ref.watch(projectRepositoryProvider),
    sessions: ref.watch(sessionServiceProvider),
  );
}
```

### Async dependencies

When a repository is exposed as `Future<T>` (e.g., `aiRepositoryProvider` reads secure storage during construction):

```dart
@Riverpod(keepAlive: true)
Future<AIService> aiService(Ref ref) async {
  final repo = await ref.watch(aiRepositoryProvider.future);
  return AIService(repo: repo);
}
```

Callers then:

```dart
await ref.read(applyServiceProvider).applyChange(...);
await (await ref.read(aiServiceProvider.future)).sendMessage(...);
```

### Cycles

Services may not transitively depend on themselves. Enforced by convention + code review; Riverpod would deadlock on circular `keepAlive` providers if introduced.

**Orchestration ownership rule of thumb:** when orchestration touches two or more services' domains, it lives on the "outer" service — the one closer to the user-initiated action. Example: `ProjectService.archiveProject` owns session archival because archive-project is a project-initiated action.

## Error handling

Three-layer flow; one translation per boundary.

```
Datasource        →  throws raw:      DioException, ProcessException, FileSystemException
                                      (or swallows + returns sentinel for boolean probes)
Repository        →  passes raw through; no domain exception translation here
Service           →  catches raw, throws domain:
                                      ProjectMissingException, ApplyTooLargeException,
                                      GitAuthException, PathEscapeException
                     — owns all `sLog` security events and `dLog` I/O-failure logs
Notifier          →  catches domain, maps to UI: CodeApplyFailure.projectMissing() etc.
                     — owns the sealed *Failure union
Widget            →  switch on *Failure, render error
```

### Domain exceptions

Each feature's domain exceptions live in `lib/services/<feature>/<feature>_exceptions.dart` as a sealed hierarchy. Existing exceptions (`ProjectMissingException`, `GitAuthException`, `GitConflictException`, `GitNoUpstreamException`, `DuplicateProjectPathException`, `StorageException`) **relocate** to their service's exception file. New ones (`ApplyTooLargeException`, `PathEscapeException`) are created at implementation time.

### Concrete example

```dart
// lib/services/apply/apply_exceptions.dart
sealed class ApplyException implements Exception {}
class ProjectMissingException extends ApplyException { ... }
class ApplyTooLargeException extends ApplyException { ... }
class PathEscapeException extends ApplyException { ... }

// lib/services/apply/apply_service.dart
Future<AppliedChange> applyChange({...}) async {
  _assertWithinProject(filePath, projectPath); // throws PathEscapeException
  if (newContent.length > kMax) throw ApplyTooLargeException(newContent.length);
  String? original;
  try {
    original = await _repo.readFile(filePath);
  } on FileSystemException catch (e, st) {
    dLog('[ApplyService] readFile failed: $e');
    if (e is PathNotFoundException) {
      original = null;
    } else {
      Error.throwWithStackTrace(ProjectMissingException(projectPath), st);
    }
  }
  await _repo.writeFile(filePath, newContent);
  return AppliedChange(
    id: _uuidGen(),
    checksum: _sha256(newContent),
    originalContent: original,
    ...
  );
}

// lib/features/chat/notifiers/code_apply_actions.dart
ApplyFailure _asFailure(Object e) => switch (e) {
  PathEscapeException()     => const ApplyFailure.pathEscape(),
  ApplyTooLargeException()  => const ApplyFailure.tooLarge(),
  ProjectMissingException() => const ApplyFailure.projectMissing(),
  _                         => ApplyFailure.unknown(e),
};

Future<void> applyChange({...}) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      final change = await ref.read(applyServiceProvider).applyChange(...);
      ref.read(appliedChangesProvider.notifier).apply(change);
    } catch (e, st) {
      Error.throwWithStackTrace(_asFailure(e), st);
    }
  });
}
```

### Logging responsibility

- `sLog` for security events → **service** (it owns policy).
- `dLog` for I/O failures being caught-and-translated → **service** at the catch site.
- Notifier does **not** `dLog` — the service already did. Exception: the notifier may `dLog` inside its `_asFailure` if the exception carried information worth preserving beyond the `*Failure` variant.

## Testing strategy

### Service tests — `test/services/<feature>/<feature>_service_test.dart`

The heaviest test layer. Two patterns:

- **Integration-style** for services that do real filesystem/process work — use real `FilesystemDatasourceIo`, real `tmp_dir`, stub the process runner. Matches the existing shape of `apply_service_test.dart` (which becomes the template for the new `ApplyService` tests).
- **Unit-style** for pure orchestration — fake the repository via `extends Fake implements ApplyRepository`. No need to add abstract interfaces to `ApplyService` itself; the concrete class is used as the "interface" for `extends Fake implements ApplyService`.

Every domain exception gets a test. Every policy decision (size cap, path escape) gets a test.

### Notifier tests — `test/features/<feature>/notifiers/<notifier>_test.dart`

Substantially thinner than today. Fake the service. Focus on:

- `AsyncValue` transitions (`AsyncLoading` → `AsyncData`/`AsyncError`).
- Exception-to-`*Failure` mapping for every branch of `_asFailure`.
- `ref.listen` trigger correctness.

Business logic tests move down to the service layer, so notifier test files generally shrink.

### Repository tests — `test/data/<feature>/repository/<repo>_test.dart`

Minimal. Keep only where the repository has non-trivial delegation logic — for example, `AIRepositoryImpl._source(provider)` picking per-provider datasources warrants a test; `ApplyRepositoryImpl.readFile` delegating to `FilesystemDatasourceIo` does not.

### Arch tests — `test/arch_test.dart`

Extend existing import-grep arch tests with the new invariants listed under **Hard dependency rules**.

## Per-feature migration scope

Nine services to create. All landing in a single PR (big-bang).

| # | Service | Current repo (strips to I/O) | Orchestration moving up | Domain exceptions |
|---|---|---|---|---|
| 1 | `ApplyService` | `ApplyRepository` | path validation, 1 MB cap, checksum, UUID gen, applied-change construction | `ProjectMissingException` (exists, relocate), `ApplyTooLargeException` (new), `PathEscapeException` (new) |
| 2 | `GitService` | `GitRepository` | retry/parse on push/pull/fetch, worktree enumeration, branch filtering, commit/checkout/createBranch composition | `GitAuthException`, `GitConflictException`, `GitNoUpstreamException` (all exist, relocate) |
| 3 | `ProjectService` | `ProjectRepository` | duplicate-path detection, relocate logic, archive cascade, file-scan orchestration | `DuplicateProjectPathException` (exists, relocate), `ProjectFileScanFailure` (exists, relocate) |
| 4 | `SessionService` | `SessionRepository` | session + message cascade delete, archival semantics, `sendAndStream` orchestration | none dedicated — notifier continues to map raw `StateError` / I/O failures to existing `*Failure` variants |
| 5 | `SettingsService` | `SettingsRepository` | `wipeAllData` cascade (moves from `SettingsActions`), onboarding state machine | `StorageException` (exists, relocate) |
| 6 | `AIService` | `AIRepository` | stream buffering (`sendMessage`), provider selection, system prompt assembly | no new exceptions — reuses `ProjectMissingException` (shared with Apply); raw `StateError` / `FileSystemException` pass through to notifier `_asFailure` |
| 7 | `GitHubService` | `GitHubRepository` (file: `lib/data/github/repository/github_repository.dart`) | PAT redaction, rate-limit handling, create-PR orchestration | none — notifier continues to map via existing `CreatePrFailure` union (`notAuthenticated` / `network` / `permissionDenied`) |
| 8 | `IdeService` | `IdeLaunchRepository` (file: `lib/data/ide/repository/ide_launch_repository.dart`) | editor detection, launch sequencing | `IdeLaunchFailedException` (new) |
| 9 | `ApiKeyTestService` | `ApiKeyTestRepository` | thin passthrough (rule: every notifier-backed feature gets a service) | none — passthrough returns `false` on failure |

### Expected file-size shifts

**Shrinks:**

| File | Today | After | Change |
|---|---|---|---|
| `ApplyRepositoryImpl` | ~200 lines | ~50 lines | **~75% smaller** |
| `GitRepositoryImpl` | ~400 lines | ~200 lines | **~50% smaller** |
| `AIRepositoryImpl` | ~95 lines | ~70 lines | **~25% smaller** |
| `SettingsActions.wipeAllData` | ~30 lines in notifier | 1 line (delegate to service) | large shrink |
| Repository test files | | | **~60% smaller** (less logic to test) |
| Notifier test files | | | **~30% smaller** (logic tests move to service) |

**Repository interfaces lose methods** — e.g., `ApplyRepository` drops `applyChange`, `revertChange`, `readOriginalForDiff`, `isExternallyModified`, `assertWithinProject`, `sha256OfString`; keeps `readFile`, `writeFile`, `deleteFile`, `gitCheckout`.

### GitRepository method split

Of the 16 public methods on `GitRepositoryImpl` today, 4 are primitives (single `git` invocation, no retry or parse logic) and stay on the thinned `GitRepository`; the remaining 12 are compositions that move to `GitService`.

**Stays on `GitRepository` (primitives):**

- `initGit(String path)`
- `currentBranch(String path)`
- `getOriginUrl(String path)`
- `isGitRepo(String path)`

**Moves to `GitService` (compositions, retry/parse, cross-method orchestration):**

- `commit`, `push`, `pushToRemote`, `pull`
- `fetchBehindCount`, `behindCount`, `fetchLiveState`
- `listRemotes`, `listLocalBranches`, `worktreeBranches`
- `checkout`, `createBranch`

The service calls into the thinned `GitRepository` for primitives and into `GitDatasource`-adjacent primitives (via the repository) for single-shot shell invocations it composes. All retry, output parsing, and multi-call sequencing lives in the service.

### ApplyRepositoryImpl — keep `FilesystemRepository` dependency

After the I/O split, `ApplyRepositoryImpl` continues to depend on `FilesystemRepository` (not `FilesystemDatasource`). This is the single sanctioned cross-repository call, documented under "Cross-repository exception" in the dependency-rule table above.

**Added:**

- `+9` new service files (`lib/services/<feature>/<feature>_service.dart`).
- `+~6` new exception files (where domain exceptions exist — a few features have none).
- `+9` new service test files.

**Net line count:** roughly flat (maybe +5–10%); distribution improves significantly. Each file has fewer reasons to change.

## Worktree and branching strategy

Phase 1 (`tech/2026-04-13-services-hybrid-di-migration`) lands first as its own PR.

This refactor goes into a **new worktree** branched from `main` after Phase 1 merges:

```
git worktree add .worktrees/tech/YYYY-MM-DD-full-clean-architecture-services \
  -b tech/YYYY-MM-DD-full-clean-architecture-services
```

Date rolls to whatever day implementation starts.

## Non-goals

- **Moving repository interfaces to a `lib/domain/` folder.** The Clean Architecture vocabulary move (`lib/data/<f>/repository/` → `lib/domain/<f>/repository/`) is deliberately out of scope. If later decided, it's a separate refactor that doesn't block or invalidate this one.
- **Introducing `Result<T, E>` / `Either` error handling.** We stay with exceptions + `AsyncValue.guard` (Rejected Option B under error handling).
- **Per-use-case classes (`ApplyChangeUseCase`, `RevertChangeUseCase`).** We chose the hybrid-granularity model: one service per feature, each public method conceptually a discrete use case (Accepted Option C under granularity).
- **Collapsing domain repositories into technology-scoped ones (`FilesystemRepository` + `ProcessRepository` only).** Domain-scoped repositories remain (Accepted Option A under repository shape; Rejected Option B).

## Rollback safety

If partway through review the shape is wrong, the entire PR can be reverted and the codebase returns to the Phase 1 target state. The Phase 1 branch remains merged; this refactor is additive on top and cleanly removable.

## Open questions for implementation-plan phase

None at the spec level. The four items originally deferred are resolved inline:

- **Method signatures** — derived mechanically from current `*RepositoryImpl` at implementation time; the per-feature migration table above is authoritative for *which* orchestration moves.
- **Domain exceptions** — resolved per-row in the migration table (Session: none; AI: none, reuses `ProjectMissingException`; GitHub: none, stays on notifier via `CreatePrFailure`; IDE: new `IdeLaunchFailedException`).
- **`ApplyRepositoryImpl._fs` dependency** — keeps `FilesystemRepository`; documented under the dependency-rule table and the "ApplyRepositoryImpl — keep `FilesystemRepository` dependency" subsection.
- **`GitRepository` shape** — resolved in "GitRepository method split": 4 primitives stay, 12 compositions move to `GitService`.

Anything remaining (import reshuffling, test-file reorganization, exact `build_runner` sequence) is mechanical and surfaces naturally during plan authoring.
