// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(providersRepository)
final providersRepositoryProvider = ProvidersRepositoryProvider._();

final class ProvidersRepositoryProvider
    extends
        $FunctionalProvider<
          ProvidersRepository,
          ProvidersRepository,
          ProvidersRepository
        >
    with $Provider<ProvidersRepository> {
  ProvidersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providersRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providersRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProvidersRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProvidersRepository create(Ref ref) {
    return providersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProvidersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProvidersRepository>(value),
    );
  }
}

String _$providersRepositoryHash() =>
    r'46f8bb1c56f7782dd66535ae3853bc54908f212c';
