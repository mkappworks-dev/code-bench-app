// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ide_launch_datasource_process.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ideLaunchDatasource)
final ideLaunchDatasourceProvider = IdeLaunchDatasourceProvider._();

final class IdeLaunchDatasourceProvider
    extends
        $FunctionalProvider<
          IdeLaunchDatasource,
          IdeLaunchDatasource,
          IdeLaunchDatasource
        >
    with $Provider<IdeLaunchDatasource> {
  IdeLaunchDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ideLaunchDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ideLaunchDatasourceHash();

  @$internal
  @override
  $ProviderElement<IdeLaunchDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IdeLaunchDatasource create(Ref ref) {
    return ideLaunchDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdeLaunchDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdeLaunchDatasource>(value),
    );
  }
}

String _$ideLaunchDatasourceHash() =>
    r'0cb49a5bd4e3a1c28b6d47d675cd99feefb2ea8b';
