# Phase 6 — Agentic Tool-use & Advanced Diff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface real agentic tool-use cards in chat (collapsed/expanded rows with metrics), close the Phase 2 diff gap (unnamed code fences), add conflict detection on revert (three-way merge view), upgrade Push to a split button for multi-remote repos, and introduce an inline PR review card.

**Architecture:** `ToolEvent` is a new `@freezed` model stored as a JSON list on `ChatMessage`. `AppliedChange` gains a SHA-256 `contentChecksum` field so `ApplyService` can detect when a file is externally modified before revert. The `ConflictMergeView` widget is shown inline in the changes panel. `GitService` already has `listRemotes`, `pushToRemote`, and `getOriginUrl` from Phase 3. `GitHubApiService` already has `listBranches` and `listPullRequests` from Phase 3; Phase 6 adds PR review methods (`getPullRequest`, `getCheckRuns`, `approvePullRequest`, `mergePullRequest`). `PRCard` polls live every 30s via a timer in its `ConsumerStatefulWidget`. **Note:** `_CommitPushButton` in `top_action_bar.dart` is a full `ConsumerStatefulWidget` (~400+ lines) with AI commit message generation and PR creation from Phase 3 — read it carefully before modifying.

**Tech Stack:** Flutter, Riverpod (keepAlive), `freezed`, `crypto` package (SHA-256), existing `diff_match_patch` (Phase 2), existing `GitService` (Phase 3), existing `GitHubApiService` (Phase 3).

---

## File Map

| Status | File | Responsibility |
|---|---|---|
| Modify | `pubspec.yaml` | Add `crypto: ^3.0.3` |
| **Create** | `lib/data/models/tool_event.dart` | `@freezed` `ToolEvent` model |
| Modify | `lib/data/models/chat_message.dart` | Add `@Default([]) List<ToolEvent> toolEvents` |
| Modify | `lib/data/models/applied_change.dart` | Add `String? contentChecksum` field (Phase 2 already has `additions`/`deletions`) |
| Modify | `lib/services/apply/apply_service.dart` | Capture checksum at apply time; conflict detection + three-way revert (Phase 2 already has `ProcessRunner`, `assertWithinProject`, `kMaxApplyContentBytes`, `kGitCheckoutTimeout`, `_computeLineCounts`) |
| **Create** | `lib/features/chat/widgets/tool_call_row.dart` | Collapsed/expanded tool-call card with metrics |
| Modify | `lib/features/chat/widgets/message_bubble.dart` | Render tool-call rows; Diff… button + inline path picker for nameless fences (Phase 2 already has Diff/Apply buttons for named fences, ~600+ lines) |
| **Create** | `lib/features/chat/widgets/conflict_merge_view.dart` | Three-tab merge view (Original / Applied / Current) |
| Modify | `lib/features/chat/widgets/changes_panel.dart` | Show `edited` badge; trigger `ConflictMergeView` (Phase 2 already has ~255-line panel with file rows, add/del counts, Revert button) |
| Modify | `lib/services/git/git_service.dart` | `listRemotes`, `pushToRemote`, `getOriginUrl` already added in Phase 3 — no changes needed |
| Modify | `lib/services/github/github_api_service.dart` | Add `getPullRequest`, `getCheckRuns`, `approvePullRequest`, `mergePullRequest` (Phase 3 already added `listBranches`, `listPullRequests`) |
| **Create** | `lib/features/chat/widgets/pr_card.dart` | PR status card — CI chips, comments, Approve/Merge/Open |
| Modify | `lib/shell/widgets/top_action_bar.dart` | Multi-remote split Push button |
| **Create** | `test/data/models/tool_event_test.dart` | Model serialisation tests |
| **Create** | `test/services/apply/apply_service_checksum_test.dart` | Checksum capture + conflict detection tests |

---

## Task 1: `crypto` package + `ToolEvent` model + `ChatMessage` update

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/data/models/tool_event.dart`
- Modify: `lib/data/models/chat_message.dart`

- [ ] **Step 1.1: Write failing tests for `ToolEvent` serialization**

  Create `test/data/models/tool_event_test.dart`:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/tool_event.dart';

  void main() {
    test('ToolEvent serializes and deserializes', () {
      final event = ToolEvent(
        type: 'tool_use',
        toolName: 'read_file',
        input: {'path': '/foo/bar.dart'},
        output: 'content here',
        filePath: '/foo/bar.dart',
        durationMs: 123,
        tokensIn: 50,
        tokensOut: 10,
      );
      final json = event.toJson();
      final restored = ToolEvent.fromJson(json);
      expect(restored.toolName, 'read_file');
      expect(restored.durationMs, 123);
      expect(restored.input['path'], '/foo/bar.dart');
    });

    test('ToolEvent with null fields serializes cleanly', () {
      const event = ToolEvent(
        type: 'tool_result',
        toolName: 'write_file',
        input: {},
      );
      final json = event.toJson();
      expect(json['output'], isNull);
    });
  }
  ```

