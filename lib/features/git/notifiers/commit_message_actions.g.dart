// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit_message_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AI commit-message generator. Always returns a usable string — falls back to
/// `'chore: update files'` so the commit flow is never blocked by a network error.

@ProviderFor(CommitMessageActions)
final commitMessageActionsProvider = CommitMessageActionsProvider._();

/// AI commit-message generator. Always returns a usable string — falls back to
/// `'chore: update files'` so the commit flow is never blocked by a network error.
final class CommitMessageActionsProvider extends $AsyncNotifierProvider<CommitMessageActions, void> {
  /// AI commit-message generator. Always returns a usable string — falls back to
  /// `'chore: update files'` so the commit flow is never blocked by a network error.
  CommitMessageActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commitMessageActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commitMessageActionsHash();

  @$internal
  @override
  CommitMessageActions create() => CommitMessageActions();
}

String _$commitMessageActionsHash() => r'24e5c931afc14cac9d8753dbb30674acc28e0440';

/// AI commit-message generator. Always returns a usable string — falls back to
/// `'chore: update files'` so the commit flow is never blocked by a network error.

abstract class _$CommitMessageActions extends $AsyncNotifier<void> {
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
