// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claude_cli_detector.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default probe used when no override is registered — reports "not
/// installed" so tests and headless tools don't need the full service
/// graph just to construct `AIRepositoryImpl`.

@ProviderFor(claudeCliDetector)
final claudeCliDetectorProvider = ClaudeCliDetectorProvider._();

/// Default probe used when no override is registered — reports "not
/// installed" so tests and headless tools don't need the full service
/// graph just to construct `AIRepositoryImpl`.

final class ClaudeCliDetectorProvider
    extends $FunctionalProvider<ClaudeCliDetector, ClaudeCliDetector, ClaudeCliDetector>
    with $Provider<ClaudeCliDetector> {
  /// Default probe used when no override is registered — reports "not
  /// installed" so tests and headless tools don't need the full service
  /// graph just to construct `AIRepositoryImpl`.
  ClaudeCliDetectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claudeCliDetectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claudeCliDetectorHash();

  @$internal
  @override
  $ProviderElement<ClaudeCliDetector> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ClaudeCliDetector create(Ref ref) {
    return claudeCliDetector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClaudeCliDetector value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ClaudeCliDetector>(value));
  }
}

String _$claudeCliDetectorHash() => r'd8b33cb19dd1f0c805837c55fe4f2ca57bb4d4af';
