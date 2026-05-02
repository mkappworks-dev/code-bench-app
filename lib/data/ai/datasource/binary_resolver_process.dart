/// Resolves a CLI binary's absolute path through the user's login shell so
/// PATH augmentations from `.zprofile` / `.bash_profile` (and, on the
/// fallback pass, `.zshrc`) are honoured.
///
/// macOS launches GUI apps with a stripped PATH
/// (`/usr/bin:/bin:/usr/sbin:/sbin`). Homebrew (`/opt/homebrew/bin`),
/// npm globals, nvm/asdf/mise shims, and `~/.local/bin` all live outside
/// that set, so a release `.app` cannot find tools that work fine under
/// `flutter run` (which inherits the launching terminal's full PATH).
///
/// Resolving once via `<shell> -l -c "command -v <bin>"` and caching the
/// absolute path — and the login shell's expanded PATH — lets every
/// subsequent `Process.start` skip PATH lookup and run Node-backed
/// binaries (e.g. `codex`, which uses `#!/usr/bin/env node`) reliably.
library;

import 'dart:io';

import '../../../core/utils/debug_logger.dart';

/// Subset accepted for `binaryName`. Currently both call sites pass a
/// hardcoded constant (`claude`, `codex`), but provider TODOs plan to read
/// this from user settings — guard the shell-quote boundary now.
///
/// Leading `-` is rejected so that a value like `-version` cannot be
/// parsed as a flag by `command` (mirrors the flag-shaped-argument guard
/// in `provider_input_guards.dart`).
final RegExp _safeBinaryNameRegex = RegExp(r'^[a-zA-Z0-9_./][a-zA-Z0-9_./-]*$');

/// Subset accepted for `$SHELL`. The login system sets this from
/// `/etc/passwd`, but a stray value would be a shell-invocation vector.
final RegExp _safeShellPathRegex = RegExp(r'^/[a-zA-Z0-9_./-]+$');

/// Outcome of a login-shell probe. Three cases let callers distinguish
/// "not installed" (UI: install) from "probe could not run" (UI: retry /
/// reinstall) — the original `Future<String?>` API collapsed both into
/// `null` and lost that distinction.
sealed class BinaryResolution {
  const BinaryResolution();
}

/// Binary was found. [path] is the absolute path to the executable.
/// [shellPath] is the login shell's expanded PATH value — pass this as
/// `PATH` in the environment of any process that invokes the binary, so
/// that shebang interpreters (e.g. `node` for `#!/usr/bin/env node`)
/// are reachable even in a release `.app` with a stripped inherited PATH.
class BinaryFound extends BinaryResolution {
  const BinaryFound(this.path, {this.shellPath});
  final String path;
  final String? shellPath;
}

class BinaryNotFound extends BinaryResolution {
  const BinaryNotFound();
}

class BinaryProbeFailed extends BinaryResolution {
  const BinaryProbeFailed(this.reason);
  final String reason;
}

/// Resolves [binaryName] via the user's login shell. Tries `-l` first
/// (fast, clean — sources `.zprofile` only). If that returns NotFound,
/// retries with `-l -i` (sources `.zshrc` too, which is where nvm / asdf
/// / mise / many npm-global setups inject their PATH). The interactive
/// pass uses a permissive parser (last `/`-prefixed line) because chatty
/// `.zshrc`s routinely print to stdout before `command -v` runs.
Future<BinaryResolution> resolveBinary(String binaryName) async {
  if (!_safeBinaryNameRegex.hasMatch(binaryName)) {
    sLog('[binaryResolver] rejected unsafe binary name: $binaryName');
    return BinaryProbeFailed('unsafe binary name: $binaryName');
  }

  final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
  if (!_safeShellPathRegex.hasMatch(shell)) {
    sLog('[binaryResolver] rejected unsafe SHELL: $shell');
    return BinaryProbeFailed('unsafe SHELL: $shell');
  }

  // Pass 1 — login-only. Fast and the stdout is reliably just the
  // resolved path, so the strict parser applies.
  final loginResult = await _probe(shell, binaryName, interactive: false);
  if (loginResult is! BinaryNotFound) return loginResult;

  // Pass 2 — login + interactive. Catches nvm / asdf / mise / npm-global
  // setups that source from `.zshrc`. Use the permissive parser because
  // a chatty `.zshrc` is the norm here.
  sLog('[binaryResolver] $binaryName not found via $shell -l; retrying with -l -i');
  return _probe(shell, binaryName, interactive: true);
}

/// Probe command appends `:::$PATH` so we can capture the shell's
/// expanded PATH alongside the binary path in a single invocation.
/// The `:::` sentinel cannot appear in a valid absolute path.
const _pathSentinel = ':::';

Future<BinaryResolution> _probe(String shell, String binaryName, {required bool interactive}) async {
  final flags = interactive ? '-l -i' : '-l';
  final ProcessResult result;
  try {
    final args = [if (interactive) '-i', '-l', '-c', 'command -v $binaryName && echo "$_pathSentinel\$PATH"'];
    result = await Process.run(shell, args).timeout(const Duration(seconds: 8));
  } catch (e) {
    sLog('[binaryResolver] $shell $flags probe failed for $binaryName: $e');
    return BinaryProbeFailed('$shell $flags probe failed: ${e.runtimeType}');
  }

  if (result.exitCode != 0) {
    final stderr = (result.stderr as String).trim();
    sLog('[binaryResolver] $binaryName not found via $shell $flags (exit ${result.exitCode}, stderr=$stderr)');
    return const BinaryNotFound();
  }

  final stdout = result.stdout as String;
  final lines = stdout.split('\n');

  // Extract the shell PATH from the sentinel line (if present).
  final shellPath = lines
      .where((l) => l.trimLeft().startsWith(_pathSentinel))
      .map((l) => l.trimLeft().substring(_pathSentinel.length).trim())
      .where((p) => p.isNotEmpty)
      .firstOrNull;

  // Extract the binary path — either strict (single absolute line) or
  // permissive (last non-sentinel absolute-path-shaped line).
  final String? resolved;
  if (interactive) {
    // Permissive: chatty .zshrc may print before command -v runs.
    resolved = lines.reversed
        .where((l) {
          final t = l.trim();
          return t.startsWith('/') && !t.contains(' ') && !t.startsWith(_pathSentinel);
        })
        .map((l) => l.trim())
        .firstOrNull;
  } else {
    // Strict: login-only stdout should be just the binary path (+ sentinel).
    final candidate = lines
        .where((l) {
          final t = l.trim();
          return t.startsWith('/') && !t.contains('\n') && !t.startsWith(_pathSentinel);
        })
        .map((l) => l.trim())
        .firstOrNull;
    // Reject multi-segment output (alias text, banner lines).
    resolved = (candidate != null && !candidate.contains(' ')) ? candidate : null;
  }

  if (resolved == null) {
    final preview = stdout.length > 256 ? '${stdout.substring(0, 256)}…' : stdout;
    sLog('[binaryResolver] $binaryName: $shell $flags returned no absolute-path line; stdout=$preview');
    return const BinaryNotFound();
  }
  return BinaryFound(resolved, shellPath: shellPath);
}
