// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitService)
final gitServiceProvider = GitServiceProvider._();

final class GitServiceProvider
    extends $FunctionalProvider<GitService, GitService, GitService>
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
  $ProviderElement<GitService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GitService create(Ref ref) {
    return gitService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitService>(value),
    );
  }
}

String _$gitServiceHash() => r'aba331d58cff6fd6266a9b957b6ea9ee75b59e09';
