// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filesystem_datasource_io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(filesystemDatasource)
final filesystemDatasourceProvider = FilesystemDatasourceProvider._();

final class FilesystemDatasourceProvider
    extends $FunctionalProvider<FilesystemDatasource, FilesystemDatasource, FilesystemDatasource>
    with $Provider<FilesystemDatasource> {
  FilesystemDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filesystemDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filesystemDatasourceHash();

  @$internal
  @override
  $ProviderElement<FilesystemDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  FilesystemDatasource create(Ref ref) {
    return filesystemDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilesystemDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<FilesystemDatasource>(value));
  }
}

String _$filesystemDatasourceHash() => r'0b432e1d5f108b8108779be73370193564a2aa08';
