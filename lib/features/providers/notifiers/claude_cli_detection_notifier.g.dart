// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claude_cli_detection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Widget-facing read-through for the local Claude Code CLI detection probe.
///
/// Widgets watch this for the latest [CliDetection] state. The underlying
/// [CliDetectionService] is a TTL-cached probe; [recheck] bypasses the cache.

@ProviderFor(ClaudeCliDetectionNotifier)
final claudeCliDetectionProvider = ClaudeCliDetectionNotifierProvider._();

/// Widget-facing read-through for the local Claude Code CLI detection probe.
///
/// Widgets watch this for the latest [CliDetection] state. The underlying
/// [CliDetectionService] is a TTL-cached probe; [recheck] bypasses the cache.
final class ClaudeCliDetectionNotifierProvider
    extends $AsyncNotifierProvider<ClaudeCliDetectionNotifier, CliDetection> {
  /// Widget-facing read-through for the local Claude Code CLI detection probe.
  ///
  /// Widgets watch this for the latest [CliDetection] state. The underlying
  /// [CliDetectionService] is a TTL-cached probe; [recheck] bypasses the cache.
  ClaudeCliDetectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claudeCliDetectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claudeCliDetectionNotifierHash();

  @$internal
  @override
  ClaudeCliDetectionNotifier create() => ClaudeCliDetectionNotifier();
}

String _$claudeCliDetectionNotifierHash() => r'bb0aad282b3764b6147618268782a0448437355f';

/// Widget-facing read-through for the local Claude Code CLI detection probe.
///
/// Widgets watch this for the latest [CliDetection] state. The underlying
/// [CliDetectionService] is a TTL-cached probe; [recheck] bypasses the cache.

abstract class _$ClaudeCliDetectionNotifier extends $AsyncNotifier<CliDetection> {
  FutureOr<CliDetection> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CliDetection>, CliDetection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CliDetection>, CliDetection>,
              AsyncValue<CliDetection>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
