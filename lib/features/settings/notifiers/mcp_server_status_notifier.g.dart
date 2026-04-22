// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_server_status_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(McpServerStatusNotifier)
final mcpServerStatusProvider = McpServerStatusNotifierProvider._();

final class McpServerStatusNotifierProvider
    extends $NotifierProvider<McpServerStatusNotifier, Map<String, McpServerStatus>> {
  McpServerStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpServerStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpServerStatusNotifierHash();

  @$internal
  @override
  McpServerStatusNotifier create() => McpServerStatusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, McpServerStatus> value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Map<String, McpServerStatus>>(value));
  }
}

String _$mcpServerStatusNotifierHash() => r'8cb8ba1cbc6ed0f13a4c6bd96a37b41d9d337780';

abstract class _$McpServerStatusNotifier extends $Notifier<Map<String, McpServerStatus>> {
  Map<String, McpServerStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, McpServerStatus>, Map<String, McpServerStatus>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, McpServerStatus>, Map<String, McpServerStatus>>,
              Map<String, McpServerStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
