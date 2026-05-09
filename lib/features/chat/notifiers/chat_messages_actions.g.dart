// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_messages_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier for message-list mutations that can fail and need a
/// stable, observable error surface (typed `AsyncError` carrying a
/// [ChatMessagesFailure]).
///
/// Send/cancel stay on [ChatMessagesNotifier] because they own streaming
/// state. Delete and load-more live here so widgets can `ref.listen` for
/// failures without being entangled with the streaming `AsyncValue`.
///
/// Single global slot (no family): only one session is active at a time, and
/// we want one snackbar per failed operation regardless of how many bubbles
/// are on screen.

@ProviderFor(ChatMessagesActions)
final chatMessagesActionsProvider = ChatMessagesActionsProvider._();

/// Command notifier for message-list mutations that can fail and need a
/// stable, observable error surface (typed `AsyncError` carrying a
/// [ChatMessagesFailure]).
///
/// Send/cancel stay on [ChatMessagesNotifier] because they own streaming
/// state. Delete and load-more live here so widgets can `ref.listen` for
/// failures without being entangled with the streaming `AsyncValue`.
///
/// Single global slot (no family): only one session is active at a time, and
/// we want one snackbar per failed operation regardless of how many bubbles
/// are on screen.
final class ChatMessagesActionsProvider extends $AsyncNotifierProvider<ChatMessagesActions, void> {
  /// Command notifier for message-list mutations that can fail and need a
  /// stable, observable error surface (typed `AsyncError` carrying a
  /// [ChatMessagesFailure]).
  ///
  /// Send/cancel stay on [ChatMessagesNotifier] because they own streaming
  /// state. Delete and load-more live here so widgets can `ref.listen` for
  /// failures without being entangled with the streaming `AsyncValue`.
  ///
  /// Single global slot (no family): only one session is active at a time, and
  /// we want one snackbar per failed operation regardless of how many bubbles
  /// are on screen.
  ChatMessagesActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatMessagesActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesActionsHash();

  @$internal
  @override
  ChatMessagesActions create() => ChatMessagesActions();
}

String _$chatMessagesActionsHash() => r'2afc9499f01f947b34dd450104066fc339b5015c';

/// Command notifier for message-list mutations that can fail and need a
/// stable, observable error surface (typed `AsyncError` carrying a
/// [ChatMessagesFailure]).
///
/// Send/cancel stay on [ChatMessagesNotifier] because they own streaming
/// state. Delete and load-more live here so widgets can `ref.listen` for
/// failures without being entangled with the streaming `AsyncValue`.
///
/// Single global slot (no family): only one session is active at a time, and
/// we want one snackbar per failed operation regardless of how many bubbles
/// are on screen.

abstract class _$ChatMessagesActions extends $AsyncNotifier<void> {
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
