// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_live_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live git state for [projectPath]. Covers cheap, local-only operations.
/// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
/// every in-app git mutation (commit, push, pull, checkout, init-git).

@ProviderFor(gitLiveState)
final gitLiveStateProvider = GitLiveStateFamily._();

/// Live git state for [projectPath]. Covers cheap, local-only operations.
/// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
/// every in-app git mutation (commit, push, pull, checkout, init-git).

final class GitLiveStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<GitLiveState>,
          GitLiveState,
          FutureOr<GitLiveState>
        >
    with $FutureModifier<GitLiveState>, $FutureProvider<GitLiveState> {
  /// Live git state for [projectPath]. Covers cheap, local-only operations.
  /// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
  /// every in-app git mutation (commit, push, pull, checkout, init-git).
  GitLiveStateProvider._({
    required GitLiveStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gitLiveStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitLiveStateHash();

  @override
  String toString() {
    return r'gitLiveStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GitLiveState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GitLiveState> create(Ref ref) {
    final argument = this.argument as String;
    return gitLiveState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GitLiveStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitLiveStateHash() => r'4c14b4dba17cf708cf0a9935289cb459b413b662';

/// Live git state for [projectPath]. Covers cheap, local-only operations.
/// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
/// every in-app git mutation (commit, push, pull, checkout, init-git).

final class GitLiveStateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GitLiveState>, String> {
  GitLiveStateFamily._()
    : super(
        retry: null,
        name: r'gitLiveStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live git state for [projectPath]. Covers cheap, local-only operations.
  /// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
  /// every in-app git mutation (commit, push, pull, checkout, init-git).

  GitLiveStateProvider call(String projectPath) =>
      GitLiveStateProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'gitLiveStateProvider';
}

/// Behind count for [projectPath]. Runs `git fetch` — network call.
/// Refreshes on a 5-minute timer and after post-push/pull mutations.

@ProviderFor(behindCount)
final behindCountProvider = BehindCountFamily._();

/// Behind count for [projectPath]. Runs `git fetch` — network call.
/// Refreshes on a 5-minute timer and after post-push/pull mutations.

final class BehindCountProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// Behind count for [projectPath]. Runs `git fetch` — network call.
  /// Refreshes on a 5-minute timer and after post-push/pull mutations.
  BehindCountProvider._({
    required BehindCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'behindCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$behindCountHash();

  @override
  String toString() {
    return r'behindCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as String;
    return behindCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BehindCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$behindCountHash() => r'b10b49920b2b18a3a86544d52b9f803831926d41';

/// Behind count for [projectPath]. Runs `git fetch` — network call.
/// Refreshes on a 5-minute timer and after post-push/pull mutations.

final class BehindCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, String> {
  BehindCountFamily._()
    : super(
        retry: null,
        name: r'behindCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Behind count for [projectPath]. Runs `git fetch` — network call.
  /// Refreshes on a 5-minute timer and after post-push/pull mutations.

  BehindCountProvider call(String projectPath) =>
      BehindCountProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'behindCountProvider';
}
