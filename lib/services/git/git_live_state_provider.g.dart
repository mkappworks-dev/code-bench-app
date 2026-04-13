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
///
/// Probe failures are surfaced as `null` fields in [GitLiveState] — **not**
/// as falsy defaults — so the UI never silently dims a button when git
/// actually crashed. Every `null` is also logged via `sLog` so the cause is
/// attributable from the platform log.

@ProviderFor(gitLiveState)
final gitLiveStateProvider = GitLiveStateFamily._();

/// Live git state for [projectPath]. Covers cheap, local-only operations.
/// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
/// every in-app git mutation (commit, push, pull, checkout, init-git).
///
/// Probe failures are surfaced as `null` fields in [GitLiveState] — **not**
/// as falsy defaults — so the UI never silently dims a button when git
/// actually crashed. Every `null` is also logged via `sLog` so the cause is
/// attributable from the platform log.

final class GitLiveStateProvider
    extends $FunctionalProvider<AsyncValue<GitLiveState>, GitLiveState, FutureOr<GitLiveState>>
    with $FutureModifier<GitLiveState>, $FutureProvider<GitLiveState> {
  /// Live git state for [projectPath]. Covers cheap, local-only operations.
  /// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
  /// every in-app git mutation (commit, push, pull, checkout, init-git).
  ///
  /// Probe failures are surfaced as `null` fields in [GitLiveState] — **not**
  /// as falsy defaults — so the UI never silently dims a button when git
  /// actually crashed. Every `null` is also logged via `sLog` so the cause is
  /// attributable from the platform log.
  GitLiveStateProvider._({required GitLiveStateFamily super.from, required String super.argument})
    : super(
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
  $FutureProviderElement<GitLiveState> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

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

String _$gitLiveStateHash() => r'203ced2c9ed852eb652396c29485a1a50cd81613';

/// Live git state for [projectPath]. Covers cheap, local-only operations.
/// Refresh triggers: window focus (via [AppLifecycleObserver]) and after
/// every in-app git mutation (commit, push, pull, checkout, init-git).
///
/// Probe failures are surfaced as `null` fields in [GitLiveState] — **not**
/// as falsy defaults — so the UI never silently dims a button when git
/// actually crashed. Every `null` is also logged via `sLog` so the cause is
/// attributable from the platform log.

final class GitLiveStateFamily extends $Family with $FunctionalFamilyOverride<FutureOr<GitLiveState>, String> {
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
  ///
  /// Probe failures are surfaced as `null` fields in [GitLiveState] — **not**
  /// as falsy defaults — so the UI never silently dims a button when git
  /// actually crashed. Every `null` is also logged via `sLog` so the cause is
  /// attributable from the platform log.

  GitLiveStateProvider call(String projectPath) => GitLiveStateProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'gitLiveStateProvider';
}

/// Behind count for [projectPath]. Runs `git fetch` — network call.
/// Refreshes on a 5-minute timer and after post-push/pull mutations.
///
/// The `isGitRepo` gate sits **above** the timer setup so non-git projects
/// don't pay for a perpetual self-invalidating timer.

@ProviderFor(behindCount)
final behindCountProvider = BehindCountFamily._();

/// Behind count for [projectPath]. Runs `git fetch` — network call.
/// Refreshes on a 5-minute timer and after post-push/pull mutations.
///
/// The `isGitRepo` gate sits **above** the timer setup so non-git projects
/// don't pay for a perpetual self-invalidating timer.

final class BehindCountProvider extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// Behind count for [projectPath]. Runs `git fetch` — network call.
  /// Refreshes on a 5-minute timer and after post-push/pull mutations.
  ///
  /// The `isGitRepo` gate sits **above** the timer setup so non-git projects
  /// don't pay for a perpetual self-invalidating timer.
  BehindCountProvider._({required BehindCountFamily super.from, required String super.argument})
    : super(
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
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

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

String _$behindCountHash() => r'9d298d457c9c3d7d3e15c83c78f73a140e0957aa';

/// Behind count for [projectPath]. Runs `git fetch` — network call.
/// Refreshes on a 5-minute timer and after post-push/pull mutations.
///
/// The `isGitRepo` gate sits **above** the timer setup so non-git projects
/// don't pay for a perpetual self-invalidating timer.

final class BehindCountFamily extends $Family with $FunctionalFamilyOverride<FutureOr<int?>, String> {
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
  ///
  /// The `isGitRepo` gate sits **above** the timer setup so non-git projects
  /// don't pay for a perpetual self-invalidating timer.

  BehindCountProvider call(String projectPath) => BehindCountProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'behindCountProvider';
}
