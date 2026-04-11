# Phase 7 — Agent Question UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **⚠️ Rebase note — significant rework if Phase 6b has landed.** Phase 6b (`docs/superpowers/plans/2026-04-10-phase6b-tool-event-status-and-id.md`) adds `id` + `ToolStatus { running, success, error, cancelled }` + `error` fields to `ToolEvent`. That makes `WorkLogEntry` / `WorkLogStatus` / `WorkLogNotifier` a near-duplicate of what `ToolEvent` already carries. When rebasing this plan after Phase 6b: **drop** Task 1.4 (`WorkLogEntry` model) and Task 3 (`WorkLogNotifier`) entirely; **rewrite** Task 6 `_WorkLogSection` to read `message.toolEvents` directly; **rewrite** `_WorkingPill` to check `any(e.status == ToolStatus.running)` on the active message's tool events. **Keep** `AskUserQuestion` + `AskQuestionNotifier` — those are unrelated to tool events.
>
> **Phase 6b is the source of truth for the full rebase delta.** Read both sub-sections of `2026-04-10-phase6b-tool-event-status-and-id.md` → "Cross-reference: Phase 7 simplification":
> 1. The main list (drop `WorkLogEntry`/`WorkLogNotifier`, rewrite `_WorkLogSection` + `_WorkingPill`).
> 2. The **"Addendum — review-fix deltas not in the original Phase 7 plan"** which lists 10 additional corrections to the code snippets below (ticker lifecycle, elapsed counter, per-burst vs sticky semantics, `activeMessageIdProvider` set/clear wiring, `ConsumerWidget` conversion, `ValueKey` usage, `firstWhereOrNull`, "Clear answer" rename, legacy id/status inference). **The code snippets in this plan file still show the pre-review patterns — do not copy them verbatim.** Several tasks are also already complete on `main` and should be skipped; the addendum enumerates them.

**Goal:** Surface agentic `AskUserQuestion` calls as structured in-chat cards with numbered option rows, free-text input, Back/Next/Submit navigation. Add a collapsible WORK LOG section inside the active message bubble showing live tool-call progress with a running timer. Add a status bar "Working for Xs" pill.

**Architecture:** `AskUserQuestion` and `WorkLogEntry` are new `@freezed` models. `AskQuestionNotifier` is a keepAlive notifier that stores per-session answers keyed by `(sessionId, stepIndex)`. `WorkLogNotifier` is a keepAlive family notifier keyed by `messageId` — each message gets its own live log. Both notifiers are fed by the same tool-call pipeline that populates `ToolEvent` (Phase 6). The status bar pill is a `Timer`-driven widget separate from the message list to avoid mass rebuilds.

**Tech Stack:** Flutter, Riverpod (`keepAlive`, family notifiers via `@Riverpod(keepAlive: true)`), `freezed`, `dart:async` (`Timer`).

---

## File Map

| Status | File | Responsibility |
|---|---|---|
| **Create** | `lib/data/models/ask_user_question.dart` | `@freezed` `AskUserQuestion` model |
| **Create** | `lib/data/models/work_log_entry.dart` | `@freezed` `WorkLogEntry` model + `WorkLogStatus` enum |
| **Create** | `lib/features/chat/notifiers/ask_question_notifier.dart` | Stores per-session answers; handles Back navigation |
| **Create** | `lib/features/chat/notifiers/work_log_notifier.dart` | keepAlive family notifier keyed by `messageId`; appended to by tool pipeline |
| **Create** | `lib/features/chat/widgets/ask_user_question_card.dart` | Numbered rows, step counter, progress dots, free-text, Back/Next/Submit |
| **Create** | `lib/features/chat/widgets/work_log_section.dart` | Collapsible toggle row + live log entries + elapsed timer |
| Modify | `lib/features/chat/widgets/message_bubble.dart` | Render `AskUserQuestionCard` and `WorkLogSection` when present (Phase 2 added Diff/Apply/Revert buttons ~600+ lines; Phase 6 adds tool-call rows — read first) |
| Modify | `lib/shell/widgets/status_bar.dart` | Add "Working for Xs" timer-driven pill; tap scrolls to active message (Phase 2 added "N changes" indicator + `changesPanelVisibleProvider` toggle — preserve it) |
| **Create** | `test/data/models/ask_user_question_test.dart` | Model serialization tests |
| **Create** | `test/features/chat/notifiers/ask_question_notifier_test.dart` | Answer storage + back navigation tests |
| **Create** | `test/features/chat/notifiers/work_log_notifier_test.dart` | Append + status transition tests |

