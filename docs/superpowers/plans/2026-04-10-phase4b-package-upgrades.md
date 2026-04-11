# Phase 4b — Package Upgrades Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade all dependencies to their latest compatible versions, migrating breaking API changes in each major-version package.

**Architecture:** Upgrades are sequenced from lowest to highest risk. Each task upgrades one package group, runs `flutter analyze` and `flutter test`, and commits. If `build_runner` regenerates code, generated files are formatted and committed alongside their source files. Tasks are independent — if one package has insurmountable conflicts, it can be deferred without blocking others.

**Tech Stack:** Flutter/Dart, pub.dev, `dart pub upgrade`, `dart run build_runner build`

**Important:** Before starting, ensure all changes from `2026-04-10-phase4a-code-quality-refactoring.md` are committed. This plan assumes `AppIcons` exists (Task 2 of that plan), which simplifies the `lucide_icons_flutter` upgrade step.

---

## Risk matrix

| Package | Current | Target | Risk | Breaking changes expected |
|---------|---------|--------|------|--------------------------|
| `cupertino_icons` | 1.0.8 | 1.0.9 | Low | Icon additions only |
| `shared_preferences` | 2.3.3 | 2.5.5 | Low | None expected |
| `mockito` | 5.4.4 | 5.6.4 | Low | None expected |
| `window_manager` | 0.4.2 | 0.5.1 | Low | Minor API additions |
| `re_editor` | 0.4.0 | 0.8.0 | Medium | Check widget API changes |
| `lucide_icons_flutter` | 1.0.0 | 3.1.12 | Medium | Icon name renames; isolated to `AppIcons` |
| `google_fonts` | 6.2.1 | 8.0.2 | Medium | API broadly stable |
| `flutter_secure_storage` | 9.2.2 | 10.0.0 | Medium | Platform initializer may change |
| `flutter_web_auth_2` | 4.0.1 | 5.0.1 | Medium | Auth flow API changes |
| `file_picker` | 8.1.2 | 11.0.2 | Medium | Return type API changed |
| `intl` | 0.19.0 | 0.20.2 | Low | DateFormat API stable |
| `drift` | 2.21.0 | 2.32.1 | Medium | Query builder additions; check deprecated APIs |
| `json_annotation` | 4.9.0 | 4.11.0 | Low | Additive |
| `freezed_annotation` + `freezed` | 2.4.4 / 2.5.7 | 3.1.0 / 3.2.5 | High | Syntax changes in `@freezed` classes |
| `go_router` | 14.6.2 | 17.2.0 | High | Route builder API changes |
| `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` | 2.6.1 / 2.3.5 / 2.4.3 | 3.3.1 / 4.0.2 / 4.0.3 | High | Major codegen + provider API changes |

---

## Files: Modified

- `pubspec.yaml` — version constraints updated across all tasks
- Generated files (`*.g.dart`, `*.freezed.dart`) — regenerated after freezed/riverpod upgrades
- Various source files — API migration fixes per package

---

## Task 1: Low-risk patch and minor upgrades

**Packages:** `cupertino_icons`, `shared_preferences`, `mockito`, `intl`, `json_annotation`

- [ ] **Step 1: Update `pubspec.yaml` constraints**

```yaml
# dependencies:
cupertino_icons: ^1.0.9
shared_preferences: ^2.5.5
intl: ^0.20.2
json_annotation: ^4.11.0

# dev_dependencies:
mockito: ^5.6.4
```

- [ ] **Step 2: Run pub get**

```bash
dart pub get
```

Expected: resolves cleanly with no conflicts.

- [ ] **Step 3: Analyze and test**

```bash
flutter analyze
flutter test
```

Expected: no issues, all tests pass. These packages have no breaking changes in their minor versions.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: upgrade cupertino_icons, shared_preferences, mockito, intl, json_annotation"
```

---

## Task 2: window_manager upgrade

**Package:** `window_manager` 0.4.2 → 0.5.1

- [ ] **Step 1: Read the migration notes**

Open in browser: https://pub.dev/packages/window_manager/changelog

Look for breaking changes between 0.4.x and 0.5.x. If there are none relevant to our usage, proceed.

Our usage is in `lib/main.dart`:
```dart
await windowManager.ensureInitialized();
await windowManager.waitUntilReadyToShow(WindowOptions(...), () async {
  await windowManager.show();
  await windowManager.focus();
});
```

- [ ] **Step 2: Update `pubspec.yaml`**

```yaml
window_manager: ^0.5.1
```

- [ ] **Step 3: Run pub get, analyze, test**

```bash
dart pub get
flutter analyze
flutter test
```

Expected: no issues. If `windowManager.waitUntilReadyToShow` signature changed, fix it in `lib/main.dart` per the changelog.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "chore: upgrade window_manager to 0.5.1"
```

