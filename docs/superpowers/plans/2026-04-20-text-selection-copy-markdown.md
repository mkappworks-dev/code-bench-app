# Text Selection & Copy-as-Markdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make assistant messages drag-selectable with native OS text selection, and add an icon-only hover-revealed "copy as markdown" button beneath each completed assistant reply.

**Architecture:** Pure widget-layer change in [lib/features/chat/widgets/message_bubble.dart](../../../lib/features/chat/widgets/message_bubble.dart). Wrap the assistant branch of `_MessageContent` in `SelectionArea`; add a new private `_AssistantActionRow` stateful widget with `AnimatedOpacity` hover reveal; convert `_AssistantBubble` from `ConsumerWidget` to `ConsumerStatefulWidget` so it can own a `_hovering` flag that a top-level `MouseRegion` updates. No new notifiers, services, providers, or models.

**Tech Stack:** Flutter (widget layer), Riverpod (unchanged — no new providers), `flutter_markdown` (unchanged — `MarkdownBody` re-used), `Clipboard.setData` from `package:flutter/services.dart`, Lucide icons via `AppIcons.copy` / `AppIcons.check`.

---

**Reference:** Implements [docs/superpowers/specs/2026-04-20-text-selection-copy-markdown-design.md](../specs/2026-04-20-text-selection-copy-markdown-design.md).

**Worktree setup (required before starting):**

```bash
git worktree add .worktrees/feat/2026-04-20-text-selection-copy-markdown -b feat/2026-04-20-text-selection-copy-markdown
cd .worktrees/feat/2026-04-20-text-selection-copy-markdown
```

All work happens inside this worktree.

---

## Task 1: Wrap assistant prose in `SelectionArea`

