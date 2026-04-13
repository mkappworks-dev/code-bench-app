// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier for all git operations.
///
/// Widgets never reach [GitRepository] directly — they call methods here.
/// State is [AsyncValue<void>]: loading/error/data are driven by each method.
/// Typed failures are emitted as [AsyncError] carrying a [GitActionsFailure].

@ProviderFor(GitActions)
final gitActionsProvider = GitActionsProvider._();

/// Command notifier for all git operations.
///
/// Widgets never reach [GitRepository] directly — they call methods here.
/// State is [AsyncValue<void>]: loading/error/data are driven by each method.
/// Typed failures are emitted as [AsyncError] carrying a [GitActionsFailure].
final class GitActionsProvider extends $AsyncNotifierProvider<GitActions, void> {
  /// Command notifier for all git operations.
  ///
  /// Widgets never reach [GitRepository] directly — they call methods here.
  /// State is [AsyncValue<void>]: loading/error/data are driven by each method.
  /// Typed failures are emitted as [AsyncError] carrying a [GitActionsFailure].
  GitActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitActionsHash();

  @$internal
  @override
  GitActions create() => GitActions();
}

String _$gitActionsHash() => r'3c8f7bfd39dbad79c25c00e6d7cce9fb9b6a3dfa';

/// Command notifier for all git operations.
///
/// Widgets never reach [GitRepository] directly — they call methods here.
/// State is [AsyncValue<void>]: loading/error/data are driven by each method.
/// Typed failures are emitted as [AsyncError] carrying a [GitActionsFailure].

abstract class _$GitActions extends $AsyncNotifier<void> {
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
