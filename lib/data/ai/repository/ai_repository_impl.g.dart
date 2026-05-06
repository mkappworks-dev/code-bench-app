// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CLI transports are not registered here — dispatched at the SessionService layer.

@ProviderFor(aiRepository)
final aiRepositoryProvider = AiRepositoryProvider._();

/// CLI transports are not registered here — dispatched at the SessionService layer.

final class AiRepositoryProvider
    extends $FunctionalProvider<AsyncValue<AIRepositoryImpl>, AIRepositoryImpl, FutureOr<AIRepositoryImpl>>
    with $FutureModifier<AIRepositoryImpl>, $FutureProvider<AIRepositoryImpl> {
  /// CLI transports are not registered here — dispatched at the SessionService layer.
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
  $FutureProviderElement<AIRepositoryImpl> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<AIRepositoryImpl> create(Ref ref) {
    return aiRepository(ref);
  }
}

String _$aiRepositoryHash() => r'b48e2381278f1b6684585e93822f8f7fc608fb56';
