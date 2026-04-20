# Configurable Coding-Tools Denylist Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the four hardcoded denylist constants in `CodingToolsService` (`_deniedSegments`, `_deniedFilenames`, `_deniedExtensions`, `_deniedFilenamePrefixes`) with a user-configurable denylist surfaced in a new `Coding Tools` tab under Settings. Users can extend or suppress the baseline with a tri-state model (baseline / user-added / user-suppressed), with per-category and global "Restore defaults" actions.

**Architecture:** Keep today's runtime behavior (refuse on direct access, silent filter in `list_dir`). Move the baseline constants out of the service into `lib/data/coding_tools/models/denylist_defaults.dart` so both runtime and UI read from one source. Effective denylist = `(baseline \ suppressed) ∪ userAdded`, computed per-category by a new `CodingToolsDenylistRepository` backed by `SharedPreferences` (JSON blob). `CodingToolsService` awaits `repo.effective()` at the top of `execute()` and threads the resolved sets into `_assertNotDenied` / `_isDeniedRel`. A new `features/coding_tools/` feature folder hosts the screen, notifiers, and widgets; existing `SettingsGroup` / `SectionLabel` / `AppDialog` patterns are reused. A new `_SettingsNav.codingTools` tab joins the Settings left nav, and the existing "↺ Restore defaults" button becomes context-aware (per active tab).

**Tech Stack:** Flutter/Dart, Riverpod (`riverpod_annotation`, `build_runner`), Freezed, `SharedPreferences`, existing `AppDialog` / `AppSnackBar` / `AppTextField` / `AppIcons`.

**Key invariants:**

- The service layer never reads `SharedPreferences` directly — only the repository does.
- Baseline defaults are a `const` in `denylist_defaults.dart`; UI and runtime share one source.
- Storage persists only *divergence from baseline* (userAdded + suppressedDefaults). Baseline changes in future app versions propagate automatically.
- Removing a user-added entry = plain delete; suppressing a baseline entry = `AppDialog.destructive` confirm.
- The existing refuse-on-direct / silent-filter-in-`list_dir` split is preserved. No per-entry behavior config.
- Scope is global (user-wide). No per-project denylist today.

---

## File map

| Action | File |
|--------|------|
| Create | `lib/data/coding_tools/models/denylist_category.dart` |
| Create | `lib/data/coding_tools/models/denylist_defaults.dart` |
| Create | `lib/data/coding_tools/models/coding_tools_denylist_state.dart` |
| Create | `lib/data/_core/preferences/coding_tools_preferences.dart` |
| Create | `lib/data/coding_tools/repository/coding_tools_denylist_repository.dart` |
| Create | `lib/data/coding_tools/repository/coding_tools_denylist_repository_impl.dart` |
| Create | `lib/features/coding_tools/coding_tools_screen.dart` |
| Create | `lib/features/coding_tools/notifiers/coding_tools_denylist_notifier.dart` |
| Create | `lib/features/coding_tools/notifiers/coding_tools_denylist_actions.dart` |
| Create | `lib/features/coding_tools/notifiers/coding_tools_denylist_failure.dart` |
| Create | `lib/features/coding_tools/widgets/denylist_chip.dart` |
| Create | `lib/features/coding_tools/widgets/denylist_category_group.dart` |
| Modify | `lib/services/coding_tools/coding_tools_service.dart` |
| Modify | `lib/features/settings/settings_screen.dart` |
| Create | `test/data/coding_tools/repository/coding_tools_denylist_repository_test.dart` |
| Modify | `test/services/coding_tools/coding_tools_service_test.dart` |
| Create | `test/features/coding_tools/notifiers/coding_tools_denylist_notifier_test.dart` |
| Create | `test/features/coding_tools/notifiers/coding_tools_denylist_actions_test.dart` |
| Create | `test/arch/coding_tools_denylist_arch_test.dart` (optional; skip if no existing arch pattern applies) |

---

**Worktree setup (required before starting):**

```bash
git worktree add .worktrees/feat/2026-04-21-configurable-coding-tools-denylist -b feat/2026-04-21-configurable-coding-tools-denylist
cd .worktrees/feat/2026-04-21-configurable-coding-tools-denylist
```

All work happens inside this worktree.

---

## Task 1: Model layer — `DenylistCategory` enum, baseline constants, state freezed class

**Goal:** Introduce a typed domain model for the denylist. Move the four hardcoded sets out of `coding_tools_service.dart` into a single `denylist_defaults.dart` file so both UI and runtime consume the same source. Introduce a freezed `CodingToolsDenylistState` that captures user divergence (userAdded + suppressedDefaults, keyed by category).

**Files:**

- Create: `lib/data/coding_tools/models/denylist_category.dart`
- Create: `lib/data/coding_tools/models/denylist_defaults.dart`
- Create: `lib/data/coding_tools/models/coding_tools_denylist_state.dart`

**Steps:**

- [ ] **Step 1: Create the enum**

  `lib/data/coding_tools/models/denylist_category.dart`:

  ```dart
  /// The four match categories used by the coding-tools path guard.
  /// Order matches the order they appear in the Settings UI (top → bottom).
  enum DenylistCategory {
    /// Matches a whole path segment (case-insensitive). Covers entire
    /// directory trees, e.g. `.git`, `.ssh`.
    segment,

    /// Exact filename match (case-insensitive) at any depth. E.g. `.env`.
    filename,

    /// Trailing extension (case-insensitive). E.g. `.pem`.
    extension,

    /// Filename prefix (case-insensitive). E.g. `.env.` matches
    /// `.env.local`, `.env.production`.
    prefix,
  }
  ```

- [ ] **Step 2: Create the baseline defaults**

  `lib/data/coding_tools/models/denylist_defaults.dart`:

  ```dart
  import 'denylist_category.dart';

  /// Baseline denylist shipped with the app. UI surfaces these with a
  /// "default" visual style; users can suppress individual entries
  /// but the set itself is immutable and the single source of truth
  /// for both runtime evaluation and the Settings UI.
  class DenylistDefaults {
    DenylistDefaults._();

    static const Set<String> segments = {'.git', '.ssh', '.aws', '.gnupg', '.config'};

    static const Set<String> filenames = {
      '.env', '.netrc', '.npmrc', '.pypirc', '.htpasswd',
      'credentials', 'secrets',
      'id_rsa', 'id_dsa', 'id_ecdsa', 'id_ed25519',
    };

    static const Set<String> extensions = {'.pem', '.key', '.p12', '.pfx', '.jks'};

    static const Set<String> prefixes = {'.env.'};

    static Set<String> forCategory(DenylistCategory category) => switch (category) {
      DenylistCategory.segment => segments,
      DenylistCategory.filename => filenames,
      DenylistCategory.extension => extensions,
      DenylistCategory.prefix => prefixes,
    };
  }
  ```

