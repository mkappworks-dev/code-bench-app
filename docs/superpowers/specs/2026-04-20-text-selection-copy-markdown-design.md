# Text Selection & Copy-as-Markdown — Spec

## Goal

Let users drag-select and copy any text from the chat stream, and copy the full raw markdown of an assistant reply with one click. Today `MarkdownBody` in `_AssistantBubble` renders non-selectable text, so users cannot grab quotes, code, or error messages out of the stream at all.

---

## Scope

**In scope:**
- Wrap `_MessageContent`'s `MarkdownBody` in `SelectionArea` so OS-native text selection works across assistant replies (drag-select, Cmd+C, right-click → Copy).
- Add an icon-only "copy as markdown" action below each completed assistant reply that copies `message.content` (the raw markdown string) to the clipboard.
- Tooltip on the icon; brief visual success state on the icon itself.

**Out of scope:**
- Selection-scoped markdown copy (mapping rendered glyphs back to source offsets). Industry convergence (ChatGPT, Claude.ai, Gemini) is whole-message copy, not selection-scoped — no evidence of user demand for the harder variant.
- Per-paragraph or per-list copy icons. Code blocks already have their own copy button via `CodeBlockBuilder`; we keep it and do not extend the pattern.
- "Quote in reply" / prefill-input-with-selection actions.
- User-message hover row. `_UserBubble` already uses `SelectableText`; a parallel "Copy" icon would duplicate the OS copy affordance for a plain-text bubble.
- Edit, retry, or regenerate buttons. The action row is designed to accept more icons later but we ship with one.

---

## Architecture

Pure widget-layer change in [lib/features/chat/widgets/message_bubble.dart](../../../lib/features/chat/widgets/message_bubble.dart). No new notifiers, services, models, or providers.

Per [CLAUDE.md](../../../CLAUDE.md) "Widget try/catch policy", `Clipboard.setData` is one of the two explicitly permitted widget-layer APIs, so the whole interaction stays in the widget layer without violating the layering rules.

```
_AssistantBubble
  └── Column
       ├── StreamingDot (if streaming)
       ├── SelectionArea           ← new: enables OS text selection
       │    └── _MessageContent (MarkdownBody + CodeBlockBuilder)
       ├── _AssistantActionRow     ← new: icon-only copy button
       ├── ToolCallRow(s)          (unchanged)
       ├── WorkLogSection          (unchanged)
       └── AskUserQuestionCard     (unchanged)
```

---

## Behavior

### Selection

Wrapping `_MessageContent` in `SelectionArea` gives every descendant text widget (prose, inline code, headings, list items) one coherent selection region. Users can drag across paragraphs, across code blocks, and across list items in a single gesture. Cmd+C, right-click → Copy, and the OS-native selection toolbar all work. No custom toolbar is attached — we rely on Flutter's default `contextMenuBuilder`.

