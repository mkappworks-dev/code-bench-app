// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ide_launch_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ideLaunchRepository)
final ideLaunchRepositoryProvider = IdeLaunchRepositoryProvider._();

final class IdeLaunchRepositoryProvider
    extends $FunctionalProvider<IdeLaunchRepository, IdeLaunchRepository, IdeLaunchRepository>
    with $Provider<IdeLaunchRepository> {
  IdeLaunchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ideLaunchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ideLaunchRepositoryHash();

  @$internal
  @override
  $ProviderElement<IdeLaunchRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  IdeLaunchRepository create(Ref ref) {
    return ideLaunchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdeLaunchRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<IdeLaunchRepository>(value));
  }
}

String _$ideLaunchRepositoryHash() => r'f71a246fb5d1550b8b448f9df2779ec31342183b';
