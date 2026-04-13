// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitService)
final gitServiceProvider = GitServiceFamily._();

final class GitServiceProvider extends $FunctionalProvider<GitService, GitService, GitService>
    with $Provider<GitService> {
  GitServiceProvider._({required GitServiceFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'gitServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitServiceHash();

  @override
  String toString() {
    return r'gitServiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<GitService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  GitService create(Ref ref) {
    final argument = this.argument as String;
    return gitService(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<GitService>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is GitServiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitServiceHash() => r'175505c9ccc1145d8c9ad06e71b2da4459b75c7d';

final class GitServiceFamily extends $Family with $FunctionalFamilyOverride<GitService, String> {
  GitServiceFamily._()
    : super(
        retry: null,
        name: r'gitServiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GitServiceProvider call(String projectPath) => GitServiceProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'gitServiceProvider';
}
