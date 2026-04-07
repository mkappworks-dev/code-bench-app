# Code Bench

An AI-powered code assistant for macOS, Windows, and Linux — built with Flutter.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- **Multi-provider AI chat** — OpenAI (GPT-4o), Anthropic (Claude), Google Gemini, and local Ollama models
- **Streaming responses** — token-by-token output via SSE
- **Code editor** — syntax-highlighted editor powered by `re_editor` with file tabs
- **File explorer** — browse and edit local directories
- **GitHub integration** — browse repositories, view files, commit changes
- **VS Code Dark+ theme** — familiar dark IDE aesthetic
- **Resizable panes** — drag-to-resize explorer/editor/chat panels, persisted across restarts
- **Session history** — all conversations stored locally in SQLite via Drift
- **Secure key storage** — API keys stored in Keychain (macOS), Credential Manager (Windows), or libsecret (Linux)

## Platforms

| Platform | Status       |
| -------- | ------------ |
| macOS    | ✅ Primary   |
| Windows  | ✅ Supported |
| Linux    | ✅ Supported |

> iOS, Android, and Web are out of scope.

## Getting Started

### Prerequisites

- Flutter 3.x (stable channel)
- Dart SDK ≥ 3.6
- macOS: Xcode + CocoaPods
- Linux: `libsecret-1-dev`, `gtk3-dev`

### Setup

```bash
git clone git@github.com:mkappworks-dev/code-bench-app.git
cd code-bench-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos
```

### Configure API Keys

On first launch, the **Onboarding** screen lets you enter API keys for:

| Provider  | Where to get                 |
| --------- | ---------------------------- |
| OpenAI    | platform.openai.com/api-keys |
| Anthropic | console.anthropic.com        |
| Gemini    | aistudio.google.com/apikey   |
| Ollama    | Local — run `ollama serve`   |

Keys are stored securely in the platform keychain (never in plain text).

### GitHub OAuth

To enable GitHub integration, set your OAuth app credentials in
`lib/services/github/github_auth_service.dart`:

```dart
static const _clientId = 'YOUR_GITHUB_CLIENT_ID';
```

Create a GitHub OAuth App at **Settings → Developer settings → OAuth Apps** with:

- Callback URL: `codebench://oauth/callback`

## Architecture

```
lib/
├── main.dart               # Entry point — ProviderScope + window init
├── app.dart                # MaterialApp.router + GoRouter
├── core/                   # Constants, theme, errors, utils
├── data/
│   ├── models/             # Freezed DTOs (AIModel, ChatMessage, etc.)
│   └── datasources/
│       ├── local/          # Drift database + SecureStorage
│       └── remote/         # (AI + GitHub services)
├── services/
│   ├── ai/                 # OpenAI, Anthropic, Gemini, Ollama
│   ├── github/             # OAuth + API
│   ├── filesystem/         # Read/write local files
│   └── session/            # Chat session management
├── features/
│   ├── onboarding/         # API key setup
│   ├── dashboard/          # Session list
│   ├── chat/               # Chat UI + streaming
│   ├── editor/             # Code editor tabs
│   ├── file_explorer/      # Directory tree
│   ├── github/             # Repo browser
│   └── settings/           # Provider keys + Ollama config
├── shell/                  # 3-pane desktop layout
└── router/                 # GoRouter config + auth guard
```

**State management**: `flutter_riverpod` + `riverpod_annotation`
**Navigation**: `go_router` with `ShellRoute`
**Database**: `drift` (SQLite)
**AI streaming**: `dio` with `ResponseType.stream` (SSE)
**Code editor**: `re_editor` + `re_highlight`

## Development

### Code Generation

After modifying any Freezed model, Drift table, or Riverpod provider:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running

```bash
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

### Linting

```bash
flutter analyze
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes
4. Open a pull request

Please follow the existing code style (Dart lints enforced via `analysis_options.yaml`).

## License

MIT — see [LICENSE](LICENSE).