---

## Task 1: `AskUserQuestion` + `WorkLogEntry` freezed models

**Files:**
- Create: `lib/data/models/ask_user_question.dart`
- Create: `lib/data/models/work_log_entry.dart`
- Create: `test/data/models/ask_user_question_test.dart`

- [ ] **Step 1.1: Write failing model tests**

  Create `test/data/models/ask_user_question_test.dart`:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/ask_user_question.dart';
  import 'package:code_bench_app/data/models/work_log_entry.dart';

  void main() {
    group('AskUserQuestion', () {
      test('serializes and deserializes', () {
        const q = AskUserQuestion(
          question: 'Choose approach',
          options: ['Option A', 'Option B'],
          stepIndex: 0,
          totalSteps: 3,
          sectionLabel: 'Architecture',
        );
        final json = q.toJson();
        final restored = AskUserQuestion.fromJson(json);
        expect(restored.question, 'Choose approach');
        expect(restored.options, ['Option A', 'Option B']);
        expect(restored.totalSteps, 3);
        expect(restored.allowFreeText, isTrue); // default
      });

      test('allowFreeText defaults to true', () {
        const q = AskUserQuestion(
          question: 'Q?',
          options: [],
          stepIndex: 0,
          totalSteps: 1,
        );
        expect(q.allowFreeText, isTrue);
      });
    });

    group('WorkLogEntry', () {
      test('status enum has three values', () {
        expect(WorkLogStatus.values.length, 3);
        expect(WorkLogStatus.values,
            containsAll([WorkLogStatus.running, WorkLogStatus.done, WorkLogStatus.failed]));
      });

      test('WorkLogEntry serializes', () {
        final entry = WorkLogEntry(
          toolName: 'read_file',
          argument: '/foo/bar.dart',
          status: WorkLogStatus.done,
          durationMs: 250,
          startedAt: DateTime(2026, 4, 10),
        );
        final json = entry.toJson();
        final restored = WorkLogEntry.fromJson(json);
        expect(restored.toolName, 'read_file');
        expect(restored.status, WorkLogStatus.done);
      });
    });
  }
  ```

- [ ] **Step 1.2: Run to confirm they fail**

  ```bash
  flutter test test/data/models/ask_user_question_test.dart
  ```

  Expected: compilation error.

- [ ] **Step 1.3: Create `AskUserQuestion` model**

  Create `lib/data/models/ask_user_question.dart`:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'ask_user_question.freezed.dart';
  part 'ask_user_question.g.dart';

  @freezed
  abstract class AskUserQuestion with _$AskUserQuestion {
    const factory AskUserQuestion({
      required String question,
      required List<String> options,
      @Default(true) bool allowFreeText,
      required int stepIndex,
      required int totalSteps,
      String? sectionLabel,
    }) = _AskUserQuestion;

    factory AskUserQuestion.fromJson(Map<String, dynamic> json) =>
        _$AskUserQuestionFromJson(json);
  }
  ```

