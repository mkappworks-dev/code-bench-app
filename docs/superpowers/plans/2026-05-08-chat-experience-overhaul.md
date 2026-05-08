# Chat Experience Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land all five chat-screen surfaces from the [2026-05-08 design spec](../specs/2026-05-08-chat-experience-overhaul-design.md) — clearer thinking states, session-list status dots, Ayu-themed code/diff with always-visible message toolbar, info-blue cross-provider question card, inline apply-diff card, and brand-colored tool-call attribution.

**Architecture:** Layered per [CLAUDE.md](../../../CLAUDE.md): widgets → notifiers → services → datasources. New types: `ProviderUserInputRequest` runtime event, `AgentUserInputRequestNotifier`, brand-color tokens on `AppColors`, `ToolPhasePill` widget. The new `AskUserQuestion` tool is registered into `ToolRegistry` with provider-specific producer wiring (Codex RPC branch, Claude CLI tool-use interception, API-direct tool registration).

**Tech Stack:** Flutter (macOS primary), Riverpod (codegen), Freezed (codegen), `re_highlight` (Ayu themes already shipped, just need imports), existing `ToolRegistry` + `ChatNotifier` + per-provider datasources.

**Branch:** `feat/2026-05-08-chat-experience-overhaul` (worktree at `.worktrees/feat/2026-05-08-chat-experience-overhaul`).

**Codegen reminder:** After editing any `@freezed` or `@riverpod` annotated file, run `dart run build_runner build --delete-conflicting-outputs` and commit the regenerated `*.g.dart` / `*.freezed.dart` alongside the source per [CLAUDE.md](../../../CLAUDE.md). After every code change, run `dart format lib/ test/` then `flutter analyze` then `flutter test` before committing.

---

## File Structure

**New files:**

