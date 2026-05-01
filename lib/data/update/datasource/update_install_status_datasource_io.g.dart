// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_install_status_datasource_io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateInstallStatusDatasource)
final updateInstallStatusDatasourceProvider = UpdateInstallStatusDatasourceProvider._();

final class UpdateInstallStatusDatasourceProvider
    extends
        $FunctionalProvider<UpdateInstallStatusDatasource, UpdateInstallStatusDatasource, UpdateInstallStatusDatasource>
    with $Provider<UpdateInstallStatusDatasource> {
  UpdateInstallStatusDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateInstallStatusDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateInstallStatusDatasourceHash();

  @$internal
  @override
  $ProviderElement<UpdateInstallStatusDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  UpdateInstallStatusDatasource create(Ref ref) {
    return updateInstallStatusDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateInstallStatusDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<UpdateInstallStatusDatasource>(value));
  }
}

String _$updateInstallStatusDatasourceHash() => r'bac0a26b0b28b4d391bf2a1dc9b957c9b4743f5d';
