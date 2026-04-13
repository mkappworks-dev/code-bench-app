# Clean Architecture Data Layer — Design Spec

**Date:** 2026-04-13  
**Scope:** Restructure `lib/services/` into a full three-layer clean architecture (datasource → repository → service/use-case) with interface abstractions at every layer.  
**Migration:** Big-bang single PR from `main`.

---

## 1. Goals

- Every I/O boundary (Dio HTTP, `Process.run`, `dart:io` file access, Drift DB) lives in a typed datasource class behind an interface.
- Repositories compose datasources and expose domain-level APIs to the service and notifier layers.
- Use-case services (`lib/services/`) are the only remaining orchestration that spans multiple repositories.
- `dart:io`, `package:dio`, and `package:drift` appear **only** in their designated datasource and `_core` files — enforced by an architectural test.

---

## 2. Three-Layer Model

```
Notifier
  └── Service (use-case)          lib/services/
        └── Repository            lib/data/<feature>/repository/
              └── Datasource      lib/data/<feature>/datasource/
```

Notifiers may consume a repository directly if no use-case orchestration is needed. They must never import a datasource.

---

## 3. Target Folder Tree

```
lib/
  core/                                         (unchanged)
  data/
    _core/                                      (shared data-layer infra)
      app_database.dart                         ← moved from datasources/local/
      secure_storage.dart                       ← renamed from secure_storage_source.dart
      preferences/
        general_preferences.dart
        onboarding_preferences.dart
      http/
        dio_factory.dart                        ← NEW: centralised Dio builder

    models/                                     (unchanged — freezed domain types)

    ai/
      datasource/
        ai_remote_datasource.dart               (abstract interface)
        anthropic_remote_datasource_dio.dart
        openai_remote_datasource_dio.dart
        gemini_remote_datasource_dio.dart
        ollama_remote_datasource_dio.dart
        custom_remote_datasource_dio.dart
      repository/
        ai_repository.dart                      (abstract interface)
        ai_repository_impl.dart                 (holds provider switch; absorbs AIServiceFactory)

    github/
      datasource/
        github_api_datasource.dart              (interface)
        github_api_datasource_dio.dart
        github_auth_datasource.dart             (interface)
        github_auth_datasource_web.dart         (OAuth + Dio token exchange)
      repository/
        github_repository.dart
        github_repository_impl.dart

    git/
      datasource/
        git_datasource.dart                     (interface)
        git_datasource_process.dart             (shells out via Process.run)
        git_live_state_datasource.dart          (interface)
        git_live_state_datasource_watcher.dart  (filesystem watcher)
      repository/
        git_repository.dart
        git_repository_impl.dart

    project/
      datasource/
        project_datasource.dart                 (interface — DB operations)
        project_datasource_drift.dart
        project_fs_datasource.dart              (interface — disk probes)
        project_fs_datasource_io.dart
        git_detector_datasource.dart            (interface)
        git_detector_datasource_io.dart
        project_file_scan_datasource.dart       (interface)
        project_file_scan_datasource_io.dart
      repository/
        project_repository.dart
        project_repository_impl.dart            (owns row→domain mapping + ProjectStatus probe)

    session/
      datasource/
        session_datasource.dart                 (interface)
        session_datasource_drift.dart
      repository/
        session_repository.dart
        session_repository_impl.dart

    filesystem/
      datasource/
        filesystem_datasource.dart              (interface)
        filesystem_datasource_io.dart
      repository/
        filesystem_repository.dart
        filesystem_repository_impl.dart

    ide/
      datasource/
        ide_launch_datasource.dart              (interface)
        ide_launch_datasource_process.dart
      repository/
        ide_launch_repository.dart
        ide_launch_repository_impl.dart

    actions/
      datasource/
        action_runner_datasource.dart           (interface)
        action_runner_datasource_process.dart
      repository/
        action_runner_repository.dart
        action_runner_repository_impl.dart

    settings/
      repository/
        settings_repository.dart               (wraps prefs + secure_storage)
        settings_repository_impl.dart

  services/                                     (use-cases only)
    apply_service.dart                          (filesystem_repo + git_repo + applied-change store)
    api_key_test_service.dart                   (ai_repo + settings_repo)

  features/                                     (unchanged)
  shell/                                        (unchanged)
  shared/                                       (unchanged)
  router/                                       (unchanged)
```

