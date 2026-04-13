// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_service_factory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiService)
final aiServiceProvider = AiServiceFamily._();

final class AiServiceProvider extends $FunctionalProvider<AsyncValue<AIService?>, AIService?, FutureOr<AIService?>>
    with $FutureModifier<AIService?>, $FutureProvider<AIService?> {
  AiServiceProvider._({required AiServiceFamily super.from, required AIProvider super.argument})
    : super(
        retry: null,
        name: r'aiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiServiceHash();

  @override
  String toString() {
    return r'aiServiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AIService?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<AIService?> create(Ref ref) {
    final argument = this.argument as AIProvider;
    return aiService(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AiServiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$aiServiceHash() => r'ef78dc675d6c14fb6ffa6f6f916770c22daa2a29';

final class AiServiceFamily extends $Family with $FunctionalFamilyOverride<FutureOr<AIService?>, AIProvider> {
  AiServiceFamily._()
    : super(
        retry: null,
        name: r'aiServiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AiServiceProvider call(AIProvider aiProvider) => AiServiceProvider._(argument: aiProvider, from: this);

  @override
  String toString() => r'aiServiceProvider';
}

@ProviderFor(availableModels)
final availableModelsProvider = AvailableModelsProvider._();

final class AvailableModelsProvider
    extends $FunctionalProvider<AsyncValue<List<AIModel>>, List<AIModel>, FutureOr<List<AIModel>>>
    with $FutureModifier<List<AIModel>>, $FutureProvider<List<AIModel>> {
  AvailableModelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableModelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableModelsHash();

  @$internal
  @override
  $FutureProviderElement<List<AIModel>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AIModel>> create(Ref ref) {
    return availableModels(ref);
  }
}

String _$availableModelsHash() => r'f7b11f9512951c80296322d74309ba81f76db281';
