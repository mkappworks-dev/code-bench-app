// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProvidersActions)
final providersActionsProvider = ProvidersActionsProvider._();

final class ProvidersActionsProvider extends $AsyncNotifierProvider<ProvidersActions, void> {
  ProvidersActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providersActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providersActionsHash();

  @$internal
  @override
  ProvidersActions create() => ProvidersActions();
}

String _$providersActionsHash() => r'b3be82b8cd7dc4b837eb8f47acc8f85a83d97eb7';

abstract class _$ProvidersActions extends $AsyncNotifier<void> {
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
