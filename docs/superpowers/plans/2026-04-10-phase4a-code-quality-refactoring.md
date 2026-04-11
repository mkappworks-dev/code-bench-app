# Phase 4a — Code Quality Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve code quality across four axes — guarded debug logging, swappable icon constants, friendly UI error messages, and a reusable snackbar helper.

**Architecture:** Each task is isolated and produces a clean commit. Tasks 1–2 lay groundwork that Tasks 3–4 build on: the `dLog` helper is used in Task 4's updated catch blocks; `AppIcons` is used whenever Task 3/4 replace raw widget code.

**Tech Stack:** Flutter/Dart, `flutter/foundation.dart` (`kDebugMode`), `lucide_icons_flutter`, `flutter_riverpod`, `flutter_test`

---

## Files: Created / Modified

### Task 1 — debugPrint helper
- **Create:** `lib/core/utils/debug_logger.dart`
- **Modify:** `lib/main.dart`
- **Modify:** `lib/shell/chat_shell.dart`
- **Modify:** `lib/features/chat/chat_notifier.dart`
- **Modify:** `lib/features/chat/widgets/changes_panel.dart`
- **Modify:** `lib/features/chat/widgets/message_bubble.dart`

### Task 2 — Icon constants
- **Create:** `lib/core/constants/app_icons.dart`
- **Modify (remove lucide import, use AppIcons):**
  - `lib/shell/widgets/top_action_bar.dart`
  - `lib/shell/widgets/status_bar.dart`
  - `lib/features/settings/settings_screen.dart`
  - `lib/features/settings/archive_screen.dart`
  - `lib/features/chat/widgets/chat_input_bar_v2.dart`
  - `lib/features/chat/widgets/changes_panel.dart`
  - `lib/features/chat/widgets/message_bubble.dart`
  - `lib/features/project_sidebar/project_sidebar.dart`
  - `lib/features/project_sidebar/widgets/project_tile.dart`
  - `lib/features/project_sidebar/widgets/conversation_tile.dart`

### Task 3 — Friendly UI error messages
- **Modify:** `lib/features/settings/archive_screen.dart`
- **Modify:** `lib/features/chat/widgets/chat_input_bar_v2.dart`
- **Modify:** `lib/features/chat/widgets/changes_panel.dart`
- **Modify:** `lib/features/chat/widgets/message_list.dart`
- **Modify:** `lib/shared/widgets/error_boundary.dart`

### Task 4 — showErrorSnackBar helper + cleanup
- **Create:** `lib/core/utils/snackbar_helper.dart`
- **Modify:** `lib/features/chat/widgets/chat_input_bar_v2.dart`
- **Modify:** `lib/features/chat/widgets/changes_panel.dart`
- **Modify:** `lib/shared/widgets/error_boundary.dart`
- **Test:** `test/core/utils/snackbar_helper_test.dart`

---

## Task 1: guarded debugPrint → dLog helper

**Goal:** All debug logging is wrapped in `kDebugMode` so it is stripped in release builds. One function, one import.

**Files:**
- Create: `lib/core/utils/debug_logger.dart`
- Modify: 6 files listed above

- [ ] **Step 1: Create the helper**

```dart
// lib/core/utils/debug_logger.dart
import 'package:flutter/foundation.dart';

/// Debug-only logger. Stripped from release builds.
/// Usage: dLog('[Tag] message: $e\n$st');
void dLog(String message) {
  if (kDebugMode) debugPrint(message);
}
```

- [ ] **Step 2: Replace in `lib/main.dart`**

Old (lines 19–21):
```dart
if (kDebugMode) {
  debugPrint('[FlutterError] ${details.exceptionAsString()}');
}
```

New (remove the `if` block, import `dLog`):
```dart
import 'core/utils/debug_logger.dart';

// inside FlutterError.onError:
dLog('[FlutterError] ${details.exceptionAsString()}');
```

- [ ] **Step 3: Replace in `lib/shell/chat_shell.dart`**

