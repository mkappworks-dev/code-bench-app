// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cli_detection_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Detects local CLI binaries and caches results per-binary with a TTL.
///
/// Authentication status is intentionally NOT probed: Claude Code has no
/// stable `auth status` subcommand, and probing via a real request would
/// burn credits. Installed → [CliAuthStatus.unknown] always; the user
/// discovers auth state when they send a message and either succeeds or
/// gets a typed failure.

@ProviderFor(CliDetectionService)
final cliDetectionServiceProvider = CliDetectionServiceProvider._();

/// Detects local CLI binaries and caches results per-binary with a TTL.
///
/// Authentication status is intentionally NOT probed: Claude Code has no
/// stable `auth status` subcommand, and probing via a real request would
/// burn credits. Installed → [CliAuthStatus.unknown] always; the user
/// discovers auth state when they send a message and either succeeds or
/// gets a typed failure.
final class CliDetectionServiceProvider extends $NotifierProvider<CliDetectionService, Map<String, CliDetection>> {
  /// Detects local CLI binaries and caches results per-binary with a TTL.
  ///
  /// Authentication status is intentionally NOT probed: Claude Code has no
  /// stable `auth status` subcommand, and probing via a real request would
  /// burn credits. Installed → [CliAuthStatus.unknown] always; the user
  /// discovers auth state when they send a message and either succeeds or
  /// gets a typed failure.
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

String _$cliDetectionServiceHash() => r'222162b9f97d996ddbae5aa02d33d5e705b23406';

/// Detects local CLI binaries and caches results per-binary with a TTL.
///
/// Authentication status is intentionally NOT probed: Claude Code has no
/// stable `auth status` subcommand, and probing via a real request would
/// burn credits. Installed → [CliAuthStatus.unknown] always; the user
/// discovers auth state when they send a message and either succeeds or
/// gets a typed failure.

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