- [ ] **Step 1.2: Run to confirm they fail**

  ```bash
  flutter test test/data/models/tool_event_test.dart
  ```

  Expected: compilation error — `ToolEvent` not found.

- [ ] **Step 1.3: Add `crypto` to `pubspec.yaml`**

  In `pubspec.yaml`, under `dependencies:`, add:

  ```yaml
    crypto: ^3.0.3
  ```

- [ ] **Step 1.4: Create `ToolEvent` freezed model**

  Create `lib/data/models/tool_event.dart`:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'tool_event.freezed.dart';
  part 'tool_event.g.dart';

  @freezed
  abstract class ToolEvent with _$ToolEvent {
    const factory ToolEvent({
      required String type,
      required String toolName,
      @Default({}) Map<String, dynamic> input,
      String? output,
      String? filePath,
      int? durationMs,
      int? tokensIn,
      int? tokensOut,
    }) = _ToolEvent;

    factory ToolEvent.fromJson(Map<String, dynamic> json) =>
        _$ToolEventFromJson(json);
  }
  ```

- [ ] **Step 1.5: Add `toolEvents` to `ChatMessage`**

  In `lib/data/models/chat_message.dart`, add the import and field:

  ```dart
  import 'tool_event.dart';
  ```

  Add to the `@freezed` factory:

  ```dart
  @Default([]) List<ToolEvent> toolEvents,
  ```

  This is the hook that was left as a placeholder in the Phase 2 spec — it is now activated.

- [ ] **Step 1.6: Run pub get + build_runner**

  ```bash
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `tool_event.freezed.dart`, `tool_event.g.dart`, and updated `chat_message.freezed.dart` generated.

- [ ] **Step 1.7: Run tests to confirm they pass**

  ```bash
  flutter test test/data/models/tool_event_test.dart
  ```

  Expected: 2 tests pass.

- [ ] **Step 1.8: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 1.9: Commit**

  ```bash
  git add pubspec.yaml pubspec.lock \
         lib/data/models/tool_event.dart \
         lib/data/models/tool_event.freezed.dart \
         lib/data/models/tool_event.g.dart \
         lib/data/models/chat_message.dart \
         lib/data/models/chat_message.freezed.dart \
         lib/data/models/chat_message.g.dart
  git commit -m "feat: ToolEvent model + toolEvents on ChatMessage; add crypto package"
  ```

---

## Task 2: `AppliedChange.contentChecksum` + conflict detection in `ApplyService`

**Files:**
- Modify: `lib/data/models/applied_change.dart`
- Modify: `lib/services/apply/apply_service.dart`
- Create: `test/services/apply/apply_service_checksum_test.dart`

- [ ] **Step 2.1: Write failing checksum tests**

  Create `test/services/apply/apply_service_checksum_test.dart`:

  ```dart
  import 'dart:io';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/services/apply/apply_service.dart';

  void main() {
    test('sha256OfString returns non-empty hex string', () {
      final hash = ApplyService.sha256OfString('hello world');
      expect(hash, isNotEmpty);
      expect(hash.length, 64); // SHA-256 = 32 bytes = 64 hex chars
    });

    test('same content produces same checksum', () {
      expect(
        ApplyService.sha256OfString('content'),
        equals(ApplyService.sha256OfString('content')),
      );
    });

    test('different content produces different checksum', () {
      expect(
        ApplyService.sha256OfString('content a'),
        isNot(equals(ApplyService.sha256OfString('content b'))),
      );
    });

    test('isExternallyModified returns false when checksums match', () async {
      final dir = await Directory.systemTemp.createTemp();
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/test.txt')..writeAsStringSync('same');
      final checksum = ApplyService.sha256OfString('same');
      expect(
        await ApplyService.isExternallyModified(file.path, checksum),
        isFalse,
      );
    });

    test('isExternallyModified returns true when file changed', () async {
      final dir = await Directory.systemTemp.createTemp();
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/test.txt')..writeAsStringSync('changed');
      final checksum = ApplyService.sha256OfString('original');
      expect(
        await ApplyService.isExternallyModified(file.path, checksum),
        isTrue,
      );
    });
  }
  ```

- [ ] **Step 2.2: Run to confirm they fail**

  ```bash
  flutter test test/services/apply/apply_service_checksum_test.dart
  ```

  Expected: compilation errors — `sha256OfString` and `isExternallyModified` not found.

