# Phase 1a — Foundation + UI Surfaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply color tokens, typography scale, Lucide icons, instant route transitions, redesigned message bubbles, functional input-bar dropdowns, sidebar sort, project tile polish, and stub top action bar layout.

**Architecture:** Pure UI layer — no new services or DB changes. All state for sort order lives in a new `ProjectSortNotifier` backed by `SharedPreferences`. Message layout, chip dropdowns, and top bar are self-contained widget changes.

**Tech Stack:** Flutter, Riverpod (`riverpod_annotation`), `lucide_icons_flutter`, `shared_preferences` (already in project), `go_router` (NoTransitionPage for instant routes).

---

## As Implemented — Deviations from Plan

The following changes were made during implementation that differ from or extend the original plan.

### Additional files created / changed

| File | Reason |
|---|---|
| `analysis_options.yaml` | Added `formatter: page_width: 120` — Dart 3.4+ reads this automatically, no CI or flag changes needed |
| `CLAUDE.md` | Added rule: never manually edit generated files (`*.g.dart`, `*.freezed.dart`); always use `build_runner` |
| `lib/core/utils/instant_menu.dart` | New utility: `showInstantMenu<T>` — zero-animation drop-in for `showMenu` (see below) |
| `lib/features/project_sidebar/widgets/project_context_menu.dart` | Switched from `showMenu` to `showInstantMenu`; removed "Rename project" item |

### Zero-animation popup menus (`showInstantMenu`)

The plan said to fix the model picker anchor. During implementation, the user also requested that all popup menus appear and disappear instantly (no scale/fade animation).

`PopupMenuThemeData.popUpAnimationStyle` (Flutter 3.16+) was the first attempt but didn't compile on the project's Flutter version. Instead, a custom `PopupRoute` subclass was created at `lib/core/utils/instant_menu.dart`:

- `_InstantMenuRoute<T>` — `transitionDuration: Duration.zero`, `reverseTransitionDuration: Duration.zero`
- `_MenuLayout` (`SingleChildLayoutDelegate`) — opens above or below the anchor based on available space; placing the menu bottom at `position.top` (button top) when opening upward so the chip is never obscured
- `ExcludeSemantics` wrapper — suppresses the `SemanticsRole.menuItem` assertion that fires when `PopupMenuItem` is rendered outside Flutter's own `_PopupMenu` route

All `showMenu` calls in the app now use `showInstantMenu`:
- `chat_input_bar_v2.dart` — effort, mode, permission, model picker chips
- `project_sidebar.dart` — sort menu
- `project_context_menu.dart` — project right-click menu

### Popup anchor calculation

The plan's Task 4 showed a `RelativeRect` using `offset.dx + size.width` as the `right` value — this is an x-coordinate, not a screen-edge inset. The correct value is `overlayWidth - offset.dx - chipWidth`.

The final `_menuAbove` helper in `chat_input_bar_v2.dart` uses `position.top = origin.dy` (button top). `_MenuLayout` then places the menu at `y = origin.dy - menuHeight`, so the menu bottom aligns with the button top — the chip remains fully visible.

The sidebar sort icon uses `position.top = origin.dy + box.size.height` (button bottom) so the menu opens downward.

### Conversation tile — right-click context menu

The plan scoped `conversation_tile.dart` to "font size and token cleanup only." During implementation, the user also requested:

- **Remove "Rename project"** from the project right-click menu
- **Add "Rename" and "Delete"** to a new right-click context menu on conversation tiles

`ConversationTile` now accepts optional `onRename` and `onDelete` callbacks and shows a `showInstantMenu` popup on right-click. `ProjectTile.onRename` and `ProjectContextMenu.handleAction`'s `onRename` parameter were removed entirely.

### Code review fixes in `chat_input_bar_v2.dart`

Applied during a post-implementation review — not in the original plan:

- `_keyboardFocusNode` added as a field and disposed in `dispose()` — the original plan's snippet created `FocusNode()` inline in `KeyboardListener`, leaking one instance per rebuild
- `_focusNode.requestFocus()` moved inside the `if (mounted)` guard in the `finally` block
- `if (box is! RenderBox || !box.hasSize) return` guard added to `_showDropdown` and `_showModelPicker` — the plan used an unchecked `as RenderBox` cast

### Sort notifier — safe async state read

`ProjectSort.setProjectSort` and `setThreadSort` use `state.valueOrNull ?? await future`. The plan's original snippet re-awaited `future` unconditionally, which could read a stale in-flight state under certain race conditions.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `pubspec.yaml` | Modify | Add `lucide_icons_flutter` dependency |
| `lib/core/constants/theme_constants.dart` | Modify | Add 4 color tokens, update/add font size constants |
| `lib/router/app_router.dart` | Modify | Replace all `builder:` with `pageBuilder:` using `NoTransitionPage` |
| `lib/features/chat/widgets/message_bubble.dart` | Modify | Remove avatars/labels, right-align user, flat assistant, pulsing dot |
| `lib/features/chat/widgets/chat_input_bar_v2.dart` | Modify | Lucide icons, functional dropdowns for Effort/Mode/Permissions, fix model picker anchor |
| `lib/features/project_sidebar/project_sidebar_notifier.dart` | Modify | Add `ProjectSortOrder`, `ThreadSortOrder` enums + `ProjectSortNotifier` with SharedPreferences |
| `lib/features/project_sidebar/project_sidebar.dart` | Modify | Add sort icon button + sort dropdown, Lucide icons, token cleanup |
| `lib/features/project_sidebar/widgets/project_tile.dart` | Modify | Lucide icons, icon-only git badge, hover new-chat icon |
| `lib/features/project_sidebar/widgets/conversation_tile.dart` | Modify | Font size 11px, token cleanup |
| `lib/shell/widgets/top_action_bar.dart` | Modify | New layout: title+badges left, Add action + VS Code dropdown + Commit/Push split button right |
| `lib/shell/widgets/status_bar.dart` | Modify | Lucide icons, token cleanup |

