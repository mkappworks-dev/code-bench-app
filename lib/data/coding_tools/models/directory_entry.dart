/// A single entry returned by [CodingToolsRepository.listDirectory].
///
/// [entityType] is one of `'file'`, `'directory'`, or `'link'` — plain
/// strings so the repository interface has no dart:io dependency.
typedef DirectoryEntry = ({String path, String entityType});
