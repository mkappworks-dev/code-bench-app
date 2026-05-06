// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_server_status_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive` so a captured instance survives the chat tab unmount while `ChatStreamService` is still emitting updates.

@ProviderFor(McpServerStatusNotifier)
final mcpServerStatusProvider = McpServerStatusNotifierProvider._();

/// `keepAlive` so a captured instance survives the chat tab unmount while `ChatStreamService` is still emitting updates.
final class McpServerStatusNotifierProvider
    extends $NotifierProvider<McpServerStatusNotifier, Map<String, McpServerStatus>> {
  /// `keepAlive` so a captured instance survives the chat tab unmount while `ChatStreamService` is still emitting updates.
  McpServerStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpServerStatusProvider',
        isAutoDispose: false,
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

String _$mcpServerStatusNotifierHash() => r'52287402abd0c1e91b66f3f27e01bd0ba30eee07';

/// `keepAlive` so a captured instance survives the chat tab unmount while `ChatStreamService` is still emitting updates.

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
