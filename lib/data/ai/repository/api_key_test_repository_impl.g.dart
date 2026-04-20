// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_test_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apiKeyTestRepository)
final apiKeyTestRepositoryProvider = ApiKeyTestRepositoryProvider._();

final class ApiKeyTestRepositoryProvider
    extends
        $FunctionalProvider<
          ApiKeyTestRepository,
          ApiKeyTestRepository,
          ApiKeyTestRepository
        >
    with $Provider<ApiKeyTestRepository> {
  ApiKeyTestRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiKeyTestRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiKeyTestRepositoryHash();

  @$internal
  @override
  $ProviderElement<ApiKeyTestRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ApiKeyTestRepository create(Ref ref) {
    return apiKeyTestRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiKeyTestRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiKeyTestRepository>(value),
    );
  }
}

String _$apiKeyTestRepositoryHash() =>
    r'60c260b4bc66334b839be905d35b3510f6654d99';
