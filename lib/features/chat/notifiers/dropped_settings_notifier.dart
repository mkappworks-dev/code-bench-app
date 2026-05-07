import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/provider_setting_drop.dart';

part 'dropped_settings_notifier.g.dart';

/// Per-message buffer of provider-side capability downgrades for the live turn — not persisted; cleared on app restart.
@Riverpod(keepAlive: true)
class MessageDroppedSettingsNotifier extends _$MessageDroppedSettingsNotifier {
  @override
  Map<String, List<ProviderSettingDrop>> build() => {};

  void add(String messageId, ProviderSettingDrop drop) {
    final list = state[messageId] ?? const <ProviderSettingDrop>[];
    state = {
      ...state,
      messageId: [...list, drop],
    };
  }

  void addAll(String messageId, Iterable<ProviderSettingDrop> drops) {
    if (drops.isEmpty) return;
    final list = state[messageId] ?? const <ProviderSettingDrop>[];
    state = {
      ...state,
      messageId: [...list, ...drops],
    };
  }

  List<ProviderSettingDrop> forMessage(String messageId) => state[messageId] ?? const [];
}
