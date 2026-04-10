import 'dart:io';

class GitRemote {
  const GitRemote({required this.name, required this.url});
  final String name;
  final String url;
}

class GitService {
  GitService(this.projectPath);

  final String projectPath;

  /// Runs `git init` in [projectPath]. Throws [GitException] on failure.
  Future<void> initGit() async {
    final result = await Process.run('git', ['init'], workingDirectory: projectPath);
    if (result.exitCode != 0) {
      throw GitException('git init failed: ${result.stderr}');
    }
  }

  /// Stages all changes and commits with [message].
  /// Returns the short SHA of the new commit.
  Future<String> commit(String message) async {
    final addResult = await Process.run('git', ['add', '-A'], workingDirectory: projectPath);
    if (addResult.exitCode != 0) {
      throw GitException('git add failed: ${addResult.stderr}');
    }
    final commitResult = await Process.run(
      'git',
      ['commit', '-m', message],
      workingDirectory: projectPath,
    );
    if (commitResult.exitCode != 0) {
      throw GitException('git commit failed: ${commitResult.stderr}');
    }
    // Extract short SHA from output like "[main abc1234] message"
    // or "[main (root-commit) abc1234] message" for initial commits.
    final out = commitResult.stdout as String;
    final match = RegExp(r'\[[\w/]+(?:\s+\([^)]+\))?\s+([a-f0-9]+)\]').firstMatch(out);
    return match?.group(1) ?? '';
  }

  /// Runs `git push`. Returns the branch name pushed to.
  Future<String> push() async {
    final branchResult = await Process.run(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: projectPath,
    );
    final branch = (branchResult.stdout as String).trim();

    final result = await Process.run('git', ['push'], workingDirectory: projectPath);
    if (result.exitCode != 0) {
      final stderr = result.stderr as String;
      if (stderr.contains('no upstream')) {
        throw GitNoUpstreamException(branch);
      }
      if (stderr.contains('Authentication') || stderr.contains('could not read Username')) {
        throw GitAuthException();
      }
      throw GitException(stderr.trim());
    }
    return branch;
  }

  /// Runs `git pull`. Returns number of new commits pulled.
  Future<int> pull() async {
    final result = await Process.run('git', ['pull'], workingDirectory: projectPath);
    if (result.exitCode != 0) {
      final stderr = result.stderr as String;
      if (stderr.contains('CONFLICT') || (result.stdout as String).contains('CONFLICT')) {
        throw GitConflictException();
      }
      if (stderr.contains('no tracking information') || stderr.contains('no upstream')) {
        throw GitNoUpstreamException('');
      }
      throw GitException(stderr.trim());
    }
    // Count new commits from stdout pattern like "2 files changed"
    final match = RegExp(r'(\d+) file').firstMatch(result.stdout as String);
    return match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
  }

  /// Fetches and returns how many commits HEAD is behind origin/[branch].
  /// Returns 0 if no remote is configured or fetch fails.
  Future<int> fetchBehindCount() async {
    final branchResult = await Process.run(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: projectPath,
    );
    if (branchResult.exitCode != 0) return 0;
    final branch = (branchResult.stdout as String).trim();

    final fetchResult = await Process.run(
      'git',
      ['fetch', '--quiet'],
      workingDirectory: projectPath,
    );
    if (fetchResult.exitCode != 0) return 0;

    final countResult = await Process.run(
      'git',
      ['rev-list', 'HEAD..origin/$branch', '--count'],
      workingDirectory: projectPath,
    );
    if (countResult.exitCode != 0) return 0;
    return int.tryParse((countResult.stdout as String).trim()) ?? 0;
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
    final branchResult = await Process.run(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: projectPath,
    );
    final branch = (branchResult.stdout as String).trim();

    final result = await Process.run(
      'git',
      ['push', remote, branch],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0) {
      throw GitException((result.stderr as String).trim());
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