---

## Task 3: lucide_icons_flutter upgrade

**Package:** `lucide_icons_flutter` 1.0.0 → 3.1.12

**Important:** This task requires the `AppIcons` constants file from the Phase 4a plan (Task 2 of that plan). If `AppIcons` is in place, only `lib/core/constants/app_icons.dart` needs updating.

- [ ] **Step 1: Read the changelog for renamed icons**

Open: https://pub.dev/packages/lucide_icons_flutter/changelog

Look for any icons we use that were renamed between 1.0 and 3.1. Our full icon list (in `AppIcons`):
- `chevronDown`, `chevronUp`, `chevronRight`
- `arrowLeft`, `arrowRight`, `arrowUp`, `arrowUpDown`
- `plus`, `x`, `trash2`, `undo2`, `check`, `copy`, `play`, `download`, `hourglass`
- `eye`, `eyeOff`, `lock`
- `code`, `folder`, `archive`, `archiveRestore`, `hardDrive`, `pencil`
- `messageSquare`, `messageSquarePlus`, `zap`
- `gitMerge`, `gitCommitHorizontal`, `gitCompare`, `gitBranch`
- `settings`

Note any renames. Lucide frequently renames icons across major versions (e.g., `gitCommitHorizontal` may become `gitCommit`).

- [ ] **Step 2: Update `pubspec.yaml`**

```yaml
lucide_icons_flutter: ^3.1.12
```

- [ ] **Step 3: Run pub get**

```bash
dart pub get
```

- [ ] **Step 4: Analyze — fix any missing icon errors**

```bash
flutter analyze
```

All errors will be in `lib/core/constants/app_icons.dart` only. For each `LucideIcons.xxx` that no longer exists, find the new name from the changelog and update the value in `AppIcons`.

Example fix if `gitCommitHorizontal` was renamed to `gitCommit`:
```dart
// old
static const IconData gitCommit = LucideIcons.gitCommitHorizontal;
// new
static const IconData gitCommit = LucideIcons.gitCommit;
```

The semantic `AppIcons.gitCommit` name stays the same — no other files need changing.

- [ ] **Step 5: Run tests**

