# Code Bench Theme & Branding Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all VS Code blue (`#007ACC`) with teal (`#4EC9B0`) across tokens, dialogs, buttons, onboarding, and settings; add `AppDialog` and `AppSnackBar` components; restructure the action bar with separate Push/PR ghost buttons; redesign the send button; and generate the app icon.

**Architecture:** Token-first — Task 1 propagates through ~80% of the codebase automatically. Remaining tasks address hard-coded `Colors.white`, `blueAccent`, new widgets, and structural changes that token updates alone cannot cover.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation + build_runner), `lucide_icons_flutter`, `dart:ui` (icon generation), `image` package (icon downsampling)

---

## File Map

**Create:**
- `lib/core/widgets/app_dialog.dart`
- `lib/core/widgets/app_snack_bar.dart`
- `lib/data/git/models/git_changed_file.dart`
- `test/tool/generate_icon_test.dart`

**Modify:**
- `lib/core/constants/theme_constants.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/constants/app_icons.dart`
- `lib/core/utils/snackbar_helper.dart`
- `lib/data/git/datasource/git_datasource.dart`
- `lib/data/git/datasource/git_datasource_process.dart`
- `lib/services/git/git_service.dart`
- `lib/features/chat/widgets/commit_dialog.dart`
- `lib/features/chat/widgets/create_pr_dialog.dart`
- `lib/shell/widgets/commit_push_button.dart`
- `lib/features/chat/widgets/chat_input_bar.dart`
- `lib/features/onboarding/onboarding_screen.dart`
- `lib/features/onboarding/widgets/step_progress_indicator.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/features/settings/general_screen.dart`
- `lib/features/settings/providers_screen.dart`
- `lib/features/chat/widgets/work_log_section.dart`
- `lib/features/chat/widgets/tool_call_row.dart`
- `lib/features/chat/widgets/ask_user_question_card.dart`
- `lib/shell/widgets/working_pill.dart`

---

## Task 1: Colour token foundation

**Files:**
- Modify: `lib/core/constants/theme_constants.dart`

- [ ] **Step 1: Update accent family (6 tokens)**

In `theme_constants.dart` change:

```dart
  static const Color accent = Color(0xFF4EC9B0);          // was 0xFF007ACC
  static const Color accentLight = Color(0xFF6DD4BE);     // was 0xFF1F8AD2
  static const Color accentHover = Color(0xFF3AB49A);     // was 0xFF0066B8
  static const Color accentDark = Color(0xFF267A68);      // was 0xFF004F85
  static const Color tabBorder = Color(0xFF4EC9B0);       // was 0xFF007ACC
  static const Color blueAccent = Color(0xFF4EC9B0);      // was 0xFF4A7CFF
```

- [ ] **Step 2: Update selection / active-state surfaces (3 tokens)**

```dart
  static const Color selectionBg = Color(0xFF0D2B27);     // was 0xFF1A2540
  static const Color selectionBorder = Color(0xFF1A4840); // was 0xFF2A3550
  static const Color questionCardBg = Color(0xFF0D2B27);  // was 0xFF1A1F2E
```

- [ ] **Step 3: Run tests**

```bash
flutter test
```

Expected: all pass. If any test asserts exact color hex values against the old blue tokens, update those expected values.

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/theme_constants.dart
git commit -m "feat: replace blue accent tokens with teal (#4EC9B0)"
```

---

## Task 2: App theme layer

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

Teal is light enough that near-black text is more legible than white on a `#4EC9B0` background. Fix `onPrimary` and the `ElevatedButton` foreground.

- [ ] **Step 1: Update ColorScheme onPrimary / onSecondary**

```dart
      colorScheme: const ColorScheme.dark(
        primary: ThemeConstants.accent,
        onPrimary: Color(0xFF0A0A0A),      // was Colors.white
        secondary: ThemeConstants.accentLight,
        onSecondary: Color(0xFF0A0A0A),    // was Colors.white
        // …rest unchanged
      ),
```

- [ ] **Step 2: Update ElevatedButton foregroundColor**

```dart
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.accent,
          foregroundColor: const Color(0xFF0A0A0A), // was Colors.white
          // …rest unchanged
        ),
      ),
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/core/theme/app_theme.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat: set onPrimary + ElevatedButton foreground to near-black for teal contrast"
```

---

## Task 3: AppIcons additions

**Files:**
- Modify: `lib/core/constants/app_icons.dart`

Two new icons needed for the action bar: cloud-upload (Push) and git pull request (Create PR).

- [ ] **Step 1: Add to AppIcons**

In `app_icons.dart`, add to the `// Git` section:

```dart
  static const IconData cloudUpload = LucideIcons.cloudUpload;
  static const IconData gitPullRequest = LucideIcons.gitPullRequest;
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/constants/app_icons.dart
git commit -m "feat: add cloudUpload and gitPullRequest to AppIcons"
```

---

## Task 4: AppDialog widget

**Files:**
- Create: `lib/core/widgets/app_dialog.dart`

Frosted-glass dialog shell. Owns only chrome: surface, icon badge, footer. Content and state belong in the calling widget.

Icon badge sizing rule: 36×36px (radius 9px) for confirmation dialogs (`hasInputField: false`); 28×28px (radius 7px) for input dialogs (`hasInputField: true`).

- [ ] **Step 1: Create the file**

