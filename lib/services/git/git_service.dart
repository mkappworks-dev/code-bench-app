import 'dart:io';

class GitRemote {
  const GitRemote({required this.name, required this.url});
  final String name;
  final String url;
}

class GitService {
  GitService(this.projectPath);

  final String projectPath;

  /// Strips GitHub tokens and embedded basic-auth credentials from [input]
  /// so git stderr can be safely rendered in the UI and logs.
  ///
  /// The app never injects PATs into git remote URLs, but a user's global
  /// git credential helper could echo one back in an error message (e.g.
  /// "fatal: Authentication failed for https://x-access-token:ghp_…@github.com/…").
  /// This is defence-in-depth so no UI path can accidentally leak a token.
  static String _sanitizeGitStderr(String input) {
    // 1. Classic + fine-grained GitHub PATs.
    var out = input.replaceAll(
      RegExp(r'(ghp|gho|ghu|ghs|ghr|github_pat)_[A-Za-z0-9_]{20,}'),
      '[redacted-token]',
    );
    // 2. Basic auth embedded in https URLs
    //    (e.g. https://user:pat@github.com/… → https://[redacted]@github.com/…).
    out = out.replaceAllMapped(
      RegExp(r'(https?://)([^/@\s]+)@'),
      (m) => '${m[1]}[redacted]@',
    );
    return out;
  }

  /// Runs `git init` in [projectPath]. Throws [GitException] on failure.
  Future<void> initGit() async {
    final result = await Process.run('git', ['init'], workingDirectory: projectPath);
    if (result.exitCode != 0) {
      throw GitException('git init failed: ${_sanitizeGitStderr(result.stderr as String)}');
    }
  }

  /// Stages all changes and commits with [message].
  /// Returns the short SHA of the new commit.
  Future<String> commit(String message) async {
    final addResult = await Process.run('git', ['add', '-A'], workingDirectory: projectPath);
    if (addResult.exitCode != 0) {
      throw GitException('git add failed: ${_sanitizeGitStderr(addResult.stderr as String)}');
    }
    final commitResult = await Process.run(
      'git',
      ['commit', '-m', message],
      workingDirectory: projectPath,
    );
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
      final rev = await Process.run(
        'git',
        ['rev-parse', '--short', 'HEAD'],
        workingDirectory: projectPath,
      );
      if (rev.exitCode == 0) return (rev.stdout as String).trim();
      throw GitException('Commit succeeded but could not parse SHA');
    }
    return match.group(1)!;
  }

  /// Runs `git push`. Returns the branch name pushed to.
  Future<String> push() async {
    final branch = await _currentBranch() ?? '';

    final result = await Process.run('git', ['push'], workingDirectory: projectPath);
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
  Future<int> pull() async {
    // Capture HEAD before the pull so we can count commits accurately.
    // (git pull's summary line reports *files* changed, not *commits*.)
    final preSha = await _headSha();

    final result = await Process.run('git', ['pull'], workingDirectory: projectPath);
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
      workingDirectory: projectPath,
    );
    if (countResult.exitCode != 0) return 0;
    return int.tryParse((countResult.stdout as String).trim()) ?? 0;
  }

  /// Fetches and returns how many commits HEAD is behind origin/[branch].
  /// Returns `null` if the count could not be determined (no remote, no
  /// upstream, offline, or any other failure). Callers should render this
  /// as an unknown/unavailable state rather than as "up to date".
  Future<int?> fetchBehindCount() async {
    final branch = await _currentBranch();
    if (branch == null) return null;
    // Defence-in-depth: if the current branch name starts with `-` (a
    // hostile ref name baked into a cloned-from-attacker .git), refuse to
    // interpolate it into the rev-list range. `git check-ref-format`
    // normally rejects these, but don't rely on that guarantee.
    if (branch.startsWith('-')) return null;

    final fetchResult = await Process.run(
      'git',
      ['fetch', '--quiet'],
      workingDirectory: projectPath,
    );
    if (fetchResult.exitCode != 0) return null;

    final countResult = await Process.run(
      'git',
      // `--` guards against a branch literally named `-x` being parsed as a flag.
      ['rev-list', '--count', 'HEAD..origin/$branch', '--'],
      workingDirectory: projectPath,
    );
    if (countResult.exitCode != 0) return null;
    return int.tryParse((countResult.stdout as String).trim());
  }

  /// Returns the current branch name, or `null` if it cannot be determined.
  Future<String?> currentBranch() => _currentBranch();

  Future<String?> _currentBranch() async {
    final result = await Process.run(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0) return null;
    final branch = (result.stdout as String).trim();
    return branch.isEmpty ? null : branch;
  }

  Future<String?> _headSha() async {
    final result = await Process.run(
      'git',
      ['rev-parse', 'HEAD'],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trim();
  }

  /// Returns the URL of the configured `origin` remote, or `null` if unset.
  Future<String?> getOriginUrl() async {
    final result = await Process.run(
      'git',
      ['remote', 'get-url', 'origin'],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0) return null;
    final url = (result.stdout as String).trim();
    return url.isEmpty ? null : url;
  }

  /// Returns list of configured git remotes.
  Future<List<GitRemote>> listRemotes() async {
    final result = await Process.run('git', ['remote', '-v'], workingDirectory: projectPath);
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

  /// Pushes current branch to a named [remote].
  Future<void> pushToRemote(String remote) async {
    // Defense-in-depth: reject remotes that look like flags so a remote
    // literally named `-d` or `--delete` cannot alter `git push` semantics.
    if (remote.startsWith('-')) {
      throw GitException('Invalid remote name: $remote');
    }
    final branch = await _currentBranch() ?? '';
    // Same reasoning for the branch name — a hostile ref baked into
    // `.git/HEAD` could otherwise reach `git push <remote> <branch>` argv.
    if (branch.startsWith('-')) {
      throw GitException('Invalid branch name: $branch');
    }

    final result = await Process.run(
      'git',
      ['push', remote, branch],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0) {
      throw GitException(_sanitizeGitStderr((result.stderr as String).trim()));
    }
  }
}

class GitException implements Exception {
  const GitException(this.message);
  final String message;
  @override
  String toString() => 'GitException: $message';
}

class GitNoUpstreamException extends GitException {
  const GitNoUpstreamException(String branch) : super('No upstream branch for $branch');
}

class GitAuthException extends GitException {
  const GitAuthException() : super('Authentication failed');
}

class GitConflictException extends GitException {
  const GitConflictException() : super('Merge conflict detected');
}
