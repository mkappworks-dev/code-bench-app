// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_datasource_dio.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateDatasource)
final updateDatasourceProvider = UpdateDatasourceProvider._();

final class UpdateDatasourceProvider extends $FunctionalProvider<UpdateDatasource, UpdateDatasource, UpdateDatasource>
    with $Provider<UpdateDatasource> {
  UpdateDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateDatasourceHash();

  @$internal
  @override
  $ProviderElement<UpdateDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  UpdateDatasource create(Ref ref) {
    return updateDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<UpdateDatasource>(value));
  }
}

String _$updateDatasourceHash() => r'9e7cdd943a6b3e56d318143bdcae868095edd619';
