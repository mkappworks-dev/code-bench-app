// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dropped_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-message buffer of provider-side capability downgrades for the live turn — not persisted; cleared on app restart.

@ProviderFor(MessageDroppedSettingsNotifier)
final messageDroppedSettingsProvider = MessageDroppedSettingsNotifierProvider._();

/// Per-message buffer of provider-side capability downgrades for the live turn — not persisted; cleared on app restart.
final class MessageDroppedSettingsNotifierProvider
    extends $NotifierProvider<MessageDroppedSettingsNotifier, Map<String, List<ProviderSettingDrop>>> {
  /// Per-message buffer of provider-side capability downgrades for the live turn — not persisted; cleared on app restart.
  MessageDroppedSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageDroppedSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageDroppedSettingsNotifierHash();

  @$internal
  @override
  MessageDroppedSettingsNotifier create() => MessageDroppedSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<ProviderSettingDrop>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<ProviderSettingDrop>>>(value),
    );
  }
}

String _$messageDroppedSettingsNotifierHash() => r'4f18fbcd0211f00668ecbea938785bd0b14d4bf5';

/// Per-message buffer of provider-side capability downgrades for the live turn — not persisted; cleared on app restart.

abstract class _$MessageDroppedSettingsNotifier extends $Notifier<Map<String, List<ProviderSettingDrop>>> {
  Map<String, List<ProviderSettingDrop>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, List<ProviderSettingDrop>>, Map<String, List<ProviderSettingDrop>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, List<ProviderSettingDrop>>, Map<String, List<ProviderSettingDrop>>>,
              Map<String, List<ProviderSettingDrop>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
