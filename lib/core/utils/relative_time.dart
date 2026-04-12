extension RelativeTime on DateTime {
  /// Full relative-time string with "ago" suffix — e.g. `"3m ago"`, `"2h ago"`, `"5d ago"`.
  String get relativeTime {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Compact relative-time string without suffix — e.g. `"3m"`, `"2h"`, `"5d"`.
  String get relativeTimeCompact {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
