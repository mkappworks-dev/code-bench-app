// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_dir_tool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listDirTool)
final listDirToolProvider = ListDirToolProvider._();

final class ListDirToolProvider extends $FunctionalProvider<ListDirTool, ListDirTool, ListDirTool>
    with $Provider<ListDirTool> {
  ListDirToolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listDirToolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listDirToolHash();

  @$internal
  @override
  $ProviderElement<ListDirTool> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ListDirTool create(Ref ref) {
    return listDirTool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListDirTool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ListDirTool>(value));
  }
}

String _$listDirToolHash() => r'ced0c067b77db6e4c305be6a8fc9959bd4d27de8';
