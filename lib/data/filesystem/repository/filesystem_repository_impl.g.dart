// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filesystem_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(filesystemRepository)
final filesystemRepositoryProvider = FilesystemRepositoryProvider._();

final class FilesystemRepositoryProvider
    extends
        $FunctionalProvider<
          FilesystemRepository,
          FilesystemRepository,
          FilesystemRepository
        >
    with $Provider<FilesystemRepository> {
  FilesystemRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filesystemRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filesystemRepositoryHash();

  @$internal
  @override
  $ProviderElement<FilesystemRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FilesystemRepository create(Ref ref) {
    return filesystemRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilesystemRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilesystemRepository>(value),
    );
  }
}

String _$filesystemRepositoryHash() =>
    r'3c601e4b604c4972f7cab5eee796fb043d165d15';
