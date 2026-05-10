// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_registry_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(toolRegistryService)
final toolRegistryServiceProvider = ToolRegistryServiceProvider._();

final class ToolRegistryServiceProvider
    extends $FunctionalProvider<ToolRegistryService, ToolRegistryService, ToolRegistryService>
    with $Provider<ToolRegistryService> {
  ToolRegistryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolRegistryServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolRegistryServiceHash();

  @$internal
  @override
  $ProviderElement<ToolRegistryService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ToolRegistryService create(Ref ref) {
    return toolRegistryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToolRegistryService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ToolRegistryService>(value));
  }
}

String _$toolRegistryServiceHash() => r'e4b20093d0bec23686f93feae1f8273eec28542d';