---

### Task 1: Add Lucide package + color tokens + typography

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/constants/theme_constants.dart`

- [ ] **Step 1: Add `lucide_icons_flutter` to pubspec.yaml**

  In `pubspec.yaml`, under `# Icons`, replace:
  ```yaml
  # Icons
  cupertino_icons: ^1.0.8
  ```
  with:
  ```yaml
  # Icons
  cupertino_icons: ^1.0.8
  lucide_icons_flutter: ^1.0.0
  ```

- [ ] **Step 2: Run `flutter pub get`**

  ```bash
  flutter pub get
  ```
  Expected: resolves without errors.

- [ ] **Step 3: Add 4 color tokens and update font sizes in ThemeConstants**

  In `lib/core/constants/theme_constants.dart`, replace the block from `// Icon sizes` onwards with:
  ```dart
    // Input / surface tokens (for input boxes, card surfaces, button backgrounds)
    static const Color inputSurface = Color(0xFF1A1A1A);
    static const Color deepBorder = Color(0xFF222222);
    static const Color mutedFg = Color(0xFF555555);
    static const Color faintFg = Color(0xFF333333);

    // Icon sizes
    static const double iconSizeSmall = 14;
    static const double iconSizeMedium = 18;
    static const double iconSizeLarge = 24;

    // Font
    static const String editorFontFamily = 'JetBrains Mono';
    static const double editorFontSize = 13;
    static const double uiFontSize = 12;        // body: messages, sidebar titles
    static const double uiFontSizeSmall = 11;   // secondary: chips, button labels
    static const double uiFontSizeLabel = 10;   // labels: section headers, timestamps
    static const double uiFontSizeBadge = 9;    // badges: git tag, provider badge
    static const double uiFontSizeLarge = 15;
  }
  ```

- [ ] **Step 4: Run analyze to confirm no breakage**

  ```bash
  flutter analyze
  ```
  Expected: no new errors.

- [ ] **Step 5: Commit**

  ```bash
  git add pubspec.yaml pubspec.lock lib/core/constants/theme_constants.dart
  git commit -m "feat: add lucide_icons_flutter and expand ThemeConstants tokens"
  ```

---

### Task 2: Instant route transitions

**Files:**
- Modify: `lib/router/app_router.dart`

