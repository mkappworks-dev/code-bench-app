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