- [ ] **Step 3: Create the freezed state model**

  `lib/data/coding_tools/models/coding_tools_denylist_state.dart`:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  import 'denylist_category.dart';
  import 'denylist_defaults.dart';

  part 'coding_tools_denylist_state.freezed.dart';

  /// User-owned divergence from the baseline, per category.
  ///   - [userAdded]: entries the user added on top of the baseline.
  ///   - [suppressedDefaults]: baseline entries the user has opted out of.
  ///
  /// Storage persists only divergence — NOT the full effective list. This
  /// keeps baseline changes in future app versions propagating automatically.
  @freezed
  sealed class CodingToolsDenylistState with _$CodingToolsDenylistState {
    const CodingToolsDenylistState._();

    const factory CodingToolsDenylistState({
      required Map<DenylistCategory, Set<String>> userAdded,
      required Map<DenylistCategory, Set<String>> suppressedDefaults,
    }) = _CodingToolsDenylistState;

    /// Empty state — every baseline entry active, no user additions.
    factory CodingToolsDenylistState.empty() => CodingToolsDenylistState(
      userAdded: {for (final c in DenylistCategory.values) c: const <String>{}},
      suppressedDefaults: {for (final c in DenylistCategory.values) c: const <String>{}},
    );

    /// Effective denylist for [category] — baseline minus suppressed,
    /// union user-added, lowercased.
    Set<String> effective(DenylistCategory category) {
      final base = DenylistDefaults.forCategory(category);
      final suppressed = suppressedDefaults[category] ?? const <String>{};
      final added = userAdded[category] ?? const <String>{};
      return {
        for (final v in base) if (!suppressed.contains(v)) v.toLowerCase(),
        for (final v in added) v.toLowerCase(),
      };
    }
  }
  ```

- [ ] **Step 4: Run codegen**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `coding_tools_denylist_state.freezed.dart` is generated. Commit alongside the source file.

- [ ] **Step 5: Verify analyzer passes**

  ```bash
  flutter analyze lib/data/coding_tools/
  ```

  Expected: `No issues found!`

**Commit:**

```
feat(coding-tools): extract denylist baseline + add user-state model

Move the four hardcoded denylist sets out of CodingToolsService into
DenylistDefaults so UI and runtime share one source. Introduce
CodingToolsDenylistState (freezed) that captures user divergence from
baseline via userAdded + suppressedDefaults maps keyed by
DenylistCategory. Runtime rewire and UI land in follow-up commits.
```

---

## Task 2: Preferences layer — `coding_tools_preferences.dart`

**Goal:** Persist `CodingToolsDenylistState` to `SharedPreferences` as a single JSON blob. Follow the one-file-per-concern pattern already in `lib/data/_core/preferences/`.

**Files:**

- Create: `lib/data/_core/preferences/coding_tools_preferences.dart`

**Steps:**

- [ ] **Step 1: Write the preferences class**

  ```dart
  import 'dart:convert';

  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  import '../../coding_tools/models/coding_tools_denylist_state.dart';
  import '../../coding_tools/models/denylist_category.dart';

  part 'coding_tools_preferences.g.dart';

  @Riverpod(keepAlive: true)
  CodingToolsPreferences codingToolsPreferences(Ref ref) => CodingToolsPreferences();

  class CodingToolsPreferences {
    static const _kDenylistState = 'coding_tools_denylist_state_v1';

    Future<CodingToolsDenylistState> getDenylistState() async {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kDenylistState);
      if (raw == null || raw.isEmpty) return CodingToolsDenylistState.empty();
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return _deserialize(decoded);
      } on FormatException {
        return CodingToolsDenylistState.empty();
      }
    }

    Future<void> setDenylistState(CodingToolsDenylistState state) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDenylistState, jsonEncode(_serialize(state)));
    }

    Future<void> clearDenylistState() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kDenylistState);
    }

    // --- Serialization ---

    Map<String, dynamic> _serialize(CodingToolsDenylistState s) => {
      'userAdded': {for (final e in s.userAdded.entries) e.key.name: e.value.toList()},
      'suppressedDefaults': {
        for (final e in s.suppressedDefaults.entries) e.key.name: e.value.toList(),
      },
    };

    CodingToolsDenylistState _deserialize(Map<String, dynamic> json) {
      Map<DenylistCategory, Set<String>> parseMap(Object? raw) {
        final out = <DenylistCategory, Set<String>>{
          for (final c in DenylistCategory.values) c: <String>{},
        };
        if (raw is! Map) return out;
        for (final entry in raw.entries) {
          final cat = DenylistCategory.values.firstWhere(
            (c) => c.name == entry.key,
            orElse: () => DenylistCategory.filename,
          );
          final list = entry.value;
          if (list is! List) continue;
          out[cat] = {for (final v in list) if (v is String && v.isNotEmpty) v};
        }
        return out;
      }

      return CodingToolsDenylistState(
        userAdded: parseMap(json['userAdded']),
        suppressedDefaults: parseMap(json['suppressedDefaults']),
      );
    }
  }
  ```

- [ ] **Step 2: Run codegen**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `coding_tools_preferences.g.dart` generated.

- [ ] **Step 3: Verify analyzer**

  ```bash
  flutter analyze lib/data/_core/preferences/
  ```

**Commit:**

```
feat(coding-tools): add SharedPreferences-backed denylist storage

