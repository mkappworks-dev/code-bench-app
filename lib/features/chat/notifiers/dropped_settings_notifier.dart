import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/provider_setting_drop.dart';

part 'dropped_settings_notifier.g.dart';

/// Per-message buffer of provider-side capability downgrades. Populated by
/// `ChatMessagesNotifier.sendMessage` when the request couldn't be honoured
/// verbatim — e.g. `act` mode coerced to `chat` on a tools-incapable
/// transport, or `reasoning_effort=high` stripped after an unknown-field 400
/// from a custom OpenAI-compatible endpoint. Read by `MessageBubble` to
/// render an inline notice. Not persisted: drops only matter for the live
/// turn; on app restart the message renders without the notice.
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