- [ ] **Step 2.3: Add `contentChecksum` to `AppliedChange`**

  In `lib/data/models/applied_change.dart`, add the field. **Note:** Phase 2 already added `additions` and `deletions` fields — preserve them:

  ```dart
  @freezed
  abstract class AppliedChange with _$AppliedChange {
    const factory AppliedChange({
      required String id,
      required String sessionId,
      required String messageId,
      required String filePath,
      String? originalContent,
      required String newContent,
      required DateTime appliedAt,
      // Phase 2 fields — line counts from char-level diff:
      @Default(0) int additions,
      @Default(0) int deletions,
      String? contentChecksum,      // ← new: SHA-256 of newContent at apply time
    }) = _AppliedChange;
  }
  ```

- [ ] **Step 2.4: Add `sha256OfString` and `isExternallyModified` to `ApplyService`**

  In `lib/services/apply/apply_service.dart`, add the import and two static methods. Add at the top of the file:

  ```dart
  import 'dart:convert';
  import 'package:crypto/crypto.dart';
  ```

  Add these static methods inside or alongside the `ApplyService` class (they can be static utilities):

  ```dart
  /// Returns the SHA-256 hex digest of [content].
  static String sha256OfString(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Returns true if the file at [filePath] has been modified since [storedChecksum].
  static Future<bool> isExternallyModified(
    String filePath,
    String storedChecksum,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return true; // file deleted = modified
      final current = await file.readAsString();
      return sha256OfString(current) != storedChecksum;
    } catch (_) {
      return true;
    }
  }
  ```

  Also update the `applyChange` method in `ApplyService` to capture the checksum when writing. **Note:** Phase 2's `ApplyService` already has:
  - `ProcessRunner` typedef and injection via constructor
  - `kMaxApplyContentBytes` content size guard
  - `kGitCheckoutTimeout` for revert
  - `assertWithinProject` path-traversal guard (lexical + symlink)
  - `_computeLineCounts` for line-level diff stats
  - `_uuidGen` factory injected via constructor (not raw `Uuid().v4()`)

  Find the `_notifier.apply(AppliedChange(...))` call inside `applyChange` (after `_fs.writeFile`) and add the checksum:

  ```dart
  // Inside applyChange, after writing content to disk and computing line counts:
  final (additions, deletions) = _computeLineCounts(originalContent, newContent);
  final checksum = ApplyService.sha256OfString(newContent);  // ← new

  _notifier.apply(AppliedChange(
    id: _uuidGen(),                // Phase 2 uses injected _uuidGen, not const Uuid().v4()
    sessionId: sessionId,
    messageId: messageId,
    filePath: filePath,
    originalContent: originalContent,
    newContent: newContent,
    appliedAt: DateTime.now(),
    additions: additions,          // Phase 2 field
    deletions: deletions,          // Phase 2 field
    contentChecksum: checksum,     // ← new: record at apply time
  ));
  ```

- [ ] **Step 2.5: Run build_runner**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 2.6: Run tests to confirm they pass**

  ```bash
  flutter test test/services/apply/apply_service_checksum_test.dart
  ```

  Expected: 5 tests pass.

- [ ] **Step 2.7: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 2.8: Commit**

  ```bash
  git add lib/data/models/applied_change.dart \
         lib/data/models/applied_change.freezed.dart \
         lib/services/apply/apply_service.dart \
         test/services/apply/apply_service_checksum_test.dart
  git commit -m "feat: contentChecksum on AppliedChange; conflict detection in ApplyService"
  ```

---

## Task 3: `ToolCallRow` widget

**Files:**
- Create: `lib/features/chat/widgets/tool_call_row.dart`

