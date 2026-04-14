import 'dart:io';

import '../../../core/utils/debug_logger.dart';
import '../git_exceptions.dart';
import '../models/git_changed_file.dart';
import 'git_datasource.dart';

class GitDatasourceProcess implements GitDatasource {
  GitDatasourceProcess(this._projectPath);

  final String _projectPath;

  /// Strips GitHub tokens and embedded basic-auth credentials from [input]
  /// so git stderr can be safely rendered in the UI and logs.
  ///
  /// The app never injects PATs into git remote URLs, but a user's global
  /// git credential helper could echo one back in an error message (e.g.
  /// "fatal: Authentication failed for https://x-access-token:ghp_…@github.com/…").
  /// This is defence-in-depth so no UI path can accidentally leak a token.
  static String _sanitizeGitStderr(String input) {
    // 1. Classic + fine-grained GitHub PATs.
    var out = input.replaceAll(RegExp(r'(ghp|gho|ghu|ghs|ghr|github_pat)_[A-Za-z0-9_]{20,}'), '[redacted-token]');
    // 2. Basic auth embedded in https URLs
    //    (e.g. https://user:pat@github.com/… → https://[redacted]@github.com/…).
    out = out.replaceAllMapped(RegExp(r'(https?://)([^/@\s]+)@'), (m) => '${m[1]}[redacted]@');
    return out;
  }

  /// Runs `git init` in [_projectPath]. Throws [GitException] on failure.
  @override
  Future<void> initGit() async {
    final result = await Process.run('git', ['init'], workingDirectory: _projectPath);
    if (result.exitCode != 0) {
      throw GitException('git init failed: ${_sanitizeGitStderr(result.stderr as String)}');
    }
  }

  /// Stages all changes and commits with [message].
  /// Returns the short SHA of the new commit.
  @override
  Future<String> commit(String message) async {
    final addResult = await Process.run('git', ['add', '-A'], workingDirectory: _projectPath);
    if (addResult.exitCode != 0) {
      throw GitException('git add failed: ${_sanitizeGitStderr(addResult.stderr as String)}');
    }
    final commitResult = await Process.run('git', ['commit', '-m', message], workingDirectory: _projectPath);
    if (commitResult.exitCode != 0) {
      throw GitException('git commit failed: ${_sanitizeGitStderr(commitResult.stderr as String)}');
    }
    // Extract short SHA from output like "[main abc1234] message" or
    // "[feat/2026-04-10-foo abc1234] message" or "[main (root-commit) abc1234]".
    // Branch refs can contain `-` and `/`, so accept any non-space, non-`]`.
    final out = commitResult.stdout as String;
    final match = RegExp(r'\[[^\s\]]+(?:\s+\([^)]+\))?\s+([a-f0-9]+)\]').firstMatch(out);
    if (match == null) {
      // Fall back to `git rev-parse HEAD` if parsing fails — never return ''.
      final rev = await Process.run('git', ['rev-parse', '--short', 'HEAD'], workingDirectory: _projectPath);
      if (rev.exitCode == 0) return (rev.stdout as String).trim();
      throw GitException('Commit succeeded but could not parse SHA');
    }
    return match.group(1)!;
  }

  /// Runs `git push`. Returns the branch name pushed to.
  @override
  Future<String> push() async {
    final branch = await _currentBranch() ?? '';

    final result = await Process.run('git', ['push'], workingDirectory: _projectPath);
    if (result.exitCode != 0) {
      final stderr = result.stderr as String;
      if (stderr.contains('no upstream')) {
        throw GitNoUpstreamException(branch);
      }
      if (stderr.contains('Authentication') || stderr.contains('could not read Username')) {
        throw GitAuthException();
      }
      throw GitException(_sanitizeGitStderr(stderr.trim()));
    }
    return branch;
  }

  /// Runs `git pull`. Returns number of new commits pulled (computed by
  /// diffing HEAD before and after).
  @override
  Future<int> pull() async {
    // Capture HEAD before the pull so we can count commits accurately.
    // (git pull's summary line reports *files* changed, not *commits*.)
    final preSha = await _headSha();

    final result = await Process.run('git', ['pull'], workingDirectory: _projectPath);
    if (result.exitCode != 0) {
      final stderr = result.stderr as String;
      if (stderr.contains('CONFLICT') || (result.stdout as String).contains('CONFLICT')) {
        throw GitConflictException();
      }
      if (stderr.contains('no tracking information') || stderr.contains('no upstream')) {
        throw GitNoUpstreamException('');
      }
      throw GitException(_sanitizeGitStderr(stderr.trim()));
    }

    if (preSha == null) return 0;
    final countResult = await Process.run(
      'git',
      // `--` separates the revision range from any accidental pathspec.
      ['rev-list', '--count', '$preSha..HEAD', '--'],
      workingDirectory: _projectPath,
    );
    if (countResult.exitCode != 0) return 0;
    return int.tryParse((countResult.stdout as String).trim()) ?? 0;
  }

