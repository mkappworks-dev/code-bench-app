// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_pr_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SECURITY: Only log `e.runtimeType` — `$e` can invoke DioException.toString()
/// which serialises the Authorization header and leaks the PAT.

@ProviderFor(CreatePrActions)
final createPrActionsProvider = CreatePrActionsProvider._();

/// SECURITY: Only log `e.runtimeType` — `$e` can invoke DioException.toString()
/// which serialises the Authorization header and leaks the PAT.
final class CreatePrActionsProvider extends $AsyncNotifierProvider<CreatePrActions, void> {
  /// SECURITY: Only log `e.runtimeType` — `$e` can invoke DioException.toString()
  /// which serialises the Authorization header and leaks the PAT.
  CreatePrActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createPrActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createPrActionsHash();

  @$internal
  @override
  CreatePrActions create() => CreatePrActions();
}

String _$createPrActionsHash() => r'bde6ebe808b0522d59d5301e98d955768bcd5967';

/// SECURITY: Only log `e.runtimeType` — `$e` can invoke DioException.toString()
/// which serialises the Authorization header and leaks the PAT.

abstract class _$CreatePrActions extends $AsyncNotifier<void> {
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
