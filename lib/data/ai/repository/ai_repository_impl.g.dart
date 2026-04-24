// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assembles [AIRepositoryImpl] with the per-transport datasource map.
///
/// The CLI detection handoff is inverted via [claudeCliDetectorProvider]
/// so this file never imports from `lib/services/` — the production
/// implementation is overridden at the app root (see `lib/main.dart`).

@ProviderFor(aiRepository)
final aiRepositoryProvider = AiRepositoryProvider._();

/// Assembles [AIRepositoryImpl] with the per-transport datasource map.
///
/// The CLI detection handoff is inverted via [claudeCliDetectorProvider]
/// so this file never imports from `lib/services/` — the production
/// implementation is overridden at the app root (see `lib/main.dart`).

final class AiRepositoryProvider
    extends $FunctionalProvider<AsyncValue<AIRepositoryImpl>, AIRepositoryImpl, FutureOr<AIRepositoryImpl>>
    with $FutureModifier<AIRepositoryImpl>, $FutureProvider<AIRepositoryImpl> {
  /// Assembles [AIRepositoryImpl] with the per-transport datasource map.
  ///
  /// The CLI detection handoff is inverted via [claudeCliDetectorProvider]
  /// so this file never imports from `lib/services/` — the production
  /// implementation is overridden at the app root (see `lib/main.dart`).
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

String _$aiRepositoryHash() => r'412c83d7472f121af96904b669d649ace7930f1f';
