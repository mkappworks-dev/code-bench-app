<p align="center">
  <img src="assets/images/app_icon.png" width="128" alt="Code Bench">
</p>
<h1 align="center">Code Bench</h1>

AI-powered desktop code assistant that combines a code editor, multi-provider AI chat, and GitHub integration — runs fully offline with Ollama.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/macOS-stable-brightgreen)](https://github.com)
[![Platform: Windows/Linux](https://img.shields.io/badge/Windows%20%7C%20Linux-in%20development-yellow)](https://github.com)

## Installation (macOS)

1. Download `CodeBench-macos.dmg` from the [latest release](https://github.com/mkappworks-dev/code-bench-app/releases/latest).
2. Open the DMG and drag **Code Bench** into **Applications**.
3. Launch the app. macOS will block it the first time because the app is not yet notarized.
4. Open **System Settings → Privacy & Security**, scroll to the bottom, and click **Open Anyway**.
5. On the next prompt, click **Open**.

> macOS may also ask *"Code Bench would like to access files in your Documents folder."* — click **Allow**. Code Bench reads project files from wherever you store them on disk, so it needs access to user folders outside its own container.

## Features

| Tab           | Capabilities                                                                                                                             |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Dashboard** | Quick-start actions · recent conversation list (last 10) · delete sessions                                                               |
| **Chat**      | Stream responses from OpenAI · Anthropic · Gemini · Ollama · custom endpoint · per-session system prompt · model selector · compare mode |
| **Editor**    | Multi-tab code editor · syntax highlighting · file save (⌘S) · close tab (⌘W) · dirty-state tracking · read-only GitHub files            |
| **GitHub**    | OAuth login · list/search repos · branch selector · file tree · open files in editor · commit dialog · PR list                           |
| **Settings**  | Store/delete API keys per provider · Ollama base URL · custom OpenAI-compatible endpoint                                                 |
| **Compare**   | Side-by-side dual-pane chat — send one prompt to two different models simultaneously                                                     |

## Platforms

| Platform | Status                                             |
| -------- | -------------------------------------------------- |
| macOS    | ✅ Stable — built and tested in CI                 |
| Windows  | 🚧 In development — build target exists, not in CI |
| Linux    | 🚧 In development — build target exists, not in CI |

iOS, Android, and Web are out of scope.

## Requirements

| Dependency                           | Version                                |
| ------------------------------------ | -------------------------------------- |
| Flutter SDK                          | ≥ 3.41.6 stable                        |
| Dart SDK                             | ≥ 3.11.4                               |
| Xcode (macOS builds)                 | 15+ Sequoia (Xcode CLI tools required) |
| Windows 10 (Windows builds)          | 1903+ _(in development)_               |
| GTK 3 + ninja + cmake (Linux builds) | system packages _(in development)_     |

### 1. Clone and fetch packages

```bash
git clone git@github.com:mkappworks-dev/code-bench-app.git
cd code-bench-app
flutter pub get
```

### 2. Generate code

Drift (SQLite ORM) and Riverpod require a one-time code-generation step. Run this before the first build and whenever you modify database tables or add `@riverpod` providers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Use watch mode during active development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 3. Run

For macos:

```bash
flutter run -d macos      # primary dev target
```

For windows:

```bash
flutter run -d windows
```

For linux:

```bash
flutter run -d linux
```

On first launch, the onboarding screen gates access until at least one AI provider API key is saved.

> **GitHub OAuth** — replace `YOUR_GITHUB_CLIENT_ID` in [lib/services/github/github_auth_service.dart](lib/services/github/github_auth_service.dart) with a real GitHub OAuth App client ID. Create one at **Settings → Developer settings → OAuth Apps** with callback URL `codebench://oauth/callback`.

## Project Structure

```
lib/
├── main.dart                    # Entry point — ProviderScope, window_manager init
├── app.dart                     # MaterialApp.router wired to GoRouter
├── router/
│   └── app_router.dart          # GoRouter: onboarding guard + ShellRoute
├── shell/
│   ├── desktop_shell.dart       # 3-pane layout (explorer | main | chat) + keyboard shortcuts
│   └── widgets/
│       ├── side_nav_rail.dart   # 48 px icon nav rail
│       └── app_title_bar.dart   # Custom title bar
├── core/
│   ├── constants/               # App, API, and theme constants
│   ├── errors/                  # AppException hierarchy
│   ├── theme/                   # AppTheme
│   └── utils/                   # PlatformUtils
├── data/
│   ├── shared/                  # Cross-cutting models: AIModel, ChatMessage (used by both AI and session domains)
│   ├── ai/                      # AI datasources (Dio), repository, models/
│   ├── session/                 # Session datasource (Drift), repository, models/ (ChatSession, ToolEvent, …)
│   ├── project/                 # Project datasource (Drift), repository, models/ (Project, WorkspaceProject, …)
│   ├── github/                  # GitHub datasources (Dio), repository, models/ (Repository, GitHubAccount, …)
│   ├── git/                     # Git datasource (Process), repository, models/ (GitLiveState), exceptions
│   ├── apply/                   # Apply datasource (filesystem), repository, models/ (AppliedChange)
│   ├── settings/                # Settings datasource (SecureStorage), repository
│   ├── filesystem/              # Filesystem datasource (dart:io)
│   └── _core/                   # Drift AppDatabase, DioFactory, SecureStorageSource
├── services/
│   ├── ai/                      # AIService — stream buffering, model selection
│   ├── github/                  # GitHubService — OAuth + REST composition
│   ├── git/                     # GitService — composite git operations
│   ├── session/                 # SessionService — send-and-stream, history
│   ├── project/                 # ProjectService — add/relocate policy
│   ├── apply/                   # ApplyService — patch orchestration + security guard
│   ├── settings/                # SettingsService — wipe cascade, onboarding
│   ├── ide/                     # IdeService — editor/terminal launch
│   └── api_key_test/            # ApiKeyTestService — provider connectivity checks
└── features/
    ├── onboarding/              # First-run API key entry
    ├── dashboard/               # Home screen with session list
    ├── chat/                    # Chat UI, chat_notifier, message streaming
    ├── editor/                  # editor_notifier (tab state) + CodeEditorWidget (re_editor)
    ├── file_explorer/           # Directory tree panel
    ├── github/                  # Repo browser, file tree, commit/PR dialogs
    ├── compare/                 # Side-by-side model comparison
    └── settings/                # API key management UI
```

## Architecture

### Dependency rule

The dependency graph is strictly one-directional. Violating it is a build-review blocker:

```
Widgets / Screens
      ↓  (ref.watch / ref.read notifier)
  Notifiers          ← the only layer widgets may reach
      ↓  (ref.read service)
  Services           ← business logic, composition, typed exceptions
      ↓  (constructor injection)
  Repositories       ← domain interfaces; no I/O
      ↓
  Datasources        ← Dio, DB, Process.run, filesystem live here
      ↓
External (REST APIs / SQLite / OS)
```

Widgets communicate with notifiers only via `ref.watch` / `ref.read(…notifier).method()`. They never reach into a service or repository provider directly. `Process.run`, `dart:io`, and `Dio` are confined to `lib/data/**/datasource/`.

**Command notifiers** (`*Actions`, e.g. `ProjectSidebarActions`, `CodeApplyActions`, `GitActions`) use `void build()` with `keepAlive: true` and expose imperative `Future<void>` methods. They are the bridge between the UI and the service layer.

**Naming conventions:**

| Layer                      | Rule                                                                                         |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| Service class              | ends in `Service` (`GitService`, `SessionService`)                                           |
| Service provider           | `@riverpod` function placed before the class it instantiates                                 |
| Repository interface       | ends in `Repository` (`GitRepository`, `AIRepository`)                                       |
| Repository impl + provider | class ends in `RepositoryImpl`; `@riverpod` before it                                        |
| Datasource file naming     | suffix encodes I/O type: `*_dio.dart`, `*_process.dart`, `*_io.dart`, `*_drift.dart`         |
| Command notifier           | ends in `Actions`; `void build()`, `keepAlive: true`                                         |
| State notifier             | ends in `Notifier`; owns `AsyncValue` or value state                                         |
| Notifier file placement    | `*_notifier.dart`, `*_actions.dart`, and `*_failure.dart` all live in `{feature}/notifiers/` |

The Riverpod generator strips the `Notifier` suffix from provider names (`ActiveSessionIdNotifier` → `activeSessionIdProvider`). The `Actions` suffix is kept (`GitActions` → `gitActionsProvider`). Widgets must never call `ref.invalidate` directly — route through a notifier method instead.

### Layered architecture

**Widgets** are pure state-renderers. They call notifier methods and listen for `AsyncError` state to show snackbars — they never try/catch business-logic calls or import service/repository exception types.

**Notifiers** mediate all commands. `*Actions` notifiers extend `AsyncNotifier<void>`; failures are emitted as `AsyncError` carrying a typed `sealed class {Notifier}Failure`. `*Notifier` classes own reactive `AsyncValue<T>` data state.

**Services** own business logic and composition. They receive repositories via constructor injection, convert low-level I/O errors into typed domain exceptions, and expose a clean API to notifiers. Services are instantiated via `@riverpod` / `@Riverpod(keepAlive: true)` providers and never constructed directly.

**Repositories** are domain interfaces (`lib/data/**/repository/`). Implementations (`*RepositoryImpl`) are wired up via Riverpod providers and injected into services.

**Datasources** (`lib/data/**/datasource/`) are where all I/O lives: Dio HTTP calls, SQLite via Drift, `Process.run`, and `dart:io` filesystem access. File suffix encodes the I/O type: `*_dio.dart`, `*_process.dart`, `*_io.dart`, `*_drift.dart`.

The full rules — naming conventions, error-handling patterns, logging matrix, security guards — are in [`CLAUDE.md`](CLAUDE.md).

### State management

| Pattern                                     | Used for                                                                                          |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `@Riverpod(keepAlive: true)` class Notifier | Long-lived app state: active session ID, selected model, editor tabs, system prompts, DB, storage |
| `@riverpod` class AsyncNotifier             | Chat messages (loads history, streams new messages)                                               |
| `@riverpod` function (StreamProvider)       | Session list — wraps `watchAllSessions()` Drift stream                                            |
| `@riverpod` function (FutureProvider)       | AI service factory, available model list                                                          |
| `StateProvider.family`                      | Compare-screen per-pane model and message state                                                   |

### Local persistence

All data is stored in a local SQLite database managed by Drift (`code_bench.db`).

| Table               | Stores                                                                                   |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `ChatSessions`      | Session ID · title · model/provider · created/updated timestamps · pin flag              |
| `ChatMessages`      | Message ID · session FK · role · content · extracted code blocks (JSON) · timestamp      |
| `WorkspaceProjects` | Project ID · name · local path · linked repo ID · active branch · associated session IDs |

DAOs: `SessionDao` (sessions + messages CRUD, stream watch) · `ProjectDao` (projects CRUD).

### Secret storage

`SecureStorageSource` wraps `flutter_secure_storage` using a consistent key scheme:

| Key                       | Holds                                           |
| ------------------------- | ----------------------------------------------- |
| `api_key_{provider}`      | API key per AI provider (e.g. `api_key_openai`) |
| `github_token`            | GitHub OAuth access token                       |
| `ollama_base_url`         | Custom Ollama server URL                        |
| `custom_endpoint_url`     | OpenAI-compatible custom endpoint               |
| `custom_endpoint_api_key` | Key for the custom endpoint                     |

| Platform | Backend                                 |
| -------- | --------------------------------------- |
| macOS    | Keychain (`first_unlock` accessibility) |
| Windows  | Windows Credential Manager              |
| Linux    | libsecret                               |

## Building for Distribution

for macos:

```bash
flutter build macos --release   # → build/macos/Build/Products/Release/
```

> **macOS App Sandbox is intentionally disabled.** Code Bench shells out to
> `git`, `code`, `cursor`, and user-defined action commands, which cannot
> work under sandbox. See [macos/Runner/README.md](macos/Runner/README.md)
> for the rationale, contributor rules, and distribution implications
> (Mac App Store eligibility, hardened runtime, notarization).

for windows:

```bash
flutter build windows --release # → build/windows/x64/runner/Release/ (in development)
```

for linux:

```bash
flutter build linux --release   # → build/linux/x64/release/bundle/ (in development)
```

## Testing & Linting

```bash
flutter test                         # run all tests
flutter analyze                      # static analysis
dart format lib/ test/               # format
dart format --set-exit-if-changed lib/ test/   # CI format check
```

## Extending Code Bench

### Adding an AI provider

1. Add a value to `AIProvider` enum in [lib/data/models/ai_model.dart](lib/data/models/ai_model.dart).
2. Implement `AIService` (streaming `sendMessage` method) in `lib/services/ai/`.
3. Add a `case` to the `switch` in [lib/services/ai/ai_service_factory.dart](lib/services/ai/ai_service_factory.dart) that reads the key from `SecureStorageSource`.
4. Add a storage method to [lib/data/datasources/local/secure_storage_source.dart](lib/data/datasources/local/secure_storage_source.dart) if the provider needs a non-key credential.
5. Add a settings field in [lib/features/settings/settings_screen.dart](lib/features/settings/settings_screen.dart).

### Adding a navigation tab

1. Add a `_NavItem` entry in [lib/shell/widgets/side_nav_rail.dart](lib/shell/widgets/side_nav_rail.dart).
2. Add a `GoRoute` inside the `ShellRoute` in [lib/router/app_router.dart](lib/router/app_router.dart).
3. Create the screen widget under `lib/features/<name>/`.
4. If the tab needs the file-explorer and chat side panels, add the route prefix to `showEditorPanes` in [lib/shell/desktop_shell.dart](lib/shell/desktop_shell.dart).

### Adding a Drift table

1. Define the table class in [lib/data/datasources/local/app_database.dart](lib/data/datasources/local/app_database.dart).
2. Create a `@DriftAccessor` DAO class in the same file.
3. Add both to the `@DriftDatabase` annotation and `daos` list.
4. Increment `schemaVersion` and add a `migration` step.
5. Run `dart run build_runner build --delete-conflicting-outputs`.

## Tech Stack

| Layer             | Technology                                                                  |
| ----------------- | --------------------------------------------------------------------------- |
| UI                | Flutter · Material Design · Google Fonts                                    |
| State             | flutter_riverpod · riverpod_annotation                                      |
| Navigation        | go_router (ShellRoute)                                                      |
| Local DB          | Drift (SQLite via sqlite3_flutter_libs)                                     |
| Secret storage    | flutter_secure_storage                                                      |
| HTTP / streaming  | Dio (SSE via `ResponseType.stream`)                                         |
| AI providers      | OpenAI · Anthropic · Gemini · Ollama · Custom                               |
| Code editor       | re_editor · re_highlight                                                    |
| Chat rendering    | flutter_markdown_plus · flutter_highlight                                   |
| GitHub OAuth      | flutter_web_auth_2                                                          |
| Window management | window_manager                                                              |
| Serialization     | freezed · json_annotation                                                   |
| Code generation   | build_runner · riverpod_generator · drift_dev · freezed · json_serializable |

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a PR.

## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) — free to use, modify, and distribute.
