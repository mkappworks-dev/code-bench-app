// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_servers_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(McpServersNotifier)
final mcpServersProvider = McpServersNotifierProvider._();

final class McpServersNotifierProvider extends $StreamNotifierProvider<McpServersNotifier, List<McpServerConfig>> {
  McpServersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpServersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpServersNotifierHash();

  @$internal
  @override
  McpServersNotifier create() => McpServersNotifier();
}

String _$mcpServersNotifierHash() => r'eeff3896d4761d8aebdb64e16713033a477a5cd7';

abstract class _$McpServersNotifier extends $StreamNotifier<List<McpServerConfig>> {
  Stream<List<McpServerConfig>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<McpServerConfig>>, List<McpServerConfig>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<McpServerConfig>>, List<McpServerConfig>>,
              AsyncValue<List<McpServerConfig>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