Persist CodingToolsDenylistState under a single JSON blob key
(coding_tools_denylist_state_v1). Serialization is tolerant of
future-added categories via enum-name matching; falls back to empty
state on FormatException so corrupt prefs don't block the app.
```

---

## Task 3: Repository interface + impl

**Goal:** Wrap the preferences class in a repository that exposes domain-level reads/writes + a fast `effective()` computation. Only the repository talks to `SharedPreferences`.

**Files:**

- Create: `lib/data/coding_tools/repository/coding_tools_denylist_repository.dart`
- Create: `lib/data/coding_tools/repository/coding_tools_denylist_repository_impl.dart`
- Create: `test/data/coding_tools/repository/coding_tools_denylist_repository_test.dart`

**Steps:**

- [ ] **Step 1: Write the interface**

  ```dart
  // coding_tools_denylist_repository.dart
  import '../models/coding_tools_denylist_state.dart';
  import '../models/denylist_category.dart';

  abstract interface class CodingToolsDenylistRepository {
    /// Loaded state (user divergence only — baseline lives in DenylistDefaults).
    Future<CodingToolsDenylistState> load();

    /// Persists [state] and returns it unchanged for chaining.
    Future<CodingToolsDenylistState> save(CodingToolsDenylistState state);

    /// Convenience — effective lowercased set for [category], baseline minus
    /// suppressed union user-added. Cached read is fine at service call sites.
    Future<Set<String>> effective(DenylistCategory category);

    /// Clears all user divergence → state == empty().
    Future<void> restoreAllDefaults();
  }
  ```

- [ ] **Step 2: Write a failing test**

  `test/data/coding_tools/repository/coding_tools_denylist_repository_test.dart`:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:code_bench_app/data/_core/preferences/coding_tools_preferences.dart';
  import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
  import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';

  void main() {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('effective() returns baseline when no user state', () async {
      final repo = CodingToolsDenylistRepositoryImpl(prefs: CodingToolsPreferences());
      final effective = await repo.effective(DenylistCategory.filename);
      expect(effective, contains('.env'));
      expect(effective, contains('credentials'));
    });

    test('user-added entries merge in lowercase', () async {
      final repo = CodingToolsDenylistRepositoryImpl(prefs: CodingToolsPreferences());
      final state = (await repo.load()).copyWith(
        userAdded: {
          DenylistCategory.filename: {'COMPANY_TOKEN'},
          for (final c in DenylistCategory.values)
            if (c != DenylistCategory.filename) c: <String>{},
        },
      );
      await repo.save(state);
      final effective = await repo.effective(DenylistCategory.filename);
      expect(effective, contains('company_token'));
    });

    test('suppressed defaults drop out of effective', () async {
      final repo = CodingToolsDenylistRepositoryImpl(prefs: CodingToolsPreferences());
      final state = (await repo.load()).copyWith(
        suppressedDefaults: {
          DenylistCategory.filename: {'credentials'},
          for (final c in DenylistCategory.values)
            if (c != DenylistCategory.filename) c: <String>{},
        },
      );
      await repo.save(state);
      final effective = await repo.effective(DenylistCategory.filename);
      expect(effective, isNot(contains('credentials')));
      expect(effective, contains('.env'));
    });

    test('restoreAllDefaults clears user divergence', () async {
      final repo = CodingToolsDenylistRepositoryImpl(prefs: CodingToolsPreferences());
      final divergent = (await repo.load()).copyWith(
        userAdded: {
          DenylistCategory.filename: {'custom'},
          for (final c in DenylistCategory.values)
            if (c != DenylistCategory.filename) c: <String>{},
        },
      );
      await repo.save(divergent);
      await repo.restoreAllDefaults();
      final effective = await repo.effective(DenylistCategory.filename);
      expect(effective, isNot(contains('custom')));
      expect(effective, contains('.env'));
    });
  }
  ```

  Run:

  ```bash
  flutter test test/data/coding_tools/repository/coding_tools_denylist_repository_test.dart
  ```

  Expected: FAIL — `CodingToolsDenylistRepositoryImpl` not defined.

- [ ] **Step 3: Write the implementation**

  `coding_tools_denylist_repository_impl.dart`:

  ```dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../_core/preferences/coding_tools_preferences.dart';
  import '../models/coding_tools_denylist_state.dart';
  import '../models/denylist_category.dart';
  import 'coding_tools_denylist_repository.dart';

  part 'coding_tools_denylist_repository_impl.g.dart';

  @Riverpod(keepAlive: true)
  CodingToolsDenylistRepository codingToolsDenylistRepository(Ref ref) =>
      CodingToolsDenylistRepositoryImpl(prefs: ref.read(codingToolsPreferencesProvider));

  class CodingToolsDenylistRepositoryImpl implements CodingToolsDenylistRepository {
    CodingToolsDenylistRepositoryImpl({required CodingToolsPreferences prefs}) : _prefs = prefs;

    final CodingToolsPreferences _prefs;

    @override
    Future<CodingToolsDenylistState> load() => _prefs.getDenylistState();

    @override
    Future<CodingToolsDenylistState> save(CodingToolsDenylistState state) async {
      await _prefs.setDenylistState(state);
      return state;
    }

    @override
    Future<Set<String>> effective(DenylistCategory category) async {
      final state = await _prefs.getDenylistState();
      return state.effective(category);
    }

    @override
    Future<void> restoreAllDefaults() => _prefs.clearDenylistState();
  }
  ```

- [ ] **Step 4: Run codegen + tests**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/data/coding_tools/repository/coding_tools_denylist_repository_test.dart
  ```

  Expected: all 4 tests pass.

- [ ] **Step 5: Verify analyzer**

  ```bash
  flutter analyze lib/data/coding_tools/
  ```

**Commit:**

```
feat(coding-tools): add denylist repository over preferences

