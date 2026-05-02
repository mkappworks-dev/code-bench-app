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
/// Leading `-` is rejected (flag-shaped-argument guard). `/` is rejected so
/// only bare binary names are accepted; absolute-path overrides must be
/// validated explicitly by the call site.
final RegExp _safeBinaryNameRegex = RegExp(r'^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$');

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
/// retries with `-i -l` (sources `.zshrc` too, which is where nvm / asdf
/// / mise / many npm-global setups inject their PATH).
Future<BinaryResolution> resolveBinary(String binaryName) async {
  if (!_safeBinaryNameRegex.hasMatch(binaryName)) {
    sLog('[binaryResolver] rejected unsafe binary name: $binaryName');
    return BinaryProbeFailed('unsafe binary name: $binaryName');
  }

  final shellEnv = Platform.environment['SHELL'];
  if (shellEnv == null) {
    sLog('[binaryResolver] SHELL env var not set, falling back to /bin/zsh');
  }
  final shell = shellEnv ?? '/bin/zsh';
  if (!_safeShellPathRegex.hasMatch(shell)) {
    sLog('[binaryResolver] rejected unsafe SHELL: $shell');
    return BinaryProbeFailed('unsafe SHELL: $shell');
  }

  // Pass 1 — login-only. Sources `.zprofile` / `.bash_profile`.
  final loginResult = await _probe(shell, binaryName, interactive: false);
  if (loginResult is! BinaryNotFound) return loginResult;

  // Pass 2 — login + interactive. Sources `.zshrc` too, which is where
  // nvm / asdf / mise / npm-global PATH augmentations live.
  sLog('[binaryResolver] $binaryName not found via $shell -l; retrying with -i -l');
  return _probe(shell, binaryName, interactive: true);
}

/// Sentinel prefix for the PATH capture line. Cannot appear in a valid path.
const _pathSentinel = ':::';

/// Output markers bracketing `command -v` result. Prevents chatty `.zshrc`
/// lines from being mistaken for the resolved binary path.
const _outputStart = '__bench_br_s__';
const _outputEnd = '__bench_br_e__';

Future<BinaryResolution> _probe(String shell, String binaryName, {required bool interactive}) async {
  final flags = interactive ? '-i -l' : '-l';
  final ProcessResult result;
  try {
    // binaryName is passed as positional arg $1 — not interpolated into the
    // script — so the regex is defence-in-depth, not the sole injection guard.
    // Sentinels bracket command -v output so chatty .zshrc lines before/after
    // cannot be mistaken for the resolved path.
    final script = "echo '$_outputStart' && command -v \"\$1\" && echo '$_outputEnd' && echo \"$_pathSentinel\$PATH\"";
    final args = [if (interactive) '-i', '-l', '-c', script, shell, binaryName];
    result = await Process.run(shell, args).timeout(const Duration(seconds: 8));
  } catch (e) {
    sLog('[binaryResolver] $shell $flags probe failed for $binaryName: $e');
    return BinaryProbeFailed('$shell $flags probe failed: ${e.runtimeType}');
  }

  if (result.exitCode != 0) {
    final stderr = (result.stderr as String).trim();
    if (result.exitCode == 1 && stderr.isEmpty) {
      // Standard "command -v found nothing" — clean not-found.
      sLog('[binaryResolver] $binaryName not found via $shell $flags (exit 1)');
      return const BinaryNotFound();
    }
    // Non-standard exit or stderr present → shell/profile failure, not a
    // clean binary miss. Return BinaryProbeFailed so the UI shows retry
    // rather than an install prompt.
    sLog(
      '[binaryResolver] $shell $flags exited ${result.exitCode} probing $binaryName; '
      'stderr=${redactSecrets(stderr)}',
    );
    return BinaryProbeFailed('$shell $flags exited ${result.exitCode}');
  }

  final stdout = result.stdout as String;
  final lines = stdout.split('\n');

  // Extract the shell PATH from the sentinel line (if present). Sanitise
  // entries before use: drop empty, `.`, `..`, and non-absolute components
  // so a `.` in the user's PATH cannot become a cwd-based lookup when
  // child processes are spawned inside a user project directory.
  final rawShellPath = lines
      .where((l) => l.trimLeft().startsWith(_pathSentinel))
      .map((l) => l.trimLeft().substring(_pathSentinel.length).trim())
      .where((p) => p.isNotEmpty)
      .firstOrNull;
  final shellPath = rawShellPath != null ? _sanitizeShellPath(rawShellPath) : null;

  // Extract the binary path from between the bracketed sentinels. Any
  // output printed by .zshrc before __bench_br_s__ is ignored.
  final startIdx = lines.indexWhere((l) => l.trim() == _outputStart);
  final endIdx = lines.indexWhere((l) => l.trim() == _outputEnd);

  String? resolved;
  if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
    resolved = lines
        .sublist(startIdx + 1, endIdx)
        .map((l) => l.trim())
        .where((t) => t.startsWith('/') && !t.contains(' '))
        .firstOrNull;
  } else {
    // Sentinels absent (shouldn't happen with our script). Fall back to
    // last absolute-path-shaped line, same as the original permissive parser.
    resolved = lines.reversed
        .map((l) => l.trim())
        .where((t) => t.startsWith('/') && !t.contains(' ') && !t.startsWith(_pathSentinel))
        .firstOrNull;
    if (resolved != null) {
      sLog('[binaryResolver] sentinels absent for $binaryName via $shell $flags — used fallback parser');
    }
  }

  if (resolved == null) {
    final preview = stdout.length > 256 ? '${stdout.substring(0, 256)}…' : stdout;
    sLog(
      '[binaryResolver] $binaryName: $shell $flags returned no path; '
      'stdout=${redactSecrets(preview)}',
    );
    return const BinaryNotFound();
  }

  // Validate the path points to an actual file. The permissive fallback
  // parser could otherwise return a directory path (e.g. /opt/homebrew/opt/node@18)
  // from chatty shell output, causing a misleading BinaryFound result.
  if (!File(resolved).existsSync()) {
    sLog('[binaryResolver] resolved path does not exist: $resolved');
    return BinaryProbeFailed('resolved path does not exist: $resolved');
  }

  return BinaryFound(resolved, shellPath: shellPath);
}

/// Sanitises a raw login-shell PATH string. Drops empty, `.`, `..`, and
/// non-absolute entries. A `.` entry in PATH resolves to cwd at tool lookup,
/// which is a PATH-hijack vector when processes run inside user project dirs.
String _sanitizeShellPath(String raw) {
  final clean = raw.split(':').where((e) => e.isNotEmpty && e != '.' && e != '..' && e.startsWith('/')).join(':');
  return clean.isEmpty ? raw : clean;
}
