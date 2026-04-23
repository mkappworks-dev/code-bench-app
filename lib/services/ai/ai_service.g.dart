// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiService)
final aiServiceProvider = AiServiceProvider._();

final class AiServiceProvider extends $FunctionalProvider<AsyncValue<AIService>, AIService, FutureOr<AIService>>
    with $FutureModifier<AIService>, $FutureProvider<AIService> {
  AiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiServiceHash();

  @$internal
  @override
  $FutureProviderElement<AIService> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<AIService> create(Ref ref) {
    return aiService(ref);
  }
}

String _$aiServiceHash() => r'4210d63d0225c8822da7b6f6ea270a645c72c2d3';
