# Phase 2 — Code Change Cards & Changes Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add inline diff/apply cards to code blocks that have a filename in their fence, and a session-level changes panel that tracks every applied file with per-entry revert.

**Architecture:** `AppliedChange` records live in-memory in a keepAlive `AppliedChangesNotifier` keyed by `sessionId`. `ApplyService` orchestrates read-snapshot→write→notify. The changes panel in `ChatShell` watches the notifier and renders as a 190 px side panel toggled from the status bar. The diff card expands inline inside `_CodeBlockWidget` when a filename is found in the code fence.

**Tech Stack:** Flutter, Riverpod (keepAlive notifiers), `freezed`, `diff_match_patch` (new), `dart:io` for git `Process.run`.

---

## File Map

| Status | File | Responsibility |
|---|---|---|
| Modify | `pubspec.yaml` | Add `diff_match_patch: ^0.4.1` |
| **Create** | `lib/data/models/applied_change.dart` | `@freezed` in-memory model; no DB |
| Modify | `lib/features/chat/chat_notifier.dart` | Add `AppliedChangesNotifier` + `ChangesPanelVisible` |
| **Create** | `lib/services/apply/apply_service.dart` | Apply + revert filesystem logic + Riverpod provider |
| Modify | `lib/features/chat/widgets/message_bubble.dart` | Parse filename from fence; Diff button; inline change card |
| **Create** | `lib/features/chat/widgets/changes_panel.dart` | Session changes panel widget |
| Modify | `lib/shell/chat_shell.dart` | Panel layout slot right of chat column |
| Modify | `lib/shell/widgets/status_bar.dart` | `● N changes` indicator |

---

## Task 1: Add `diff_match_patch` package + `AppliedChange` model

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/data/models/applied_change.dart`

- [ ] **Step 1.1: Add dependency to pubspec.yaml**

  In `pubspec.yaml`, under `dependencies:`, after the `uuid:` line add:

  ```yaml
    diff_match_patch: ^0.4.1
  ```

- [ ] **Step 1.2: Create the AppliedChange model**

  Create `lib/data/models/applied_change.dart`:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'applied_change.freezed.dart';

  @freezed
  class AppliedChange with _$AppliedChange {
    const factory AppliedChange({
      required String id,            // uuid
      required String sessionId,
      required String messageId,     // ChatMessage that contained the code block
      required String filePath,      // absolute path on disk
      String? originalContent,       // null = file didn't exist before Apply
      required String newContent,    // content that was written to disk
      required DateTime appliedAt,
    }) = _AppliedChange;
  }
  ```

  Note: `newContent` is not in the spec model but is needed for `+N −N` line counts in the panel.

- [ ] **Step 1.3: Run pub get + build_runner**

  ```bash
  cd /path/to/repo && flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `lib/data/models/applied_change.freezed.dart` generated with no errors.

- [ ] **Step 1.4: Verify analyze is clean**

  ```bash
  flutter analyze
  ```

  Expected: No issues.

- [ ] **Step 1.5: Commit**

  ```bash
  git add pubspec.yaml pubspec.lock lib/data/models/applied_change.dart lib/data/models/applied_change.freezed.dart
  git commit -m "feat: add diff_match_patch dep and AppliedChange model"
  ```

---

## Task 2: `AppliedChangesNotifier` + `ChangesPanelVisible`

**Files:**
- Modify: `lib/features/chat/chat_notifier.dart`
- Modify: `lib/features/chat/chat_notifier.g.dart` (via build_runner)
- Create: `test/features/chat/applied_changes_notifier_test.dart`

- [ ] **Step 2.1: Write failing tests**

  Create `test/features/chat/applied_changes_notifier_test.dart`:

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/applied_change.dart';
  import 'package:code_bench_app/features/chat/chat_notifier.dart';

  AppliedChange _change({
    String id = 'c1',
    String sessionId = 'sid',
    String messageId = 'mid',
    String filePath = '/tmp/foo.dart',
    String newContent = 'new',
    String? originalContent = 'old',
  }) =>
      AppliedChange(
        id: id,
        sessionId: sessionId,
        messageId: messageId,
        filePath: filePath,
        originalContent: originalContent,
        newContent: newContent,
        appliedAt: DateTime(2026),
      );

  void main() {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('apply adds change to correct session', () {
      final notifier = container.read(appliedChangesProvider.notifier);
      notifier.apply(_change(sessionId: 'sid', id: 'c1'));
      notifier.apply(_change(sessionId: 'sid', id: 'c2'));
      notifier.apply(_change(sessionId: 'other', id: 'c3'));

      final forSid = container.read(appliedChangesProvider)['sid']!;
      expect(forSid.length, 2);
      expect(forSid.map((c) => c.id), containsAll(['c1', 'c2']));

      final forOther = container.read(appliedChangesProvider)['other']!;
      expect(forOther.length, 1);
    });

    test('revert removes the change by id', () {
      final notifier = container.read(appliedChangesProvider.notifier);
      notifier.apply(_change(id: 'c1'));
      notifier.apply(_change(id: 'c2'));
      notifier.revert('c1');

      final changes = container.read(appliedChangesProvider)['sid']!;
      expect(changes.map((c) => c.id), ['c2']);
    });

    test('changesForSession returns empty list when no changes', () {
      final notifier = container.read(appliedChangesProvider.notifier);
      expect(notifier.changesForSession('nobody'), isEmpty);
    });

    test('ChangesPanelVisible toggles', () {
      final notifier = container.read(changesPanelVisibleProvider.notifier);
      expect(container.read(changesPanelVisibleProvider), false);
      notifier.toggle();
      expect(container.read(changesPanelVisibleProvider), true);
      notifier.toggle();
      expect(container.read(changesPanelVisibleProvider), false);
    });
  }
  ```

