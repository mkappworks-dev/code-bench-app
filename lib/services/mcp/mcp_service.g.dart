// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mcpService)
final mcpServiceProvider = McpServiceProvider._();

final class McpServiceProvider extends $FunctionalProvider<McpService, McpService, McpService>
    with $Provider<McpService> {
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
  $ProviderElement<McpService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  McpService create(Ref ref) {
    return mcpService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<McpService>(value));
  }
}

String _$mcpServiceHash() => r'c9963253d5d8875873de7f6dbe6130e17438bf42';
