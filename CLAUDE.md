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

## Brainstorming Options

When presenting multiple-choice options (A/B/C etc.) during brainstorming:
- Always include a short concrete example for each option
- Always mark the recommended option with a ★ symbol

## Pull Request Template

Use this format both when creating a PR (`gh pr create`) and when asked for a PR summary. When giving a summary (not creating), wrap the output in a markdown code block so it is copyable:

```markdown
## Summary

Brief description of what this PR does and why.

Closes #<!-- issue number -->

## Changes

-
-

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor / internal improvement
- [ ] Documentation

## Checklist

- [ ] `flutter analyze` passes with no issues
- [ ] `dart format lib/` applied
- [ ] `flutter test` passes
- [ ] If Drift tables or Riverpod providers were changed, `build_runner` was re-run and generated files are not committed
- [ ] PR is focused on a single concern
```
