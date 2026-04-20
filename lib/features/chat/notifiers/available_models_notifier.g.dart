// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_models_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AvailableModelsNotifier)
final availableModelsProvider = AvailableModelsNotifierProvider._();

final class AvailableModelsNotifierProvider extends $AsyncNotifierProvider<AvailableModelsNotifier, List<AIModel>> {
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

String _$availableModelsNotifierHash() => r'31a384029d4dbf1bc0523ea8b53c66c414a7ed56';

abstract class _$AvailableModelsNotifier extends $AsyncNotifier<List<AIModel>> {
  FutureOr<List<AIModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<AIModel>>, List<AIModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AIModel>>, List<AIModel>>,
              AsyncValue<List<AIModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