Find lines 43 and 47:
```dart
debugPrint('[_newChat] error: $e\n$st');
```

Replace both with:
```dart
dLog('[_newChat] error: $e\n$st');
```

Add import at top:
```dart
import '../core/utils/debug_logger.dart';
```

- [ ] **Step 4: Replace in `lib/features/chat/chat_notifier.dart` (line 84)**

```dart
// before
debugPrint('[sendMessage] stream error: $e\n$st');
// after
dLog('[sendMessage] stream error: $e\n$st');
```

Add import:
```dart
import '../../core/utils/debug_logger.dart';
```

- [ ] **Step 5: Replace in `lib/features/chat/widgets/changes_panel.dart` (lines 224, 234)**

```dart
// before
debugPrint('[revert] state error: $e');
debugPrint('[revert] error: $e\n$st');
// after
dLog('[revert] state error: $e');
dLog('[revert] error: $e\n$st');
```

Add import:
```dart
import '../../../core/utils/debug_logger.dart';
```

- [ ] **Step 6: Replace in `lib/features/chat/widgets/message_bubble.dart` (lines 378, 385, 392, 425, 428, 431, 753)**

```dart
// all occurrences of debugPrint → dLog
dLog('[security] _loadDiff path rejected: $e');
dLog('[_loadDiff] filesystem: $e');
dLog('[_loadDiff] unexpected: $e\n$st');
dLog('[security] _applyChange path rejected: $e');
dLog('[_applyChange] filesystem: $e');
dLog('[_applyChange] unexpected: $e\n$st');
dLog('[clipboard] copy failed: $e');
```

Add import:
```dart
import '../../../core/utils/debug_logger.dart';
```

- [ ] **Step 7: Verify — no bare `debugPrint` remains in lib/ (except where intentional)**

Run:
```bash
grep -rn "debugPrint" lib/ --include="*.dart"
```

Expected: only `lib/core/utils/debug_logger.dart` (the definition) and `lib/main.dart` (the `FlutterError.onError` handler, now replaced).
The grep result should show zero remaining unguarded `debugPrint` calls in source files.

- [ ] **Step 8: Analyze and format**

```bash
dart format lib/core/utils/debug_logger.dart lib/main.dart lib/shell/chat_shell.dart lib/features/chat/chat_notifier.dart lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/message_bubble.dart
flutter analyze
```

Expected: no issues.

- [ ] **Step 9: Commit**

```bash
git add lib/core/utils/debug_logger.dart lib/main.dart lib/shell/chat_shell.dart lib/features/chat/chat_notifier.dart lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/message_bubble.dart
git commit -m "refactor: replace bare debugPrint with guarded dLog helper"
```

---

## Task 2: Icon constants file (AppIcons)

**Goal:** All `LucideIcons.*` references go through `AppIcons`, so swapping the icon package later only requires changing one file.

**Files:**
- Create: `lib/core/constants/app_icons.dart`
- Modify: 10 feature/widget files (remove lucide import, add AppIcons import)

- [ ] **Step 1: Create `lib/core/constants/app_icons.dart`**

