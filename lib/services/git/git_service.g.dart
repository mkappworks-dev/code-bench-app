// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitService)
final gitServiceProvider = GitServiceProvider._();

final class GitServiceProvider extends $FunctionalProvider<GitService, GitService, GitService>
    with $Provider<GitService> {
  GitServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitServiceHash();

  @$internal
  @override
  $ProviderElement<GitService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  GitService create(Ref ref) {
    return gitService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<GitService>(value));
  }
}

String _$gitServiceHash() => r'aba331d58cff6fd6266a9b957b6ea9ee75b59e09';

/// Convenience providers consumed by notifiers and widgets.

@ProviderFor(gitLiveState)
final gitLiveStateProvider = GitLiveStateFamily._();

/// Convenience providers consumed by notifiers and widgets.

final class GitLiveStateProvider
    extends $FunctionalProvider<AsyncValue<GitLiveState>, GitLiveState, FutureOr<GitLiveState>>
    with $FutureModifier<GitLiveState>, $FutureProvider<GitLiveState> {
  /// Convenience providers consumed by notifiers and widgets.
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

String _$gitLiveStateHash() => r'087c4b7a0982e50e1094880f4b67008fccf3a494';

/// Convenience providers consumed by notifiers and widgets.

final class GitLiveStateFamily extends $Family with $FunctionalFamilyOverride<FutureOr<GitLiveState>, String> {
  GitLiveStateFamily._()
    : super(
        retry: null,
        name: r'gitLiveStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Convenience providers consumed by notifiers and widgets.

  GitLiveStateProvider call(String projectPath) => GitLiveStateProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'gitLiveStateProvider';
}

@ProviderFor(behindCount)
final behindCountProvider = BehindCountFamily._();

final class BehindCountProvider extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
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

String _$behindCountHash() => r'1a24ebad677e9050428147262acac10732ea2088';

final class BehindCountFamily extends $Family with $FunctionalFamilyOverride<FutureOr<int?>, String> {
  BehindCountFamily._()
    : super(
        retry: null,
        name: r'behindCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BehindCountProvider call(String projectPath) => BehindCountProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'behindCountProvider';
}
