// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_servers_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(McpServersActions)
final mcpServersActionsProvider = McpServersActionsProvider._();

final class McpServersActionsProvider extends $AsyncNotifierProvider<McpServersActions, void> {
  McpServersActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpServersActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpServersActionsHash();

  @$internal
  @override
  McpServersActions create() => McpServersActions();
}

String _$mcpServersActionsHash() => r'ccdee8e0c65932ad68cf589630d1c179030178ad';

abstract class _$McpServersActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>, AsyncValue<void>, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
