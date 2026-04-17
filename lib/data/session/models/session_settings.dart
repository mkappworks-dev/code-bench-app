enum ChatMode { chat, plan, act }

enum ChatEffort { low, medium, high, max }

enum ChatPermission { readOnly, askBefore, fullAccess }

extension ChatModeLabel on ChatMode {
  String get label => switch (this) {
    ChatMode.chat => 'Chat',
    ChatMode.plan => 'Plan',
    ChatMode.act => 'Act',
  };
}

extension ChatEffortLabel on ChatEffort {
  String get label => switch (this) {
    ChatEffort.low => 'Low',
    ChatEffort.medium => 'Medium',
    ChatEffort.high => 'High',
    ChatEffort.max => 'Max',
  };
}

extension ChatPermissionLabel on ChatPermission {
  String get label => switch (this) {
    ChatPermission.readOnly => 'Read only',
    ChatPermission.askBefore => 'Ask before changes',
    ChatPermission.fullAccess => 'Full access',
  };
}