Interface + impl for load/save/effective/restoreAllDefaults. The
effective() read is the hot path the service calls each tool
invocation; it composes baseline ∩ !suppressed ∪ userAdded and
lowercases in one pass. Tests cover baseline-only, user-added merge,
suppressed default, and restore.
```

---

## Task 4: Rewire `CodingToolsService` to consume the repository

**Goal:** Replace the four hardcoded sets with a single `await _denylistRepo.effective(category)` call per tool execution. Preserve today's behavior (refuse on direct access, silent filter in `list_dir`). Extend `CodingToolsServiceTest` so user-added entries block and suppressed defaults are allowed.

**Files:**

- Modify: `lib/services/coding_tools/coding_tools_service.dart`
- Modify: `test/services/coding_tools/coding_tools_service_test.dart`

**Steps:**

- [ ] **Step 1: Add failing tests for user-added + suppressed behavior**

  Add the following new test group inside `test/services/coding_tools/coding_tools_service_test.dart`, after the existing `group('read_file', ...)`:

  ```dart
  group('configurable denylist', () {
    test('user-added filename is refused on read_file', () async {
      // Arrange: persist a user-added "custom_secret" filename.
      SharedPreferences.setMockInitialValues({});
      final prefs = CodingToolsPreferences();
      final repo = CodingToolsDenylistRepositoryImpl(prefs: prefs);
      await repo.save(
        (await repo.load()).copyWith(
          userAdded: {
            DenylistCategory.filename: {'custom_secret'},
            for (final c in DenylistCategory.values)
              if (c != DenylistCategory.filename) c: <String>{},
          },
        ),
      );
      final svcWithRepo = CodingToolsService(
        repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()),
        applyService: ApplyService(repo: ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()))),
        denylist: repo,
      );
      File(p.join(projectDir.path, 'custom_secret')).writeAsStringSync('sensitive');
      final r = await svcWithRepo.execute(
        toolName: 'read_file',
        args: {'path': 'custom_secret'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultError>());
      expect((r as CodingToolResultError).message, contains('blocked for safety'));
    });

    test('suppressed baseline filename is allowed on read_file', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = CodingToolsPreferences();
      final repo = CodingToolsDenylistRepositoryImpl(prefs: prefs);
      await repo.save(
        (await repo.load()).copyWith(
          suppressedDefaults: {
            DenylistCategory.filename: {'credentials'},
            for (final c in DenylistCategory.values)
              if (c != DenylistCategory.filename) c: <String>{},
          },
        ),
      );
      final svcWithRepo = CodingToolsService(
        repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()),
        applyService: ApplyService(repo: ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()))),
        denylist: repo,
      );
      File(p.join(projectDir.path, 'credentials')).writeAsStringSync('not-actually-secret');
      final r = await svcWithRepo.execute(
        toolName: 'read_file',
        args: {'path': 'credentials'},
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
      );
      expect(r, isA<CodingToolResultSuccess>());
    });
  });
  ```

  Update the shared `setUp` to pass a default `CodingToolsDenylistRepositoryImpl` (backed by `SharedPreferences.setMockInitialValues({})`) into every existing `svc = CodingToolsService(...)` construction so existing tests still see the baseline.

  Run:

  ```bash
  flutter test test/services/coding_tools/coding_tools_service_test.dart --plain-name "configurable denylist"
  ```

  Expected: FAIL — `CodingToolsService` constructor does not accept `denylist:`.

- [ ] **Step 2: Update the service signature + runtime**

  In `lib/services/coding_tools/coding_tools_service.dart`:

  1. Add constructor param `required CodingToolsDenylistRepository denylist` and store it as `_denylist`.
  2. Delete the four `_denied*` constants.
  3. Change `_assertNotDenied` → `_assertNotDenied(String abs, String projectPath, _EffectiveDenylist denylist)` where `_EffectiveDenylist` is a small private record:

     ```dart
     typedef _EffectiveDenylist = ({
       Set<String> segments,
       Set<String> filenames,
       Set<String> extensions,
       Set<String> prefixes,
     });
     ```
  4. Change `_isDeniedRel` → `_isDeniedRel(String relPath, _EffectiveDenylist denylist)`.
  5. At the top of each of `_readFile` / `_listDir` / `_writeFile` / `_strReplace`, load the effective denylist once:

     ```dart
     final denylist = (
       segments: await _denylist.effective(DenylistCategory.segment),
       filenames: await _denylist.effective(DenylistCategory.filename),
       extensions: await _denylist.effective(DenylistCategory.extension),
       prefixes: await _denylist.effective(DenylistCategory.prefix),
     );
     ```

     Thread `denylist` into the existing `_assertNotDenied` and `_isDeniedRel` call sites.

  6. Update the generator provider:

     ```dart
     @Riverpod(keepAlive: true)
     CodingToolsService codingToolsService(Ref ref) => CodingToolsService(
       repo: ref.watch(codingToolsRepositoryProvider),
       applyService: ref.watch(applyServiceProvider),
       denylist: ref.watch(codingToolsDenylistRepositoryProvider),
     );
     ```

- [ ] **Step 3: Run codegen + tests**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/services/coding_tools/coding_tools_service_test.dart
  ```

  Expected: all tests (old + new) pass.

- [ ] **Step 4: Verify analyzer**

  ```bash
  flutter analyze lib/services/coding_tools/
  ```

**Commit:**

```
feat(coding-tools): make denylist configurable at runtime

Replace the four hardcoded _denied* constants with per-execute reads
from CodingToolsDenylistRepository. Behavior unchanged at baseline:
refuse on direct access, silent-filter in list_dir. User-added
entries now block; user-suppressed baselines now pass through. Tests
extended to cover both paths.
```

---

## Task 5: State notifier — `CodingToolsDenylistNotifier`

**Goal:** Expose the current `CodingToolsDenylistState` to widgets as an `AsyncValue`. Notifier holds state only; command surface lives in the Actions notifier (Task 6).

**Files:**

- Create: `lib/features/coding_tools/notifiers/coding_tools_denylist_notifier.dart`
- Create: `test/features/coding_tools/notifiers/coding_tools_denylist_notifier_test.dart`

**Steps:**

- [ ] **Step 1: Write a failing test**

  ```dart
  // test/features/coding_tools/notifiers/coding_tools_denylist_notifier_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
  import 'package:code_bench_app/features/coding_tools/notifiers/coding_tools_denylist_notifier.dart';

  void main() {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('loads empty state with all baseline defaults available', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = await container.read(codingToolsDenylistProvider.future);
      expect(state.userAdded[DenylistCategory.filename], isEmpty);
      expect(state.suppressedDefaults[DenylistCategory.filename], isEmpty);
    });
  }
  ```

  Run:

  ```bash
  flutter test test/features/coding_tools/notifiers/coding_tools_denylist_notifier_test.dart
  ```

  Expected: FAIL — provider not defined.

