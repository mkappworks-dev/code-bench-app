// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitRepository)
final gitRepositoryProvider = GitRepositoryProvider._();

final class GitRepositoryProvider extends $FunctionalProvider<GitRepository, GitRepository, GitRepository>
    with $Provider<GitRepository> {
  GitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitRepositoryHash();

  @$internal
  @override
  $ProviderElement<GitRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  GitRepository create(Ref ref) {
    return gitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<GitRepository>(value));
  }
}

String _$gitRepositoryHash() => r'e9a7ca5d991b8b21336f4048fb5bd00aa65b7a4c';

/// Convenience provider: replaces gitLiveStateProvider(path) family.

@ProviderFor(gitLiveState)
final gitLiveStateProvider = GitLiveStateFamily._();

/// Convenience provider: replaces gitLiveStateProvider(path) family.

final class GitLiveStateProvider
    extends $FunctionalProvider<AsyncValue<GitLiveState>, GitLiveState, FutureOr<GitLiveState>>
    with $FutureModifier<GitLiveState>, $FutureProvider<GitLiveState> {
  /// Convenience provider: replaces gitLiveStateProvider(path) family.
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

String _$gitLiveStateHash() => r'07b69b044db8083820ee5412336ea229fef434d5';

/// Convenience provider: replaces gitLiveStateProvider(path) family.

final class GitLiveStateFamily extends $Family with $FunctionalFamilyOverride<FutureOr<GitLiveState>, String> {
  GitLiveStateFamily._()
    : super(
        retry: null,
        name: r'gitLiveStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Convenience provider: replaces gitLiveStateProvider(path) family.

  GitLiveStateProvider call(String projectPath) => GitLiveStateProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'gitLiveStateProvider';
}

/// Replaces behindCountProvider(path) family — includes the 5-minute
/// self-invalidating timer.

@ProviderFor(behindCount)
final behindCountProvider = BehindCountFamily._();

/// Replaces behindCountProvider(path) family — includes the 5-minute
/// self-invalidating timer.

final class BehindCountProvider extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// Replaces behindCountProvider(path) family — includes the 5-minute
  /// self-invalidating timer.
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

String _$behindCountHash() => r'b18443c558901c095a1269c0eb021c485c8dee1c';

/// Replaces behindCountProvider(path) family — includes the 5-minute
/// self-invalidating timer.

final class BehindCountFamily extends $Family with $FunctionalFamilyOverride<FutureOr<int?>, String> {
  BehindCountFamily._()
    : super(
        retry: null,
        name: r'behindCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Replaces behindCountProvider(path) family — includes the 5-minute
  /// self-invalidating timer.

  BehindCountProvider call(String projectPath) => BehindCountProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'behindCountProvider';
}