Create `lib/core/widgets/app_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

enum AppDialogIconType { teal, destructive }

class AppDialogAction {
  const AppDialogAction._({
    required this.label,
    required this.onPressed,
    required this.style,
  });

  factory AppDialogAction.cancel({required VoidCallback onPressed}) =>
      AppDialogAction._(label: 'Cancel', onPressed: onPressed, style: _ActionStyle.ghost);

  factory AppDialogAction.primary({required String label, required VoidCallback? onPressed}) =>
      AppDialogAction._(label: label, onPressed: onPressed, style: _ActionStyle.primary);

  factory AppDialogAction.destructive({required String label, required VoidCallback onPressed}) =>
      AppDialogAction._(label: label, onPressed: onPressed, style: _ActionStyle.destructive);

  final String label;
  final VoidCallback? onPressed;
  final _ActionStyle style;
}

enum _ActionStyle { primary, ghost, destructive }

/// Frosted-glass dialog surface with icon badge + standardised footer.
///
/// Content and dialog state belong in the caller's widget. AppDialog provides
/// only the visual chrome: background, border, icon badge, and footer buttons.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.icon,
    required this.iconType,
    required this.title,
    this.subtitle,
    this.hasInputField = false,
    required this.content,
    required this.actions,
    this.minWidth = 300,
    this.maxWidth = 480,
  });

  final IconData icon;
  final AppDialogIconType iconType;
  final String title;
  final String? subtitle;
  final bool hasInputField;
  final Widget content;
  final List<AppDialogAction> actions;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final badgeSize = hasInputField ? 28.0 : 36.0;
    final badgeRadius = hasInputField ? 7.0 : 9.0;
    final headerBottomPad = hasInputField ? 12.0 : 14.0;

    final (iconBg, iconFg) = switch (iconType) {
      AppDialogIconType.teal => (const Color(0x1A4EC9B0), ThemeConstants.accent),
      AppDialogIconType.destructive => (const Color(0x1AF44747), ThemeConstants.error),
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xF7161616),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF333333)),
            boxShadow: const [
              BoxShadow(color: Color(0xD9000000), blurRadius: 60, offset: Offset(0, 20)),
              BoxShadow(color: Color(0x0AFFFFFF), blurRadius: 0, spreadRadius: 0.5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, headerBottomPad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(badgeRadius),
                      ),
                      child: Icon(icon, size: badgeSize * 0.5, color: iconFg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: (badgeSize - 16.0) / 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: ThemeConstants.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  color: ThemeConstants.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: content,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF242424))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions.indexed
                      .map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(left: entry.$1 > 0 ? 8.0 : 0.0),
                          child: _ActionButton(action: entry.$2),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final AppDialogAction action;

  @override
  Widget build(BuildContext context) {
    final (bg, border, textColor) = switch (action.style) {
      _ActionStyle.primary => (
        ThemeConstants.accent,
        Border.all(color: Colors.transparent),
        const Color(0xFF0A0A0A),
      ),
      _ActionStyle.ghost => (
        Colors.transparent,
        Border.all(color: ThemeConstants.borderColor),
        ThemeConstants.textPrimary,
      ),
      _ActionStyle.destructive => (
        Colors.transparent,
        Border.all(color: const Color(0xFF3D1515)),
        ThemeConstants.error,
      ),
    };

    return GestureDetector(
      onTap: action.onPressed,
      child: Opacity(
        opacity: action.onPressed == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: border,
          ),
          child: Text(
            action.label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: action.style == _ActionStyle.primary ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze lib/core/widgets/app_dialog.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/app_dialog.dart
git commit -m "feat: add AppDialog — frosted glass dialog shell with icon badge + footer"
```

---

## Task 5: AppSnackBar widget + helper update

**Files:**
- Create: `lib/core/widgets/app_snack_bar.dart`
- Modify: `lib/core/utils/snackbar_helper.dart`

- [ ] **Step 1: Create AppSnackBar**

Create `lib/core/widgets/app_snack_bar.dart`:

```dart
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

enum AppSnackBarType { success, error, warning, info }

class AppSnackBar extends StatelessWidget {
  const AppSnackBar({
    super.key,
    required this.label,
    this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final String? message;
  final AppSnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const _typeColor = {
    AppSnackBarType.success: Color(0xFF4EC9B0),
    AppSnackBarType.error: Color(0xFFF44747),
    AppSnackBarType.warning: Color(0xFFCCA700),
    AppSnackBarType.info: Color(0xFF4FC1FF),
  };

  static const _typeIconBg = {
    AppSnackBarType.success: Color(0x1F4EC9B0),
    AppSnackBarType.error: Color(0x1FF44747),
    AppSnackBarType.warning: Color(0x1FCCA700),
    AppSnackBarType.info: Color(0x1F4FC1FF),
  };

  static const _typeIcon = {
    AppSnackBarType.success: Icons.check_circle_outline,
    AppSnackBarType.error: Icons.error_outline,
    AppSnackBarType.warning: Icons.warning_amber_outlined,
    AppSnackBarType.info: Icons.info_outline,
  };

  /// Shows a frosted snackbar anchored to the bottom of the nearest Scaffold.
  static void show(
    BuildContext context,
    String label, {
    String? message,
    AppSnackBarType type = AppSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: AppSnackBar(
            label: label,
            message: message,
            type: type,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor[type]!;
    final iconBg = _typeIconBg[type]!;
    final iconData = _typeIcon[type]!;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xF7161616),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(color: const Color(0xFF2A2A2A)),
          right: BorderSide(color: const Color(0xFF2A2A2A)),
          bottom: BorderSide(color: const Color(0xFF2A2A2A)),
          left: BorderSide(color: typeColor, width: 3),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xB3000000), blurRadius: 32, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(5)),
              child: Icon(iconData, size: 13, color: typeColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      message!,
                      style: const TextStyle(color: ThemeConstants.dimFg, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              child: const Icon(Icons.close, size: 13, color: Color(0xFF555555)),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update snackbar_helper.dart**

Replace the contents of `lib/core/utils/snackbar_helper.dart`:

```dart
import 'package:flutter/material.dart';
import '../widgets/app_snack_bar.dart';