- [ ] **Step 1.4: Create `WorkLogEntry` model**

  Create `lib/data/models/work_log_entry.dart`:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'work_log_entry.freezed.dart';
  part 'work_log_entry.g.dart';

  enum WorkLogStatus { running, done, failed }

  @freezed
  abstract class WorkLogEntry with _$WorkLogEntry {
    const factory WorkLogEntry({
      required String toolName,
      String? argument,
      required WorkLogStatus status,
      int? durationMs,
      required DateTime startedAt,
    }) = _WorkLogEntry;

    factory WorkLogEntry.fromJson(Map<String, dynamic> json) =>
        _$WorkLogEntryFromJson(json);
  }
  ```

- [ ] **Step 1.5: Run build_runner**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `ask_user_question.freezed.dart`, `ask_user_question.g.dart`, `work_log_entry.freezed.dart`, `work_log_entry.g.dart` generated.

- [ ] **Step 1.6: Run tests to confirm they pass**

  ```bash
  flutter test test/data/models/ask_user_question_test.dart
  ```

  Expected: all tests pass.

- [ ] **Step 1.7: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 1.8: Commit**

  ```bash
  git add lib/data/models/ask_user_question.dart \
         lib/data/models/ask_user_question.freezed.dart \
         lib/data/models/ask_user_question.g.dart \
         lib/data/models/work_log_entry.dart \
         lib/data/models/work_log_entry.freezed.dart \
         lib/data/models/work_log_entry.g.dart \
         test/data/models/ask_user_question_test.dart
  git commit -m "feat: AskUserQuestion + WorkLogEntry freezed models"
  ```

---

## Task 2: `AskQuestionNotifier`

**Files:**
- Create: `lib/features/chat/notifiers/ask_question_notifier.dart`
- Create: `test/features/chat/notifiers/ask_question_notifier_test.dart`

- [ ] **Step 2.1: Write failing tests**

  Create `test/features/chat/notifiers/ask_question_notifier_test.dart`:

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/features/chat/notifiers/ask_question_notifier.dart';

  void main() {
    ProviderContainer makeContainer() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('starts with no answers', () {
      final c = makeContainer();
      final state = c.read(askQuestionNotifierProvider);
      expect(state.answers, isEmpty);
    });

    test('setAnswer stores keyed by sessionId + stepIndex', () {
      final c = makeContainer();
      c.read(askQuestionNotifierProvider.notifier).setAnswer(
        sessionId: 'sess1',
        stepIndex: 0,
        selectedOption: 'Option A',
        freeText: null,
      );
      final state = c.read(askQuestionNotifierProvider);
      expect(state.answers[('sess1', 0)]?.selectedOption, 'Option A');
    });

    test('getAnswer returns null when no answer stored', () {
      final c = makeContainer();
      final notifier = c.read(askQuestionNotifierProvider.notifier);
      expect(notifier.getAnswer('sess1', 0), isNull);
    });

    test('clearSession removes all answers for a session', () {
      final c = makeContainer();
      final notifier = c.read(askQuestionNotifierProvider.notifier);
      notifier.setAnswer(
        sessionId: 'sess1', stepIndex: 0,
        selectedOption: 'A', freeText: null);
      notifier.setAnswer(
        sessionId: 'sess1', stepIndex: 1,
        selectedOption: 'B', freeText: null);
      notifier.clearSession('sess1');
      expect(notifier.getAnswer('sess1', 0), isNull);
      expect(notifier.getAnswer('sess1', 1), isNull);
    });
  }
  ```

- [ ] **Step 2.2: Run to confirm they fail**

  ```bash
  flutter test test/features/chat/notifiers/ask_question_notifier_test.dart
  ```

  Expected: compilation error.