```bash
flutter test
```

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/constants/app_icons.dart
git commit -m "chore: upgrade lucide_icons_flutter to 3.1.12, fix renamed icons in AppIcons"
```

---

## Task 4: google_fonts upgrade

**Package:** `google_fonts` 6.2.1 → 8.0.2

- [ ] **Step 1: Check usage in codebase**

```bash
grep -rn "GoogleFonts" lib/ --include="*.dart"
```

Note every call site. Common patterns: `GoogleFonts.inter()`, `GoogleFonts.jetBrainsMono()`, `GoogleFonts.asTextTheme()`.

- [ ] **Step 2: Read changelog**

Open: https://pub.dev/packages/google_fonts/changelog

Look for breaking changes between 6.x and 8.x. The primary API (`GoogleFonts.xxx()`) has been stable, but `asTextTheme` parameters changed in some versions.

- [ ] **Step 3: Update `pubspec.yaml`**

```yaml
google_fonts: ^8.0.2
```

- [ ] **Step 4: Run pub get, analyze, fix, test**

```bash
dart pub get
flutter analyze
```

Fix any compilation errors per the changelog. Run:
```bash
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
# plus any modified lib files
git commit -m "chore: upgrade google_fonts to 8.0.2"
```

---

## Task 5: flutter_secure_storage upgrade

**Package:** `flutter_secure_storage` 9.2.2 → 10.0.0

- [ ] **Step 1: Check usage**

```bash
grep -rn "FlutterSecureStorage\|secureStorage\|flutter_secure_storage" lib/ --include="*.dart"
```

Note which files use it and what methods are called (typically `read`, `write`, `delete`, `readAll`).

- [ ] **Step 2: Read migration guide**

Open: https://pub.dev/packages/flutter_secure_storage/changelog

In 10.0.0 the macOS/iOS backend initializer may require explicit platform setup. Check if an `AndroidOptions`, `IOSOptions`, or `MacOsOptions` constructor argument changed.

- [ ] **Step 3: Update `pubspec.yaml`**

```yaml
flutter_secure_storage: ^10.0.0
```

- [ ] **Step 4: Run pub get, analyze, fix**

```bash
dart pub get
flutter analyze
```

Common fix: if `FlutterSecureStorage()` constructor options changed, update call sites.

```bash
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
# plus any modified lib files
git commit -m "chore: upgrade flutter_secure_storage to 10.0.0"
```

---

## Task 6: flutter_web_auth_2 upgrade

**Package:** `flutter_web_auth_2` 4.0.1 → 5.0.1

- [ ] **Step 1: Check usage**

```bash
grep -rn "FlutterWebAuth2\|authenticate\|flutter_web_auth_2" lib/ --include="*.dart"
```

The primary call site is `lib/services/github/github_auth_service.dart`.

- [ ] **Step 2: Read changelog**

Open: https://pub.dev/packages/flutter_web_auth_2/changelog

In v5 the `authenticate` method signature may have changed (callback scheme handling). Check the `callbackUrlScheme` parameter.

- [ ] **Step 3: Update `pubspec.yaml`**

```yaml
flutter_web_auth_2: ^5.0.1
```

- [ ] **Step 4: Run pub get, analyze, fix**

```bash
dart pub get
flutter analyze
```

Fix any API changes in `lib/services/github/github_auth_service.dart`.

```bash
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/github/github_auth_service.dart
git commit -m "chore: upgrade flutter_web_auth_2 to 5.0.1"
```

---

## Task 7: file_picker upgrade

**Package:** `file_picker` 8.1.2 → 11.0.2

This is a 3-major-version jump. The API changed significantly.

- [ ] **Step 1: Check usage**

```bash
grep -rn "FilePicker\|pickFiles\|file_picker" lib/ --include="*.dart"
```

In version 8.x the return type of `FilePicker.platform.pickFiles()` is `FilePickerResult?` with a `.files` list of `PlatformFile`. In v9–11, check if this changed.

- [ ] **Step 2: Read changelog**

Open: https://pub.dev/packages/file_picker/changelog

Focus on changes between 8.x and 11.x. Look for changes to `pickFiles`, `PlatformFile.path`, `FileType`, and `withData` parameter.

- [ ] **Step 3: Update `pubspec.yaml`**

```yaml
file_picker: ^11.0.2
```

- [ ] **Step 4: Run pub get, analyze, fix**

```bash
dart pub get
flutter analyze
```

Fix each call site. Common migration: `FilePickerResult.files.first.path` API is stable but platform-specific initializations may differ.

```bash
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
# plus any modified lib files
git commit -m "chore: upgrade file_picker to 11.0.2, migrate API changes"
```

---

## Task 8: re_editor upgrade

**Package:** `re_editor` 0.4.0 → 0.8.0

- [ ] **Step 1: Check usage**

```bash
grep -rn "CodeEditor\|CodeLineEditingController\|CodeHighlighter\|re_editor" lib/ --include="*.dart"
```

- [ ] **Step 2: Read changelog**

Open: https://pub.dev/packages/re_editor/changelog

Look for changes to `CodeEditor` widget constructor parameters and `CodeLineEditingController` API.

- [ ] **Step 3: Update `pubspec.yaml`**

```yaml
re_editor: ^0.8.0
```

- [ ] **Step 4: Run pub get, analyze, fix, test**

```bash
dart pub get
flutter analyze
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
# plus any modified lib files
git commit -m "chore: upgrade re_editor to 0.8.0"
```

---

## Task 9: Drift upgrade

**Packages:** `drift` 2.21.0 → 2.32.1, `drift_flutter` 0.2.1 → 0.3.0, `drift_dev` 2.21.0 → 2.32.1

- [ ] **Step 1: Read drift migration guide**

Open: https://drift.simonbinder.eu/migrations/

Check for any breaking changes in query builder, table definitions, or `DriftDatabase` class between 2.21 and 2.32.

- [ ] **Step 2: Update `pubspec.yaml`**

```yaml
# dependencies:
drift: ^2.32.1
drift_flutter: ^0.3.0

# dev_dependencies:
drift_dev: ^2.32.1
```

- [ ] **Step 3: Run pub get**

```bash
dart pub get
```

- [ ] **Step 4: Regenerate database code**

```bash
dart format lib/
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Analyze and fix**

