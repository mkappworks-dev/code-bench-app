# Phase 10 — `ToolEvent.status` + `id` (kill the eternal spinner)

**Date:** 2026-04-11
**Type:** `tech/` (model refactor + bug fix)
**Worktree:** `.worktrees/tech/2026-04-11-phase10-tool-event-status-and-id`
**Branch:** `tech/2026-04-11-phase10-tool-event-status-and-id`
**Depends on:** Phase 6 (`feat/2026-04-10-phase6-agentic-tool-use`) — must be merged to `main` first so this branches off the `ToolEvent` model Phase 6 introduced.

---

## Motivation

The review of the Phase 6 PR (see `docs/superpowers/reviews/2026-04-11-phase6-review.md` if captured) flagged **M4 — the eternal-spinner bug** in `tool_call_row.dart:47`:

```dart
final isRunning = widget.event.durationMs == null && widget.event.output == null;
```

This infers "is this tool still running?" from the absence of two unrelated optional fields. That breaks in three real scenarios:

1. **Silent failure path.** A tool invocation raises before `output` is set and before `durationMs` is computed → the row sticks on a spinner forever. The Phase 6 PR shipped a tooltip mitigation (`tool_call_row.dart:95-98`) that covers the *durationMs present, output null* case only. The *nothing-written-at-all* case is still an eternal spinner.
2. **Cancelled tool call.** A user-cancelled or model-interrupted tool has no natural "terminal but no output" encoding.
3. **Zero-output success.** A tool that legitimately returns an empty string is indistinguishable from failure.

The root cause is that `ToolEvent` encodes state via field presence rather than an explicit `status`. Adding a typed `ToolStatus` enum makes the lifecycle explicit and unblocks the Phase 7 rework (see the cross-reference section below).

Secondary motivation: Phase 7 as currently drafted introduces a parallel `WorkLogEntry` state machine with its own `{ running, done, failed }` enum. With `ToolEvent.status` in place, Phase 7 can render `message.toolEvents` directly and drop the duplicate model. Phase 10 is a prerequisite for that simplification.

## Architecture

`ToolEvent` gains three fields:

| Field     | Type                       | Nullable | Purpose |
| --------- | -------------------------- | -------- | ------- |
| `id`      | `String`                   | no       | Stable identity for an emission — lets the emitter update a running event into a completed event without ambiguity when the same tool is called twice. Mirrors `provider_request_id` from AI tool-use blocks when available; otherwise UUID v4. |
| `status`  | `ToolStatus` (enum)        | no       | Explicit lifecycle: `running` / `success` / `error` / `cancelled`. Default on construction is `running`. |
| `error`   | `String?`                  | yes      | Short human-readable error message set when `status == error`. Never leak PAT / secrets — emitters log `runtimeType` and pass a scrubbed summary. |

Because the app is **not yet released** (see memory `project_release_status.md`), existing chat DB rows with old `ToolEvent` JSON can be migrated by best-effort inference in `fromJson` rather than via a Drift migration — see Task 2 step 2.3. That keeps this phase self-contained.

**The model becomes the single source of truth.** No parallel notifiers, no derived-state helpers. `tool_call_row.dart` switches on `event.status`, not on field presence.

### What's intentionally NOT in this plan

- **No new emitters.** As of the Phase 6 merge, nothing in `lib/` constructs a `ToolEvent` in production code (only the test file and the `fromJson` path do). Wiring emitters is Phase 11 territory (or folded into the Phase 7 tool-use pipeline work). This plan only makes the model ready.
- **No WorkLogEntry deletion.** Phase 7 hasn't shipped yet. When Phase 7 rebases onto `main` with Phase 10 present, it drops `WorkLogEntry` itself (see `Cross-reference: Phase 7` below).
- **No status bar pill changes.** That's also Phase 7.

## Files

