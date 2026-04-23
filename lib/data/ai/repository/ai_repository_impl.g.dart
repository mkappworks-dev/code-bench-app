// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns the concrete [AIRepositoryImpl] (typed as the class, not as
/// `AIRepository`) so downstream service providers can pass the same
/// instance into multiple narrow-interface fields — e.g. one service
/// takes [AIRepository] for testConnection/fetchAvailableModels AND
/// [TextStreamingRepository] for streamMessage, both satisfied by the
/// same object.

@ProviderFor(aiRepository)
final aiRepositoryProvider = AiRepositoryProvider._();

/// Returns the concrete [AIRepositoryImpl] (typed as the class, not as
/// `AIRepository`) so downstream service providers can pass the same
/// instance into multiple narrow-interface fields — e.g. one service
/// takes [AIRepository] for testConnection/fetchAvailableModels AND
/// [TextStreamingRepository] for streamMessage, both satisfied by the
/// same object.

final class AiRepositoryProvider
    extends $FunctionalProvider<AsyncValue<AIRepositoryImpl>, AIRepositoryImpl, FutureOr<AIRepositoryImpl>>
    with $FutureModifier<AIRepositoryImpl>, $FutureProvider<AIRepositoryImpl> {
  /// Returns the concrete [AIRepositoryImpl] (typed as the class, not as
  /// `AIRepository`) so downstream service providers can pass the same
  /// instance into multiple narrow-interface fields — e.g. one service
  /// takes [AIRepository] for testConnection/fetchAvailableModels AND
  /// [TextStreamingRepository] for streamMessage, both satisfied by the
  /// same object.
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

String _$aiRepositoryHash() => r'fe81ae4d5ee92cddda71c501b772624f4294e1e1';
