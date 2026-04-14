/// A single file in the staged (or working-tree) diff, parsed from
/// `git diff --cached --numstat` output.
class GitChangedFile {
  const GitChangedFile({required this.path, required this.additions, required this.deletions, required this.status});

  final String path;
  final int additions;
  final int deletions;
  final GitChangedFileStatus status;
}

enum GitChangedFileStatus {
  added,
  modified,
  deleted,
  renamed;

  String get badge => switch (this) {
    GitChangedFileStatus.added => 'A',
    GitChangedFileStatus.modified => 'M',
    GitChangedFileStatus.deleted => 'D',
    GitChangedFileStatus.renamed => 'R',
  };
}
