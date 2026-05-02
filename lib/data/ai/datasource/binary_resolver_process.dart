/// Resolves a CLI binary's absolute path through the user's login shell so
/// PATH augmentations from `.zprofile` / `.bash_profile` are honoured.
///
/// macOS launches GUI apps with a stripped PATH
/// (`/usr/bin:/bin:/usr/sbin:/sbin`). Homebrew (`/opt/homebrew/bin`),
/// npm globals, nvm/asdf/mise shims, and `~/.local/bin` all live outside
/// that set, so a release `.app` cannot find tools that work fine under
/// `flutter run` (which inherits the launching terminal's full PATH).
///
/// Resolving once via `<shell> -l -c "command -v <bin>"` and caching the
/// absolute path lets every subsequent `Process.start` skip PATH lookup.
library;

import 'dart:io';

import '../../../core/utils/debug_logger.dart';

/// Subset accepted for `binaryName`. Currently both call sites pass a
/// hardcoded constant (`claude`, `codex`), but provider TODOs plan to read
/// this from user settings — guard the shell-quote boundary now.
final RegExp _safeBinaryNameRegex = RegExp(r'^[a-zA-Z0-9_./-]+$');

/// Subset accepted for `$SHELL`. The login system sets this from
/// `/etc/passwd`, but a stray value would be a shell-invocation vector.
final RegExp _safeShellPathRegex = RegExp(r'^/[a-zA-Z0-9_./-]+$');

/// Returns the absolute path of [binaryName] as resolved by the user's
/// login shell, or null if not found / probe errored.
///
/// Uses `-l` (login) but not `-i` (interactive): `.zprofile` is sourced
/// (where Homebrew installs its `brew shellenv` snippet) but `.zshrc` is
/// not, so a chatty interactive config can't poison our stdout parse.
Future<String?> resolveBinaryViaLoginShell(String binaryName) async {
  if (!_safeBinaryNameRegex.hasMatch(binaryName)) {
    sLog('[binaryResolver] rejected unsafe binary name: $binaryName');
    return null;
  }

  final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
  if (!_safeShellPathRegex.hasMatch(shell)) {
    sLog('[binaryResolver] rejected unsafe SHELL: $shell');
    return null;
  }

  final ProcessResult result;
  try {
    result = await Process.run(shell, ['-l', '-c', 'command -v $binaryName']).timeout(const Duration(seconds: 5));
  } catch (e) {
    sLog('[binaryResolver] login-shell probe failed for $binaryName: $e');
    return null;
  }
  if (result.exitCode != 0) return null;

  final resolved = (result.stdout as String).trim();
  // `command -v` on a non-builtin returns an absolute path. A relative
  // path or alias-shaped output (e.g. "claude: aliased to ...") means we
  // don't have a usable executable to hand to `Process.start`.
  if (resolved.isEmpty || !resolved.startsWith('/')) return null;
  return resolved;
}
