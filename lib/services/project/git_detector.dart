import 'dart:io';

import '../../core/utils/debug_logger.dart';

class GitDetector {
  /// Returns `true` when [directoryPath] is a git repository or a git
  /// worktree whose `.git` file points at a legitimate worktree metadata
  /// directory.
  ///
  /// ## Why the `.git` file needs validation
  ///
  /// In a plain repo `.git` is a directory and this is uninteresting —
  /// git owns it. In a worktree created by `git worktree add`, `.git` is a
  /// *file* containing `gitdir: <path>`. Git happily follows that pointer
  /// to any absolute path on disk, so a project folder delivered by an
  /// attacker (e.g. via a zip) could ship a `.git` file pointing to
  /// `/Users/victim/some-unrelated-repo/.git`. The app would then probe
  /// that unrelated repo and — via the `behindCount` timer — run
  /// `git fetch` against its remote. Path traversal is the attack surface;
  /// `git fetch` side effects are the blast radius.
  ///
  /// We only accept a `.git` file whose canonical `gitdir:` target
  /// contains a `/.git/worktrees/` or `/.git/modules/` segment, which is
  /// how both `git worktree add` and submodules structure the pointer.
  /// Anything else is logged via `sLog` and rejected.
  static bool isGitRepo(String directoryPath) {
    final gitPath = '$directoryPath${Platform.pathSeparator}.git';
    final type = FileSystemEntity.typeSync(gitPath);
    if (type == FileSystemEntityType.directory) return true;
    if (type != FileSystemEntityType.file) return false;

    return _isValidWorktreeGitFile(gitPath, projectPath: directoryPath);
  }

  /// Parses a `.git` file's `gitdir:` pointer and canonicalizes it.
  /// Returns `true` only when the resolved target is a directory whose
  /// path includes a known-legitimate git metadata segment. Any other
  /// shape (non-existent, escapes to an unrelated location) is rejected
  /// and logged.
  static bool _isValidWorktreeGitFile(String gitFilePath, {required String projectPath}) {
    final String content;
    try {
      content = File(gitFilePath).readAsStringSync();
    } on FileSystemException catch (e) {
      sLog('[GitDetector] .git file read failed at $gitFilePath: ${e.message}');
      return false;
    }

    final match = RegExp(r'^\s*gitdir:\s*(.+?)\s*$', multiLine: true).firstMatch(content);
    if (match == null) {
      sLog('[GitDetector] .git file at $gitFilePath has no `gitdir:` line — rejecting');
      return false;
    }
    final rawTarget = match.group(1)!;

    // Resolve relative targets against the project directory (the conventional
    // base when `.git` is a file), then canonicalize to strip `..` segments.
    final resolvedInput = rawTarget.startsWith(Platform.pathSeparator)
        ? rawTarget
        : '$projectPath${Platform.pathSeparator}$rawTarget';

    final String canonical;
    try {
      // `resolveSymbolicLinksSync` requires the path to exist. A legitimate
      // worktree or submodule target always exists; a malicious or stale
      // pointer may not — in either case, reject.
      canonical = Directory(resolvedInput).resolveSymbolicLinksSync();
    } on FileSystemException catch (e) {
      sLog('[GitDetector] .git file gitdir target at $resolvedInput could not be canonicalized: ${e.message}');
      return false;
    }

    // Legitimate git-worktree targets look like `<repo>/.git/worktrees/<name>`.
    // Legitimate submodule targets look like `<superproject>/.git/modules/<name>`.
    // Anything else (arbitrary repo dirs, `.ssh`, etc.) is rejected — git
    // would otherwise silently probe and potentially `git fetch` an
    // unrelated repo that the user never intended to expose.
    final sep = Platform.pathSeparator;
    final allowedSegments = ['$sep.git${sep}worktrees$sep', '$sep.git${sep}modules$sep'];
    final ok = allowedSegments.any(canonical.contains);
    if (!ok) {
      sLog('[GitDetector] rejecting .git file pointing outside worktree/submodule metadata: $canonical');
      return false;
    }
    return true;
  }

  /// Synchronous helper that returns the current branch name, or `null` if
  /// it cannot be determined. Unlike [GitService.currentBranch], this is
  /// sync and suitable for call sites that cannot `await`.
  ///
  /// Returns `null` for detached HEAD (git prints the literal `"HEAD"`),
  /// for non-git directories, and on probe failure. The catch is narrow
  /// — only [ProcessException] is swallowed, so programmer errors
  /// ([TypeError], [StateError], OOM) still escape.
  static String? getCurrentBranch(String directoryPath) {
    if (!isGitRepo(directoryPath)) return null;
    try {
      final result = Process.runSync('git', ['rev-parse', '--abbrev-ref', 'HEAD'], workingDirectory: directoryPath);
      if (result.exitCode != 0) return null;
      final branch = (result.stdout as String).trim();
      if (branch.isEmpty) return null;
      // Detached HEAD — see [GitService._currentBranch] for the rationale.
      if (branch == 'HEAD') return null;
      return branch;
    } on ProcessException catch (e) {
      sLog('[GitDetector.getCurrentBranch] git rev-parse threw: ${e.message}');
      return null;
    }
  }
}
