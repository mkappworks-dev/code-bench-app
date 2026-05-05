// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit_message_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Generates an AI-assisted commit message. Always returns a usable value —
/// the `'chore: update files'` fallback — even when the AI call is
/// unavailable, so the commit flow is never blocked by a network error.
///
/// On [NetworkException], the notifier emits [AsyncError] carrying a
/// [CommitMessageFailure] so widgets can surface an inline "AI unavailable"
/// notice via [ref.listen] without needing a try/catch in widget code.

@ProviderFor(CommitMessageActions)
final commitMessageActionsProvider = CommitMessageActionsProvider._();

/// Generates an AI-assisted commit message. Always returns a usable value —
/// the `'chore: update files'` fallback — even when the AI call is
/// unavailable, so the commit flow is never blocked by a network error.
///
/// On [NetworkException], the notifier emits [AsyncError] carrying a
/// [CommitMessageFailure] so widgets can surface an inline "AI unavailable"
/// notice via [ref.listen] without needing a try/catch in widget code.
final class CommitMessageActionsProvider extends $AsyncNotifierProvider<CommitMessageActions, void> {
  /// Generates an AI-assisted commit message. Always returns a usable value —
  /// the `'chore: update files'` fallback — even when the AI call is
  /// unavailable, so the commit flow is never blocked by a network error.
  ///
  /// On [NetworkException], the notifier emits [AsyncError] carrying a
  /// [CommitMessageFailure] so widgets can surface an inline "AI unavailable"
  /// notice via [ref.listen] without needing a try/catch in widget code.
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

String _$commitMessageActionsHash() => r'93db16fa6ec25405b6ddd23784c5912fd4b3cdce';

/// Generates an AI-assisted commit message. Always returns a usable value —
/// the `'chore: update files'` fallback — even when the AI call is
/// unavailable, so the commit flow is never blocked by a network error.
///
/// On [NetworkException], the notifier emits [AsyncError] carrying a
/// [CommitMessageFailure] so widgets can surface an inline "AI unavailable"
/// notice via [ref.listen] without needing a try/catch in widget code.

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
