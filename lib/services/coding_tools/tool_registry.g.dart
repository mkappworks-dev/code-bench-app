// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_registry.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(toolRegistry)
final toolRegistryProvider = ToolRegistryProvider._();

final class ToolRegistryProvider extends $FunctionalProvider<ToolRegistry, ToolRegistry, ToolRegistry>
    with $Provider<ToolRegistry> {
  ToolRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolRegistryHash();

  @$internal
  @override
  $ProviderElement<ToolRegistry> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ToolRegistry create(Ref ref) {
    return toolRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToolRegistry value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ToolRegistry>(value));
  }
}

String _$toolRegistryHash() => r'bc8a55c62b8b6b636a86e400764eb3f0007ee114';