- [ ] **Step 2.3: Create `AskQuestionNotifier`**

  Create `lib/features/chat/notifiers/ask_question_notifier.dart`:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  part 'ask_question_notifier.freezed.dart';
  part 'ask_question_notifier.g.dart';

  @freezed
  abstract class QuestionAnswer with _$QuestionAnswer {
    const factory QuestionAnswer({
      required String? selectedOption,
      required String? freeText,
    }) = _QuestionAnswer;
  }

  @freezed
  abstract class AskQuestionState with _$AskQuestionState {
    const factory AskQuestionState({
      @Default({}) Map<(String, int), QuestionAnswer> answers,
    }) = _AskQuestionState;
  }

  @Riverpod(keepAlive: true)
  class AskQuestionNotifier extends _$AskQuestionNotifier {
    @override
    AskQuestionState build() => const AskQuestionState();

    void setAnswer({
      required String sessionId,
      required int stepIndex,
      required String? selectedOption,
      required String? freeText,
    }) {
      final key = (sessionId, stepIndex);
      state = state.copyWith(
        answers: {
          ...state.answers,
          key: QuestionAnswer(
            selectedOption: selectedOption,
            freeText: freeText,
          ),
        },
      );
    }

    QuestionAnswer? getAnswer(String sessionId, int stepIndex) =>
        state.answers[(sessionId, stepIndex)];

    void clearSession(String sessionId) {
      state = state.copyWith(
        answers: Map.fromEntries(
          state.answers.entries
              .where((e) => e.key.$1 != sessionId),
        ),
      );
    }
  }
  ```

- [ ] **Step 2.4: Run build_runner**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 2.5: Run tests to confirm they pass**

  ```bash
  flutter test test/features/chat/notifiers/ask_question_notifier_test.dart
  ```

  Expected: 4 tests pass.

- [ ] **Step 2.6: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 2.7: Commit**

  ```bash
  git add lib/features/chat/notifiers/ask_question_notifier.dart \
         lib/features/chat/notifiers/ask_question_notifier.freezed.dart \
         lib/features/chat/notifiers/ask_question_notifier.g.dart \
         test/features/chat/notifiers/ask_question_notifier_test.dart
  git commit -m "feat: AskQuestionNotifier — per-session answer storage with back navigation"
  ```

---

## Task 3: `WorkLogNotifier`

**Files:**
- Create: `lib/features/chat/notifiers/work_log_notifier.dart`
- Create: `test/features/chat/notifiers/work_log_notifier_test.dart`

- [ ] **Step 3.1: Write failing tests**

  Create `test/features/chat/notifiers/work_log_notifier_test.dart`:

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/work_log_entry.dart';
  import 'package:code_bench_app/features/chat/notifiers/work_log_notifier.dart';

  void main() {
    ProviderContainer makeContainer() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('starts with empty log and collapsed', () {
      final c = makeContainer();
      final state = c.read(workLogNotifierProvider('msg1'));
      expect(state.entries, isEmpty);
      expect(state.isExpanded, isFalse);
      expect(state.isRunning, isFalse);
    });

    test('appendEntry adds to entries', () {
      final c = makeContainer();
      c.read(workLogNotifierProvider('msg1').notifier).appendEntry(
        WorkLogEntry(
          toolName: 'read_file',
          argument: '/foo.dart',
          status: WorkLogStatus.running,
          startedAt: DateTime.now(),
        ),
      );
      final state = c.read(workLogNotifierProvider('msg1'));
      expect(state.entries.length, 1);
      expect(state.entries.first.toolName, 'read_file');
      expect(state.isRunning, isTrue);
    });

    test('finishEntry updates entry status to done', () {
      final c = makeContainer();
      final notifier = c.read(workLogNotifierProvider('msg1').notifier);
      notifier.appendEntry(WorkLogEntry(
        toolName: 'write_file',
        status: WorkLogStatus.running,
        startedAt: DateTime.now(),
      ));
      notifier.finishEntry('write_file', WorkLogStatus.done, durationMs: 100);
      final state = c.read(workLogNotifierProvider('msg1'));
      expect(state.entries.first.status, WorkLogStatus.done);
      expect(state.entries.first.durationMs, 100);
    });

    test('markComplete stops running', () {
      final c = makeContainer();
      final notifier = c.read(workLogNotifierProvider('msg1').notifier);
      notifier.appendEntry(WorkLogEntry(
        toolName: 'search',
        status: WorkLogStatus.running,
        startedAt: DateTime.now(),
      ));
      notifier.markComplete();
      expect(c.read(workLogNotifierProvider('msg1')).isRunning, isFalse);
    });

    test('toggleExpanded flips isExpanded', () {
      final c = makeContainer();
      c.read(workLogNotifierProvider('msg1').notifier).toggleExpanded();
      expect(c.read(workLogNotifierProvider('msg1')).isExpanded, isTrue);
    });
  }
  ```

- [ ] **Step 3.2: Run to confirm they fail**

  ```bash
  flutter test test/features/chat/notifiers/work_log_notifier_test.dart
  ```

  Expected: compilation error.

