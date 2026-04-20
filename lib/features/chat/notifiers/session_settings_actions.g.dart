// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_settings_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Coordinator notifier that loads and persists the five per-session chat
/// settings (model, system prompt, mode, effort, permission).
///
/// Reacts to [activeSessionIdProvider] changes and pushes the stored values
/// into their respective reactive notifiers so [ChatInputBar] always reflects
/// the active session's settings.

@ProviderFor(SessionSettingsActions)
final sessionSettingsActionsProvider = SessionSettingsActionsProvider._();

/// Coordinator notifier that loads and persists the five per-session chat
/// settings (model, system prompt, mode, effort, permission).
///
/// Reacts to [activeSessionIdProvider] changes and pushes the stored values
/// into their respective reactive notifiers so [ChatInputBar] always reflects
/// the active session's settings.
final class SessionSettingsActionsProvider extends $AsyncNotifierProvider<SessionSettingsActions, void> {
  /// Coordinator notifier that loads and persists the five per-session chat
  /// settings (model, system prompt, mode, effort, permission).
  ///
  /// Reacts to [activeSessionIdProvider] changes and pushes the stored values
  /// into their respective reactive notifiers so [ChatInputBar] always reflects
  /// the active session's settings.
  SessionSettingsActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionSettingsActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionSettingsActionsHash();

  @$internal
  @override
  SessionSettingsActions create() => SessionSettingsActions();
}

String _$sessionSettingsActionsHash() => r'8fd25a055e425de905f98755368f5001ffed4773';

/// Coordinator notifier that loads and persists the five per-session chat
/// settings (model, system prompt, mode, effort, permission).
///
/// Reacts to [activeSessionIdProvider] changes and pushes the stored values
/// into their respective reactive notifiers so [ChatInputBar] always reflects
/// the active session's settings.

abstract class _$SessionSettingsActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>, AsyncValue<void>, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
