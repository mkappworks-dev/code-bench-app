// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mcpRepository)
final mcpRepositoryProvider = McpRepositoryProvider._();

final class McpRepositoryProvider
    extends $FunctionalProvider<McpRepository, McpRepository, McpRepository>
    with $Provider<McpRepository> {
  McpRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpRepositoryHash();

  @$internal
  @override
  $ProviderElement<McpRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  McpRepository create(Ref ref) {
    return mcpRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<McpRepository>(value),
    );
  }
}

String _$mcpRepositoryHash() => r'0659a7b5b949d9abb85a50e097b01543f4e4b7be';
