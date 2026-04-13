// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_remotes_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads the configured git remotes for [path] once on mount and tracks
/// which remote the user has selected for the next Push.
///
/// Family: one provider instance per project path — disposes when the
/// widget tree stops watching it.

@ProviderFor(GitRemotesNotifier)
final gitRemotesProvider = GitRemotesNotifierFamily._();

/// Loads the configured git remotes for [path] once on mount and tracks
/// which remote the user has selected for the next Push.
///
/// Family: one provider instance per project path — disposes when the
/// widget tree stops watching it.
final class GitRemotesNotifierProvider extends $AsyncNotifierProvider<GitRemotesNotifier, GitRemotesState> {
  /// Loads the configured git remotes for [path] once on mount and tracks
  /// which remote the user has selected for the next Push.
  ///
  /// Family: one provider instance per project path — disposes when the
  /// widget tree stops watching it.
  GitRemotesNotifierProvider._({required GitRemotesNotifierFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'gitRemotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitRemotesNotifierHash();

  @override
  String toString() {
    return r'gitRemotesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GitRemotesNotifier create() => GitRemotesNotifier();

  @override
  bool operator ==(Object other) {
    return other is GitRemotesNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitRemotesNotifierHash() => r'53d54d84d335998fbf1b44accbf01099af8ad2d8';

/// Loads the configured git remotes for [path] once on mount and tracks
/// which remote the user has selected for the next Push.
///
/// Family: one provider instance per project path — disposes when the
/// widget tree stops watching it.

final class GitRemotesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitRemotesNotifier,
          AsyncValue<GitRemotesState>,
          GitRemotesState,
          FutureOr<GitRemotesState>,
          String
        > {
  GitRemotesNotifierFamily._()
    : super(
        retry: null,
        name: r'gitRemotesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads the configured git remotes for [path] once on mount and tracks
  /// which remote the user has selected for the next Push.
  ///
  /// Family: one provider instance per project path — disposes when the
  /// widget tree stops watching it.

  GitRemotesNotifierProvider call(String path) => GitRemotesNotifierProvider._(argument: path, from: this);

  @override
  String toString() => r'gitRemotesProvider';
}

/// Loads the configured git remotes for [path] once on mount and tracks
/// which remote the user has selected for the next Push.
///
/// Family: one provider instance per project path — disposes when the
/// widget tree stops watching it.

abstract class _$GitRemotesNotifier extends $AsyncNotifier<GitRemotesState> {
  late final _$args = ref.$arg as String;
  String get path => _$args;

  FutureOr<GitRemotesState> build(String path);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GitRemotesState>, GitRemotesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GitRemotesState>, GitRemotesState>,
              AsyncValue<GitRemotesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