The existing per-code-block copy button inside `CodeBlockBuilder` continues to work. Code blocks become selectable (previously they weren't) and also still offer one-click raw-source copy.

`_UserBubble` keeps its current `SelectableText`; selection there already works.

### Copy-as-markdown action row

A new `_AssistantActionRow` widget renders after `_MessageContent` and **before** `ToolCallRow` / `WorkLogSection`, so the row sits close to the prose it belongs to. It contains a single `IconButton` showing `AppIcons.copy`.

| Condition | Row visibility |
|---|---|
| `message.isStreaming == true` | Hidden (streaming content is mid-write — copying is premature) |
| `message.content.trim().isEmpty` | Hidden |
| Cursor outside the bubble | Icon at 0.4 opacity |
| Cursor inside the bubble | Icon at 1.0 opacity |
| Touch platforms (no hover events) | Icon at 0.4 opacity, always tappable |

A top-level `MouseRegion` wraps the whole assistant `Column` so both the prose and the row trigger the reveal — otherwise hovering the row *itself* would be the only way to show the row, which is unreachable.

Tap handler:

```dart
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
```

While `_copied == true`, the icon swaps to `AppIcons.check` tinted with `c.success` (the token already exists in [app_colors.dart](../../../lib/core/theme/app_colors.dart)). No snackbar on success — the icon swap is the feedback.

### Tooltip

`Tooltip(message: 'Copy as markdown')` wraps the `IconButton`. Shows on hover after the normal tooltip delay.

---

## Data flow

```
MouseRegion.onEnter  ──► setState(_hovering = true)  ──► AnimatedOpacity 1.0
MouseRegion.onExit   ──► setState(_hovering = false) ──► AnimatedOpacity 0.0

IconButton.onPressed ──► Clipboard.setData(message.content)
                      ──► setState(_copied = true)
                      ──► Timer(1.5s) ──► setState(_copied = false)
```

No providers, no Riverpod. Local `StatefulWidget` state only.

---

## Error Handling

Only one error path: `Clipboard.setData` throwing. Handled inline with a `try`/`catch` in the tap handler (explicitly permitted by CLAUDE.md's Widget-try-catch exception for `Clipboard.*`). We `dLog` the exception for triage and surface a generic error snackbar. No typed failure union — this is not a notifier.

---

## Integration Points

| Area | Change |
|---|---|
| `_AssistantBubble.build` | Insert `_AssistantActionRow` between `_MessageContent` and the tool-events `for` loop. Wrap the whole `Column` subtree in a `MouseRegion` that tracks hover state via `InheritedWidget` or callback-prop style. |
| `_MessageContent.build` | For the assistant branch, wrap `MarkdownBody` in `SelectionArea`. User branch unchanged. |
| `_UserBubble` | Unchanged. |
| `code_block_widget.dart` | Unchanged — its copy button still works; its contents are now also OS-selectable via the parent `SelectionArea`. |
| `app_icons.dart` | No change. `AppIcons.copy` and `AppIcons.check` already exist. |
| Theme tokens | Reuse `c.textMuted` for idle icon color, `c.success` for the 1.5s success state. No new tokens. |

---

## Testing

Widget tests in `test/features/chat/widgets/message_bubble_test.dart` (create if missing):

1. **Streaming hides the action row** — pump a `_AssistantBubble` with `message.isStreaming == true`, assert `find.byIcon(AppIcons.copy)` returns zero results.
2. **Completed assistant renders the action row** — pump with `isStreaming == false`, assert the icon exists.
3. **User bubble has no action row** — pump a `_UserBubble`, assert no `AppIcons.copy` in the subtree.
4. **Tap copies raw markdown** — intercept `SystemChannels.platform` via `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler`, tap the icon, assert the `Clipboard.setData` call payload equals `message.content` (not the rendered text).
5. **Success icon swap** — after tap, assert the icon is `AppIcons.check`; pump 1500ms, assert it reverts to `AppIcons.copy`.
6. **Empty message hides the row** — pump with `message.content = ''`, assert no icon.
7. **Selection works** — pump with a multi-paragraph assistant message, programmatically trigger selection on the `SelectionArea`, assert `selectedContent` is non-null. (Light sanity check — `SelectionArea` is Flutter framework behavior; we're just confirming we wired it up.)

---

## Rollout / Risks

- **Risk:** `SelectionArea` can interfere with tap gestures on descendants. `CodeBlockBuilder`'s copy button uses an `IconButton`, which handles its own hit testing correctly under `SelectionArea` (tested pattern — Flutter docs confirm `GestureDetector` children keep their gestures).
- **Touch platforms:** no detection needed. The icon renders at 0.4 opacity by default and bumps to 1.0 on hover. On touch, users never see the full-opacity state but the icon is still tappable at 0.4 — parity with the existing muted-icon patterns elsewhere in the app.
- **Risk:** large assistant messages with many tool rows push the action row far from the action target. Mitigated by positioning the row directly under `_MessageContent`, before tool events.
- **Backout:** revert the one file ([message_bubble.dart](../../../lib/features/chat/widgets/message_bubble.dart)). No schema migrations, no state persistence changes, no provider graph changes.

---

## Non-functional Requirements

- **Architecture:** respects the Riverpod layering rules in CLAUDE.md (no notifier/service reach-through; widget-only `Clipboard` call is on the explicit allow-list).
- **Naming:** `_AssistantActionRow` is a private widget — no provider, no failure class, no suffix-convention applicability.
- **Logging:** one `dLog` on clipboard failure only. No `sLog` — this is not a security event.
- **Performance:** `AnimatedOpacity` on a single icon; negligible overhead. `SelectionArea` adds one `RenderObject` wrapper per message.