- [ ] **Step 2.2: Run tests to confirm they fail**

  ```bash
  flutter test test/features/chat/applied_changes_notifier_test.dart
  ```

  Expected: FAIL — `appliedChangesProvider` not found.

- [ ] **Step 2.3: Add notifiers to `chat_notifier.dart`**

  Add these two classes at the bottom of `lib/features/chat/chat_notifier.dart` (after the existing providers, before the end of file):

  ```dart
  import '../../data/models/applied_change.dart';
  ```

  Add the import at the top of the file alongside existing imports, then append:

  ```dart
  // ── Applied changes (in-memory, keyed by sessionId) ─────────────────────────

  @Riverpod(keepAlive: true)
  class AppliedChanges extends _$AppliedChanges {
    @override
    Map<String, List<AppliedChange>> build() => {};

    void apply(AppliedChange change) {
      final list = [...(state[change.sessionId] ?? []), change];
      state = {...state, change.sessionId: list};
    }

    void revert(String id) {
      state = {
        for (final entry in state.entries)
          entry.key: entry.value.where((c) => c.id != id).toList(),
      };
    }

    List<AppliedChange> changesForSession(String sessionId) =>
        state[sessionId] ?? [];
  }

  // ── Changes panel visibility ─────────────────────────────────────────────────

  @Riverpod(keepAlive: true)
  class ChangesPanelVisible extends _$ChangesPanelVisible {
    @override
    bool build() => false;

    void toggle() => state = !state;
    void hide() => state = false;
  }
  ```

  The full updated import block at the top of `chat_notifier.dart`:

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../data/models/ai_model.dart';
  import '../../data/models/applied_change.dart';
  import '../../data/models/chat_message.dart';
  import '../../data/models/chat_session.dart';
  import '../../services/session/session_service.dart';

  part 'chat_notifier.g.dart';
  ```

- [ ] **Step 2.4: Regenerate**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `chat_notifier.g.dart` updated; no errors.

- [ ] **Step 2.5: Run tests to confirm they pass**

  ```bash
  flutter test test/features/chat/applied_changes_notifier_test.dart
  ```

  Expected: All 4 tests PASS.

- [ ] **Step 2.6: Commit**

  ```bash
  git add lib/features/chat/chat_notifier.dart lib/features/chat/chat_notifier.g.dart \
    test/features/chat/applied_changes_notifier_test.dart
  git commit -m "feat: add AppliedChangesNotifier and ChangesPanelVisible to chat_notifier"
  ```

---

## Task 3: `ApplyService`

**Files:**
- Create: `lib/services/apply/apply_service.dart`
- Create: `test/services/apply/apply_service_test.dart`

- [ ] **Step 3.1: Write failing tests**

  Create `test/services/apply/apply_service_test.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/applied_change.dart';
  import 'package:code_bench_app/features/chat/chat_notifier.dart';
  import 'package:code_bench_app/services/apply/apply_service.dart';
  import 'package:code_bench_app/services/filesystem/filesystem_service.dart';

  void main() {
    late Directory tmpDir;
    late ProviderContainer container;
    late ApplyService service;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('apply_test_');
      container = ProviderContainer();
      service = ApplyService(
        fs: FilesystemService(),
        notifier: container.read(appliedChangesProvider.notifier),
        uuidGen: () => 'test-uuid',
      );
    });

    tearDown(() async {
      container.dispose();
      await tmpDir.delete(recursive: true);
    });

    test('apply creates file and records change when file did not exist', () async {
      final filePath = '${tmpDir.path}/new_file.dart';
      await service.applyChange(
        filePath: filePath,
        newContent: 'void main() {}',
        sessionId: 'sid',
        messageId: 'mid',
      );

      // File is written to disk
      expect(File(filePath).existsSync(), true);
      expect(File(filePath).readAsStringSync(), 'void main() {}');

      // Change is recorded with null originalContent (file didn't exist)
      final changes = container.read(appliedChangesProvider)['sid']!;
      expect(changes.length, 1);
      expect(changes.first.originalContent, isNull);
      expect(changes.first.newContent, 'void main() {}');
      expect(changes.first.filePath, filePath);
      expect(changes.first.id, 'test-uuid');
    });

    test('apply snapshots original content when file exists', () async {
      final filePath = '${tmpDir.path}/existing.dart';
      File(filePath).writeAsStringSync('original content');

      await service.applyChange(
        filePath: filePath,
        newContent: 'updated content',
        sessionId: 'sid',
        messageId: 'mid',
      );

      final changes = container.read(appliedChangesProvider)['sid']!;
      expect(changes.first.originalContent, 'original content');
      expect(File(filePath).readAsStringSync(), 'updated content');
    });

    test('revert (non-git) writes back original content', () async {
      final filePath = '${tmpDir.path}/file.dart';
      File(filePath).writeAsStringSync('original');

      await service.applyChange(
        filePath: filePath,
        newContent: 'changed',
        sessionId: 'sid',
        messageId: 'mid',
      );

      final change = container.read(appliedChangesProvider)['sid']!.first;
      await service.revertChange(
        change: change,
        isGit: false,
        projectPath: tmpDir.path,
      );

      expect(File(filePath).readAsStringSync(), 'original');

      // Entry removed from notifier
      final remaining = container.read(appliedChangesProvider)['sid'] ?? [];
      expect(remaining, isEmpty);
    });

    test('revert (non-git) deletes file when originalContent is null', () async {
      final filePath = '${tmpDir.path}/new.dart';
      await service.applyChange(
        filePath: filePath,
        newContent: 'new file content',
        sessionId: 'sid',
        messageId: 'mid',
      );

      final change = container.read(appliedChangesProvider)['sid']!.first;
      await service.revertChange(
        change: change,
        isGit: false,
        projectPath: tmpDir.path,
      );

      expect(File(filePath).existsSync(), false);
    });
  }
  ```

- [ ] **Step 3.2: Run tests to confirm they fail**

  ```bash
  flutter test test/services/apply/apply_service_test.dart
  ```

  Expected: FAIL — `ApplyService` not found.

- [ ] **Step 3.3: Create `ApplyService`**

  Create `lib/services/apply/apply_service.dart`:

  ```dart
  import 'dart:io';

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import 'package:uuid/uuid.dart';

  import '../../data/models/applied_change.dart';
  import '../../features/chat/chat_notifier.dart';
  import '../filesystem/filesystem_service.dart';

  part 'apply_service.g.dart';

  @Riverpod(keepAlive: true)
  ApplyService applyService(Ref ref) {
    return ApplyService(
      fs: ref.watch(filesystemServiceProvider),
      notifier: ref.read(appliedChangesProvider.notifier),
    );
  }

  class ApplyService {
    ApplyService({
      required FilesystemService fs,
      required AppliedChanges notifier,
      String Function()? uuidGen,
    })  : _fs = fs,
          _notifier = notifier,
          _uuidGen = uuidGen ?? (() => const Uuid().v4());

    final FilesystemService _fs;
    final AppliedChanges _notifier;
    final String Function() _uuidGen;

    Future<void> applyChange({
      required String filePath,
      required String newContent,
      required String sessionId,
      required String messageId,
    }) async {
      String? originalContent;
      try {
        originalContent = await _fs.readFile(filePath);
      } catch (_) {
        // File doesn't exist — originalContent stays null
      }

      await _fs.writeFile(filePath, newContent);

      _notifier.apply(AppliedChange(
        id: _uuidGen(),
        sessionId: sessionId,
        messageId: messageId,
        filePath: filePath,
        originalContent: originalContent,
        newContent: newContent,
        appliedAt: DateTime.now(),
      ));
    }

    Future<void> revertChange({
      required AppliedChange change,
      required bool isGit,
      required String projectPath,
    }) async {
      if (change.originalContent == null) {
        // File was created by Apply — delete it
        await _fs.deleteFile(change.filePath);
      } else if (isGit) {
        await Process.run(
          'git',
          ['checkout', '--', change.filePath],
          workingDirectory: projectPath,
        );
      } else {
        await _fs.writeFile(change.filePath, change.originalContent!);
      }

      _notifier.revert(change.id);
    }
  }
  ```

- [ ] **Step 3.4: Regenerate**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `lib/services/apply/apply_service.g.dart` created.

- [ ] **Step 3.5: Run tests to confirm they pass**

  ```bash
  flutter test test/services/apply/apply_service_test.dart
  ```

  Expected: All 4 tests PASS.

- [ ] **Step 3.6: Commit**

  ```bash
  git add lib/services/apply/ test/services/apply/
  git commit -m "feat: add ApplyService with apply and revert filesystem logic"
  ```

---

## Task 4: Diff button + inline change card in `message_bubble.dart`

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`
- Modify: `test/features/chat/widgets/message_bubble_test.dart`