- [ ] **Step 3.3: Create `WorkLogNotifier`**

  Create `lib/features/chat/notifiers/work_log_notifier.dart`:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../../data/models/work_log_entry.dart';

  part 'work_log_notifier.freezed.dart';
  part 'work_log_notifier.g.dart';

  @freezed
  abstract class WorkLogState with _$WorkLogState {
    const factory WorkLogState({
      @Default([]) List<WorkLogEntry> entries,
      @Default(false) bool isExpanded,
      @Default(false) bool isRunning,
      DateTime? completedAt,
    }) = _WorkLogState;
  }

  @Riverpod(keepAlive: true)
  class WorkLogNotifier extends _$WorkLogNotifier {
    @override
    WorkLogState build(String messageId) => const WorkLogState();

    /// Appends a new entry (typically with status = running).
    void appendEntry(WorkLogEntry entry) {
      state = state.copyWith(
        entries: [...state.entries, entry],
        isRunning: entry.status == WorkLogStatus.running || state.isRunning,
      );
    }

    /// Updates the most recent entry with [toolName] to [status].
    void finishEntry(
      String toolName,
      WorkLogStatus status, {
      int? durationMs,
    }) {
      final idx = state.entries.lastIndexWhere((e) => e.toolName == toolName);
      if (idx == -1) return;
      final updated = state.entries[idx].copyWith(
        status: status,
        durationMs: durationMs,
      );
      final newEntries = [...state.entries];
      newEntries[idx] = updated;
      state = state.copyWith(entries: newEntries);
    }

    /// Called when the agent finishes all tool calls.
    void markComplete() {
      state = state.copyWith(
        isRunning: false,
        completedAt: DateTime.now(),
      );
    }

    void toggleExpanded() {
      state = state.copyWith(isExpanded: !state.isExpanded);
    }
  }
  ```

- [ ] **Step 3.4: Run build_runner**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 3.5: Run tests to confirm they pass**

  ```bash
  flutter test test/features/chat/notifiers/work_log_notifier_test.dart
  ```

  Expected: 5 tests pass.

- [ ] **Step 3.6: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 3.7: Commit**

  ```bash
  git add lib/features/chat/notifiers/work_log_notifier.dart \
         lib/features/chat/notifiers/work_log_notifier.freezed.dart \
         lib/features/chat/notifiers/work_log_notifier.g.dart \
         test/features/chat/notifiers/work_log_notifier_test.dart
  git commit -m "feat: WorkLogNotifier — per-message tool-call log, keepAlive family"
  ```

---

## Task 4: `AskUserQuestionCard` widget

**Files:**
- Create: `lib/features/chat/widgets/ask_user_question_card.dart`

- [ ] **Step 4.1: Create `AskUserQuestionCard`**

  Create `lib/features/chat/widgets/ask_user_question_card.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/ask_user_question.dart';
  import '../notifiers/ask_question_notifier.dart';

  class AskUserQuestionCard extends ConsumerStatefulWidget {
    const AskUserQuestionCard({
      super.key,
      required this.question,
      required this.sessionId,
      required this.onSubmit,
      this.onBack,
    });

    final AskUserQuestion question;
    final String sessionId;
    final ValueChanged<Map<String, dynamic>> onSubmit;
    final VoidCallback? onBack;

    @override
    ConsumerState<AskUserQuestionCard> createState() =>
        _AskUserQuestionCardState();
  }

  class _AskUserQuestionCardState
      extends ConsumerState<AskUserQuestionCard> {
    String? _selectedOption;
    final _freeTextController = TextEditingController();

    @override
    void initState() {
      super.initState();
      // Restore prior answer if backing into this step
      final prior = ref.read(askQuestionNotifierProvider.notifier).getAnswer(
        widget.sessionId, widget.question.stepIndex);
      if (prior != null) {
        _selectedOption = prior.selectedOption;
        if (prior.freeText != null) {
          _freeTextController.text = prior.freeText!;
        }
      }
    }

    @override
    void dispose() {
      _freeTextController.dispose();
      super.dispose();
    }

    bool get _canSubmit =>
        _selectedOption != null || _freeTextController.text.trim().isNotEmpty;

    bool get _isLastStep =>
        widget.question.stepIndex == widget.question.totalSteps - 1;

    void _handleSubmit() {
      if (!_canSubmit) return;
      // Save answer
      ref.read(askQuestionNotifierProvider.notifier).setAnswer(
        sessionId: widget.sessionId,
        stepIndex: widget.question.stepIndex,
        selectedOption: _selectedOption,
        freeText: _freeTextController.text.trim().isEmpty
            ? null
            : _freeTextController.text.trim(),
      );
      // Build answer payload
      widget.onSubmit({
        'step': widget.question.stepIndex,
        'selectedOption': _selectedOption,
        'freeText': _freeTextController.text.trim().isEmpty
            ? null
            : _freeTextController.text.trim(),
      });
    }

    @override
    Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A3550)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: progress dots + step counter + section label
            _StepHeader(
              currentStep: widget.question.stepIndex,
              totalSteps: widget.question.totalSteps,
              sectionLabel: widget.question.sectionLabel,
            ),
            const SizedBox(height: 12),
            // Question title
            Text(
              widget.question.question,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            // Option rows
            if (widget.question.options.isNotEmpty)
              ...widget.question.options.asMap().entries.map(
                (entry) => _OptionRow(
                  index: entry.key,
                  label: entry.value,
                  isSelected: _selectedOption == entry.value,
                  onTap: () =>
                      setState(() => _selectedOption = entry.value),
                ),
              ),
            // Free-text input
            if (widget.question.allowFreeText) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _freeTextController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Or describe your own approach…',
                  hintStyle: TextStyle(
                      color: Color(0xFF555555), fontSize: 11),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(
                    color: ThemeConstants.textPrimary, fontSize: 12),
                maxLines: 3,
                minLines: 1,
              ),
            ],
            const SizedBox(height: 14),
            // Footer
            Row(
              children: [
                // Back
                TextButton(
                  onPressed: widget.question.stepIndex > 0
                      ? widget.onBack
                      : null,
                  child: const Text('← Back',
                      style: TextStyle(fontSize: 11)),
                ),
                const Spacer(),
                // Next or Submit
                if (!_isLastStep)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7CFF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: _canSubmit ? _handleSubmit : null,
                    child: const Text('Next →',
                        style: TextStyle(fontSize: 11)),
                  )
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7CFF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: _canSubmit ? _handleSubmit : null,
                    child: const Text('Submit',
                        style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      );
    }
  }

  // ── Progress dots header ───────────────────────────────────────────────────

  class _StepHeader extends StatelessWidget {
    const _StepHeader({
      required this.currentStep,
      required this.totalSteps,
      required this.sectionLabel,
    });

    final int currentStep;
    final int totalSteps;
    final String? sectionLabel;

    @override
    Widget build(BuildContext context) {
      return Row(
        children: [
          // Dots
          Row(
            children: List.generate(totalSteps, (i) {
              Color dotColor;
              if (i < currentStep) {
                dotColor = const Color(0xFF4A7CFF);
              } else if (i == currentStep) {
                dotColor =
                    const Color(0xFF4A7CFF).withOpacity(0.5);
              } else {
                dotColor = const Color(0xFF2A2A2A);
              }
              return Padding(
                padding: EdgeInsets.only(
                    right: i < totalSteps - 1 ? 4 : 0),
                child: Container(
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          // Step counter
          Text(
            '${currentStep + 1} / $totalSteps',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Section label
          if (sectionLabel != null)
            Text(
              sectionLabel!,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
        ],
      );
    }
  }

  // ── Option row ─────────────────────────────────────────────────────────────

  class _OptionRow extends StatelessWidget {
    const _OptionRow({
      required this.index,
      required this.label,
      required this.isSelected,
      required this.onTap,
    });

    final int index;
    final String label;
    final bool isSelected;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1A2540)
                : const Color(0xFF151515),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4A7CFF)
                  : const Color(0xFF2A2A2A),
            ),
          ),
          child: Row(
            children: [
              // Numbered badge
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4A7CFF)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF888888),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? ThemeConstants.textPrimary
                        : ThemeConstants.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 4.2: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 4.3: Commit**

  ```bash
  git add lib/features/chat/widgets/ask_user_question_card.dart
  git commit -m "feat: AskUserQuestionCard — numbered rows, step counter, free-text, navigation"
  ```

---

## Task 5: `WorkLogSection` widget

**Files:**
- Create: `lib/features/chat/widgets/work_log_section.dart`

- [ ] **Step 5.1: Create `WorkLogSection`**

  Create `lib/features/chat/widgets/work_log_section.dart`:

  ```dart
  import 'dart:async';

  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/work_log_entry.dart';
  import '../notifiers/work_log_notifier.dart';

  class WorkLogSection extends ConsumerStatefulWidget {
    const WorkLogSection({super.key, required this.messageId});
    final String messageId;

    @override
    ConsumerState<WorkLogSection> createState() => _WorkLogSectionState();
  }

  class _WorkLogSectionState extends ConsumerState<WorkLogSection> {
    Timer? _tickTimer;
    int _elapsedSeconds = 0;

    @override
    void initState() {
      super.initState();
      _startTicker();
    }

    void _startTicker() {
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final state = ref.read(workLogNotifierProvider(widget.messageId));
        if (!state.isRunning) {
          _tickTimer?.cancel();
          return;
        }
        if (mounted) setState(() => _elapsedSeconds++);
      });
    }

    @override
    void dispose() {
      _tickTimer?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final state =
          ref.watch(workLogNotifierProvider(widget.messageId));

      if (state.entries.isEmpty) return const SizedBox.shrink();

      // Compute elapsed seconds from completion time if done
      final elapsed = state.isRunning
          ? _elapsedSeconds
          : state.completedAt != null
              ? state.completedAt!
                  .difference(
                    state.entries.first.startedAt,
                  )
                  .inSeconds
              : _elapsedSeconds;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toggle row ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () => ref
                .read(workLogNotifierProvider(widget.messageId).notifier)
                .toggleExpanded(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  if (state.isRunning)
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF4A7CFF),
                      ),
                    )
                  else
                    const Icon(Icons.check_circle,
                        size: 11, color: Colors.green),
                  const SizedBox(width: 6),
                  const Text(
                    'WORK LOG',
                    style: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '⏱ ${elapsed}s',
                    style: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    state.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 12,
                    color: ThemeConstants.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // ── Expanded log entries ───────────────────────────────────────
          if (state.isExpanded)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ThemeConstants.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: state.entries.map((entry) {
                  final icon = switch (entry.status) {
                    WorkLogStatus.running => '⚡',
                    WorkLogStatus.done => '✓',
                    WorkLogStatus.failed => '✗',
                  };
                  final iconColor = switch (entry.status) {
                    WorkLogStatus.running => const Color(0xFF4A7CFF),
                    WorkLogStatus.done => Colors.green,
                    WorkLogStatus.failed => Colors.red,
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(icon,
                            style: TextStyle(
                                color: iconColor, fontSize: 10)),
                        const SizedBox(width: 6),
                        Text(
                          entry.toolName,
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (entry.argument != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.argument!,
                              style: const TextStyle(
                                color: ThemeConstants.textSecondary,
                                fontSize: 9,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        if (entry.durationMs != null)
                          Text(
                            '${entry.durationMs}ms',
                            style: const TextStyle(
                              color: ThemeConstants.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    }
  }
  ```

- [ ] **Step 5.2: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 5.3: Commit**

  ```bash
  git add lib/features/chat/widgets/work_log_section.dart
  git commit -m "feat: WorkLogSection — collapsible tool-call log with elapsed timer"
  ```

---

## Task 6: Wire into `message_bubble.dart` + status bar pill

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`
- Modify: `lib/shell/widgets/status_bar.dart`

- [ ] **Step 6.1: Read `message_bubble.dart`**

  Read `lib/features/chat/widgets/message_bubble.dart` to understand its current structure. **Note:** This file is large after Phase 2 (~600+ lines) and Phase 6 (tool-call rows). Key landmarks:
  - `_CodeBlockWidget` — code fence rendering with Diff/Apply buttons (Phase 2) and Diff… picker (Phase 6)
  - Tool-call rows rendered after markdown content (Phase 6)
  - The assistant bubble content `Column` is where `AskUserQuestionCard` and `WorkLogSection` should be added

- [ ] **Step 6.2: Wire `AskUserQuestionCard` and `WorkLogSection` into `message_bubble.dart`**

  In the assistant message bubble build section, add imports and render the new widgets:

  ```dart
  // Add imports at top
  import '../../../data/models/ask_user_question.dart';
  import 'ask_user_question_card.dart';
  import 'work_log_section.dart';
  import '../notifiers/work_log_notifier.dart';
  ```

  In the assistant bubble `Column` (after markdown content and tool-call rows from Phase 6). Insert **after** the `ToolCallRow` loop added in Phase 6:

  ```dart
  // Render AskUserQuestion card if the message has one
  // (The message model will carry this via a new nullable field or via
  //  a global notifier keyed by sessionId+stepIndex — see note below)
  //
  // Pattern: if the active session is awaiting a question answer AND
  // this is the latest assistant message, show the card.
  // The question is delivered via AskQuestionNotifier.currentQuestion
  // (add this field to the notifier) or passed through as a message attribute.
  //
  // Minimal implementation: add a nullable AskUserQuestion to ChatMessage model
  // and render it when non-null.
  if (message.askQuestion != null)
    Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AskUserQuestionCard(
        question: message.askQuestion!,
        sessionId: message.sessionId,
        onSubmit: (answer) {
          // Send answer back as user message
          // ref.read(chatNotifierProvider.notifier).sendMessage(
          //   jsonEncode(answer),
          //   sessionId: message.sessionId,
          // );
        },
        onBack: message.askQuestion!.stepIndex > 0
            ? () {
                // Navigate to previous step — requires multi-step card
                // management via AskQuestionNotifier
              }
            : null,
      ),
    ),

  // WORK LOG — shown for every assistant message that has log entries
  WorkLogSection(messageId: message.id),
  ```

  **Note on `message.askQuestion`:** Add a nullable `AskUserQuestion? askQuestion` field to `ChatMessage` in `lib/data/models/chat_message.dart` and re-run `build_runner`. This is the cleanest hook for associating a question with a specific message.

- [ ] **Step 6.3: Add `askQuestion` to `ChatMessage`**

  In `lib/data/models/chat_message.dart`:

  ```dart
  import 'ask_user_question.dart';
  ```

  Add field:

  ```dart
  AskUserQuestion? askQuestion,
  ```

  Run build_runner:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 6.4: Add `"Working for Xs"` pill to `status_bar.dart`**

  In `lib/shell/widgets/status_bar.dart`, read the file first. **Note:** Phase 2 changed the status bar layout — it now has:
  - Left: "Local" indicator with `hardDrive` icon
  - Centre-right: "N changes" indicator (conditionally shown when `changeCount > 0`, toggles `ChangesPanel`)
  - Right: Git branch indicator
  - `Spacer()` between left and centre-right sections

  The `_WorkingPill` should be inserted **between the Spacer and the changes indicator**, so it appears in the centre area:

  Add a `_WorkingPill` widget that subscribes to any `WorkLogNotifier` for the active message. The simplest approach: watch the `activeSessionId`, then check if there is a `WorkLogNotifier` for the last message ID in that session that `isRunning`.

  Add after the existing status bar content:

  ```dart
  // Add import
  import '../features/chat/notifiers/work_log_notifier.dart';
  import '../features/chat/chat_notifier.dart';
  ```

  Add a `_WorkingPill` widget class at the bottom of the file:

  ```dart
  class _WorkingPill extends ConsumerStatefulWidget {
    const _WorkingPill({required this.messageId});
    final String messageId;

    @override
    ConsumerState<_WorkingPill> createState() => _WorkingPillState();
  }

  class _WorkingPillState extends ConsumerState<_WorkingPill> {
    Timer? _tick;
    int _seconds = 0;

    @override
    void initState() {
      super.initState();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        final state = ref.read(workLogNotifierProvider(widget.messageId));
        if (!state.isRunning) {
          _tick?.cancel();
          return;
        }
        if (mounted) setState(() => _seconds++);
      });
    }

    @override
    void dispose() {
      _tick?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final state = ref.watch(workLogNotifierProvider(widget.messageId));
      if (!state.isRunning) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () {
          // Scroll to active message — requires a ScrollController reference
          // passed from the message list. Omit for now; add in a follow-up.
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2540),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A3550)),
          ),
          child: Text(
            'Working for ${_seconds}s',
            style: const TextStyle(
                color: Color(0xFF4A7CFF), fontSize: 10),
          ),
        ),
      );
    }
  }
  ```

  Wire the pill into the status bar `build` method. The Phase 2 Row layout is:

  ```
  [hardDrive icon] [Local] [Spacer] [N changes indicator] [git branch]
  ```

  Insert the pill **after the `Spacer()` and before the changes indicator**:

  ```dart
  // Inside the status bar Row children, after const Spacer():
  const Spacer(),
  // ← Insert working pill here, before the changeCount check
  Consumer(
    builder: (_, ref, __) {
      final sessionId = ref.watch(activeSessionIdProvider);
      if (sessionId == null) return const SizedBox.shrink();
      final messageId = ref.watch(activeMessageIdProvider);
      if (messageId == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: _WorkingPill(messageId: messageId),
      );
    },
  ),
  // Centre-right: N changes indicator (existing Phase 2 code)
  if (changeCount > 0) ...[
  ```

  Add `activeMessageIdProvider` to `lib/features/chat/chat_notifier.dart`:

  ```dart
  @Riverpod(keepAlive: true)
  class ActiveMessageId extends _$ActiveMessageId {
    @override
    String? build() => null;

    void set(String? id) => state = id;
  }
  ```

  Run build_runner:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 6.5: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 6.6: Commit**

  ```bash
  git add lib/features/chat/widgets/message_bubble.dart \
         lib/features/chat/widgets/ask_user_question_card.dart \
         lib/features/chat/widgets/work_log_section.dart \
         lib/shell/widgets/status_bar.dart \
         lib/features/chat/chat_notifier.dart \
         lib/features/chat/chat_notifier.g.dart \
         lib/data/models/chat_message.dart \
         lib/data/models/chat_message.freezed.dart \
         lib/data/models/chat_message.g.dart
  git commit -m "feat: wire AskUserQuestionCard + WorkLogSection into message bubble; status bar pill"
  ```

---

## Task 7: Final checks

- [ ] **Step 7.1: Run full test suite**

  ```bash
  flutter test
  ```

- [ ] **Step 7.2: Format**

  ```bash
  dart format lib/ test/
  ```

- [ ] **Step 7.3: Analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 7.4: Manual smoke test**

  Run `flutter run -d macos` and verify:
  - Assistant messages with an `askQuestion` show the `AskUserQuestionCard` with numbered options, step counter, and free-text input
  - Selecting an option highlights the row in blue
  - Submit calls `onSubmit` callback
  - Back button is disabled on step 0, enabled otherwise
  - `WorkLogSection` appears at the bottom of any message with log entries
  - Toggle row shows spinner while running, ✓ when done; timer counts up during run
  - Expanding the log shows individual tool call entries with status icon + duration
  - Status bar shows "Working for Xs" pill while agent is running
  - Pill disappears after agent completes