---

## 4. Naming Conventions

| Layer | Interface | Concrete |
|---|---|---|
| Repository | `FooRepository` | `FooRepositoryImpl` |
| Datasource | `FooBarDatasource` | `FooBarDatasourceDio` / `FooBarDatasourceDrift` / `FooBarDatasourceProcess` / `FooBarDatasourceIo` |

Datasource suffix signals the I/O mechanism. Repository impl suffix is always `Impl`.

---

## 5. Interface Contracts

### 5a. Datasource — single I/O boundary

```dart
// lib/data/ai/datasource/ai_remote_datasource.dart
abstract interface class AIRemoteDatasource {
  AIProvider get provider;
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });
  Future<bool> testConnection(AIModel model, String apiKey);
  Future<List<AIModel>> fetchAvailableModels(String apiKey);
}
```

Datasources speak wire protocol only. They do not know about persistence, retries, or provider selection logic.

### 5b. Repository — domain API

```dart
// lib/data/ai/repository/ai_repository.dart
abstract interface class AIRepository {
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });
  Future<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });
  Future<bool> testConnection(AIModel model, String apiKey);
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey);
}
```

`AIRepositoryImpl` receives a `Map<AIProvider, AIRemoteDatasource>` and dispatches on `model.provider`. The `sendMessage` buffering (previously duplicated across all 5 provider files) collapses into one implementation here.

### 5c. Repository composing two datasources

```dart
// lib/data/project/repository/project_repository_impl.dart
class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl({required ProjectDatasource db, required ProjectFsDatasource fs});

  @override
  Stream<List<Project>> watchAllProjects() =>
      _db.watchAllProjectRows().map(
        (rows) => rows.map((r) => _toDomain(r, _fs.exists(r.path))).toList(),
      );

  Project _toDomain(WorkspaceProjectRow row, bool existsOnDisk) => Project(
        id: row.id, name: row.name, path: row.path,
        status: existsOnDisk ? ProjectStatus.available : ProjectStatus.missing,
        ...
      );
}
```

Row→domain mapping (currently `ProjectService._projectFromRow`) and the `ProjectStatus` disk probe both belong here.

### 5d. Use-case service — multi-repo orchestration

```dart
// lib/services/apply_service.dart
class ApplyService {
  ApplyService({
    required FilesystemRepository fs,
    required GitRepository git,
    required AppliedChangesNotifier history,
  });
  // No dart:io or Process.run — all I/O via injected repositories.
}
```

---

## 6. Riverpod Wiring

### 6a. Infra providers

```dart
// lib/data/_core/app_database.dart
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => AppDatabase();

// lib/data/_core/secure_storage.dart
@Riverpod(keepAlive: true)
SecureStorage secureStorage(Ref ref) => SecureStorage();
```

### 6b. Datasource providers — return the interface type

```dart
// Returns AIRemoteDatasource (interface), not AnthropicRemoteDatasourceDio
@Riverpod(keepAlive: true)
AIRemoteDatasource anthropicRemoteDatasource(Ref ref, String apiKey) =>
    AnthropicRemoteDatasourceDio(Dio(BaseOptions(...)));
```

API-key-parameterised datasources use Riverpod family providers. Changing a key in settings invalidates the datasource, which invalidates the repository, which triggers notifier rebuilds — no manual `ref.invalidate` needed.

### 6c. Repository providers

```dart
@Riverpod(keepAlive: true)
AIRepository aiRepository(Ref ref) {
  final keys = ref.watch(apiKeysProvider);
  return AIRepositoryImpl(sources: {
    AIProvider.anthropic: ref.watch(anthropicRemoteDatasourceProvider(keys.anthropic ?? '')),
    AIProvider.openai:    ref.watch(openaiRemoteDatasourceProvider(keys.openai ?? '')),
    AIProvider.gemini:    ref.watch(geminiRemoteDatasourceProvider(keys.gemini ?? '')),
    AIProvider.ollama:    ref.watch(ollamaRemoteDatasourceProvider(keys.ollamaBaseUrl)),
    AIProvider.custom:    ref.watch(customRemoteDatasourceProvider(keys.customBaseUrl, keys.customKey)),
  });
}
```