**Files:**
- Modify: [lib/features/chat/widgets/message_bubble.dart:148-185](../../../lib/features/chat/widgets/message_bubble.dart#L148-L185) (`_MessageContent.build`)
- Test: [test/features/chat/widgets/message_bubble_test.dart](../../../test/features/chat/widgets/message_bubble_test.dart)

- [ ] **Step 1: Write a failing widget test that asserts `SelectionArea` wraps the assistant `MarkdownBody`**

Append this test inside the existing `void main() { ... }` block in `test/features/chat/widgets/message_bubble_test.dart`, before the `group('parseCodeFenceInfo', ...)` block:

```dart
testWidgets('assistant message prose is wrapped in a SelectionArea', (tester) async {
  await tester.pumpWidget(_wrap(MessageBubble(message: _msg(MessageRole.assistant))));
  await tester.pumpAndSettle();
  expect(find.byType(SelectionArea), findsOneWidget);
});

testWidgets('user message prose is NOT wrapped in a SelectionArea', (tester) async {
  await tester.pumpWidget(_wrap(MessageBubble(message: _msg(MessageRole.user))));
  await tester.pumpAndSettle();
  expect(find.byType(SelectionArea), findsNothing);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
flutter test test/features/chat/widgets/message_bubble_test.dart --plain-name "SelectionArea"
```

Expected: FAIL — first test reports `Expected: exactly one matching candidate, Actual: _TextWidgetFinder:<zero widgets with type "SelectionArea">`. Second test passes trivially.

- [ ] **Step 3: Wrap the assistant `MarkdownBody` in `SelectionArea`**

Edit [lib/features/chat/widgets/message_bubble.dart:161-183](../../../lib/features/chat/widgets/message_bubble.dart#L161-L183) — the `return MarkdownBody(...)` inside `_MessageContent.build`. Change it to return a `SelectionArea` wrapping the `MarkdownBody`:

```dart
return SelectionArea(
  child: MarkdownBody(
    data: message.content,
    styleSheet: MarkdownStyleSheet(
      p: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSize, height: 1.65),
      code: TextStyle(
        fontFamily: ThemeConstants.editorFontFamily,
        backgroundColor: c.inlineCodeFill,
        color: c.inlineCodeText,
        fontSize: ThemeConstants.uiFontSizeSmall,
      ),
      codeblockDecoration: BoxDecoration(
        color: c.codeBlockBg,
        border: Border.all(color: c.subtleBorder),
        borderRadius: BorderRadius.circular(7),
      ),
      h1: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      h2: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
      h3: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
      blockquote: TextStyle(color: c.textSecondary),
      listBullet: TextStyle(color: c.textPrimary),
    ),
    builders: {'code': CodeBlockBuilder(messageId: message.id, sessionId: message.sessionId)},
  ),
);
```

The user branch (the `if (message.role == MessageRole.user)` early-return with `SelectableText`) is unchanged.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
flutter test test/features/chat/widgets/message_bubble_test.dart --plain-name "SelectionArea"
```

Expected: PASS — both tests green.

- [ ] **Step 5: Run the full message-bubble test file to catch regressions**

```bash
flutter test test/features/chat/widgets/message_bubble_test.dart
```

Expected: all tests pass (including the pre-existing `assistant code block renders without crash` — proves `CodeBlockBuilder`'s `Copy` button still works under the new `SelectionArea` wrapper).

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib/features/chat/widgets/message_bubble.dart test/features/chat/widgets/message_bubble_test.dart
flutter analyze
git add lib/features/chat/widgets/message_bubble.dart test/features/chat/widgets/message_bubble_test.dart
git commit -m "feat(chat): enable OS-native text selection on assistant messages"
```

Expected: `flutter analyze` reports no new issues; commit succeeds.

---

## Task 2: Add `_AssistantActionRow` with hover-revealed copy button

**Files:**
- Modify: [lib/features/chat/widgets/message_bubble.dart](../../../lib/features/chat/widgets/message_bubble.dart) — convert `_AssistantBubble` to `ConsumerStatefulWidget`, add `_AssistantActionRow` stateful widget, wrap `Column` subtree in `MouseRegion`, add imports for `Timer`, `Clipboard`, `AppIcons`, `dLog`.
- Test: [test/features/chat/widgets/message_bubble_test.dart](../../../test/features/chat/widgets/message_bubble_test.dart)

- [ ] **Step 1: Write failing widget tests for the action row's visibility rules**

Append these tests inside the existing `void main() { ... }` block, after the `SelectionArea` tests from Task 1:

```dart
testWidgets('completed assistant message renders the copy-as-markdown icon', (tester) async {
  await tester.pumpWidget(_wrap(MessageBubble(message: _msg(MessageRole.assistant))));
  await tester.pumpAndSettle();
  expect(find.byIcon(AppIcons.copy), findsOneWidget);
});

testWidgets('streaming assistant message hides the copy icon', (tester) async {
  await tester.pumpWidget(_wrap(MessageBubble(message: _msg(MessageRole.assistant, streaming: true))));
  await tester.pumpAndSettle();
  expect(find.byIcon(AppIcons.copy), findsNothing);
});

testWidgets('empty assistant message hides the copy icon', (tester) async {
  final msg = ChatMessage(
    id: 'id',
    sessionId: 'sid',
    role: MessageRole.assistant,
    content: '   ',
    timestamp: DateTime.now(),
  );
  await tester.pumpWidget(_wrap(MessageBubble(message: msg)));
  await tester.pumpAndSettle();
  expect(find.byIcon(AppIcons.copy), findsNothing);
});

testWidgets('user message has no copy-as-markdown icon', (tester) async {
  await tester.pumpWidget(_wrap(MessageBubble(message: _msg(MessageRole.user))));
  await tester.pumpAndSettle();
  expect(find.byIcon(AppIcons.copy), findsNothing);
});

testWidgets('tapping copy button copies raw markdown and swaps icon to check', (tester) async {
  final msg = ChatMessage(
    id: 'id',
    sessionId: 'sid',
    role: MessageRole.assistant,
    content: '**hello** `world`',
    timestamp: DateTime.now(),
  );

  // Intercept the clipboard platform channel.
  String? copied;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied = (call.arguments as Map)['text'] as String;
    }
    return null;
  });

  await tester.pumpWidget(_wrap(MessageBubble(message: msg)));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(AppIcons.copy));
  await tester.pump();

  expect(copied, '**hello** `world`');
  expect(find.byIcon(AppIcons.check), findsOneWidget);

  // After 1500ms, reverts to copy icon.
  await tester.pump(const Duration(milliseconds: 1600));
  expect(find.byIcon(AppIcons.check), findsNothing);
  expect(find.byIcon(AppIcons.copy), findsOneWidget);
});
```

Also add these imports at the top of the test file:

```dart
import 'package:flutter/services.dart';
import 'package:code_bench_app/core/constants/app_icons.dart';
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
flutter test test/features/chat/widgets/message_bubble_test.dart --plain-name "copy"
```

Expected: FAIL — all tests report `Expected: exactly one matching candidate, Actual: zero widgets with icon <AppIcons.copy>`. The icon is not yet rendered anywhere.

- [ ] **Step 3: Add required imports to `message_bubble.dart`**

Edit the top of [lib/features/chat/widgets/message_bubble.dart](../../../lib/features/chat/widgets/message_bubble.dart) — after the existing imports at lines 1-17, ensure these imports are present (add any that are missing):

```dart
import 'package:flutter/services.dart';            // Clipboard.setData, ClipboardData

import '../../../core/constants/app_icons.dart';   // AppIcons.copy, AppIcons.check
import '../../../core/utils/debug_logger.dart';    // dLog
```

The existing `'dart:async'` import on line 1 already provides `Timer` — no change needed there.

- [ ] **Step 4: Convert `_AssistantBubble` from `ConsumerWidget` to `ConsumerStatefulWidget`**

Replace [lib/features/chat/widgets/message_bubble.dart:74-144](../../../lib/features/chat/widgets/message_bubble.dart#L74-L144) — the entire `_AssistantBubble` class — with:

```dart
class _AssistantBubble extends ConsumerStatefulWidget {
  const _AssistantBubble({required this.message});
  final ChatMessage message;

  @override
  ConsumerState<_AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends ConsumerState<_AssistantBubble> {
  bool _hovering = false;

  /// Formats the answer map produced by [AskUserQuestionCard] into a
  /// plain user-message string and re-posts it via [chatMessagesProvider].
  void _submitAnswer(Map<String, dynamic> answer) {
    final parts = <String>[];
    final selected = answer['selectedOption'];
    final freeText = answer['freeText'];
    if (selected is String && selected.isNotEmpty) parts.add(selected);
    if (freeText is String && freeText.isNotEmpty) parts.add(freeText);
    if (parts.isEmpty) return;
    unawaited(ref.read(chatMessagesProvider(widget.message.sessionId).notifier).sendMessage(parts.join('\n\n')));
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    ref.listen(chatMessagesProvider(message.sessionId), (_, next) {
      if (next is! AsyncError || !context.mounted) return;
      showErrorSnackBar(context, 'Failed to send response. Please try again.');
    });
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 2, margin: const EdgeInsets.only(top: 3, bottom: 3), color: AppColors.of(context).borderColor),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isStreaming) const StreamingDot(),
                _MessageContent(message: message),
                _AssistantActionRow(message: message, hovering: _hovering),
                if (message.toolEvents.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final event in message.toolEvents)
                    Padding(
                      key: ValueKey('tool-row-${event.id}'),
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ToolCallRow(event: event),
                    ),
                ],
                if (message.toolEvents.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  WorkLogSection(sessionId: message.sessionId, messageId: message.id),
                ],
                if (message.askQuestion != null) ...[
                  const SizedBox(height: 8),
                  AskUserQuestionCard(
                    question: message.askQuestion!,
                    sessionId: message.sessionId,
                    onSubmit: _submitAnswer,
                    onBack: message.askQuestion!.stepIndex > 0
                        ? () => ref
                              .read(askQuestionProvider.notifier)
                              .setAnswer(
                                sessionId: message.sessionId,
                                stepIndex: message.askQuestion!.stepIndex,
                                selectedOption: null,
                                freeText: null,
                              )
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

Key edits from the original:
1. Class declaration swapped to `ConsumerStatefulWidget` + `_AssistantBubbleState` pattern.
2. `_hovering` bool added as local state.
3. `_submitAnswer(WidgetRef ref, ...)` → `_submitAnswer(Map<String, dynamic> answer)` — `ref` now comes from the enclosing `ConsumerState`.
4. The `Row` is wrapped in a top-level `MouseRegion` that flips `_hovering` on enter/exit.
5. A new `_AssistantActionRow(message: message, hovering: _hovering)` line is inserted directly after `_MessageContent(message: message)` and before the tool-events block.
6. `onSubmit: (answer) => _submitAnswer(ref, answer)` simplified to `onSubmit: _submitAnswer`.

- [ ] **Step 5: Add the `_AssistantActionRow` widget**

Insert this class definition in [lib/features/chat/widgets/message_bubble.dart](../../../lib/features/chat/widgets/message_bubble.dart) directly after the `_AssistantBubbleState` class and before the `// ── Message content ───` section comment (approximately the section between the new `_AssistantBubbleState` closing brace and the existing `_MessageContent` class):

```dart
// ── Assistant action row (copy-as-markdown) ───────────────────────────────────

class _AssistantActionRow extends StatefulWidget {
  const _AssistantActionRow({required this.message, required this.hovering});
  final ChatMessage message;
  final bool hovering;

  @override
  State<_AssistantActionRow> createState() => _AssistantActionRowState();
}

class _AssistantActionRowState extends State<_AssistantActionRow> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.message.content));
      if (!mounted) return;
      setState(() => _copied = true);
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() => _copied = false);
      });
    } catch (e) {
      dLog('[_AssistantActionRow] clipboard failed: $e');
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to copy. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isStreaming || widget.message.content.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final c = AppColors.of(context);
    final icon = _copied ? AppIcons.check : AppIcons.copy;
    final iconColor = _copied ? c.success : c.textMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: AnimatedOpacity(
        opacity: widget.hovering ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Tooltip(
          message: 'Copy as markdown',
          child: IconButton(
            icon: Icon(icon, size: 14, color: iconColor),
            onPressed: _copy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            visualDensity: VisualDensity.compact,
            splashRadius: 14,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run the action-row tests to verify they pass**

```bash
flutter test test/features/chat/widgets/message_bubble_test.dart --plain-name "copy"
```

Expected: PASS — all five copy-related tests green:
- `completed assistant message renders the copy-as-markdown icon`
- `streaming assistant message hides the copy icon`
- `empty assistant message hides the copy icon`
- `user message has no copy-as-markdown icon`
- `tapping copy button copies raw markdown and swaps icon to check`

- [ ] **Step 7: Run the full message-bubble test file + chat widget regressions**

```bash
flutter test test/features/chat/widgets/message_bubble_test.dart test/features/chat/widgets/chat_input_bar_test.dart test/features/chat/widgets/tool_call_row_test.dart
```

Expected: all tests pass.

- [ ] **Step 8: Run the full test suite for confidence**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 9: Format, analyze, commit**

```bash
dart format lib/features/chat/widgets/message_bubble.dart test/features/chat/widgets/message_bubble_test.dart
flutter analyze
git add lib/features/chat/widgets/message_bubble.dart test/features/chat/widgets/message_bubble_test.dart
git commit -m "feat(chat): add hover-revealed copy-as-markdown button on assistant messages"
```

Expected: `flutter analyze` reports no new issues; commit succeeds.

- [ ] **Step 10: Manual smoke on macOS**

```bash
flutter run -d macos
```

Manually verify in the running app:
1. Send a message, wait for the assistant to reply.
2. Hover over the assistant bubble — the copy icon below the prose fades from 40% to 100% opacity.
3. Click the copy icon — icon swaps to a green checkmark; after ~1.5s it reverts to the copy icon.
4. Paste into a plain-text editor — the clipboard holds the raw markdown (e.g. `**hello** `world``), not the rendered HTML.
5. Drag-select across paragraphs inside an assistant reply — OS-native selection highlight appears; Cmd+C copies the selected plain text.
6. While a message is streaming, the copy icon is not visible.

If any step fails, do not close the plan; debug inline and re-commit.

---

## Completion

After both tasks are done, all steps checked, and manual smoke passes, invoke the `superpowers:finishing-a-development-branch` skill to present merge / PR / keep / discard options.