- [ ] **Step 1: Replace all `builder:` with `pageBuilder:` using `NoTransitionPage`**

  Replace the entire content of `lib/router/app_router.dart` with:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:go_router/go_router.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../data/datasources/local/onboarding_preferences.dart';
  import '../features/chat/chat_screen.dart';
  import '../features/onboarding/onboarding_screen.dart';
  import '../features/settings/settings_screen.dart';
  import '../shell/chat_shell.dart';

  part 'app_router.g.dart';

  @Riverpod(keepAlive: true)
  GoRouter appRouter(Ref ref) {
    return GoRouter(
      initialLocation: '/chat',
      redirect: (context, state) async {
        final prefs = ref.read(onboardingPreferencesProvider);
        final done = await prefs.isCompleted();
        if (!done && state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: OnboardingScreen()),
        ),
        ShellRoute(
          builder: (context, state, child) => ChatShell(child: child),
          routes: [
            GoRoute(
              path: '/chat',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ChatScreen()),
            ),
            GoRoute(
              path: '/chat/:sessionId',
              pageBuilder: (context, state) => NoTransitionPage(
                child: ChatScreen(
                  sessionId: state.pathParameters['sessionId'],
                ),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
            ),
          ],
        ),
      ],
    );
  }
  ```

- [ ] **Step 2: Run analyze**

  ```bash
  flutter analyze
  ```
  Expected: no errors.

- [ ] **Step 3: Commit**

  ```bash
  git add lib/router/app_router.dart
  git commit -m "feat: disable route transition animations (NoTransitionPage)"
  ```

---

### Task 3: Message bubble redesign

**Files:**
- Modify: `lib/features/chat/widgets/message_bubble.dart`

- [ ] **Step 1: Write the widget test**

  Create `test/features/chat/widgets/message_bubble_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/data/models/chat_message.dart';
  import 'package:code_bench_app/features/chat/widgets/message_bubble.dart';

  Widget _wrap(Widget child) => ProviderScope(
        child: MaterialApp(home: Scaffold(body: child)),
      );

  ChatMessage _msg(MessageRole role, {bool streaming = false}) => ChatMessage(
        id: 'id',
        sessionId: 'sid',
        role: role,
        content: 'Hello world',
        timestamp: DateTime.now(),
        isStreaming: streaming,
      );

  void main() {
    testWidgets('user message is right-aligned', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(message: _msg(MessageRole.user))));
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('assistant message has no background container', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(message: _msg(MessageRole.assistant))));
      // No avatar icon
      expect(find.byIcon(Icons.smart_toy), findsNothing);
      // No role label text
      expect(find.text('Assistant'), findsNothing);
    });

    testWidgets('streaming shows pulsing dot, not CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        _wrap(MessageBubble(message: _msg(MessageRole.assistant, streaming: true))),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(StreamingDot), findsOneWidget);
    });
  }
  ```

- [ ] **Step 2: Run the test to confirm it fails**

  ```bash
  flutter test test/features/chat/widgets/message_bubble_test.dart
  ```
  Expected: FAIL — tests reference `StreamingDot` which doesn't exist yet, and current layout has avatars.

- [ ] **Step 3: Rewrite `message_bubble.dart`**

  Replace the full file with:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_highlight/flutter_highlight.dart';
  import 'package:flutter_highlight/themes/vs2015.dart';
  import 'package:flutter_markdown/flutter_markdown.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/chat_message.dart';
  import 'apply_code_dialog.dart';

  class MessageBubble extends ConsumerWidget {
    const MessageBubble({super.key, required this.message});

    final ChatMessage message;

    bool get _isUser => message.role == MessageRole.user;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _isUser ? _UserBubble(message: message) : _AssistantBubble(message: message, ref: ref),
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
          // Left accent border
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

  // ── Message content (shared markdown renderer) ───────────────────────────────

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
          blockquote: const TextStyle(color: ThemeConstants.textSecondary),
          listBullet: const TextStyle(color: ThemeConstants.textPrimary),
        ),
        builders: {'code': _CodeBlockBuilder(ref: ref)},
      );
    }
  }

  // ── Code block builder ───────────────────────────────────────────────────────

  class _CodeBlockBuilder extends MarkdownElementBuilder {
    _CodeBlockBuilder({required this.ref});
    final WidgetRef ref;

    @override
    Widget? visitElementAfter(element, TextStyle? preferredStyle) {
      final language =
          element.attributes['class']?.replaceFirst('language-', '') ?? 'plaintext';
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
      return _CodeBlockWidget(code: code, language: language, ref: ref);
    }
  }

  class _CodeBlockWidget extends StatefulWidget {
    const _CodeBlockWidget({required this.code, required this.language, required this.ref});
    final String code;
    final String language;
    final WidgetRef ref;

    @override
    State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
  }

  class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
    bool _applying = false;

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
            Container(
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
                  const Spacer(),
                  GestureDetector(
                    onTap: _applying
                        ? null
                        : () async {
                            setState(() => _applying = true);
                            try {
                              await showApplyCodeDialog(
                                context, widget.ref, widget.code, widget.language,
                              );
                            } finally {
                              if (mounted) setState(() => _applying = false);
                            }
                          },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _applying ? LucideIcons.hourglass : LucideIcons.download,
                          size: 12,
                          color: ThemeConstants.mutedFg,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _applying ? 'Applying...' : 'Apply',
                          style: const TextStyle(
                            color: ThemeConstants.mutedFg,
                            fontSize: ThemeConstants.uiFontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CopyButton(code: widget.code),
                ],
              ),
            ),
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
  }

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

- [ ] **Step 4: Run the tests**

  ```bash
  flutter test test/features/chat/widgets/message_bubble_test.dart
  ```
  Expected: all 3 tests PASS.

- [ ] **Step 5: Analyze**

  ```bash
  flutter analyze
  ```
  Expected: no errors.

- [ ] **Step 6: Commit**

  ```bash
  git add lib/features/chat/widgets/message_bubble.dart test/features/chat/widgets/message_bubble_test.dart
  git commit -m "feat: redesign message bubble — right-align user, flat assistant, pulsing dot"
  ```

---

### Task 4: Input bar — functional chip dropdowns + fix model picker

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar_v2.dart`

- [ ] **Step 1: Write the test**

  Create `test/features/chat/widgets/chat_input_bar_v2_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench_app/features/chat/widgets/chat_input_bar_v2.dart';

  Widget _wrap(Widget child) => ProviderScope(
        child: MaterialApp(home: Scaffold(body: child)),
      );

  void main() {
    testWidgets('effort chip shows current selection', (tester) async {
      await tester.pumpWidget(_wrap(const ChatInputBarV2(sessionId: 'sid')));
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('tapping effort chip opens dropdown with all options', (tester) async {
      await tester.pumpWidget(_wrap(const ChatInputBarV2(sessionId: 'sid')));
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);
    });

    testWidgets('selecting effort option updates the chip label', (tester) async {
      await tester.pumpWidget(_wrap(const ChatInputBarV2(sessionId: 'sid')));
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Low'));
      await tester.pumpAndSettle();
      expect(find.text('Low'), findsOneWidget);
    });
  }
  ```

- [ ] **Step 2: Run the test to confirm it fails**

  ```bash
  flutter test test/features/chat/widgets/chat_input_bar_v2_test.dart
  ```
  Expected: FAIL — dropdown doesn't open yet.