| Action      | Path                                                | Why                                                                  |
| ----------- | --------------------------------------------------- | -------------------------------------------------------------------- |
| Modify      | `lib/data/models/tool_event.dart`                   | Add `id`, `status`, `error` fields; add `ToolStatus` enum             |
| Regenerate  | `lib/data/models/tool_event.freezed.dart`           | Freezed output                                                       |
| Regenerate  | `lib/data/models/tool_event.g.dart`                 | JSON serialization                                                   |
| Regenerate  | `lib/data/models/chat_message.freezed.dart`         | Indirectly — `ChatMessage.toolEvents` shape changes                  |
| Regenerate  | `lib/data/models/chat_message.g.dart`               | Indirectly                                                           |
| Modify      | `lib/features/chat/widgets/tool_call_row.dart`      | Switch on `event.status` instead of inferring from field presence    |
| Modify      | `test/data/models/tool_event_test.dart`             | Cover new fields + status transitions + legacy JSON tolerance        |
| Modify      | `test/features/chat/widgets/tool_call_row_test.dart` (if exists — else create minimal) | Cover each status → icon/color mapping |

## Task list

### Task 1: Add `ToolStatus` enum and new fields to `ToolEvent`

**Files:**
- Modify: `lib/data/models/tool_event.dart`

- [ ] **Step 1.1: Create the worktree**

  ```bash
  git worktree add .worktrees/tech/2026-04-11-phase10-tool-event-status-and-id -b tech/2026-04-11-phase10-tool-event-status-and-id
  cd .worktrees/tech/2026-04-11-phase10-tool-event-status-and-id
  ```

