// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_test_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apiKeyTestService)
final apiKeyTestServiceProvider = ApiKeyTestServiceProvider._();

final class ApiKeyTestServiceProvider
    extends
        $FunctionalProvider<
          ApiKeyTestService,
          ApiKeyTestService,
          ApiKeyTestService
        >
    with $Provider<ApiKeyTestService> {
  ApiKeyTestServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiKeyTestServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiKeyTestServiceHash();

  @$internal
  @override
  $ProviderElement<ApiKeyTestService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ApiKeyTestService create(Ref ref) {
    return apiKeyTestService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiKeyTestService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiKeyTestService>(value),
    );
  }
}

String _$apiKeyTestServiceHash() => r'88551480e91aa42c4654a565a3ee2850324835df';