- [ ] **Step 3: Update `chat_input_bar_v2.dart`**

  Replace the full file with:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/ai_model.dart';
  import '../chat_notifier.dart';

  enum _Effort { low, medium, high, max }
  enum _Mode { chat, plan, act }
  enum _Permission { readOnly, askBefore, fullAccess }

  extension _EffortLabel on _Effort {
    String get label => switch (this) {
          _Effort.low => 'Low',
          _Effort.medium => 'Medium',
          _Effort.high => 'High',
          _Effort.max => 'Max',
        };
  }

  extension _ModeLabel on _Mode {
    String get label => switch (this) {
          _Mode.chat => 'Chat',
          _Mode.plan => 'Plan',
          _Mode.act => 'Act',
        };
  }

  extension _PermissionLabel on _Permission {
    String get label => switch (this) {
          _Permission.readOnly => 'Read only',
          _Permission.askBefore => 'Ask before changes',
          _Permission.fullAccess => 'Full access',
        };
  }

  class ChatInputBarV2 extends ConsumerStatefulWidget {
    const ChatInputBarV2({super.key, required this.sessionId});
    final String sessionId;

    @override
    ConsumerState<ChatInputBarV2> createState() => _ChatInputBarV2State();
  }

  class _ChatInputBarV2State extends ConsumerState<ChatInputBarV2> {
    final _controller = TextEditingController();
    final _focusNode = FocusNode();
    bool _isSending = false;
    _Effort _effort = _Effort.high;
    _Mode _mode = _Mode.chat;
    _Permission _permission = _Permission.fullAccess;

    @override
    void dispose() {
      _controller.dispose();
      _focusNode.dispose();
      super.dispose();
    }

    Future<void> _send() async {
      final text = _controller.text.trim();
      if (text.isEmpty || _isSending) return;
      _controller.clear();
      setState(() => _isSending = true);
      try {
        final systemPrompt = ref.read(sessionSystemPromptProvider)[widget.sessionId];
        await ref.read(chatMessagesProvider(widget.sessionId).notifier).sendMessage(
              text,
              systemPrompt: (systemPrompt != null && systemPrompt.isNotEmpty) ? systemPrompt : null,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: ThemeConstants.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isSending = false);
        _focusNode.requestFocus();
      }
    }

    void _showDropdown<T>(
      BuildContext context,
      List<T> items,
      T selected,
      String Function(T) label,
      void Function(T) onSelect,
    ) {
      final box = context.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;
      showMenu<T>(
        context: context,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy + size.height + 4,
          offset.dx + size.width,
          0,
        ),
        color: ThemeConstants.panelBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
        items: items.map((item) => PopupMenuItem<T>(
          value: item,
          height: 32,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label(item),
                  style: TextStyle(
                    color: item == selected
                        ? ThemeConstants.textPrimary
                        : ThemeConstants.textSecondary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                ),
              ),
              if (item == selected)
                const Icon(LucideIcons.check, size: 11, color: ThemeConstants.accent),
            ],
          ),
        )).toList(),
      ).then((value) {
        if (value != null) onSelect(value);
      });
    }

    void _showModelPicker(BuildContext context) {
      final models = AIModels.defaults;
      final selected = ref.read(selectedModelProvider);
      final box = context.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;
      showMenu<AIModel>(
        context: context,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy + size.height + 4,
          offset.dx + size.width,
          0,
        ),
        color: ThemeConstants.panelBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
        items: models.map((m) => PopupMenuItem<AIModel>(
          value: m,
          height: 32,
          child: Text(
            '${m.provider.displayName} / ${m.name}',
            style: TextStyle(
              color: m == selected ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
              fontSize: ThemeConstants.uiFontSizeSmall,
            ),
          ),
        )).toList(),
      ).then((value) {
        if (value != null) ref.read(selectedModelProvider.notifier).select(value);
      });
    }

    @override
    Widget build(BuildContext context) {
      final model = ref.watch(selectedModelProvider);
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: ThemeConstants.deepBorder)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: ThemeConstants.inputSurface,
            border: Border.all(color: ThemeConstants.deepBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    _send();
                  }
                },
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  minLines: 1,
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: ThemeConstants.uiFontSize,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ask anything, @tag files/folders, or use /command',
                    hintStyle: TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSize),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(top: 7),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: ThemeConstants.deepBorder)),
                ),
                child: Row(
                  children: [
                    Builder(
                      builder: (ctx) => _ControlChip(
                        icon: LucideIcons.zap,
                        label: model.name,
                        onTap: () => _showModelPicker(ctx),
                      ),
                    ),
                    const _Separator(),
                    Builder(
                      builder: (ctx) => _ControlChip(
                        label: _effort.label,
                        onTap: () => _showDropdown(
                          ctx,
                          _Effort.values,
                          _effort,
                          (e) => e.label,
                          (e) => setState(() => _effort = e),
                        ),
                      ),
                    ),
                    const _Separator(),
                    Builder(
                      builder: (ctx) => _ControlChip(
                        icon: LucideIcons.messageSquare,
                        label: _mode.label,
                        onTap: () => _showDropdown(
                          ctx,
                          _Mode.values,
                          _mode,
                          (m) => m.label,
                          (m) => setState(() => _mode = m),
                        ),
                      ),
                    ),
                    const _Separator(),
                    Builder(
                      builder: (ctx) => _ControlChip(
                        icon: LucideIcons.lock,
                        label: _permission.label,
                        onTap: () => _showDropdown(
                          ctx,
                          _Permission.values,
                          _permission,
                          (p) => p.label,
                          (p) => setState(() => _permission = p),
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _isSending ? null : _send,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: ThemeConstants.accent,
                          shape: BoxShape.circle,
                        ),
                        child: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(LucideIcons.arrowUp, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  class _ControlChip extends StatelessWidget {
    const _ControlChip({this.icon, required this.label, required this.onTap});
    final IconData? icon;
    final String label;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 11, color: ThemeConstants.textSecondary),
                const SizedBox(width: 4),
              ],
              Text(label, style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall)),
              const SizedBox(width: 3),
              const Icon(LucideIcons.chevronDown, size: 10, color: ThemeConstants.faintFg),
            ],
          ),
        ),
      );
    }
  }

  class _Separator extends StatelessWidget {
    const _Separator();

    @override
    Widget build(BuildContext context) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 1),
        child: Text('|', style: TextStyle(color: ThemeConstants.deepBorder, fontSize: ThemeConstants.uiFontSizeSmall)),
      );
    }
  }
  ```

- [ ] **Step 4: Run the tests**

  ```bash
  flutter test test/features/chat/widgets/chat_input_bar_v2_test.dart
  ```
  Expected: all 3 tests PASS.

- [ ] **Step 5: Analyze**

  ```bash
  flutter analyze
  ```
  Expected: no errors.

- [ ] **Step 6: Commit**

  ```bash
  git add lib/features/chat/widgets/chat_input_bar_v2.dart test/features/chat/widgets/chat_input_bar_v2_test.dart
  git commit -m "feat: add functional chip dropdowns to input bar (Effort/Mode/Permissions)"
  ```

---

### Task 5: Project sidebar sort notifier

**Files:**
- Modify: `lib/features/project_sidebar/project_sidebar_notifier.dart`

- [ ] **Step 1: Write the test**

  Create `test/features/project_sidebar/project_sidebar_sort_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:code_bench_app/features/project_sidebar/project_sidebar_notifier.dart';

  void main() {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default sort orders are lastMessage', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = await container.read(projectSortProvider.future);
      expect(state.projectSort, ProjectSortOrder.lastMessage);
      expect(state.threadSort, ThreadSortOrder.lastMessage);
    });

    test('setProjectSort persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(projectSortProvider.notifier).setProjectSort(ProjectSortOrder.createdAt);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('project_sort_order'), 'createdAt');
    });

    test('setThreadSort updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(projectSortProvider.notifier).setThreadSort(ThreadSortOrder.createdAt);
      final state = await container.read(projectSortProvider.future);
      expect(state.threadSort, ThreadSortOrder.createdAt);
    });
  }
  ```

- [ ] **Step 2: Run to confirm FAIL**

  ```bash
  flutter test test/features/project_sidebar/project_sidebar_sort_test.dart
  ```
  Expected: FAIL — `projectSortProvider` doesn't exist.

- [ ] **Step 3: Add sort state to `project_sidebar_notifier.dart`**

  Add at the top of the file, after imports:
  ```dart
  import 'package:shared_preferences/shared_preferences.dart';
  ```

  Add these classes and enum definitions after the existing `ExpandedProjectIds` notifier:
  ```dart
  enum ProjectSortOrder { lastMessage, createdAt, manual }
  enum ThreadSortOrder { lastMessage, createdAt }

  class ProjectSortState {
    const ProjectSortState({required this.projectSort, required this.threadSort});
    final ProjectSortOrder projectSort;
    final ThreadSortOrder threadSort;
    ProjectSortState copyWith({ProjectSortOrder? projectSort, ThreadSortOrder? threadSort}) =>
        ProjectSortState(
          projectSort: projectSort ?? this.projectSort,
          threadSort: threadSort ?? this.threadSort,
        );
  }

  @Riverpod(keepAlive: true)
  class ProjectSort extends _$ProjectSort {
    static const _projectKey = 'project_sort_order';
    static const _threadKey = 'thread_sort_order';

    @override
    Future<ProjectSortState> build() async {
      final prefs = await SharedPreferences.getInstance();
      final projectSort = ProjectSortOrder.values.firstWhere(
        (e) => e.name == prefs.getString(_projectKey),
        orElse: () => ProjectSortOrder.lastMessage,
      );
      final threadSort = ThreadSortOrder.values.firstWhere(
        (e) => e.name == prefs.getString(_threadKey),
        orElse: () => ThreadSortOrder.lastMessage,
      );
      return ProjectSortState(projectSort: projectSort, threadSort: threadSort);
    }

    Future<void> setProjectSort(ProjectSortOrder order) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_projectKey, order.name);
      state = AsyncData((await future).copyWith(projectSort: order));
    }

    Future<void> setThreadSort(ThreadSortOrder order) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_threadKey, order.name);
      state = AsyncData((await future).copyWith(threadSort: order));
    }
  }
  ```

- [ ] **Step 4: Run build_runner to regenerate `.g.dart`**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Expected: exits cleanly, `project_sidebar_notifier.g.dart` updated.

- [ ] **Step 5: Run the tests**

  ```bash
  flutter test test/features/project_sidebar/project_sidebar_sort_test.dart
  ```
  Expected: all 3 tests PASS.

- [ ] **Step 6: Analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 7: Commit**

  ```bash
  git add lib/features/project_sidebar/project_sidebar_notifier.dart \
          lib/features/project_sidebar/project_sidebar_notifier.g.dart \
          test/features/project_sidebar/project_sidebar_sort_test.dart
  git commit -m "feat: add ProjectSortNotifier with SharedPreferences persistence"
  ```

---

### Task 6: Project tile — Lucide icons + icon-only git badge + hover new-chat

**Files:**
- Modify: `lib/features/project_sidebar/widgets/project_tile.dart`

- [ ] **Step 1: Replace `project_tile.dart`**

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../../core/constants/theme_constants.dart';
  import '../../../data/models/chat_session.dart';
  import '../../../data/models/project.dart';
  import 'conversation_tile.dart';
  import 'project_context_menu.dart';

  class ProjectTile extends ConsumerStatefulWidget {
    const ProjectTile({
      super.key,
      required this.project,
      required this.sessions,
      required this.isExpanded,
      required this.activeSessionId,
      required this.onToggleExpand,
      required this.onSessionTap,
      required this.onRemove,
      required this.onRename,
      required this.onNewConversation,
    });

    final Project project;
    final List<ChatSession> sessions;
    final bool isExpanded;
    final String? activeSessionId;
    final VoidCallback onToggleExpand;
    final ValueChanged<String> onSessionTap;
    final ValueChanged<String> onRemove;
    final ValueChanged<String> onRename;
    final ValueChanged<String> onNewConversation;

    @override
    ConsumerState<ProjectTile> createState() => _ProjectTileState();
  }

  class _ProjectTileState extends ConsumerState<ProjectTile> {
    bool _hovered = false;

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onSecondaryTapUp: (details) async {
              final action = await ProjectContextMenu.show(
                context: context,
                position: details.globalPosition,
                projectPath: widget.project.path,
                isGit: widget.project.isGit,
              );
              if (action != null && context.mounted) {
                await ProjectContextMenu.handleAction(
                  action: action,
                  projectId: widget.project.id,
                  projectPath: widget.project.path,
                  context: context,
                  onRemove: widget.onRemove,
                  onRename: widget.onRename,
                  onNewConversation: widget.onNewConversation,
                );
              }
            },
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: InkWell(
                onTap: widget.onToggleExpand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      // Chevron
                      Icon(
                        widget.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                        size: 14,
                        color: ThemeConstants.faintFg,
                      ),
                      const SizedBox(width: 4),
                      // Folder icon
                      Icon(LucideIcons.folder, size: 13, color: ThemeConstants.textSecondary),
                      const SizedBox(width: 6),
                      // Project name
                      Expanded(
                        child: Text(
                          widget.project.name,
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: ThemeConstants.uiFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // New-chat icon (hover only)
                      AnimatedOpacity(
                        opacity: _hovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 120),
                        child: InkWell(
                          onTap: () => widget.onNewConversation(widget.project.id),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              LucideIcons.messagePlusSquare,
                              size: 13,
                              color: ThemeConstants.mutedFg,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Git icon (icon only, no pill)
                      Tooltip(
                        message: widget.project.isGit
                            ? (widget.project.currentBranch ?? 'git')
                            : '',
                        child: Icon(
                          LucideIcons.gitBranch,
                          size: 13,
                          color: widget.project.isGit
                              ? ThemeConstants.success
                              : ThemeConstants.faintFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.isExpanded && widget.sessions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 10, bottom: 6),
              child: Column(
                children: widget.sessions
                    .map((s) => ConversationTile(
                          session: s,
                          isActive: s.sessionId == widget.activeSessionId,
                          onTap: () => widget.onSessionTap(s.sessionId),
                        ))
                    .toList(),
              ),
            ),
        ],
      );
    }
  }
  ```