- [ ] **Step 1.2: Replace `lib/data/models/tool_event.dart`**

  Replace the entire file with:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'tool_event.freezed.dart';
  part 'tool_event.g.dart';

  /// Lifecycle of a single tool-use invocation.
  ///
  /// Explicit states replace the Phase-6 "infer from field presence" pattern
  /// (`durationMs == null && output == null`) that caused the eternal-spinner
  /// bug when a tool raised before either field was written.
  ///
  /// Terminal states: [success], [error], [cancelled]. Only [running] shows
  /// a spinner in the UI.
  enum ToolStatus {
    running,
    success,
    error,
    cancelled,
  }

  @freezed
  abstract class ToolEvent with _$ToolEvent {
    const factory ToolEvent({
      /// Stable identity for the emission. Prefer the provider's tool-use
      /// block id when available (Anthropic `tool_use.id`, OpenAI
      /// `tool_call.id`); fall back to a UUID v4. Lets the emitter update a
      /// [running] event into a terminal state without ambiguity when the
      /// model calls the same tool twice in a single turn.
      required String id,
      required String type,
      required String toolName,
      @Default(ToolStatus.running) ToolStatus status,
      @Default({}) Map<String, dynamic> input,
      String? output,
      String? filePath,
      int? durationMs,
      int? tokensIn,
      int? tokensOut,
      /// Short human-readable error summary. Set **only** when [status] is
      /// [ToolStatus.error]. Must not contain secrets — emitters should log
      /// `runtimeType` via `dLog` and pass a scrubbed message here (see the
      /// "no PAT header logging" rule in `macos/Runner/README.md`).
      String? error,
    }) = _ToolEvent;

    factory ToolEvent.fromJson(Map<String, dynamic> json) {
      // Legacy tolerance: pre-Phase-10 chat DB rows have no `id` or `status`.
      // The app is not yet released so there's no production data to migrate,
      // but local dev databases from the Phase 6 branch exist. Infer a
      // plausible status from the old "field presence" rule and mint a UUID
      // for the id so the keyed widget tree stays stable on rebuild.
      //
      // NOTE: this legacy path is intentionally forgiving — it's a
      // one-release bridge. Remove after the next app release if deemed safe.
      final rawJson = Map<String, dynamic>.of(json);
      rawJson['id'] ??= _legacyId();
      if (rawJson['status'] == null) {
        final hasOutput = rawJson['output'] != null;
        final hasDuration = rawJson['durationMs'] != null;
        rawJson['status'] = switch ((hasOutput, hasDuration)) {
          (true, _) => 'success',
          (false, true) => 'error', // finished but no output — treat as error
          (false, false) => 'running', // truly unknown — leave spinner
        }
            .toString();
      }
      return _$ToolEventFromJson(rawJson);
    }
  }

  // Kept as a private top-level fn (not a static) so it stays out of the
  // generated freezed surface. Uses a minimal PRNG-seeded id rather than
  // pulling in the `uuid` package here — legacy ids never round-trip to a
  // provider, so collision resistance is overkill.
  String _legacyId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'legacy-$now';
  }
  ```

  **Why `id` is required even for legacy rows:** widget keying. Flutter's list diffing relies on stable keys — if an old chat message rebuilds and `id` is null for half its tool events, expansion state collapses at random. Minting a legacy id in `fromJson` keeps this invariant.

- [ ] **Step 1.3: Regenerate freezed / json_serializable output**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  This regenerates:
  - `lib/data/models/tool_event.freezed.dart`
  - `lib/data/models/tool_event.g.dart`
  - `lib/data/models/chat_message.freezed.dart` (transitively — `ChatMessage.toolEvents` is `List<ToolEvent>`)
  - `lib/data/models/chat_message.g.dart`

  Expected: build_runner exits 0. Inspect `git status` — only the four `.g.dart` / `.freezed.dart` files above should have changed besides your `tool_event.dart` edit.

- [ ] **Step 1.4: Commit**

  ```bash
  dart format lib/data/models/tool_event.dart
  git add lib/data/models/tool_event.dart \
          lib/data/models/tool_event.freezed.dart \
          lib/data/models/tool_event.g.dart \
          lib/data/models/chat_message.freezed.dart \
          lib/data/models/chat_message.g.dart
  git commit -m "feat(tool_event): add id, status, error fields with legacy fromJson tolerance"
  ```

  **Note on generated files:** per memory `feedback_generated_files.md`, generated `.g.dart` and `.freezed.dart` files are committed together with their source in a single commit.

### Task 2: Tests for the model changes

**Files:**
- Modify: `test/data/models/tool_event_test.dart`

- [ ] **Step 2.1: Extend `test/data/models/tool_event_test.dart`**

  Replace the file with:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/tool_event.dart';

  void main() {
    group('ToolEvent round-trip', () {
      test('serializes and deserializes with all fields', () {
        final event = ToolEvent(
          id: 'tool_01ABC',
          type: 'tool_use',
          toolName: 'read_file',
          status: ToolStatus.success,
          input: {'path': '/foo/bar.dart'},
          output: 'content here',
          filePath: '/foo/bar.dart',
          durationMs: 123,
          tokensIn: 50,
          tokensOut: 10,
        );
        final json = event.toJson();
        final restored = ToolEvent.fromJson(json);
        expect(restored.id, 'tool_01ABC');
        expect(restored.toolName, 'read_file');
        expect(restored.status, ToolStatus.success);
        expect(restored.durationMs, 123);
        expect(restored.input['path'], '/foo/bar.dart');
      });

      test('defaults status to running and serializes cleanly with nulls', () {
        const event = ToolEvent(
          id: 'tool_02',
          type: 'tool_use',
          toolName: 'write_file',
          input: {},
        );
        expect(event.status, ToolStatus.running);
        final json = event.toJson();
        expect(json['output'], isNull);
        expect(json['error'], isNull);
      });

      test('error status carries an error message', () {
        const event = ToolEvent(
          id: 'tool_03',
          type: 'tool_result',
          toolName: 'run_command',
          status: ToolStatus.error,
          error: 'exit code 1',
        );
        final json = event.toJson();
        final restored = ToolEvent.fromJson(json);
        expect(restored.status, ToolStatus.error);
        expect(restored.error, 'exit code 1');
      });

      test('cancelled status round-trips', () {
        const event = ToolEvent(
          id: 'tool_04',
          type: 'tool_use',
          toolName: 'search',
          status: ToolStatus.cancelled,
        );
        final restored = ToolEvent.fromJson(event.toJson());
        expect(restored.status, ToolStatus.cancelled);
      });
    });

    group('ToolEvent legacy fromJson tolerance', () {
      test('legacy JSON with output → status success, minted id', () {
        final legacy = {
          'type': 'tool_use',
          'toolName': 'read_file',
          'input': {'path': 'x'},
          'output': 'ok',
          'durationMs': 50,
        };
        final restored = ToolEvent.fromJson(legacy);
        expect(restored.status, ToolStatus.success);
        expect(restored.id, startsWith('legacy-'));
      });

      test('legacy JSON with durationMs but no output → status error', () {
        final legacy = {
          'type': 'tool_use',
          'toolName': 'run_command',
          'input': {},
          'durationMs': 200,
        };
        final restored = ToolEvent.fromJson(legacy);
        expect(restored.status, ToolStatus.error);
      });

      test('legacy JSON with neither → status running', () {
        final legacy = {
          'type': 'tool_use',
          'toolName': 'bash',
          'input': {},
        };
        final restored = ToolEvent.fromJson(legacy);
        expect(restored.status, ToolStatus.running);
      });
    });
  }
  ```

