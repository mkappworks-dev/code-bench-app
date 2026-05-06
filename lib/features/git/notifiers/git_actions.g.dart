// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GitActions)
final gitActionsProvider = GitActionsProvider._();

final class GitActionsProvider extends $AsyncNotifierProvider<GitActions, void> {
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

String _$gitActionsHash() => r'15d7a91bc128b5316f347833a8bfdb024250ca9f';

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
