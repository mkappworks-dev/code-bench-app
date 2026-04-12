# Widget → Notifier → Service Architecture: Error-Handling Completion

**Date:** 2026-04-12
**Branch:** `tech/2026-04-12-widget-notifier-service-arch`
**Status:** Approved — ready for implementation planning

## Context

The worktree has landed 16 refactor commits that enforce a layered architecture:

```
Widgets / Screens
      ↓  (ref.watch / ref.read notifier)
  Notifiers          ← the only layer widgets may reach
      ↓  (ref.read service)
  Services           ← Dio, DB, Process.run, filesystem live here
```

Achieved so far (worktree state, 2026-04-12):

- Widget-level `ref.invalidate` eliminated from `lib/features` — all routed through notifier methods.
- Direct service-provider reads, `Process.run`, `Directory(...)`, `File(...)` in widgets: effectively zero.
- Extracted command notifiers: `CodeApplyActions`, `CreatePrActions`, `PrNotifier`, `ProjectFileScanActions`, `AskQuestionNotifier`, `GitActions`, `IdeLaunchActions`, `ActionOutputNotifier`.
- Architectural rules (dependency graph, `Actions` vs `Notifier` suffix, logging matrix) codified in the worktree's `CLAUDE.md`.

What remains:

- **56 try/catch blocks across 11 widgets.** Hot spots: `message_bubble.dart` (9), `github_step.dart` (9), `changes_panel.dart` (7), `pr_card.dart` (7), `branch_picker_popover.dart` (7), plus smaller clusters in `api_keys_step`, `add_project_step`, `remove_project_dialog`, `chat_input_bar`, `relocate_project_dialog`, `message_list`.
- **Rethrow-heavy notifiers.** Extracted Actions classes currently catch → `dLog` → `rethrow`, pushing the try/catch pain back onto widgets (see `lib/features/chat/notifiers/code_apply_actions.dart`).

This spec closes the remaining gap: widgets become pure state-renderers, notifiers own failure as typed `AsyncValue` state, and the rules are documented for future contributors.

## Goal

Widgets never catch service exceptions, never own loading booleans, and never introspect exception types. Errors flow up as typed `AsyncValue` state from notifiers. Behavior is functionally equivalent to today — no UX changes; only the plumbing moves.

## Design decisions

### 1. Widget try/catch policy

**Forbidden** around any business-logic call — service calls, notifier method calls, or any async work that touches I/O.