- [ ] **Step 2.2: Run the tests**

  ```bash
  flutter test test/data/models/tool_event_test.dart
  ```

  Expected: all 7 tests PASS.

- [ ] **Step 2.3: Commit**

  ```bash
  dart format test/data/models/tool_event_test.dart
  git add test/data/models/tool_event_test.dart
  git commit -m "test(tool_event): cover status transitions and legacy fromJson"
  ```

### Task 3: Switch `tool_call_row.dart` to explicit status

**Files:**
- Modify: `lib/features/chat/widgets/tool_call_row.dart`

- [ ] **Step 3.1: Replace the status detection block**

  In `lib/features/chat/widgets/tool_call_row.dart`, find:

  ```dart
  // A tool event is "running" when we have neither a duration nor an
  // output — both are written once the tool returns.
  final isRunning = widget.event.durationMs == null && widget.event.output == null;
  ```

  Replace with:

  ```dart
  // Explicit status replaces the Phase-6 "infer from field presence"
  // heuristic. See Phase 10 plan for the eternal-spinner bug rationale.
  final status = widget.event.status;
  ```

  Then find the trailing-icon conditional (around lines 82–98 in the Phase 6 branch):

  ```dart
  if (isRunning)
    const SizedBox(
      width: 10,
      height: 10,
      child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF4A7CFF)),
    )
  else if (widget.event.output != null)
    const Icon(Icons.check_circle, size: 11, color: Colors.green)
  else
    Tooltip(
      message: '${widget.event.toolName} — no output recorded',
      child: const Icon(Icons.error, size: 11, color: Colors.red),
    ),
  ```

  Replace with:

  ```dart
  switch (status) {
    ToolStatus.running => const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Color(0xFF4A7CFF),
        ),
      ),
    ToolStatus.success => const Icon(Icons.check_circle, size: 11, color: Colors.green),
    ToolStatus.error => Tooltip(
        message: widget.event.error ?? '${widget.event.toolName} — failed',
        child: const Icon(Icons.error, size: 11, color: Colors.red),
      ),
    ToolStatus.cancelled => Tooltip(
        message: '${widget.event.toolName} — cancelled',
        child: const Icon(Icons.cancel_outlined, size: 11, color: Color(0xFF888888)),
      ),
  },
  ```

  **Why a `switch` expression instead of `if/else`:** the compiler enforces exhaustiveness on `ToolStatus`. If someone adds a new status later (e.g. `ToolStatus.timeout`), the build fails in `tool_call_row.dart` instead of falling through to a silent spinner.

- [ ] **Step 3.2: Surface error in the expanded section**

  In the expanded section (around line 166 in the Phase 6 branch), after the `OUTPUT` block, add an `ERROR` block:

  ```dart
  if (widget.event.status == ToolStatus.error && widget.event.error != null) ...[
    const Text(
      'ERROR',
      style: TextStyle(color: Colors.red, fontSize: 9, letterSpacing: 1),
    ),
    const SizedBox(height: 4),
    Text(
      widget.event.error!,
      style: const TextStyle(
        color: ThemeConstants.textPrimary,
        fontSize: 10,
        fontFamily: 'monospace',
      ),
    ),
    const SizedBox(height: 8),
  ],
  ```

- [ ] **Step 3.3: Add the import**

  The enum lives in the same file as the class, so:

  ```dart
  import '../../../data/models/tool_event.dart';
  ```

  is already present — no new import needed. Verify with `flutter analyze`.

- [ ] **Step 3.4: Verify compilation**

  ```bash
  flutter analyze
  ```

  Expected: no errors. If the `switch` expression trips an unreachable-default warning, it means freezed generated a catch-all — delete the offending `default` branch.

- [ ] **Step 3.5: Commit**

  ```bash
  dart format lib/features/chat/widgets/tool_call_row.dart
  git add lib/features/chat/widgets/tool_call_row.dart
  git commit -m "fix(tool_call_row): switch on ToolStatus — kill eternal spinner"
  ```

### Task 4: Widget tests for each status → UI mapping

**Files:**
- Create: `test/features/chat/widgets/tool_call_row_test.dart` (if absent; otherwise modify)