```dart
// lib/core/constants/app_icons.dart
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Central icon registry. All icon usage in the app goes through this class.
/// To switch icon packages, update the values here only.
abstract final class AppIcons {
  // Navigation / chevrons
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData arrowLeft = LucideIcons.arrowLeft;
  static const IconData arrowRight = LucideIcons.arrowRight;
  static const IconData arrowUp = LucideIcons.arrowUp;
  static const IconData arrowUpDown = LucideIcons.arrowUpDown;

  // Actions
  static const IconData add = LucideIcons.plus;
  static const IconData close = LucideIcons.x;
  static const IconData trash = LucideIcons.trash2;
  static const IconData revert = LucideIcons.undo2;
  static const IconData check = LucideIcons.check;
  static const IconData copy = LucideIcons.copy;
  static const IconData run = LucideIcons.play;
  static const IconData apply = LucideIcons.download;
  static const IconData applying = LucideIcons.hourglass;
  static const IconData sort = LucideIcons.arrowUpDown;

  // Visibility / auth
  static const IconData showSecret = LucideIcons.eye;
  static const IconData hideSecret = LucideIcons.eyeOff;
  static const IconData lock = LucideIcons.lock;

  // Content / files
  static const IconData code = LucideIcons.code;
  static const IconData folder = LucideIcons.folder;
  static const IconData archive = LucideIcons.archive;
  static const IconData archiveRestore = LucideIcons.archiveRestore;
  static const IconData storage = LucideIcons.hardDrive;
  static const IconData rename = LucideIcons.pencil;

  // Chat / AI
  static const IconData chat = LucideIcons.messageSquare;
  static const IconData newChat = LucideIcons.messageSquarePlus;
  static const IconData aiMode = LucideIcons.zap;

  // Git
  static const IconData gitMerge = LucideIcons.gitMerge;
  static const IconData gitCommit = LucideIcons.gitCommitHorizontal;
  static const IconData gitDiff = LucideIcons.gitCompare;
  static const IconData gitBranch = LucideIcons.gitBranch;

  // UI chrome
  static const IconData settings = LucideIcons.settings;
}
```

- [ ] **Step 2: Update `lib/shell/widgets/top_action_bar.dart`**

Replace:
```dart
import 'package:lucide_icons_flutter/lucide_icons.dart';
```
With:
```dart
import '../../core/constants/app_icons.dart';
```

Then replace every `LucideIcons.*` reference in that file with the matching `AppIcons.*` constant:
- `LucideIcons.plus` → `AppIcons.add`
- `LucideIcons.gitMerge` → `AppIcons.gitMerge`
- `LucideIcons.code` → `AppIcons.code`
- `LucideIcons.gitCommitHorizontal` → `AppIcons.gitCommit`
- `LucideIcons.chevronDown` → `AppIcons.chevronDown`

- [ ] **Step 3: Update `lib/shell/widgets/status_bar.dart`**

Replace lucide import → `import '../../core/constants/app_icons.dart';`

- `LucideIcons.hardDrive` → `AppIcons.storage`

- [ ] **Step 4: Update `lib/features/settings/settings_screen.dart`**

Replace lucide import → `import '../../core/constants/app_icons.dart';`

Replacements:
- `LucideIcons.settings` → `AppIcons.settings`
- `LucideIcons.messageSquare` → `AppIcons.chat`
- `LucideIcons.archive` → `AppIcons.archive`
- `LucideIcons.arrowLeft` → `AppIcons.arrowLeft`
- `LucideIcons.play` → `AppIcons.run`
- `LucideIcons.chevronUp` → `AppIcons.chevronUp`
- `LucideIcons.chevronDown` → `AppIcons.chevronDown`
- `LucideIcons.eyeOff` → `AppIcons.hideSecret`
- `LucideIcons.eye` → `AppIcons.showSecret`
- `LucideIcons.x` → `AppIcons.close`
- `LucideIcons.check` → `AppIcons.check`

- [ ] **Step 5: Update `lib/features/settings/archive_screen.dart`**

Replace lucide import → `import '../../core/constants/app_icons.dart';`

- `LucideIcons.archive` → `AppIcons.archive`
- `LucideIcons.folder` → `AppIcons.folder`
- `LucideIcons.archiveRestore` → `AppIcons.archiveRestore`

- [ ] **Step 6: Update `lib/features/chat/widgets/chat_input_bar_v2.dart`**

Replace lucide import → `import '../../../core/constants/app_icons.dart';`

- `LucideIcons.check` → `AppIcons.check`
- `LucideIcons.zap` → `AppIcons.aiMode`
- `LucideIcons.messageSquare` → `AppIcons.chat`
- `LucideIcons.lock` → `AppIcons.lock`
- `LucideIcons.arrowUp` → `AppIcons.arrowUp`
- `LucideIcons.chevronDown` → `AppIcons.chevronDown`

