// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_config_datasource_drift.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mcpConfigDatasource)
final mcpConfigDatasourceProvider = McpConfigDatasourceProvider._();

final class McpConfigDatasourceProvider
    extends $FunctionalProvider<McpConfigDatasourceDrift, McpConfigDatasourceDrift, McpConfigDatasourceDrift>
    with $Provider<McpConfigDatasourceDrift> {
  McpConfigDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpConfigDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpConfigDatasourceHash();

  @$internal
  @override
  $ProviderElement<McpConfigDatasourceDrift> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  McpConfigDatasourceDrift create(Ref ref) {
    return mcpConfigDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpConfigDatasourceDrift value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<McpConfigDatasourceDrift>(value));
  }
}

String _$mcpConfigDatasourceHash() => r'b50694b4a93a91651a49cb1b7ad8f85787636bae';
