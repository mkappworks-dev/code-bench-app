// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'codex_cli_datasource_process.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(codexCliDatasourceProcess)
final codexCliDatasourceProcessProvider = CodexCliDatasourceProcessProvider._();

final class CodexCliDatasourceProcessProvider
    extends
        $FunctionalProvider<
          AIProviderDatasource,
          AIProviderDatasource,
          AIProviderDatasource
        >
    with $Provider<AIProviderDatasource> {
  CodexCliDatasourceProcessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codexCliDatasourceProcessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codexCliDatasourceProcessHash();

  @$internal
  @override
  $ProviderElement<AIProviderDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AIProviderDatasource create(Ref ref) {
    return codexCliDatasourceProcess(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AIProviderDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AIProviderDatasource>(value),
    );
  }
}

String _$codexCliDatasourceProcessHash() =>
    r'41a7501a03b5ff4f370ec29058a37d181966fc5a';