- [ ] **Step 4.1: Check whether a test exists**

  ```bash
  ls test/features/chat/widgets/tool_call_row_test.dart 2>/dev/null || echo "missing"
  ```

  If missing, create it. If present, extend the existing file with the cases below.

- [ ] **Step 4.2: Write the widget tests**

  Create `test/features/chat/widgets/tool_call_row_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/tool_event.dart';
  import 'package:code_bench_app/features/chat/widgets/tool_call_row.dart';

  Widget _host(ToolEvent event) => MaterialApp(
        home: Scaffold(body: ToolCallRow(event: event)),
      );

  void main() {
    testWidgets('running status renders a spinner', (tester) async {
      await tester.pumpWidget(_host(const ToolEvent(
        id: 't1',
        type: 'tool_use',
        toolName: 'read_file',
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('success status renders a green check', (tester) async {
      await tester.pumpWidget(_host(const ToolEvent(
        id: 't2',
        type: 'tool_use',
        toolName: 'read_file',
        status: ToolStatus.success,
        output: 'ok',
      )));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('error status renders a red error icon with tooltip', (tester) async {
      await tester.pumpWidget(_host(const ToolEvent(
        id: 't3',
        type: 'tool_use',
        toolName: 'run_command',
        status: ToolStatus.error,
        error: 'exit 1',
      )));
      expect(find.byIcon(Icons.error), findsOneWidget);
      // Tooltip is the parent — look up by message.
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'exit 1');
    });

    testWidgets('cancelled status renders a grey cancel icon', (tester) async {
      await tester.pumpWidget(_host(const ToolEvent(
        id: 't4',
        type: 'tool_use',
        toolName: 'search',
        status: ToolStatus.cancelled,
      )));
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('expanded error section shows the error text', (tester) async {
      await tester.pumpWidget(_host(const ToolEvent(
        id: 't5',
        type: 'tool_use',
        toolName: 'run_command',
        status: ToolStatus.error,
        error: 'Permission denied',
      )));
      // Tap to expand.
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      expect(find.text('Permission denied'), findsOneWidget);
      expect(find.text('ERROR'), findsOneWidget);
    });
  }
  ```

- [ ] **Step 4.3: Run the tests**

  ```bash
  flutter test test/features/chat/widgets/tool_call_row_test.dart
  ```

  Expected: 5 tests PASS.

- [ ] **Step 4.4: Commit**

  ```bash
  dart format test/features/chat/widgets/tool_call_row_test.dart
  git add test/features/chat/widgets/tool_call_row_test.dart
  git commit -m "test(tool_call_row): cover each ToolStatus → icon/tooltip mapping"
  ```

### Task 5: Post-implementation checks

Per memory `feedback_dart_format.md`, run the standard trio before handing off.

- [ ] **Step 5.1: Format, analyze, test**

  ```bash
  dart format lib/ test/
  flutter analyze
  flutter test
  ```

  Expected:
  - `dart format` — no diffs (already applied per-task).
  - `flutter analyze` — 0 issues.
  - `flutter test` — all tests pass. The Phase 6 branch had 104 tests; this plan adds ~12 (7 model + 5 widget), landing at ~116.

- [ ] **Step 5.2: Commit any format-only diffs**

  If `dart format lib/ test/` produced incidental diffs in files other than the ones above, commit them separately:

  ```bash
  git status
  git add <only-format-diff-files>
  git commit -m "chore: dart format"
  ```

- [ ] **Step 5.3: Push and open a PR**

  Wait for explicit user approval before pushing. When approved:

  ```bash
  git push -u origin tech/2026-04-11-phase10-tool-event-status-and-id
  gh pr create --title "tech(phase10): explicit ToolEvent.status — kill eternal spinner" --body "$(cat <<'EOF'
  ## Summary

  Replaces Phase 6's `isRunning = durationMs == null && output == null` heuristic in `tool_call_row.dart` with an explicit `ToolStatus` enum on `ToolEvent`. Fixes the eternal-spinner bug (M4 from the Phase 6 review) and adds a stable `id` field for future emitter-side deduplication.

  Closes <!-- issue number -->

  ## Changes

  - Add `ToolStatus { running, success, error, cancelled }` enum
  - Add `id` (required), `status` (default `running`), `error` (nullable) to `ToolEvent`
  - `ToolEvent.fromJson` tolerates legacy JSON from pre-Phase-10 local DBs (app is pre-release — no formal migration needed)
  - `tool_call_row.dart` switches on `event.status` — compile-time exhaustive
  - Expanded section surfaces `error` text when present
  - Widget + model test coverage for each status

  ## Type of change

  - [x] Bug fix
  - [ ] New feature
  - [x] Refactor / internal improvement
  - [ ] Documentation

  ## Checklist

  - [x] `flutter analyze` passes with no issues
  - [x] `dart format lib/` applied
  - [x] `flutter test` passes
  - [x] `build_runner` regenerated `tool_event.*.dart` + `chat_message.*.dart`; generated files are committed alongside source
  - [x] PR is focused on a single concern
  EOF
  )"
  ```

