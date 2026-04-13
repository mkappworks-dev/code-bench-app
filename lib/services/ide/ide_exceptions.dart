class IdeLaunchFailedException implements Exception {
  IdeLaunchFailedException(this.editor, this.path, [this.detail]);

  final String editor;
  final String path;
  final String? detail;

  @override
  String toString() => 'Failed to launch $editor for "$path"${detail != null ? ': $detail' : ''}';
}