Every repository provider returns the **interface type**, enabling test overrides.

### 6d. Test override pattern

```dart
ProviderScope(
  overrides: [
    projectFsDatasourceProvider.overrideWithValue(FakeProjectFsDatasource(existing: {'/path/a': false})),
  ],
  child: const App(),
)
```

Override at the datasource layer for I/O faking, or at the repository layer for full feature faking.

---

## 7. Architectural Boundary Rule

`dart:io`, `package:dio`, and `package:drift` must appear **only** in:

| Import | Permitted paths |
|---|---|
| `dart:io` | `lib/data/**/*_io.dart`, `lib/data/**/*_process.dart` |
| `package:dio` | `lib/data/**/*_dio.dart` |
| `package:drift` | `lib/data/**/*_drift.dart`, `lib/data/_core/app_database.dart` |

This is enforced by an architectural test added in the PR:

```dart
// test/arch_test.dart
test('dart:io only in datasource _io/_process files', () {
  final violations = grep('dart:io', under: 'lib/')
      .where((path) => !path.endsWith('_io.dart') && !path.endsWith('_process.dart'));
  expect(violations, isEmpty);
});
```

---

## 8. Migration Commit Sequence (big-bang PR)

Each commit must compile and pass `flutter analyze` before the next begins.

| # | Commit | Deletes |
|---|---|---|
| 1 | Scaffold `lib/data/_core/`. Move DB, secure storage, prefs. Add `dio_factory.dart`. Regen build_runner. | `lib/data/datasources/local/` |
| 2 | AI feature. 5 datasources + `AIRepositoryImpl` (absorbs factory + buffering). Flip `ChatNotifier`, `ApiKeyTestService`. | `lib/services/ai/` |
| 3 | GitHub feature. `GithubApiDatasourceDio` + `GithubAuthDatasourceWeb` + `GithubRepositoryImpl`. Flip consumers. | `lib/services/github/` |
| 4 | Git feature. `GitDatasourceProcess` + `GitLiveStateDatasource` + `GitRepositoryImpl`. Flip consumers. | `lib/services/git/` |
| 5 | Project feature. Split `ProjectService` into Drift datasource + FS datasource + `ProjectRepositoryImpl`. Port git_detector + file_scan. Flip consumers. | `lib/services/project/` |
| 6 | Session + Filesystem + IDE + Actions + Settings. Datasources + repositories. Flip consumers. | `lib/services/{session,filesystem,ide,actions,settings}/` |
| 7 | Apply use-case. Replace direct `File`/`Process.run` with `FilesystemRepository` + `GitRepository`. | `lib/services/apply/` |
| 8 | Add `test/arch_test.dart`. Final `dart format lib/ test/` + `flutter analyze` + `flutter test`. | (empty service subfolders) |

---

## 9. Risks & Notes

- **`ApplyService` ↔ `ChatNotifier` coupling.** `ApplyService` reads `appliedChangesProvider.notifier` (UI-layer state). This is intentional — it stays as-is. Not a layering violation because `AppliedChangesNotifier` is applied-change UI state, not a data-layer concern.
- **Drift regeneration in commit 1.** Moving `app_database.dart` changes the `.g.dart` output path. Regenerate and commit the generated file in commit 1.
- **GitHub OAuth `_clientId` placeholder.** `'YOUR_GITHUB_CLIENT_ID'` is preserved unchanged — out of scope.
- **No new test coverage in this PR.** Refactor-only. Update existing test overrides from service to repository types. New datasource/repository unit tests are follow-up work.
- **Review the PR commit-by-commit**, not as a squashed diff.

---

## 10. Out of Scope

- Bug fixes or behaviour changes of any kind
- Changing any public notifier or widget surface
- Changing the Drift schema
- New features
- `lib/core/`, `lib/shared/`, `lib/router/`, `lib/shell/` — untouched
