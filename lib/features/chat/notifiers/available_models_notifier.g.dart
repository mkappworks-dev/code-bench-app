// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_models_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AvailableModelsNotifier)
final availableModelsProvider = AvailableModelsNotifierProvider._();

final class AvailableModelsNotifierProvider
    extends $AsyncNotifierProvider<AvailableModelsNotifier, AvailableModelsResult> {
  AvailableModelsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableModelsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableModelsNotifierHash();

  @$internal
  @override
  AvailableModelsNotifier create() => AvailableModelsNotifier();
}

String _$availableModelsNotifierHash() => r'd39ae718e153b97a1ce2415d5cccd2233ec3da14';

abstract class _$AvailableModelsNotifier extends $AsyncNotifier<AvailableModelsResult> {
  FutureOr<AvailableModelsResult> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AvailableModelsResult>, AvailableModelsResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AvailableModelsResult>, AvailableModelsResult>,
              AsyncValue<AvailableModelsResult>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