- [ ] **Step 7: Update `lib/features/chat/widgets/changes_panel.dart`**

Replace lucide import → `import '../../../core/constants/app_icons.dart';`

- `LucideIcons.arrowRight` → `AppIcons.arrowRight`
- `LucideIcons.undo2` → `AppIcons.revert`

- [ ] **Step 8: Update `lib/features/chat/widgets/message_bubble.dart`**

Replace lucide import → `import '../../../core/constants/app_icons.dart';`

- `LucideIcons.gitCompare` → `AppIcons.gitDiff`
- `LucideIcons.hourglass` → `AppIcons.applying`
- `LucideIcons.download` → `AppIcons.apply`
- `LucideIcons.chevronUp` → `AppIcons.chevronUp`
- `LucideIcons.check` → `AppIcons.check`
- `LucideIcons.copy` → `AppIcons.copy`

- [ ] **Step 9: Update `lib/features/project_sidebar/project_sidebar.dart`**

Replace lucide import → `import '../../core/constants/app_icons.dart';`

- `LucideIcons.arrowUpDown` → `AppIcons.arrowUpDown`
- `LucideIcons.plus` → `AppIcons.add`
- `LucideIcons.folder` → `AppIcons.folder`
- `LucideIcons.settings` → `AppIcons.settings`
- `LucideIcons.check` → `AppIcons.check`

- [ ] **Step 10: Update `lib/features/project_sidebar/widgets/project_tile.dart`**

Replace lucide import → `import '../../../core/constants/app_icons.dart';`

- `LucideIcons.chevronDown` → `AppIcons.chevronDown`
- `LucideIcons.chevronRight` → `AppIcons.chevronRight`
- `LucideIcons.folder` → `AppIcons.folder`
- `LucideIcons.messageSquarePlus` → `AppIcons.newChat`
- `LucideIcons.gitBranch` → `AppIcons.gitBranch`

- [ ] **Step 11: Update `lib/features/project_sidebar/widgets/conversation_tile.dart`**

Replace lucide import → `import '../../../core/constants/app_icons.dart';`

- `LucideIcons.pencil` → `AppIcons.rename`
- `LucideIcons.archive` → `AppIcons.archive`
- `LucideIcons.trash2` → `AppIcons.trash`