```bash
flutter analyze
```

Common drift 2.x changes: deprecated `customSelect` → `customSelectQuery`, database accessor changes. Fix per the migration guide.

- [ ] **Step 6: Run tests**

```bash
flutter test
```

- [ ] **Step 7: Format generated files and commit**

```bash
dart format lib/data/datasources/local/
git add pubspec.yaml pubspec.lock lib/data/datasources/local/app_database.dart lib/data/datasources/local/app_database.g.dart lib/data/datasources/local/general_preferences.dart lib/data/datasources/local/general_preferences.g.dart lib/data/datasources/local/onboarding_preferences.dart lib/data/datasources/local/onboarding_preferences.g.dart lib/data/datasources/local/secure_storage_source.dart lib/data/datasources/local/secure_storage_source.g.dart
git commit -m "chore: upgrade drift to 2.32.1, regenerate database code"
```

---

## Task 10: Freezed upgrade (high risk)

**Packages:** `freezed_annotation` 2.4.4 → 3.1.0, `freezed` 2.5.7 → 3.2.5, `json_serializable` 6.8.0 → 6.13.0, `build_runner` 2.4.13 → 2.13.1

Freezed 3.x changed how `@freezed` classes are declared (the mixin changed from `_$ClassName` to a different pattern). All `.freezed.dart` and `.g.dart` files need regeneration.

- [ ] **Step 1: Read the freezed migration guide**

Open: https://pub.dev/packages/freezed/changelog

Key things to check:
- Did the `part` directive format change?
- Did the `@freezed` / `@unfreezed` annotation API change?
- Did `copyWith`, `when`, `map`, `maybeWhen` signatures change?

- [ ] **Step 2: List all freezed models**

```bash
grep -rn "@freezed\|@Freezed" lib/ --include="*.dart" -l
```

Expected files:
- `lib/data/models/ai_model.dart`
- `lib/data/models/chat_message.dart`
- `lib/data/models/chat_session.dart`
- `lib/data/models/project.dart`
- `lib/data/models/repository.dart`
- `lib/data/models/workspace_project.dart`
- `lib/data/models/applied_change.dart`

- [ ] **Step 3: Update `pubspec.yaml`**

```yaml
# dependencies:
freezed_annotation: ^3.1.0

# dev_dependencies:
freezed: ^3.2.5
json_serializable: ^6.13.0
build_runner: ^2.13.1
```

- [ ] **Step 4: Run pub get**

```bash
dart pub get
```

- [ ] **Step 5: Apply source-level changes required by freezed 3.x**

Per the freezed 3.x changelog, if the mixin declaration format changed, update each `@freezed` class. The typical change (if any) is in the class declaration line:

```dart
// freezed 2.x
@freezed
class MyModel with _$MyModel {
  const factory MyModel({...}) = _MyModel;
}

// freezed 3.x (check the changelog — may be unchanged or may require a new pattern)
```

Update each of the 7 model files if required.

- [ ] **Step 6: Delete old generated files**

```bash
find lib -name "*.freezed.dart" -delete
find lib -name "*.g.dart" ! -path "*/datasources/*" -delete
```

- [ ] **Step 7: Regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: all `.freezed.dart` and `.g.dart` files regenerated with no errors.

- [ ] **Step 8: Analyze and fix**

```bash
flutter analyze
```

If `when`/`map` pattern exhaustiveness changed, fix call sites. Common: new union cases require new `when` branches.

- [ ] **Step 9: Run tests**

```bash
flutter test
```

- [ ] **Step 10: Format and commit**

```bash
dart format lib/data/models/ lib/data/datasources/
git add pubspec.yaml pubspec.lock lib/data/models/ lib/data/datasources/
git commit -m "chore: upgrade freezed to 3.x, build_runner to 2.13, regenerate all models"
```

---

## Task 11: Riverpod upgrade (highest risk)

**Packages:** `flutter_riverpod` 2.6.1 → 3.3.1, `riverpod_annotation` 2.3.5 → 4.0.2, `riverpod_generator` 2.4.3 → 4.0.3

Riverpod 3.x changes the public API and codegen format. Every `@riverpod`-annotated function and the generated `.g.dart` files need to be checked.

- [ ] **Step 1: Read the Riverpod 3.x migration guide**

