// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiProviderRepository)
final aiProviderRepositoryProvider = AiProviderRepositoryProvider._();

final class AiProviderRepositoryProvider
    extends $FunctionalProvider<AIProviderRepository, AIProviderRepository, AIProviderRepository>
    with $Provider<AIProviderRepository> {
  AiProviderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiProviderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiProviderRepositoryHash();

  @$internal
  @override
  $ProviderElement<AIProviderRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AIProviderRepository create(Ref ref) {
    return aiProviderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AIProviderRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AIProviderRepository>(value));
  }
}

String _$aiProviderRepositoryHash() => r'd889c651720d3afd529916a323d6b6691e66c7b3';