- [ ] **Step 2: Implement the notifier**

  ```dart
  // coding_tools_denylist_notifier.dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../../data/coding_tools/models/coding_tools_denylist_state.dart';
  import '../../../data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';

  part 'coding_tools_denylist_notifier.g.dart';

  /// Loads the user's denylist divergence and rebuilds when the Actions
  /// notifier invalidates this provider after a mutation.
  @riverpod
  class CodingToolsDenylistNotifier extends _$CodingToolsDenylistNotifier {
    @override
    Future<CodingToolsDenylistState> build() =>
        ref.read(codingToolsDenylistRepositoryProvider).load();
  }
  ```

  Note the class name is `CodingToolsDenylistNotifier` but the Riverpod generator strips the `Notifier` suffix → provider variable is `codingToolsDenylistProvider` (per the repo's naming convention memory).

- [ ] **Step 3: Run codegen + test**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/features/coding_tools/notifiers/coding_tools_denylist_notifier_test.dart
  ```

  Expected: PASS.

**Commit:**

```
feat(coding-tools): add denylist state notifier

Async state notifier that loads CodingToolsDenylistState via the
repository. Rebuilt on Actions invalidation. Widgets ref.watch this
to render the three chip variants (default/user-added/suppressed).
```

---

## Task 6: Actions notifier + failure union

**Goal:** Command surface the UI drives: `addUserEntry`, `removeUserEntry`, `suppressBaseline`, `restoreBaseline`, `restoreCategory`, `restoreAll`. Each mutation invalidates the state notifier. Typed failure covers validation errors (duplicate / empty input) and storage faults.

**Files:**

- Create: `lib/features/coding_tools/notifiers/coding_tools_denylist_actions.dart`
- Create: `lib/features/coding_tools/notifiers/coding_tools_denylist_failure.dart`
- Create: `test/features/coding_tools/notifiers/coding_tools_denylist_actions_test.dart`

**Steps:**

- [ ] **Step 1: Write the failure union**

  ```dart
  // coding_tools_denylist_failure.dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'coding_tools_denylist_failure.freezed.dart';

  @freezed
  sealed class CodingToolsDenylistFailure with _$CodingToolsDenylistFailure {
    /// Entry text was empty, whitespace only, or matched no legal shape.
    const factory CodingToolsDenylistFailure.invalidEntry() = CodingToolsDenylistInvalidEntry;

    /// Entry is already present (user-added) or is already active (baseline).
    const factory CodingToolsDenylistFailure.duplicate() = CodingToolsDenylistDuplicate;

    /// SharedPreferences write failed.
    const factory CodingToolsDenylistFailure.saveFailed() = CodingToolsDenylistSaveFailed;

    const factory CodingToolsDenylistFailure.unknown(Object error) = CodingToolsDenylistUnknown;
  }
  ```

- [ ] **Step 2: Write failing tests**

  ```dart
  // coding_tools_denylist_actions_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
  import 'package:code_bench_app/features/coding_tools/notifiers/coding_tools_denylist_actions.dart';
  import 'package:code_bench_app/features/coding_tools/notifiers/coding_tools_denylist_failure.dart';
  import 'package:code_bench_app/features/coding_tools/notifiers/coding_tools_denylist_notifier.dart';

  void main() {
    late ProviderContainer c;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      c = ProviderContainer();
      addTearDown(c.dispose);
    });

    test('addUserEntry persists + state reflects it', () async {
      await c.read(codingToolsDenylistProvider.future);
      await c.read(codingToolsDenylistActionsProvider.notifier)
          .addUserEntry(DenylistCategory.filename, 'custom_secret');
      final state = await c.read(codingToolsDenylistProvider.future);
      expect(state.userAdded[DenylistCategory.filename], contains('custom_secret'));
    });

    test('addUserEntry rejects empty input with invalidEntry failure', () async {
      await c.read(codingToolsDenylistActionsProvider.notifier)
          .addUserEntry(DenylistCategory.filename, '  ');
      final err = c.read(codingToolsDenylistActionsProvider).error;
      expect(err, isA<CodingToolsDenylistInvalidEntry>());
    });

    test('suppressBaseline drops the entry from effective', () async {
      await c.read(codingToolsDenylistActionsProvider.notifier)
          .suppressBaseline(DenylistCategory.filename, 'credentials');
      final state = await c.read(codingToolsDenylistProvider.future);
      expect(state.effective(DenylistCategory.filename), isNot(contains('credentials')));
    });

    test('restoreCategory clears both userAdded + suppressedDefaults for one kind', () async {
      await c.read(codingToolsDenylistActionsProvider.notifier)
          .addUserEntry(DenylistCategory.filename, 'custom');
      await c.read(codingToolsDenylistActionsProvider.notifier)
          .suppressBaseline(DenylistCategory.filename, '.env');
      await c.read(codingToolsDenylistActionsProvider.notifier)
          .restoreCategory(DenylistCategory.filename);
      final state = await c.read(codingToolsDenylistProvider.future);
      expect(state.userAdded[DenylistCategory.filename], isEmpty);
      expect(state.suppressedDefaults[DenylistCategory.filename], isEmpty);
    });

    test('restoreAll clears everything', () async {
      await c.read(codingToolsDenylistActionsProvider.notifier)
          .addUserEntry(DenylistCategory.filename, 'a');
      await c.read(codingToolsDenylistActionsProvider.notifier)
          .addUserEntry(DenylistCategory.segment, 'b');
      await c.read(codingToolsDenylistActionsProvider.notifier).restoreAll();
      final state = await c.read(codingToolsDenylistProvider.future);
      for (final cat in DenylistCategory.values) {
        expect(state.userAdded[cat], isEmpty);
        expect(state.suppressedDefaults[cat], isEmpty);
      }
    });
  }
  ```

  Run:

  ```bash
  flutter test test/features/coding_tools/notifiers/coding_tools_denylist_actions_test.dart
  ```

  Expected: all FAIL — actions class not defined.

- [ ] **Step 3: Implement the actions notifier**

  ```dart
  // coding_tools_denylist_actions.dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../../core/utils/debug_logger.dart';
  import '../../../data/coding_tools/models/coding_tools_denylist_state.dart';
  import '../../../data/coding_tools/models/denylist_category.dart';
  import '../../../data/coding_tools/models/denylist_defaults.dart';
  import '../../../data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';
  import 'coding_tools_denylist_failure.dart';
  import 'coding_tools_denylist_notifier.dart';

  export 'coding_tools_denylist_failure.dart';

  part 'coding_tools_denylist_actions.g.dart';

  @Riverpod(keepAlive: true)
  class CodingToolsDenylistActions extends _$CodingToolsDenylistActions {
    @override
    FutureOr<void> build() {}

    CodingToolsDenylistFailure _asFailure(Object e) => switch (e) {
      CodingToolsDenylistFailure() => e,
      _ => CodingToolsDenylistFailure.unknown(e),
    };

    String _normalize(String raw) => raw.trim();

    Future<void> addUserEntry(DenylistCategory category, String raw) async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        try {
          final value = _normalize(raw);
          if (value.isEmpty) throw const CodingToolsDenylistFailure.invalidEntry();
          final repo = ref.read(codingToolsDenylistRepositoryProvider);
          final current = await repo.load();
          final added = {...(current.userAdded[category] ?? const <String>{})};
          final baseline = DenylistDefaults.forCategory(category);
          if (added.contains(value) || baseline.contains(value)) {
            throw const CodingToolsDenylistFailure.duplicate();
          }
          added.add(value);
          await repo.save(
            current.copyWith(
              userAdded: {...current.userAdded, category: added},
            ),
          );
          ref.invalidate(codingToolsDenylistProvider);
        } catch (e, st) {
          dLog('[CodingToolsDenylistActions] addUserEntry failed: $e');
          Error.throwWithStackTrace(_asFailure(e), st);
        }
      });
    }

    Future<void> removeUserEntry(DenylistCategory category, String value) async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        try {
          final repo = ref.read(codingToolsDenylistRepositoryProvider);
          final current = await repo.load();
          final added = {...(current.userAdded[category] ?? const <String>{})}..remove(value);
          await repo.save(current.copyWith(userAdded: {...current.userAdded, category: added}));
          ref.invalidate(codingToolsDenylistProvider);
        } catch (e, st) {
          dLog('[CodingToolsDenylistActions] removeUserEntry failed: $e');
          Error.throwWithStackTrace(_asFailure(e), st);
        }
      });
    }

    Future<void> suppressBaseline(DenylistCategory category, String value) async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        try {
          final repo = ref.read(codingToolsDenylistRepositoryProvider);
          final current = await repo.load();
          final suppressed = {...(current.suppressedDefaults[category] ?? const <String>{})}..add(value);
          await repo.save(
            current.copyWith(
              suppressedDefaults: {...current.suppressedDefaults, category: suppressed},
            ),
          );
          ref.invalidate(codingToolsDenylistProvider);
        } catch (e, st) {
          dLog('[CodingToolsDenylistActions] suppressBaseline failed: $e');
          Error.throwWithStackTrace(_asFailure(e), st);
        }
      });
    }

    Future<void> restoreBaseline(DenylistCategory category, String value) async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        try {
          final repo = ref.read(codingToolsDenylistRepositoryProvider);
          final current = await repo.load();
          final suppressed = {...(current.suppressedDefaults[category] ?? const <String>{})}..remove(value);
          await repo.save(
            current.copyWith(
              suppressedDefaults: {...current.suppressedDefaults, category: suppressed},
            ),
          );
          ref.invalidate(codingToolsDenylistProvider);
        } catch (e, st) {
          dLog('[CodingToolsDenylistActions] restoreBaseline failed: $e');
          Error.throwWithStackTrace(_asFailure(e), st);
        }
      });
    }

    Future<void> restoreCategory(DenylistCategory category) async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        try {
          final repo = ref.read(codingToolsDenylistRepositoryProvider);
          final current = await repo.load();
          await repo.save(
            current.copyWith(
              userAdded: {...current.userAdded, category: <String>{}},
              suppressedDefaults: {...current.suppressedDefaults, category: <String>{}},
            ),
          );
          ref.invalidate(codingToolsDenylistProvider);
        } catch (e, st) {
          dLog('[CodingToolsDenylistActions] restoreCategory failed: $e');
          Error.throwWithStackTrace(_asFailure(e), st);
        }
      });
    }

    Future<void> restoreAll() async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        try {
          await ref.read(codingToolsDenylistRepositoryProvider).restoreAllDefaults();
          ref.invalidate(codingToolsDenylistProvider);
        } catch (e, st) {
          dLog('[CodingToolsDenylistActions] restoreAll failed: $e');
          Error.throwWithStackTrace(_asFailure(e), st);
        }
      });
    }
  }
  ```

- [ ] **Step 4: Run codegen + tests**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/features/coding_tools/notifiers/
  ```

  Expected: all tests pass.