- [ ] **Step 3.1: Create `ToolCallRow`**

  Create `lib/features/chat/widgets/tool_call_row.dart`:

  ```dart
  import 'package:flutter/material.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/tool_event.dart';

  class ToolCallRow extends StatefulWidget {
    const ToolCallRow({super.key, required this.event});
    final ToolEvent event;

    @override
    State<ToolCallRow> createState() => _ToolCallRowState();
  }

  class _ToolCallRowState extends State<ToolCallRow> {
    bool _expanded = false;

    IconData _iconForTool(String toolName) {
      return switch (toolName) {
        'read_file' || 'read' => Icons.description_outlined,
        'write_file' || 'write' => Icons.edit_outlined,
        'run_command' || 'bash' => Icons.terminal,
        'search' || 'grep' => Icons.search,
        _ => Icons.build_outlined,
      };
    }

    String _primaryArg(ToolEvent event) {
      if (event.filePath != null) return event.filePath!;
      if (event.input.isNotEmpty) {
        final first = event.input.values.first;
        if (first is String) {
          return first.length > 60 ? '${first.substring(0, 60)}…' : first;
        }
      }
      return '';
    }

    @override
    Widget build(BuildContext context) {
      final arg = _primaryArg(widget.event);
      final isRunning = widget.event.durationMs == null &&
          widget.event.output == null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Collapsed row ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius:
                    BorderRadius.circular(_expanded ? 0 : 6),
                border: Border.all(color: ThemeConstants.borderColor),
              ),
              child: Row(
                children: [
                  // Tool icon
                  Icon(
                    _iconForTool(widget.event.toolName),
                    size: 13,
                    color: ThemeConstants.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  // Tool name
                  Text(
                    widget.event.toolName,
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (arg.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        arg,
                        style: const TextStyle(
                          color: ThemeConstants.textSecondary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  const SizedBox(width: 8),
                  // Status
                  if (isRunning)
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF4A7CFF),
                      ),
                    )
                  else if (widget.event.output != null)
                    const Icon(Icons.check_circle,
                        size: 11, color: Colors.green)
                  else
                    const Icon(Icons.error, size: 11, color: Colors.red),
                  // Duration
                  if (widget.event.durationMs != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${widget.event.durationMs}ms',
                      style: const TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                  // Tokens
                  if (widget.event.tokensIn != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '↑${widget.event.tokensIn} ↓${widget.event.tokensOut ?? 0}',
                      style: const TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 12,
                    color: ThemeConstants.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // ── Expanded section ───────────────────────────────────────────────
          if (_expanded)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF131313),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6)),
                border: Border.all(color: ThemeConstants.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input
                  if (widget.event.input.isNotEmpty) ...[
                    const Text('INPUT',
                        style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 9,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    for (final entry in widget.event.input.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: const TextStyle(
                                color: ThemeConstants.textSecondary,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  color: ThemeConstants.textPrimary,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                  // Output
                  if (widget.event.output != null) ...[
                    const Text('OUTPUT',
                        style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 9,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    _ExpandableOutput(text: widget.event.output!),
                    const SizedBox(height: 8),
                  ],
                  // Metrics footer
                  if (widget.event.durationMs != null)
                    Row(
                      children: [
                        Text(
                          '${widget.event.durationMs}ms',
                          style: const TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                        if (widget.event.tokensIn != null) ...[
                          const Text(' · ',
                              style: TextStyle(
                                  color: ThemeConstants.textSecondary,
                                  fontSize: 9)),
                          Text(
                            '↑${widget.event.tokensIn} ↓${widget.event.tokensOut ?? 0} tokens',
                            style: const TextStyle(
                              color: ThemeConstants.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
        ],
      );
    }
  }

  class _ExpandableOutput extends StatefulWidget {
    const _ExpandableOutput({required this.text});
    final String text;

    @override
    State<_ExpandableOutput> createState() => _ExpandableOutputState();
  }

  class _ExpandableOutputState extends State<_ExpandableOutput> {
    bool _showAll = false;

    @override
    Widget build(BuildContext context) {
      final lines = widget.text.split('\n');
      final truncated = !_showAll && lines.length > 5;
      final visible = truncated ? lines.take(5).join('\n') : widget.text;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            visible,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          if (truncated)
            GestureDetector(
              onTap: () => setState(() => _showAll = true),
              child: const Text('Show more…',
                  style: TextStyle(
                      color: Color(0xFF4A7CFF), fontSize: 10)),
            ),
        ],
      );
    }
  }
  ```

- [ ] **Step 3.2: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 3.3: Commit**

  ```bash
  git add lib/features/chat/widgets/tool_call_row.dart
  git commit -m "feat: ToolCallRow — collapsed/expanded tool-call card with metrics"
  ```

---