  /// Fetches and returns how many commits HEAD is behind origin/[branch].
  /// Returns `null` if the count could not be determined (no remote, no
  /// upstream, offline, or any other failure). Callers should render this
  /// as an unknown/unavailable state rather than as "up to date".
  @override
  Future<int?> fetchBehindCount() async {
    final branch = await _currentBranch();
    if (branch == null) return null;
    // Defence-in-depth: if the current branch name starts with `-` (a
    // hostile ref name baked into a cloned-from-attacker .git), refuse to
    // interpolate it into the rev-list range. `git check-ref-format`
    // normally rejects these, but don't rely on that guarantee.
    if (branch.startsWith('-')) return null;

    final fetchResult = await Process.run('git', ['fetch', '--quiet'], workingDirectory: _projectPath);
    if (fetchResult.exitCode != 0) return null;

    final countResult = await Process.run(
      'git',
      // `--` guards against a branch literally named `-x` being parsed as a flag.
      ['rev-list', '--count', 'HEAD..origin/$branch', '--'],
      workingDirectory: _projectPath,
    );
    if (countResult.exitCode != 0) return null;
    return int.tryParse((countResult.stdout as String).trim());
  }

  /// Returns the current branch name, or `null` if it cannot be determined.
  @override
  Future<String?> currentBranch() => _currentBranch();

  Future<String?> _currentBranch() async {
    final result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD'], workingDirectory: _projectPath);
    if (result.exitCode != 0) return null;
    final branch = (result.stdout as String).trim();
    if (branch.isEmpty) return null;
    // `rev-parse --abbrev-ref HEAD` prints the literal string "HEAD" (exit 0)
    // when the repo is in detached-HEAD state. Map that to `null` so callers
    // can distinguish "detached" from "on a real branch named HEAD" — and
    // so the status bar renders "(detached)" rather than "HEAD", and the
    // Open PR button's `isOnDefaultBranch` check stays correct.
    if (branch == 'HEAD') return null;
    return branch;
  }

  Future<String?> _headSha() async {
    final result = await Process.run('git', ['rev-parse', 'HEAD'], workingDirectory: _projectPath);
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trim();
  }

  /// Returns the URL of the configured `origin` remote, or `null` if unset.
  @override
  Future<String?> getOriginUrl() async {
    final result = await Process.run('git', ['remote', 'get-url', 'origin'], workingDirectory: _projectPath);
    if (result.exitCode != 0) return null;
    final url = (result.stdout as String).trim();
    return url.isEmpty ? null : url;
  }

  /// Returns list of configured git remotes.
  @override
  Future<List<GitRemote>> listRemotes() async {
    final result = await Process.run('git', ['remote', '-v'], workingDirectory: _projectPath);
    if (result.exitCode != 0) return [];
    final lines = (result.stdout as String).trim().split('\n');
    final seen = <String>{};
    final remotes = <GitRemote>[];
    for (final line in lines) {
      if (line.isEmpty) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final name = parts[0];
      final url = parts[1];
      if (seen.add(name)) {
        remotes.add(GitRemote(name: name, url: url));
      }
    }
    return remotes;
  }

  /// Returns local branch names, current branch first, then alphabetical.
  @override
  Future<List<String>> listLocalBranches() async {
    final result = await Process.run('git', ['branch', '--format=%(refname:short)'], workingDirectory: _projectPath);
    if (result.exitCode != 0) return const [];
    final all = (result.stdout as String).trim().split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final current = await _currentBranch();
    if (current != null) {
      all.remove(current);
      return [current, ...all..sort()];
    }
    return all..sort();
  }

  /// Returns a map of branch name → worktree filesystem path for every
  /// git worktree OTHER than this one ([_projectPath]).
  ///
  /// Skips the block whose `worktree` path matches [_projectPath] so the
  /// current working tree is never reported as "occupied elsewhere".
  /// This path-based skip is correct for both the main working tree (block 0
  /// = self) and linked worktrees (block 0 is the main repo, NOT self).
  @override
  Future<Map<String, String>> worktreeBranches() async {
    final result = await Process.run('git', ['worktree', 'list', '--porcelain'], workingDirectory: _projectPath);
    if (result.exitCode != 0) return const {};
    final blocks = (result.stdout as String).trim().split(RegExp(r'\n\n+'));
    final map = <String, String>{};
    for (final block in blocks) {
      final lines = block.split('\n');
      final worktreeLine = lines.firstWhere((l) => l.startsWith('worktree '), orElse: () => '');
      final worktreePath = worktreeLine.substring('worktree '.length).trim();
      if (worktreePath == _projectPath || worktreePath.isEmpty) continue;
      String? branch;
      for (final line in lines) {
        if (line.startsWith('branch ')) {
          branch = line.substring('branch '.length).trim().replaceFirst('refs/heads/', '');
          break;
        }
      }
      if (branch != null) map[branch] = worktreePath;
    }
    return map;
  }