- [ ] **Step 5: Verify analyzer**

  ```bash
  flutter analyze lib/features/coding_tools/
  ```

**Commit:**

```
feat(coding-tools): add denylist actions notifier + typed failures

AsyncNotifier<void> exposing addUserEntry / removeUserEntry /
suppressBaseline / restoreBaseline / restoreCategory / restoreAll.
Each mutation invalidates the state notifier. Validation errors
(empty, duplicate) surface as typed CodingToolsDenylistFailure so
widgets can switch without importing service exceptions.
```

---

## Task 7: UI widgets — chip + category group

**Goal:** Two reusable widgets that drive the screen:
1. `DenylistChip` — tri-state chip (default / user-added / suppressed) with an × tap.
2. `DenylistCategoryGroup` — one category's mini-group: title, subtitle, chips, Add row, per-category "↺" reset.

**Files:**

- Create: `lib/features/coding_tools/widgets/denylist_chip.dart`
- Create: `lib/features/coding_tools/widgets/denylist_category_group.dart`

**Steps:**

- [ ] **Step 1: `DenylistChip`**

  ```dart
  // denylist_chip.dart
  import 'package:flutter/material.dart';

  import '../../../core/constants/app_icons.dart';
  import '../../../core/constants/theme_constants.dart';
  import '../../../core/theme/app_colors.dart';

  enum DenylistChipVariant { baseline, userAdded, suppressed }

  class DenylistChip extends StatelessWidget {
    const DenylistChip({
      super.key,
      required this.label,
      required this.variant,
      required this.onRemove,
    });

    final String label;
    final DenylistChipVariant variant;
    final VoidCallback onRemove;

    @override
    Widget build(BuildContext context) {
      final c = AppColors.of(context);
      final (fg, bg, border, strike) = switch (variant) {
        DenylistChipVariant.baseline => (c.accent, c.accentTintBg, c.accentTintStroke, false),
        DenylistChipVariant.userAdded => (c.success ?? c.accent, c.successTintBg ?? c.accentTintBg, c.successTintStroke ?? c.accentTintStroke, false),
        DenylistChipVariant.suppressed => (c.error, c.errorTintBg, c.error.withValues(alpha: 0.4), true),
      };
      return InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontFamily: ThemeConstants.editorFontFamily,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  decoration: strike ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(width: 6),
              Icon(AppIcons.close, size: 11, color: fg.withValues(alpha: 0.7)),
            ],
          ),
        ),
      );
    }
  }
  ```

  Note on tokens: use existing `ThemeConstants` and `AppColors` only — no hardcoded hex (per the `theme_constants_colors` memory). If `success` / `successTintBg` / `successTintStroke` don't exist in `AppColors`, add them there in this task as a small additive change (follow neighbouring accent tokens as the template) and note it in the commit.