## Task 4: Wire tool-call rows + Diff… button into `message_bubble.dart`

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`

> **Phase 2 context:** `message_bubble.dart` was significantly expanded in Phase 2 (~575 lines of changes). It already has:
> - A Diff button and inline change card for code blocks **with** a detected filename
> - Apply/Revert buttons wired to `ApplyService`
> - `_CodeBlockWidget` with filename parsing from code fence headers
> - Horizontal scrolling for diff display
>
> This task adds: (1) tool-call row rendering (new), (2) a "Diff…" button with path picker for code fences **without** a filename (gap-closing).

- [ ] **Step 4.1: Read `message_bubble.dart`**

  Read `lib/features/chat/widgets/message_bubble.dart` to understand its current structure — specifically how `_CodeBlockWidget` is built, where the existing Diff/Apply buttons are rendered, and how the filename detection works. The file is large (~600+ lines after Phase 2).

- [ ] **Step 4.2: Add tool-call rows to the assistant message bubble**

  In the assistant message build section (where `message.toolEvents` can be accessed), add a loop to render `ToolCallRow` for each event. Find where the message content is rendered and add after it:

  ```dart
  // Add import at top
  import 'tool_call_row.dart';

  // In the assistant bubble content Column, after the markdown/text content:
  if (message.toolEvents.isNotEmpty) ...[
    const SizedBox(height: 8),
    for (final event in message.toolEvents)
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ToolCallRow(event: event),
      ),
  ],
  ```

- [ ] **Step 4.3: Add `Diff…` button for nameless code fences**

  **Phase 2 already renders a Diff button when a filename is detected.** This step only handles the `else` branch — when no filename was parsed from the code fence header. Find the condition in `_CodeBlockWidget` that checks for a filename and add the picker fallback:

  ```dart
  // In _CodeBlockWidget, extend the existing filename check:
  if (filename != null)
    // ← Phase 2 already handles this case (Diff + Apply buttons)
    ...existingDiffApplyButtons
  else
    _DiffWithPickerButton(code: code, projectId: projectId),
  ```

  Add the `_DiffWithPickerButton` widget class in `message_bubble.dart`:

  ```dart
  class _DiffWithPickerButton extends ConsumerStatefulWidget {
    const _DiffWithPickerButton({required this.code, required this.projectId});
    final String code;
    final String? projectId;

    @override
    ConsumerState<_DiffWithPickerButton> createState() =>
        _DiffWithPickerButtonState();
  }

  class _DiffWithPickerButtonState
      extends ConsumerState<_DiffWithPickerButton> {
    bool _showPicker = false;
    final _controller = TextEditingController();
    List<String> _suggestions = [];
    String? _selectedFile;

    void _filter(String query) {
      // Filter project files using substring match
      // (Relies on ProjectService.listFiles or a cached file list)
      // Simplified: scan project directory for .dart, etc.
      if (widget.projectId == null) return;
      // Use a basic file system scan of the project root limited to common code files
      setState(() {
        _suggestions = []; // populated by actual file scanning (see note below)
      });
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      if (!_showPicker) {
        return TextButton(
          onPressed: () => setState(() => _showPicker = true),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: const Text('Diff…',
              style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 10)),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Which file does this update?',
              style: TextStyle(
                  color: Color(0xFFB0B0B0), fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _filter,
                  onSubmitted: (v) {
                    if (_suggestions.isNotEmpty) {
                      setState(() => _selectedFile = _suggestions.first);
                    } else if (v.isNotEmpty) {
                      setState(() => _selectedFile = v);
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'lib/features/...',
                    hintStyle: TextStyle(
                        color: Color(0xFF555555), fontSize: 11),
                    isDense: true,
                  ),
                  style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _selectedFile != null
                    ? () {
                        // TODO: trigger diff with _selectedFile
                      }
                    : null,
                child: const Text('Diff'),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 12),
                onPressed: () => setState(() => _showPicker = false),
              ),
            ],
          ),
          if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (_, i) => InkWell(
                  onTap: () =>
                      setState(() => _selectedFile = _suggestions[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Text(
                      _suggestions[i],
                      style: const TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 10,
                          fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }
  ```

  **Note on file suggestions:** The `_filter` method should scan the project directory. To avoid complexity, use `Directory(projectPath).listSync(recursive: true)` with a filter for common extensions (`.dart`, `.ts`, `.js`, `.py`, `.json`, etc.) and substring-match the query against relative paths. The project path is available from the active project provider.

- [ ] **Step 4.4: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 4.5: Commit**

  ```bash
  git add lib/features/chat/widgets/message_bubble.dart
  git commit -m "feat: render tool-call rows in message bubble; Diff… button for nameless fences"
  ```

---

## Task 5: `ConflictMergeView` + changes panel `edited` badge

**Files:**
- Create: `lib/features/chat/widgets/conflict_merge_view.dart`
- Modify: `lib/features/chat/widgets/changes_panel.dart`

> **Phase 2 context:** `changes_panel.dart` already exists (~255 lines) with:
> - File rows showing filename, additions/deletions counts, and a Revert button
> - Session-grouped change list from `appliedChangesProvider`
> - Visibility toggling via `changesPanelVisibleProvider`
> - Integration with `ApplyService.revertChange`
>
> This task extends the existing panel with an `edited` badge (via `FutureBuilder` + checksum check) and a `ConflictMergeView` dialog on revert when a file was externally modified. Read the file first to find the exact row widget to extend.

- [ ] **Step 5.1: Create `ConflictMergeView`**

  Create `lib/features/chat/widgets/conflict_merge_view.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter/material.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/applied_change.dart';

  class ConflictMergeView extends StatefulWidget {
    const ConflictMergeView({
      super.key,
      required this.change,
      required this.currentContent,
      required this.onAcceptRevert,
      required this.onKeepCurrent,
    });

    final AppliedChange change;
    final String currentContent;
    final VoidCallback onAcceptRevert;
    final VoidCallback onKeepCurrent;

    @override
    State<ConflictMergeView> createState() => _ConflictMergeViewState();
  }

  class _ConflictMergeViewState extends State<ConflictMergeView>
      with SingleTickerProviderStateMixin {
    late final TabController _tabController;

    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 3, vsync: this);
    }

    @override
    void dispose() {
      _tabController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            labelColor: const Color(0xFF4A7CFF),
            unselectedLabelColor: ThemeConstants.textSecondary,
            indicatorColor: const Color(0xFF4A7CFF),
            tabs: const [
              Tab(text: 'Original'),
              Tab(text: 'Applied'),
              Tab(text: 'Current'),
            ],
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabController,
              children: [
                _ContentView(
                    content: widget.change.originalContent ?? '(new file)'),
                _ContentView(content: widget.change.newContent),
                _ContentView(content: widget.currentContent),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onKeepCurrent,
                child: const Text('Keep current',
                    style: TextStyle(
                        color: ThemeConstants.textSecondary, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7CFF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                ),
                onPressed: widget.onAcceptRevert,
                child: const Text('Accept revert',
                    style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      );
    }
  }

  class _ContentView extends StatelessWidget {
    const _ContentView({required this.content});
    final String content;

    @override
    Widget build(BuildContext context) {
      return Container(
        color: ThemeConstants.codeBlockBg,
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 10,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 5.2: Add `edited` badge + conflict view to `changes_panel.dart`**

  In `lib/features/chat/widgets/changes_panel.dart`, read the file first to understand its current structure from Phase 2.

  For each file row in the panel, check if the file was externally modified. Add the `edited` badge and merge view trigger:

  ```dart
  // Add import
  import 'dart:io';
  import '../../../services/apply/apply_service.dart';
  import 'conflict_merge_view.dart';
  ```

  In the list item builder, add an async check for external modification. Replace or extend the existing file row build with a `FutureBuilder`:

  ```dart
  // For each AppliedChange entry, wrap its row with:
  FutureBuilder<bool>(
    future: change.contentChecksum != null
        ? ApplyService.isExternallyModified(
            change.filePath, change.contentChecksum!)
        : Future.value(false),
    builder: (context, snap) {
      final isEdited = snap.data ?? false;
      return _FileRow(
        change: change,
        isEdited: isEdited,
        onRevert: () async {
          if (isEdited) {
            final currentContent =
                await File(change.filePath).readAsString();
            if (!context.mounted) return;
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                title: const Text('File externally modified',
                    style: TextStyle(
                        color: Color(0xFFE0E0E0), fontSize: 13)),
                content: ConflictMergeView(
                  change: change,
                  currentContent: currentContent,
                  onAcceptRevert: () async {
                    Navigator.of(context).pop();
                    await File(change.filePath)
                        .writeAsString(change.originalContent ?? '');
                    // Remove entry from AppliedChangesNotifier
                    ref
                        .read(appliedChangesProvider.notifier)
                        .remove(change.id);
                  },
                  onKeepCurrent: () => Navigator.of(context).pop(),
                ),
              ),
            );
          } else {
            // No conflict — revert directly
            await File(change.filePath)
                .writeAsString(change.originalContent ?? '');
            ref
                .read(appliedChangesProvider.notifier)
                .remove(change.id);
          }
        },
      );
    },
  ),
  ```

  Add the `edited` badge inside `_FileRow`:

  ```dart
  if (isEdited)
    Container(
      margin: const EdgeInsets.only(left: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2900),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFAA7700)),
      ),
      child: const Text('edited',
          style: TextStyle(
              color: Color(0xFFFFAA00), fontSize: 9)),
    ),
  ```

- [ ] **Step 5.3: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 5.4: Commit**

  ```bash
  git add lib/features/chat/widgets/conflict_merge_view.dart \
         lib/features/chat/widgets/changes_panel.dart
  git commit -m "feat: ConflictMergeView + edited badge in changes panel"
  ```

---

## Task 6: `GitHubApiService` PR review methods

> **Phase 3 context:** `github_api_service.dart` already has `validateToken`, `createPullRequest`, `listBranches`, `listPullRequests` from Phase 3. The methods below are additive — do not duplicate existing ones.

**Files:**
- Modify: `lib/services/github/github_api_service.dart`

- [ ] **Step 6.1: Add PR review API methods**

  In `lib/services/github/github_api_service.dart`, add after `createPullRequest`:

  ```dart
  Future<Map<String, dynamic>> getPullRequest(
    String owner,
    String repo,
    int number,
  ) async {
    try {
      final response =
          await _dio.get('/repos/$owner/$repo/pulls/$number');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to get PR',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getCheckRuns(
    String owner,
    String repo,
    String sha,
  ) async {
    try {
      final response = await _dio.get(
          '/repos/$owner/$repo/commits/$sha/check-runs');
      final data = response.data as Map<String, dynamic>;
      return (data['check_runs'] as List)
          .cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to get check runs',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<void> approvePullRequest(
    String owner,
    String repo,
    int number,
  ) async {
    try {
      await _dio.post(
        '/repos/$owner/$repo/pulls/$number/reviews',
        data: {'event': 'APPROVE'},
      );
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to approve PR',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<void> mergePullRequest(
    String owner,
    String repo,
    int number,
  ) async {
    try {
      await _dio.put('/repos/$owner/$repo/pulls/$number/merge');
    } on DioException catch (e) {
      throw NetworkException(
        'Failed to merge PR',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }
  ```

- [ ] **Step 6.2: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 6.3: Commit**

  ```bash
  git add lib/services/github/github_api_service.dart
  git commit -m "feat: GitHubApiService — getPR, getCheckRuns, approvePR, mergePR"
  ```

---

## Task 7: `PRCard` widget

**Files:**
- Create: `lib/features/chat/widgets/pr_card.dart`

- [ ] **Step 7.1: Create `PRCard`**

  Create `lib/features/chat/widgets/pr_card.dart`:

  ```dart
  import 'dart:async';
  import 'dart:io';

  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../services/github/github_api_service.dart';

  class PRCard extends ConsumerStatefulWidget {
    const PRCard({
      super.key,
      required this.owner,
      required this.repo,
      required this.prNumber,
    });
    final String owner;
    final String repo;
    final int prNumber;

    @override
    ConsumerState<PRCard> createState() => _PRCardState();
  }

  class _PRCardState extends ConsumerState<PRCard> {
    Map<String, dynamic>? _pr;
    List<Map<String, dynamic>> _checkRuns = [];
    bool _approved = false;
    bool _merged = false;
    Timer? _pollTimer;

    @override
    void initState() {
      super.initState();
      _load();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _load(),
      );
    }

    @override
    void dispose() {
      _pollTimer?.cancel();
      super.dispose();
    }

    Future<void> _load() async {
      // Use the existing `githubApiServiceProvider` rather than reading the
      // token + constructing GitHubApiService by hand. The provider already
      // does exactly that, is keepAlive, and keeps the PAT out of the widget
      // layer — reinventing it here would just duplicate logic and give us
      // a second place to forget a null-check.
      final svc = await ref.read(githubApiServiceProvider.future);
      if (svc == null) return;
      try {
        final pr = await svc.getPullRequest(widget.owner, widget.repo, widget.prNumber);
        final sha = (pr['head'] as Map<String, dynamic>?)?['sha'] as String?;
        List<Map<String, dynamic>> checks = [];
        if (sha != null) {
          checks = await svc.getCheckRuns(widget.owner, widget.repo, sha);
        }
        if (mounted) setState(() { _pr = pr; _checkRuns = checks; });
      } catch (_) {}
    }

    Future<void> _approve() async {
      final svc = await ref.read(githubApiServiceProvider.future);
      if (svc == null) return;
      await svc.approvePullRequest(widget.owner, widget.repo, widget.prNumber);
      if (mounted) setState(() => _approved = true);
    }

    Future<void> _merge() async {
      final svc = await ref.read(githubApiServiceProvider.future);
      if (svc == null) return;
      await svc.mergePullRequest(widget.owner, widget.repo, widget.prNumber);
      if (mounted) setState(() => _merged = true);
    }

    String _badgeText() {
      if (_merged) return 'merged';
      final state = _pr?['state'] as String? ?? 'open';
      return state;
    }

    Color _badgeColor() => switch (_badgeText()) {
          'merged' => const Color(0xFF6E40C9),
          'closed' => Colors.red,
          _ => Colors.green,
        };

    @override
    Widget build(BuildContext context) {
      if (_pr == null) {
        return const Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              SizedBox(width: 8),
              Text('Loading PR…',
                  style: TextStyle(
                      color: ThemeConstants.textSecondary, fontSize: 11)),
            ],
          ),
        );
      }

      final title = _pr!['title'] as String? ?? '';
      final prNum = _pr!['number'] as int? ?? widget.prNumber;
      final base = (_pr!['base'] as Map<String, dynamic>?)?['ref'] as String? ?? '';
      final head = (_pr!['head'] as Map<String, dynamic>?)?['ref'] as String? ?? '';
      final commits = _pr!['commits'] as int? ?? 0;
      final htmlUrl = _pr!['html_url'] as String? ?? '';
      final reviews =
          (_pr!['requested_reviewers'] as List?)?.cast<Map<String, dynamic>>() ??
              [];

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ThemeConstants.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _badgeColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _badgeColor()),
                  ),
                  child: Text(
                    _badgeText(),
                    style: TextStyle(
                        color: _badgeColor(), fontSize: 9),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '#$prNum',
                  style: const TextStyle(
                      color: ThemeConstants.textSecondary, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Meta row
            Text(
              '$base ← $head · $commits commit${commits == 1 ? '' : 's'}',
              style: const TextStyle(
                  color: ThemeConstants.textSecondary, fontSize: 10),
            ),
            // CI chips
            if (_checkRuns.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _checkRuns.map((c) {
                  final name = c['name'] as String? ?? '';
                  final conclusion = c['conclusion'] as String?;
                  final status = c['status'] as String? ?? '';
                  final icon = conclusion == 'success'
                      ? '✓'
                      : conclusion == 'failure'
                          ? '✗'
                          : '⏳';
                  final color = conclusion == 'success'
                      ? Colors.green
                      : conclusion == 'failure'
                          ? Colors.red
                          : const Color(0xFFFFAA00);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                      '$icon $name',
                      style: TextStyle(color: color, fontSize: 9),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            // Footer actions
            Row(
              children: [
                if (!_approved && !_merged)
                  TextButton(
                    onPressed: _approve,
                    child: const Text('✓ Approve',
                        style: TextStyle(fontSize: 11)),
                  )
                else if (_approved)
                  const Text('Approved ✓',
                      style: TextStyle(
                          color: Colors.green, fontSize: 11)),
                const SizedBox(width: 8),
                if (!_merged)
                  TextButton(
                    onPressed: _merge,
                    child: const Text('Merge ↓',
                        style: TextStyle(fontSize: 11)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Process.run('open', [htmlUrl]),
                  child: const Text('Open on GitHub ↗',
                      style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 7.2: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 7.3: Commit**

  ```bash
  git add lib/features/chat/widgets/pr_card.dart
  git commit -m "feat: PRCard — CI chips, approve/merge, 30s polling"
  ```

---

## Task 8: Multi-remote Push split button

**Files:**
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 8.1: Verify `GitService.listRemotes` and `pushToRemote` exist**

  Phase 3 added `listRemotes()`, `pushToRemote(String remote)`, and `getOriginUrl()` to `lib/services/git/git_service.dart`. Verify all three are present before proceeding. **Read `top_action_bar.dart` in full before editing** — `_CommitPushButton` is a full `ConsumerStatefulWidget` (~400+ lines) with AI commit message generation and PR creation already wired up from Phase 3.

- [ ] **Step 8.2: Load remote list in `_CommitPushButtonState`**

  In the existing `_CommitPushButtonState` class (from Phase 3), add remote-list state:

  ```dart
  List<GitRemote> _remotes = [];
  String _selectedRemote = 'origin';

  // In initState, alongside _checkBehindCount():
  _loadRemotes();

  Future<void> _loadRemotes() async {
    final remotes = await GitService(widget.project.path).listRemotes();
    if (mounted) {
      setState(() {
        _remotes = remotes;
        if (remotes.isNotEmpty &&
            !remotes.any((r) => r.name == _selectedRemote)) {
          _selectedRemote = remotes.first.name;
        }
      });
    }
  }
  ```

- [ ] **Step 8.3: Update `_doPush` to use selected remote, and add multi-remote dropdown**

  In `_doPush`:

  ```dart
  Future<void> _doPush() async {
    setState(() => _pushing = true);
    try {
      if (_remotes.length <= 1) {
        await GitService(widget.project.path).push();
      } else {
        await GitService(widget.project.path).pushToRemote(_selectedRemote);
      }
      // ... existing success handling
    }
    // ... existing error handling
  }
  ```

  In the `build` method, when `_remotes.length > 1`, add the remote picker to the Push dropdown:

  ```dart
  // Inside the dropdown itemBuilder, before the Push item:
  if (_remotes.length > 1) ...[
    for (final remote in _remotes)
      CheckedPopupMenuItem<String>(
        value: 'select_${remote.name}',
        checked: _selectedRemote == remote.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(remote.name,
                style: const TextStyle(fontSize: 11)),
            Text(remote.url,
                style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF888888))),
          ],
        ),
      ),
    const PopupMenuDivider(),
    const PopupMenuItem(
      value: 'push_all',
      child: Text('Push to all remotes',
          style: TextStyle(fontSize: 11)),
    ),
    const PopupMenuDivider(),
  ],
  ```

  Handle the new actions in `onSelected`:

  ```dart
  case 'push_all':
    for (final remote in _remotes) {
      await GitService(widget.project.path).pushToRemote(remote.name);
    }
  default:
    if (value.startsWith('select_')) {
      setState(() => _selectedRemote = value.substring(7));
    }
  ```

- [ ] **Step 8.4: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 8.5: Commit**

  ```bash
  git add lib/shell/widgets/top_action_bar.dart
  git commit -m "feat: multi-remote Push split button in top action bar"
  ```

---

## Task 9: Final checks

- [ ] **Step 9.1: Run full test suite**

  ```bash
  flutter test
  ```

- [ ] **Step 9.2: Format**

  ```bash
  dart format lib/ test/
  ```

- [ ] **Step 9.3: Analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 9.4: Manual smoke test**

  Run `flutter run -d macos` and verify:
  - Assistant messages with `toolEvents` render collapsed tool-call rows
  - Expanding a row shows input/output/metrics
  - Unnamed code fences show "Diff…" button; clicking expands path picker
  - Changes panel shows "edited" badge when file was externally modified; revert triggers merge view
  - Push button shows remote selector dropdown for multi-remote repos
  - PR card renders with CI chips and approve/merge actions
