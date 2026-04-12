extension RelativeTime on DateTime {
  /// Returns a human-readable relative-time string compared to now.
  ///
  /// Examples: `"3m ago"`, `"2h ago"`, `"5d ago"`.
  String get relativeTime {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
