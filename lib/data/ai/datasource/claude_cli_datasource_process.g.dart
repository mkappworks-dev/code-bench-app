// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claude_cli_datasource_process.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(claudeCliDatasourceProcess)
final claudeCliDatasourceProcessProvider = ClaudeCliDatasourceProcessProvider._();

final class ClaudeCliDatasourceProcessProvider
    extends $FunctionalProvider<AIProviderDatasource, AIProviderDatasource, AIProviderDatasource>
    with $Provider<AIProviderDatasource> {
  ClaudeCliDatasourceProcessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claudeCliDatasourceProcessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claudeCliDatasourceProcessHash();

  @$internal
  @override
  $ProviderElement<AIProviderDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AIProviderDatasource create(Ref ref) {
    return claudeCliDatasourceProcess(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AIProviderDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AIProviderDatasource>(value));
  }
}

String _$claudeCliDatasourceProcessHash() => r'ac5ddd45fcc8b06067ccd2f686b978219d1b1ddf';
