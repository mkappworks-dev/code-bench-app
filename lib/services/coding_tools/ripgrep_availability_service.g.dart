// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ripgrep_availability_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns true if ripgrep (`rg`) is installed. Cached for the session.
/// The user can force a re-check via [RipgrepAvailabilityStateNotifier.recheck].

@ProviderFor(ripgrepAvailability)
final ripgrepAvailabilityProvider = RipgrepAvailabilityProvider._();

/// Returns true if ripgrep (`rg`) is installed. Cached for the session.
/// The user can force a re-check via [RipgrepAvailabilityStateNotifier.recheck].

final class RipgrepAvailabilityProvider extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Returns true if ripgrep (`rg`) is installed. Cached for the session.
  /// The user can force a re-check via [RipgrepAvailabilityStateNotifier.recheck].
  RipgrepAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ripgrepAvailabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ripgrepAvailabilityHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return ripgrepAvailability(ref);
  }
}

String _$ripgrepAvailabilityHash() => r'ea6bd8a45fe4875bedad6bfc9b5d76d948a2b094';
