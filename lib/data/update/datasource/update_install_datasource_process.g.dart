// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_install_datasource_process.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateInstallDatasource)
final updateInstallDatasourceProvider = UpdateInstallDatasourceProvider._();

final class UpdateInstallDatasourceProvider
    extends $FunctionalProvider<UpdateInstallDatasource, UpdateInstallDatasource, UpdateInstallDatasource>
    with $Provider<UpdateInstallDatasource> {
  UpdateInstallDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateInstallDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateInstallDatasourceHash();

  @$internal
  @override
  $ProviderElement<UpdateInstallDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  UpdateInstallDatasource create(Ref ref) {
    return updateInstallDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateInstallDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<UpdateInstallDatasource>(value));
  }
}

String _$updateInstallDatasourceHash() => r'7ffb5ea102921df7745b6ca5784a41b7ef5cf1e6';