- [ ] **Step 12: Verify no stray lucide imports remain in lib/**

```bash
grep -rn "lucide_icons_flutter" lib/ --include="*.dart"
```

Expected: only `lib/core/constants/app_icons.dart` (the single import point).

- [ ] **Step 13: Analyze, format, and commit**

```bash
dart format lib/core/constants/app_icons.dart lib/shell/widgets/top_action_bar.dart lib/shell/widgets/status_bar.dart lib/features/settings/settings_screen.dart lib/features/settings/archive_screen.dart lib/features/chat/widgets/chat_input_bar_v2.dart lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/message_bubble.dart lib/features/project_sidebar/project_sidebar.dart lib/features/project_sidebar/widgets/project_tile.dart lib/features/project_sidebar/widgets/conversation_tile.dart
flutter analyze
flutter test
```

Expected: no issues, all tests pass.

```bash
git add lib/core/constants/app_icons.dart lib/shell/widgets/top_action_bar.dart lib/shell/widgets/status_bar.dart lib/features/settings/settings_screen.dart lib/features/settings/archive_screen.dart lib/features/chat/widgets/chat_input_bar_v2.dart lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/message_bubble.dart lib/features/project_sidebar/project_sidebar.dart lib/features/project_sidebar/widgets/project_tile.dart lib/features/project_sidebar/widgets/conversation_tile.dart
git commit -m "refactor: centralize all icon references behind AppIcons constants"
```

---

## Task 3: Friendly UI error messages — no raw exceptions in UI text

**Goal:** No UI widget shows `$e`, `e.toString()`, or a stack trace to the user. All displayed text is a hardcoded, human-readable string.

**Affected call sites:**

| File | Line | Bad pattern | Replacement text |
|------|------|------------|-----------------|
| `archive_screen.dart` | 23 | `Text('Error: $e')` | `'Failed to load archived sessions.'` |
| `chat_input_bar_v2.dart` | 81 | `Text('Error: $e')` | `'Failed to send message. Please try again.'` |
| `changes_panel.dart` | 228 | `Text('Revert failed: ${e.message}')` | `'Revert failed. Please try again.'` |
| `changes_panel.dart` | 238 | `Text('Revert failed: $e')` | `'Revert failed. Please try again.'` |
| `message_list.dart` | 77 | `_ErrorState(error: e.toString())` | hardcoded string |
| `error_boundary.dart` | 30 | `_error.toString()` | AppException.message or fallback |
| `error_boundary.dart` | 118 | `error.toString()` | AppException.message or fallback |

- [ ] **Step 1: Add a helper to `AppException` to extract a user-facing message**

Open `lib/core/errors/app_exception.dart`. Add a static helper **after** the class body:

```dart
/// Returns a user-facing message from any error:
/// - AppException → its own .message
/// - Everything else → the fallback string
String userMessage(Object error, {String fallback = 'Something went wrong.'}) {
  if (error is AppException) return error.message;
  return fallback;
}
```

This is a top-level function (not inside the class) so it can be called anywhere via `import 'app_exception.dart'`.

- [ ] **Step 2: Fix `lib/features/settings/archive_screen.dart` line 23**

Old:
```dart
child: Text('Error: $e', style: const TextStyle(color: ThemeConstants.error, fontSize: 11)),
```

New:
```dart
child: const Text('Failed to load archived sessions.', style: TextStyle(color: ThemeConstants.error, fontSize: 11)),
```

- [ ] **Step 3: Fix `lib/features/chat/widgets/chat_input_bar_v2.dart` line 81**

Old:
```dart
SnackBar(content: Text('Error: $e'), backgroundColor: ThemeConstants.error),
```

New:
```dart
SnackBar(content: const Text('Failed to send message. Please try again.'), backgroundColor: ThemeConstants.error),
```

- [ ] **Step 4: Fix `lib/features/chat/widgets/changes_panel.dart` lines 228 and 238**

Old (StateError catch block, line 228):
```dart
content: Text('Revert failed: ${e.message}'),
```
New:
```dart
content: const Text('Revert failed. Please try again.'),
```

Old (generic catch block, line 238):
```dart
content: Text('Revert failed: $e'),
```
New:
```dart
content: const Text('Revert failed. Please try again.'),
```

- [ ] **Step 5: Fix `lib/features/chat/widgets/message_list.dart` line 77**

Old:
```dart
error: (e, _) => _ErrorState(error: e.toString()),
```

New (import `app_exception.dart`, call `userMessage`):
```dart
// Add import at top of file:
import '../../../core/errors/app_exception.dart';

// Change line 77:
error: (e, _) => _ErrorState(error: userMessage(e, fallback: 'Could not load messages.')),
```

- [ ] **Step 6: Fix `lib/shared/widgets/error_boundary.dart`**

Add import:
```dart
import '../../core/errors/app_exception.dart';
```

In `_ErrorBoundaryState.build` (around line 30), change:
```dart
// old
error: _error.toString(),
// new
error: userMessage(_error!, fallback: 'An unexpected error occurred.'),
```

In `AsyncErrorView.build` (around line 118), change:
```dart
// old
error.toString(),
// new
userMessage(error, fallback: 'An unexpected error occurred.'),
```

- [ ] **Step 7: Analyze, format, test**

```bash
dart format lib/core/errors/app_exception.dart lib/features/settings/archive_screen.dart lib/features/chat/widgets/chat_input_bar_v2.dart lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/message_list.dart lib/shared/widgets/error_boundary.dart
flutter analyze
flutter test
```

Expected: no issues, all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/core/errors/app_exception.dart lib/features/settings/archive_screen.dart lib/features/chat/widgets/chat_input_bar_v2.dart lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/message_list.dart lib/shared/widgets/error_boundary.dart
git commit -m "refactor: replace raw exception text in UI with hardcoded user-friendly messages"
```

---

## Task 4: showErrorSnackBar helper — eliminate repeated snackbar pattern

**Goal:** The 5+ copy-pasted `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` error blocks are replaced by a single function call. The function is tested.

**Repeated pattern found in:**
- `lib/features/chat/widgets/changes_panel.dart` (2 calls — already updated in Task 3, still verbose)
- `lib/features/chat/widgets/chat_input_bar_v2.dart` (1 call — already updated in Task 3)
- `lib/features/chat/widgets/message_bubble.dart` — already has `_showApplyError` (leave as is, it's already a local helper)
- `lib/features/chat/widgets/apply_code_dialog.dart` — already using `const SnackBar` (leave as is)
- `lib/features/settings/settings_screen.dart` — uses `const SnackBar` (leave as is, messages are hardcoded)

The two remaining verbose call sites worth extracting: `changes_panel.dart` and `chat_input_bar_v2.dart` after Task 3 changes. Plus `error_boundary.dart` can be left as is since it has its own `onRetry` layout.

- [ ] **Step 1: Write the failing test first**

Create `test/core/utils/snackbar_helper_test.dart`:

```dart
import 'package:code_bench_app/core/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showErrorSnackBar shows error text with error background', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showErrorSnackBar(context, 'Test error'),
            child: const Text('tap'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pump();

    expect(find.text('Test error'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, const Color(0xFFF44747)); // ThemeConstants.error
  });

  testWidgets('showSuccessSnackBar shows message text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showSuccessSnackBar(context, 'Saved'),
            child: const Text('tap'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/core/utils/snackbar_helper_test.dart
```

Expected: FAIL with `'package:code_bench_app/core/utils/snackbar_helper.dart' not found`.

- [ ] **Step 3: Create `lib/core/utils/snackbar_helper.dart`**

```dart
// lib/core/utils/snackbar_helper.dart
import 'package:flutter/material.dart';

import '../constants/theme_constants.dart';

/// Shows a red error snackbar. Use for action failures visible to the user.
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: ThemeConstants.error,
    ),
  );
}

/// Shows a neutral snackbar. Use for confirmations (e.g. "Copied").
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/core/utils/snackbar_helper_test.dart
```

Expected: PASS.

- [ ] **Step 5: Use `showErrorSnackBar` in `changes_panel.dart`**

Add import:
```dart
import '../../../core/utils/snackbar_helper.dart';
```

Replace the two `ScaffoldMessenger.of(context).showSnackBar(...)` blocks (in the `onTap` of the revert button) with:
```dart
if (context.mounted) showErrorSnackBar(context, 'Revert failed. Please try again.');
```

Both the `StateError` and generic `catch` blocks use the same message (already changed in Task 3), so this replaces both.

- [ ] **Step 6: Use `showErrorSnackBar` in `chat_input_bar_v2.dart`**

Add import:
```dart
import '../../../core/utils/snackbar_helper.dart';
```

Replace the catch block (already updated in Task 3):
```dart
if (mounted) showErrorSnackBar(context, 'Failed to send message. Please try again.');
```

- [ ] **Step 7: Format, analyze, run all tests**

```bash
dart format lib/core/utils/snackbar_helper.dart lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/chat_input_bar_v2.dart test/core/utils/snackbar_helper_test.dart
flutter analyze
flutter test
```

Expected: no issues, all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/core/utils/snackbar_helper.dart test/core/utils/snackbar_helper_test.dart lib/features/chat/widgets/changes_panel.dart lib/features/chat/widgets/chat_input_bar_v2.dart
git commit -m "refactor: extract showErrorSnackBar helper, eliminate repeated snackbar pattern"
```
