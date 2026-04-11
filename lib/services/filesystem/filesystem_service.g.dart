// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filesystem_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(filesystemService)
final filesystemServiceProvider = FilesystemServiceProvider._();

final class FilesystemServiceProvider
    extends $FunctionalProvider<FilesystemService, FilesystemService, FilesystemService>
    with $Provider<FilesystemService> {
  FilesystemServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filesystemServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filesystemServiceHash();

  @$internal
  @override
  $ProviderElement<FilesystemService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  FilesystemService create(Ref ref) {
    return filesystemService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilesystemService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<FilesystemService>(value));
  }
}

String _$filesystemServiceHash() => r'75f325571c452e8c8c22011b69c2dacd9cf05006';
