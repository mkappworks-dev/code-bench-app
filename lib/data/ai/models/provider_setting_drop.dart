import '../../shared/session_settings.dart';

/// One per-turn capability downgrade, stamped on the assistant message so the UI can surface it without a missable snackbar.
sealed class ProviderSettingDrop {
  const ProviderSettingDrop({required this.reason});
  final String reason;
}

class ProviderSettingDropMode extends ProviderSettingDrop {
  const ProviderSettingDropMode({required this.requested, required super.reason});
  final ChatMode requested;
}

class ProviderSettingDropEffort extends ProviderSettingDrop {
  const ProviderSettingDropEffort({required this.requested, this.applied, required super.reason});
  final ChatEffort requested;
  final ChatEffort? applied;
}

class ProviderSettingDropThinkingBudget extends ProviderSettingDrop {
  const ProviderSettingDropThinkingBudget({
    required this.requestedTokens,
    required this.appliedTokens,
    required super.reason,
  });
  final int requestedTokens;
  final int appliedTokens;
}

typedef ProviderSettingDropSink = void Function(ProviderSettingDrop drop);