Open: https://riverpod.dev/docs/migration/from_v2

Critical changes to look for:
- `AsyncNotifier` / `Notifier` class API changes
- `ref.listen` / `ref.watch` behavior changes
- Codegen annotation changes (`@riverpod` function → class style if changed)
- `ProviderContainer` API changes (affects tests)
- `ConsumerWidget` API (likely unchanged)

- [ ] **Step 2: List all Riverpod providers**

```bash
grep -rn "@riverpod\|@Riverpod" lib/ --include="*.dart" -l
```

Expected files:
- `lib/services/filesystem/filesystem_service.dart`
- `lib/services/github/github_api_service.dart`
- `lib/services/github/github_auth_service.dart`
- `lib/services/project/project_service.dart`
- `lib/services/session/session_service.dart`
- `lib/services/apply/apply_service.dart`
- `lib/services/ai/ai_service_factory.dart`
- `lib/features/chat/chat_notifier.dart`
- `lib/features/project_sidebar/project_sidebar_notifier.dart`
- `lib/data/datasources/local/onboarding_preferences.dart`
- `lib/data/datasources/local/general_preferences.dart`
- `lib/data/datasources/local/secure_storage_source.dart`

- [ ] **Step 3: Update `pubspec.yaml`**

```yaml
# dependencies:
flutter_riverpod: ^3.3.1
riverpod_annotation: ^4.0.2

# dev_dependencies:
riverpod_generator: ^4.0.3
```

- [ ] **Step 4: Run pub get**

```bash
dart pub get
```

- [ ] **Step 5: Delete old Riverpod generated files**

```bash
find lib -name "*.g.dart" -delete
```

- [ ] **Step 6: Regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

If the codegen syntax changed (function-based → class-based), `build_runner` will produce errors. Fix each annotated provider per the migration guide before re-running.

- [ ] **Step 7: Analyze and fix**

```bash
flutter analyze
```

Typical breaking changes:
- If `ref.read(someProvider.notifier).method()` pattern changed
- If `AsyncValue.when` added required parameters
- If `ProviderContainer` constructor changed (affects tests)

Fix each error. For test files using `ProviderContainer`, check if `overrideWith` signature changed.

- [ ] **Step 8: Run tests**

```bash
flutter test
```

Fix any test failures caused by Riverpod API changes (likely in `ProviderContainer` usage and `overrideWith` calls in test helpers).

- [ ] **Step 9: Format and commit**

```bash
dart format lib/ test/
git add pubspec.yaml pubspec.lock lib/ test/
git commit -m "chore: upgrade flutter_riverpod to 3.x, regenerate all providers"
```

---

## Task 12: go_router upgrade

**Package:** `go_router` 14.6.2 → 17.2.0

- [ ] **Step 1: Read the migration guide**

Open: https://pub.dev/packages/go_router/changelog

Check for changes between 14.x and 17.x, focusing on:
- `GoRoute` constructor changes
- `ShellRoute` / `StatefulShellRoute` API
- `GoRouter` constructor (especially `initialLocation`, `redirect`, `routes`)
- `GoRouterState` properties

Our router is in `lib/router/app_router.dart`.

- [ ] **Step 2: Update `pubspec.yaml`**

```yaml
go_router: ^17.2.0
```

- [ ] **Step 3: Run pub get**

```bash
dart pub get
```

- [ ] **Step 4: Regenerate router (if using @TypedGoRoute)**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Analyze and fix**

```bash
flutter analyze
```

Fix each error in `lib/router/app_router.dart` and `lib/router/app_router.g.dart` per the changelog.

- [ ] **Step 6: Run tests**

```bash
flutter test
```

- [ ] **Step 7: Format and commit**

```bash
dart format lib/router/
git add pubspec.yaml pubspec.lock lib/router/app_router.dart lib/router/app_router.g.dart
git commit -m "chore: upgrade go_router to 17.x, fix routing API changes"
```

---

## Post-upgrade checklist

- [ ] **Run full test suite one final time**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Run flutter analyze**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Build the app**

```bash
flutter build macos
```

Expected: builds successfully with no warnings.

- [ ] **Smoke test the app manually**

- Launch the app
- Open a project, start a chat session
- Send a message and confirm AI response renders
- Apply a code change and confirm changes panel works
- Open Settings, verify all tabs load
- Archive a session, restore it
- Confirm GitHub auth flow launches (if connected)
