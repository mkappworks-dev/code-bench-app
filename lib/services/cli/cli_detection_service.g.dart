// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cli_detection_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Detects local CLI binaries and caches results per-binary with a TTL.

@ProviderFor(CliDetectionService)
final cliDetectionServiceProvider = CliDetectionServiceProvider._();

/// Detects local CLI binaries and caches results per-binary with a TTL.
final class CliDetectionServiceProvider extends $NotifierProvider<CliDetectionService, Map<String, CliDetection>> {
  /// Detects local CLI binaries and caches results per-binary with a TTL.
  CliDetectionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cliDetectionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cliDetectionServiceHash();

  @$internal
  @override
  CliDetectionService create() => CliDetectionService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, CliDetection> value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Map<String, CliDetection>>(value));
  }
}

String _$cliDetectionServiceHash() => r'2598d64841584ea5951151c1d1731a497b8a3776';

/// Detects local CLI binaries and caches results per-binary with a TTL.

abstract class _$CliDetectionService extends $Notifier<Map<String, CliDetection>> {
  Map<String, CliDetection> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, CliDetection>, Map<String, CliDetection>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, CliDetection>, Map<String, CliDetection>>,
              Map<String, CliDetection>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
