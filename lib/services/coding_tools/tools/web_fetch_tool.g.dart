// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_fetch_tool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(webFetchTool)
final webFetchToolProvider = WebFetchToolProvider._();

final class WebFetchToolProvider
    extends $FunctionalProvider<WebFetchTool, WebFetchTool, WebFetchTool>
    with $Provider<WebFetchTool> {
  WebFetchToolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webFetchToolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webFetchToolHash();

  @$internal
  @override
  $ProviderElement<WebFetchTool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WebFetchTool create(Ref ref) {
    return webFetchTool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebFetchTool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebFetchTool>(value),
    );
  }
}

String _$webFetchToolHash() => r'40a937dfdb70d4af1aeeca46561a3c62f719aae6';