- [ ] **Step 2: Analyze**

  ```bash
  flutter analyze
  ```
  Expected: no errors. (Note: `LucideIcons.messagePlusSquare` — verify the exact icon name in the package; alternative: `LucideIcons.squarePen`.)

- [ ] **Step 3: Commit**

  ```bash
  git add lib/features/project_sidebar/widgets/project_tile.dart
  git commit -m "feat: project tile — Lucide icons, icon-only git badge, hover new-chat button"
  ```

---

### Task 7: Project sidebar — sort dropdown + header polish

**Files:**
- Modify: `lib/features/project_sidebar/project_sidebar.dart`
- Modify: `lib/features/project_sidebar/widgets/conversation_tile.dart`

- [ ] **Step 1: Update `conversation_tile.dart` — font size to 11px + Lucide icons**

  In `lib/features/project_sidebar/widgets/conversation_tile.dart`, find every `fontSize: 12` and change to `fontSize: ThemeConstants.uiFontSizeSmall`. Find `Icons.*` and replace with `LucideIcons.*` equivalents. (Read the file first to see what icons are used.)

  Read the file:
  ```bash
  # in the editor, read lib/features/project_sidebar/widgets/conversation_tile.dart
  ```

- [ ] **Step 2: Update `project_sidebar.dart` — add sort icon, sort dropdown**

  Replace the `Container` header section (lines 57–87) with:
  ```dart
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
    ),
    child: Row(
      children: [
        const Text(
          'PROJECTS',
          style: TextStyle(
            color: ThemeConstants.mutedFg,
            fontSize: ThemeConstants.uiFontSizeLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        // Sort icon
        Builder(
          builder: (ctx) => InkWell(
            onTap: () => _showSortMenu(ctx, ref),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(LucideIcons.arrowUpDown, size: 13, color: ThemeConstants.mutedFg),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Add project icon
        InkWell(
          onTap: () => _addProject(context, ref),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Icon(LucideIcons.plus, size: 13, color: ThemeConstants.mutedFg),
          ),
        ),
      ],
    ),
  ),
  ```

  Add the `_showSortMenu` method to `ProjectSidebar`:
  ```dart
  void _showSortMenu(BuildContext context, WidgetRef ref) {
    final sortAsync = ref.read(projectSortProvider);
    final current = sortAsync.valueOrNull;
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        0,
      ),
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      items: [
        _sortHeader('SORT PROJECTS'),
        _sortItem('proj_lastMessage', 'Last user message',
            current?.projectSort == ProjectSortOrder.lastMessage),
        _sortItem('proj_createdAt', 'Created at',
            current?.projectSort == ProjectSortOrder.createdAt),
        _sortItem('proj_manual', 'Manual',
            current?.projectSort == ProjectSortOrder.manual),
        const PopupMenuDivider(),
        _sortHeader('SORT THREADS'),
        _sortItem('thread_lastMessage', 'Last user message',
            current?.threadSort == ThreadSortOrder.lastMessage),
        _sortItem('thread_createdAt', 'Created at',
            current?.threadSort == ThreadSortOrder.createdAt),
      ],
    ).then((value) {
      if (value == null) return;
      final notifier = ref.read(projectSortProvider.notifier);
      switch (value) {
        case 'proj_lastMessage':
          notifier.setProjectSort(ProjectSortOrder.lastMessage);
        case 'proj_createdAt':
          notifier.setProjectSort(ProjectSortOrder.createdAt);
        case 'proj_manual':
          notifier.setProjectSort(ProjectSortOrder.manual);
        case 'thread_lastMessage':
          notifier.setThreadSort(ThreadSortOrder.lastMessage);
        case 'thread_createdAt':
          notifier.setThreadSort(ThreadSortOrder.createdAt);
      }
    });
  }

  PopupMenuItem<String> _sortHeader(String label) => PopupMenuItem<String>(
        enabled: false,
        height: 24,
        child: Text(
          label,
          style: const TextStyle(
            color: ThemeConstants.mutedFg,
            fontSize: ThemeConstants.uiFontSizeLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      );

  PopupMenuItem<String> _sortItem(String value, String label, bool selected) =>
      PopupMenuItem<String>(
        value: value,
        height: 32,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
              ),
            ),
            if (selected)
              const Icon(LucideIcons.check, size: 11, color: ThemeConstants.accent),
          ],
        ),
      );
  ```

  Also add required imports at top of file:
  ```dart
  import 'package:lucide_icons_flutter/lucide_icons.dart';
  import 'project_sidebar_notifier.dart'; // already there
  ```