| Path | Responsibility |
|---|---|
| `lib/core/theme/brand_color_for.dart` | Maps `providerId` → brand `Color` (helper, no widget state) |
| `lib/data/ai/models/agent_ask_user_question_tool.dart` | Constants + JSON-schema for the `AskUserQuestion` tool registered with API providers |
| `lib/features/chat/notifiers/agent_user_input_request_notifier.dart` | Holds active `ProviderUserInputRequest?`; `request(req) → Future<String>`, `submit`, `cancel` |
| `lib/features/chat/widgets/apply_diff_card.dart` | Inline apply-diff card · ready/applied/failed states |
| `lib/features/chat/widgets/tool_phase_pill.dart` | Color-encoded phase chip (think/tool/io) at bubble tail |
| `lib/features/chat/widgets/session_status_dot.dart` | 7px colored dot prefixed to session rows |
| `lib/features/chat/utils/tool_phase_classifier.dart` | `classifyTool(toolName, capability?) → PhaseClass` enum mapper |
| `test/features/chat/utils/tool_phase_classifier_test.dart` | Unit tests for classifier |
| `test/core/theme/brand_color_for_test.dart` | Unit tests for brand-color helper |
| `test/features/chat/notifiers/agent_user_input_request_notifier_test.dart` | Notifier behavior tests |
| `test/features/chat/widgets/apply_diff_card_test.dart` | Widget tests for state transitions |
| `test/features/chat/widgets/tool_phase_pill_test.dart` | Widget tests for color/label rendering |
| `lib/features/chat/widgets/diff_body.dart` | Reusable multi-line diff renderer with line-number gutters, +/− markers, per-row tinting |
| `lib/features/chat/widgets/diff_card.dart` | Read-only diff card for markdown ` ```diff ` blocks (wraps DiffBody with file-header strip) |
| `test/features/chat/widgets/diff_body_test.dart` | Widget tests for diff line rendering |

**Modified files:**

| Path | Change |
|---|---|
| `lib/core/theme/app_colors.dart` | Add `brandAnthropic`, `brandOpenAI`, `brandGemini`, `brandOllama` tokens (dark + light); update `copyWith` + `lerp` |
| `lib/data/ai/models/provider_runtime_event.dart` | Add `ProviderUserInputRequest` variant |
| `lib/data/ai/datasource/codex_session.dart` | Branch `_handleServerRequest` for `requestUserInput`; new `respondToUserInputRequest` |
| `lib/data/ai/datasource/codex_cli_datasource_process.dart` | Forward `respondToUserInputRequest` to pool |
| `lib/data/ai/datasource/codex_session_pool.dart` | Forward `respondToUserInputRequest` to session |
| `lib/data/ai/datasource/claude_cli_datasource_process.dart` | Intercept `tool_use` for `AskUserQuestion`; reply via `tool_result` flow |
| `lib/data/ai/datasource/anthropic_remote_datasource_dio.dart` | Inject `AskUserQuestion` tool; intercept tool-use for it |
| `lib/data/ai/datasource/openai_remote_datasource_dio.dart` | Same shape, OpenAI function-calling format |
| `lib/data/ai/datasource/gemini_remote_datasource_dio.dart` | Same shape, Gemini function declarations format |
| `lib/data/ai/datasource/ollama_remote_datasource_dio.dart` | Same shape, Ollama tools format |
| `lib/data/ai/datasource/custom_remote_datasource_dio.dart` | Same shape, OpenAI-compatible format |
| `lib/data/ai/datasource/ai_provider_datasource.dart` | Add `respondToUserInputRequest` to interface |
| `lib/data/ai/repository/*.dart` | Surface `respondToUserInputRequest` |
| `lib/features/chat/widgets/tool_call_row.dart` | Asymmetric badge: brand chip + neutral model chip |
| `lib/features/chat/widgets/provider_label.dart` | Co-locate next to `brandColorFor` if helpful (or leave separate) |
| `lib/features/chat/widgets/ask_user_question_card.dart` | Hide stepper when `totalSteps == 1`; info-blue agent-mode |
| `lib/features/chat/widgets/message_bubble.dart` | Render new question card from `agentUserInputRequestProvider`; render `ApplyDiffCard` in slot order; always-visible toolbar (no hover) |
| `lib/features/chat/widgets/message_list.dart` (or wherever) | Hookup phase pill at tail of streaming bubble |
| `lib/features/chat/notifiers/chat_notifier.dart` | Forward `ProviderUserInputRequest` events to `agentUserInputRequestProvider` |
| `lib/features/sessions/widgets/*.dart` (session list row widget) | Prefix `SessionStatusDot` |

**Deleted:**

- `lib/features/chat/widgets/apply_code_dialog.dart` (snackbar stub)

---

## Phase A · Foundation

### Task 1: Brand color tokens on AppColors

**Files:**
- Modify: `lib/core/theme/app_colors.dart`

- [ ] **Step 1: Add brand-color fields to AppColors**

In the `AppColors` constructor parameter list, after the existing fields (alongside `accent`, `accentLight`, etc.), add:

```dart
required this.brandAnthropic,
required this.brandOpenAI,
required this.brandGemini,
required this.brandOllama,
```

In the field declaration block (after the existing Color fields, before the `CodeHighlightTheme jsonHighlightTheme` getter):

```dart
final Color brandAnthropic;
final Color brandOpenAI;
final Color brandGemini;
final Color brandOllama;
```

In the `static const AppColors dark` block, add:

```dart
brandAnthropic: Color(0xFFD97757),
brandOpenAI: Color(0xFF10A37F),
brandGemini: Color(0xFF4285F4),
brandOllama: Color(0xFF9D9D9D),
```

In the `static const AppColors light` block, add:

```dart
brandAnthropic: Color(0xFFD97757),
brandOpenAI: Color(0xFF10A37F),
brandGemini: Color(0xFF4285F4),
brandOllama: Color(0xFF5C6474),
```

In the `copyWith` parameter list, add:

```dart
Color? brandAnthropic,
Color? brandOpenAI,
Color? brandGemini,
Color? brandOllama,
```

And in the `copyWith` body's `AppColors(...)` call:

```dart
brandAnthropic: brandAnthropic ?? this.brandAnthropic,
brandOpenAI: brandOpenAI ?? this.brandOpenAI,
brandGemini: brandGemini ?? this.brandGemini,
brandOllama: brandOllama ?? this.brandOllama,
```

In the `lerp` body's `AppColors(...)` call:

```dart
brandAnthropic: Color.lerp(brandAnthropic, other.brandAnthropic, t)!,
brandOpenAI: Color.lerp(brandOpenAI, other.brandOpenAI, t)!,
brandGemini: Color.lerp(brandGemini, other.brandGemini, t)!,
brandOllama: Color.lerp(brandOllama, other.brandOllama, t)!,
```

- [ ] **Step 2: Format and analyze**

```bash
dart format lib/core/theme/app_colors.dart && flutter analyze lib/core/theme/app_colors.dart
```

Expected: No issues found.

- [ ] **Step 3: Run tests**

```bash
flutter test
```

Expected: All tests pass (no behavioral change yet).

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat(theme): add brand-color tokens for tool-call attribution"
```

---

### Task 2: brandColorFor helper + tests

**Files:**
- Create: `lib/core/theme/brand_color_for.dart`
- Test: `test/core/theme/brand_color_for_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/theme/brand_color_for_test.dart`:

```dart
import 'package:code_bench/core/theme/app_colors.dart';
import 'package:code_bench/core/theme/brand_color_for.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const c = AppColors.dark;

  group('brandColorFor', () {
    test('claude-cli and anthropic share Anthropic brand', () {
      expect(brandColorFor('claude-cli', c), c.brandAnthropic);
      expect(brandColorFor('anthropic', c), c.brandAnthropic);
    });
    test('codex and openai share OpenAI brand', () {
      expect(brandColorFor('codex', c), c.brandOpenAI);
      expect(brandColorFor('openai', c), c.brandOpenAI);
    });
    test('gemini → brandGemini', () {
      expect(brandColorFor('gemini', c), c.brandGemini);
    });
    test('ollama → brandOllama', () {
      expect(brandColorFor('ollama', c), c.brandOllama);
    });
    test('custom and unknown ids → accent fallback', () {
      expect(brandColorFor('custom', c), c.accent);
      expect(brandColorFor('definitely-not-a-provider', c), c.accent);
    });
    test('null id → accent fallback', () {
      expect(brandColorFor(null, c), c.accent);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/core/theme/brand_color_for_test.dart
```

Expected: Compilation error — `brand_color_for.dart` doesn't exist.

- [ ] **Step 3: Implement the helper**

Create `lib/core/theme/brand_color_for.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Maps a provider id (as stored on `ChatMessage.providerId` or
/// emitted by datasources) to its brand color. Same-vendor pairs
/// (`claude-cli`/`anthropic`, `codex`/`openai`) share a brand.
/// Returns `c.accent` for `custom`, unknown ids, or null.
Color brandColorFor(String? providerId, AppColors c) {
  return switch (providerId) {
    'claude-cli' || 'anthropic' => c.brandAnthropic,
    'codex' || 'openai' => c.brandOpenAI,
    'gemini' => c.brandGemini,
    'ollama' => c.brandOllama,
    _ => c.accent,
  };
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/core/theme/brand_color_for_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/core/theme/brand_color_for.dart test/core/theme/brand_color_for_test.dart
flutter analyze
git add lib/core/theme/brand_color_for.dart test/core/theme/brand_color_for_test.dart
git commit -m "feat(theme): add brandColorFor helper with vendor-pair grouping"
```

---

## Phase B · Surface 6 · Tool-call attribution

### Task 3: Asymmetric badge styling on tool_call_row

**Files:**
- Modify: `lib/features/chat/widgets/tool_call_row.dart`

- [ ] **Step 1: Update _BadgeChip to take a style enum**

Replace the existing `_BadgeChip` class at the bottom of `tool_call_row.dart` with:

```dart
enum _BadgeStyle { brand, neutral }

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.color,
    required this.style,
  });
  final String label;
  final Color color;
  final _BadgeStyle style;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (style == _BadgeStyle.brand) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 10, color: color, letterSpacing: 0.3)),
          ],
        ),
      );
    }
    // neutral
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.chipFill,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: c.chipStroke, width: 0.5),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary, letterSpacing: 0.3)),
    );
  }
}
```

- [ ] **Step 2: Update the badge call sites**

In `tool_call_row.dart`, replace the existing block at the lines that currently render the two badges (search for `if (widget.providerLabel != null) ...`):

```dart
if (widget.providerLabel != null) ...[
  const SizedBox(width: 8),
  _BadgeChip(
    label: widget.providerLabel!,
    color: brandColorFor(widget.providerId, c),
    style: _BadgeStyle.brand,
  ),
],
if (widget.modelLabel != null) ...[
  const SizedBox(width: 4),
  _BadgeChip(
    label: widget.modelLabel!,
    color: c.textSecondary,
    style: _BadgeStyle.neutral,
  ),
],
```

- [ ] **Step 3: Add providerId field to ToolCallRow**

In `ToolCallRow`'s constructor + field block, add:

```dart
const ToolCallRow({
  super.key,
  required this.event,
  this.providerId,
  this.providerLabel,
  this.modelLabel,
});
final ToolEvent event;
final String? providerId;
final String? providerLabel;
final String? modelLabel;
```

Add the import at the top:

```dart
import '../../../core/theme/brand_color_for.dart';
```

- [ ] **Step 4: Update the call site in message_bubble.dart**

In `lib/features/chat/widgets/message_bubble.dart`, find the `ToolCallRow(...)` invocation around line 250 and update it:

```dart
ToolCallRow(
  event: event,
  providerId: message.providerId,
  providerLabel: providerLabelFor(message.providerId),
  modelLabel: message.modelId,
),
```

- [ ] **Step 5: Format, analyze, run tests**

```bash
dart format lib/features/chat/widgets/tool_call_row.dart lib/features/chat/widgets/message_bubble.dart
flutter analyze
flutter test
```

Expected: All passing.

- [ ] **Step 6: Smoke test in macOS app**

```bash
flutter run -d macos
```

Open a chat session that has tool calls. Verify the provider badge is brand-colored with a dot prefix; the model badge is neutral monospace. Stop the app.

- [ ] **Step 7: Commit**

```bash
git add lib/features/chat/widgets/tool_call_row.dart lib/features/chat/widgets/message_bubble.dart
git commit -m "feat(chat): brand-colored provider chip + neutral model chip on tool cards"
```

---

## Phase C · Surface 2 · Session list status indicators

### Task 4: SessionStatusDot widget + integration

**Files:**
- Create: `lib/features/chat/widgets/session_status_dot.dart`
- Test: `test/features/chat/widgets/session_status_dot_test.dart`
- Modify: the session-list row widget (locate via grep)

- [ ] **Step 1: Locate the session list row widget**

```bash
grep -rn "ListTile\|onTap.*session\|sessionId" lib/features/sessions lib/features/chat lib/shell --include="*.dart" 2>&1 | grep -i "list\|tile\|row" | head -20
```

Inspect the matches to find the per-row widget that renders one session in the sidebar list. Record its path as `<SESSION_ROW_PATH>` for the next step.

- [ ] **Step 2: Define the SessionStatus enum**

Inspect the chat session model in `lib/data/session/models/`:

```bash
find lib/data/session -name "*.dart" | grep -v ".g.dart\|.freezed.dart" | head -10
```

Identify where the session's runtime state (streaming/awaiting/error/idle) is tracked. This may be derived state across the chat notifier rather than persisted; if so, the new helper goes there. For the dot widget itself the enum is local:

Create `lib/features/chat/widgets/session_status_dot.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum SessionStatus { idle, streaming, awaiting, errored }

class SessionStatusDot extends StatelessWidget {
  const SessionStatusDot({super.key, required this.status});
  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = switch (status) {
      SessionStatus.streaming => c.accent,
      SessionStatus.awaiting => c.warning,
      SessionStatus.errored => c.error,
      SessionStatus.idle => c.iconInactive,
    };

    return _Dot(
      color: color,
      pulse: status == SessionStatus.streaming,
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.4 + 0.6 * t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 * t),
                blurRadius: 6 + 2 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Add a derivation helper for session status**

Pick a place — if the chat notifier already exposes per-session state, add a getter on the session view-model or a top-level helper. Search:

```bash
grep -rn "isStreaming\|streamFailure\|pendingPermissionRequest" lib/features/chat/notifiers lib/features/sessions/notifiers --include="*.dart" 2>&1 | head -20
```

If a session-level notifier owns these flags, add a `SessionStatus get status` derived from them in the same file. If not, create `lib/features/chat/utils/session_status_for.dart`:

```dart
import '../widgets/session_status_dot.dart';

/// Derives session-list status from streaming/permission/error flags.
SessionStatus sessionStatusFor({
  required bool isStreaming,
  required bool hasPendingPermission,
  required bool hasPendingQuestion,
  required bool lastTurnFailed,
}) {
  if (isStreaming) return SessionStatus.streaming;
  if (hasPendingPermission || hasPendingQuestion) return SessionStatus.awaiting;
  if (lastTurnFailed) return SessionStatus.errored;
  return SessionStatus.idle;
}
```

- [ ] **Step 4: Insert SessionStatusDot into the session row**

Open `<SESSION_ROW_PATH>` from Step 1. Add the import:

```dart
import 'session_status_dot.dart';
```

(Adjust path depth.) In the `Row(...)` that renders the session entry, insert as the first child:

```dart
Row(
  children: [
    SessionStatusDot(status: sessionStatusFor(
      isStreaming: session.isStreaming,
      hasPendingPermission: session.pendingPermissionRequest != null,
      hasPendingQuestion: session.askQuestion != null,
      lastTurnFailed: session.lastTurnFailed,
    )),
    const SizedBox(width: 8),
    // ... existing children
  ],
),
```

If the `session` view-model lacks one of these fields, derive it inline from whatever is present — but call this out in the commit message so the engineer reviewing the PR can confirm the derivation.

- [ ] **Step 5: Format, analyze, run tests, smoke test, commit**

```bash
dart format lib/features/chat/widgets/session_status_dot.dart $SESSION_ROW_PATH
flutter analyze
flutter test
flutter run -d macos    # verify dots render in the session list
```

```bash
git add lib/features/chat/widgets/session_status_dot.dart lib/features/chat/utils/session_status_for.dart $SESSION_ROW_PATH
git commit -m "feat(chat): session list status dots — streaming/awaiting/errored/idle"
```

---

## Phase D · Surface 3 · Markdown · Ayu · Toolbar

### Task 5: Switch code-block backgrounds to Ayu palette

**Files:**
- Modify: `lib/core/theme/app_colors.dart`
- Modify: any widget directly reading `c.codeBlockBg` (find via grep)

- [ ] **Step 1: Update codeBlockBg / jsonEditorBg dark/light values**

In `lib/core/theme/app_colors.dart`, change the `codeBlockBg` and `jsonEditorBg` const values:

In the `dark` block:

```dart
codeBlockBg: Color(0xFF0B0E14),  // was 0xFF0D1117 — Ayu Dark code bg
jsonEditorBg: Color(0xFF0B0E14),  // was 0xFF0D1117
```

In the `light` block:

```dart
codeBlockBg: Color(0xFFFAFAFA),  // Ayu Light code bg (keep separate from app bg #F0F2F5)
jsonEditorBg: Color(0xFFFAFAFA),  // was #F5F5F5
```

- [ ] **Step 2: Switch the highlight theme imports to Ayu**

In `lib/core/theme/app_colors.dart` lines 4-5, replace:

```dart
import 'package:re_highlight/styles/atom-one-light.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
```

with:

```dart
import 'package:re_highlight/styles/ayu-light.dart';
import 'package:re_highlight/styles/ayu-dark.dart';
```

In the `jsonHighlightTheme` getter, swap `atomOneDarkTheme` → `ayuDarkTheme` and `atomOneLightTheme` → `ayuLightTheme`:

```dart
CodeHighlightTheme get jsonHighlightTheme {
  final isDark = ThemeData.estimateBrightnessForColor(background) == Brightness.dark;
  return CodeHighlightTheme(
    languages: {'json': CodeHighlightThemeMode(mode: langJson)},
    theme: isDark ? ayuDarkTheme : ayuLightTheme,
  );
}
```

- [ ] **Step 3: Verify the imports resolve**

```bash
flutter analyze lib/core/theme/app_colors.dart
```

Expected: No issues. If `re_highlight` does not ship `ayu-dark` / `ayu-light` directly, the analyzer will surface "URI doesn't exist" — in that case run:

```bash
ls $(find ~/.pub-cache -path '*/re_highlight-*/lib/styles' -type d 2>/dev/null | head -1) | grep ayu
```

If only one ayu file exists (e.g., `ayu.dart`), import that for both modes; if Ayu is not packaged, copy the theme map inline as a fallback (the engineer should consult the spec's risk section).

- [ ] **Step 4: Format, analyze, run tests, smoke test, commit**

```bash
dart format lib/core/theme/app_colors.dart
flutter analyze
flutter test
flutter run -d macos    # verify diff/code blocks render with darker bg in dark mode
```

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat(theme): switch code highlight theme to Ayu (dark + light)"
```

---

### Task 5.5: DiffBody widget + DiffCard for markdown diff blocks