---

## Cross-reference: Phase 7 simplification

`docs/superpowers/plans/2026-04-10-phase7-agent-question-ui.md` currently introduces `WorkLogEntry` + `WorkLogStatus { running, done, failed }` + `WorkLogNotifier` as a parallel state machine for tool-call progress. That model is a near-duplicate of what Phase 10 adds to `ToolEvent`.

**When Phase 7 rebases after Phase 10 lands, do this:**

1. **Delete** the `WorkLogEntry` model task (Phase 7 Task 1.4) and the `WorkLogNotifier` task (Phase 7 Task 3) entirely.
2. **Rewrite Phase 7 Task 6 `_WorkLogSection`** to subscribe to `message.toolEvents` directly via `ref.watch(chatNotifierProvider(sessionId).select((s) => s.messages.firstWhere((m) => m.id == messageId).toolEvents))` (or equivalent `select` trim).
3. **Rewrite the `_WorkingPill`** (Phase 7 Task 6 status-bar pill) to check whether any event in the active message has `status == ToolStatus.running` instead of querying a `WorkLogNotifier`.
4. **Keep** `AskUserQuestion` / `AskQuestionNotifier` — those are unrelated to tool events and still need their own model and notifier.

Phase 7 becomes smaller and structurally simpler as a result. The `finishEntry(toolName, status, ...)` name-based lookup — which silently mis-matches when the model calls the same tool twice in a turn — also disappears, because emitters update by `id` instead.

---

## Cross-reference: Phase 8 rebase note

`docs/superpowers/plans/2026-04-10-phase8-missing-project-detection.md` Task 9 enumerates the write buttons in `top_action_bar.dart` to wrap with `_ensureProjectAvailable`. The enumeration predates Phase 6. When rebasing:

- Add `_doPushAll` to the wrap list (new in Phase 6 — remote fan-out push).
- No changes needed to Task 8 (`assertWithinProject`) — Phase 10 doesn't touch `apply_service.dart`.

---

## Cross-reference: Phase 9 rebase note

`docs/superpowers/plans/2026-04-11-phase9-live-git-status.md` Task 7 Step 7 adds invalidation calls after `_doPush`, `_doPull`, and `_runCommit`. When rebasing after Phase 6:

- Add a single `ref.invalidate(gitLiveStateProvider(widget.project.path))` + `ref.invalidate(behindCountProvider(widget.project.path))` after `_doPushAll` completes (once per fan-out, not per remote).

---

## Risks & rollback

- **Legacy JSON tolerance is a one-release bridge.** `fromJson` accepts legacy shapes via inference. If you skip writing a follow-up migration before the next release, silent drift in status classification could persist. Leave a `TODO(phase11)` in the `_legacyId` helper or file a tracking issue.
- **Regenerating `chat_message.*.dart` is transitive.** The `ChatMessage` model didn't change semantically, but its generated files refresh because freezed re-emits related types. `git diff` those files carefully — any semantic shift is a build_runner bug, not something this plan should mask.
- **Rollback**: `git checkout main -- lib/data/models/tool_event.dart && dart run build_runner build --delete-conflicting-outputs` reverts cleanly. No Drift migration means no forward-compat concerns.

---

## Done when

- [ ] `flutter test` passes (expect ~116 tests)
- [ ] `flutter analyze` clean
- [ ] `tool_call_row.dart` contains zero references to the old `isRunning` heuristic
- [ ] A `ToolEvent` constructed with `status: ToolStatus.error, error: 'boom'` renders a red icon with `boom` as its tooltip
- [ ] Legacy-JSON tests demonstrate the three inference branches (success / error / running)
- [ ] Phase 7/8/9 cross-reference notes are captured above (this plan is the single source of truth for the rebase deltas)