### Context: what changes

`_CodeBlockBuilder` currently passes the full info string (e.g. `dart lib/main.dart`) as `language` to `_CodeBlockWidget`. We split it to extract the actual language and an optional filename. `_CodeBlockWidget` gains:
- A **Diff** button in the header (visible only when `filename != null`)
- Inline expansion into a change card with **Before / Diff / After** tabs and **Apply** / **Collapse** buttons when Diff is clicked

`_CodeBlockBuilder` also receives `messageId` and `sessionId` from `_MessageContent` so the Apply action can record which message triggered it.

### Filename parsing helper

- [ ] **Step 4.1: Write failing test for filename parsing and Diff button visibility**

  Add to `test/features/chat/widgets/message_bubble_test.dart`:

  ```dart
  import 'package:code_bench_app/features/chat/widgets/message_bubble.dart'
      show parseCodeFenceInfo;

  // ... inside main() ...

  group('parseCodeFenceInfo', () {
    test('returns language only when no filename', () {
      final result = parseCodeFenceInfo('dart');
      expect(result.$1, 'dart');
      expect(result.$2, isNull);
    });

    test('returns language and filename when both present', () {
      final result = parseCodeFenceInfo('dart lib/auth/middleware.dart');
      expect(result.$1, 'dart');
      expect(result.$2, 'lib/auth/middleware.dart');
    });

    test('handles filename with spaces via second+ word join', () {
      final result = parseCodeFenceInfo('dart path with spaces/file.dart');
      expect(result.$1, 'dart');
      expect(result.$2, 'path with spaces/file.dart');
    });
  });
  ```

  Also add an import at the top:
  ```dart
  import 'package:code_bench_app/features/chat/widgets/message_bubble.dart'
      show parseCodeFenceInfo;
  ```

  (The `show parseCodeFenceInfo` import exposes only the helper so the test stays narrow.)

- [ ] **Step 4.2: Run test to confirm it fails**

  ```bash
  flutter test test/features/chat/widgets/message_bubble_test.dart
  ```

  Expected: FAIL — `parseCodeFenceInfo` not found.

