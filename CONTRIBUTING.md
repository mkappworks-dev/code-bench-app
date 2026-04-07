# Contributing to Code Bench

Thank you for your interest in contributing. This document covers how to report bugs, propose features, and submit pull requests.

---

## Table of Contents

- [Contributing to Code Bench](#contributing-to-code-bench)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [License Acknowledgment](#license-acknowledgment)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Development Setup](#development-setup)
  - [Making Changes](#making-changes)
    - [Branch naming](#branch-naming)
    - [Where to add things](#where-to-add-things)
    - [After modifying Drift tables, Freezed models, or Riverpod providers](#after-modifying-drift-tables-freezed-models-or-riverpod-providers)
  - [Commit Message Conventions](#commit-message-conventions)
  - [Pull Request Guidelines](#pull-request-guidelines)
  - [Code Style](#code-style)

---

## Code of Conduct

Be respectful and constructive in all project spaces (issues, PRs, discussions). Harassment, personal attacks, and discriminatory language will not be tolerated and may result in permanent removal from the project.

---

## License Acknowledgment

By submitting a contribution you agree that your work will be licensed under the [MIT License](LICENSE) that covers this project. You retain copyright in your contributions; you are granting the project and its users the rights described in that license.

---

## Reporting Bugs

Before filing a bug, check if it has already been reported. When opening an issue:

- Describe what you expected vs. what happened
- Include steps to reproduce
- State your OS and Flutter/Dart version (`flutter --version`)
- Attach a screenshot or screen recording if the issue is visual

---

## Suggesting Features

Open a [Feature Request](https://github.com/mkappworks-dev/code-bench-app/issues/new) issue. Include:

- The problem you are trying to solve (not just the desired solution)
- Which part of the app it relates to (chat, editor, file explorer, GitHub integration, settings)
- Any prior art from similar tools

---

## Development Setup

```bash
# 1. Fork https://github.com/mkappworks-dev/code-bench-app, then clone your fork
git clone https://github.com/<your-username>/code-bench-app.git
cd code-bench-app

# Optional: add the upstream remote to pull in future changes
git remote add upstream https://github.com/mkappworks-dev/code-bench-app.git

# 2. Install dependencies
flutter pub get

# 3. Generate code (Drift tables + Riverpod providers + Freezed models)
dart run build_runner build --delete-conflicting-outputs

# 4. Run on your platform
flutter run -d macos   # or windows / linux
```

Keep code generation running in watch mode during active development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## Making Changes

### Branch naming

```
feat/<short-description>     # new feature
fix/<short-description>      # bug fix
refactor/<short-description> # internal cleanup
docs/<short-description>     # documentation only
```

### Where to add things

| Change                 | Location                                                                                                       |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| New AI provider        | `lib/services/ai/` + register in the provider selection logic                                                  |
| New feature screen     | `lib/features/<name>/` + route in `lib/router/app_router.dart` + destination in `lib/shell/desktop_shell.dart` |
| New Drift table        | `lib/data/datasources/local/` → re-run `build_runner`                                                          |
| New Freezed model      | `lib/data/models/` → re-run `build_runner`                                                                     |
| New Riverpod provider  | Add `@riverpod` annotation → re-run `build_runner`                                                             |
| New secure storage key | `lib/data/datasources/local/` — route through `SecureStorage`, never hardcode                                  |

### After modifying Drift tables, Freezed models, or Riverpod providers

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated `.g.dart` and `.freezed.dart` files are gitignored — do not commit them.

---

## Commit Message Conventions

This project uses [Conventional Commits](https://www.conventionalcommits.org/).

| Type       | When to use                                |
| ---------- | ------------------------------------------ |
| `feat`     | A new feature visible to users             |
| `fix`      | A bug fix                                  |
| `docs`     | Documentation changes only                 |
| `refactor` | Code restructuring with no behavior change |
| `test`     | Adding or updating tests                   |
| `chore`    | Build scripts, dependency updates, tooling |

Format: `<type>(<optional scope>): <short imperative summary>`

Examples:

```
feat(chat): add streaming response cancellation
fix(keychain): handle null return from flutter_secure_storage on Linux
chore: bump flutter to 3.22.0
```

Breaking changes: add `!` after the type (`feat!:`) and include a `BREAKING CHANGE:` footer.

---

## Pull Request Guidelines

1. **Keep PRs focused** — one feature or fix per PR.
2. **Run checks locally** before pushing:
   ```bash
   flutter analyze
   dart format lib/
   flutter test
   ```
3. **Write a clear PR title** using the same conventional commit format (`feat: …`, `fix: …`).
4. **Write a clear PR description** — what changed and why; include screenshots for UI changes.
5. **Reference any related issue** — `Closes #123`.
6. **Do not force-push** to a PR branch after review has started.
7. **Squash merge preferred** — maintainers will squash commits on merge to keep the history linear.

PRs that fail `flutter analyze` or introduce formatting issues will not be merged.

---

## Code Style

- Follow standard Dart/Flutter conventions (`dart format` enforces this).
- Use `const` constructors wherever possible.
- Prefer named parameters for widgets with more than two arguments.
- Keep widget files focused — one primary widget per file.
- Do not add comments to self-explanatory code; do comment non-obvious logic.
- All API keys and credentials must go through `SecureStorage` — never hardcode or log them.