/// Shows a frosted error snackbar.
void showErrorSnackBar(BuildContext context, String label, {String? detail}) {
  AppSnackBar.show(context, label, message: detail, type: AppSnackBarType.error);
}

/// Shows a frosted success snackbar.
void showSuccessSnackBar(BuildContext context, String label, {String? detail}) {
  AppSnackBar.show(context, label, message: detail, type: AppSnackBarType.success);
}
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/core/widgets/app_snack_bar.dart lib/core/utils/snackbar_helper.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/widgets/app_snack_bar.dart lib/core/utils/snackbar_helper.dart
git commit -m "feat: add AppSnackBar frosted snackbar + update snackbar_helper"
```

---

## Task 6: GitChangedFile model + datasource + service

**Files:**
- Create: `lib/data/git/models/git_changed_file.dart`
- Modify: `lib/data/git/datasource/git_datasource.dart`
- Modify: `lib/data/git/datasource/git_datasource_process.dart`
- Modify: `lib/services/git/git_service.dart`

Powers the file list in the redesigned commit dialog.

- [ ] **Step 1: Create GitChangedFile model**

Create `lib/data/git/models/git_changed_file.dart`:

```dart
/// A single file in the staged (or working-tree) diff, parsed from
/// `git diff --cached --numstat` output.
class GitChangedFile {
  const GitChangedFile({
    required this.path,
    required this.additions,
    required this.deletions,
    required this.status,
  });

  final String path;
  final int additions;
  final int deletions;
  final GitChangedFileStatus status;
}

enum GitChangedFileStatus {
  added,
  modified,
  deleted,
  renamed;

  String get badge => switch (this) {
    GitChangedFileStatus.added => 'A',
    GitChangedFileStatus.modified => 'M',
    GitChangedFileStatus.deleted => 'D',
    GitChangedFileStatus.renamed => 'R',
  };
}
```

- [ ] **Step 2: Add getChangedFiles to GitDatasource interface**

In `lib/data/git/datasource/git_datasource.dart`:

Add import at the top:
```dart
import '../models/git_changed_file.dart';
```

Add method to the interface (after `listLocalBranches`):
```dart
  Future<List<GitChangedFile>> getChangedFiles();
```

- [ ] **Step 3: Implement getChangedFiles in GitDatasourceProcess**

In `lib/data/git/datasource/git_datasource_process.dart`:

Add import:
```dart
import '../models/git_changed_file.dart';
```

Add method after the existing `createBranch` method (or any existing method):

```dart
  /// Returns staged changes via `git diff --cached --numstat`.
  /// Falls back to `git diff --numstat HEAD` when nothing is staged.
  @override
  Future<List<GitChangedFile>> getChangedFiles() async {
    var result = await Process.run(
      'git',
      ['diff', '--cached', '--numstat'],
      workingDirectory: _projectPath,
    );
    var output = (result.stdout as String).trim();

    if (output.isEmpty && result.exitCode == 0) {
      result = await Process.run(
        'git',
        ['diff', '--numstat', 'HEAD'],
        workingDirectory: _projectPath,
      );
      output = (result.stdout as String).trim();
    }

    if (output.isEmpty) return [];
    return output.split('\n').map(_parseLine).whereType<GitChangedFile>().toList();
  }

  static GitChangedFile? _parseLine(String line) {
    final parts = line.split('\t');
    if (parts.length < 3) return null;
    final additions = int.tryParse(parts[0]) ?? 0;
    final deletions = int.tryParse(parts[1]) ?? 0;
    final path = parts.sublist(2).join('\t').trim();
    if (path.isEmpty) return null;
    return GitChangedFile(
      path: path,
      additions: additions,
      deletions: deletions,
      status: _inferStatus(additions, deletions, path),
    );
  }

  static GitChangedFileStatus _inferStatus(int additions, int deletions, String path) {
    if (path.contains(' => ')) return GitChangedFileStatus.renamed;
    if (additions > 0 && deletions == 0) return GitChangedFileStatus.added;
    if (deletions > 0 && additions == 0) return GitChangedFileStatus.deleted;
    return GitChangedFileStatus.modified;
  }
```

- [ ] **Step 4: Expose getChangedFiles on GitService**

In `lib/services/git/git_service.dart`:

Add import:
```dart
import '../../data/git/models/git_changed_file.dart';
```

Add to exports (after the existing `export` lines):
```dart
export '../../data/git/models/git_changed_file.dart';
```

Add method (after any existing `_ds(path).X()` delegation):
```dart
  Future<List<GitChangedFile>> getChangedFiles(String path) =>
      _ds(path).getChangedFiles();
```

- [ ] **Step 5: Run flutter analyze**

```bash
flutter analyze lib/data/git/ lib/services/git/git_service.dart
```

Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/data/git/models/git_changed_file.dart \
        lib/data/git/datasource/git_datasource.dart \
        lib/data/git/datasource/git_datasource_process.dart \
        lib/services/git/git_service.dart
git commit -m "feat: add GitChangedFile model and getChangedFiles() through git stack"
```

