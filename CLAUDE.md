# Code Bench — Claude Instructions

## Development Commands

```bash
# Run on macOS (primary dev target)
flutter run -d macos

# Run on other platforms
flutter run -d windows
flutter run -d linux

# Build
flutter build macos

# Analyze
flutter analyze

# Format
dart format lib/ test/

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Generate code after editing Drift tables, adding @riverpod, or @freezed models
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs
```

## Implementation Plans & Worktrees

Plans are saved to `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`.

When starting work from a plan, always create a git worktree under `.worktrees/` at the repo root. The worktree directory and branch share the same name, using a conventional prefix based on the type of work:

| Prefix  | When to use                      |
| ------- | -------------------------------- |
| `feat/` | New features                     |
| `fix/`  | Bug fixes                        |
| `tech/` | Refactors, tooling, dependencies |
| `doc/`  | Documentation only               |

The name after the prefix is the plan filename stripped of `.md` only — keep the date. For a plan file `2026-04-07-sign-features-flag.md` (a feature):

```bash
git worktree add .worktrees/feat/2026-04-07-sign-features-flag -b feat/2026-04-07-sign-features-flag
cd .worktrees/feat/2026-04-07-sign-features-flag
```

All implementation work happens inside that worktree.
