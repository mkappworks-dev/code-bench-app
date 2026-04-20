// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit_message_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Generates AI-assisted text for git workflows: commit messages and PR
/// title / body. Both methods always return a usable value — the fallback
/// string — even when the AI call fails, so the commit / PR flow is never
/// blocked by a network error.
///
/// On [NetworkException], the notifier emits [AsyncError] carrying a
/// [CommitMessageFailure] so widgets can surface an inline "AI unavailable"
/// notice via [ref.listen] without needing a try/catch in widget code.

@ProviderFor(CommitMessageActions)
final commitMessageActionsProvider = CommitMessageActionsProvider._();

/// Generates AI-assisted text for git workflows: commit messages and PR
/// title / body. Both methods always return a usable value — the fallback
/// string — even when the AI call fails, so the commit / PR flow is never
/// blocked by a network error.
///
/// On [NetworkException], the notifier emits [AsyncError] carrying a
/// [CommitMessageFailure] so widgets can surface an inline "AI unavailable"
/// notice via [ref.listen] without needing a try/catch in widget code.
final class CommitMessageActionsProvider
    extends $AsyncNotifierProvider<CommitMessageActions, void> {
  /// Generates AI-assisted text for git workflows: commit messages and PR
  /// title / body. Both methods always return a usable value — the fallback
  /// string — even when the AI call fails, so the commit / PR flow is never
  /// blocked by a network error.
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

String _$commitMessageActionsHash() =>
    r'c2bd299e8cb9ffe50b5eab7f8510f2cf10991507';

/// Generates AI-assisted text for git workflows: commit messages and PR
/// title / body. Both methods always return a usable value — the fallback
/// string — even when the AI call fails, so the commit / PR flow is never
/// blocked by a network error.
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
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