---

## Task 7: Rewrite CommitDialog

**Files:**
- Modify: `lib/features/chat/widgets/commit_dialog.dart`
- Modify: `lib/shell/widgets/commit_push_button.dart` (call-site update)

Public API change: `CommitDialog.show` gains a required `projectPath` parameter.

- [ ] **Step 1: Replace commit_dialog.dart**

Replace `lib/features/chat/widgets/commit_dialog.dart` with:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/_core/preferences/general_preferences.dart';
import '../../../services/git/git_service.dart';

class CommitDialog extends ConsumerStatefulWidget {
  const CommitDialog({super.key, required this.initialMessage, required this.projectPath});

  final String initialMessage;
  final String projectPath;

  /// Shows the commit dialog and returns the confirmed message, or null if cancelled.
  static Future<String?> show(
    BuildContext context,
    String initialMessage, {
    required String projectPath,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => CommitDialog(initialMessage: initialMessage, projectPath: projectPath),
    );
  }

  @override
  ConsumerState<CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends ConsumerState<CommitDialog> {
  late final TextEditingController _controller;
  bool _autoCommit = false;
  List<GitChangedFile> _changedFiles = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMessage);
    unawaited(_loadAutoCommit());
    unawaited(_loadChangedFiles());
  }

  Future<void> _loadAutoCommit() async {
    final value = await ref.read(generalPreferencesProvider).getAutoCommit();
    if (mounted) setState(() => _autoCommit = value);
  }

  Future<void> _loadChangedFiles() async {
    try {
      final files = await ref.read(gitServiceProvider).getChangedFiles(widget.projectPath);
      if (mounted) setState(() => _changedFiles = files);
    } catch (_) {
      // File list is informational — silently hide on error.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;
    Navigator.of(context).pop(msg);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) => AppDialog(
        icon: AppIcons.gitCommit,
        iconType: AppDialogIconType.teal,
        title: 'Commit changes',
        hasInputField: true,
        maxWidth: 440,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_changedFiles.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Column(children: _changedFiles.map(_buildFileRow).toList()),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 72,
              decoration: const InputDecoration(
                labelText: 'Commit message',
                labelStyle: TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
              ),
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: ThemeConstants.uiFontSize,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(
                  value: _autoCommit,
                  onChanged: (v) async {
                    setState(() => _autoCommit = v);
                    await ref.read(generalPreferencesProvider).setAutoCommit(v);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  '⚡ Auto-commit future commits',
                  style: TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
          AppDialogAction.primary(
            label: 'Commit',
            onPressed: _controller.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow(GitChangedFile file) {
    final (badgeColor, badgeBg) = switch (file.status) {
      GitChangedFileStatus.modified => (const Color(0xFFCCA700), const Color(0x1ACCA700)),
      GitChangedFileStatus.added => (ThemeConstants.accent, const Color(0x1A4EC9B0)),
      GitChangedFileStatus.deleted => (ThemeConstants.error, const Color(0x1AF44747)),
      GitChangedFileStatus.renamed => (ThemeConstants.textSecondary, ThemeConstants.inputSurface),
    };

    return SizedBox(
      height: 22,
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(2)),
            alignment: Alignment.center,
            child: Text(
              file.status.badge,
              style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              file.path,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 11,
                fontFamily: ThemeConstants.editorFontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('+${file.additions}', style: const TextStyle(color: ThemeConstants.success, fontSize: 10)),
          const SizedBox(width: 4),
          Text('−${file.deletions}', style: const TextStyle(color: ThemeConstants.error, fontSize: 10)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update call site in commit_push_button.dart**

In `lib/shell/widgets/commit_push_button.dart`, find:
```dart
    final confirmed = await CommitDialog.show(context, message);
```
Change to:
```dart
    final confirmed = await CommitDialog.show(context, message, projectPath: widget.project.path);
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/features/chat/widgets/commit_dialog.dart \
               lib/shell/widgets/commit_push_button.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/widgets/commit_dialog.dart lib/shell/widgets/commit_push_button.dart
git commit -m "feat: rewrite CommitDialog — frosted surface + staged file list"
```

---

## Task 8: Rewrite CreatePrDialog

**Files:**
- Modify: `lib/features/chat/widgets/create_pr_dialog.dart`

Public API unchanged — `CreatePrDialog.show()` keeps the same signature.

- [ ] **Step 1: Replace create_pr_dialog.dart**

Replace `lib/features/chat/widgets/create_pr_dialog.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/widgets/app_dialog.dart';

class PrFormResult {
  const PrFormResult({required this.title, required this.body, required this.base, required this.draft});
  final String title;
  final String body;
  final String base;
  final bool draft;
}

class CreatePrDialog extends ConsumerStatefulWidget {
  const CreatePrDialog({
    super.key,
    required this.initialTitle,
    required this.initialBody,
    required this.branches,
  });

  final String initialTitle;
  final String initialBody;
  final List<String> branches;

  static Future<PrFormResult?> show(
    BuildContext context, {
    required String initialTitle,
    required String initialBody,
    required List<String> branches,
  }) {
    return showDialog<PrFormResult>(
      context: context,
      builder: (_) => CreatePrDialog(
        initialTitle: initialTitle,
        initialBody: initialBody,
        branches: branches,
      ),
    );
  }

  @override
  ConsumerState<CreatePrDialog> createState() => _CreatePrDialogState();
}

class _CreatePrDialogState extends ConsumerState<CreatePrDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late String _base;
  bool _draft = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _bodyController = TextEditingController(text: widget.initialBody);
    _base = widget.branches.contains('main')
        ? 'main'
        : (widget.branches.isNotEmpty ? widget.branches.first : 'main');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      PrFormResult(title: title, body: _bodyController.text.trim(), base: _base, draft: _draft),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _titleController,
      builder: (_, __) => AppDialog(
        icon: AppIcons.gitPullRequest,
        iconType: AppDialogIconType.teal,
        title: 'Create pull request',
        hasInputField: true,
        maxWidth: 480,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              maxLength: 70,
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
              ),
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: ThemeConstants.uiFontSize,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
                alignLabelWithHint: true,
              ),
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: ThemeConstants.uiFontSize,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Base branch:',
                  style: TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: widget.branches.contains(_base) ? _base : null,
                  dropdownColor: ThemeConstants.inputSurface,
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                  items: widget.branches
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _base = v);
                  },
                ),
                const Spacer(),
                const Text(
                  'Draft PR',
                  style: TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                ),
                Switch(value: _draft, onChanged: (v) => setState(() => _draft = v)),
              ],
            ),
          ],
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
          AppDialogAction.primary(
            label: 'Create PR',
            onPressed: _titleController.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze lib/features/chat/widgets/create_pr_dialog.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/widgets/create_pr_dialog.dart
git commit -m "feat: rewrite CreatePrDialog — frosted surface + fork icon"
```

---

## Task 9: Action bar restructure

**Files:**
- Modify: `lib/shell/widgets/commit_push_button.dart`

Changes:
1. Left half: `Colors.white` text/icon → `Color(0xFF0A0A0A)` (near-black text on teal background)
2. Right half: `accentLight` → `accentHover` background; `Colors.white` → `Color(0xFF0A0A0A)` content
3. Add Push ghost button (calls existing `_doPush`)
4. Add Create PR ghost button (calls existing `_showCreatePrDialog`)
5. Simplify dropdown to remote-selection + Pull only (Push and Create PR move to dedicated buttons)

- [ ] **Step 1: Fix left half text/icon colors**

Find these two lines inside the left-half `Container`:
```dart
Icon(AppIcons.gitCommit, size: 12, color: s.canCommit ? Colors.white : ThemeConstants.mutedFg),
```
```dart
color: s.canCommit ? Colors.white : ThemeConstants.mutedFg,
```

Change both `Colors.white` → `const Color(0xFF0A0A0A)`.

Also the busy-state text color — find:
```dart
                      Text(
                        _pushing
                            ? '● Pushing…'
                            : _pulling
                            ? '● Pulling…'
                            : 'Commit',
                        style: TextStyle(
                          color: s.canCommit ? Colors.white : ThemeConstants.mutedFg,
```
Change `Colors.white` → `const Color(0xFF0A0A0A)`.

- [ ] **Step 2: Fix right half colors**

Find the right-half Container decoration:
```dart
                color: s.canDropdown ? ThemeConstants.accentLight : ThemeConstants.inputSurface,
```
Change `accentLight` → `accentHover`.

Find the two `Colors.white` usages in the right-half content (badge label Text + chevron Icon):
```dart
color: s.canDropdown ? Colors.white : ThemeConstants.mutedFg,
```
Both occurrences → change `Colors.white` → `const Color(0xFF0A0A0A)`.

- [ ] **Step 3: Add Push and Create PR ghost buttons to the outer Row**

The top-level `return Row(...)` currently has two children (left Tooltip, right Tooltip). Add three more children after the right Tooltip:

```dart
        // ── Push ghost button ──────────────────────────────────────────────
        const SizedBox(width: 4),
        Tooltip(
          message: 'Push to remote',
          child: GestureDetector(
            onTap: (busy || !s.canPush) ? null : () => unawaited(_doPush(s)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints.tightFor(height: ThemeConstants.actionButtonHeight),
              decoration: BoxDecoration(
                color: ThemeConstants.inputSurface,
                border: Border.all(color: ThemeConstants.deepBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.cloudUpload,
                    size: 10,
                    color: (busy || !s.canPush) ? ThemeConstants.faintFg : ThemeConstants.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _pushing ? '…' : 'Push',
                    style: TextStyle(
                      color: (busy || !s.canPush) ? ThemeConstants.faintFg : ThemeConstants.textSecondary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Create PR ghost button ─────────────────────────────────────────
        const SizedBox(width: 4),
        Tooltip(
          message: 'Create pull request',
          child: GestureDetector(
            onTap: (busy || !s.canPr) ? null : () => unawaited(_showCreatePrDialog()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints.tightFor(height: ThemeConstants.actionButtonHeight),
              decoration: BoxDecoration(
                color: ThemeConstants.inputSurface,
                border: Border.all(color: ThemeConstants.deepBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.gitPullRequest,
                    size: 10,
                    color: (busy || !s.canPr) ? ThemeConstants.faintFg : ThemeConstants.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PR',
                    style: TextStyle(
                      color: (busy || !s.canPr) ? ThemeConstants.faintFg : ThemeConstants.textSecondary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
```

- [ ] **Step 4: Simplify the dropdown items list**

Remove the `push` and `create_pr` `PopupMenuItem`s and their dividers from the dropdown `items` list. The simplified list:

```dart
items: [
  if (s.remotes.length > 1) ...[
    for (final remote in s.remotes)
      CheckedPopupMenuItem<String>(
        value: 'select_${remote.name}',
        checked: s.selectedRemote == remote.name,
        height: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              remote.name,
              style: const TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
            Text(
              remote.url,
              style: const TextStyle(
                color: ThemeConstants.faintFg,
                fontSize: ThemeConstants.uiFontSizeLabel,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    const PopupMenuDivider(),
    const PopupMenuItem(
      value: 'push_all',
      height: 32,
      child: Text(
        'Push to all remotes',
        style: TextStyle(
          color: ThemeConstants.textSecondary,
          fontSize: ThemeConstants.uiFontSizeSmall,
        ),
      ),
    ),
    const PopupMenuDivider(),
  ],
  PopupMenuItem(
    value: 'pull',
    height: 32,
    enabled: s.canPull && !busy,
    child: Text(
      _pulling ? '● Pulling…' : s.canPull ? 'Pull${s.badgeLabel}' : 'Pull',
      style: TextStyle(
        color: s.canPull ? ThemeConstants.accent : ThemeConstants.faintFg,
        fontSize: ThemeConstants.uiFontSizeSmall,
      ),
    ),
  ),
],
```

Update the `switch (action)` handler to remove `push` and `create_pr` cases:

```dart
switch (action) {
  case 'push_all':
    unawaited(_doPushAll(s));
  case 'pull':
    unawaited(_doPull());
  case final String sel when sel.startsWith('select_'):
    ref
        .read(gitRemotesProvider(widget.project.path).notifier)
        .selectRemote(sel.substring('select_'.length));
}
```

- [ ] **Step 5: Run flutter analyze**

```bash
flutter analyze lib/shell/widgets/commit_push_button.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/shell/widgets/commit_push_button.dart
git commit -m "feat: action bar — teal commit button near-black text + Push/PR ghost buttons"
```

---

## Task 10: Chat send button redesign

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar.dart`

Changes: circle → 28×28px rounded square (r=7px); teal when text present; grey border when empty; `#267A68` with pulsing stop square when streaming.

- [ ] **Step 1: Add SingleTickerProviderStateMixin**

Change:
```dart
class _ChatInputBarState extends ConsumerState<ChatInputBar> {
```
to:
```dart
class _ChatInputBarState extends ConsumerState<ChatInputBar> with SingleTickerProviderStateMixin {
```

- [ ] **Step 2: Add AnimationController fields**

After `bool _isSending = false;`, add:
```dart
  late AnimationController _pulseController;
  late Animation<double> _pulseOpacity;
```

- [ ] **Step 3: Initialise and dispose animation controller**

In `initState()`, after the draft restore block, add:
```dart
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseOpacity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
```

In `dispose()`, before `super.dispose()`, add:
```dart
    _pulseController.dispose();
```

- [ ] **Step 4: Replace send button Container**

Find the entire `GestureDetector` that wraps the send button (starts with `onTap: _isSending ? null : _send`). Replace it with:

```dart
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (_, __) {
                            final hasText = _controller.text.trim().isNotEmpty;
                            final Color bg;
                            if (_isSending) {
                              bg = const Color(0xFF267A68);
                            } else if (hasText && !isMissing) {
                              bg = ThemeConstants.accent;
                            } else {
                              bg = ThemeConstants.inputSurface;
                            }
                            return GestureDetector(
                              onTap: _isSending ? null : _send,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(7),
                                  border: (!_isSending && (!hasText || isMissing))
                                      ? Border.all(color: ThemeConstants.deepBorder)
                                      : null,
                                ),
                                child: Center(
                                  child: _isSending
                                      ? AnimatedBuilder(
                                          animation: _pulseOpacity,
                                          builder: (_, __) => Opacity(
                                            opacity: _pulseOpacity.value,
                                            child: Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0A0A0A),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          AppIcons.arrowUp,
                                          size: 14,
                                          color: (hasText && !isMissing)
                                              ? const Color(0xFF0A0A0A)
                                              : const Color(0xFF444444),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
```

- [ ] **Step 5: Run flutter analyze**

```bash
flutter analyze lib/features/chat/widgets/chat_input_bar.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/widgets/chat_input_bar.dart
git commit -m "feat: send button — rounded square, teal active, pulsing stop square when streaming"
```

---

## Task 11: Onboarding branding panel

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`

Changes: teal-atmospheric gradient, `</>` logo mark (CustomPainter), teal feature card colors, updated tagline color.

- [ ] **Step 1: Update _BrandingPanel gradient**

Find:
```dart
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [ThemeConstants.sidebarBackground, ThemeConstants.activityBar, ThemeConstants.deepBackground],
          ),
```
Replace:
```dart
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFF0E1A18), Color(0xFF0A0E0D), ThemeConstants.deepBackground],
          ),
```

- [ ] **Step 2: Replace "C" lettermark with </> logo mark**

Find the entire 32×32 logo container (from `Container(` with `width: 32,` through the closing `)` of the child `Text('C', ...)`):

```dart
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ThemeConstants.accent, ThemeConstants.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: ThemeConstants.shadowDark, blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'C',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
```

Replace with:
```dart
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2B27),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A4840)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x404EC9B0), blurRadius: 12),
                    ],
                  ),
                  child: const _CodeGlyph(),
                ),
