class DuplicateProjectPathException implements Exception {
  DuplicateProjectPathException(this.path);
  final String path;

  @override
  String toString() => 'A project at "$path" already exists in Code Bench.';
}