- [ ] **Step 2: `DenylistCategoryGroup`**

  Widget takes:
  - `title` (e.g. `'Blocked directories'`)
  - `subtitle` (e.g. `'Any segment match'`)
  - `baseline: Set<String>`
  - `userAdded: Set<String>`
  - `suppressed: Set<String>`
  - `inputHint`
  - `isSubmitting: bool` (spins the Add button)
  - `onAdd(String value)`
  - `onRemoveUser(String value)` — tapped × on a userAdded chip
  - `onSuppressBaseline(String value)` — tapped × on an *active baseline* chip; caller shows the destructive confirm dialog, widget is pure
  - `onRestoreBaseline(String value)` — tapped × on a *suppressed baseline* chip (un-suppresses, no confirm)
  - `onRestoreCategory()` — tapped ↺ in the group header; caller confirms if this would re-block suppressed

  The group routes × taps to the right callback based on chip variant: userAdded → `onRemoveUser`; active baseline → `onSuppressBaseline`; suppressed baseline → `onRestoreBaseline`. Inside `DenylistChip`, the callback is a single `onRemove` regardless of variant — routing happens in the group.

  Chips render in this order per category: user-added → baseline-active → baseline-suppressed. The "↺" per-category link sits in the group header, right-aligned; disable when both `userAdded` and `suppressed` are empty.

  Follow the `SettingsGroup` visual style (glassFill background, subtleBorder, 9-radius), but this is *not* a `SettingsGroup` — it's a custom container. Keep the widget pure (no `ref`) so callers own the failure handling.

- [ ] **Step 3: Verify analyzer**

  ```bash
  flutter analyze lib/features/coding_tools/widgets/
  ```

**Commit:**

```
feat(coding-tools): add denylist chip + category group widgets

DenylistChip renders the three variants (baseline/user/suppressed)
with a strikethrough for suppressed entries. DenylistCategoryGroup
hosts one category with title, subtitle, chip wall ordered
user-added → active → suppressed, an Add input, and a per-category
Restore link. Pure widgets — callers own the confirm dialogs.
```

---

## Task 8: `CodingToolsScreen`

**Goal:** Assemble the four `DenylistCategoryGroup`s, wire them to the Actions notifier, host the confirm dialogs (suppressing baseline; per-category restore when it would re-block), and surface failures via `ref.listen` + `AppSnackBar`.

**Files:**

- Create: `lib/features/coding_tools/coding_tools_screen.dart`

**Steps:**

- [ ] **Step 1: Write the screen**

  Pattern to follow: the existing `GeneralScreen` for layout (`SectionLabel`, `SingleChildScrollView`, `AppSnackBar`, `AppDialog`).

  Structure:

  ```
  SectionLabel('Coding Tools')
  subtitle: 'Files and folders the agent may not read, list, or modify. Defaults are shipped — you can add your own or opt out of specific defaults with a confirmation.'
  4 × DenylistCategoryGroup (segments / filenames / extensions / prefixes)
  Divider
  SectionLabel('About')
  explainer + link to docs (future; skip link today — just a one-line explanation of tri-state)
  ```

  Confirm dialog on `onSuppressBaseline(value)` uses `AppDialog.destructive`:

  > Title: "Allow the agent to access `.env`?"
  > Body: "The coding tools will no longer refuse reads, lists, or writes of any file named `.env` inside your project. You can restore this block at any time."
  > Actions: Cancel · "Allow access" (destructive).

  Confirm dialog on `onRestoreCategory()` *only* when `suppressed.isNotEmpty` (because restoring would re-block something the user had allowed); otherwise no dialog.

  Ref discipline:
  - `ref.watch(codingToolsDenylistProvider)` in `build()` to render.
  - `ref.read(codingToolsDenylistActionsProvider.notifier).xxx()` in callbacks.
  - `ref.listen(codingToolsDenylistActionsProvider, ...)` at top of `build()` to surface `AsyncError` → switch on `CodingToolsDenylistFailure`:
    - `invalidEntry` → snackbar "Enter a non-empty value."
    - `duplicate` → snackbar "That entry is already in the list."
    - `saveFailed` → snackbar "Could not save — please try again."
    - `unknown` → snackbar "Unexpected error."

  Loading indicator on the Add button driven by `ref.watch(codingToolsDenylistActionsProvider).isLoading`.

- [ ] **Step 2: Manual smoke test against the running app**

  ```bash
  flutter run -d macos
  ```

  (Ad-hoc — no test yet. Verify screen renders, 4 groups show, tap an × on `.env` pops dialog, add → chip appears.)

- [ ] **Step 3: Verify analyzer**

  ```bash
  flutter analyze lib/features/coding_tools/
  ```

**Commit:**

```
feat(coding-tools): add Coding Tools settings screen

Hosts the four denylist categories, wires the Actions notifier, and
gates baseline suppression behind an AppDialog.destructive confirm.
Per-category Restore prompts only when it would re-block a
user-allowed baseline entry. Failures surface via ref.listen +
AppSnackBar with a switch on CodingToolsDenylistFailure.
```

---

## Task 9: Wire into the Settings left nav + context-aware Restore

**Goal:** Add a new `_SettingsNav.codingTools` tab to the existing `_SettingsLeftNav`, route to `CodingToolsScreen`, and make the existing "↺ Restore defaults" button context-aware per active tab.

**Files:**

- Modify: `lib/features/settings/settings_screen.dart`

**Steps:**

- [ ] **Step 1: Add the enum case + nav item**

  1. `enum _SettingsNav { general, providers, integrations, codingTools, archive }` — put `codingTools` after `integrations` (below it in the nav, above Archive).
  2. Add a `_NavItem` in `_SettingsLeftNav.build` between Integrations and Archive:

     ```dart
     _NavItem(
       icon: AppIcons.terminal, // or an equivalent — pick from existing icons
       label: 'Coding Tools',
       isActive: widget.activeNav == _SettingsNav.codingTools,
       onTap: () => widget.onSelect(_SettingsNav.codingTools),
     ),
     ```

     If `AppIcons.terminal` doesn't exist, use the closest existing icon (e.g. `AppIcons.code` or `AppIcons.shield`). Don't introduce new icons in this task.

  3. Add a case in `_buildContent`:

     ```dart
     case _SettingsNav.codingTools:
       return CodingToolsScreen(key: ValueKey('coding-tools-$_codingToolsVersion'));
     ```