```

- [ ] **Step 3: Update tagline color**

Find:
```dart
          const Text(
            'AI-powered coding workspace',
            style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 11),
          ),
```
Change `textSecondary` → `const Color(0xFF4A6660)`.

- [ ] **Step 4: Update _FeatureCard to teal-tinted surface**

In the `_FeatureCard.build()` method, find:
```dart
        decoration: BoxDecoration(
          color: ThemeConstants.frostedBg,
          border: Border.all(color: ThemeConstants.frostedBorder),
          borderRadius: BorderRadius.circular(8),
        ),
```
Replace:
```dart
        decoration: BoxDecoration(
          color: const Color(0x0A4EC9B0),
          border: Border.all(color: const Color(0x144EC9B0)),
          borderRadius: BorderRadius.circular(8),
        ),
```

- [ ] **Step 5: Add _CodeGlyph CustomPainter at the bottom of the file**

Add before the final closing `}` of the file:

```dart
// ── </> logo mark ──────────────────────────────────────────────────────────

class _CodeGlyph extends StatelessWidget {
  const _CodeGlyph();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(32, 32), painter: _CodeGlyphPainter());
}

class _CodeGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4EC9B0)
      ..strokeWidth = 2.2 * (size.width / 32)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final s = size.width / 32;
    // Left bracket <
    canvas.drawLine(Offset(5 * s, 16 * s), Offset(11 * s, 10 * s), paint);
    canvas.drawLine(Offset(5 * s, 16 * s), Offset(11 * s, 22 * s), paint);
    // Right bracket >
    canvas.drawLine(Offset(27 * s, 16 * s), Offset(21 * s, 10 * s), paint);
    canvas.drawLine(Offset(27 * s, 16 * s), Offset(21 * s, 22 * s), paint);
    // Slash /
    canvas.drawLine(Offset(19 * s, 9 * s), Offset(13 * s, 23 * s), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

- [ ] **Step 6: Run flutter analyze**

```bash
flutter analyze lib/features/onboarding/onboarding_screen.dart
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/onboarding/onboarding_screen.dart
git commit -m "feat: teal onboarding panel — </> glyph, atmospheric gradient, teal feature cards"
```

---

## Task 12: Step progress indicator

**Files:**
- Modify: `lib/features/onboarding/widgets/step_progress_indicator.dart`

Single change: `blueAccent` → `accent` (now carries the teal value after Task 1, but the reference should be semantic).

- [ ] **Step 1: Update dot colours**

Find:
```dart
            dotColor = ThemeConstants.blueAccent; // completed
```
Change to:
```dart
            dotColor = ThemeConstants.accent; // completed
```

Find:
```dart
            dotColor = ThemeConstants.blueAccent.withValues(alpha: 0.5); // current
```
Change to:
```dart
            dotColor = ThemeConstants.accent.withValues(alpha: 0.45); // current
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/onboarding/widgets/step_progress_indicator.dart
git commit -m "feat: step progress dots — blueAccent → accent"
```

---

## Task 13: Settings nav + layout + dividers

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/settings/general_screen.dart`
- Modify: `lib/features/settings/providers_screen.dart`

- [ ] **Step 1: Fix Row crossAxisAlignment in SettingsScreen**

In `_SettingsScreenState.build()`, find:
```dart
      body: Row(
        children: [
```
Change to:
```dart
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
```

- [ ] **Step 2: Update _NavItem active state**

Find the entire `_NavItem.build()` return statement and replace:

```dart
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ThemeConstants.inputSurface : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? ThemeConstants.textPrimary : ThemeConstants.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
```

with:

```dart
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: isActive ? 14 : 16,
          right: 16,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? ThemeConstants.selectionBg : null,
          border: isActive
              ? const Border(left: BorderSide(color: ThemeConstants.accent, width: 2))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? ThemeConstants.accent : ThemeConstants.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
```

- [ ] **Step 3: Add section dividers to GeneralScreen**

In `general_screen.dart`, before each `SectionLabel` that is not the first (`SectionLabel('General')`), replace the preceding `SizedBox(height: 24)` with a `Divider`:

```dart
          const Divider(height: 36, thickness: 1, color: ThemeConstants.borderColor),
          SectionLabel('About'),
```

Apply the same pattern before any other non-first `SectionLabel` in the file (e.g. `'Debug'` if present — read the file to confirm).

- [ ] **Step 4: Add section dividers to ProvidersScreen**

In `providers_screen.dart`, before `SectionLabel('Ollama (Local)')` find the preceding `SizedBox(height: 16)` and replace with:
```dart
          const Divider(height: 36, thickness: 1, color: ThemeConstants.borderColor),
```

Before `SectionLabel('Custom Endpoint (OpenAI-compatible)')` do the same.

- [ ] **Step 5: Run flutter analyze**

```bash
flutter analyze lib/features/settings/
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/settings_screen.dart \
        lib/features/settings/general_screen.dart \
        lib/features/settings/providers_screen.dart
git commit -m "feat: settings — teal active nav, stretch layout fix, section dividers"
```

---

## Task 14: Blue token audit

**Files:**
- Modify: `lib/features/chat/widgets/ask_user_question_card.dart`
- Review (no code change expected): `lib/features/chat/widgets/work_log_section.dart`, `lib/features/chat/widgets/tool_call_row.dart`, `lib/shell/widgets/working_pill.dart`

After Task 1, `blueAccent`, `selectionBg`, `selectionBorder`, and `questionCardBg` already carry teal values. This task verifies correctness and fixes the one known contrast issue.

- [ ] **Step 1: Verify work_log_section.dart, tool_call_row.dart, working_pill.dart**

```bash
flutter analyze lib/features/chat/widgets/work_log_section.dart \
               lib/features/chat/widgets/tool_call_row.dart \
               lib/shell/widgets/working_pill.dart
```

No source changes expected. The `blueAccent` spinners and labels are now teal via Task 1.

- [ ] **Step 2: Fix ask_user_question_card.dart button foreground**

Open `lib/features/chat/widgets/ask_user_question_card.dart`.

Find lines ~134 and ~143 where `backgroundColor: ThemeConstants.blueAccent` appears (these are now `#4EC9B0` — light teal that needs dark text). For each, add a matching `foregroundColor`:

```dart
backgroundColor: ThemeConstants.blueAccent,
foregroundColor: const Color(0xFF0A0A0A),  // add this line
```

If the buttons use `ButtonStyle` via `WidgetStateProperty`, instead:
```dart
backgroundColor: const WidgetStatePropertyAll(ThemeConstants.blueAccent),
foregroundColor: const WidgetStatePropertyAll(Color(0xFF0A0A0A)),  // add
```

Read the actual widget type in the file to determine the exact call pattern.

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/features/chat/widgets/ask_user_question_card.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/widgets/ask_user_question_card.dart
git commit -m "feat: blue token audit — near-black foreground on teal button backgrounds"
```

---

## Task 15: App icon generation

**Files:**
- Create: `test/tool/generate_icon_test.dart`
- Create (generated output): `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{16,32,64,128,256,512,1024}.png`

Uses `dart:ui` canvas rendering + the `image` package for downsampling to each required size.

- [ ] **Step 1: Verify image package is in dev_dependencies**

Check `pubspec.yaml` for `image:` under `dev_dependencies`. If absent, add:
```yaml
dev_dependencies:
  image: ^4.5.0
```
Then run:
```bash
flutter pub get
```

- [ ] **Step 2: Create the generator test**

Create `test/tool/generate_icon_test.dart`:

```dart
// Run with: flutter test test/tool/generate_icon_test.dart
// Writes 7 PNG files to macos/Runner/Assets.xcassets/AppIcon.appiconset/

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('generate app icon PNGs', () async {
    final master = await _render1024();
    const outDir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';

    for (final size in [16, 32, 64, 128, 256, 512, 1024]) {
      final output = size == 1024
          ? master
          : img.copyResize(
              master,
              width: size,
              height: size,
              interpolation: img.Interpolation.lanczos,
            );
      await File('$outDir/app_icon_$size.png').writeAsBytes(img.encodePng(output));
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

/// Renders the 1024×1024 master icon using dart:ui.
Future<img.Image> _render1024() async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Dark rounded-square background
  final bgPaint = ui.Paint()..color = const ui.Color(0xFF111111);
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, size, size),
      const ui.Radius.circular(224), // ~22% of 1024
    ),
    bgPaint,
  );

  // Subtle top-left highlight
  final gradPaint = ui.Paint()
    ..shader = ui.Gradient.linear(
      ui.Offset.zero,
      ui.Offset(size, size),
      [const ui.Color(0x22FFFFFF), const ui.Color(0x00000000)],
    );
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, size, size),
      const ui.Radius.circular(224),
    ),
    gradPaint,
  );

  // </> glyph — coordinates from 32-unit viewport scaled ×32
  const s = 32.0;
  final glyphPaint = ui.Paint()
    ..color = const ui.Color(0xFF4EC9B0)
    ..strokeWidth = 2.2 * s
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke;

  canvas.drawLine(ui.Offset(5 * s, 16 * s), ui.Offset(11 * s, 10 * s), glyphPaint);
  canvas.drawLine(ui.Offset(5 * s, 16 * s), ui.Offset(11 * s, 22 * s), glyphPaint);
  canvas.drawLine(ui.Offset(27 * s, 16 * s), ui.Offset(21 * s, 10 * s), glyphPaint);
  canvas.drawLine(ui.Offset(27 * s, 16 * s), ui.Offset(21 * s, 22 * s), glyphPaint);
  canvas.drawLine(ui.Offset(19 * s, 9 * s), ui.Offset(13 * s, 23 * s), glyphPaint);

  final picture = recorder.endRecording();
  final uiImage = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) throw StateError('canvas toByteData returned null');

  return img.Image.fromBytes(
    width: size.toInt(),
    height: size.toInt(),
    bytes: byteData.buffer,
    format: img.Format.uint8,
    numChannels: 4,
  );
}
```

- [ ] **Step 3: Run the generator**

```bash
flutter test test/tool/generate_icon_test.dart --reporter expanded
```

Expected: test passes, 7 PNG files written.

- [ ] **Step 4: Verify output**

```bash
ls -lh macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png
```

Expected: 7 files. The 1024px file should be ≥30 KB.

- [ ] **Step 5: Commit**

```bash
dart format lib/ test/
git add test/tool/generate_icon_test.dart \
        macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png
git commit -m "feat: generate </> app icon — 7 PNG sizes"
```

---

## Final verification checklist

- [ ] `dart format lib/ test/`
- [ ] `flutter analyze` — zero issues
- [ ] `flutter test` — all pass
- [ ] `flutter run -d macos` — verify manually:
  - Action bar shows Commit (teal split, dark text) + Push (ghost + cloud icon) + PR (ghost + fork icon)
  - Send button: teal rounded square with dark arrow when text present; grey border when empty; dark-green with pulsing stop square while streaming
  - Commit dialog: frosted surface, icon badge, staged file list with M/A/D/R badges
  - Create PR dialog: frosted surface, fork icon badge
  - Onboarding: `</>` logo mark, teal glow, teal feature cards, teal progress dots
  - Settings: teal 2px left-border on active nav item, no light-grey strips at top/bottom of window, section dividers between setting groups
  - App icon: appears in macOS Dock and About window
