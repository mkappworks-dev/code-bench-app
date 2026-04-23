// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiRepository)
final aiRepositoryProvider = AiRepositoryProvider._();

final class AiRepositoryProvider
    extends $FunctionalProvider<AsyncValue<AIRepository>, AIRepository, FutureOr<AIRepository>>
    with $FutureModifier<AIRepository>, $FutureProvider<AIRepository> {
  AiRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<AIRepository> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<AIRepository> create(Ref ref) {
    return aiRepository(ref);
  }
}

String _$aiRepositoryHash() => r'35af23d624b5e12a2ab8938a9f764f32c1f7ba11';