**Files:**
- Create: `lib/features/chat/widgets/diff_body.dart`
- Create: `lib/features/chat/widgets/diff_card.dart`
- Test: `test/features/chat/widgets/diff_body_test.dart`
- Modify: the markdown renderer (find via grep) — render ` ```diff ` code blocks as `DiffCard`

- [ ] **Step 1: Write the failing test**

Create `test/features/chat/widgets/diff_body_test.dart`:

```dart
import 'package:code_bench/core/theme/app_theme.dart';
import 'package:code_bench/features/chat/widgets/diff_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child));

  testWidgets('renders addition lines with + marker', (tester) async {
    await tester.pumpWidget(wrap(const DiffBody(
      diffText: '+final x = 1;\n-final x = 0;\n',
    )));
    expect(find.text('+'), findsOneWidget);
    expect(find.text('−'), findsOneWidget);
  });

  testWidgets('renders hunk header lines', (tester) async {
    await tester.pumpWidget(wrap(const DiffBody(
      diffText: '@@ -1,3 +1,4 @@ void main() {',
    )));
    expect(find.textContaining('@@ -1,3'), findsOneWidget);
  });

  testWidgets('renders context lines with space marker', (tester) async {
    await tester.pumpWidget(wrap(const DiffBody(
      diffText: ' context line',
    )));
    expect(find.text('context line'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/chat/widgets/diff_body_test.dart
```

Expected: Compilation error — `diff_body.dart` doesn't exist.

- [ ] **Step 3: Implement DiffBody**

Create `lib/features/chat/widgets/diff_body.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Renders a unified-diff string line by line with +/− gutter markers and
/// per-row background tinting. Used by both [DiffCard] and [ApplyDiffCard].
class DiffBody extends StatelessWidget {
  const DiffBody({super.key, required this.diffText});
  final String diffText;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lines = diffText.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();

    return Container(
      color: c.codeBlockBg,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final line in lines) _DiffLine(line: line, c: c)],
      ),
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine({required this.line, required this.c});
  final String line;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final isAdd = line.startsWith('+');
    final isDel = line.startsWith('-');
    final isHunk = line.startsWith('@@');

    Color? rowBg;
    Color markerColor;
    Color textColor;

    if (isAdd) {
      rowBg = const Color(0xFFAAD94C).withValues(alpha: 0.08);
      markerColor = const Color(0xFFAAD94C);
      textColor = const Color(0xFFAAD94C);
    } else if (isDel) {
      rowBg = const Color(0xFFF07178).withValues(alpha: 0.08);
      markerColor = const Color(0xFFF07178);
      textColor = const Color(0xFFF07178);
    } else if (isHunk) {
      rowBg = c.info.withValues(alpha: 0.06);
      markerColor = c.info;
      textColor = c.info;
    } else {
      markerColor = c.textMuted;
      textColor = c.textSecondary;
    }

    final marker = isAdd ? '+' : isDel ? '−' : ' ';
    final content = (isAdd || isDel) ? line.substring(1) : line;

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            child: Text(
              marker,
              style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: markerColor, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              content,
              style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/chat/widgets/diff_body_test.dart
```

Expected: All pass.

- [ ] **Step 5: Implement DiffCard**

Create `lib/features/chat/widgets/diff_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'diff_body.dart';

/// Read-only diff card rendered for ` ```diff ` fenced blocks in markdown.
/// Strips diff --git / --- / +++ header lines, extracts the filename, and
/// computes +N/−N stats from the content lines.
class DiffCard extends StatelessWidget {
  const DiffCard({super.key, required this.rawDiff});
  final String rawDiff;

  static _ParsedDiff _parse(String raw) {
    final lines = raw.split('\n');
    String filename = '';
    int additions = 0;
    int deletions = 0;
    final bodyLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('diff --git')) {
        final parts = line.split(' ');
        if (parts.length >= 3) filename = parts.last.replaceFirst('b/', '');
      } else if (line.startsWith('--- ') || line.startsWith('+++ ')) {
        if (filename.isEmpty && line.startsWith('+++ ')) {
          filename = line.substring(4).replaceFirst('b/', '').replaceFirst('a/', '');
        }
      } else {
        bodyLines.add(line);
        if (line.startsWith('+') && !line.startsWith('++')) additions++;
        if (line.startsWith('-') && !line.startsWith('--')) deletions++;
      }
    }

    return _ParsedDiff(
      filename: filename.isEmpty ? 'diff' : filename,
      additions: additions,
      deletions: deletions,
      body: bodyLines.join('\n'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = _parse(rawDiff);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.04),
        border: Border.all(color: c.accent.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DiffHead(c: c, filename: p.filename, additions: p.additions, deletions: p.deletions),
          DiffBody(diffText: p.body),
        ],
      ),
    );
  }
}

class _ParsedDiff {
  const _ParsedDiff({required this.filename, required this.additions, required this.deletions, required this.body});
  final String filename;
  final int additions;
  final int deletions;
  final String body;
}

class _DiffHead extends StatelessWidget {
  const _DiffHead({required this.c, required this.filename, required this.additions, required this.deletions});
  final AppColors c;
  final String filename;
  final int additions;
  final int deletions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: c.accent.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.difference_outlined, size: 14, color: c.accent),
          const SizedBox(width: 8),
          Text(filename, style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Text('+$additions', style: const TextStyle(color: Color(0xFFAAD94C), fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
          const SizedBox(width: 4),
          Text('·', style: TextStyle(color: c.textMuted, fontSize: 10)),
          const SizedBox(width: 4),
          Text('−$deletions', style: const TextStyle(color: Color(0xFFF07178), fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Wire into the markdown renderer**

Find the widget that renders fenced code blocks in markdown:

```bash
grep -rn "codeBlock\|MarkdownBody\|flutter_markdown\|CodeHighlight\|syntaxHighlighter\|builders" lib/features/chat/widgets --include="*.dart" 2>&1 | head -20
```

In the existing code-block builder, add a case for the `diff` language before the existing highlight path:

```dart
if (language == 'diff') {
  return DiffCard(rawDiff: code);
}
// ... existing syntax-highlight path
```

If the renderer uses a `Map<String, MarkdownElementBuilder>` builders map, follow whatever pattern the existing code-block builder uses and add a `diff` language branch in the same place.

- [ ] **Step 7: Format, analyze, run tests, smoke test, commit**

```bash
dart format lib/features/chat/widgets/diff_body.dart lib/features/chat/widgets/diff_card.dart test/features/chat/widgets/diff_body_test.dart
flutter analyze
flutter test
flutter run -d macos    # paste a ```diff block in a chat message; verify DiffCard renders
```

```bash
git add lib/features/chat/widgets/diff_body.dart lib/features/chat/widgets/diff_card.dart test/features/chat/widgets/diff_body_test.dart
git commit -m "feat(chat): DiffBody + DiffCard for markdown diff code blocks"
```

---

### Task 6: Always-visible message toolbar

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart` (the `_AssistantActionRow` widget)

- [ ] **Step 1: Locate _AssistantActionRow**

```bash
grep -n "_AssistantActionRow\|_hovering" lib/features/chat/widgets/message_bubble.dart 2>&1 | head -20
```

- [ ] **Step 2: Remove hover gating**

In `_MessageBubbleState`, remove the `_hovering` field and the `MouseRegion` wrapper around the bubble (or keep `MouseRegion` if it serves other purposes — but stop passing `hovering` into the action row).

In `_AssistantActionRow`, remove the `hovering` parameter and any `if (!hovering) return SizedBox.shrink();` early return. The row renders unconditionally.

- [ ] **Step 3: Confirm copy/retry/delete buttons exist**

If the action row currently has a `copy` button but no `retry` or `delete`, add them. Use `IconButton` instances styled per `ThemeConstants.iconSizeSmall` (14px). The `retry` callback re-runs the user message that produced this assistant turn; the `delete` callback removes the assistant message via `chatActionsProvider.removeAssistantMessage(message.id)` (add this method to the chat actions notifier if missing).

If `chatActionsProvider` doesn't have `removeAssistantMessage` or `retry`, add them as TDD tasks before this one. Search first:

```bash
grep -n "removeAssistantMessage\|retryMessage\|retry(" lib/features/chat/notifiers --include="*.dart" -r
```

If absent, defer to Task 6.5 below.

- [ ] **Step 4: Format, analyze, run tests, smoke test, commit**

```bash
dart format lib/features/chat/widgets/message_bubble.dart
flutter analyze
flutter test
git add lib/features/chat/widgets/message_bubble.dart
git commit -m "feat(chat): always-visible per-message toolbar (copy/retry/delete)"
```

---

### Task 6.5: Wire retry / delete actions on chatActionsProvider (only if missing)

**Files:**
- Modify: `lib/features/chat/notifiers/chat_actions.dart` (or wherever the chat command notifier lives — search via Step 3 of Task 6)
- Test: `test/features/chat/notifiers/chat_actions_test.dart` (add cases)

- [ ] **Step 1: Inspect existing actions notifier**

Open the file. Identify the `*Actions` class for chat operations.

- [ ] **Step 2: Add the methods**

Add inside the class (replace `// TODO` lines with the existing `_asFailure` / `AsyncValue.guard` pattern from [code_apply_actions.dart](../../../lib/features/chat/notifiers/code_apply_actions.dart)):

```dart
Future<void> retryAssistantMessage(String messageId) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      // 1. Find the user message whose response this is.
      // 2. Truncate trailing assistant messages from the same turn.
      // 3. Re-send the user message through the existing send path.
      final repo = ref.read(sessionRepositoryProvider);
      await repo.retryFromAssistantMessage(messageId);
    } catch (e, st) {
      dLog('[ChatActions] retryAssistantMessage failed: ${e.runtimeType}');
      Error.throwWithStackTrace(_asFailure(e), st);
    }
  });
}

Future<void> deleteAssistantMessage(String messageId) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      final repo = ref.read(sessionRepositoryProvider);
      await repo.deleteMessage(messageId);
    } catch (e, st) {
      dLog('[ChatActions] deleteAssistantMessage failed: ${e.runtimeType}');
      Error.throwWithStackTrace(_asFailure(e), st);
    }
  });
}
```

If `SessionRepository.retryFromAssistantMessage` or `.deleteMessage` doesn't exist, add the corresponding methods first (they wrap the existing message-store API).

- [ ] **Step 3: Wire into _AssistantActionRow**

In `_AssistantActionRow`, the `retry` button's `onPressed`:

```dart
onPressed: () => ref.read(chatActionsProvider.notifier).retryAssistantMessage(message.id),
```

Same for `delete`:

```dart
onPressed: () => ref.read(chatActionsProvider.notifier).deleteAssistantMessage(message.id),
```

- [ ] **Step 4: Codegen, format, analyze, test, commit**

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/features/chat/notifiers/ lib/features/chat/widgets/
flutter analyze
flutter test
git add lib/features/chat/ lib/data/session/
git commit -m "feat(chat): retry/delete actions on assistant messages"
```

---

## Phase E · Surface 1 · Phase pill + tool-card body

### Task 7: ToolPhaseClassifier + tests

**Files:**
- Create: `lib/features/chat/utils/tool_phase_classifier.dart`
- Test: `test/features/chat/utils/tool_phase_classifier_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/chat/utils/tool_phase_classifier_test.dart`:

```dart
import 'package:code_bench/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench/features/chat/utils/tool_phase_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyTool', () {
    test('readOnly capability → io', () {
      expect(classifyTool('read_file', ToolCapability.readOnly), PhaseClass.io);
      expect(classifyTool('grep', ToolCapability.readOnly), PhaseClass.io);
    });
    test('mutatingFiles capability → io', () {
      expect(classifyTool('write_file', ToolCapability.mutatingFiles), PhaseClass.io);
      expect(classifyTool('str_replace', ToolCapability.mutatingFiles), PhaseClass.io);
    });
    test('shell capability → tool', () {
      expect(classifyTool('bash', ToolCapability.shell), PhaseClass.tool);
    });
    test('network capability → tool', () {
      expect(classifyTool('web_fetch', ToolCapability.network), PhaseClass.tool);
    });
    test('unknown name without capability → tool (opaque exec)', () {
      expect(classifyTool('mystery_tool', null), PhaseClass.tool);
    });
    test('CLI-transport built-in names map by name when capability is unknown', () {
      // Claude CLI / Codex emit tool names; we don't always have a capability.
      expect(classifyTool('Read', null), PhaseClass.io);
      expect(classifyTool('Edit', null), PhaseClass.io);
      expect(classifyTool('Bash', null), PhaseClass.tool);
      expect(classifyTool('WebFetch', null), PhaseClass.tool);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/features/chat/utils/tool_phase_classifier_test.dart
```

Expected: Compilation error.

- [ ] **Step 3: Implement classifier**

Create `lib/features/chat/utils/tool_phase_classifier.dart`:

```dart
import '../../../data/coding_tools/models/tool_capability.dart';

enum PhaseClass { think, tool, io }

/// Maps a tool invocation to a phase class for color-encoding the
/// tail-of-bubble pill.
///
/// - `readOnly` / `mutatingFiles` → [io] (filesystem touches)
/// - `shell` / `network` → [tool] (subprocess or HTTP)
/// - When [capability] is null (CLI-transport tool from Claude/Codex
///   where we don't have the registry entry), fall back to a name-based
///   map of well-known tool names; unknowns default to [tool].
PhaseClass classifyTool(String toolName, ToolCapability? capability) {
  if (capability != null) {
    return switch (capability) {
      ToolCapability.readOnly || ToolCapability.mutatingFiles => PhaseClass.io,
      ToolCapability.shell || ToolCapability.network => PhaseClass.tool,
    };
  }
  // CLI-transport tool names (Claude Code, Codex) — best-effort by name.
  return switch (toolName) {
    'Read' || 'Edit' || 'Write' || 'Glob' || 'Grep' || 'NotebookEdit' || 'read_file' || 'write_file' || 'list_dir' || 'glob' || 'grep' || 'str_replace' => PhaseClass.io,
    'Bash' || 'WebFetch' || 'WebSearch' || 'bash' || 'web_fetch' => PhaseClass.tool,
    _ => PhaseClass.tool,
  };
}
```

- [ ] **Step 4: Run tests to verify pass**

```bash
flutter test test/features/chat/utils/tool_phase_classifier_test.dart
```

Expected: All pass.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/features/chat/utils/tool_phase_classifier.dart test/features/chat/utils/tool_phase_classifier_test.dart
flutter analyze
git add lib/features/chat/utils/ test/features/chat/utils/
git commit -m "feat(chat): tool-phase classifier for pill color encoding"
```

---

### Task 8: ToolPhasePill widget + tests

**Files:**
- Create: `lib/features/chat/widgets/tool_phase_pill.dart`
- Test: `test/features/chat/widgets/tool_phase_pill_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/chat/widgets/tool_phase_pill_test.dart`:

```dart
import 'package:code_bench/core/theme/app_theme.dart';
import 'package:code_bench/features/chat/utils/tool_phase_classifier.dart';
import 'package:code_bench/features/chat/widgets/tool_phase_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child));

  testWidgets('renders label with phase color · think', (tester) async {
    await tester.pumpWidget(wrap(const ToolPhasePill(phase: PhaseClass.think, label: 'thinking')));
    expect(find.text('thinking'), findsOneWidget);
  });

  testWidgets('renders label with phase color · tool', (tester) async {
    await tester.pumpWidget(wrap(const ToolPhasePill(phase: PhaseClass.tool, label: 'running git status')));
    expect(find.text('running git status'), findsOneWidget);
  });

  testWidgets('renders label with phase color · io', (tester) async {
    await tester.pumpWidget(wrap(const ToolPhasePill(phase: PhaseClass.io, label: 'reading 3 files')));
    expect(find.text('reading 3 files'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/chat/widgets/tool_phase_pill_test.dart
```

Expected: Compilation error.

- [ ] **Step 3: Implement the widget**

Create `lib/features/chat/widgets/tool_phase_pill.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../utils/tool_phase_classifier.dart';

/// Ephemeral chip pinned to the tail of a streaming assistant bubble.
/// Disappears when the turn completes. Color-encoded by [phase].
class ToolPhasePill extends StatefulWidget {
  const ToolPhasePill({super.key, required this.phase, required this.label});
  final PhaseClass phase;
  final String label;

  @override
  State<ToolPhasePill> createState() => _ToolPhasePillState();
}

class _ToolPhasePillState extends State<ToolPhasePill> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = switch (widget.phase) {
      PhaseClass.think => c.accent,
      PhaseClass.tool => c.warning,
      PhaseClass.io => c.info,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_ctrl.value);
              return Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.4 + 0.6 * t),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 10.5,
              color: color,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests, format, analyze, commit**

```bash
flutter test test/features/chat/widgets/tool_phase_pill_test.dart
dart format lib/features/chat/widgets/tool_phase_pill.dart test/features/chat/widgets/tool_phase_pill_test.dart
flutter analyze
git add lib/features/chat/widgets/tool_phase_pill.dart test/features/chat/widgets/tool_phase_pill_test.dart
git commit -m "feat(chat): ToolPhasePill widget — color-encoded ephemeral phase chip"
```

---

### Task 9: Render phase pills at the tail of the streaming bubble

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`

- [ ] **Step 1: Compute active phases from message state**

In `message_bubble.dart`, before the existing `_AssistantActionRow` render, add:

```dart
List<({PhaseClass phase, String label})> _activePhases(ChatMessage m) {
  if (!m.isStreaming) return const [];
  final out = <({PhaseClass phase, String label})>[];
  // Active running tools — one pill per concurrent tool, classified by capability or name.
  final running = m.toolEvents.where((e) => e.status == ToolStatus.running).toList();
  for (final e in running) {
    out.add((
      phase: classifyTool(e.toolName, null),
      label: _phaseLabelFor(e),
    ));
  }
  // If model is generating text without active tools, show "thinking".
  if (running.isEmpty) {
    out.add((phase: PhaseClass.think, label: 'thinking'));
  }
  return out;
}

String _phaseLabelFor(ToolEvent e) {
  return switch (e.toolName.toLowerCase()) {
    'bash' => 'running ${_truncate(e.input["command"]?.toString() ?? "command", 24)}',
    'web_fetch' || 'webfetch' => 'fetching url',
    'read' || 'read_file' => 'reading ${_truncate(e.filePath ?? "file", 32)}',
    'write' || 'write_file' || 'edit' || 'str_replace' => 'editing ${_truncate(e.filePath ?? "file", 32)}',
    'glob' => 'finding files',
    'grep' => 'searching',
    _ => 'running ${e.toolName}',
  };
}

String _truncate(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}…';
```

Add the imports:

```dart
import '../utils/tool_phase_classifier.dart';
import 'tool_phase_pill.dart';
```

- [ ] **Step 2: Render the pills**

In the `_MessageContent`'s `build` (or wherever the bubble's stream tail renders), insert at the end of the `Column.children` for the assistant bubble — *after* tool cards and message text, *before* `_AssistantActionRow`:

```dart
if (message.isStreaming) ...[
  const SizedBox(height: 6),
  Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      for (final p in _activePhases(message))
        ToolPhasePill(phase: p.phase, label: p.label),
    ],
  ),
],
```

- [ ] **Step 3: Format, analyze, run tests, smoke test, commit**

```bash
dart format lib/features/chat/widgets/message_bubble.dart
flutter analyze
flutter test
flutter run -d macos    # send a message that triggers tool calls; verify pill at tail
```

```bash
git add lib/features/chat/widgets/message_bubble.dart
git commit -m "feat(chat): render phase pills at tail of streaming bubble"
```

---

## Phase F · Surface 5 · Inline apply-diff card

### Task 10: ApplyDiffCard widget + 3 states

**Files:**
- Create: `lib/features/chat/widgets/apply_diff_card.dart`
- Test: `test/features/chat/widgets/apply_diff_card_test.dart`
- Modify: `lib/features/chat/widgets/message_bubble.dart` (render slot)
- Delete: `lib/features/chat/widgets/apply_code_dialog.dart`

- [ ] **Step 1: Inspect existing CodeApplyActions and CodeApplyFailure**

```bash
grep -n "class CodeApplyActions\|sealed class CodeApply" lib/features/chat/notifiers/code_apply_actions.dart lib/features/chat/notifiers/code_apply_failure.dart 2>&1 | head
```

Note the method names available (`apply`, `applyToFile`, etc.) and the failure variants. The card calls those.

- [ ] **Step 2: Write a widget test for state transitions**

Create `test/features/chat/widgets/apply_diff_card_test.dart`:

```dart
import 'package:code_bench/core/theme/app_theme.dart';
import 'package:code_bench/features/chat/widgets/apply_diff_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
    child: MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child)),
  );

  testWidgets('ready state shows Apply button and diff body', (tester) async {
    await tester.pumpWidget(wrap(const ApplyDiffCard(
      filename: 'chat_notifier.dart',
      language: 'dart',
      newCode: 'final x = 1;\n',
      oldPreview: 'final x = 0;\n',
      additions: 1,
      deletions: 1,
      state: ApplyCardState.ready,
    )));
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('chat_notifier.dart'), findsOneWidget);
  });

  testWidgets('applied state shows applied pill, no Apply button', (tester) async {
    await tester.pumpWidget(wrap(const ApplyDiffCard(
      filename: 'chat_notifier.dart',
      language: 'dart',
      newCode: 'final x = 1;\n',
      oldPreview: 'final x = 0;\n',
      additions: 1,
      deletions: 1,
      state: ApplyCardState.applied,
    )));
    expect(find.text('Apply'), findsNothing);
    expect(find.textContaining('applied'), findsOneWidget);
  });

  testWidgets('failed state shows Re-diff button and warning style', (tester) async {
    await tester.pumpWidget(wrap(const ApplyDiffCard(
      filename: 'chat_notifier.dart',
      language: 'dart',
      newCode: 'final x = 1;\n',
      oldPreview: 'final x = 0;\n',
      additions: 1,
      deletions: 1,
      state: ApplyCardState.failed,
      errorMessage: 'file diverged',
    )));
    expect(find.text('Re-diff'), findsOneWidget);
    expect(find.textContaining('diverged'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
flutter test test/features/chat/widgets/apply_diff_card_test.dart
```

Expected: Compilation error.

- [ ] **Step 4: Implement ApplyDiffCard**

Create `lib/features/chat/widgets/apply_diff_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

enum ApplyCardState { ready, applied, failed }

class ApplyDiffCard extends ConsumerWidget {
  const ApplyDiffCard({
    super.key,
    required this.filename,
    required this.language,
    required this.newCode,
    required this.oldPreview,
    required this.additions,
    required this.deletions,
    required this.state,
    this.errorMessage,
    this.onApply,
    this.onReDiff,
    this.onCopy,
    this.onOpenInEditor,
  });

  final String filename;
  final String language;
  final String newCode;
  final String oldPreview;
  final int additions;
  final int deletions;
  final ApplyCardState state;
  final String? errorMessage;
  final VoidCallback? onApply;
  final VoidCallback? onReDiff;
  final VoidCallback? onCopy;
  final VoidCallback? onOpenInEditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final isFailed = state == ApplyCardState.failed;
    final accentColor = isFailed ? c.error : c.accent;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.04),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Head(
            c: c,
            accent: accentColor,
            filename: filename,
            additions: additions,
            deletions: deletions,
            state: state,
            errorMessage: errorMessage,
            onApply: onApply,
            onReDiff: onReDiff,
            onCopy: onCopy,
            onOpenInEditor: onOpenInEditor,
          ),
          if (!isFailed) _Body(c: c, newCode: newCode, oldPreview: oldPreview, applied: state == ApplyCardState.applied),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({
    required this.c,
    required this.accent,
    required this.filename,
    required this.additions,
    required this.deletions,
    required this.state,
    required this.errorMessage,
    required this.onApply,
    required this.onReDiff,
    required this.onCopy,
    required this.onOpenInEditor,
  });
  final AppColors c;
  final Color accent;
  final String filename;
  final int additions;
  final int deletions;
  final ApplyCardState state;
  final String? errorMessage;
  final VoidCallback? onApply;
  final VoidCallback? onReDiff;
  final VoidCallback? onCopy;
  final VoidCallback? onOpenInEditor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: accent.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(state == ApplyCardState.failed ? Icons.warning_amber_rounded : Icons.description_outlined, size: 14, color: accent),
          const SizedBox(width: 8),
          Text(filename, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
          if (state != ApplyCardState.failed) ...[
            const SizedBox(width: 8),
            Text('+$additions', style: const TextStyle(color: Color(0xFFAAD94C), fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            const SizedBox(width: 4),
            Text('·', style: TextStyle(color: c.textMuted, fontSize: 10)),
            const SizedBox(width: 4),
            Text('−$deletions', style: const TextStyle(color: Color(0xFFF07178), fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
          ] else if (errorMessage != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '— $errorMessage',
                style: TextStyle(color: accent.withValues(alpha: 0.85), fontSize: 10, fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const Spacer(),
          if (state == ApplyCardState.ready) ...[
            if (onCopy != null) _IconButton(icon: Icons.copy, onPressed: onCopy!),
            if (onOpenInEditor != null) _IconButton(icon: Icons.open_in_new, onPressed: onOpenInEditor!),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                backgroundColor: accent.withValues(alpha: 0.18),
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
              child: const Text('Apply'),
            ),
          ] else if (state == ApplyCardState.applied) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: accent.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check, size: 10, color: accent),
                const SizedBox(width: 4),
                Text('applied', style: TextStyle(color: accent, fontSize: 10, fontFamily: 'monospace')),
              ]),
            ),
            const SizedBox(width: 6),
            if (onOpenInEditor != null) _IconButton(icon: Icons.open_in_new, onPressed: onOpenInEditor!),
          ] else ...[
            FilledButton(
              onPressed: onReDiff,
              style: FilledButton.styleFrom(
                backgroundColor: accent.withValues(alpha: 0.15),
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
              child: const Text('Re-diff'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.c, required this.newCode, required this.oldPreview, required this.applied});
  final AppColors c;
  final String newCode;
  final String oldPreview;
  final bool applied;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: applied ? 0.75 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: c.codeBlockBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              applied ? '−${oldPreview.split('\n').first}' : oldPreview,
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: Color(0xFFF07178), height: 1.5),
            ),
            const SizedBox(height: 2),
            Text(
              applied ? '+${newCode.split('\n').first}' : newCode,
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: Color(0xFFAAD94C), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return IconButton(
      icon: Icon(icon, size: 13),
      color: c.textSecondary,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      onPressed: onPressed,
    );
  }
}
```

- [ ] **Step 5: Verify the test passes**

```bash
flutter test test/features/chat/widgets/apply_diff_card_test.dart
```

Expected: All pass.

- [ ] **Step 6: Render in MessageBubble; delete the dialog stub**

First, find the active-project provider name:

```bash
grep -rn "activeProject\|currentProject" lib/features/ lib/data/ --include="*.dart" | grep "@riverpod\|Provider" | head -10
```

Note the provider name (e.g. `activeProjectProvider`) and the model fields for `id` and `path` (e.g. `project.id`, `project.path`). Substitute those below.

In `lib/features/chat/widgets/message_bubble.dart`, locate the existing block that referenced `showApplyCodeDialog` (search via `grep -n "showApplyCode\|apply_code_dialog" lib/features/chat`). Replace it with:

```dart
for (final codeBlock in message.codeBlocks)
  if (codeBlock.filename != null)
    _ApplyCardLoader(codeBlock: codeBlock, message: message),
```

Add the private `_ApplyCardLoader` widget at the bottom of `message_bubble.dart`. It loads the current file content asynchronously (needed for `oldPreview`) and tracks apply state per card independently, avoiding the single-slot `codeApplyActionsProvider` ambiguity when multiple blocks are visible:

```dart
class _ApplyCardLoader extends ConsumerStatefulWidget {
  const _ApplyCardLoader({required this.codeBlock, required this.message});
  final CodeBlock codeBlock;
  final ChatMessage message;

  @override
  ConsumerState<_ApplyCardLoader> createState() => _ApplyCardLoaderState();
}

class _ApplyCardLoaderState extends ConsumerState<_ApplyCardLoader> {
  String _oldPreview = '';
  ApplyCardState _cardState = ApplyCardState.ready;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOldContent();
  }

  Future<void> _loadOldContent() async {
    // Substitute the correct active-project provider name found above.
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    final content = await ref
        .read(codeApplyActionsProvider.notifier)
        .readFileContent(widget.codeBlock.filename!, project.path);
    if (mounted) setState(() => _oldPreview = content ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    if (project == null) return const SizedBox.shrink();
    final newCode = widget.codeBlock.code;
    return ApplyDiffCard(
      filename: widget.codeBlock.filename!,
      language: widget.codeBlock.language ?? '',
      newCode: newCode,
      oldPreview: _oldPreview,
      additions: newCode.split('\n').where((l) => l.isNotEmpty).length,
      deletions: _oldPreview.split('\n').where((l) => l.isNotEmpty).length,
      state: _cardState,
      errorMessage: _errorMessage,
      onApply: () async {
        final actions = ref.read(codeApplyActionsProvider.notifier);
        await actions.applyChange(
          projectId: project.id,
          filePath: widget.codeBlock.filename!,
          projectPath: project.path,
          newContent: newCode,
          sessionId: widget.message.sessionId,
          messageId: widget.message.id,
        );
        if (!mounted) return;
        // Inline hasError check per CLAUDE.md shared-provider exception.
        final s = ref.read(codeApplyActionsProvider);
        setState(() {
          _cardState = s.hasError ? ApplyCardState.failed : ApplyCardState.applied;
          _errorMessage = s.hasError ? s.error?.runtimeType.toString() : null;
        });
      },
      onReDiff: () {
        setState(() { _cardState = ApplyCardState.ready; _errorMessage = null; });
        _loadOldContent();
      },
    );
  }
}
```

Use `codeApplyActionsProvider`'s state (`AsyncValue.hasValue` → applied; `AsyncValue.hasError` → failed; otherwise ready) to derive the `ApplyCardState`.

Delete `lib/features/chat/widgets/apply_code_dialog.dart`. Remove its import from anywhere in the codebase:

```bash
grep -rn "apply_code_dialog" lib/ test/ --include="*.dart"
```

Each match must be removed — replace with the inline card or delete unused imports.

- [ ] **Step 7: Format, analyze, run tests, smoke test, commit**

```bash
dart format lib/features/chat/widgets/ test/features/chat/widgets/apply_diff_card_test.dart
flutter analyze
flutter test
flutter run -d macos    # generate code in chat; verify Apply button works; verify applied/failed states render
```

```bash
git add lib/features/chat/widgets/apply_diff_card.dart test/features/chat/widgets/apply_diff_card_test.dart lib/features/chat/widgets/message_bubble.dart
git rm lib/features/chat/widgets/apply_code_dialog.dart
git commit -m "feat(chat): inline apply-diff card · ready/applied/failed states"
```

---

### Task 10.5: Replace `ApplyDiffCard._Body` with `DiffBody`

**Files:**
- Modify: `lib/features/chat/widgets/apply_diff_card.dart`
- Modify: `test/features/chat/widgets/apply_diff_card_test.dart`

- [ ] **Step 1: Add a diff-text builder helper**

At the bottom of `lib/features/chat/widgets/apply_diff_card.dart`, add a private top-level function:

```dart
String _buildDiffText(String oldPreview, String newCode) {
  final buffer = StringBuffer();
  for (final line in oldPreview.split('\n')) {
    if (line.isNotEmpty) buffer.writeln('-$line');
  }
  for (final line in newCode.split('\n')) {
    if (line.isNotEmpty) buffer.writeln('+$line');
  }
  return buffer.toString();
}
```

- [ ] **Step 2: Replace `_Body` with `DiffBody`**

Delete the entire `_Body` class from `apply_diff_card.dart` (the two-`Text`-widget class from Task 10).

Add the import at the top of the file:

```dart
import 'diff_body.dart';
```

In `ApplyDiffCard.build`, replace:

```dart
if (!isFailed) _Body(c: c, newCode: newCode, oldPreview: oldPreview, applied: state == ApplyCardState.applied),
```

with:

```dart
if (!isFailed)
  Opacity(
    opacity: state == ApplyCardState.applied ? 0.75 : 1.0,
    child: DiffBody(diffText: _buildDiffText(oldPreview, newCode)),
  ),
```

- [ ] **Step 3: Update the widget test expectation**

In `test/features/chat/widgets/apply_diff_card_test.dart`, update the `ready state` test to verify `DiffBody` is present:

```dart
testWidgets('ready state shows Apply button and diff body', (tester) async {
  await tester.pumpWidget(wrap(const ApplyDiffCard(
    filename: 'chat_notifier.dart',
    language: 'dart',
    newCode: 'final x = 1;\n',
    oldPreview: 'final x = 0;\n',
    additions: 1,
    deletions: 1,
    state: ApplyCardState.ready,
  )));
  expect(find.text('Apply'), findsOneWidget);
  expect(find.text('chat_notifier.dart'), findsOneWidget);
  expect(find.byType(DiffBody), findsOneWidget);
});
```

- [ ] **Step 4: Run tests, format, analyze, smoke test, commit**

```bash
flutter test test/features/chat/widgets/apply_diff_card_test.dart
dart format lib/features/chat/widgets/apply_diff_card.dart test/features/chat/widgets/apply_diff_card_test.dart
flutter analyze
flutter run -d macos    # verify ApplyDiffCard renders full multi-line diff with row tinting
```

```bash
git add lib/features/chat/widgets/apply_diff_card.dart test/features/chat/widgets/apply_diff_card_test.dart
git commit -m "feat(chat): ApplyDiffCard uses DiffBody for full multi-line diff rendering"
```

---

## Phase G · Surface 4 · Question card · cross-provider

### Task 11: ProviderUserInputRequest event variant

**Files:**
- Modify: `lib/data/ai/models/provider_runtime_event.dart`

- [ ] **Step 1: Add the variant**

Append to `lib/data/ai/models/provider_runtime_event.dart`:

```dart
/// Agent-initiated request for typed user input (not a yes/no approval).
/// UI shows a question card with [prompt], optional [choices], and a
/// free-text fallback. The reply travels back through
/// `respondToUserInputRequest({response: <answer>})`.
class ProviderUserInputRequest extends ProviderRuntimeEvent {
  const ProviderUserInputRequest({
    required this.requestId,
    required this.prompt,
    this.choices,
    this.defaultValue,
  });
  final String requestId;
  final String prompt;
  final List<String>? choices;
  final String? defaultValue;
}
```

- [ ] **Step 2: Format, analyze, test, commit**

```bash
dart format lib/data/ai/models/provider_runtime_event.dart
flutter analyze
flutter test
git add lib/data/ai/models/provider_runtime_event.dart
git commit -m "feat(events): ProviderUserInputRequest runtime event variant"
```

---

### Task 12: respondToUserInputRequest on the datasource interface

**Files:**
- Modify: `lib/data/ai/datasource/ai_provider_datasource.dart`

- [ ] **Step 1: Add the method to the abstract**

Open `lib/data/ai/datasource/ai_provider_datasource.dart`. Locate `respondToPermissionRequest`. Add a sibling:

```dart
/// Respond to an agent-initiated user-input request emitted as a
/// [ProviderUserInputRequest]. Datasources that don't surface user-input
/// requests should override with a no-op.
void respondToUserInputRequest(String sessionId, String requestId, {required String response});
```

- [ ] **Step 2: Add no-op default to abstract or implementations**

If the interface is a pure abstract, every implementation must override. If it has a default body, you can place a no-op there. Choose based on the existing code style.

- [ ] **Step 3: Add no-op to providers that don't need it**

Open each implementation (`anthropic_remote_datasource_dio.dart`, `openai_remote_datasource_dio.dart`, `gemini_remote_datasource_dio.dart`, `ollama_remote_datasource_dio.dart`, `custom_remote_datasource_dio.dart`, `claude_cli_datasource_process.dart`). Add a stub for now:

```dart
@override
void respondToUserInputRequest(String sessionId, String requestId, {required String response}) {
  // Real wiring lands in subsequent tasks for this datasource.
}
```

This keeps the analyzer happy; per-provider wiring follows in tasks 14–17.

- [ ] **Step 4: Format, analyze, test, commit**

```bash
dart format lib/data/ai/datasource/
flutter analyze
flutter test
git add lib/data/ai/datasource/
git commit -m "feat(ai-datasource): add respondToUserInputRequest interface stub"
```

---

### Task 12.5: Surface `respondToUserInputRequest` through the repository layer

**Files:**
- Modify: the AI provider repository interface (find via grep below)
- Modify: the AI provider repository implementation (find via grep below)

- [ ] **Step 1: Locate the repository layer**

```bash
find lib/data/ai/repository -name "*.dart" | grep -v ".g.dart\|.freezed.dart" | head -10
```

Identify the abstract interface (likely `ai_provider_repository.dart`) and the implementation (likely `*_impl.dart`). The interface already has `respondToPermissionRequest` — add `respondToUserInputRequest` as a sibling.

- [ ] **Step 2: Add to the abstract interface**

In the interface file, locate `respondToPermissionRequest`. Add immediately after it:

```dart
void respondToUserInputRequest(String sessionId, String requestId, {required String response});
```

- [ ] **Step 3: Add the implementation**

In the `*RepositoryImpl` class, inspect how `respondToPermissionRequest` delegates to the datasource. Add a sibling with the same delegation pattern:

```dart
@override
void respondToUserInputRequest(String sessionId, String requestId, {required String response}) {
  _datasource.respondToUserInputRequest(sessionId, requestId, response: response);
}
```

Replace `_datasource` with whatever field name the existing `respondToPermissionRequest` body uses.

- [ ] **Step 4: Format, analyze, run tests, commit**

```bash
dart format lib/data/ai/repository/
flutter analyze
flutter test
git add lib/data/ai/repository/
git commit -m "feat(ai-repo): surface respondToUserInputRequest through repository layer"
```

---

### Task 13: AgentUserInputRequestNotifier + tests

**Files:**
- Create: `lib/features/chat/notifiers/agent_user_input_request_notifier.dart`
- Test: `test/features/chat/notifiers/agent_user_input_request_notifier_test.dart`

- [ ] **Step 1: Write the notifier (TDD pair: test first)**

Create `test/features/chat/notifiers/agent_user_input_request_notifier_test.dart`:

```dart
import 'package:code_bench/data/ai/models/provider_runtime_event.dart';
import 'package:code_bench/features/chat/notifiers/agent_user_input_request_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state is null', () {
    final container = ProviderContainer();
    expect(container.read(agentUserInputRequestProvider), isNull);
    container.dispose();
  });

  test('request stores the active request and emits it', () {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider.notifier);
    final req = const ProviderUserInputRequest(requestId: 'r1', prompt: 'q?');
    n.requestAndAwait(req);
    expect(container.read(agentUserInputRequestProvider), req);
    container.dispose();
  });

  test('submit completes the future with the answer and clears state', () async {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider.notifier);
    final fut = n.requestAndAwait(const ProviderUserInputRequest(requestId: 'r1', prompt: 'q?'));
    n.submit('hello');
    final answer = await fut;
    expect(answer, 'hello');
    expect(container.read(agentUserInputRequestProvider), isNull);
    container.dispose();
  });

  test('cancel completes the future with null and clears state', () async {
    final container = ProviderContainer();
    final n = container.read(agentUserInputRequestProvider.notifier);
    final fut = n.requestAndAwait(const ProviderUserInputRequest(requestId: 'r1', prompt: 'q?'));
    n.cancel();
    final answer = await fut;
    expect(answer, isNull);
    expect(container.read(agentUserInputRequestProvider), isNull);
    container.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/chat/notifiers/agent_user_input_request_notifier_test.dart
```

Expected: Compilation error.

- [ ] **Step 3: Implement notifier**

Create `lib/features/chat/notifiers/agent_user_input_request_notifier.dart`:

```dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/provider_runtime_event.dart';

part 'agent_user_input_request_notifier.g.dart';

/// Holds the active [ProviderUserInputRequest], if any, and provides
/// imperative `submit` / `cancel` methods. Parallels
/// `AgentPermissionRequestNotifier` in shape.
@Riverpod(keepAlive: true)
class AgentUserInputRequestNotifier extends _$AgentUserInputRequestNotifier {
  Completer<String?>? _pending;

  @override
  ProviderUserInputRequest? build() => null;

  /// Stores the request and returns a future that resolves when the user
  /// answers (string) or cancels (null).
  Future<String?> requestAndAwait(ProviderUserInputRequest req) {
    _pending?.complete(null); // any prior pending is implicitly cancelled
    _pending = Completer<String?>();
    state = req;
    return _pending!.future;
  }

  void submit(String answer) {
    _pending?.complete(answer);
    _pending = null;
    state = null;
  }

  void cancel() {
    _pending?.complete(null);
    _pending = null;
    state = null;
  }
}
```

- [ ] **Step 4: Codegen**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run tests, format, analyze, commit**

```bash
flutter test test/features/chat/notifiers/agent_user_input_request_notifier_test.dart
dart format lib/features/chat/notifiers/agent_user_input_request_notifier.dart test/features/chat/notifiers/agent_user_input_request_notifier_test.dart
flutter analyze
git add lib/features/chat/notifiers/agent_user_input_request_notifier.dart lib/features/chat/notifiers/agent_user_input_request_notifier.g.dart test/features/chat/notifiers/agent_user_input_request_notifier_test.dart
git commit -m "feat(chat): AgentUserInputRequestNotifier · request/submit/cancel"
```

---

### Task 14: AskUserQuestionCard agent-mode (info-blue, single-step)

**Files:**
- Modify: `lib/features/chat/widgets/ask_user_question_card.dart`

- [ ] **Step 1: Add an agent-mode flag to the widget**

In `AskUserQuestionCard`, add a constructor flag:

```dart
const AskUserQuestionCard({
  super.key,
  required this.question,
  required this.sessionId,
  required this.onSubmit,
  this.onBack,
  this.agentMode = false,
});
final bool agentMode;
```

- [ ] **Step 2: Hide stepper when single-step (or agentMode)**

In the `build` method, replace the existing `_StepHeader(...)` line with:

```dart
if (!agentMode && widget.question.totalSteps > 1) ...[
  _StepHeader(
    currentStep: widget.question.stepIndex,
    totalSteps: widget.question.totalSteps,
    sectionLabel: widget.question.sectionLabel,
  ),
  const SizedBox(height: 12),
],
```

- [ ] **Step 3: Switch container colors when agentMode**

In the existing `Container` decoration:

```dart
final infoColor = agentMode ? c.info : c.blueAccent;
final cardBg = agentMode ? c.info.withValues(alpha: 0.06) : c.questionCardBg;
final cardBorder = agentMode ? c.info.withValues(alpha: 0.4) : c.selectionBorder;

return Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(8),
    border: Border(
      left: BorderSide(color: infoColor, width: 3),
      top: BorderSide(color: cardBorder),
      right: BorderSide(color: cardBorder),
      bottom: BorderSide(color: cardBorder),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // ... existing content with stepper conditional from Step 2
      if (agentMode) ...[
        Text(
          'Question from agent',
          style: TextStyle(color: infoColor, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
      ],
      // existing prompt + options + free text + actions
    ],
  ),
);
```

In the existing `_OptionRow` selected color, swap `c.blueAccent` for `infoColor` when `agentMode`. Keep the existing constructor's color path otherwise.

In the action row, when `agentMode == true`, hide the "Clear answer" button entirely and label the primary button "Submit":

```dart
if (!agentMode)
  TextButton(
    onPressed: widget.question.stepIndex > 0 ? widget.onBack : null,
    child: const Text('Clear answer', style: TextStyle(fontSize: 11)),
  )
else
  const SizedBox.shrink(),
const Spacer(),
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: infoColor,
    foregroundColor: c.onAccent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
  ),
  onPressed: _canSubmit ? _handleSubmit : null,
  child: Text(
    agentMode || _isLastStep ? 'Submit' : 'Next →',
    style: const TextStyle(fontSize: 11),
  ),
),
```

- [ ] **Step 4: Format, analyze, test, commit**

```bash
dart format lib/features/chat/widgets/ask_user_question_card.dart
flutter analyze
flutter test
git add lib/features/chat/widgets/ask_user_question_card.dart
git commit -m "feat(chat): agent-mode question card · info-blue · single-step submit"
```

---

### Task 15: Render question card from agentUserInputRequestProvider in MessageBubble

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`
- Modify: `lib/features/chat/notifiers/chat_notifier.dart`

- [ ] **Step 1: Forward ProviderUserInputRequest events in chat_notifier**

In `chat_notifier.dart`, find the runtime-event consumer (the place where `ProviderPermissionRequest` is forwarded to `agentPermissionRequestProvider`). Add a parallel branch:

```dart
if (event is ProviderUserInputRequest) {
  unawaited(_handleUserInputRequest(event));
  return;
}
```

Add `_handleUserInputRequest`:

```dart
Future<void> _handleUserInputRequest(ProviderUserInputRequest req) async {
  final n = ref.read(agentUserInputRequestProvider.notifier);
  final response = await n.requestAndAwait(req);
  if (response == null) {
    // user cancelled — interrupt the turn
    await _cancelCurrentTurn();
    return;
  }
  final session = ref.read(activeSessionIdProvider);
  if (session == null) return;
  ref.read(aiProviderRepositoryProvider).respondToUserInputRequest(
    session,
    req.requestId,
    response: response,
  );
}
```

(If `_cancelCurrentTurn` does not exist, use the existing cancel-stream path; the engineer should grep for whatever notifier method already cancels in-flight turns and reuse it.)

Add the import:

```dart
import 'agent_user_input_request_notifier.dart';
```

- [ ] **Step 2: Add `isLastInSession` parameter to `MessageBubble`**

The question card must only appear on the last bubble in the session — not on every historical bubble. `message.isStreaming` is the wrong guard because the stream pauses while awaiting the answer, so `isStreaming` may already be false when the card needs to be visible.

Add a `isLastInSession` bool constructor parameter to the bubble widget (search for the `MessageBubble` or equivalent class that renders a single assistant turn):

```dart
const MessageBubble({
  super.key,
  required this.message,
  this.isLastInSession = false,   // add this
  // ... existing params
});
final bool isLastInSession;
```

In the message list widget that builds each bubble, pass:

```dart
MessageBubble(
  message: messages[index],
  isLastInSession: index == messages.length - 1,
  // ... existing args
)
```

- [ ] **Step 3: Render the card in the message bubble**

In `lib/features/chat/widgets/message_bubble.dart`, near the existing `if (message.askQuestion != null)` block, add a sibling that watches the new provider:

```dart
Consumer(
  builder: (context, ref, _) {
    final req = ref.watch(agentUserInputRequestProvider);
    if (req == null) return const SizedBox.shrink();
    if (!isLastInSession) return const SizedBox.shrink();
    final asWizard = AskUserQuestion(
      question: req.prompt,
      options: req.choices ?? const <String>[],
      allowFreeText: true,
      stepIndex: 0,
      totalSteps: 1,
    );
    return AskUserQuestionCard(
      question: asWizard,
      sessionId: message.sessionId,
      agentMode: true,
      onSubmit: (answer) async {
        final text = (answer['freeText'] as String?) ?? (answer['selectedOption'] as String?) ?? '';
        ref.read(agentUserInputRequestProvider.notifier).submit(text);
      },
    );
  },
),
```

Add the import:

```dart
import '../notifiers/agent_user_input_request_notifier.dart';
```

- [ ] **Step 4: Format, analyze, test, commit**

```bash
dart format lib/features/chat/notifiers/chat_notifier.dart lib/features/chat/widgets/message_bubble.dart
flutter analyze
flutter test
git add lib/features/chat/notifiers/chat_notifier.dart lib/features/chat/widgets/message_bubble.dart
git commit -m "feat(chat): wire AgentUserInputRequestNotifier into bubble + chat notifier"
```

---

### Task 16: Codex producer wiring · ProviderUserInputRequest

**Files:**
- Modify: `lib/data/ai/datasource/codex_session.dart`
- Modify: `lib/data/ai/datasource/codex_session_pool.dart`
- Modify: `lib/data/ai/datasource/codex_cli_datasource_process.dart`

- [ ] **Step 1: Capture a real `requestUserInput` payload (data risk)**

The spec flags this as a data-shape risk. Run codex with a prompt that triggers the agent to ask a question (e.g., a vague task that the agent must clarify). Capture the JSON-RPC server request via `dLog` output by temporarily adding to `codex_session.dart` `_handleServerRequest`:

```dart
if (method == 'item/tool/requestUserInput') {
  dLog('[CodexCli] requestUserInput params: ${jsonEncode(params)}');
}
```

Run:

```bash
flutter run -d macos
```

Trigger an ambiguous task; observe the logged payload in the console. Note the field names — typical candidates are `prompt`, `message`, `choices`, `options`, `default_response`. If the payload has unexpected shapes, update the variant fields in `provider_runtime_event.dart` (Task 11) before proceeding.

Remove the temporary `dLog` after capturing.

- [ ] **Step 2: Branch the handler to emit ProviderUserInputRequest**

In `codex_session.dart`, replace the existing `case 'item/tool/requestUserInput':` branch (currently calls `_emitPermissionRequest`):

```dart
case 'item/tool/requestUserInput':
  _emitUserInputRequest(id, params);
```

Add `_emitUserInputRequest` next to `_emitPermissionRequest`:

```dart
void _emitUserInputRequest(dynamic id, Map<String, dynamic>? params) {
  final normalized = _coerceId(id);
  final requestId = (normalized ?? id).toString();

  // Field names verified against a real payload in Step 1; adjust here if needed.
  final prompt = (params?['prompt'] ?? params?['message'] ?? '') as String;
  final rawChoices = params?['choices'] ?? params?['options'];
  final choices = rawChoices is List ? rawChoices.whereType<String>().toList() : null;
  final defaultValue = params?['default_response'] as String?;

  final completer = Completer<Map<String, dynamic>>();
  _pendingApprovals[requestId] = completer;
  final requestProcess = _process;
  final requestThreadId = _providerThreadId;

  _streamController?.add(
    ProviderUserInputRequest(
      requestId: requestId,
      prompt: prompt,
      choices: choices,
      defaultValue: defaultValue,
    ),
  );

  completer.future.then(
    (result) {
      if (!identical(_process, requestProcess) || _providerThreadId != requestThreadId) {
        sLog('[CodexCli] User-input response dropped — turn changed (id=$id)');
        return;
      }
      _respond(id, result);
    },
    onError: (e) {
      sLog('[CodexCli] User-input response failed: $e');
    },
  );
}
```

- [ ] **Step 3: Add respondToUserInputRequest to CodexSession**

In `codex_session.dart`, near `respondToPermissionRequest`:

```dart
void respondToUserInputRequest(String requestId, {required String response}) {
  final completer = _pendingApprovals.remove(requestId);
  if (completer == null) {
    dLog('[CodexCli] No pending user-input request for $requestId');
    return;
  }
  completer.complete({'response': response});
}
```

- [ ] **Step 4: Forward through pool and datasource**

In `codex_session_pool.dart`, parallel to `respondToPermissionRequest`:

```dart
void respondToUserInputRequest(String sessionId, String requestId, {required String response}) {
  _sessions[sessionId]?.respondToUserInputRequest(requestId, response: response);
}
```

In `codex_cli_datasource_process.dart`:

```dart
@override
void respondToUserInputRequest(String sessionId, String requestId, {required String response}) =>
    _pool.respondToUserInputRequest(sessionId, requestId, response: response);
```

- [ ] **Step 5: Format, analyze, test, smoke test, commit**

```bash
dart format lib/data/ai/datasource/codex_session.dart lib/data/ai/datasource/codex_session_pool.dart lib/data/ai/datasource/codex_cli_datasource_process.dart
flutter analyze
flutter test
flutter run -d macos    # trigger an ambiguous task; verify question card appears, answer is sent back, agent continues
```

```bash
git add lib/data/ai/datasource/
git commit -m "fix(codex): route requestUserInput to question card with typed reply"
```

---

### Task 17: Claude CLI producer wiring · intercept AskUserQuestion tool_use

**Files:**
- Modify: `lib/data/ai/datasource/claude_cli_datasource_process.dart`

- [ ] **Step 1: Capture a real AskUserQuestion stream-json (data risk)**

In a test session with Claude CLI, prompt the agent to ask a clarifying question. Add a temporary `dLog` to `claude_cli_stream_parser.dart` `_parseStreamEvent` `content_block_start` case:

```dart
if (block['type'] == 'tool_use' && block['name'] == 'AskUserQuestion') {
  dLog('[ClaudeCli] AskUserQuestion block: ${jsonEncode(block)}');
}
```

Run, observe the input schema. Anthropic's `AskUserQuestion` tool typically takes `{question: string, options: string[]}`. Confirm before proceeding.

Remove the temporary log.

- [ ] **Step 2: Add interception in claude_cli_datasource_process.dart**

In `claude_cli_datasource_process.dart`, locate where `StreamEvent.cliToolUseComplete` is handled (the dispatcher that turns parsed events into `ProviderRuntimeEvent`s for the controller). Add a branch *before* emitting the regular tool-use complete:

```dart
case CliToolUseComplete(:final id, :final input):
  if (input is Map<String, dynamic> && _isAskUserQuestion(_pendingNames[id])) {
    final prompt = (input['question'] ?? '') as String;
    final rawChoices = input['options'];
    final choices = rawChoices is List ? rawChoices.whereType<String>().toList() : null;
    _pendingAskUserQuestions[sessionId] = _PendingAUQ(toolUseId: id, sessionId: sessionId);
    controller.add(ProviderUserInputRequest(
      requestId: id,
      prompt: prompt,
      choices: choices,
    ));
    break;
  }
  controller.add(ProviderToolUseComplete(toolId: id, input: input));
  break;
```

`_isAskUserQuestion` is a helper:

```dart
bool _isAskUserQuestion(String? name) =>
    name == 'AskUserQuestion' || name == 'ask_user_question';
```

`_pendingNames` is a `Map<String, String>` keyed by tool-use id, populated in the `cliToolUseStart` branch:

```dart
case CliToolUseStart(:final id, :final name):
  _pendingNames[id] = name;
  if (name != 'AskUserQuestion') {
    controller.add(ProviderToolUseStart(toolId: id, toolName: name));
  }
  break;
```

`_pendingAskUserQuestions` tracks unresolved AUQ calls per session for the response path:

```dart
final Map<String, _PendingAUQ> _pendingAskUserQuestions = {};

class _PendingAUQ {
  _PendingAUQ({required this.toolUseId, required this.sessionId});
  final String toolUseId;
  final String sessionId;
}
```

- [ ] **Step 3: Implement respondToUserInputRequest**

Replace the existing no-op `respondToUserInputRequest` from Task 12 with:

```dart
@override
void respondToUserInputRequest(String sessionId, String requestId, {required String response}) {
  final pending = _pendingAskUserQuestions.remove(sessionId);
  if (pending == null || pending.toolUseId != requestId) {
    dLog('[ClaudeCli] No pending AskUserQuestion for session $sessionId / request $requestId');
    return;
  }
  // Inject a tool_result back into the CLI's stdin as a user-message turn.
  // Claude CLI accepts these in --output-format stream-json mode.
  final payload = jsonEncode({
    'type': 'user',
    'message': {
      'role': 'user',
      'content': [
        {
          'type': 'tool_result',
          'tool_use_id': requestId,
          'content': response,
        }
      ],
    },
  });
  _processes[sessionId]?.stdin.writeln(payload);
}
```

(If Claude CLI's stream-json input format differs, adjust the payload shape — verify by inspecting a real input echo from the Claude CLI docs that ship with the binary, or by capturing a stdin sample.)

- [ ] **Step 4: Format, analyze, test, smoke, commit**

```bash
dart format lib/data/ai/datasource/claude_cli_datasource_process.dart
flutter analyze
flutter test
flutter run -d macos    # ask Claude CLI a vague question; verify question card appears and answer is sent back
```

```bash
git add lib/data/ai/datasource/claude_cli_datasource_process.dart
git commit -m "feat(claude-cli): intercept AskUserQuestion tool_use → ProviderUserInputRequest"
```

---

### Task 18: API providers · register AskUserQuestion as a tool

**Files:**
- Create: `lib/data/ai/models/agent_ask_user_question_tool.dart`
- Modify: `lib/data/ai/datasource/anthropic_remote_datasource_dio.dart`
- Modify: `lib/data/ai/datasource/openai_remote_datasource_dio.dart`
- Modify: `lib/data/ai/datasource/gemini_remote_datasource_dio.dart`
- Modify: `lib/data/ai/datasource/ollama_remote_datasource_dio.dart`
- Modify: `lib/data/ai/datasource/custom_remote_datasource_dio.dart`

- [ ] **Step 1: Define the canonical schema**

Create `lib/data/ai/models/agent_ask_user_question_tool.dart`:

```dart
/// Canonical name and JSON-schema for the AskUserQuestion tool that
/// API-direct providers expose to the model. The host intercepts
/// tool-use blocks with this name and surfaces a question card instead
/// of executing.
class AgentAskUserQuestionTool {
  AgentAskUserQuestionTool._();

  static const String name = 'AskUserQuestion';
  static const String description =
      'Ask the user a clarifying question. Use this when you need information '
      'from the user that you cannot infer from context. Returns the user\'s '
      'typed answer as the tool result.';

  static const Map<String, dynamic> inputSchema = {
    'type': 'object',
    'properties': {
      'question': {
        'type': 'string',
        'description': 'The question to ask the user.',
      },
      'options': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Optional list of suggested answers.',
      },
    },
    'required': ['question'],
  };

  static Map<String, dynamic> get anthropicShape => {
        'name': name,
        'description': description,
        'input_schema': inputSchema,
      };

  static Map<String, dynamic> get openAiShape => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': inputSchema,
        },
      };

  static Map<String, dynamic> get geminiShape => {
        'name': name,
        'description': description,
        'parameters': inputSchema,
      };

  /// Ollama uses OpenAI-compatible function-calling.
  static Map<String, dynamic> get ollamaShape => openAiShape;
}
```

- [ ] **Step 2: Register in each datasource**

For each `*_remote_datasource_dio.dart`, find where the request body's `tools` list is built. Add the appropriate shape:

For `anthropic_remote_datasource_dio.dart`:

```dart
final tools = <Map<String, dynamic>>[
  ...existingTools,
  AgentAskUserQuestionTool.anthropicShape,
];
```

For `openai_remote_datasource_dio.dart`, `ollama_remote_datasource_dio.dart`, `custom_remote_datasource_dio.dart`:

```dart
final tools = <Map<String, dynamic>>[
  ...existingTools,
  AgentAskUserQuestionTool.openAiShape,
];
```

For `gemini_remote_datasource_dio.dart`:

```dart
final tools = <Map<String, dynamic>>[
  ...existingTools,
  AgentAskUserQuestionTool.geminiShape,
];
```

- [ ] **Step 3: Intercept tool-use blocks named AskUserQuestion**

In each datasource's response-streaming path, when a tool-use block is parsed, check for `name == 'AskUserQuestion'` *before* dispatching to the host's tool-execution path:

```dart
if (toolUse.name == AgentAskUserQuestionTool.name) {
  final input = toolUse.input as Map<String, dynamic>;
  final prompt = (input['question'] ?? '') as String;
  final rawOptions = input['options'];
  final choices = rawOptions is List ? rawOptions.whereType<String>().toList() : null;
  _pendingUserInputRequests[sessionId] = (toolUseId: toolUse.id);
  controller.add(ProviderUserInputRequest(
    requestId: toolUse.id,
    prompt: prompt,
    choices: choices,
  ));
  return; // do NOT execute as a regular tool
}
```

Add `_pendingUserInputRequests` as a `Map<String, ({String toolUseId})>` on the datasource.

- [ ] **Step 4: Implement respondToUserInputRequest in each datasource**

Replace the no-op stub from Task 12. Each datasource's reply path: assemble a `tool_result` keyed by the original tool-use id, then continue the agent loop's next turn with that result:

```dart
@override
void respondToUserInputRequest(String sessionId, String requestId, {required String response}) {
  final pending = _pendingUserInputRequests.remove(sessionId);
  if (pending == null || pending.toolUseId != requestId) {
    dLog('[<ProviderName>] No pending AskUserQuestion for $sessionId/$requestId');
    return;
  }
  // Wire into the agent loop's existing tool-result feedback path.
  // Each datasource has a different mechanism for this — typically a
  // controller it pushes a synthetic ToolResultEvent into.
  _agentLoopFeedback(sessionId, ToolResultEvent(
    toolUseId: requestId,
    output: response,
    isError: false,
  ));
}
```

The `_agentLoopFeedback` call is provider-specific. The engineer must locate the existing code path that delivers the executed-tool result back to the next API turn (search: `tool_result` references in each datasource) and reuse it.

- [ ] **Step 5: Format, analyze, test, smoke, commit**

```bash
dart format lib/data/ai/
flutter analyze
flutter test
flutter run -d macos    # test with each provider configured: ask an ambiguous question, verify card appears
```

```bash
git add lib/data/ai/
git commit -m "feat(api-providers): register AskUserQuestion tool · intercept and reply"
```

---

## Phase H · Final integration & smoke testing

### Task 19: End-to-end smoke matrix + analyze + format + test

**Files:** none (verification only)

- [ ] **Step 1: Run the full check suite**

```bash
dart format lib/ test/
flutter analyze
flutter test
```

Expected: All passing, no analyze issues.

- [ ] **Step 2: Smoke-test each surface in macOS app**

```bash
flutter run -d macos
```

Verify in order:

1. **Surface 2 · Session list dots** — open the sidebar; observe dots prefix each session row with the right color (start a turn → streaming dot pulses; permission card pending → amber; cause a stream failure → red; idle session → gray).
2. **Surface 1 · Phase pill + tool cards** — send a message that causes the agent to read files and run a shell command. Verify color-coded pills at the bubble tail (blue for read, amber for shell, teal for thinking). Verify tool cards stay in the bubble after the turn completes.
3. **Surface 6 · Brand badges** — verify each tool card shows a brand-colored provider chip with a leading dot, and a separate neutral model chip.
4. **Surface 3 · Markdown / Ayu / toolbar** — paste a code-fenced markdown reply; verify the code block renders with Ayu-dark bg (#0B0E14). Verify copy/retry/delete row appears below every assistant bubble (always visible).
5. **Surface 5 · Apply diff** — ask the agent to make a code edit; verify the inline ApplyDiffCard renders with `Apply` button. Click `Apply` → verify "applied" pill replaces the button. Force a divergence (modify the file externally) → verify "Re-diff" path.
6. **Surface 4 · Question card** — *for each* of: codex, claude-cli, anthropic API, openai API, gemini API, ollama, custom — send a vague task that should make the agent ask a clarifying question. Verify:
   - Info-blue question card appears (not amber permission card).
   - Submitting an answer makes the agent continue.
   - Cancelling halts the turn cleanly.

- [ ] **Step 3: Address any regressions surfaced during smoke**

Document and fix issues. Each fix is its own commit.

- [ ] **Step 4: Final commit**

If any final polish is needed:

```bash
git add -A
git commit -m "chore: final polish for chat experience overhaul"
```

If everything was clean during smoke and tests, no extra commit is needed.

---

### Task 20: Open the PR

**Files:** none

- [ ] **Step 1: Push the branch**

```bash
git push -u origin feat/2026-05-08-chat-experience-overhaul
```

- [ ] **Step 2: Open the PR using the repo's template**

```bash
gh pr create --base main --head feat/2026-05-08-chat-experience-overhaul --fill
```

`gh pr create` auto-uses [.github/pull_request_template.md](../../../.github/pull_request_template.md). Verify the body before submitting; ensure each acceptance criterion from the spec is mapped to a checkbox.

- [ ] **Step 3: Run /ultrareview if desired**

`/ultrareview` is user-triggered and bills the user; surface the option in the PR description but don't auto-launch.

---

## Self-review notes

- **Spec coverage:** every numbered surface (1–6 plus cross-cutting and code-theme) maps to at least one task. Question card touches tasks 11–18. Brand attribution: 1–3. Markdown/Ayu/toolbar: 5–6 (and 6.5 if needed). Phase pill: 7–9. Apply diff: 10. Session dot: 4.
- **Type consistency:** `ApplyCardState` enum (ready/applied/failed) used consistently in Task 10. `PhaseClass` enum (think/tool/io) used consistently across 7, 8, 9. `ProviderUserInputRequest` shape locked in Task 11 and consumed unchanged by 13, 16, 17, 18.
- **Risks acknowledged:** Tasks 16 and 17 explicitly call out the data-shape capture step before locking the parser, per the spec's Risks section. Task 5 has a fallback for missing `re_highlight` ayu themes. Task 4 has a fallback for missing session view-model fields.
- **Codegen reminders:** Tasks 13 (notifier) explicitly run `build_runner`. Other modified `@riverpod` / `@freezed` files (none in this plan beyond task 13) — none expected.
- **Pre-existing work to discover during execution:** Tasks 4 (session row widget path), 6 (action row implementation status), 6.5 (chat actions notifier methods), and 17/18 (per-provider tool-result feedback path) require runtime grep before writing code. Plan calls these out explicitly.