- [ ] **Step 3: Analyze**

  ```bash
  flutter analyze
  ```
  Expected: no errors.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/project_sidebar/project_sidebar.dart \
          lib/features/project_sidebar/widgets/conversation_tile.dart
  git commit -m "feat: sidebar sort dropdown with SharedPreferences persistence"
  ```

---

### Task 8: Top action bar — new layout (stubs)

**Files:**
- Modify: `lib/shell/widgets/top_action_bar.dart`

- [ ] **Step 1: Replace `top_action_bar.dart`**

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../core/constants/theme_constants.dart';
  import '../../data/models/chat_session.dart';
  import '../../data/models/project.dart';
  import '../../features/chat/chat_notifier.dart';
  import '../../features/project_sidebar/project_sidebar_notifier.dart';

  class TopActionBar extends ConsumerWidget {
    const TopActionBar({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final sessionId = ref.watch(activeSessionIdProvider);
      final projectId = ref.watch(activeProjectIdProvider);
      final sessionsAsync = ref.watch(chatSessionsProvider);
      final projectsAsync = ref.watch(projectsProvider);

      final sessionTitle = sessionsAsync.whenOrNull(
            data: (List<ChatSession> list) {
              if (sessionId == null) return 'Code Bench';
              try {
                return list.firstWhere((s) => s.sessionId == sessionId).title;
              } catch (_) {
                return 'New Chat';
              }
            },
          ) ??
          'Code Bench';

      final project = projectsAsync.whenOrNull(
        data: (List<Project> list) {
          if (projectId == null) return null;
          try {
            return list.firstWhere((p) => p.id == projectId);
          } catch (_) {
            return null;
          }
        },
      );

      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: ThemeConstants.inputBackground,
          border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
        ),
        child: Row(
          children: [
            // ── Left: title + badges ──────────────────────────────────────────
            Text(
              sessionTitle,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: ThemeConstants.uiFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (project != null) ...[
              const SizedBox(width: 8),
              // Project name badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ThemeConstants.inputSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  project.name,
                  style: const TextStyle(
                    color: ThemeConstants.mutedFg,
                    fontSize: ThemeConstants.uiFontSizeLabel,
                  ),
                ),
              ),
              // No Git badge (only when not a git repo)
              if (!project.isGit) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1F0A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'No Git',
                    style: TextStyle(
                      color: Color(0xFFE8A228),
                      fontSize: ThemeConstants.uiFontSizeLabel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
            const Spacer(),
            // ── Right: action buttons ─────────────────────────────────────────
            _ActionButton(
              icon: LucideIcons.plus,
              label: 'Add action',
              onTap: () {}, // wired in Phase 3
            ),
            const SizedBox(width: 5),
            _VsCodeDropdown(), // VS Code / Cursor / Finder / Terminal (stubs)
            const SizedBox(width: 5),
            // Git action: Commit & Push (git) or Initialize Git (no git)
            if (project != null && project.isGit)
              _CommitPushButton(onCommit: () {}, onDropdown: () {})
            else if (project != null && !project.isGit)
              _ActionButton(
                icon: LucideIcons.gitMerge,
                label: 'Initialize Git',
                onTap: () {}, // wired in Phase 3
              ),
          ],
        ),
      );
    }
  }

  // ── VS Code dropdown ─────────────────────────────────────────────────────────

  class _VsCodeDropdown extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return _ActionButton(
        icon: LucideIcons.code2,
        label: 'VS Code',
        trailingCaret: true,
        onTap: () {
          // Stub — wired in Phase 3
        },
      );
    }
  }

  // ── Commit & Push split button ───────────────────────────────────────────────

  class _CommitPushButton extends StatelessWidget {
    const _CommitPushButton({required this.onCommit, required this.onDropdown});
    final VoidCallback onCommit;
    final VoidCallback onDropdown;

    @override
    Widget build(BuildContext context) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left: Commit & Push
          GestureDetector(
            onTap: onCommit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeConstants.accent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.gitCommit, size: 12, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Commit & Push',
                    style: TextStyle(color: Colors.white, fontSize: ThemeConstants.uiFontSizeSmall),
                  ),
                ],
              ),
            ),
          ),
          // Right: dropdown caret
          GestureDetector(
            onTap: onDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeConstants.accentLight,
                border: const Border(left: BorderSide(color: ThemeConstants.accentDark)),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
              ),
              child: const Icon(LucideIcons.chevronDown, size: 11, color: Colors.white),
            ),
          ),
        ],
      );
    }
  }

  // ── Shared action button ─────────────────────────────────────────────────────

  class _ActionButton extends StatelessWidget {
    const _ActionButton({
      required this.icon,
      required this.label,
      required this.onTap,
      this.isPrimary = false,
      this.trailingCaret = false,
    });

    final IconData icon;
    final String label;
    final VoidCallback onTap;
    final bool isPrimary;
    final bool trailingCaret;

    @override
    Widget build(BuildContext context) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isPrimary ? ThemeConstants.accent : ThemeConstants.inputSurface,
            border: Border.all(
              color: isPrimary ? ThemeConstants.accent : ThemeConstants.deepBorder,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: isPrimary ? Colors.white : ThemeConstants.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : ThemeConstants.textSecondary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
              ),
              if (trailingCaret) ...[
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronDown, size: 10, color: ThemeConstants.faintFg),
              ],
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 2: Analyze**

  ```bash
  flutter analyze
  ```
  Expected: no errors.

- [ ] **Step 3: Commit**

  ```bash
  git add lib/shell/widgets/top_action_bar.dart
  git commit -m "feat: top action bar new layout — stubs for Add action, VS Code dropdown, Commit & Push split button, No Git badge"
  ```

---

### Task 9: Status bar Lucide sweep + full analyze + test run

**Files:**
- Modify: `lib/shell/widgets/status_bar.dart`

- [ ] **Step 1: Read and update `status_bar.dart`**

  Read `lib/shell/widgets/status_bar.dart`, replace any `Icons.*` with `LucideIcons.*` equivalents, and replace any raw `Color(0xFF...)` literals with the appropriate `ThemeConstants` token.

- [ ] **Step 2: Full test run**

  ```bash
  flutter test
  ```
  Expected: all tests pass.

- [ ] **Step 3: Full analyze**

  ```bash
  flutter analyze
  ```
  Expected: no issues.

- [ ] **Step 4: Format**

  ```bash
  dart format lib/ test/
  ```

- [ ] **Step 5: Final commit**

  ```bash
  git add lib/shell/widgets/status_bar.dart
  git commit -m "feat: Phase 1a complete — Lucide icons, color tokens, typography, message bubble, dropdowns, sidebar sort, top bar"
  ```

---

## Checklist: Spec Coverage

- [x] Icon library (`lucide_icons_flutter`) — Task 1
- [x] Color tokens (`inputSurface`, `deepBorder`, `mutedFg`, `faintFg`) — Task 1
- [x] Typography scale (`uiFontSize=12`, `uiFontSizeLabel=10`, `uiFontSizeBadge=9`) — Task 1
- [x] Route transitions (instant, no slide) — Task 2
- [x] Message layout (right-align user, flat assistant, no avatars, pulsing dot) — Task 3
- [x] Input bar chip dropdowns (Effort/Mode/Permissions) + model picker anchor fix — Task 4
- [x] Sidebar sort dropdown with persistence — Tasks 5 + 7
- [x] Project tile Lucide icons + icon-only git badge + hover new-chat — Task 6
- [x] Conversation tile font 11px — Task 7
- [x] Top action bar layout (Add action stub, VS Code stub, Commit & Push split, No Git badge) — Task 8
- [x] Status bar token cleanup — Task 9
