// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_messages_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier for delete / retry / load-more — the message-list mutations that need an observable error surface independent of the streaming `AsyncValue` on [ChatMessagesNotifier]. Single global slot so a duplicated snackbar across many bubble instances can't fire.

@ProviderFor(ChatMessagesActions)
final chatMessagesActionsProvider = ChatMessagesActionsProvider._();

/// Command notifier for delete / retry / load-more — the message-list mutations that need an observable error surface independent of the streaming `AsyncValue` on [ChatMessagesNotifier]. Single global slot so a duplicated snackbar across many bubble instances can't fire.
final class ChatMessagesActionsProvider extends $AsyncNotifierProvider<ChatMessagesActions, void> {
  /// Command notifier for delete / retry / load-more — the message-list mutations that need an observable error surface independent of the streaming `AsyncValue` on [ChatMessagesNotifier]. Single global slot so a duplicated snackbar across many bubble instances can't fire.
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

String _$chatMessagesActionsHash() => r'238bbb89565ae4f805c1cc3b0331279495c333eb';

/// Command notifier for delete / retry / load-more — the message-list mutations that need an observable error surface independent of the streaming `AsyncValue` on [ChatMessagesNotifier]. Single global slot so a duplicated snackbar across many bubble instances can't fire.

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
