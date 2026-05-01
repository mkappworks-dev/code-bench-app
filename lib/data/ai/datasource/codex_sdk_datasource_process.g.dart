// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'codex_sdk_datasource_process.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(codexSdkDatasourceProcess)
final codexSdkDatasourceProcessProvider = CodexSdkDatasourceProcessProvider._();

final class CodexSdkDatasourceProcessProvider
    extends $FunctionalProvider<AIProviderDatasource, AIProviderDatasource, AIProviderDatasource>
    with $Provider<AIProviderDatasource> {
  CodexSdkDatasourceProcessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codexSdkDatasourceProcessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codexSdkDatasourceProcessHash();

  @$internal
  @override
  $ProviderElement<AIProviderDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AIProviderDatasource create(Ref ref) {
    return codexSdkDatasourceProcess(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AIProviderDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AIProviderDatasource>(value));
  }
}

String _$codexSdkDatasourceProcessHash() => r'fc5e18c26495ad2eb61591bcfc24c82ca6bdcb16';