**Permitted** only around widget-layer APIs already carved out in the logging matrix: `launchUrl`, `Clipboard.setData`, `Clipboard.getData`. Their failures are widget-layer concerns (the user clicked a button that the OS couldn't handle) and don't need to flow through a notifier.

Enforcement: code-review grep for `try\s*\{` under `lib/features/**/widgets/**`. Any match must wrap a `launchUrl` or `Clipboard` call.

**Alternatives considered:**

- *Forbid all try/catch in widgets.* Rejected — would require wrapping every `Clipboard.setData` call in a throwaway notifier, which is ceremony without benefit.
- *Only forbid try/catch around `.notifier`/service calls.* Rejected — too loose; the carve-out would silently expand to cover "my async thing."

### 2. Actions-notifier shape

Every command notifier (`*Actions` suffix) extends `AsyncNotifier<void>`:

```dart
@Riverpod(keepAlive: true)
class CodeApplyActions extends _$CodeApplyActions {
  @override
  FutureOr<void> build() {} // AsyncData<void>

  Future<void> applyChange({ required ... }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(applyServiceProvider).applyChange(...);
      } catch (e, st) {
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
```

Widgets read:

- Loading: `ref.watch(codeApplyActionsProvider).isLoading` drives button spinners.
- Success/failure side effects: `ref.listen(codeApplyActionsProvider, (prev, next) { ... })` drives snackbars, dialogs, navigation.

**Limitation — "second call overwrites first's state."** A single `AsyncValue<void>` slot per notifier means if two invocations are in flight simultaneously, only the latter's result is visible. Accepted as-is for the initial migration because every Actions notifier in this codebase today is user-initiated and sequential. Revisit at end of migration — see *Follow-ups* below.

**Alternatives considered:**

- *`Future<AsyncValue<T>>` return type (method-level Result pattern).* Rejected — not idiomatic Riverpod, abandons the reactive state model, forces widgets to keep local `bool _loading` state.
- *`family` provider per operation (per-file, per-project, etc.).* Rejected as default — heavy ceremony, unbounded key growth with `keepAlive: true`. Kept as targeted escalation path for proven concurrency.

### 3. Typed failure unions

Each Actions notifier owns a `freezed` sealed class named `{Notifier}Failure`:

```dart
@freezed
sealed class CodeApplyFailure with _$CodeApplyFailure {
  const factory CodeApplyFailure.projectMissing({ required String projectId }) = _ProjectMissing;
  const factory CodeApplyFailure.outsideProject(String path) = _OutsideProject;
  const factory CodeApplyFailure.diskWrite(String message) = _DiskWrite;
  const factory CodeApplyFailure.unknown(Object error) = _Unknown;
}
```

The notifier's private `_asFailure(Object e)` helper maps raw exceptions (`ProjectMissingException`, `StateError`, `FileSystemException`, else) to the variants. Widgets then do:

```dart
ref.listen(codeApplyActionsProvider, (prev, next) {
  if (next is! AsyncError) return;
  final failure = next.error;
  if (failure is! CodeApplyFailure) return;
  switch (failure) {
    case _ProjectMissing(): showSnackbar('Project folder was moved or deleted'); break;
    case _OutsideProject(): showSnackbar('Refusing to write outside project'); break;
    case _DiskWrite(:final message): showSnackbar('Write failed: $message'); break;
    case _Unknown(): showSnackbar('Failed to apply change'); break;
  }
});
```

Benefits:

- Widgets never `import` from `lib/services/` for exception types.
- Exhaustive `switch` makes "did you forget a variant?" a compile error.
- Failure variants that need non-snackbar UX (e.g. `ProjectMissing` also triggers a sidebar refresh) stay cleanly dispatchable without introspection.

**Alternatives considered:**

- *`String? errorMessage` helper on notifier.* Rejected — loses typed dispatch; the moment one failure needs non-snackbar UX, you're back to introspection.
- *Raw exceptions, widget type-checks with `if (e is X)`.* Rejected — forces widgets to import service-layer exception types, violating the dependency rule.

### 4. State notifiers (`*Notifier` suffix)

No structural change. `ChatNotifier`, `GitHubAuthNotifier`, `BranchPickerNotifier`, etc. already own `AsyncValue<T>` over their data. Where they currently `rethrow` to widgets, replace with the same failure-union-based state transition used by Actions notifiers.

## In-scope notifiers (12)

Each gets its own `{Name}Failure` sealed class + variants:

| Notifier | Shape change | File |
|---|---|---|
| `CodeApplyActions` | rethrow → AsyncNotifier<void> | `lib/features/chat/notifiers/code_apply_actions.dart` |
| `CreatePrActions` | rethrow → AsyncNotifier<void> | `lib/features/chat/notifiers/create_pr_actions.dart` |
| `PrNotifier` | rethrow → failure-union state | `lib/features/chat/notifiers/pr_notifier.dart` |
| `ProjectFileScanActions` | rethrow → AsyncNotifier<void> | `lib/features/chat/notifiers/project_file_scan_actions.dart` |
| `AskQuestionNotifier` | rethrow → failure-union state | `lib/features/chat/notifiers/ask_question_notifier.dart` |
| `GitActions` | rethrow → AsyncNotifier<void> | `lib/shell/notifiers/git_actions.dart` |
| `IdeLaunchActions` | rethrow → AsyncNotifier<void> | `lib/shell/notifiers/ide_launch_actions.dart` |
| `ActionOutputNotifier` | rethrow → failure-union state | `lib/shell/notifiers/action_output_notifier.dart` |
| `OnboardingNotifier` | rethrow → failure-union state | `lib/features/onboarding/notifiers/onboarding_notifier.dart` |
| `ProjectSidebarActions` | rethrow → AsyncNotifier<void> | `lib/features/project_sidebar/project_sidebar_actions.dart` |
| `ChatNotifier` | rethrow → failure-union state | `lib/features/chat/chat_notifier.dart` |
| `BranchPickerNotifier` | rethrow → failure-union state | `lib/features/branch_picker/branch_picker_notifier.dart` |

## In-scope widgets (11)

Remove try/catch around business calls; replace with `ref.listen` + `isLoading` reads. Keep try/catch only around `launchUrl` / `Clipboard`.

| Widget | try/catch to remove |
|---|---|
| `lib/features/chat/widgets/message_bubble.dart` | 9 |
| `lib/features/onboarding/widgets/github_step.dart` | 9 (minus launchUrl) |
| `lib/features/chat/widgets/changes_panel.dart` | 7 |
| `lib/features/chat/widgets/pr_card.dart` | 7 (minus launchUrl/Clipboard) |
| `lib/features/branch_picker/widgets/branch_picker_popover.dart` | 7 |
| `lib/features/onboarding/widgets/api_keys_step.dart` | 4 |
| `lib/features/onboarding/widgets/add_project_step.dart` | 4 |
| `lib/features/project_sidebar/widgets/remove_project_dialog.dart` | 4 |
| `lib/features/chat/widgets/chat_input_bar.dart` | 2 |
| `lib/features/project_sidebar/widgets/relocate_project_dialog.dart` | 2 |
| `lib/features/chat/widgets/message_list.dart` | 1 |

## Testing

Full failure-branch coverage per notifier. For each of the 12 notifiers:

- One happy-path test (service resolves → state becomes `AsyncData`).
- One test per failure variant (service throws X → state becomes `AsyncError(Failure.y)` with the expected fields).
- One test per side effect beyond snackbar — e.g. `CodeApplyFailure.projectMissing` triggers `ProjectSidebarActions.refreshProjectStatus` — asserted via a mock that records the call.

Estimate: ~30–40 new test cases across existing `test/` trees, colocated with the existing notifier tests.

## Documentation

**1. Extend the worktree's `CLAUDE.md`.** Add a new section *"Error Handling & State Emission"* covering:

- Widget try/catch policy (rule 1) with do/don't snippets.
- Actions-notifier shape (rule 2) with the `AsyncNotifier<void>` + `AsyncValue.guard` template.
- Failure-union convention (rule 3) with the sealed class naming rule and the exhaustive-switch example.
- Links from each rule to an in-repo canonical example notifier and widget.

**2. Update the root `README.md` Architecture section.** Add a brief *"Layered architecture"* subsection describing Widget → Notifier → Service, its enforcement, and a pointer to `CLAUDE.md` for the full rules. README stays high-level; CLAUDE.md stays canonical.

## Delivery

Single PR out of this worktree. Internal commit sequence:

1. Extend `CLAUDE.md` with the new rules (docs-first anchor for reviewers).
2. Add failure unions + migrate Actions notifiers to `AsyncNotifier<void>`.
3. Migrate widgets to `ref.listen` / `AsyncValue` watching; remove try/catch.
4. Add/update notifier tests covering every failure variant and side effect.
5. Update `README.md` Architecture section.
6. Re-run `build_runner --delete-conflicting-outputs`; commit generated files alongside their source.

## Out of scope

- No changes to services (`lib/services/**`).
- No changes to the Drift schema.
- No UX redesign of error presentation — snackbars stay snackbars, dialogs stay dialogs.
- No new features; zero behavior change for success paths; failure paths functionally equivalent but driven by typed state.
- Family-provider escalation — see *Follow-ups*.

## Follow-ups (post-merge)

- **Revisit `CodeApplyActions` and `ProjectFileScanActions` for potential `family` escalation.** If either has a real parallel-invocation path (bulk apply across multiple files, parallel project scans), promote just that one to a `family`-keyed AsyncNotifier. Until a concrete collision is observed or a bulk-apply feature is shipped, keep the single-slot form. Rationale: YAGNI, plus migrating A→C is mechanical; going C→A is hard once call sites depend on per-key state.
- **Localization seam.** Widgets now hold the failure-variant → message-string map. If/when `AppLocalizations` is introduced, the mapping is the only widget-side change; notifiers stay language-agnostic.

## Consequences

- New failure unions introduce ~12 small freezed types to maintain. Adding a service exception requires adding a variant and updating the notifier's `_asFailure`. Trade-off accepted — compile-time exhaustiveness is worth the bookkeeping.
- `AsyncNotifier<void>` state is shared per notifier, so fast-double-tap collisions on the same button can mask the first error. Accepted; revisit per *Follow-ups* if QA surfaces real cases.
- `ref.listen` + `isLoading` becomes the dominant widget pattern for commands. Code reviewers should reject new widgets that try to drive command UX via local `bool _loading` or try/catch.