- [ ] **Step 4.3: Rewrite `message_bubble.dart`**

  Replace the full file content with the following. The key changes are:
  1. Add `parseCodeFenceInfo` top-level function (exported for tests)
  2. `_CodeBlockBuilder` now carries `messageId` + `sessionId`, passes to `_CodeBlockWidget`
  3. `_CodeBlockWidget` shows Diff button when `filename != null`; expands to change card

  Full file:

  ```dart
  import 'dart:io';

  import 'package:diff_match_patch/diff_match_patch.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_highlight/flutter_highlight.dart';
  import 'package:flutter_highlight/themes/vs2015.dart';
  import 'package:flutter_markdown/flutter_markdown.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';
  import 'package:path/path.dart' as p;

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/chat_message.dart';
  import '../../../features/project_sidebar/project_sidebar_notifier.dart';
  import '../../../services/apply/apply_service.dart';
  import '../chat_notifier.dart';

  // ── Public helper (also used by tests) ───────────────────────────────────────

  /// Splits a code fence info string (e.g. "dart lib/main.dart") into
  /// (language, filename?). Filename is null if no second word is present.
  (String language, String? filename) parseCodeFenceInfo(String info) {
    final parts = info.split(' ');
    final language = parts.first;
    final filename = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    return (language, filename);
  }

  // ── MessageBubble ─────────────────────────────────────────────────────────────

  class MessageBubble extends ConsumerWidget {
    const MessageBubble({super.key, required this.message});

    final ChatMessage message;

    bool get _isUser => message.role == MessageRole.user;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _isUser
            ? _UserBubble(message: message)
            : _AssistantBubble(message: message, ref: ref),
      );
    }
  }

  // ── User bubble ──────────────────────────────────────────────────────────────

  class _UserBubble extends StatelessWidget {
    const _UserBubble({required this.message});
    final ChatMessage message;

    @override
    Widget build(BuildContext context) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: ThemeConstants.userMessageBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              message.content,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: ThemeConstants.uiFontSize,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }
  }

  // ── Assistant bubble ─────────────────────────────────────────────────────────

  class _AssistantBubble extends StatelessWidget {
    const _AssistantBubble({required this.message, required this.ref});
    final ChatMessage message;
    final WidgetRef ref;

    @override
    Widget build(BuildContext context) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            margin: const EdgeInsets.only(top: 3, bottom: 3),
            color: ThemeConstants.borderColor,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isStreaming) const StreamingDot(),
                _MessageContent(message: message, ref: ref),
              ],
            ),
          ),
        ],
      );
    }
  }

  // ── Streaming dot ────────────────────────────────────────────────────────────

  class StreamingDot extends StatefulWidget {
    const StreamingDot({super.key});

    @override
    State<StreamingDot> createState() => _StreamingDotState();
  }

  class _StreamingDotState extends State<StreamingDot>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _opacity;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      )..repeat(reverse: true);
      _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: FadeTransition(
          opacity: _opacity,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: ThemeConstants.success,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
  }

  // ── Message content ───────────────────────────────────────────────────────────

  class _MessageContent extends StatelessWidget {
    const _MessageContent({required this.message, required this.ref});
    final ChatMessage message;
    final WidgetRef ref;

    @override
    Widget build(BuildContext context) {
      if (message.role == MessageRole.user) {
        return SelectableText(
          message.content,
          style: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: ThemeConstants.uiFontSize,
            height: 1.5,
          ),
        );
      }
      return MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: ThemeConstants.uiFontSize,
            height: 1.65,
          ),
          code: const TextStyle(
            fontFamily: ThemeConstants.editorFontFamily,
            backgroundColor: ThemeConstants.codeBlockBg,
            color: ThemeConstants.syntaxString,
            fontSize: ThemeConstants.uiFontSizeSmall,
          ),
          codeblockDecoration: BoxDecoration(
            color: ThemeConstants.codeBlockBg,
            borderRadius: BorderRadius.circular(6),
          ),
          h1: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          h2: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          h3: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          blockquote:
              const TextStyle(color: ThemeConstants.textSecondary),
          listBullet:
              const TextStyle(color: ThemeConstants.textPrimary),
        ),
        builders: {
          'code': _CodeBlockBuilder(
            ref: ref,
            messageId: message.id,
            sessionId: message.sessionId,
          ),
        },
      );
    }
  }

  // ── Code block builder ───────────────────────────────────────────────────────

  class _CodeBlockBuilder extends MarkdownElementBuilder {
    _CodeBlockBuilder({
      required this.ref,
      required this.messageId,
      required this.sessionId,
    });
    final WidgetRef ref;
    final String messageId;
    final String sessionId;

    @override
    Widget? visitElementAfter(element, TextStyle? preferredStyle) {
      final fullInfo =
          element.attributes['class']?.replaceFirst('language-', '') ??
              'plaintext';
      final code = element.textContent;

      if (!element.attributes.containsKey('class') && !code.contains('\n')) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: ThemeConstants.codeBlockBg,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            code,
            style: const TextStyle(
              fontFamily: ThemeConstants.editorFontFamily,
              color: ThemeConstants.syntaxString,
              fontSize: ThemeConstants.uiFontSize,
            ),
          ),
        );
      }

      final (language, filename) = parseCodeFenceInfo(fullInfo);
      return _CodeBlockWidget(
        code: code,
        language: language,
        filename: filename,
        messageId: messageId,
        sessionId: sessionId,
        ref: ref,
      );
    }
  }

  // ── Code block widget ─────────────────────────────────────────────────────────

  enum _DiffCardState { hidden, loading, loaded, error }

  class _CodeBlockWidget extends StatefulWidget {
    const _CodeBlockWidget({
      required this.code,
      required this.language,
      this.filename,
      required this.messageId,
      required this.sessionId,
      required this.ref,
    });
    final String code;
    final String language;
    final String? filename;
    final String messageId;
    final String sessionId;
    final WidgetRef ref;

    @override
    State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
  }

  class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
    _DiffCardState _diffState = _DiffCardState.hidden;
    String? _originalContent;
    List<Diff>? _diffs;
    String? _diffError;
    int _activeTab = 1; // 0=Before, 1=Diff, 2=After
    bool _applying = false;

    Future<void> _loadDiff() async {
      setState(() => _diffState = _DiffCardState.loading);
      try {
        final projectId = widget.ref.read(activeProjectIdProvider);
        final projects =
            widget.ref.read(projectsProvider).valueOrNull ?? [];
        final project = projects.cast<dynamic>().firstWhere(
              (p) => p.id == projectId,
              orElse: () => null,
            );
        if (project == null) throw Exception('No active project');

        final absolutePath = p.join(project.path as String, widget.filename!);

        String? original;
        try {
          original = await File(absolutePath).readAsString();
        } catch (_) {
          original = null; // file doesn't exist yet
        }

        final dmp = DiffMatchPatch();
        final diffs = dmp.diff_main(original ?? '', widget.code);
        dmp.diff_cleanupSemantic(diffs);

        setState(() {
          _originalContent = original;
          _diffs = diffs;
          _diffState = _DiffCardState.loaded;
        });
      } catch (e) {
        setState(() {
          _diffError = e.toString();
          _diffState = _DiffCardState.error;
        });
      }
    }

    Future<void> _applyChange() async {
      setState(() => _applying = true);
      try {
        final projectId = widget.ref.read(activeProjectIdProvider);
        final projects =
            widget.ref.read(projectsProvider).valueOrNull ?? [];
        final project = projects.cast<dynamic>().firstWhere(
              (p) => p.id == projectId,
              orElse: () => null,
            );
        if (project == null) return;

        final absolutePath = p.join(project.path as String, widget.filename!);
        await widget.ref.read(applyServiceProvider).applyChange(
              filePath: absolutePath,
              newContent: widget.code,
              sessionId: widget.sessionId,
              messageId: widget.messageId,
            );

        // Show panel when first change is applied
        widget.ref.read(changesPanelVisibleProvider.notifier).state = true;

        setState(() => _diffState = _DiffCardState.hidden);
      } finally {
        if (mounted) setState(() => _applying = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: ThemeConstants.codeBlockBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ThemeConstants.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (_diffState == _DiffCardState.loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              )
            else if (_diffState == _DiffCardState.loaded)
              _buildDiffCard()
            else if (_diffState == _DiffCardState.error)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _diffError ?? 'Error computing diff',
                  style: const TextStyle(
                    color: ThemeConstants.error,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HighlightView(
                  widget.code,
                  language: widget.language,
                  theme: vs2015Theme,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(
                    fontFamily: ThemeConstants.editorFontFamily,
                    fontSize: ThemeConstants.editorFontSize,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget _buildHeader() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
        ),
        child: Row(
          children: [
            Text(
              widget.language,
              style: const TextStyle(
                color: ThemeConstants.mutedFg,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontFamily: ThemeConstants.editorFontFamily,
              ),
            ),
            if (widget.filename != null) ...[
              const SizedBox(width: 6),
              Text(
                widget.filename!,
                style: const TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  fontFamily: ThemeConstants.editorFontFamily,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            if (widget.filename != null && _diffState == _DiffCardState.hidden)
              _HeaderButton(
                label: 'Diff',
                icon: LucideIcons.gitCompare,
                onTap: _loadDiff,
              ),
            if (_diffState == _DiffCardState.loaded) ...[
              _HeaderButton(
                label: _applying ? 'Applying...' : 'Apply',
                icon: _applying ? LucideIcons.hourglass : LucideIcons.download,
                onTap: _applying ? null : _applyChange,
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                label: 'Collapse',
                icon: LucideIcons.chevronUp,
                onTap: () =>
                    setState(() => _diffState = _DiffCardState.hidden),
              ),
            ],
            const SizedBox(width: 12),
            _CopyButton(code: widget.code),
          ],
        ),
      );
    }

    Widget _buildDiffCard() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
            ),
            child: Row(
              children: [
                _Tab(label: 'Before', index: 0, activeIndex: _activeTab,
                    onTap: (i) => setState(() => _activeTab = i)),
                _Tab(label: 'Diff', index: 1, activeIndex: _activeTab,
                    onTap: (i) => setState(() => _activeTab = i)),
                _Tab(label: 'After', index: 2, activeIndex: _activeTab,
                    onTap: (i) => setState(() => _activeTab = i)),
              ],
            ),
          ),
          // Tab content
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: _activeTab == 0
                  ? _buildPlainContent(_originalContent ?? '(new file)')
                  : _activeTab == 2
                      ? _buildPlainContent(widget.code)
                      : _buildDiffContent(),
            ),
          ),
        ],
      );
    }

    Widget _buildPlainContent(String content) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: HighlightView(
          content,
          language: widget.language,
          theme: vs2015Theme,
          padding: const EdgeInsets.all(12),
          textStyle: const TextStyle(
            fontFamily: ThemeConstants.editorFontFamily,
            fontSize: ThemeConstants.editorFontSize,
            height: 1.5,
          ),
        ),
      );
    }

    Widget _buildDiffContent() {
      final diffs = _diffs ?? [];
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: diffs.map((diff) {
            final bg = diff.operation == DIFF_INSERT
                ? const Color(0x3300CC66)
                : diff.operation == DIFF_DELETE
                    ? const Color(0x33FF4444)
                    : Colors.transparent;
            final prefix = diff.operation == DIFF_INSERT
                ? '+'
                : diff.operation == DIFF_DELETE
                    ? '−'
                    : ' ';
            return Container(
              color: bg,
              width: double.infinity,
              child: Text(
                diff.text
                    .split('\n')
                    .map((line) => '$prefix $line')
                    .join('\n'),
                style: const TextStyle(
                  fontFamily: ThemeConstants.editorFontFamily,
                  fontSize: ThemeConstants.editorFontSize,
                  color: ThemeConstants.textPrimary,
                  height: 1.5,
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  // ── Small reusable header button ─────────────────────────────────────────────

  class _HeaderButton extends StatelessWidget {
    const _HeaderButton({
      required this.label,
      required this.icon,
      required this.onTap,
    });
    final String label;
    final IconData icon;
    final VoidCallback? onTap;

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: ThemeConstants.mutedFg),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: ThemeConstants.mutedFg,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
          ],
        ),
      );
    }
  }

  // ── Tab ───────────────────────────────────────────────────────────────────────

  class _Tab extends StatelessWidget {
    const _Tab({
      required this.label,
      required this.index,
      required this.activeIndex,
      required this.onTap,
    });
    final String label;
    final int index;
    final int activeIndex;
    final void Function(int) onTap;

    @override
    Widget build(BuildContext context) {
      final isActive = index == activeIndex;
      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? ThemeConstants.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: ThemeConstants.uiFontSizeSmall,
              color: isActive
                  ? ThemeConstants.textPrimary
                  : ThemeConstants.mutedFg,
            ),
          ),
        ),
      );
    }
  }

  // ── Copy button ───────────────────────────────────────────────────────────────

  class _CopyButton extends StatefulWidget {
    const _CopyButton({required this.code});
    final String code;

    @override
    State<_CopyButton> createState() => _CopyButtonState();
  }

  class _CopyButtonState extends State<_CopyButton> {
    bool _copied = false;

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: widget.code));
          setState(() => _copied = true);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _copied = false);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? LucideIcons.check : LucideIcons.copy,
              size: 12,
              color: ThemeConstants.mutedFg,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? 'Copied' : 'Copy',
              style: const TextStyle(
                color: ThemeConstants.mutedFg,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 4.4: Run tests**

  ```bash
  flutter test test/features/chat/widgets/message_bubble_test.dart
  ```

  Expected: All tests (original 3 + new 3 parseCodeFenceInfo tests) PASS.

- [ ] **Step 4.5: Analyze**

  ```bash
  flutter analyze
  ```

  Expected: No issues.

- [ ] **Step 4.6: Commit**

  ```bash
  git add lib/features/chat/widgets/message_bubble.dart \
    test/features/chat/widgets/message_bubble_test.dart
  git commit -m "feat: add Diff button and inline change card to code blocks"
  ```

---

## Task 5: `ChangesPanel` widget

**Files:**
- Create: `lib/features/chat/widgets/changes_panel.dart`

This widget is wired into the shell in Task 6. No separate test here — it's a pure display widget that watches providers already tested in Task 2.

- [ ] **Step 5.1: Create `changes_panel.dart`**

  Create `lib/features/chat/widgets/changes_panel.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';
  import 'package:path/path.dart' as p;

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/applied_change.dart';
  import '../../../data/models/project.dart';
  import '../../../features/project_sidebar/project_sidebar_notifier.dart';
  import '../../../services/apply/apply_service.dart';
  import '../chat_notifier.dart';

  class ChangesPanel extends ConsumerWidget {
    const ChangesPanel({super.key, required this.sessionId});

    final String sessionId;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final allChanges = ref.watch(appliedChangesProvider);
      final changes = allChanges[sessionId] ?? [];

      // Group changes by messageId preserving order
      final grouped = <String, List<AppliedChange>>{};
      for (final change in changes) {
        grouped.putIfAbsent(change.messageId, () => []).add(change);
      }

      // Resolve project for isGit + path
      final projectId = ref.watch(activeProjectIdProvider);
      final project = ref
          .watch(projectsProvider)
          .valueOrNull
          ?.cast<Project?>()
          .firstWhere((p) => p?.id == projectId, orElse: () => null);

      return Container(
        decoration: const BoxDecoration(
          color: ThemeConstants.sidebarBackground,
          border: Border(left: BorderSide(color: ThemeConstants.borderColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: ThemeConstants.borderColor)),
              ),
              child: const Text(
                'Changes',
                style: TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Change entries
            Expanded(
              child: changes.isEmpty
                  ? const Center(
                      child: Text(
                        'No changes yet',
                        style: TextStyle(
                          color: ThemeConstants.mutedFg,
                          fontSize: ThemeConstants.uiFontSizeSmall,
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: grouped.entries.expand((entry) {
                        return [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                            child: Text(
                              'Message',
                              style: const TextStyle(
                                color: ThemeConstants.faintFg,
                                fontSize: ThemeConstants.uiFontSizeLabel,
                              ),
                            ),
                          ),
                          ...entry.value.map(
                            (change) => _ChangeEntry(
                              change: change,
                              project: project,
                              onRevert: () => ref
                                  .read(applyServiceProvider)
                                  .revertChange(
                                    change: change,
                                    isGit: project?.isGit ?? false,
                                    projectPath: project?.path ?? '',
                                  ),
                            ),
                          ),
                        ];
                      }).toList(),
                    ),
            ),
            // Footer — stub "Commit all" button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: ThemeConstants.borderColor)),
              ),
              child: GestureDetector(
                onTap: () {
                  // Phase 3: wire to git commit flow
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Commit all',
                      style: TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(LucideIcons.arrowRight,
                        size: 11, color: ThemeConstants.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ── Single change entry ───────────────────────────────────────────────────────

  class _ChangeEntry extends StatelessWidget {
    const _ChangeEntry({
      required this.change,
      required this.project,
      required this.onRevert,
    });

    final AppliedChange change;
    final Project? project;
    final VoidCallback onRevert;

    /// Compute +N −N from original vs new content.
    (int additions, int deletions) get _lineCounts {
      final originalLines =
          (change.originalContent ?? '').split('\n');
      final newLines = change.newContent.split('\n');

      // Naive count: lines only in new = additions, only in original = deletions
      final added = newLines.length - originalLines.length;
      return added >= 0 ? (added, 0) : (0, -added);
    }

    @override
    Widget build(BuildContext context) {
      final filename = p.basename(change.filePath);
      final relativePath = project != null
          ? p.relative(change.filePath, from: project!.path)
          : change.filePath;

      final (additions, deletions) = _lineCounts;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style: const TextStyle(
                      fontFamily: ThemeConstants.editorFontFamily,
                      color: ThemeConstants.textPrimary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    relativePath,
                    style: const TextStyle(
                      color: ThemeConstants.mutedFg,
                      fontSize: ThemeConstants.uiFontSizeLabel,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Line counts
            Text(
              '+$additions',
              style: const TextStyle(
                color: Color(0xFF4EC9B0),
                fontSize: ThemeConstants.uiFontSizeLabel,
                fontFamily: ThemeConstants.editorFontFamily,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              '−$deletions',
              style: const TextStyle(
                color: ThemeConstants.error,
                fontSize: ThemeConstants.uiFontSizeLabel,
                fontFamily: ThemeConstants.editorFontFamily,
              ),
            ),
            const SizedBox(width: 6),
            // Revert button
            GestureDetector(
              onTap: onRevert,
              child: const Icon(
                LucideIcons.undo2,
                size: 12,
                color: ThemeConstants.mutedFg,
              ),
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 5.2: Analyze**

  ```bash
  flutter analyze
  ```

  Expected: No issues.

- [ ] **Step 5.3: Commit**

  ```bash
  git add lib/features/chat/widgets/changes_panel.dart
  git commit -m "feat: add ChangesPanel widget"
  ```

---

## Task 6: Wire `ChatShell` — panel layout slot + toggle state

**Files:**
- Modify: `lib/shell/chat_shell.dart`

The current layout wraps everything in `Expanded(child: child)`. We insert a `Row` between `TopActionBar` and `StatusBar` that contains the main content plus the optional 190 px changes panel.

- [ ] **Step 6.1: Rewrite `chat_shell.dart`**

  Replace the full file:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';

  import '../core/constants/theme_constants.dart';
  import '../features/chat/chat_notifier.dart';
  import '../features/chat/widgets/changes_panel.dart';
  import '../features/project_sidebar/project_sidebar.dart';
  import '../features/project_sidebar/project_sidebar_notifier.dart';
  import '../services/session/session_service.dart';
  import 'widgets/status_bar.dart';
  import 'widgets/top_action_bar.dart';

  class ChatShell extends ConsumerWidget {
    const ChatShell({super.key, required this.child});

    final Widget child;

    Future<void> _newChat(WidgetRef ref, BuildContext context) async {
      final projectId = ref.read(activeProjectIdProvider);
      if (projectId == null) return;
      final model = ref.read(selectedModelProvider);
      final service = ref.read(sessionServiceProvider);
      final sessionId = await service.createSession(
        model: model,
        projectId: projectId,
      );
      ref.read(activeSessionIdProvider.notifier).set(sessionId);
      if (context.mounted) context.go('/chat/$sessionId');
    }

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final panelVisible = ref.watch(changesPanelVisibleProvider);
      final activeSessionId = ref.watch(activeSessionIdProvider);

      return Material(
        color: ThemeConstants.background,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
                () => _newChat(ref, context),
            const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                () => _newChat(ref, context),
            const SingleActivator(LogicalKeyboardKey.comma, meta: true):
                () => context.go('/settings'),
            const SingleActivator(LogicalKeyboardKey.comma, control: true):
                () => context.go('/settings'),
          },
          child: Focus(
            autofocus: true,
            child: Row(
              children: [
                // Sidebar
                const ProjectSidebar(),
                // Right panel
                Expanded(
                  child: Column(
                    children: [
                      const TopActionBar(),
                      // Chat content + optional changes panel
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: child),
                            if (panelVisible && activeSessionId != null)
                              SizedBox(
                                width: 190,
                                child: ChangesPanel(sessionId: activeSessionId),
                              ),
                          ],
                        ),
                      ),
                      const StatusBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 6.2: Analyze**

  ```bash
  flutter analyze
  ```

  Expected: No issues.

- [ ] **Step 6.3: Commit**

  ```bash
  git add lib/shell/chat_shell.dart
  git commit -m "feat: add changes panel layout slot to ChatShell"
  ```

---

## Task 7: Wire `status_bar.dart` — `● N changes` indicator

**Files:**
- Modify: `lib/shell/widgets/status_bar.dart`

Add a `● N changes` indicator on the right side of the status bar, visible only when there are changes for the current session. Clicking it toggles the changes panel.

- [ ] **Step 7.1: Rewrite `status_bar.dart`**

  Replace the full file:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../core/constants/theme_constants.dart';
  import '../../data/models/project.dart';
  import '../../features/chat/chat_notifier.dart';
  import '../../features/project_sidebar/project_sidebar_notifier.dart';

  class StatusBar extends ConsumerWidget {
    const StatusBar({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final projectId = ref.watch(activeProjectIdProvider);
      final projectsAsync = ref.watch(projectsProvider);
      final activeSessionId = ref.watch(activeSessionIdProvider);
      final panelVisible = ref.watch(changesPanelVisibleProvider);

      Project? activeProject;
      if (projectId != null) {
        activeProject = projectsAsync.whenOrNull(
          data: (list) {
            try {
              return list.firstWhere((p) => p.id == projectId);
            } catch (_) {
              return null;
            }
          },
        );
      }

      // Count changes for the current session
      int changeCount = 0;
      if (activeSessionId != null) {
        final allChanges = ref.watch(appliedChangesProvider);
        changeCount = allChanges[activeSessionId]?.length ?? 0;
      }

      return Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: ThemeConstants.activityBar,
          border: Border(top: BorderSide(color: ThemeConstants.borderColor)),
        ),
        child: Row(
          children: [
            // Left: Local indicator
            Icon(
              LucideIcons.hardDrive,
              size: 10,
              color: ThemeConstants.faintFg,
            ),
            const SizedBox(width: 5),
            Text(
              'Local',
              style: const TextStyle(
                color: ThemeConstants.faintFg,
                fontSize: ThemeConstants.uiFontSizeLabel,
              ),
            ),
            const Spacer(),
            // Centre-right: changes indicator (hidden when 0)
            if (changeCount > 0) ...[
              GestureDetector(
                onTap: () =>
                    ref.read(changesPanelVisibleProvider.notifier).toggle(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: panelVisible
                            ? ThemeConstants.accent
                            : ThemeConstants.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$changeCount ${changeCount == 1 ? 'change' : 'changes'}',
                      style: TextStyle(
                        color: panelVisible
                            ? ThemeConstants.accent
                            : ThemeConstants.warning,
                        fontSize: ThemeConstants.uiFontSizeLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            // Right: Git branch
            if (activeProject != null && activeProject.isGit) ...[
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: ThemeConstants.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                activeProject.currentBranch ?? 'unknown',
                style: const TextStyle(
                  color: ThemeConstants.success,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                ),
              ),
            ] else if (activeProject != null) ...[
              Text(
                'Not git',
                style: const TextStyle(
                  color: ThemeConstants.faintFg,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 7.2: Run full test suite**

  ```bash
  flutter test
  ```

  Expected: All tests pass.

- [ ] **Step 7.3: Format + analyze**

  ```bash
  dart format lib/ test/
  flutter analyze
  ```

  Expected: No issues.

- [ ] **Step 7.4: Commit**

  ```bash
  git add lib/shell/widgets/status_bar.dart
  git commit -m "feat: add N changes indicator to status bar wired to changes panel toggle"
  ```

---

## Self-Review

### Spec coverage check

| Spec requirement | Covered in |
|---|---|
| Diff button on code blocks with filename in fence | Task 4 |
| Reads file from disk, computes diff with `diff_match_patch` | Task 4 |
| Before / Diff / After tabs | Task 4 |
| Apply writes to disk + records in `AppliedChangesNotifier` | Task 3 + 4 |
| File doesn't exist → all lines as additions | Task 3 (originalContent=null) + Task 4 (Before shows "new file") |
| Existing unapplied edits → diff against current disk content | Task 4 (reads from disk at Diff time) |
| Changes panel: 190 px, right of chat | Task 5 + 6 |
| Panel toggle from `● N changes` in status bar | Task 7 |
| Hidden when no changes | Task 7 (changeCount == 0 guard) |
| Entries grouped by message | Task 5 |
| Filename + relative path + `+N −N` + ↩ revert | Task 5 |
| "Commit all →" stub button | Task 5 |
| Panel state survives open/close within session | Task 2 (keepAlive notifier) |
| `isGit` branches revert: git checkout vs write-back | Task 3 |
| File was new: delete on revert | Task 3 |
| `AppliedChange` model as specified | Task 1 (+ newContent added) |
| `AppliedChangesNotifier` keepAlive keyed by sessionId | Task 2 |
| `ApplyService` thin service | Task 3 |
| `diff_match_patch` added | Task 1 |

### Placeholder scan

None found — all steps contain full code.

### Type consistency

- `AppliedChange.id` / `AppliedChange.sessionId` / `AppliedChange.messageId` / `AppliedChange.filePath` / `AppliedChange.originalContent` / `AppliedChange.newContent` / `AppliedChange.appliedAt` — consistent across Tasks 1–5.
- `appliedChangesProvider` — generated name for `AppliedChanges` notifier — used in Tasks 2, 3, 4, 5, 7.
- `changesPanelVisibleProvider` — generated name for `ChangesPanelVisible` — used in Tasks 2, 4, 6, 7.
- `applyServiceProvider` — generated name for `applyService` factory — used in Tasks 3, 4, 5.
- `ApplyService.applyChange` / `ApplyService.revertChange` — consistent signatures across Tasks 3, 4, 5.
