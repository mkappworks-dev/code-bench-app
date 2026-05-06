import '../models/grep_match.dart';

/// Abstraction over grep backends. Two implementations:
/// - [GrepDatasourceProcess] — shells out to ripgrep when available.
/// - [GrepDatasourceIo] — pure-Dart fallback via dart:io.
abstract interface class GrepDatasource {
  Future<GrepResult> grep({
    required String pattern,
    required String rootPath,
    int contextLines = 2,
    int maxMatches = 100,
    List<String> fileExtensions = const [],
  });
}