  /// Switches the working tree to [branch] using `git switch`.
  ///
  /// Uses `git switch` (git 2.23+, 2019) rather than `git checkout` so a
  /// branch name that happens to match a tracked file path cannot fall
  /// through to "restore this file" semantics — `switch` only operates on
  /// refs, never pathspecs.
  /// Throws [ArgumentError] for flag-shaped names, [GitException] on git failure.
  @override
  Future<void> checkout(String branch) async {
    if (branch.isEmpty) throw ArgumentError('Branch name must not be empty.');
    if (branch.startsWith('-')) {
      sLog('[GitDatasourceProcess] flag-shaped checkout branch rejected: "$branch"');
      throw ArgumentError('Branch name must not start with a dash.');
    }
    final result = await Process.run('git', ['switch', branch], workingDirectory: _projectPath);
    if (result.exitCode != 0) {
      throw GitException(
        (result.stderr as String).trim().isNotEmpty ? (result.stderr as String).trim() : 'git switch failed',
      );
    }
  }

  /// Validates [name] and runs `git checkout -b [name]`.
  /// Throws [ArgumentError] for flag-shaped names, [GitException] on git failure.
  @override
  Future<void> createBranch(String name) async {
    if (name.isEmpty) throw ArgumentError('Branch name must not be empty.');
    if (name.startsWith('-')) {
      sLog('[GitDatasourceProcess] flag-shaped createBranch name rejected: "$name"');
      throw ArgumentError('Branch name must not start with a dash.');
    }
    if (name.contains(' ')) throw ArgumentError('Branch name must not contain spaces.');
    final result = await Process.run('git', ['checkout', '-b', name], workingDirectory: _projectPath);
    if (result.exitCode != 0) {
      throw GitException((result.stderr as String).trim());
    }
  }

  /// Pushes current branch to a named [remote].
  @override
  Future<void> pushToRemote(String remote) async {
    // Defense-in-depth: reject remotes that look like flags so a remote
    // literally named `-d` or `--delete` cannot alter `git push` semantics.
    if (remote.startsWith('-')) {
      sLog('[GitDatasourceProcess] flag-shaped remote rejected: "$remote"');
      throw GitException('Invalid remote name: $remote');
    }
    final branch = await _currentBranch() ?? '';
    // Same reasoning for the branch name — a hostile ref baked into
    // `.git/HEAD` could otherwise reach `git push <remote> <branch>` argv.
    if (branch.startsWith('-')) {
      sLog('[GitDatasourceProcess] flag-shaped branch rejected: "$branch"');
      throw GitException('Invalid branch name: $branch');
    }

    final result = await Process.run('git', ['push', remote, branch], workingDirectory: _projectPath);
    if (result.exitCode != 0) {
      throw GitException(_sanitizeGitStderr((result.stderr as String).trim()));
    }
  }

  /// Returns staged changes via `git diff --cached --numstat`.
  /// Falls back to `git diff --numstat HEAD` when nothing is staged.
  @override
  Future<List<GitChangedFile>> getChangedFiles() async {
    var result = await Process.run('git', ['diff', '--cached', '--numstat'], workingDirectory: _projectPath);
    var output = (result.stdout as String).trim();

    if (output.isEmpty && result.exitCode == 0) {
      result = await Process.run('git', ['diff', '--numstat', 'HEAD'], workingDirectory: _projectPath);
      output = (result.stdout as String).trim();
      if (result.exitCode != 0) {
        dLog('[GitDatasourceProcess] getChangedFiles HEAD diff failed (exit ${result.exitCode}): ${(result.stderr as String).trim()}');
        return [];
      }
    }

    if (output.isEmpty) return [];
    return output.split('\n').map(_parseLine).whereType<GitChangedFile>().toList();
  }

  static GitChangedFile? _parseLine(String line) {
    final parts = line.split('\t');
    if (parts.length < 3) return null;
    final additions = int.tryParse(parts[0]) ?? 0;
    final deletions = int.tryParse(parts[1]) ?? 0;
    final path = parts.sublist(2).join('\t').trim();
    if (path.isEmpty) return null;
    return GitChangedFile(
      path: path,
      additions: additions,
      deletions: deletions,
      status: _inferStatus(additions, deletions, path),
    );
  }

  static GitChangedFileStatus _inferStatus(int additions, int deletions, String path) {
    if (path.contains(' => ')) return GitChangedFileStatus.renamed;
    if (additions > 0 && deletions == 0) return GitChangedFileStatus.added;
    if (deletions > 0 && additions == 0) return GitChangedFileStatus.deleted;
    return GitChangedFileStatus.modified;
  }
}
