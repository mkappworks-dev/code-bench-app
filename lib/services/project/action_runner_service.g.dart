// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_runner_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(actionRunnerService)
final actionRunnerServiceProvider = ActionRunnerServiceProvider._();

final class ActionRunnerServiceProvider
    extends
        $FunctionalProvider<
          ActionRunnerService,
          ActionRunnerService,
          ActionRunnerService
        >
    with $Provider<ActionRunnerService> {
  ActionRunnerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'actionRunnerServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$actionRunnerServiceHash();

  @$internal
  @override
  $ProviderElement<ActionRunnerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActionRunnerService create(Ref ref) {
    return actionRunnerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActionRunnerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActionRunnerService>(value),
    );
  }
}

String _$actionRunnerServiceHash() =>
    r'9c75da84fb7f4e5306b60cacdae2e3c3f7b191b4';
