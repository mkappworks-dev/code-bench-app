// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claude_sdk_datasource_process.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(claudeSdkDatasourceProcess)
final claudeSdkDatasourceProcessProvider = ClaudeSdkDatasourceProcessProvider._();

final class ClaudeSdkDatasourceProcessProvider
    extends $FunctionalProvider<AIProviderDatasource, AIProviderDatasource, AIProviderDatasource>
    with $Provider<AIProviderDatasource> {
  ClaudeSdkDatasourceProcessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claudeSdkDatasourceProcessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claudeSdkDatasourceProcessHash();

  @$internal
  @override
  $ProviderElement<AIProviderDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AIProviderDatasource create(Ref ref) {
    return claudeSdkDatasourceProcess(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AIProviderDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AIProviderDatasource>(value));
  }
}

String _$claudeSdkDatasourceProcessHash() => r'ebd4d5775d09b3ef858400176f7635160cdd732c';