- [ ] **Step 2: Make `_restoreDefaults` context-aware**

  Replace the current `_restoreDefaults` body with a switch on `_activeNav`:

  ```dart
  Future<void> _restoreDefaults() async {
    switch (_activeNav) {
      case _SettingsNav.general: await _restoreGeneralDefaults();
      case _SettingsNav.codingTools: await _restoreCodingToolsDefaults();
      case _SettingsNav.providers:
      case _SettingsNav.integrations:
      case _SettingsNav.archive:
        // No-op (these tabs don't own "restorable" prefs today).
        return;
    }
  }
  ```

  Factor the existing General restore into `_restoreGeneralDefaults()` unchanged. Add `_restoreCodingToolsDefaults()`:

  - Shows `AppDialog` with title "Restore coding-tools denylist defaults?" and body listing what will be reset ("Your additions and any defaults you've opted out of will be cleared.").
  - On confirm: `await ref.read(codingToolsDenylistActionsProvider.notifier).restoreAll()`.
  - On error (inline check of `hasError`, per the multi-instance `ref.listen` caveat): show `AppSnackBar` error.
  - On success: bump a new `_codingToolsVersion` int to re-key the screen, matching the General pattern.

  Consider hiding the "↺ Restore defaults" button entirely when the active tab has no restore (Providers/Integrations/Archive). Keep it visible on General and Coding Tools. Implementation: compute `showRestore = _activeNav == _SettingsNav.general || _activeNav == _SettingsNav.codingTools` and wrap the restore chunk of `_SettingsLeftNav`.

- [ ] **Step 3: Verify analyzer + run the app**

  ```bash
  flutter analyze lib/features/settings/
  flutter run -d macos
  ```

  Manual QA:
  - Click Coding Tools in the left nav — screen loads with 4 groups.
  - "↺ Restore defaults" is visible. Click it while on General — only General prefs reset. Switch to Coding Tools and click — only denylist resets.
  - Switch to Providers — Restore button hidden (or disabled per your choice).

**Commit:**

```
feat(settings): add Coding Tools tab + per-tab Restore defaults

New _SettingsNav.codingTools tab joins the left nav between General
and Providers. The existing Restore defaults button switches on the
active tab — General resets general prefs, Coding Tools resets the
denylist divergence, other tabs hide the button.
```

---

## Task 10: Final verification — analyzer, format, tests, QA

**Goal:** Lock the branch in green.

**Steps:**

- [ ] **Step 1: Format**

  ```bash
  dart format lib/ test/
  ```

- [ ] **Step 2: Analyzer**

  ```bash
  flutter analyze
  ```

  Expected: `No issues found!`

- [ ] **Step 3: Full test suite**

  ```bash
  flutter test
  ```

  Expected: all green. Pay attention to `test/arch_test.dart` — if it pins the set of public providers or feature folders, update it to include the new ones.

- [ ] **Step 4: Regenerate generated files (idempotency check)**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  git status
  ```

  Expected: no diff after codegen (all generated files already committed alongside their sources per the `generated_files` memory).

- [ ] **Step 5: Manual QA checklist — walk through item-by-item with the user**

  Per the `post_plan_qa_checklist` memory, at PR review the user will be asked to verify each:

  1. Open Settings → **Coding Tools** tab loads with four groups (Directories, Filenames, Extensions, Prefixes) populated with defaults styled as "baseline".
  2. Type `company_token` in the Filenames Add field, press Add → chip appears styled as "user-added". Restart the app → chip still there.
  3. Click × on the `company_token` chip → gone without a dialog.
  4. Click × on `.env` baseline chip → confirm dialog appears with destructive primary button. Click Allow access → chip becomes strikethrough "suppressed" style.
  5. With `.env` suppressed, in chat ask the agent to "read the .env file in my project" (manually create one first). It should succeed.
  6. Click the ↺ on the Filenames group → because there's a suppressed default, confirm dialog fires. Confirm → `.env` chip returns to baseline style.
  7. Click the left-nav "↺ Restore defaults" while on Coding Tools → one confirm dialog, all four categories reset.
  8. Switch to General → click "↺ Restore defaults" → only General resets. Coding Tools divergence is untouched.
  9. Switch to Providers / Integrations / Archive → Restore button is hidden or disabled.

**Commit:**

```
chore(coding-tools): final verification pass

Run dart format, flutter analyze, and flutter test after the full
feature lands. No code changes — just confirms the branch is green
before PR.
```

(If format/analyzer/tests all pass without touching source, skip this commit.)

---

## Out of scope (explicit non-goals)

- Per-project denylist. Today's scope is global only. Storage shape leaves room to add a per-project slot later without migrating the existing blob.
- Exposing the denylist to the model. The model only sees the *effect* (refusal messages, filtered `list_dir` output).
- Per-entry behavior toggles (refuse-only vs silent-only). Preserved as a single consistent behavior: refuse on direct, silent on list.
- `.claudeignore`-style file in the repo. This is Code Bench's own setting, not a Claude Code convention.
- Ephemeral per-message bypasses or "allow once" flows.

---

## Risk notes

- **Async repo reads on every tool call.** `SharedPreferences` caches in-process after first load, so the per-call cost is a map lookup, not disk I/O. Acceptable. If the agent loop becomes hot enough to notice, promote the repo to an in-memory snapshot refreshed via `ref.listen` on the state provider.
- **JSON blob key versioning.** Key is `coding_tools_denylist_state_v1`. If the schema changes, bump to `_v2` and migrate on first read; don't rewrite `_v1` in place.
- **Strikethrough chip interaction.** The × on a suppressed baseline chip *un-suppresses* (re-blocks) it — confirmed in Task 7's `DenylistCategoryGroup` callback routing. The visual meaning: "× removes the chip's current state" — strikethrough state is "allowed-by-user", × returns it to baseline-active. Add a tooltip (`Tooltip` widget) on suppressed chips clarifying "Click × to re-block" to reduce confusion.
