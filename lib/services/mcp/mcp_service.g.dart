// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [McpService] wired to [McpServerStatusNotifier] from the
/// settings feature.
///
/// Documented exception: this provider (the composition root / wiring layer)
/// imports [McpServerStatusNotifier] from `lib/features/` to wire the status
/// callback. The [McpService] class itself has no direct knowledge of
/// `lib/features/`. Pattern mirrors [agentServiceProvider].

@ProviderFor(mcpService)
final mcpServiceProvider = McpServiceProvider._();

/// Provides a [McpService] wired to [McpServerStatusNotifier] from the
/// settings feature.
///
/// Documented exception: this provider (the composition root / wiring layer)
/// imports [McpServerStatusNotifier] from `lib/features/` to wire the status
/// callback. The [McpService] class itself has no direct knowledge of
/// `lib/features/`. Pattern mirrors [agentServiceProvider].

final class McpServiceProvider
    extends $FunctionalProvider<McpService, McpService, McpService>
    with $Provider<McpService> {
  /// Provides a [McpService] wired to [McpServerStatusNotifier] from the
  /// settings feature.
  ///
  /// Documented exception: this provider (the composition root / wiring layer)
  /// imports [McpServerStatusNotifier] from `lib/features/` to wire the status
  /// callback. The [McpService] class itself has no direct knowledge of
  /// `lib/features/`. Pattern mirrors [agentServiceProvider].
  McpServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpServiceHash();

  @$internal
  @override
  $ProviderElement<McpService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  McpService create(Ref ref) {
    return mcpService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<McpService>(value),
    );
  }
}

String _$mcpServiceHash() => r'c53864a04124b9cd6da339157e23601ad6beb261';
